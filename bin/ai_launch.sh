#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ensure environment
AI_HOME="${HOME}/.local_ai"
DB="$AI_HOME/ai_modules.db"

mkdir -p "$AI_HOME/logs"
mkdir -p "$AI_HOME/modules"

# Start Ollama if not running
if ! pgrep -x ollama >/dev/null 2>&1; then
    nohup ollama serve > "$AI_HOME/logs/ollama_server.log" 2>&1 &
fi

# Self-healing DB: create table if missing
sqlite3 "$DB" <<'EOF'
CREATE TABLE IF NOT EXISTS modules (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    script BLOB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

echo "[INFO] AI environment ready."
