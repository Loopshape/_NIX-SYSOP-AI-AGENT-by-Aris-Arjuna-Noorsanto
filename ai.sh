#!/usr/bin/env bash
<<<<<<< HEAD
#
# SysOp-AI: A Self-Contained AI Command-Line Application
#
# This script provides a framework for interacting with a pool of local language
# models via Ollama to perform tasks, generate code, and persist its state.
#
# USAGE:
#   sysop-ai <command> [options]
#
# COMMANDS:
#   run <prompt>      Runs the main AI loop with a given prompt.
#   import <url...>   Imports content from one or more URLs.
#   memories          Lists the AI's past interactions.
#   events            Shows the detailed event log.
#   blobs             Lists all files stored in the blob database.
#   status            Displays configuration and environment status.
#   help              Shows this help message.
#
# See 'sysop-ai <command> --help' for more information on a specific command.
#
set -euo pipefail
IFS=$'\n\t'
=======
set -euo pipefail

# ============================================================================
# AI Unified CLI Template
# Combines Ollama analyzer, WebDev orchestrator, and prompt continuation.
# ============================================================================
OLLAMA_HOST="http://localhost:11434"
DEFAULT_MODEL="codellama"
AI_SESSION_FILE="$HOME/.ai_last_session.json"

# --- ANSI colors & logging ---
COLOR_RESET="\x1b[0m"; COLOR_YELLOW="\x1b[33m"
COLOR_GREEN="\x1b[32m"; COLOR_CYAN="\x1b[36m"
COLOR_RED="\x1b[31m";   COLOR_BLUE="\x1b[34m"

log_info()  { echo -e "${COLOR_CYAN}[INFO] $1${COLOR_RESET}" >&2; }
log_error() { echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}" >&2; }

# ============================================================================
# SECTION 1: Ollama-style code analysis interface
# (fill in your real call_ollama_api implementation here)
# ============================================================================
call_ollama_api() {
    local MODEL="$1"; local PROMPT="$2"; local FILE="${3:-}"
    log_info "Simulating API call to model '$MODEL'"
    echo "[placeholder response from $MODEL for prompt: $PROMPT, file: $FILE]"
}

# ============================================================================
# SECTION 2: WebDev orchestrator stub
# (replace with your Node.js subprocess logic)
# ============================================================================
run_webdev_task() {
    local PROMPT="$1"
    log_info "Simulating WebDev orchestration for prompt: $PROMPT"
    echo "[placeholder webdev output for: $PROMPT]"
}

# ============================================================================
# SECTION 3: Session save / resume
# ============================================================================
save_session() {
    local MODEL="$1"; local PROMPT="$2"; local RESPONSE="$3"
    jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg response "$RESPONSE" \
       '{model:$model, prompt:$prompt, response:$response, timestamp:now}' \
       > "$AI_SESSION_FILE"
}

continue_session() {
    if [[ ! -f "$AI_SESSION_FILE" ]]; then
        log_error "No previous session found."
        exit 1
    fi
    local USER_PROMPT="$1"
    local MODEL=$(jq -r '.model' "$AI_SESSION_FILE")
    local CONTEXT=$(jq -r '.response' "$AI_SESSION_FILE")
    local COMBINED_PROMPT="Previous context:\n${CONTEXT}\n\nUser continuation:\n${USER_PROMPT}"
    call_ollama_api "$MODEL" "$COMBINED_PROMPT"
}

# ============================================================================
# SECTION 4: Analyzer entry point
# ============================================================================
run_analyzer() {
    local PROMPT="$1"; local SCRIPT_PATH="$2"; local MODEL="${3:-$DEFAULT_MODEL}"
    local RESPONSE
    RESPONSE=$(call_ollama_api "$MODEL" "$PROMPT" "$SCRIPT_PATH")
    save_session "$MODEL" "$PROMPT" "$RESPONSE"
}

# ============================================================================
# SECTION 5: CLI routing
# ============================================================================
show_help() {
    echo -e "${COLOR_YELLOW}Usage:${COLOR_RESET}
      ai dex 'prompt' /path/to/script.sh [model]
      ai dev 'web project description'
      ai prompt 'continue last conversation'"
}

case "${1:-}" in
    dex)
        [[ -z "${2:-}" || -z "${3:-}" ]] && { show_help; exit 1; }
        run_analyzer "$2" "$3" "${4:-$DEFAULT_MODEL}"
        ;;
    dev)
        [[ -z "${2:-}" ]] && { show_help; exit 1; }
        run_webdev_task "$2"
        ;;
    prompt)
        [[ -z "${2:-}" ]] && { show_help; exit 1; }
        continue_session "$2"
        ;;
    *)
        show_help
        ;;
esac

// Enhanced WebDev Code-Engine with Working Color Implementation
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3 from 'sqlite3';
>>>>>>> 051132d49003487fb706444860087269deb5a850

# ==============================================================================
# SECTION 1: CORE AI ENGINE & HELPERS (Largely Unchanged)
# ==============================================================================

# -------------------- Paths & Configuration --------------------
AI_HOME="${AI_HOME:-$HOME/.sysop_ai_env}"
AI_DB="$AI_HOME/ai_data.db"
BLOBS_DB="$AI_HOME/blobs.db"
TASKS_DIR="$AI_HOME/tasks"
OLLAMA_BIN="${OLLAMA_BIN:-/home/linuxbrew/.linuxbrew/bin/ollama}"

export VERBOSE_THINKING="${VERBOSE_THINKING:-true}"
export THINKING_DELAY="${THINKING_DELAY:-0.2}"
export SHOW_REASONING="${SHOW_REASONING:-true}"

export PROOF_CYCLE_INDEX=0
export PROOF_NET_WORTH_INDEX=0
export PROOF_FRAMEWORKS=""
export PROOF_COMPLEXITY=0
export PROOF_TASK_ID=""

# -------------------- Models --------------------
declare -A MODEL_WEIGHTS
POOL_MODELS=("2244:latest" "core:latest" "loop:latest" "coin:latest" "code:latest")
MODEL_WEIGHTS=( ["2244:latest"]=2 ["core:latest"]=2 ["loop:latest"]=1 ["coin:latest"]=1 ["code:latest"]=2 )

# -------------------- Core Initializer --------------------
_initialize_env() {
    thinking "Initializing environment and databases..." 0
    mkdir -p "$AI_HOME" "$TASKS_DIR"
    sqlite3 "$AI_DB" <<'EOF'
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT, prompt TEXT, response TEXT,
    proof_state TEXT, framework TEXT, complexity INTEGER DEFAULT 1,
    reasoning_log TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT, event_type TEXT, message TEXT,
    metadata TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS reasoning_chains (
    id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT, step INTEGER,
    reasoning TEXT, context TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
    sqlite3 "$BLOBS_DB" <<'EOF'
CREATE TABLE IF NOT EXISTS blobs (
    id INTEGER PRIMARY KEY, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    filename TEXT, content TEXT
);
EOF
    log_event "INFO" "Databases initialized with enhanced schemas."
}

# -------------------- Git Setup --------------------
_git_setup() {
    thinking "Checking Git setup..." 0
    local git_branch="devel"
    if ! git -C "$AI_HOME" rev-parse --is-inside-work-tree &>/dev/null; then
        git init -b "$git_branch" "$AI_HOME"
        log_event "INFO" "Initialized new Git repository in $AI_HOME"
    fi
    git -C "$AI_HOME" checkout "$git_branch" 2>/dev/null || git -C "$AI_HOME" checkout -b "$git_branch"
    log_event "DEBUG" "Git branch set to $git_branch"
}

# -------------------- ANSI Colors --------------------
COLOR_RESET='\x1b[0m'
COLOR_BRIGHT='\x1b[1m'
COLOR_RED='\x1b[31m'
COLOR_GREEN='\x1b[32m'
COLOR_YELLOW='\x1b[33m'
COLOR_BLUE='\x1b[34m'
COLOR_MAGENTA='\x1b[35m'
COLOR_CYAN='\x1b[36m'
COLOR_GRAY='\x1b[90m'

# -------------------- Enhanced Logging & Thinking --------------------
log_event() {
    local level="$1" message="$2" metadata="${3:-}" color="$COLOR_CYAN"
    case "$level" in
        "ERROR") color="$COLOR_RED" ;; "WARN") color="$COLOR_YELLOW" ;;
        "SUCCESS") color="$COLOR_GREEN" ;; "INFO") color="$COLOR_BLUE" ;;
        "DEBUG") color="$COLOR_MAGENTA" ;;
    esac
    echo -e "[$color$level$COLOR_RESET] $(date +%H:%M:%S): $message"
    message=$(sed "s/'/''/g" <<< "$message"); metadata=$(sed "s/'/''/g" <<< "$metadata")
    sqlite3 "$AI_DB" "INSERT INTO events (event_type, message, metadata) VALUES ('$level', '$message', '$metadata');" 2>/dev/null || true
}

thinking() {
    local message="$1" depth="${2:-0}" indent=""
    for ((i=0; i<depth; i++)); do indent+="  "; done
    if [ "$VERBOSE_THINKING" = "true" ]; then
        echo -e "${indent}🤔 ${COLOR_CYAN}THINKING$COLOR_RESET: $message"
        sleep "$THINKING_DELAY"
    fi
}

show_reasoning() {
    local reasoning="$1" context="$2"
    if [ "$SHOW_REASONING" = "true" ] && [ -n "$reasoning" ]; then
        echo -e "\n${COLOR_YELLOW}💭 REASONING [$context]:$COLOR_RESET"
        echo -e "$COLOR_GRAY$reasoning$COLOR_RESET"
        echo -e "${COLOR_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$COLOR_RESET\n"
        local escaped_reasoning=$(sed "s/'/''/g" <<< "$reasoning")
        local escaped_context=$(sed "s/'/''/g" <<< "$context")
        sqlite3 "$AI_DB" "INSERT INTO reasoning_chains (task_id, step, reasoning, context) VALUES ('$PROOF_TASK_ID', $PROOF_CYCLE_INDEX, '$escaped_reasoning', '$escaped_context');" 2>/dev/null || true
    fi
}

# -------------------- Proof & State Helpers --------------------
calculate_complexity() {
    local prompt="$1" score=0
    thinking "Calculating task complexity..." 1
    local keywords=("authentication" "database" "api" "middleware" "component" "responsive" "ssr" "state management" "deployment" "docker")
    local found_keywords=""
    for keyword in "${keywords[@]}"; do
        if [[ "$prompt" =~ $keyword ]]; then
            score=$((score + 2)); found_keywords+="$keyword, "
        fi
    done
    PROOF_COMPLEXITY=$((score < 10 ? score : 10))
    show_reasoning "Score: $PROOF_COMPLEXITY (from keywords: ${found_keywords%, })" "Complexity Analysis"
}

detect_frameworks() {
    local prompt="$1" detected=()
    thinking "Analyzing prompt for framework indicators..." 1
    local framework_keywords=("react hooks component" "angular typescript rxjs" "vue composition api" "python flask django fastapi" "node express backend")
    for entry in "${framework_keywords[@]}"; do
        local framework="${entry%% *}" keywords="${entry#* }"
        if [[ "$prompt" =~ $framework ]] || [[ "$prompt" =~ $keywords ]]; then
            detected+=("$framework")
        fi
    done
    local result="${detected[*]}"
    PROOF_FRAMEWORKS="$result"
    show_reasoning "Detected: $result" "Framework Detection"
}

proof_cycle() {
    local converged="$1" reasoning="$2"
    thinking "Processing proof cycle: converged=$converged" 1
    PROOF_CYCLE_INDEX=$((PROOF_CYCLE_INDEX + 1))
    PROOF_NET_WORTH_INDEX=$((PROOF_NET_WORTH_INDEX + (converged == 1 ? 1 : -1)))
    show_reasoning "$reasoning. Cycle $PROOF_CYCLE_INDEX. Net Worth: $PROOF_NET_WORTH_INDEX." "Proof Cycle Update"
}

# -------------------- Helpers (Updated) --------------------
add_memory_enhanced() {
    local prompt_esc=$(sed "s/'/''/g" <<< "$1") response_esc=$(sed "s/'/''/g" <<< "$2")
    local proof_state_esc=$(sed "s/'/''/g" <<< "$3") framework_esc=$(sed "s/'/''/g" <<< "$4")
    local reasoning_log_esc=$(sed "s/'/''/g" <<< "$6")
    sqlite3 "$AI_DB" "INSERT INTO memories (prompt, response, task_id, proof_state, framework, complexity, reasoning_log) VALUES (
      '$prompt_esc', '[XOR$(printf "%d" "0x$(echo -n "$2" | sha256sum | cut -c1-8)")] $response_esc', '$PROOF_TASK_ID',
      '$proof_state_esc', '$framework_esc', $5, '$reasoning_log_esc'
    );" 2>/dev/null
}
add_blob() { sqlite3 "$BLOBS_DB" "INSERT INTO blobs (filename,content) VALUES ('$1','$(sed "s/'/''/g" <<< "$2")');"; }
run_ollama_json() { "$OLLAMA_BIN" run "$1" --format=json --keepalive=3200m "$2"; }
gen_task_id() { echo -n "${1:-}$(date +%s%N)$RANDOM" | sha256sum | cut -c1-16; }

# -------------------- Syntax Highlight --------------------
highlight_file() {
    local file="$1"
    if command -v pygmentize &>/dev/null; then pygmentize -g "$file"; else
        echo -e "${COLOR_YELLOW}[WARN] pygmentize not found. Displaying plain text.$COLOR_RESET"
        cat "$file"
    fi
}

# -------------------- Consensus Iteration --------------------
_run_consensus_iteration() {
    local -n models="$1" local -n weights="$2" local prompt="$3" local iter="$4"
    local fused_output="" model_reasoning=""
    for model in "${models[@]}"; do
        thinking "Querying model $model..." 2
        log_event "DEBUG" "Querying model: $model (Iter $iter)"
        local json data
        json=$(run_ollama_json "$model" "$prompt") || { log_event "WARN" "Model $model failed on iteration $iter."; continue; }
        data="$json"
        local weight="${weights[$model]:-1}"
        for ((w=1; w<=weight; w++)); do fused_output+="$data"$'\n'; done
        model_reasoning+="$model contributed ${weight}x. "
    done
    show_reasoning "$model_reasoning" "Consensus Fusion (Iteration $iter)"
    echo "$fused_output"
}

# -------------------- AI Loop (The 'run' command's core) --------------------
run_ai_loop() {
    local initial_prompt="$1" FORCE_EDIT="${FORCE_EDIT:-false}"
    local IMPORT_URLS=("${IMPORT_URLS[@]:-}") MAX_LOOPS=3
    PROOF_TASK_ID=$(gen_task_id "$initial_prompt")
    PROOF_CYCLE_INDEX=0; PROOF_NET_WORTH_INDEX=0
    local current_context="$initial_prompt" last_fused_output="" converged=0
    detect_frameworks "$initial_prompt"; calculate_complexity "$initial_prompt"
    log_event "TASK_START" "Prompt: $initial_prompt" "TaskID: $PROOF_TASK_ID, Complexity: $PROOF_COMPLEXITY, Frameworks: $PROOF_FRAMEWORKS"
    if [[ ${#IMPORT_URLS[@]} -gt 0 ]]; then
        thinking "Importing URLs into context..." 1
        for url in "${IMPORT_URLS[@]}"; do _cmd_import "$url"; done
    fi
    echo -e "\n${COLOR_BRIGHT}${COLOR_MAGENTA}🎯 STARTING AI LOOP (Task ID: $PROOF_TASK_ID)$COLOR_RESET"
    echo -e "${COLOR_GRAY}Complexity: $PROOF_COMPLEXITY | Target: $PROOF_FRAMEWORKS$COLOR_RESET\n"
    for ((i=1; i<=MAX_LOOPS; i++)); do
        echo -e "\n${COLOR_CYAN}[AI LOOP $i/$MAX_LOOPS]$COLOR_RESET"
        thinking "Running consensus iteration $i..." 1
        local consensus_output
        consensus_output=$(_run_consensus_iteration POOL_MODELS MODEL_WEIGHTS "$current_context" "$i")
        local reasoning="Initial pass. Checking for convergence." is_converged=0 current_proof_state="DIVERGED"
        if [[ "$consensus_output" == "$last_fused_output" ]] && [[ -n "$consensus_output" ]]; then
            is_converged=1; current_proof_state="CONVERGED"
            reasoning="Consensus output matched the previous iteration. Convergence achieved."
        fi
        proof_cycle "$is_converged" "$reasoning"
        add_memory_enhanced "$current_context" "$consensus_output" "$current_proof_state" "$PROOF_FRAMEWORKS" "$PROOF_COMPLEXITY" "$reasoning"
        echo -e "${COLOR_GREEN}[Consensus Output (Proof: $current_proof_state)]$COLOR_RESET"
        if [[ "$is_converged" == 1 ]]; then converged=1; break; fi
        last_fused_output="$consensus_output"
        current_context="$initial_prompt"$'\n\n'"--- Previous Consensus Output for Refinement ---"$'\n'"$consensus_output"
    done
    thinking "Finalizing task and generating artifacts..." 1
    local final_content="$last_fused_output"
    local final_state=$([[ "$converged" == 1 ]] && echo "CONVERGED" || echo "MAX_LOOPS_REACHED")
    log_event "TASK_END" "Task finished with state: $final_state" "NetWorth: $PROOF_NET_WORTH_INDEX"
    local file_type="default_web_triad" main_content="$final_content"
    local base_filename="$TASKS_DIR/task_${PROOF_TASK_ID}" primary_file_path=""
    if [[ "$final_content" =~ ^GENERATE_FILE: ]]; then
        file_type=$(echo "$final_content" | sed -n 's/^GENERATE_FILE:\([^[:space:]]*\).*$/\1/p')
        main_content=$(echo "$final_content" | sed '1d')
        echo -e "${COLOR_CYAN}[Detected File Type Directive] $file_type$COLOR_RESET"
    fi
    if [[ "$FORCE_EDIT" == true ]] || [[ "$final_content" =~ "GENERATE_CODE" ]] || [[ "$file_type" != "default_web_triad" ]]; then
        case "$file_type" in
            bash_script) primary_file_path="${base_filename}.sh"; echo "$main_content" > "$primary_file_path"; chmod +x "$primary_file_path"; log_event "SUCCESS" "Generated Bash Script: $primary_file_path" ;;
            python_script) primary_file_path="${base_filename}.py"; echo "$main_content" > "$primary_file_path"; log_event "SUCCESS" "Generated Python Script: $primary_file_path" ;;
            html_single|html_component|react_component|angular_component) primary_file_path="${base_filename}.html"; echo "<!-- Code generated by SysOp-AI ($file_type) -->$main_content" > "$primary_file_path"; log_event "SUCCESS" "Generated Single HTML/Component File: $primary_file_path" ;;
            *) primary_file_path="${base_filename}.html"; echo "<!-- HTML generated by AI -->$main_content" > "$primary_file_path"; echo "// JS generated by AI" > "${base_filename}.js"; echo "/* CSS generated by AI */" > "${base_filename}.css"; add_blob "${base_filename}.js" "// JS"; add_blob "${base_filename}.css" "/* CSS"; log_event "SUCCESS" "Generated HTML, JS, CSS triad."; git -C "$AI_HOME" add "${base_filename}.js" "${base_filename}.css" || true ;;
        esac
        add_blob "$primary_file_path" "$(cat "$primary_file_path")"
        git -C "$AI_HOME" add "$primary_file_path" || true
        git -C "$AI_HOME" commit -m "AI task $PROOF_TASK_ID ($file_type) - Final Artifact" || true
        echo -e "${COLOR_GREEN}[Git] Committed changes to task $PROOF_TASK_ID.$COLOR_RESET"
        if [[ -f "$primary_file_path" ]]; then
            echo -e "\n${COLOR_BRIGHT}${COLOR_GREEN}--- FINAL ARTIFACT ($primary_file_path) ---$COLOR_RESET"
            highlight_file "$primary_file_path"
            echo -e "${COLOR_BRIGHT}${COLOR_GREEN}-------------------------------------------$COLOR_RESET\n"
        fi
    else
        echo -e "\n${COLOR_YELLOW}[INFO] Task completed but no file generation directive found. Output was textual.$COLOR_RESET"
        echo "$final_content"
    fi
}

# ==============================================================================
# SECTION 2: CLI COMMANDS & DISPATCHER (## REFACTORED SECTION ##)
# ==============================================================================

_show_main_help() {
    # ## MODIFIED ##: Replaced grep with printf for clean formatting.
    printf "${COLOR_BRIGHT}SysOp-AI: A Self-Contained AI Command-Line Application${COLOR_RESET}\n\n"
    printf "This script provides a framework for interacting with a pool of local language\n"
    printf "models via Ollama to perform tasks, generate code, and persist its state.\n\n"
    printf "${COLOR_YELLOW}USAGE:${COLOR_RESET}\n"
    printf "  sysop-ai <command> [options]\n\n"
    printf "${COLOR_YELLOW}COMMANDS:${COLOR_RESET}\n"
    printf "  ${COLOR_GREEN}run <prompt>${COLOR_RESET}\t  Runs the main AI loop with a given prompt.\n"
    printf "  ${COLOR_GREEN}import <url...>${COLOR_RESET}\t  Imports content from one or more URLs.\n"
    printf "  ${COLOR_GREEN}memories${COLOR_RESET}\t\t  Lists the AI's past interactions.\n"
    printf "  ${COLOR_GREEN}events${COLOR_RESET}\t\t  Shows the detailed event log.\n"
    printf "  ${COLOR_GREEN}blobs${COLOR_RESET}\t\t  Lists all files stored in the blob database.\n"
    printf "  ${COLOR_GREEN}status${COLOR_RESET}\t\t  Displays configuration and environment status.\n"
    printf "  ${COLOR_GREEN}help${COLOR_RESET}\t\t  Shows this help message.\n\n"
    printf "See 'sysop-ai <command> --help' for more information on a specific command.\n"
}

_show_run_help() {
    # ## NEW FUNCTION ##: Dedicated help for the 'run' command.
    printf "${COLOR_BRIGHT}Usage: sysop-ai run <prompt> [options]${COLOR_RESET}\n\n"
    printf "Runs the main AI loop to process a prompt, converge on a solution, and generate artifacts.\n\n"
    printf "${COLOR_YELLOW}ARGUMENTS:${COLOR_RESET}\n"
    printf "  ${COLOR_GREEN}<prompt>${COLOR_RESET}\t The instructional text for the AI to process.\n\n"
    printf "${COLOR_YELLOW}OPTIONS:${COLOR_RESET}\n"
    printf "  ${COLOR_GREEN}--force${COLOR_RESET}\t\t Force file generation even without a 'GENERATE_CODE' directive.\n"
    printf "  ${COLOR_GREEN}--import <url>${COLOR_RESET}\t Import a URL's content into the context before running. Can be used multiple times.\n"
    printf "  ${COLOR_GREEN}--help${COLOR_RESET}\t\t Show this help message.\n"
}

_cmd_run() {
    # ## MODIFIED ##: More robust argument parsing loop.
    local PROMPT=""
    FORCE_EDIT=false
    IMPORT_URLS=()
    local args=()

    # Separate flags from positional arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) FORCE_EDIT=true; shift ;;
            --import)
                if [[ -z "${2:-}" ]]; then echo "Error: --import requires a URL." >&2; exit 1; fi
                IMPORT_URLS+=("$2"); shift 2 ;;
            --help) _show_run_help; exit 0 ;;
            -*) echo "Error: Unknown option '$1'" >&2; _show_run_help >&2; exit 1 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    PROMPT="${args[*]}"
    if [[ -z "$PROMPT" ]]; then
        echo "Error: 'run' command requires a prompt." >&2
        _show_run_help >&2
        exit 1
    fi

    run_ai_loop "$PROMPT"
}

_cmd_import() {
    if [[ $# -eq 0 ]]; then echo "Error: 'import' command requires at least one URL." >&2; exit 1; fi
    for url in "$@"; do
        echo -e "${COLOR_CYAN}[Importing URL]$COLOR_RESET $url"
        # ## MODIFIED ##: Improved sanitization for filenames.
        local safe_basename
        safe_basename=$(basename "$url" | sed 's/[^a-zA-Z0-9._-]/_/g' | cut -c 1-64)
        local filename="$TASKS_DIR/$safe_basename"
        local content
        content=$(curl -sL "$url")
        echo "$content" > "$filename"
        add_blob "$filename" "$content"
        log_event "SUCCESS" "Imported URL content." "Filename: $filename"
    done
}

_cmd_memories() {
    echo -e "${COLOR_BRIGHT}--- AI Memory Log (Last 20) ---$COLOR_RESET"
    sqlite3 -header -column "$AI_DB" \
        "SELECT id, datetime(ts) as timestamp, task_id, complexity, framework, substr(prompt, 1, 40) AS prompt_summary, proof_state FROM memories ORDER BY id DESC LIMIT 20;"
}

_cmd_events() {
    echo -e "${COLOR_BRIGHT}--- AI Event Log (Last 20) ---$COLOR_RESET"
    sqlite3 -header -column "$AI_DB" \
        "SELECT id, datetime(ts) as timestamp, event_type, message FROM events ORDER BY id DESC LIMIT 20;"
}

_cmd_blobs() {
    echo -e "${COLOR_BRIGHT}--- Stored Blobs ---$COLOR_RESET"
    sqlite3 -header -column "$BLOBS_DB" \
        "SELECT id, datetime(created_at) as created_at, filename FROM blobs ORDER BY id DESC;"
}

_cmd_status() {
    # ## MODIFIED ##: Using printf for clean, aligned output.
    printf "${COLOR_BRIGHT}--- SysOp-AI Status ---${COLOR_RESET}\n"
    printf "${COLOR_BLUE}  ⚙️  CONFIGURATION:${COLOR_RESET}\n"
    printf "  %-20s %s\n" "AI_HOME:" "$AI_HOME"
    printf "  %-20s %s\n" "AI_DB:" "$AI_DB"
    printf "  %-20s %s\n" "OLLAMA_BIN:" "$OLLAMA_BIN"
    printf "${COLOR_BLUE}  🧠 VERBOSE SETTINGS:${COLOR_RESET}\n"
    printf "  %-20s %s\n" "Verbose Thinking:" "$VERBOSE_THINKING"
    printf "  %-20s %s\n" "Show Reasoning:" "$SHOW_REASONING"
    printf "  %-20s %s s\n" "Thinking Delay:" "$THINKING_DELAY"
    
    printf "${COLOR_BLUE}  🤖 OLLAMA STATUS:${COLOR_RESET}\n"
    if ! command -v "$OLLAMA_BIN" &>/dev/null; then
        printf "  %-20s ${COLOR_RED}%s${COLOR_RESET}\n" "Status:" "Not found or not executable"
    else
        printf "  %-20s ${COLOR_GREEN}%s${COLOR_RESET}\n" "Status:" "Found"
    fi
    printf "  Configured Models:\n"
    for model in "${POOL_MODELS[@]}"; do
        printf "    - %s (Weight: %s)\n" "$model" "${MODEL_WEIGHTS[$model]}"
    done
    
    printf "${COLOR_BLUE}  💾 DATABASE SUMMARY:${COLOR_RESET}\n"
    local memory_count; memory_count=$(sqlite3 "$AI_DB" "SELECT COUNT(*) FROM memories;" 2>/dev/null || echo 0)
    local event_count; event_count=$(sqlite3 "$AI_DB" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo 0)
    local blob_count; blob_count=$(sqlite3 "$BLOBS_DB" "SELECT COUNT(*) FROM blobs;" 2>/dev/null || echo 0)
    printf "  %-20s %s\n" "Total Memories:" "$memory_count"
    printf "  %-20s %s\n" "Total Events:" "$event_count"
    printf "  %-20s %s\n" "Total Blobs:" "$blob_count"
}

# --- Main Command Dispatcher ---
_main() {
    if [[ $# -eq 0 ]]; then
        _show_main_help
        exit 1
    fi

    local command="$1"
    shift

    _initialize_env
    _git_setup

    case "$command" in
        run) _cmd_run "$@" ;;
        import) _cmd_import "$@" ;;
        memories) _cmd_memories "$@" ;;
        events) _cmd_events "$@" ;;
        blobs) _cmd_blobs "$@" ;;
        status) _cmd_status "$@" ;;
        help|--help|-h) _show_main_help ;;
        *)
            echo -e "${COLOR_RED}Error: Unknown command '$command'$COLOR_RESET" >&2
            _show_main_help >&2
            exit 1
            ;;
    esac
}

# Execute the main function with all script arguments
_main "$@"
