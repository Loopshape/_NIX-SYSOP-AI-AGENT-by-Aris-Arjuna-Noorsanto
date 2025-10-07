#!/usr/bin/env bash
set -euo pipefail

# ███████╗██╗   ██╗███████╗ ██████╗ ██████╗ █████╗ ██╗
# ██╔════╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║
# ███████╗ ╚████╔╝ █████╗  ██║   ██║██████╔╝███████║██║
# ╚════██║  ╚██╔╝  ██╔══╝  ██║   ██║██╔═══╝ ██╔══██║██║
# ███████║   ██║   ███████╗╚██████╔╝██║     ██║  ██║███████╗
# ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝
#
# Mixed SysOp-AI Agent – Installer, Launcher & Orchestrator
# Version: custom

# --- Environment & Configuration ---
export AI_HOME="${AI_HOME:-$HOME/.sysop-ai}"
export DB_DIR="$AI_HOME/db"
export AI_DATA_DB="$DB_DIR/ai_data.db"
export BLOBS_DB="$DB_DIR/blobs.db"
export ORCHESTRATOR_FILE="$AI_HOME/orchestrator.mjs"
export SESSION_FILE="$AI_HOME/.session"
export OLLAMA_BIN="ollama"
export NODE_MODULES="$AI_HOME/node_modules"
export NODE_PATH="${NODE_PATH:-}:$NODE_MODULES"

# --- Logging ---
log_event() {
    echo "[\x1b[34m$1\x1b[0m] $(date): $2"
    sqlite3 "$AI_DATA_DB" "INSERT INTO events (event_type, message) VALUES ('$1', '$2');" || true
}

# --- Dependency Checks ---
check_node_modules() {
    if [ ! -d "$NODE_MODULES/sqlite3" ]; then
        echo "[INFO] Node module 'sqlite3' missing. Installing locally..."
        npm install --prefix "$AI_HOME" sqlite3
    fi
}

check_dependencies() {
    local missing_deps=()
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    check_node_modules
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# --- Database Initialization ---
init_databases() {
    mkdir -p "$DB_DIR"
    sqlite3 "$AI_DATA_DB" <<SQL
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    prompt TEXT,
    response TEXT,
    proof_state TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT,
    message TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
    sqlite3 "$BLOBS_DB" <<SQL
CREATE TABLE IF NOT EXISTS blobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    file_path TEXT,
    content BLOB,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
    log_event "INFO" "Databases initialized: memories, events, blobs"
}

# --- Orchestrator Setup: embed Node orchestrator.js (consensus loop, model pool) ---
setup_orchestrator() {
    mkdir -p "$AI_HOME"
    cat > "$ORCHESTRATOR_FILE" <<'EOF_JS'
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3Pkg from 'sqlite3';
const { verbose } = sqlite3Pkg;
const sqlite3 = verbose();

// ENV from Bash
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR || path.join(AI_HOME, 'projects');
const AI_DATA_DB_PATH = process.env.AI_DATA_DB;
const BLOBS_DB_PATH = process.env.BLOBS_DB;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';

// Mandatory model pool
const MODEL_POOL = ["core", "loop", "2244"];  

const aiDataDb = new sqlite3.Database(AI_DATA_DB_PATH);
const blobsDb = new sqlite3.Database(BLOBS_DB_PATH);

class ProofTracker {
    constructor(initialPrompt) {
        this.cycleIndex = initialPrompt.length;
        this.netWorthIndex = (this.cycleIndex % 128) << 2;
        this.entropyRatio = (this.cycleIndex ^ Date.now()) / 1000;
    }
    crosslineEntropy(data) {
        const h = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(h.substring(0, 8), 16);
    }
    proofCycle(converged) {
        this.cycleIndex += converged ? 1 : 0;
        this.netWorthIndex -= converged ? 0 : 1;
    }
    getState() {
        return {
            cycleIndex: this.cycleIndex,
            netWorthIndex: this.netWorthIndex,
            entropyRatio: this.entropyRatio
        };
    }
}

class AIOrchestrator {
    constructor(prompt, options) {
        this.initialPrompt = prompt;
        this.options = options;
        this.taskId = crypto.createHash('sha256').update(Date.now().toString()).digest('hex');
        this.proofTracker = new ProofTracker(prompt);
    }

    runOllama(model, currPrompt) {
        return new Promise((resolve, reject) => {
            console.log(`\n\x1b[34m[INFO]\x1b[0m Model \x1b[33m'${model}'\x1b[0m is thinking...`);
            const cmd = `${OLLAMA_BIN} run ${model} "${currPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(cmd);
            let out = "";
            child.on('error', e => reject(e));
            child.stdout.on('data', d => {
                process.stdout.write(`\x1b[2m${d}\x1b[0m`);
                out += d;
            });
            child.stderr.on('data', d => process.stderr.write(d));
            child.on('close', code => {
                if (code !== 0) reject(new Error(`Model ${model} exited ${code}`));
                else resolve(out.trim());
            });
        });
    }

    async consensusLoop() {
        const systemPrompt = `SYSTEM PROMPT: You are a world-class software engineer. Your response MUST be ONLY the requested artifact. Use markdown for all code blocks. User Task:\n`;
        let currPrompt = systemPrompt + this.initialPrompt;
        let lastFusion = "";
        let prevHash = "";
        let converged = false;
        for (let i = 0; i < 3 && !converged; i++) {
            const promises = MODEL_POOL.map(m => this.runOllama(m, currPrompt).catch(e => `ERROR:${e.toString()}`));
            const results = await Promise.all(promises);
            const valids = results.filter(r => !r.startsWith("ERROR:"));
            if (valids.length === 0) {
                throw new Error("All models failed");
            }
            const fused = valids.join("\n---\n");
            this.proofTracker.crosslineEntropy(fused);

            if (fused === lastFusion) {
                converged = true;
                this.proofTracker.proofCycle(true);
            } else {
                this.proofTracker.proofCycle(false);
            }

            const rehash = crypto.createHash('sha256')
                .update(i + "|" + prevHash + "|" + fused + "|" + Date.now().toString())
                .digest('hex');
            console.log(`[INFO] iteration ${i}, rehash = ${rehash}`);
            prevHash = rehash;

            lastFusion = fused;
            currPrompt = systemPrompt + this.initialPrompt + `\n[PREV ITERATION OUTPUT]\n${fused}`;
        }
        return lastFusion;
    }

    async execute() {
        try {
            const result = await this.consensusLoop();
            console.log("\n\x1b[1;36m--- Final Consensus Output ---\x1b[0m\n");
            console.log(result);
            aiDataDb.run(
                `INSERT INTO memories(task_id, prompt, response, proof_state) VALUES (?,?,?,?)`,
                [this.taskId, this.initialPrompt, result, JSON.stringify(this.proofTracker.getState())],
                err => { if (err) console.error("DB memory insert error:", err); }
            );
        } catch (e) {
            console.error("Orchestrator error:", e);
        } finally {
            aiDataDb.close();
            blobsDb.close();
        }
    }
}

(async () => {
    const args = process.argv.slice(2);
    const prompt = args.join(' ');
    if (!prompt) {
        console.error("Usage: orchestrator.mjs <prompt>");
        process.exit(1);
    }
    const options = {};
    const orchestrator = new AIOrchestrator(prompt, options);
    await orchestrator.execute();
})();
EOF_JS

    log_event "INFO" "Orchestrator file written at $ORCHESTRATOR_FILE"
}

# --- Running a Task ---
run_ai_task() {
    local full_prompt="$*"
    # If the prompt contains a hyphen, bypass consensus and run a default model
    if [[ "$full_prompt" == *-* ]]; then
        echo "[INFO] Hyphen in prompt — direct run via Ollama"
        if command -v "$OLLAMA_BIN" &> /dev/null; then
            "$OLLAMA_BIN" run core "$full_prompt"
        else
            echo "[ERROR] Ollama not found"
            exit 1
        fi
        return
    fi

    # If session project exists, attach it
    if [ -f "$SESSION_FILE" ]; then
        local proj
        proj=$(cat "$SESSION_FILE")
        full_prompt="$full_prompt --project=$proj"
    fi

    log_event "TASK_START" "Prompt: $full_prompt"
    node "$ORCHESTRATOR_FILE" $full_prompt
    log_event "TASK_END" "Finished task"
}

# --- Status Reporting ---
status_check() {
    echo "SysOp-AI Status Report"
    echo "AI_HOME: $AI_HOME"
    echo "Orchestrator: $ORCHESTRATOR_FILE"
    echo "Ollama: $(command -v $OLLAMA_BIN &>/dev/null && echo OK || echo Not Found)"
    echo "NodeJS: $(command -v node &>/dev/null && echo OK || echo Not Found)"
    echo "SQLite3: $(command -v sqlite3 &>/dev/null && echo OK || echo Not Found)"
    [ -f "$SESSION_FILE" ] && echo "Active session: $(cat $SESSION_FILE)" || echo "No active session"
}

# --- Main Execution ---
check_dependencies
init_databases
setup_orchestrator

if [ $# -eq 0 ]; then
    status_check
    exit 0
fi

COMMAND="$1"; shift
case "$COMMAND" in
    --start)
        read -r -p "Project name: " proj
        echo "$proj" > "$SESSION_FILE"
        log_event "SESSION" "Session started: $proj"
        ;;
    --stop)
        rm -f "$SESSION_FILE"
        log_event "SESSION" "Session stopped"
        ;;
    run)
        run_ai_task "$@"
        ;;
    status)
        status_check
        ;;
    *)
        run_ai_task "$COMMAND" "$@"
        ;;
esac