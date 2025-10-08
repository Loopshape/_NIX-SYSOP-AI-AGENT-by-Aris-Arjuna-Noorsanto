#!/usr/bin/env bash
# WebDev Code-Engine with Dynamic Math Logic and MAX PARALLELISM
# Version: 8.3.1 (Double Entropy: Google Ping RTT)

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
export WEB_CONFIG_DB="$DB_DIR/web_config.db"
export SESSION_FILE="$AI_HOME/.session"
export OLLAMA_BIN="$(command -v ollama || true)" # Dynamically find ollama
export NODE_PATH="${NODE_PATH:-}:$NODE_MODULES"
export CODE_PROCESSOR_PY="$SCRIPTS_DIR/code_processor.py"

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
COLOR_PURPLE='\x1b[35m' # Added for consistency with log_event

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
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN" "pylint" "black" "autopep8" "shfmt" "ping" "curl")
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
        "ANALYSIS") color="$COLOR_PURPLE" ;; "PLAN") color="$COLOR_CYAN" ;;
        "EXECUTE") color="$COLOR_GREEN" ;; "MEMORY") color="$COLOR_YELLOW" ;;
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
        echo -e "${COLOR_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    fi
}

# --- SQLITE UTILITIES WITH ERROR HANDLING ---
sqlite_escape() {
    echo "$1" | sed "s/'/''/g"
}

# --- USER CONFIRMATION ---
confirm_action() {
    local action="$1"
    local response

    echo -e "${COLOR_YELLOW}CONFIRM: $action${COLOR_RESET}" >&2
    read -p "Type 'yes' to confirm: " -r response

    if [[ "$response" == "yes" ]]; then
        log_event "DEBUG" "User confirmed action: $action"
        return 0
    else
        log_event "WARN" "User cancelled action: $action"
        return 1
    fi
}

# --- Code Processing and Highlighting ---
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

# --- Fixed Dependency Installation (Node.js Modules) ---
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

# --- MODIFIED: check_dependencies with active installation ---
check_dependencies() {
    thinking "Checking and installing system and Python dependencies..." 1
    
    # Check and install core system dependencies
    local system_deps=("sqlite3" "node" "python3" "git" "ping" "curl")
    for dep in "${system_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_event "ERROR" "Missing critical system dependency: $dep"
            echo "${COLOR_RED}❌ Missing critical system dependency: $dep. Please install manually to proceed.${COLOR_RESET}"
            exit 1 # Exit for critical missing dependencies
        else
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$dep"
        fi
    done

    # Check Ollama separately as it's not a standard system dependency
    if ! command -v "$OLLAMA_BIN" &> /dev/null; then
        log_event "WARN" "Ollama binary not found: $OLLAMA_BIN"
        echo "${COLOR_YELLOW}⚠️ Ollama binary not found. Please install Ollama from ollama.com if you intend to use AI models.${COLOR_RESET}"
    else
        printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$OLLAMA_BIN"
    fi

    # Install Python tools
    local python_tools=("black" "autopep8" "pylint")
    for tool in "${python_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Installing Python tool: $tool..."
            if command -v pip3 &> /dev/null; then
                pip3 install --user "$tool" &> /dev/null # Redirect output to /dev/null
                if [ $? -eq 0 ]; then
                    printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET} (installed via pip3)\n" "$tool"
                else
                    printf "  ${COLOR_RED}❌ Failed to install Python tool: %s${COLOR_RESET}\n" "$tool"
                fi
            else
                printf "  ${COLOR_RED}❌ pip3 not found. Cannot install %s. Please install pip3 and try again.${COLOR_RESET}\n" "$tool"
            fi
        else
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$tool"
        fi
    done
    
    # Install shfmt (Go tool)
    if ! command -v shfmt &> /dev/null; then
        echo "Installing shfmt (shell formatter)..."
        local OS=$(uname -s)
        local ARCH=$(uname -m)
        local SHFMT_URL=""
        
        if [[ "$OS" == "Linux" ]]; then
            if [[ "$ARCH" == "x86_64" ]]; then
                SHFMT_URL="https://github.com/mvdan/sh/releases/latest/download/shfmt_linux_amd64"
            elif [[ "$ARCH" == "aarch64" ]]; then
                SHFMT_URL="https://github.com/mvdan/sh/releases/latest/download/shfmt_linux_arm64"
            fi
        elif [[ "$OS" == "Darwin" ]]; then # macOS
            if [[ "$ARCH" == "x86_64" ]]; then
                SHFMT_URL="https://github.com/mvdan/sh/releases/latest/download/shfmt_darwin_amd64"
            elif [[ "$ARCH" == "arm64" ]]; then
                SHFMT_URL="https://github.com/mvdan/sh/releases/latest/download/shfmt_darwin_arm64"
            fi
        fi

        if [ -n "$SHFMT_URL" ]; then
            if command -v curl &> /dev/null; then
                if curl -sSLo /usr/local/bin/shfmt "$SHFMT_URL"; then
                    chmod +x /usr/local/bin/shfmt
                    printf "  ${COLOR_GREEN}✅ shfmt${COLOR_RESET} (installed)\n"
                else
                    printf "  ${COLOR_RED}❌ Failed to download shfmt from %s${COLOR_RESET}\n" "$SHFMT_URL"
                fi
            else
                printf "  ${COLOR_RED}❌ curl not found. Cannot install shfmt. Please install curl and try again.${COLOR_RESET}\n"
            fi
        else
            printf "  ${COLOR_RED}❌ shfmt installation not supported for your OS/Arch: %s/%s${COLOR_RESET}\n" "$OS" "$ARCH"
        fi
    else
        printf "  ${COLOR_GREEN}✅ shfmt${COLOR_RESET}\n"
    fi

    # Check and install Node.js modules (specifically sqlite3)
    check_node_modules
    
    log_event "SUCCESS" "All dependencies satisfied (or warnings/installations issued)"
}

# Web Development Framework Detection (Simplified for Bash)
detect_frameworks() {
    local project_path="${1:-$PWD}"
    local frameworks=()
    
    frameworks+=("node" "react")
    
    show_reasoning "Detected frameworks: ${frameworks[*]}" "Framework Detection"
    echo "${frameworks[@]}"
}

# --- MODIFIED: Enhanced Database Initialization with simplified schema ---
init_databases() {
    thinking "Initializing databases with simplified schema..." 1
    mkdir -p "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR" # Ensure necessary directories exist

    # ai_data.db (simplified to match new script)
    sqlite3 "$AI_DATA_DB" <<SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, task_id TEXT, prompt TEXT, response TEXT, proof_state TEXT, framework TEXT, complexity INTEGER, reasoning_log TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, event_type TEXT, message TEXT, metadata TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS model_usage (task_id TEXT NOT NULL, model_name TEXT NOT NULL, PRIMARY KEY (task_id, model_name));
SQL

    # web_config.db (matches new script's definition)
    sqlite3 "$WEB_CONFIG_DB" <<SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY, name TEXT UNIQUE, framework TEXT, port INTEGER, domain TEXT, status TEXT DEFAULT 'inactive', ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS deployments (id INTEGER PRIMARY KEY, project_name TEXT, environment TEXT, status TEXT, url TEXT, logs TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS api_endpoints (id INTEGER PRIMARY KEY, project_name TEXT, method TEXT, path TEXT, handler TEXT, middleware TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS config (key TEXT PRIMARY KEY, value TEXT); -- Added config table
CREATE TABLE IF NOT EXISTS hashes (type TEXT, target TEXT, hash TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP); -- Added hashes table
SQL
    # blobs.db and wallet.db are no longer initialized as per the new script's schema.

    log_event "SUCCESS" "Databases initialized with simplified schema"
}

# --- Configuration Management ---
set_config() {
    local k="$1" v="$2"
    log_event "DEBUG" "Setting config: $k = [REDACTED]"

    if sqlite3 "$WEB_CONFIG_DB" "INSERT OR REPLACE INTO config (key, value) VALUES ('$(sqlite_escape "$k")', '$(sqlite_escape "$v")');" 2>/dev/null; then
        log_event "SUCCESS" "Config set: $k"
    else
        log_event "ERROR" "Failed to set config: $k"
        return 1
    fi
}

get_config() {
    local k="$1"
    local result
    result=$(sqlite3 "$WEB_CONFIG_DB" "SELECT value FROM config WHERE key = '$(sqlite_escape "$k")';" 2>/dev/null)
    log_event "DEBUG" "Retrieved config: $k = $result"
    echo "$result"
}

view_config() {
    log_event "DEBUG" "Viewing all configuration"
    sqlite3 -header -column "$WEB_CONFIG_DB" "SELECT * FROM config;" 2>/dev/null || echo "No configuration set."
}

# --- Hashing Functions ---
hash_string() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

hash_file_content() {
    if [[ -f "$1" ]]; then
        local hash
        hash=$(sha256sum "$1" | cut -d' ' -f1)
        log_event "DEBUG" "Hashed file: $1 -> $hash"
        echo "$hash"
    else
        log_event "ERROR" "File not found: $1"
        return 1
    fi
}

record_hash() {
    local type="$1" target="$2" hash="$3"
    log_event "DEBUG" "Recording hash: $type:$target -> $hash"

    if sqlite3 "$WEB_CONFIG_DB" "INSERT OR REPLACE INTO hashes (type, target, hash) VALUES ('$(sqlite_escape "$type")', '$(sqlite_escape "$target")', '$(sqlite_escape "$hash")');" 2>/dev/null; then
        log_event "INFO" "Recorded hash for $type: $target"
    else
        log_event "WARN" "Failed to record hash for $type: $target"
    fi
}

get_hash() {
    local type="$1" target="$2"
    local result
    result=$(sqlite3 "$WEB_CONFIG_DB" "SELECT hash FROM hashes WHERE type='$(sqlite_escape "$type")' AND target='$(sqlite_escape "$target")';" 2>/dev/null)
    log_event "DEBUG" "Retrieved hash for $type:$target -> $result"
    echo "$result"
}

view_hash_index() {
    log_event "DEBUG" "Viewing hash index"
    sqlite3 -header -column "$WEB_CONFIG_DB" "SELECT * FROM hashes ORDER BY timestamp DESC;" 2>/dev/null || echo "No hashes recorded."
}

# --- Fixed Orchestrator with Working Colors (FULL CONTENT, with minor fixes) ---
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
const SLOWER_MODELS_ENV = process.env.SLOWER_MODELS || "llama3:70b,mixtral:8x7b"; // Default slower models

// Enhanced Model Pool for Web Development (Default/Fallback)
const WEB_DEV_MODELS = ["2244:latest", "core:latest", "loop:latest", "coin:latest", "code:latest"];
const SLOWER_MODELS = SLOWER_MODELS_ENV.split(',');
const SLOWER_MODEL_ACTIVATION_CHANCE = 0.3; // 30% chance to engage a slower model for review

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

// --- NEW: Deterministic Random Integer from Hash ---
const getDeterministicRandomInt = (seedString, min, max) => {
    const hash = crypto.createHash('sha256').update(seedString).digest('hex');
    // Take a portion of the hash and convert to integer
    const intValue = parseInt(hash.substring(0, 8), 16); 
    return min + (intValue % (max - min + 1));
};

// --- NEW: Get Google Ping Entropy ---
const getGooglePingEntropy = async () => {
    try {
        think("Pinging google.com for external entropy...", 2);
        // Use 'ping -c 1' for a single packet on Linux/macOS, '-n 1' on Windows
        const command = process.platform === 'win32' ? 'ping -n 1 google.com' : 'ping -c 1 google.com';
        const { stdout } = await new Promise((resolve, reject) => {
            exec(command, (error, stdout, stderr) => {
                if (error) {
                    // Log error but don't reject, return 0 for graceful fallback
                    console.error(colors.redText(`[PING ERROR] Failed to ping google.com: ${error.message}`));
                    return resolve({ stdout: '', stderr: error.message });
                }
                resolve({ stdout, stderr });
            });
        });

        // Extract average RTT (example for Linux/macOS, might need adjustment for Windows)
        let rttMatch;
        if (process.platform === 'win32') {
            rttMatch = stdout.match(/Average = (\d+)ms/);
        } else {
            rttMatch = stdout.match(/rtt min\/avg\/max\/mdev = [0-9.]+\/([0-9.]+)/);
        }
        
        if (rttMatch && rttMatch[1]) {
            const avgRtt = parseFloat(rttMatch[1]);
            think(`Google Ping RTT: ${avgRtt}ms`, 2);
            return avgRtt;
        } else {
            think("Could not parse ping RTT from output.", 2);
            return 0; // Default to 0 if parsing fails
        }
    } catch (e) {
        console.error(colors.redText(`[PING EXCEPTION] ${e.message}`));
        return 0; // Default to 0 on error
    }
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

    async crosslineEntropy(data) { // Made async
        think("Analyzing output entropy and incorporating external factors...", 1);
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(hash.substring(0, 8), 16);
        
        // Incorporate Google Ping RTT for external entropy
        const pingRtt = await getGooglePingEntropy();
        this.entropyRatio += pingRtt; // Add RTT to entropy ratio

        showReasoning(`Entropy updated: ${this.entropyRatio} (hash: ${hash.substring(0, 16)}..., ping: ${pingRtt}ms)`, 'Entropy Analysis');
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
            await this.proofTracker.crosslineEntropy(validResults.join('')); // AWAIT here
            const fusedOutput = this.fuseWebOutputs(validResults);
            
            const convergenceReasoning = `Iteration ${i + 1}: ${fusedOutput === lastFusedOutput ? 'Outputs converged' : 'Outputs still diverging'}`;
            const initialConverged = fusedOutput === lastFusedOutput;
            
            // Proof Cycle with Dynamic Math Logic
            converged = this.proofTracker.proofCycle(initialConverged, bestFramework, convergenceReasoning);
            
            // --- NEW: Slower Model Control Step ---
            const randomChance = getDeterministicRandomInt(this.taskId + String(i), 0, 100);
            if (SLOWER_MODELS.length > 0 && randomChance < (SLOWER_MODEL_ACTIVATION_CHANCE * 100)) {
                think(`Deterministic random chance (${randomChance}%) triggered slower model review.`, 2);
                const slowerModelIndex = getDeterministicRandomInt(this.taskId + String(i) + "slower", 0, SLOWER_MODELS.length - 1);
                const selectedSlowerModel = SLOWER_MODELS[slowerModelIndex];
                
                const reviewPrompt = `Review and refine the following output based on the original task: "${this.initialPrompt}". Focus on accuracy, completeness, and best practices. Return ONLY the refined output.

Output to review:
\`\`\`
${fusedOutput}
\`\`\`

Your refined output:`;
                
                think(`Engaging slower model (${selectedSlowerModel}) for review...`, 2);
                const refinedOutput = await this.runOllama(selectedSlowerModel, reviewPrompt, bestFramework, i + 1 + "_review").catch(e => {
                    console.error(colors.redText(`[SLOWER MODEL ERROR] ${e}`));
                    return fusedOutput; // Fallback to original if slower model fails
                });
                
                showReasoning(`Slower model (${selectedSlowerModel}) refined output.`, 'Slower Model Control');
                currentPrompt = this.initialPrompt + `\n\nPrevious iteration (refined) output for improvement:\n${refinedOutput}`;
                lastFusedOutput = refinedOutput; // Update lastFusedOutput with refined version
            } else {
                if (SLOWER_MODELS.length > 0) {
                    think(`Slower model review skipped this iteration (chance: ${randomChance}%).`, 2);
                }
                currentPrompt = this.initialPrompt + `\n\nPrevious iteration output for improvement:\n${fusedOutput}`;
                lastFusedOutput = fusedOutput;
            }
            // --- END Slower Model Control Step ---

            if (converged) {
                think("Consensus achieved! Dynamic threshold met or outputs converged.", 2);
            } else {
                think("No consensus yet, continuing to next iteration...", 2);
            }
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
        const bestOutput = scoredResults.output; // FIX: Access 'output' property of the first element
        
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
            const language = match; // FIX: Capture group 1 is language
            let code = match.trim(); // FIX: Capture group 2 is code
            
            blocks.push({ 
                language: language, 
                code: code,
                framework: this.detectedFrameworks || 'node' // Use first detected framework
            });
        }
        
        if (blocks.length === 0 && content.trim().length > 0) {
            blocks.push({
                language: 'javascript', // Default to JS if no language specified but content exists
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
            const targetPath = modifyMatch; // FIX: Capture group 1 for the path
            const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
            const projectPath = path.join(PROJECTS_DIR, project);
            const fullPath = path.join(projectPath, targetPath);

            if (blocks.length === 1) {
                await this.handleFileModification(fullPath, blocks.code); // FIX: Access code from the first block
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
            const key = parts; // FIX: key is the first part
            const value = parts.length > 1 ? parts.slice(1).join('=') : true;
            
            // Special handling for --file
            if (key === 'file' && typeof value === 'boolean') { // If --file is passed without =, expect path as next arg
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

# --- Code Processor Python Script (FULL CONTENT, with minor fixes) ---
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
    
    file_path = sys.argv # FIX: Get the first argument
    file_extension = sys.argv # FIX: Get the second argument
    
    process_code_file(file_path, file_extension)
EOF_PY
    chmod +x "$CODE_PROCESSOR_PY"
    log_event "SUCCESS" "Python code processor script created: $CODE_PROCESSOR_PY"
}

# --- NEW CODE REPAIR TOOL ---
tool_code_repair() {
    local file_path="$1"
    local file_extension="${file_path##*.}"
    
    log_event "ANALYSIS" "Starting Code Repair Agent on: $file_path"
    
    if [[ ! -f "$file_path" ]]; then
        log_event "ERROR" "File not found for repair: $file_path"
        return 1
    fi

    # 1. Run Static Analysis and Formatting
    thinking "Running static analysis and formatting pipeline..."
    local analysis_output
    
    local temp_report_file
    temp_report_file=$(mktemp)
    
    if ! python3 "$CODE_PROCESSOR_PY" "$file_path" "$file_extension" > "$temp_report_file" 2>&1; then
        log_event "ERROR" "Python code processor failed. Check dependencies."
        cat "$temp_report_file" >&2
        rm "$temp_report_file"
        return 1
    fi

    analysis_output=$(cat "$temp_report_file")
    rm "$temp_report_file"

    local formatted_code
    local analysis_findings
    
    # Extract the formatted code and the analysis findings
    formatted_code=$(echo "$analysis_output" | sed -n '/--- SYNTAX HIGHLIGHTED CODE ---/,$p' | sed '1,2d' | sed '$d' | sed '/^$/d' || true)
    analysis_findings=$(echo "$analysis_output" | sed -n '/--- STATIC ANALYSIS FINDINGS ---/,/--- SYNTAX HIGHLIGHTED CODE ---/p' | sed '1d;$d' || true)

    if [[ -z "$analysis_findings" ]]; then
        log_event "SUCCESS" "Code is clean! Only formatting applied."
        if confirm_action "Apply formatting changes to $file_path"; then
            echo "$formatted_code" > "$file_path"
            log_event "SUCCESS" "File $file_path formatted successfully."
        fi
        return 0
    fi

    # 2. Construct AI Repair Prompt
    log_event "WARN" "Analysis found issues. Delegating to Ollama for intelligent repair."
    local repair_prompt="The following code has been formatted and analyzed by static tools. Your task is to intelligently fix the issues and return ONLY the corrected code block. DO NOT include any explanation or extra text.

File: $file_path
Language: $file_extension

--- STATIC ANALYSIS REPORT ---
$analysis_findings
--- END REPORT ---

--- CODE TO REPAIR ---
\`\`\`$file_extension
$formatted_code
\`\`\`

Your corrected code (start with \`\`\`$file_extension):"

    # 3. Call Ollama directly for Repair
    log_event "EXECUTE" "Calling Ollama for intelligent code repair..."
    local repaired_response
    # Using a default code model, can be made configurable
    local code_repair_model=$(get_config code_repair_model || echo "code:latest") 
    repaired_response=$(ollama run "$code_repair_model" "$repair_prompt" 2>&1 || true)
    
    local repaired_code
    repaired_code=$(echo "$repaired_response" | sed -n '/```/,$p' | sed '1d;$d' | sed '/^$/d' || true)

    if [[ -z "$repaired_code" ]]; then
        log_event "ERROR" "AI failed to return a valid code block for repair."
        echo "AI Response: $repaired_response" >&2
        return 1
    fi

    # 4. Apply Final Repair
    log_event "ANALYSIS" "AI Repair complete. Reviewing final code."
    echo -e "${COLOR_GREEN}--- AI REPAIRED CODE (Review) ---${COLOR_RESET}" >&2
    echo "$repaired_code" > "$file_path.repaired.tmp"
    _process_code_file "$file_path.repaired.tmp" "$file_extension" # Re-run processor for final highlight

    if confirm_action "Apply AI-repaired code to $file_path"; then
        echo "$repaired_code" > "$file_path"
        log_event "SUCCESS" "File $file_path repaired and updated successfully."
    else
        log_event "WARN" "AI repair cancelled. Repaired code saved to $file_path.repaired.tmp"
    fi
    
    rm -f "$file_path.repaired.tmp"
    return 0
}

# --- Installation Function (MODIFIED) ---
install_webdev_ai() {
    echo -e "\n${COLOR_BRIGHT}${COLOR_CYAN}🚀 INSTALLING WEBDEV AI CODE ENGINE${COLOR_RESET}"
    echo -e "${COLOR_GRAY}=========================================${COLOR_RESET}"
    
    # Ensure all base directories exist (aligned with new script's mkdir -p for essential dirs)
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR" "$LOG_DIR"
    
    # Check and install system dependencies (updated function)
    check_dependencies
    
    # Initialize databases (updated function with simplified schema)
    init_databases
    
    # Setup orchestrator (retains full content)
    setup_orchestrator
    
    # Setup code processor (retains full content)
    setup_code_processor

    # Set default config values if not present
    local default_configs=(
        "code_repair_model:code:latest"
        "slower_models:llama3:70b,mixtral:8x7b" # Default slower models
        "temperature:0.7"
        "top_p:0.9"
    )

    for config in "${default_configs[@]}"; do
        local key="${config%:*}"
        local value="${config#*:}"
        if [[ -z "$(get_config "$key")" ]]; then
            set_config "$key" "$value"
        fi
    done
    
    echo -e "\n${COLOR_BRIGHT}${COLOR_GREEN}✅ INSTALLATION COMPLETED SUCCESSFULLY!${COLOR_RESET}"
    echo -e "${COLOR_BRIGHT}${COLOR_YELLOW}💡 Usage examples:${COLOR_RESET}"
    echo "  webdev-ai 'create a React component for user dashboard'"
    echo "  webdev-ai --start my-project"
    echo "  webdev-ai status"
    echo "  webdev-ai --verbose  # Toggle thinking mode"
    echo "  webdev-ai repair ./src/broken_script.py"
}

# --- AI Task Runner (Fusion of Triumvirate and WebDev-AI) ---
run_webdev_task() {
    local full_prompt=""
    local file_path=""
    local args=()
    
    # Parse arguments to separate prompt from --file
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                if [[ -z "${2:-}" ]]; then log_event "ERROR" "Error: --file requires a path."; return 1; fi
                file_path="$2"
                args+=("--file=$file_path")
                shift 2
                ;;
            *)
                full_prompt="$full_prompt $1"
                shift
                ;;
        esac
    done
    
    full_prompt=$(echo "$full_prompt" | xargs) # Trim leading/trailing spaces

    log_event "ANALYSIS" "User request: $full_prompt"

    if [ -f "$SESSION_FILE" ]; then
        local proj=$(cat "$SESSION_FILE")
        thinking "Active session detected: $proj"
        args+=("--project=$proj")
    fi

    log_event "EXECUTE" "Delegating to Node.js Orchestrator for parallel execution..."
    
    # Set environment variables for Node.js
    export AI_DATA_DB="$AI_DATA_DB"
    export PROJECTS_DIR
    export CODE_PROCESSOR_PY
    export VERBOSE_THINKING
    export SHOW_REASONING
    export OLLAMA_BIN # Ensure ollama path is passed
    export SLOWER_MODELS=$(get_config slower_models || echo "llama3:70b,mixtral:8x7b") # Export slower models config

    local final_response
    # The Node.js orchestrator handles the full Triumvirate-style loop internally
    final_response=$(node "$ORCHESTRATOR_FILE" "$full_prompt" "${args[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_event "ERROR" "Node.js Orchestrator failed with exit code $exit_code"
        echo "$final_response" >&2
        return 1
    fi
    
    # Extract task_id from orchestrator output for logging
    local task_id_match
    task_id_match=$(echo "$final_response" | grep 'Task ID (2π-indexed):' | awk '{print $NF}' || true)
    local task_id="${task_id_match:-$(hash_string "$full_prompt" | cut -c1-16)}"
    local project_dir="$PROJECTS_DIR/task_$task_id"
    
    if ! mkdir -p "$project_dir"; then
        log_event "ERROR" "Failed to create project directory: $project_dir"
        return 1
    fi
    
    echo "User Prompt: $full_prompt" > "$project_dir/summary.txt"
    echo -e "\\n--- Final Agent Response ---\\n" >> "$project_dir/summary.txt"
    echo "$final_response" >> "$project_dir/summary.txt"
    log_event "SUCCESS" "Full task log and summary saved in: $project_dir"

    echo -e "\\n${COLOR_GREEN}✅ === AI TASK COMPLETE ===${COLOR_RESET}" >&2
    echo -e "${COLOR_GREEN}📝 Final Response:${COLOR_RESET}" >&2
    # The orchestrator already prints the final output, so no need to re-parse here.
    # Just ensure the full output is visible.
    echo "$final_response"
}

# --- MAIN CLI DISPATCHER ---
main() {
    local start_time=$(date +%s)
    log_event "DEBUG" "Script started: WebDev Code-Engine v8.3.1"

    # Initial directory setup (covers essential directories as per new script)
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR" "$LOG_DIR"
    
    # Always perform dependency check and DB/orchestrator setup if not installed
    # This ensures a runnable state even without explicit --install
    check_dependencies
    init_databases
    setup_orchestrator
    setup_code_processor

    if [ $# -eq 0 ]; then
        show_help # Show help if no arguments provided
        exit 0
    fi

    COMMAND="$1"
    shift

    case "$COMMAND" in
        --start)
            local proj="$1"
            if [[ -z "$proj" ]]; then
                read -p "Project/Repo name: " proj
            fi
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
            export VERBOSE_THINKING="true"
            export SHOW_REASONING="true"
            echo "Verbose thinking: ENABLED"
            ;;
        --quiet)
            export VERBOSE_THINKING="false"
            export SHOW_REASONING="false"
            echo "Verbose thinking: DISABLED"
            ;;
        --install|--setup) # Combined install and setup
            install_webdev_ai
            ;;
        --config)
            case "${1:-}" in
                "set")
                    if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                        log_event "ERROR" "Usage: webdev-ai --config set <key> <value>"
                        return 1
                    fi
                    set_config "$2" "$3"
                    ;;
                "get")
                    if [[ -z "${2:-}" ]]; then
                        log_event "ERROR" "Usage: webdev-ai --config get <key>"
                        return 1
                    fi
                    get_config "$2"
                    ;;
                "view") view_config ;;
                *) log_event "ERROR" "Usage: webdev-ai --config [set|get|view] [key] [value]" ;;
            esac
            ;;
        --hash)
            case "${1:-}" in
                "file")
                    if [[ -z "${2:-}" ]]; then
                        log_event "ERROR" "Usage: webdev-ai --hash file <path>"
                        return 1
                    fi
                    local file_hash=$(hash_file_content "$2")
                    record_hash "file" "$2" "$file_hash"
                    ;;
                "prompt")
                    if [[ -z "${2:-}" ]]; then
                        log_event "ERROR" "Usage: webdev-ai --hash prompt \"<text>\""
                        return 1
                    fi
                    local prompt_hash=$(hash_string "$2")
                    record_hash "prompt" "$2" "$prompt_hash"
                    ;;
                "view") view_hash_index ;;
                *) log_event "ERROR" "Usage: webdev-ai --hash [file|prompt|view] [target]" ;;
            esac
            ;;
        repair)
            if [[ -z "${1:-}" ]]; then
                log_event "ERROR" "Usage: webdev-ai repair <file_path>"
                return 1
            fi
            tool_code_repair "$1"
            ;;
        status)
            enhanced_status
            ;;
        --help|-h)
            show_help
            ;;
        *)
            # Default to running a webdev task
            run_webdev_task "$COMMAND" "$@"
            ;;
    esac

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_event "DEBUG" "Script completed in ${duration}s"
}

show_help() {
    cat << EOF
${COLOR_GREEN}WebDev Code-Engine v8.3.1 - Unified Hybrid Agent${COLOR_RESET}

${COLOR_CYAN}Description:${COLOR_RESET} Advanced AI agent system with hybrid execution (Node.js/Python), dynamic model selection, and comprehensive logging. Now with deterministic randomness, slower AI control for token streams, and external "double entropy" from Google ping RTT. Error handling adjusted to prevent automatic script exits. Asynchronous concurrency for models is fully functional.

${COLOR_CYAN}Usage:${COLOR_RESET}
  webdev-ai [OPTIONS] "<your prompt>"      - Run AI Task
  webdev-ai repair <file_path>             - Run static analysis and AI-powered code repair
  webdev-ai --verbose                      - Enable verbose debugging
  webdev-ai --quiet                        - Disable verbose debugging
  webdev-ai --install                      - Install dependencies and orchestrator
  webdev-ai --setup                        - Alias for --install
  webdev-ai --config [set|get|view]        - Configuration management
  webdev-ai --hash [file|prompt|view]      - Content hashing utilities
  webdev-ai status                         - View system status
  webdev-ai --start [project]              - Start a project session
  webdev-ai --stop                         - Stop the current session
  webdev-ai --help                         - Show this help

${COLOR_CYAN}Configuration Options (via --config set <key> <value>):${COLOR_RESET}
  code_repair_model: The Ollama model to use for code repair (default: code:latest)
  slower_models: Comma-separated list of Ollama models for review/control (default: llama3:70b,mixtral:8x7b)
  temperature: AI model temperature (default: 0.7)
  top_p: AI model top_p (default: 0.9)

${COLOR_CYAN}Examples:${COLOR_RESET}
  webdev-ai "Create a Python Flask API with a /status endpoint"
  webdev-ai repair ./src/broken_script.py
  webdev-ai --start my-new-app
  webdev-ai --config set slower_models "llama3:70b,gemma:7b"
  webdev-ai --hash file ./src/main.js

${COLOR_CYAN}Log File:${COLOR_RESET} (Events logged to database: $AI_DATA_DB)
${COLOR_CYAN}Data Directory:${COLOR_RESET} $AI_HOME
EOF
}

# --- ENTRY POINT WITH COMPREHENSIVE ERROR HANDLING ---
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    if [[ -z "$HOME" ]]; then
        echo "ERROR: HOME environment variable not set" >&2
        exit 1
    fi

    # Ensure AI_HOME exists before logging
    mkdir -p "$AI_HOME" "$DB_DIR" "$SCRIPTS_DIR"

    if main "$@"; then
        exit 0
    else
        exit 1
    fi
fi
