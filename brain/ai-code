#!/usr/bin/env bash
set -euo pipefail

# ███████╗██╗   ██╗███████╗ ██████╗ ██████╗ █████╗ ██╗    ██████╗ ██████╗ ██████╗ ███████╗
# ██╔════╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║    ██╔══██╗██╔══██╗██╔══██╗██╔════╝
# ███████╗ ╚████╔╝ █████╗  ██║   ██║██████╔╝███████║██║    ██║  ██║██████╔╝██████╔╝█████╗  
# ╚════██║  ╚██╔╝  ██╔══╝  ██║   ██║██╔═══╝ ██╔══██║██║    ██║  ██║██╔═══╝ ██╔═══╝ ██╔══╝  
# ███████║   ██║   ███████╗╚██████╔╝██║     ██║  ██║███████╗██████╔╝██║     ██║     ███████╗
# ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝     ╚══════╝
#
# WebDev Code-Engine with Dynamic Math Logic and MAX PARALLELISM
# Version: 8.0.0 (Code Quality and Analysis Pipeline)

# --- Enhanced Environment & Configuration ---
export AI_HOME="${AI_HOME:-$HOME/.webdev-ai}"
export ENV_HOME="${ENV_HOME:-$HOME/.webdev_ai_env}"
export NODE_MODULES="$AI_HOME/node_modules"
export PLUGIN_DIR="$AI_HOME/plugins"
export LOG_DIR="$AI_HOME/ollama_logs"
export ORCHESTRATOR_FILE="$AI_HOME/orchestrator.mjs"
export TASKS_DIR="$AI_HOME/tasks"
export PROJECTS_DIR="$AI_HOME/projects"
export DB_DIR="$AI_HOME/db"
export SSH_DIR="$AI_HOME/ssh"
export TEMPLATES_DIR="$AI_HOME/templates"
export SCRIPTS_DIR="$AI_HOME/scripts"
export AI_DATA_DB="$DB_DIR/ai_data.db"
export BLOBS_DB="$DB_DIR/blobs.db"
export WALLET_DB="$DB_DIR/wallet.db"
export WEB_CONFIG_DB="$DB_DIR/web_config.db"
export SESSION_FILE="$AI_HOME/.session"
export OLLAMA_BIN="ollama"
export NODE_PATH="${NODE_PATH:-}:$NODE_MODULES"
export CODE_PROCESSOR_PY="$SCRIPTS_DIR/code_processor.py" # New Python script path

# Verbose thinking configuration
export VERBOSE_THINKING="${VERBOSE_THINKING:-true}"
export THINKING_DELAY="${THINKING_DELAY:-0.5}"
export SHOW_REASONING="${SHOW_REASONING:-true}"

# --- ANSI Colors (Re-defined for Bash functions) ---
COLOR_RESET='\x1b[0m'
COLOR_BRIGHT='\x1b[1m'
COLOR_RED='\x1b[31m'
COLOR_GREEN='\x1b[32m'
COLOR_YELLOW='\x1b[33m'
COLOR_BLUE='\x1b[34m'
COLOR_MAGENTA='\x1b[35m'
COLOR_CYAN='\x1b[36m'
COLOR_GRAY='\x1b[90m'

# --- Enhanced Status Function ---
enhanced_status() {
    printf "\n${COLOR_BRIGHT}${COLOR_CYAN}🌐 WEBDEV AI CODE ENGINE STATUS${COLOR_RESET}\n"
    printf "${COLOR_GRAY}==========================================${COLOR_RESET}\n"
    printf "AI_HOME: %s\n" "$AI_HOME"
    printf "Projects: %s created\n" "$(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l)"
    printf "Active Session: %s\n" "$([ -f "$SESSION_FILE" ] && cat "$SESSION_FILE" || echo "None")"
    printf "Verbose Thinking: %s\n" "$VERBOSE_THINKING"
    printf "Show Reasoning: %s\n" "$SHOW_REASONING"
    
    # Check if dependencies are available
    printf "\n${COLOR_BRIGHT}${COLOR_BLUE}🔧 DEPENDENCIES:${COLOR_RESET}\n"
    # ## MODIFIED ##: Added Python tools to dependency check
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN" "pylint" "black" "autopep8" "shfmt")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$dep"
        else
            printf "  ${COLOR_RED}❌ %s${COLOR_RESET}\n" "$dep"
        fi
    done
    
    # Check Node modules
    printf "\n${COLOR_BRIGHT}${COLOR_MAGENTA}📦 NODE MODULES:${COLOR_RESET}\n"
    local node_modules=("sqlite3")
    for module in "${node_modules[@]}"; do
        if [ -d "$NODE_MODULES/$module" ]; then
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$module"
        else
            printf "  ${COLOR_RED}❌ %s${COLOR_RESET}\n" "$module"
        fi
    done
    
    # Show recent projects
    printf "\n${COLOR_BRIGHT}${COLOR_MAGENTA}📁 RECENT PROJECTS:${COLOR_RESET}\n"
    if [ -f "$WEB_CONFIG_DB" ]; then
        sqlite3 "$WEB_CONFIG_DB" "SELECT name, framework, status, datetime(ts) FROM projects ORDER BY ts DESC LIMIT 5;" 2>/dev/null | while IFS='|' read name framework status timestamp; do
            printf "  🗂️  %s (%s) - %s\n" "$name" "$framework" "$status"
            printf "     📅 %s\n" "$timestamp"
        done || printf "  No projects yet\n"
    else
        printf "  No projects database found\n"
    fi
    
    # Show system stats
    printf "\n${COLOR_BRIGHT}${COLOR_GREEN}📊 SYSTEM STATS:${COLOR_RESET}\n"
    if [ -f "$AI_DATA_DB" ]; then
        local total_tasks=$(sqlite3 "$AI_DATA_DB" "SELECT COUNT(*) FROM memories;" 2>/dev/null || echo "0")
        local total_events=$(sqlite3 "$AI_DATA_DB" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "0")
        printf "  Total Tasks: %s\n" "$total_tasks"
        printf "  Total Events: %s\n" "$total_events"
    fi
    
    # Show disk usage
    if [ -d "$AI_HOME" ]; then
        local disk_usage=$(du -sh "$AI_HOME" 2>/dev/null | cut -f1)
        printf "  Disk Usage: %s\n" "$disk_usage"
    fi
    
    printf "\n${COLOR_BRIGHT}${COLOR_YELLOW}💡 TIP: Use '--verbose' to toggle thinking mode, '--quiet' for silent mode${COLOR_RESET}\n"
}

# --- Enhanced Logging with Verbose Support ---
log_event() {
    local level="$1" message="$2" metadata="${3:-}" color="$COLOR_CYAN"
    case "$level" in
        "ERROR") color="$COLOR_RED" ;; "WARN") color="$COLOR_YELLOW" ;;
        "SUCCESS") color="$COLOR_GREEN" ;; "INFO") color="$COLOR_BLUE" ;;
        "DEBUG") color="$COLOR_MAGENTA" ;; "THINKING") color="$COLOR_CYAN" ;;
    esac
    
    echo -e "[${color}${level}${COLOR_RESET}] $(date +%H:%M:%S): $message"
    
    local message_esc=$(sed "s/'/''/g" <<< "$message")
    local metadata_esc=$(sed "s/'/''/g" <<< "$metadata")
    sqlite3 "$AI_DATA_DB" <<EOF || true
INSERT INTO events (event_type, message, metadata) VALUES ('$level', '$message_esc', '$metadata_esc');
EOF
}

# --- Thinking Animation and Verbose Output ---
thinking() {
    local message="$1" depth="${2:-0}" indent=""
    for ((i=0; i<depth; i++)); do indent+="  "; done
    
    if [ "$VERBOSE_THINKING" = "true" ]; then
        echo -e "${indent}🤔 ${COLOR_CYAN}THINKING${COLOR_RESET}: $message"
        sleep "$THINKING_DELAY"
    fi
}

show_reasoning() {
    local reasoning="$1" context="$2"
    
    if [ "$SHOW_REASONING" = "true" ] && [ -n "$reasoning" ]; then
        echo -e "\n${COLOR_YELLOW}💭 REASONING [$context]:${COLOR_RESET}"
        echo -e "${COLOR_GRAY}$reasoning${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n"
    fi
}

# --- Code Processing and Highlighting (## NEW FUNCTION ##) ---
_process_code_file() {
    local file_path="$1"
    local file_extension="${file_path##*.}"
    
    thinking "Processing code file: $file_path (ext: $file_extension)" 1
    
    if [ ! -f "$CODE_PROCESSOR_PY" ]; then
        log_event "ERROR" "Code processor script not found: $CODE_PROCESSOR_PY"
        cat "$file_path" # Fallback to plain output
        return
    fi

    # Call the Python script to handle formatting, analysis, and highlighting
    python3 "$CODE_PROCESSOR_PY" "$file_path" "$file_extension"
    
    if [ $? -ne 0 ]; then
        log_event "WARN" "Code processing failed for $file_path. Displaying raw content."
        cat "$file_path"
    fi
}

# --- Fixed Dependency Installation ---
install_node_modules() {
    thinking "Installing Node.js modules..." 1
    
    if [ ! -f "$AI_HOME/package.json" ]; then
        cat > "$AI_HOME/package.json" << 'PKG_JSON'
{
  "name": "webdev-ai-orchestrator",
  "version": "1.0.0",
  "description": "WebDev AI Code Engine Orchestrator",
  "type": "module",
  "dependencies": {
    "sqlite3": "^5.1.6"
  }
}
PKG_JSON
    fi
    
    thinking "Running npm install in $AI_HOME..." 2
    cd "$AI_HOME"
    
    if [ ! -d "$NODE_MODULES/sqlite3" ]; then
        thinking "Installing sqlite3..." 3
        npm install sqlite3 --save --loglevel=error
        if [ $? -eq 0 ]; then
            log_event "SUCCESS" "Installed sqlite3"
        else
            log_event "ERROR" "Failed to install sqlite3"
        fi
    fi
    
    thinking "Verifying module installation..." 2
    if [ -d "$NODE_MODULES/sqlite3" ]; then
        thinking "✅ sqlite3 installed successfully" 3
    else
        thinking "❌ sqlite3 failed to install" 3
        log_event "ERROR" "Module sqlite3 not found after installation"
    fi
    
    cd - > /dev/null
}

check_node_modules() {
    thinking "Checking Node.js modules..." 1
    
    if [ ! -d "$NODE_MODULES/sqlite3" ]; then
        thinking "sqlite3 module missing, installing..." 2
        install_node_modules
    else
        thinking "All Node.js modules are installed" 2
    fi
}

check_dependencies() {
    thinking "Checking system dependencies..." 1
    local missing_deps=()
    # ## MODIFIED ##: Added Python tools to dependency check
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN" "pylint" "black" "autopep8" "shfmt")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    check_node_modules
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_event "ERROR" "Missing dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies: ${missing_deps[*]}"
        # Do not exit here, allow the user to run status/install, but warn heavily
    fi
    
    log_event "SUCCESS" "All dependencies satisfied (or warnings issued)"
}

# Web Development Framework Detection (Simplified for Bash)
detect_frameworks() {
    local project_path="${1:-$PWD}"
    local frameworks=()
    
    frameworks+=("node" "react")
    
    show_reasoning "Detected frameworks: ${frameworks[*]}" "Framework Detection"
    echo "${frameworks[@]}"
}

# --- Enhanced Database Initialization ---
init_databases() {
    thinking "Initializing databases..." 1
    mkdir -p "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR"

    # Enhanced ai_data.db
    sqlite3 "$AI_DATA_DB" <<SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    prompt TEXT,
    response TEXT,
    proof_state TEXT,
    framework TEXT,
    complexity INTEGER DEFAULT 1,
    reasoning_log TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT,
    message TEXT,
    metadata TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS web_components (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    type TEXT,
    framework TEXT,
    code TEXT,
    dependencies TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS reasoning_chains (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    step INTEGER,
    reasoning TEXT,
    context TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS model_usage (
    task_id TEXT NOT NULL,
    model_name TEXT NOT NULL,
    PRIMARY KEY (task_id, model_name)
);
SQL

    # Enhanced blobs.db
    sqlite3 "$BLOBS_DB" <<SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS blobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    file_path TEXT,
    content BLOB,
    file_type TEXT,
    framework TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS scripts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    type TEXT,
    code TEXT,
    description TEXT,
    usage_count INTEGER DEFAULT 0,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

    # Web configuration database
    sqlite3 "$WEB_CONFIG_DB" <<SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    framework TEXT,
    port INTEGER,
    domain TEXT,
    status TEXT DEFAULT 'inactive',
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    environment TEXT,
    status TEXT,
    url TEXT,
    logs TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS api_endpoints (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    method TEXT,
    path TEXT,
    handler TEXT,
    middleware TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

    log_event "SUCCESS" "Enhanced databases initialized"
}

# --- Fixed Orchestrator with Working Colors (## FINAL OPTIMIZATION ##) ---
setup_orchestrator() {
    log_event "INFO" "Setting up enhanced orchestrator with dynamic math logic and max parallelism..."
    mkdir -p "$AI_HOME"
    cat > "$ORCHESTRATOR_FILE" <<'EOF_JS'
// Enhanced WebDev Code-Engine with Dynamic Math Logic and MAX PARALLELISM
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3 from 'sqlite3';

// Enhanced Environment
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';
const VERBOSE_THINKING = process.env.VERBOSE_THINKING !== 'false';
const SHOW_REASONING = process.env.SHOW_REASONING !== 'false';
const AI_DATA_DB = process.env.AI_DATA_DB;

// Enhanced Model Pool for Web Development (Default/Fallback)
const WEB_DEV_MODELS = ["2244:latest", "core:latest", "loop:latest", "coin:latest", "code:latest"];
const MODEL_WEIGHTS = { "2244:latest": 2, "core:latest": 2, "loop:latest": 1, "coin:latest": 1, "code:latest": 2 };

// Working color implementation using template literals
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
    
    // Combined styles
    boldCyan: (text) => `\x1b[1;36m${text}\x1b[0m`,
    boldGreen: (text) => `\x1b[1;32m${text}\x1b[0m`,
    boldMagenta: (text) => `\x1b[1;35m${text}\x1b[0m`,
    blueText: (text) => `\x1b[34m${text}\x1b[0m`,
    yellowText: (text) => `\x1b[33m${text}\x1b[0m`,
    greenText: (text) => `\x1b[32m${text}\x1b[0m`,
    redText: (text) => `\x1b[31m${text}\x1b[0m`,
    cyanText: (text) => `\x1b[36m${text}\x1b[0m`,
    grayText: (text) => `\x1b[90m${text}\x1b[0m`,
    magentaText: (text) => `\x1b[35m${text}\x1b[0m`
};

// --- Database Helpers ---
const getDb = () => new sqlite3.Database(AI_DATA_DB);

const logEvent = (level, message, metadata = '') => {
    const db = getDb();
    const sql = `INSERT INTO events (event_type, message, metadata) VALUES (?, ?, ?)`;
    db.run(sql, [level, message, metadata], (err) => {
        if (err) console.error(colors.redText(`[DB ERROR] Failed to log event: ${err.message}`));
        db.close();
    });
};

// --- Verbose thinking functions ---
const think = (message, depth = 0) => {
    if (VERBOSE_THINKING) {
        const indent = '  '.repeat(depth);
        console.log(colors.cyanText(`${indent}🤔 THINKING: ${message}`));
    }
};

const showReasoning = (reasoning, context = 'Reasoning') => {
    if (SHOW_REASONING && reasoning) {
        console.log(colors.yellowText(`\n💭 ${context.toUpperCase()}:\n`));
        console.log(colors.grayText(reasoning));
        console.log(colors.yellowText('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'));
    }
};

// --- Math/Hashing Helpers (Ported to Node.js) ---
const genCircularIndex = () => {
    const secondsInDay = 86400;
    const now = new Date();
    const secondsOfDay = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
    
    const scaledPi2 = 6283185; 
    const scaledIndex = Math.floor((secondsOfDay / secondsInDay) * scaledPi2);
    
    return scaledIndex.toString().padStart(7, '0');
};

const genRecursiveHash = (prompt) => {
    const promptHash = crypto.createHash('sha256').update(prompt).digest('hex').substring(0, 8);
    const circularIndex = genCircularIndex();
    const baseString = `${promptHash}.${circularIndex}`;

    const hash1 = crypto.createHash('sha256').update(baseString).digest('hex').substring(0, 4);
    const hash2 = crypto.createHash('sha256').update(hash1 + baseString).digest('hex').substring(4, 8);
    const hash3 = crypto.createHash('sha256').update(hash2 + hash1 + baseString).digest('hex').substring(8, 12);
    const hash4 = crypto.createHash('sha256').update(hash3 + hash2 + hash1 + baseString).digest('hex').substring(12, 16);
    const hash5 = crypto.createHash('sha256').update(hash4 + hash3 + hash2 + hash1 + baseString).digest('hex').substring(16, 20);

    return `${hash1}.${hash2}.${hash3}.${hash4}.${hash5}.${circularIndex}`;
};

// --- Dynamic Model Selection (Ported to Node.js) ---
const selectDynamicModels = (framework, complexity) => {
    return new Promise((resolve, reject) => {
        think("Selecting dynamic model pool for task...", 1);
        const db = getDb();
        const POOL_SIZE = 3;
        
        const availableModels = WEB_DEV_MODELS; 
        
        if (availableModels.length === 0) {
            logEvent("ERROR", "No Ollama models found. Falling back to defaults.");
            db.close();
            return resolve(WEB_DEV_MODELS);
        }

        let modelScores = {};
        let promises = [];

        availableModels.forEach(model => {
            const query = `
                SELECT SUM(
                    CASE T1.proof_state
                        WHEN 'CONVERGED' THEN 3 * T1.complexity
                        ELSE -1 * T1.complexity
                    END
                ) AS score
                FROM memories AS T1
                JOIN model_usage AS T2 ON T1.task_id = T2.task_id
                WHERE T2.model_name = ? AND T1.framework LIKE ?;
            `;
            
            promises.push(new Promise((res, rej) => {
                db.get(query, [model, `%${framework}%`], (err, row) => {
                    if (err) {
                        console.error(colors.redText(`[DB ERROR] Scoring model ${model}: ${err.message}`));
                        modelScores[model] = 0;
                    } else {
                        modelScores[model] = row.score || 0;
                    }
                    res();
                });
            }));
        });

        Promise.all(promises).then(() => {
            db.close();
            
            const sortedModels = Object.entries(modelScores)
                .sort(([, scoreA], [, scoreB]) => scoreB - scoreA)
                .map(([model]) => model);

            let dynamicPool = sortedModels.slice(0, POOL_SIZE);
            
            if (dynamicPool.length < POOL_SIZE) {
                availableModels.forEach(model => {
                    if (!dynamicPool.includes(model)) {
                        dynamicPool.push(model);
                    }
                });
                dynamicPool = dynamicPool.slice(0, POOL_SIZE);
            }

            const reasoningText = `Scores: ${JSON.stringify(modelScores)}\nSelected dynamic pool: ${dynamicPool.join(', ')}`;
            showReasoning(reasoningText, "Dynamic Model Selection");
            resolve(dynamicPool);
        });
    });
};

const updateModelUsage = (taskId, modelPool) => {
    return new Promise((resolve, reject) => {
        think("Logging model usage for this task...", 2);
        const db = getDb();
        db.serialize(() => {
            modelPool.forEach(model => {
                const sql = `INSERT OR IGNORE INTO model_usage (task_id, model_name) VALUES (?, ?)`;
                db.run(sql, [taskId, model], (err) => {
                    if (err) console.error(colors.redText(`[DB ERROR] Failed to log model usage: ${err.message}`));
                });
            });
            db.close(resolve);
        });
    });
};

// --- WebDevProofTracker (Modified for 2π Modulo Logic) ---
class WebDevProofTracker {
    constructor(initialPrompt, detectedFrameworks = [], taskId) {
        this.taskId = taskId;
        this.cycleIndex = 0; 
        this.netWorthIndex = 0;
        this.entropyRatio = (initialPrompt.length ^ Date.now()) / 1000;
        this.frameworks = detectedFrameworks;
        this.complexityScore = this.calculateComplexity(initialPrompt);
        this.reasoningChain = [];
    }

    calculateComplexity(prompt) {
        think("Calculating task complexity...", 1);
        let score = 0;
        const complexityKeywords = [
            'authentication', 'database', 'api', 'middleware', 'component', 
            'responsive', 'ssr', 'state management', 'deployment', 'docker'
        ];
        complexityKeywords.forEach(keyword => {
            if (prompt.toLowerCase().includes(keyword)) score += 2;
        });
        
        showReasoning(`Complexity score: ${score} (based on keywords: ${complexityKeywords.filter(k => prompt.toLowerCase().includes(k)).join(', ')})`, 'Complexity Analysis');
        return Math.min(score, 10);
    }

    crosslineEntropy(data) {
        think("Analyzing output entropy...", 1);
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(hash.substring(0, 8), 16);
        
        showReasoning(`Entropy updated: ${this.entropyRatio} (hash: ${hash.substring(0, 16)}...)`, 'Entropy Analysis');
    }

    proofCycle(converged, frameworkUsed = '', reasoning = '') {
        think(`Processing proof cycle: converged=${converged}, framework=${frameworkUsed}`, 1);
        this.cycleIndex += 1;
        this.netWorthIndex += converged ? 1 : -1;
        if (frameworkUsed && !this.frameworks.includes(frameworkUsed)) {
            this.frameworks.push(frameworkUsed);
        }
        
        let finalConverged = converged;
        
        // ## 2π Modulo Logical Algorithm ##
        const circularIndex = parseInt(genCircularIndex());
        const dynamicThreshold = (circularIndex % 3) + 1; 

        if (this.netWorthIndex >= dynamicThreshold) {
            reasoning += ` Dynamic threshold (${dynamicThreshold}) met. Accelerating convergence.`;
            finalConverged = true; 
        }
        
        if (reasoning) {
            this.reasoningChain.push({
                cycle: this.cycleIndex,
                converged: finalConverged,
                framework: frameworkUsed,
                reasoning,
                timestamp: new Date().toISOString()
            });
        }
        
        showReasoning(`Cycle ${this.cycleIndex}: ${finalConverged ? 'CONVERGED' : 'DIVERGED'}, Net Worth: ${this.netWorthIndex}. Dynamic Threshold: ${dynamicThreshold}.`, 'Proof Cycle');
        
        return finalConverged;
    }

    getState() {
        return {
            cycleIndex: this.cycleIndex,
            netWorthIndex: this.netWorthIndex,
            entropyRatio: this.entropyRatio,
            frameworks: this.frameworks,
            complexityScore: this.complexityScore,
            reasoningChain: this.reasoningChain
        };
    }
}

class WebDevOrchestrator {
    constructor(prompt, options) {
        this.initialPrompt = prompt;
        this.options = options;
        this.taskId = genRecursiveHash(prompt); 
        this.detectedFrameworks = this.detectFrameworksFromPrompt(prompt);
        this.proofTracker = new WebDevProofTracker(prompt, this.detectedFrameworks, this.taskId);
        this.modelPool = WEB_DEV_MODELS; 
        
        think(`Initialized orchestrator for task: ${prompt.substring(0, 100)}...`, 0);
        showReasoning(`Task ID (2π-indexed): ${this.taskId}`, 'Task ID Generation');
    }

    detectFrameworksFromPrompt(prompt) {
        think("Analyzing prompt for framework indicators...", 1);
        const frameworkKeywords = {
            react: ['react', 'jsx', 'component', 'hook'],
            vue: ['vue', 'composition api', 'vuex'],
            angular: ['angular', 'typescript', 'rxjs'],
            node: ['node', 'express', 'backend', 'api'],
            nextjs: ['next.js', 'nextjs', 'ssr'],
            python: ['python', 'flask', 'django', 'fastapi']
        };

        const detected = [];
        for (const [framework, keywords] of Object.entries(frameworkKeywords)) {
            if (keywords.some(keyword => prompt.toLowerCase().includes(keyword))) {
                detected.push(framework);
            }
        }
        
        const result = detected.length > 0 ? detected : ['node', 'react'];
        showReasoning(`Keywords found: ${Object.entries(frameworkKeywords).filter(([fw, keys]) => keys.some(k => prompt.toLowerCase().includes(k))).map(([fw]) => fw).join(', ')}`, 'Framework Detection');
        return result;
    }

    getEnhancedSystemPrompt(framework) {
        think(`Generating system prompt for ${framework}...`, 1);
        const basePrompt = `You are a ${framework} expert. Create production-ready code with best practices.`;
        
        const enhancedPrompt = `${basePrompt}
        
CRITICAL REQUIREMENTS:
- Generate COMPLETE, WORKING code - no placeholders or TODOs
- Include all necessary imports and dependencies
- Add proper error handling and validation
- Use modern ES6+ syntax and latest framework features
- Include responsive design considerations
- Add security best practices

User Task: `;

        showReasoning(`Framework: ${framework}\nPrompt length: ${enhancedPrompt.length} chars`, 'System Prompt');
        return enhancedPrompt;
    }

    async readProjectFile(filePath) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            think(`Successfully read file: ${filePath}`, 1);
            return `--- START FILE: ${filePath} ---\n${content}\n--- END FILE: ${filePath} ---\n\n`;
        } catch (error) {
            console.error(colors.redText(`[FILE ERROR] Could not read file ${filePath}: ${error.message}`));
            return `--- FILE READ ERROR: ${filePath} ---\n`;
        }
    }

    async runOllama(model, currentPrompt, framework, iteration) {
        return new Promise((resolve, reject) => {
            const enhancedPrompt = this.getEnhancedSystemPrompt(framework) + currentPrompt;
            
            // Log the start of the model's thinking process
            console.log(colors.blueText(`\n[${framework.toUpperCase()}-ITERATION-${iteration}]`), colors.yellowText(`${model} thinking...`));
            
            const command = `${OLLAMA_BIN} run ${model} "${enhancedPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(command);
            let output = '';
            
            child.on('error', (err) => {
                think(`Model ${model} encountered error: ${err.message}`, 2);
                reject(`OLLAMA EXECUTION ERROR: ${err.message}`);
            });
            
            child.stdout.on('data', data => {
                // Token Streaming Verbose Output
                if (VERBOSE_THINKING) {
                    process.stdout.write(colors.grayText(`  ${data}`));
                } else {
                    process.stdout.write(colors.grayText(data));
                }
                output += data;
            });
            
            child.stderr.on('data', data => {
                if (VERBOSE_THINKING) {
                    process.stderr.write(colors.redText(`  ERROR: ${data}`));
                } else {
                    process.stderr.write(colors.redText(data));
                }
            });
            
            child.on('close', code => {
                if (code !== 0) {
                    think(`Model ${model} exited with code ${code}`, 2);
                    return reject(`Model ${model} exited with code ${code}`);
                }
                
                think(`Model ${model} completed successfully`, 2);
                resolve(output.trim());
            });
        });
    }

    async recursiveConsensus() {
        think("Starting recursive consensus process (MAX PARALLELISM)...", 1);
        
        this.modelPool = await selectDynamicModels(this.detectedFrameworks[0] || 'node', this.proofTracker.complexityScore);
        
        let currentPrompt = this.initialPrompt;
        let lastFusedOutput = "";
        let converged = false;
        let bestFramework = this.detectedFrameworks[0] || 'node';

        for (let i = 0; i < 3 && !converged; i++) {
            think(`Consensus iteration ${i + 1}/3...`, 2);
            
            // MAX PARALLELISM: Launch all models simultaneously using Promise.all
            const promises = this.modelPool.map((model, index) => {
                return this.runOllama(model, currentPrompt, bestFramework, i + 1).catch(e => {
                    return e; // Capture error but don't stop Promise.all
                });
            });
            
            think("Waiting for all models to complete asynchronously...", 2);
            const results = await Promise.all(promises);
            const validResults = results.filter(r => 
                typeof r === 'string' && r.length > 0 && !r.startsWith('OLLAMA EXECUTION ERROR')
            );

            if (validResults.length === 0) {
                think("All models failed to produce valid output", 2);
                return "Error: All models failed. Please check Ollama installation and model availability.";
            }

            think(`Fusing ${validResults.length} valid outputs...`, 2);
            this.proofTracker.crosslineEntropy(validResults.join(''));
            const fusedOutput = this.fuseWebOutputs(validResults);
            
            const convergenceReasoning = `Iteration ${i + 1}: ${fusedOutput === lastFusedOutput ? 'Outputs converged' : 'Outputs still diverging'}`;
            const initialConverged = fusedOutput === lastFusedOutput;
            
            // Proof Cycle with Dynamic Math Logic
            converged = this.proofTracker.proofCycle(initialConverged, bestFramework, convergenceReasoning);
            
            if (converged) {
                think("Consensus achieved! Dynamic threshold met or outputs converged.", 2);
            } else {
                think("No consensus yet, continuing to next iteration...", 2);
            }

            lastFusedOutput = fusedOutput;
            currentPrompt = this.initialPrompt + `\n\nPrevious iteration output for improvement:\n${fusedOutput}`;
        }

        think("Consensus process completed", 1);
        await updateModelUsage(this.taskId, this.modelPool); 
        return lastFusedOutput;
    }

    fuseWebOutputs(results) {
        think(`Fusing ${results.length} model outputs...`, 2);
        
        const scoredResults = results.map(output => {
            let score = 0;
            const codeBlocks = (output.match(/```/g) || []).length / 2;
            score += codeBlocks * 10;
            score += Math.min(output.length / 100, 50);
            return { output, score };
        });
        
        scoredResults.sort((a, b) => b.score - a.score);
        const bestOutput = scoredResults.output;
        
        showReasoning(`Selected output with score ${scoredResults[0].score}`, 'Output Fusion');
        return bestOutput;
    }

    parseEnhancedCodeBlocks(content) {
        // CRITICAL FIX: Ensure content is a string before attempting to use it.
        if (typeof content !== 'string' || content.length === 0) {
            return [];
        }
        
        const regex = /```(\w+)\s*([\s\S]*?)```/g;
        const blocks = [];
        let match;
        
        while ((match = regex.exec(content)) !== null) {
            const language = match; // Capture group 1: language
            let code = match.trim(); // Capture group 2: code
            
            blocks.push({ 
                language: language, 
                code: code,
                framework: this.detectedFrameworks || 'node'
            });
        }
        
        if (blocks.length === 0 && content.trim().length > 0) {
            blocks.push({
                language: 'javascript',
                code: content.trim(),
                framework: this.detectedFrameworks || 'node'
            });
        }
        
        return blocks;
    }

    async handleFileModification(filePath, newContent) {
        think(`Applying modification to file: ${filePath}`, 1);
        try {
            fs.writeFileSync(filePath, newContent);
            console.log(colors.boldGreen(`[SUCCESS] MODIFIED FILE: ${filePath}`));
        } catch (error) {
            console.error(colors.redText(`[ERROR] Failed to modify file ${filePath}: ${error.message}`));
        }
    }

    async handleEnhancedCodeGeneration(content) {
        const blocks = this.parseEnhancedCodeBlocks(content);
        if (!blocks.length) {
            think("No code blocks found in output", 1);
            return;
        }

        // 1. Check for MODIFY_FILE directive
        const modifyRegex = /^\s*MODIFY_FILE:\s*([^\s]+)\s*$/m;
        const modifyMatch = content.match(modifyRegex);

        if (modifyMatch) {
            const targetPath = modifyMatch;
            const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
            const projectPath = path.join(PROJECTS_DIR, project);
            const fullPath = path.join(projectPath, targetPath);

            if (blocks.length === 1) {
                await this.handleFileModification(fullPath, blocks.code);
            } else {
                console.error(colors.redText(`[ERROR] MODIFY_FILE directive found, but output contains ${blocks.length} code blocks. Only one block is supported for modification.`));
            }
            return;
        }

        // 2. Default to NEW FILE generation
        const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
        const projectPath = path.join(PROJECTS_DIR, project);
        
        think(`Creating project directory: ${projectPath}`, 1);
        fs.mkdirSync(projectPath, { recursive: true });

        for (const [i, block] of blocks.entries()) {
            const ext = block.language === 'javascript' ? 'js' : 
                       block.language === 'typescript' ? 'ts' : 
                       block.language === 'python' ? 'py' : 
                       block.language === 'html' ? 'html' : 
                       block.language === 'css' ? 'css' : 'txt';
            
            const fileName = `file_${i}.${ext}`;
            const filePath = path.join(projectPath, fileName);
            
            fs.writeFileSync(filePath, block.code);
            console.log(colors.greenText(`[SUCCESS] Generated: ${filePath}`));
        }

        console.log(colors.cyanText(`\n🎉 Project ${project} created successfully!`));
        console.log(colors.cyanText(`📁 Location: ${projectPath}`));
    }

    async execute() {
        think("Starting WebDev AI execution...", 0);
        
        // 1. Read file content if --file option is present
        if (this.options.file) {
            const fileContent = await this.readProjectFile(this.options.file);
            this.initialPrompt = fileContent + this.initialPrompt;
            showReasoning(`Injected file content from: ${this.options.file}`, 'File Context');
        }

        console.log(colors.boldCyan("\n🚀 WEBDEV AI CODE ENGINE STARTING..."));
        console.log(colors.cyanText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
        
        const finalOutput = await this.recursiveConsensus();
        
        console.log(colors.boldGreen("\n✅ TASK COMPLETED SUCCESSFULLY"));
        console.log(colors.boldCyan("\n--- Final Web Development Output ---\n"));
        console.log(finalOutput);
        
        think("Saving results and generating code...", 1);
        await this.handleEnhancedCodeGeneration(finalOutput);
        
        console.log(colors.boldGreen("\n🎉 WEBDEV AI EXECUTION COMPLETED!"));
        console.log(colors.cyanText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
    }
}

// Enhanced CLI with verbose thinking
(async () => {
    const args = process.argv.slice(2);
    
    // Parse options and collect positional arguments
    const options = {};
    const positionalArgs = [];
    
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith('--')) {
            const parts = arg.slice(2).split('=');
            const key = parts;
            const value = parts.length > 1 ? parts.slice(1).join('=') : true;
            
            // Special handling for --file
            if (key === 'file' && typeof value === 'boolean') {
                options[key] = args[i + 1];
                i++; // Skip next argument
            } else {
                options[key] = value;
            }
        } else {
            positionalArgs.push(arg);
        }
    }
    
    const prompt = positionalArgs.join(' ');

    if (!prompt) {
        console.log(colors.redText('Error: No prompt provided. Usage: webdev-ai "create a react component for user dashboard"'));
        process.exit(1);
    }

    console.log(colors.boldMagenta("\n🧠 WEBDEV AI - VERBOSE THINKING MODE"));
    console.log(colors.magentaText("========================================\n"));
    
    const orchestrator = new WebDevOrchestrator(prompt, options);
    await orchestrator.execute();
})();
EOF_JS

    log_event "SUCCESS" "Enhanced orchestrator with dynamic math logic and max parallelism created"
}

# --- Code Processor Python Script (## NEW FILE ##) ---
setup_code_processor() {
    thinking "Setting up Python code processor..." 1
    cat > "$CODE_PROCESSOR_PY" <<'EOF_PY'
#!/usr/bin/env python3
import sys
import os
import subprocess
from pygments import highlight
from pygments.lexers import get_lexer_by_name, guess_lexer
from pygments.formatters import Terminal256Formatter

def run_formatter(tool, code):
    """Runs an external formatting tool on the code."""
    try:
        if tool == 'black':
            # Black is for Python
            process = subprocess.run(['black', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        elif tool == 'autopep8':
            # autopep8 is for Python
            process = subprocess.run(['autopep8', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        elif tool == 'shfmt':
            # shfmt is for shell scripts
            process = subprocess.run(['shfmt', '-i', '4', '-ci', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        # Add other formatters here (e.g., prettier for JS/TS/CSS)
        return code, None
    except subprocess.CalledProcessError as e:
        return code, f"Formatter {tool} failed: {e.stderr.decode('utf-8').strip()}"
    except FileNotFoundError:
        return code, f"Formatter {tool} not found. Skipping."
    except Exception as e:
        return code, f"Formatter {tool} error: {str(e)}"

def run_analysis(tool, file_path):
    """Runs a static analysis tool (like pylint) on the file."""
    try:
        if tool == 'pylint':
            # Pylint is for Python
            process = subprocess.run(['pylint', file_path], capture_output=True, check=False)
            # Filter out the summary and keep only the errors/warnings
            output = process.stdout.decode('utf-8')
            analysis_output = "\n".join([line for line in output.splitlines() if not line.startswith('---') and not line.startswith('Your code has been rated')])
            return analysis_output
        # Add other analyzers here (e.g., eslint)
        return ""
    except FileNotFoundError:
        return f"Analyzer {tool} not found. Skipping."
    except Exception as e:
        return f"Analyzer {tool} error: {str(e)}"

def process_code_file(file_path, file_extension):
    """Reads, formats, analyzes, and highlights a code file."""
    try:
        with open(file_path, 'r') as f:
            code = f.read()
    except Exception as e:
        print(f"\x1b[31m[ERROR] Could not read file: {file_path}. {str(e)}\x1b[0m", file=sys.stderr)
        return

    # 1. Determine Language and Lexer
    if file_extension == 'py':
        lang = 'python'
        formatter_tools = ['black', 'autopep8']
        analyzer_tools = ['pylint']
    elif file_extension == 'sh':
        lang = 'bash'
        formatter_tools = ['shfmt']
        analyzer_tools = []
    elif file_extension in ['js', 'ts', 'jsx', 'tsx', 'css', 'html']:
        lang = file_extension
        formatter_tools = [] # Prettier/ESLint would go here
        analyzer_tools = []
    else:
        lang = 'text'
        formatter_tools = []
        analyzer_tools = []

    # 2. Formatting
    formatted_code = code
    format_log = []
    for tool in formatter_tools:
        formatted_code, error = run_formatter(tool, formatted_code)
        if error:
            format_log.append(error)
        else:
            format_log.append(f"Formatter {tool} applied successfully.")

    # 3. Analysis
    analysis_log = []
    for tool in analyzer_tools:
        analysis_output = run_analysis(tool, file_path)
        if analysis_output:
            analysis_log.append(f"\x1b[1;33m--- {tool.upper()} ANALYSIS ---\x1b[0m\n{analysis_output}")

    # 4. Syntax Highlighting
    try:
        lexer = get_lexer_by_name(lang, stripall=True)
    except:
        lexer = guess_lexer(formatted_code)
        
    formatter = Terminal256Formatter(style='monokai')
    highlighted_code = highlight(formatted_code, lexer, formatter)

    # 5. Output Results
    print(f"\n\x1b[1;36m--- CODE ANALYSIS & FORMATTING REPORT ---\x1b[0m")
    print(f"\x1b[34mFile:\x1b[0m {file_path}")
    print(f"\x1b[34mLanguage:\x1b[0m {lang}")
    print(f"\x1b[34mFormatting Log:\x1b[0m {'; '.join(format_log)}")
    
    if analysis_log:
        print(f"\n\x1b[1;31m--- STATIC ANALYSIS FINDINGS ---\x1b[0m")
        print('\n'.join(analysis_log))
    
    print(f"\n\x1b[1;32m--- SYNTAX HIGHLIGHTED CODE ---\x1b[0m")
    print(highlighted_code)
    print(f"\x1b[1;36m-------------------------------------------\x1b[0m")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: code_processor.py <file_path> <file_extension>", file=sys.stderr)
        sys.exit(1)
    
    file_path = sys.argv
    file_extension = sys.argv
    
    process_code_file(file_path, file_extension)
EOF_PY
    chmod +x "$CODE_PROCESSOR_PY"
    log_event "SUCCESS" "Python code processor script created: $CODE_PROCESSOR_PY"
}

# --- Installation Function (## MODIFIED ##) ---
install_webdev_ai() {
    echo -e "\n${COLOR_BRIGHT}${COLOR_CYAN}🚀 INSTALLING WEBDEV AI CODE ENGINE${COLOR_RESET}"
    echo -e "${COLOR_GRAY}=========================================${COLOR_RESET}"
    
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR" "$LOG_DIR"
    
    check_dependencies
    init_databases
    setup_orchestrator
    setup_code_processor # ## NEW: Install Python script ##
    
    echo -e "\n${COLOR_BRIGHT}${COLOR_GREEN}✅ INSTALLATION COMPLETED SUCCESSFULLY!${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT}${COLOR_YELLOW}💡 Usage examples:${COLOR_RESET}"
    echo "  webdev-ai 'create a React component for user dashboard'"
    echo "  webdev-ai --start my-project"
    echo "  webdev-ai status"
    echo "  webdev-ai --verbose  # Toggle thinking mode"
}

# --- Main Enhanced Execution ---
main() {
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR"
    
    check_dependencies
    init_databases
    setup_orchestrator
    
    # Ensure the code processor is available before running tasks
    if [ ! -f "$CODE_PROCESSOR_PY" ]; then
        setup_code_processor
    fi

    if [ $# -eq 0 ]; then
        enhanced_status
        exit 0
    fi

    COMMAND="$1"
    shift

    case "$COMMAND" in
        --start)
            read -p "Project/Repo name: " proj
            echo "$proj" > "$SESSION_FILE"
            log_event "SESSION" "Started web development session for $proj"
            thinking "Session started for project: $proj" 0
            ;;
        --stop)
            [ -f "$SESSION_FILE" ] && proj=$(cat "$SESSION_FILE") && log_event "SESSION" "Stopped session for $proj"
            rm -f "$SESSION_FILE"
            thinking "Session stopped" 0
            ;;
        --verbose|--think)
            toggle_verbose
            ;;
        --quiet)
            export VERBOSE_THINKING="false"
            export SHOW_REASONING="false"
            echo "Verbose thinking: DISABLED"
            ;;
        --install)
            install_webdev_ai
            ;;
        run)
            run_webdev_task "$@"
            ;;
        status)
            enhanced_status
            ;;
        --create-component)
            run_webdev_task "Create a React/Vue component for: $@"
            ;;
        --create-api)
            run_webdev_task "Create a Node.js/Express API endpoint for: $@"
            ;;
        *)
            run_webdev_task "$COMMAND $@"
            ;;
    esac
}

# --- Execute Main Function ---
main "$@"
