#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DB="$HOME/.local_ai/ai_modules.db"
MODULE_DIR="$HOME/.local_ai/modules"

echo "[INFO] Self-healing DB..."

# Ensure the database exists and has the right table
sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS modules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    script BLOB,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

# Scan module directory
for module in "$MODULE_DIR"/*.sh; do
    [ -f "$module" ] || continue
    modname=$(basename "$module" .sh)
    
    # Insert or replace module as BLOB
    sqlite3 "$DB" <<SQL
INSERT INTO modules(name, script, updated_at)
VALUES (
    '$modname',
    readfile('$module'),
    CURRENT_TIMESTAMP
)
ON CONFLICT(name) DO UPDATE SET
    script=excluded.script,
    updated_at=CURRENT_TIMESTAMP;
SQL

    echo "[INFO] Module stored: $modname"
done

echo "[INFO] Self-healing DB completed."
