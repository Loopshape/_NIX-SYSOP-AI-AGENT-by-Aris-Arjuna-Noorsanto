#!/usr/bin/env bash
set -euo pipefail

# === Environment & Config ===
export AI_HOME="${AI_HOME:-$HOME/.sysop-ai}"
export NODE_MODULES="$AI_HOME/node_modules"
export ORCHESTRATOR_FILE="$AI_HOME/orchestrator.mjs"
export DB_DIR="$AI_HOME/db"
export AI_DATA_DB="$DB_DIR/ai_data.db"
export BLOBS_DB="$DB_DIR/blobs.db"
export SESSION_FILE="$AI_HOME/.session"
export OLLAMA_BIN="ollama"
export NODE_PATH="${NODE_PATH:-}:$NODE_MODULES"

# === Logging ===
log_event() {
    echo "[INFO] $(date): $1"
    sqlite3 "$AI_DATA_DB" "INSERT INTO events (event_type,message) VALUES ('INFO','$1');" || true
}

# === Dependency Checks ===
check_dependencies() {
    local deps=("node" "python3" "git" "$OLLAMA_BIN" "pygmentize")
    local missing=()
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null || missing+=("$dep")
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# === DB Initialization ===
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
    log_event "Databases initialized"
}

# === Run AI Task ===
run_ai_task() {
    local full_prompt="$*"
    [ -f "$SESSION_FILE" ] && full_prompt="$full_prompt --project=$(cat "$SESSION_FILE")"
    log_event "TASK_START: $full_prompt"
    node "$ORCHESTRATOR_FILE" $full_prompt
    log_event "TASK_END"
}

# === Session Management ===
start_session() {
    read -p "Project/Repo name: " proj
    echo "$proj" > "$SESSION_FILE"
    log_event "Session started for $proj"
}

stop_session() {
    rm -f "$SESSION_FILE"
    log_event "Session stopped"
}

# === Status ===
status_check() {
    echo "SysOp-AI Status:"
    echo "NodeJS: $(command -v node &>/dev/null && echo OK || echo Not Found)"
    echo "Python3: $(command -v python3 &>/dev/null && echo OK || echo Not Found)"
    echo "Ollama: $(command -v $OLLAMA_BIN &>/dev/null && echo OK || echo Not Found)"
    echo "Pygments: $(command -v pygmentize &>/dev/null && echo OK || echo Not Found)"
    [ -f "$SESSION_FILE" ] && echo "Active Session: $(cat $SESSION_FILE)" || echo "Active Session: None"
}

# === Main Execution ===
check_dependencies
init_databases

if [ $# -eq 0 ]; then
    status_check
    exit 0
fi

COMMAND="$1"; shift

case "$COMMAND" in
    --start) start_session ;;
    --stop) stop_session ;;
    run) run_ai_task "$@" ;;
    status) status_check ;;
    *) run_ai_task "$COMMAND $@" ;;
esac