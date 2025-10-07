#!/usr/bin/env bash
# AI DevOps Platform v10.4 - Unified Hybrid Agent
# Fusion of Triumvirate CLI/Logging and WebDev-AI Execution/Self-Optimization.
# Version 10.4.4 (Final Function Scoping Fix)

set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION (Unified Paths) ---
SCRIPT_NAME="ai"
SCRIPT_VERSION="10.4.4"
AI_HOME="${AI_HOME:-$HOME/.ai_agent}"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/ai_projects}"
SSH_DIR="$HOME/.ssh"
GIT_SSH_KEY="$SSH_DIR/id_ai_agent"
LOG_FILE="$AI_HOME/ai.log"

# WebDev-AI specific paths (Integrated)
DB_DIR="$AI_HOME/db"
SCRIPTS_DIR="$AI_HOME/scripts"
ORCHESTRATOR_FILE="$AI_HOME/orchestrator.mjs"
CODE_PROCESSOR_PY="$SCRIPTS_DIR/code_processor.py"
NODE_MODULES="$AI_HOME/node_modules"
NODE_PATH="${NODE_PATH:-}:$NODE_MODULES"
AI_DATA_DB="$DB_DIR/ai_data.db"
BLOBS_DB="$DB_DIR/blobs.db"
WEB_CONFIG_DB="$DB_DIR/web_config.db"
SESSION_FILE="$AI_HOME/.session"

# Triumvirate specific paths (Integrated)
MEMORY_DB="$AI_DATA_DB" # MEMORY_DB is now AI_DATA_DB
HASH_INDEX_DB="$AI_HOME/hashes.db"
POOL_INDEX_DB="$AI_HOME/pool_index.db"
API_LOGS_DB="$AI_HOME/api_logs.db"
CONFIG_DB="$AI_HOME/config.db"

# Default Worker Models (Used as fallback for dynamic selection)
DEFAULT_MESSENGER_MODEL="loop:latest"
DEFAULT_COMBINATOR_MODEL="code:latest"
DEFAULT_TRADER_MODEL="2244:latest"

# Worker Models (Loaded from config)
MESSENGER_MODEL=""
COMBINATOR_MODEL=""
TRADER_MODEL=""

OLLAMA_BIN="$(command -v ollama || true)"
API_PORT="${API_PORT:-8080}"
API_PID_FILE="$AI_HOME/api.pid"

# Verbose thinking configuration (WebDev-AI style)
export VERBOSE_THINKING="${VERBOSE_THINKING:-true}"
export THINKING_DELAY="${THINKING_DELAY:-0.5}"
export SHOW_REASONING="${SHOW_REASONING:-true}"

# --- ANSI Colors (Exported for all functions) ---
export COLOR_RESET='\x1b[0m'
export COLOR_BRIGHT='\x1b[1m'
export COLOR_RED='\x1b[31m'
export COLOR_GREEN='\x1b[32m'
export COLOR_YELLOW='\x1b[33m'
export COLOR_BLUE='\x1b[34m'
export COLOR_MAGENTA='\x1b[35m'
export COLOR_CYAN='\x1b[36m'
export COLOR_GRAY='\x1b[90m'

# --- VERBOSE LOGGING SYSTEM (Triumvirate Style) ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
ORANGE='\033[0;33m'; NC='\033[0m'

LOG_LEVEL="${LOG_LEVEL:-INFO}"

log_to_file() {
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        printf "${PURPLE}[DEBUG][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
        log_to_file "DEBUG" "$*"
    fi
}

log_info() {
    if [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]]; then
        printf "${BLUE}[INFO][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
        log_to_file "INFO" "$*"
    fi
}

log_warn() {
    printf "${YELLOW}[WARN][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "WARN" "$*"
}

log_error() {
    printf "${RED}[ERROR][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "ERROR" "$*"
    return 1
}

log_success() {
    printf "${GREEN}[SUCCESS][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "SUCCESS" "$*"
}

log_think() {
    printf "${ORANGE}🤔 [THINK][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "THINK" "$*"
}

log_analysis() {
    printf "${PURPLE}🔍 [ANALYSIS][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "ANALYSIS" "$*"
}

log_plan() {
    printf "${CYAN}📋 [PLAN][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "PLAN" "$*"
}

log_execute() {
    printf "${GREEN}⚡ [EXECUTE][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "EXECUTE" "$*"
}

log_memory() {
    printf "${YELLOW}🧠 [MEMORY][%s]${NC} %s\\n" "$(date '+%T')" "$*" >&2
    log_to_file "MEMORY" "$*"
}

# --- BULLETPROOF ERROR HANDLING ---
trap 'cleanup_on_exit' EXIT INT TERM

cleanup_on_exit() {
    local exit_code=$?
    log_debug "Cleanup initiated with exit code: $exit_code"

    if [[ -f "$API_PID_FILE" ]]; then
        local api_pid=$(cat "$API_PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$api_pid" ]] && kill -0 "$api_pid" 2>/dev/null; then
            log_info "Stopping API server (PID: $api_pid) during cleanup"
            kill "$api_pid" 2>/dev/null || true
            rm -f "$API_PID_FILE"
        fi
    fi

    find "$AI_HOME" -name "*.tmp" -delete 2>/dev/null || true

    if [[ $exit_code -eq 0 ]]; then
        log_success "Script completed successfully"
    else
        log_error "Script exited with error code: $exit_code"
    fi
}

# Robust command execution with error handling
safe_exec() {
    local cmd="$1"
    local description="${2:-Executing command}"

    log_debug "Safe exec: $description"
    log_debug "Command: $cmd"

    if eval "$cmd"; then
        log_debug "Command succeeded: $description"
        return 0
    else
        local exit_code=$?
        log_error "Command failed (exit $exit_code): $description"
        log_error "Failed command: $cmd"
        return $exit_code
    fi
}

# --- DIRECTORY AND ENVIRONMENT SETUP ---
setup_directories() {
    log_debug "Setting up directories: AI_HOME=$AI_HOME, PROJECTS_DIR=$PROJECTS_DIR"

    local dirs=("$AI_HOME" "$PROJECTS_DIR" "$SSH_DIR" "$DB_DIR" "$SCRIPTS_DIR")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_info "Creating directory: $dir"
            if ! mkdir -p "$dir"; then
                log_error "Failed to create directory: $dir"
                return 1
            fi
        fi
        log_debug "Directory verified: $dir"
    done

    if [[ -d "$SSH_DIR" ]]; then
        chmod 700 "$SSH_DIR" 2>/dev/null || log_warn "Could not set permissions on $SSH_DIR"
    fi

    log_success "Directory structure verified"
}

# --- SQLITE UTILITIES WITH ERROR HANDLING ---
sqlite_escape() {
    echo "$1" | sed "s/'/''/g"
}

# --- DATABASE INITIALIZATION (Unified Schema) ---
init_db() {
    log_debug "Initializing databases"

    if ! command -v sqlite3 &> /dev/null; then
        log_error "sqlite3 is required but not installed"
        return 1
    fi

    # MEMORY_DB (ai_data.db equivalent)
    sqlite3 "$MEMORY_DB" <<SQL 2>/dev/null
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

    # HASH_INDEX_DB
    sqlite3 "$HASH_INDEX_DB" "CREATE TABLE IF NOT EXISTS hashes (type TEXT, target TEXT, hash TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>/dev/null

    # CONFIG_DB
    sqlite3 "$CONFIG_DB" "CREATE TABLE IF NOT EXISTS config (key TEXT PRIMARY KEY, value TEXT);" 2>/dev/null

    # POOL_INDEX_DB
    sqlite3 "$POOL_INDEX_DB" "CREATE TABLE IF NOT EXISTS pools (pool_hash TEXT PRIMARY KEY, rehash_count INTEGER DEFAULT 0, tasks TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);" 2>/dev/null

    # API_LOGS_DB
    sqlite3 "$API_LOGS_DB" "CREATE TABLE IF NOT EXISTS api_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, endpoint TEXT, method TEXT, payload TEXT);" 2>/dev/null

    # WEB_CONFIG_DB
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

    # BLOBS_DB
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

    log_success "Databases initialized"
}

# --- CONFIGURATION MANAGEMENT ---
set_config() {
    local k="$1" v="$2"
    log_debug "Setting config: $k = [REDACTED]"

    if sqlite3 "$CONFIG_DB" "INSERT OR REPLACE INTO config (key, value) VALUES ('$k', '$(sqlite_escape "$v")');" 2>/dev/null; then
        log_success "Config set: $k"
    else
        log_error "Failed to set config: $k"
        return 1
    fi
}

get_config() {
    local k="$1"
    local result
    result=$(sqlite3 "$CONFIG_DB" "SELECT value FROM config WHERE key = '$k';" 2>/dev/null)
    log_debug "Retrieved config: $k = $result"
    echo "$result"
}

view_config() {
    log_debug "Viewing all configuration"
    sqlite3 -header -column "$CONFIG_DB" "SELECT * FROM config;" 2>/dev/null || echo "No configuration set."
}

load_config_values() {
    log_debug "Loading configuration values"

    local messenger_config=$(get_config messenger_model)
    local combinator_config=$(get_config combinator_model)
    local trader_config=$(get_config trader_model)

    MESSENGER_MODEL="${messenger_config:-$DEFAULT_MESSENGER_MODEL}"
    COMBINATOR_MODEL="${combinator_config:-$DEFAULT_COMBINATOR_MODEL}"
    TRADER_MODEL="${trader_config:-$DEFAULT_TRADER_MODEL}"

    AI_TEMPERATURE="$(get_config temperature || echo "0.7")"
    AI_TOP_P="$(get_config top_p || echo "0.9")"
    AI_SEED="$(get_config seed || echo "")"
    API_PORT="$(get_config api_port || echo "8080")"

    log_info "Loaded models: Messenger=$MESSENGER_MODEL, Combinator=$COMBINATOR_MODEL, Trader=$TRADER_MODEL"
    log_debug "AI parameters: temperature=$AI_TEMPERATURE, top_p=$AI_TOP_P, seed=$AI_SEED"
}

# --- MEMORY MANAGEMENT ---
add_to_memory() {
    local p="$1" r="$2" ph="$3" th="$4"
    log_debug "Adding to memory: pool_hash=$ph, task_hash=$th"

    if sqlite3 "$MEMORY_DB" "INSERT INTO memories (prompt, response, pool_hash, task_hash) VALUES ('$(sqlite_escape "$p")', '$(sqlite_escape "$r")', '$ph', '$th');" 2>/dev/null; then
        log_debug "Memory entry added successfully"
    else
        log_warn "Failed to add memory entry"
    fi
}

search_memory() {
    local q="$1" l="${2:-5}"
    log_debug "Searching memory for: $q (limit: $l)"

    local result
    result=$(sqlite3 -header -column "$MEMORY_DB" "SELECT timestamp,prompt,response FROM memories WHERE prompt LIKE '%$(sqlite_escape "$q")%' OR response LIKE '%$(sqlite_escape "$q")%' ORDER BY timestamp DESC LIMIT $l;" 2>/dev/null)

    if [[ -n "$result" ]]; then
        log_debug "Memory search found results"
        echo "$result"
    else
        log_debug "Memory search returned no results"
        echo "No relevant memories found."
    fi
}

clear_memory() {
    log_warn "Request to clear ALL memory data"
    if confirm_action "Clear ALL memory data"; then
        if sqlite3 "$MEMORY_DB" "DELETE FROM memories;" 2>/dev/null; then
            log_success "Memory cleared"
        else
            log_error "Failed to clear memory"
        fi
    else
        log_info "Memory clear cancelled by user"
    fi
}

# --- HASHING FUNCTIONS ---
hash_string() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

hash_file_content() {
    if [[ -f "$1" ]]; then
        local hash
        hash=$(sha256sum "$1" | cut -d' ' -f1)
        log_debug "Hashed file: $1 -> $hash"
        echo "$hash"
    else
        log_error "File not found: $1"
        return 1
    fi
}

hash_repo_content() {
    if [[ -d "$1" ]]; then
        local hash
        hash=$(find "$1" -type f ! -path "*/.git/*" -exec cat {} + 2>/dev/null | sha256sum | cut -d' ' -f1)
        log_debug "Hashed repo: $1 -> $hash"
        echo "$hash"
    else
        log_error "Directory not found: $1"
        return 1
    fi
}

record_hash() {
    local type="$1" target="$2" hash="$3"
    log_debug "Recording hash: $type:$target -> $hash"

    if sqlite3 "$HASH_INDEX_DB" "INSERT OR REPLACE INTO hashes (type, target, hash) VALUES ('$type', '$(sqlite_escape "$target")', '$hash');" 2>/dev/null; then
        log_info "Recorded hash for $type: $target"
    else
        log_warn "Failed to record hash for $type: $target"
    fi
}

get_hash() {
    local type="$1" target="$2"
    local result
    result=$(sqlite3 "$HASH_INDEX_DB" "SELECT hash FROM hashes WHERE type='$type' AND target='$(sqlite_escape "$target")';" 2>/dev/null)
    log_debug "Retrieved hash for $type:$target -> $result"
    echo "$result"
}

view_hash_index() {
    log_debug "Viewing hash index"
    sqlite3 -header -column "$HASH_INDEX_DB" "SELECT * FROM hashes ORDER BY timestamp DESC;" 2>/dev/null || echo "No hashes recorded."
}

# --- TASK POOLING SYSTEM ---
setup_task_pool() {
    local prompt="$1"
    log_debug "Setting up task pool for prompt: ${prompt:0:50}..."

    log_think "Analyzing prompt for semantic hashing..."

    local semantic_hash_val
    semantic_hash_val=$(echo "$prompt" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | cut -c1-16)
    if [[ -z "$semantic_hash_val" ]]; then
        semantic_hash_val=$(hash_string "$prompt" | cut -c1-16)
        log_warn "Fallback: Generated semantic hash from raw prompt"
    fi

    local instance_hash_val=$(hash_string "$prompt$(date +%s%N)" | cut -c1-16)
    local pool_dir="$PROJECTS_DIR/$semantic_hash_val"

    log_debug "Creating pool directory: $pool_dir"
    if ! mkdir -p "$pool_dir"; then
        log_error "Failed to create pool directory: $pool_dir"
        return 1
    fi

    local rehash_count=0
    local tasks_json='[]'
    local existing_data

    existing_data=$(sqlite3 "$POOL_INDEX_DB" "SELECT rehash_count, tasks FROM pools WHERE pool_hash = '$semantic_hash_val';" 2>/dev/null)

    if [[ -n "$existing_data" ]]; then
        rehash_count=$(echo "$existing_data" | cut -d'|' -f1)
        local existing_tasks=$(echo "$existing_data" | cut -d'|' -f2)
        rehash_count=$((rehash_count + 1))

        if command -v jq &> /dev/null && [[ -n "$existing_tasks" ]]; then
            tasks_json=$(echo "$existing_tasks" | jq -c --arg task "$instance_hash_val" '. + [$task]' 2>/dev/null || echo "[\"$instance_hash_val\"]")
        else
            tasks_json="[\"$instance_hash_val\"]"
        fi

        if ! sqlite3 "$POOL_INDEX_DB" "UPDATE pools SET rehash_count = $rehash_count, tasks = '$(sqlite_escape "$tasks_json")' WHERE pool_hash = '$semantic_hash_val';" 2>/dev/null; then
            log_warn "Failed to update pool index"
        fi
    else
        rehash_count=1
        tasks_json="[\"$instance_hash_val\"]"
        if ! sqlite3 "$POOL_INDEX_DB" "INSERT INTO pools (pool_hash, rehash_count, tasks) VALUES ('$semantic_hash_val', $rehash_count, '$(sqlite_escape "$tasks_json")');" 2>/dev/null; then
            log_warn "Failed to insert new pool index"
        fi
    fi

    log_memory "Task pool created: semantic=$semantic_hash_val, instance=$instance_hash_val, resonance=$rehash_count"
    echo "$semantic_hash_val $instance_hash_val $rehash_count"
}

# --- USER CONFIRMATION ---
confirm_action() {
    local action="$1"
    local response

    echo -e "${YELLOW}CONFIRM: $action${NC}" >&2
    read -p "Type 'yes' to confirm: " -r response

    if [[ "$response" == "yes" ]]; then
        log_debug "User confirmed action: $action"
        return 0
    else
        log_warn "User cancelled action: $action"
        return 1
    fi
}

# --- BULLETPROOF TOOL IMPLEMENTATIONS ---
tool_read_file() {
    local p="$1"
    log_think "Reading file: $p"

    if [[ ! -f "$p" ]]; then
        log_error "File not found: $p"
        echo "ERROR: File not found: $p"
        return 1
    fi

    if [[ ! -r "$p" ]]; then
        log_error "No read permission for file: $p"
        echo "ERROR: No read permission for file: $p"
        return 1
    fi

    log_debug "Successfully reading file: $p"
    cat "$p"
}

tool_list_directory() {
    local p="${1:-.}"
    log_think "Listing directory: $p"

    if [[ ! -d "$p" ]]; then
        log_error "Directory not found: $p"
        echo "ERROR: Directory not found: $p"
        return 1
    fi

    if [[ ! -r "$p" ]]; then
        log_error "No read permission for directory: $p"
        echo "ERROR: No read permission for directory: $p"
        return 1
    fi

    log_debug "Successfully listing directory: $p"
    if command -v tree &> /dev/null; then
        tree -L 2 "$p"
    else
        ls -la "$p"
    fi
}

tool_web_search() {
    if ! command -v googler &> /dev/null; then
        log_error "googler not installed"
        echo "ERROR: googler not installed. Install with: sudo apt-get install googler"
        return 1
    fi

    local query="$1" count="${2:-3}"
    log_think "Searching web for: $query"

    if confirm_action "Search web for: $query"; then
        log_debug "Executing web search: $query (count: $count)"
        googler --count "$count" --exact "$query"
    else
        log_info "Web search cancelled by user"
        echo "ACTION CANCELED: Web search."
    fi
}

tool_write_file() {
    local path="$1" content="$2"
    log_think "Writing to file: $path"

    if confirm_action "Write to file: $path"; then
        local dir=$(dirname "$path")
        log_debug "Creating directory: $dir"

        if ! mkdir -p "$dir"; then
            log_error "Failed to create directory: $dir"
            echo "ERROR: Failed to create directory: $dir"
            return 1
        fi

        if echo "$content" > "$path"; then
            log_success "File written: $path"
            echo "SUCCESS: File written to $path"
        else
            log_error "Failed to write file: $path"
            echo "ERROR: Failed to write file: $path"
            return 1
        fi
    else
        log_info "File write cancelled by user"
        echo "ACTION CANCELED: Write to $path"
    fi
}

tool_run_command() {
    local cmd="$1"
    local project_root
    project_root=$(get_config current_project_root || echo ".")

    log_think "Running command: $cmd (in: $project_root)"

    if confirm_action "Run command: $cmd (in: $project_root)"; then
        log_debug "Executing command: $cmd in $project_root"

        if (cd "$project_root" && eval "$cmd" 2>&1); then
            log_success "Command executed successfully"
        else
            local exit_code=$?
            log_error "Command failed with exit code: $exit_code"
            return $exit_code
        fi
    else
        log_info "Command execution cancelled by user"
        echo "ACTION CANCELED: Run command."
    fi
}

# --- NEW CODE REPAIR TOOL ---
tool_code_repair() {
    local file_path="$1"
    local file_extension="${file_path##*.}"
    
    log_analysis "Starting Code Repair Agent on: $file_path"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found for repair: $file_path"
        return 1
    fi

    # 1. Run Static Analysis and Formatting
    log_think "Running static analysis and formatting pipeline..."
    local analysis_output
    
    # Create a temporary file to capture the Python script's output
    local temp_report_file
    temp_report_file=$(mktemp)
    
    # Run the Python script and redirect its stdout to the temp file
    if ! python3 "$CODE_PROCESSOR_PY" "$file_path" "$file_extension" > "$temp_report_file" 2>&1; then
        log_error "Python code processor failed. Check dependencies."
        cat "$temp_report_file" >&2
        rm "$temp_report_file"
        return 1
    fi

    analysis_output=$(cat "$temp_report_file")
    rm "$temp_report_file"

    # Extract the formatted code and the analysis findings
    local formatted_code
    local analysis_findings
    
    # Simple extraction: assume formatted code is after "--- SYNTAX HIGHLIGHTED CODE ---"
    # and analysis findings are after "--- STATIC ANALYSIS FINDINGS ---"
    formatted_code=$(echo "$analysis_output" | sed -n '/--- SYNTAX HIGHLIGHTED CODE ---/,$p' | sed '1,2d' | sed '$d' | sed '/^$/d' || true)
    analysis_findings=$(echo "$analysis_output" | sed -n '/--- STATIC ANALYSIS FINDINGS ---/,/--- SYNTAX HIGHLIGHTED CODE ---/p' | sed '1d;$d' || true)

    if [[ -z "$analysis_findings" ]]; then
        log_success "Code is clean! Only formatting applied."
        # Overwrite the original file with the formatted code
        if confirm_action "Apply formatting changes to $file_path"; then
            echo "$formatted_code" > "$file_path"
            log_success "File $file_path formatted successfully."
        fi
        return 0
    fi

    # 2. Construct AI Repair Prompt
    log_warn "Analysis found issues. Delegating to Ollama for intelligent repair."
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

    # 3. Call Node.js Orchestrator for Repair
    log_execute "Calling Node.js Orchestrator for intelligent code repair..."
    
    # We'll use a direct Ollama call for simplicity, bypassing the full orchestrator loop.
    local repaired_response
    repaired_response=$(run_worker_raw "CodeRepair" "$TRADER_MODEL" "You are a Code Repair Agent. Fix the code based on the report and return ONLY the corrected code block." "$repair_prompt")
    local repaired_code
    
    # Extract the code block from the response
    repaired_code=$(echo "$repaired_response" | sed -n '/```/,$p' | sed '1d;$d' | sed '/^$/d' || true)

    if [[ -z "$repaired_code" ]]; then
        log_error "AI failed to return a valid code block for repair."
        return 1
    fi

    # 4. Apply Final Repair
    log_analysis "AI Repair complete. Reviewing final code."
    echo -e "${GREEN}--- AI REPAIRED CODE (Review) ---${NC}" >&2
    echo "$repaired_code" > "$file_path.repaired.tmp"
    _process_code_file "$file_path.repaired.tmp" "$file_extension" # Re-run processor for final highlight

    if confirm_action "Apply AI-repaired code to $file_path"; then
        echo "$repaired_code" > "$file_path"
        log_success "File $file_path repaired and updated successfully."
    else
        log_warn "AI repair cancelled. Repaired code saved to $file_path.repaired.tmp"
    fi
    
    rm -f "$file_path.repaired.tmp"
    return 0
}

# --- MAIN CLI DISPATCHER FUNCTIONS ---

# --- Installation Function ---
install_webdev_ai() {
    echo -e "\n${COLOR_BRIGHT}${COLOR_CYAN}🚀 INSTALLING AI DEVOPS PLATFORM${COLOR_RESET}"
    echo -e "${COLOR_GRAY}=========================================${COLOR_RESET}"
    
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$SCRIPTS_DIR"
    
    check_dependencies
    init_db
    setup_orchestrator
    setup_code_processor
    
    echo -e "\n${COLOR_BRIGHT}${COLOR_GREEN}✅ INSTALLATION COMPLETED SUCCESSFULLY!${COLOR_RESET}"
    echo "  npm install sqlite3"
    echo "  pip install pygments pylint black autopep8"
    echo "  sudo apt install shfmt (or equivalent)"
    echo -e "${COLOR_BRIGHT}${COLOR_YELLOW}💡 Usage examples:${COLOR_RESET}"
    echo "  $SCRIPT_NAME 'create a Python Flask API with a /status endpoint'"
    echo "  $SCRIPT_NAME --setup"
    echo "  $SCRIPT_NAME --verbose  # Enable verbose debugging"
}

# --- Enhanced Status Function ---
enhanced_status() {
    printf "\n${COLOR_BRIGHT}${COLOR_CYAN}🌐 AI DEVOPS PLATFORM STATUS${COLOR_RESET}\n"
    printf "${COLOR_GRAY}==========================================${COLOR_RESET}\n"
    printf "AI_HOME: %s\n" "$AI_HOME"
    printf "Projects: %s created\n" "$(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l)"
    printf "Active Session: %s\n" "$([ -f "$SESSION_FILE" ] && cat "$SESSION_FILE" || echo "None")"
    printf "Verbose Thinking: %s\n" "$VERBOSE_THINKING"
    printf "Show Reasoning: %s\n" "$SHOW_REASONING"
    
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN" "pylint" "black" "autopep8" "shfmt")
    printf "\n${COLOR_BRIGHT}${COLOR_BLUE}🔧 DEPENDENCIES:${COLOR_RESET}\n"
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$dep"
        else
            printf "  ${COLOR_RED}❌ %s${COLOR_RESET}\n" "$dep"
        fi
    done
    
    printf "\n${COLOR_BRIGHT}${COLOR_MAGENTA}📦 NODE MODULES:${COLOR_RESET}\n"
    local node_modules=("sqlite3")
    for module in "${node_modules[@]}"; do
        if [ -d "$NODE_MODULES/$module" ]; then
            printf "  ${COLOR_GREEN}✅ %s${COLOR_RESET}\n" "$module"
        else
            printf "  ${COLOR_RED}❌ %s${COLOR_RESET}\n" "$module"
        fi
    done
    
    printf "\n${COLOR_BRIGHT}${COLOR_GREEN}📊 SYSTEM STATS:${COLOR_RESET}\n"
    if [ -f "$MEMORY_DB" ]; then
        local total_tasks=$(sqlite3 "$MEMORY_DB" "SELECT COUNT(*) FROM memories;" 2>/dev/null || echo "0")
        local total_events=$(sqlite3 "$MEMORY_DB" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "0")
        printf "  Total Memories: %s\n" "$total_tasks"
        printf "  Total Events: %s\n" "$total_events"
    fi
    
    if [ -d "$AI_HOME" ]; then
        local disk_usage=$(du -sh "$AI_HOME" 2>/dev/null | cut -f1)
        printf "  Disk Usage: %s\n" "$disk_usage"
    fi
    
    printf "\n${COLOR_BRIGHT}${COLOR_YELLOW}💡 TIP: Use '--verbose' to toggle thinking mode, '--quiet' for silent mode${COLOR_RESET}\n"
}

# --- Toggle Verbose Mode ---
toggle_verbose() {
    if [ "$VERBOSE_THINKING" = "true" ]; then
        export VERBOSE_THINKING="false"
        export SHOW_REASONING="false"
        echo "Verbose thinking: DISABLED"
    else
        export VERBOSE_THINKING="true"
        export SHOW_REASONING="true"
        echo "Verbose thinking: ENABLED"
    fi
}

# --- AI Task Runner (Fusion of Triumvirate and WebDev-AI) ---
run_ai_task() {
    local full_prompt=""
    local file_path=""
    local args=()
    
    # Parse arguments to separate prompt from --file
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                if [[ -z "${2:-}" ]]; then log_error "Error: --file requires a path."; return 1; fi
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

    log_analysis "User request: $full_prompt"

    if [ -f "$SESSION_FILE" ]; then
        local proj=$(cat "$SESSION_FILE")
        log_think "Active session detected: $proj"
        args+=("--project=$proj")
    fi

    log_execute "Delegating to Node.js Orchestrator for parallel execution..."
    
    # Set environment variables for Node.js
    export AI_DATA_DB="$MEMORY_DB"
    export PROJECTS_DIR
    export CODE_PROCESSOR_PY
    export VERBOSE_THINKING
    export SHOW_REASONING
    
    local final_response
    # The Node.js orchestrator handles the full Triumvirate-style loop internally
    final_response=$(node "$ORCHESTRATOR_FILE" "$full_prompt" "${args[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Node.js Orchestrator failed with exit code $exit_code"
        echo "$final_response" >&2
        return 1
    fi
    
    # Extract final answer from the Node.js output
    local final_answer_line
    final_answer_line=$(echo "$final_response" | grep '^\\[FINAL_ANSWER\\]' || true)

    if [[ -z "$final_answer_line" ]]; then
        log_warn "Orchestrator did not return a [FINAL_ANSWER] tag. Displaying full output."
    fi

    # Save full response to a task directory (using the Node.js generated ID)
    local task_id_match
    task_id_match=$(echo "$final_response" | grep 'Task ID (2π-indexed):' | awk '{print $NF}' || true)
    local task_id="${task_id_match:-$(hash_string "$full_prompt" | cut -c1-16)}"
    local project_dir="$PROJECTS_DIR/task_$task_id"
    
    if ! mkdir -p "$project_dir"; then
        log_error "Failed to create project directory: $project_dir"
        return 1
    fi
    
    echo "User Prompt: $full_prompt" > "$project_dir/summary.txt"
    echo -e "\\n--- Final Agent Response ---\\n" >> "$project_dir/summary.txt"
    echo "$final_response" >> "$project_dir/summary.txt"
    log_success "Full task log and summary saved in: $project_dir"

    echo -e "\\n${GREEN}✅ === AI TASK COMPLETE ===${NC}" >&2
    echo -e "${GREEN}📝 Final Response:${NC}" >&2
    echo "$final_response" | sed -n '/^\\[FINAL_ANSWER\\]/,$p' | sed '1d'
}

# --- MAIN CLI DISPATCHER ---
main() {
    local start_time=$(date +%s)
    log_debug "Script started: $SCRIPT_NAME v$SCRIPT_VERSION"

    # Initialize environment
    if ! setup_directories; then
        log_error "Failed to setup directories"
        return 1
    fi

    init_db
    load_config_values
    setup_orchestrator
    setup_code_processor

    case "${1:-}" in
        "--setup")
            log_info "Running setup procedure"
            check_dependencies
            setup_environment
            ;;

        "--config")
            case "${2:-}" in
                "set")
                    if [[ -z "${3:-}" || -z "${4:-}" ]]; then
                        log_error "Usage: $0 --config set <key> <value>"
                        return 1
                    fi
                    set_config "$3" "$4"
                    ;;
                "get")
                    if [[ -z "${3:-}" ]]; then
                        log_error "Usage: $0 --config get <key>"
                        return 1
                    fi
                    get_config "$3"
                    ;;
                "view") view_config ;;
                *) log_error "Usage: $0 --config [set|get|view] [key] [value]" ;;
            esac
            ;;

        "--hash")
            case "${2:-}" in
                "file")
                    if [[ -z "${3:-}" ]]; then
                        log_error "Usage: $0 --hash file <path>"
                        return 1
                    fi
                    local file_hash=$(hash_file_content "$3")
                    record_hash "file" "$3" "$file_hash"
                    ;;
                "prompt")
                    if [[ -z "${3:-}" ]]; then
                        log_error "Usage: $0 --hash prompt \"<text>\""
                        return 1
                    fi
                    local prompt_hash=$(hash_string "$3")
                    record_hash "prompt" "$3" "$prompt_hash"
                    ;;
                *) log_error "Usage: $0 --hash [file|prompt|repo|get|view] [target]" ;;
            esac
            ;;

        "--api")
            # API management commands...
            ;;

        "--verbose")
            LOG_LEVEL="DEBUG"
            export VERBOSE_THINKING="true"
            export SHOW_REASONING="true"
            log_debug "Verbose mode enabled"
            shift
            main "$@"
            ;;

        "--help"|"-h"|"")
            show_help
            ;;

        "status")
            enhanced_status
            ;;

        "--start")
            local proj="$2"
            if [[ -z "$proj" ]]; then
                read -p "Project/Repo name: " proj
            fi
            echo "$proj" > "$SESSION_FILE"
            log_event "SESSION" "Started web development session for $proj"
            log_think "Session started for project: $proj"
            ;;
        
        "--stop")
            [ -f "$SESSION_FILE" ] && proj=$(cat "$SESSION_FILE") && log_event "SESSION" "Stopped session for $proj"
            rm -f "$SESSION_FILE"
            log_think "Session stopped"
            ;;

        "--install")
            install_webdev_ai
            ;;

        "repair")
            if [[ -z "${2:-}" ]]; then
                log_error "Usage: $0 repair <file_path>"
                return 1
            fi
            tool_code_repair "$2"
            ;;

        *)
            local prompt_to_run="$*"
            if [[ -z "$prompt_to_run" ]]; then
                log_error "No prompt provided"
                show_help
                return 1
            fi

            if ! check_dependencies; then
                log_error "Dependency check failed"
                return 1
            fi

            run_ai_task "$prompt_to_run"
            ;;
    esac

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_debug "Script completed in ${duration}s"
}

show_help() {
    cat << EOF
${GREEN}$SCRIPT_NAME v$SCRIPT_VERSION - Unified Hybrid Agent${NC}

${CYAN}Description:${NC} Advanced AI agent system with hybrid execution (Node.js/Python), dynamic model selection, and comprehensive logging.

${CYAN}Usage:${NC}
  $0 [OPTIONS] "<your prompt>"      - Run AI Task
  $0 repair <file_path>             - Run static analysis and AI-powered code repair
  $0 --verbose "<prompt>"           - Enable verbose debugging
  $0 --setup                        - Initial setup and dependency check
  $0 --config [set|get|view]        - Configuration management
  $0 --hash [file|prompt|repo]      - Content hashing utilities
  $0 status                         - View system status
  $0 --start [project]              - Start a project session
  $0 --stop                         - Stop the current session
  $0 --install                      - Install dependencies and orchestrator
  $0 --help                         - Show this help

${CYAN}Examples:${NC}
  $0 "Create a Python Flask API with a /status endpoint"
  $0 repair ./src/broken_script.py
  $0 --start my-new-app
  $0 --config set trader_model llama3.1:8b

${CYAN}Log File:${NC} $LOG_FILE
${CYAN}Data Directory:${NC} $AI_HOME
EOF
}

# --- ENTRY POINT WITH COMPREHENSIVE ERROR HANDLING ---
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    if [[ -z "$HOME" ]]; then
        echo "ERROR: HOME environment variable not set" >&2
        exit 1
    fi

    if [[ ! -d "$(dirname "$0")" ]]; then
        mkdir -p "$(dirname "$0")"
    fi

    if main "$@"; then
        exit 0
    else
        exit 1
    fi
fi
