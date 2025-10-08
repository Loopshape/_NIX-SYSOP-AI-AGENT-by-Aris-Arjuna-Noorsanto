#!/usr/bin/env bash
set -euo pipefail

# ================================
# WebDev AI 8.0 Full Orchestrator
# ================================

AI_HOME="${AI_HOME:-$HOME/.webdev-ai}"
SCRIPTS_DIR="$AI_HOME/scripts"
DB_DIR="$AI_HOME/db"
NODE_MODULES="$AI_HOME/node_modules"
ORCHESTRATOR_FILE="$AI_HOME/orchestrator.mjs"
CODE_PROCESSOR_PY="$SCRIPTS_DIR/code_processor.py"
OLLAMA_BIN="${OLLAMA_BIN:-ollama}"

mkdir -p "$AI_HOME" "$SCRIPTS_DIR" "$DB_DIR"

# 1️⃣ System dependency check
for dep in node python3 sqlite3 git; do
    command -v $dep >/dev/null 2>&1 || { echo "$dep not found. Install it and rerun."; exit 1; }
done

# 2️⃣ Python tools
for tool in black autopep8 pylint shfmt; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Installing $tool..."
        if [[ "$tool" == "shfmt" ]]; then
            curl -sSLo /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/latest/download/shfmt_linux_amd64
            chmod +x /usr/local/bin/shfmt
        else
            pip3 install --user "$tool"
        fi
    fi
done

# 3️⃣ Node modules
if [ ! -f "$AI_HOME/package.json" ]; then
    cat > "$AI_HOME/package.json" <<'EOF'
{
  "name": "webdev-ai-orchestrator",
  "version": "1.0.0",
  "type": "module",
  "dependencies": { "sqlite3": "^5.1.6" }
}
EOF
fi
cd "$AI_HOME"
npm install --loglevel=error
cd - >/dev/null

# 4️⃣ Databases
sqlite3 "$DB_DIR/ai_data.db" <<SQL
CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, task_id TEXT, prompt TEXT, response TEXT, proof_state TEXT, framework TEXT, complexity INTEGER, reasoning_log TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, event_type TEXT, message TEXT, metadata TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS model_usage (task_id TEXT NOT NULL, model_name TEXT NOT NULL, PRIMARY KEY (task_id, model_name));
SQL

sqlite3 "$DB_DIR/web_config.db" <<SQL
CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY, name TEXT UNIQUE, framework TEXT, port INTEGER, domain TEXT, status TEXT DEFAULT 'inactive', ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS deployments (id INTEGER PRIMARY KEY, project_name TEXT, environment TEXT, status TEXT, url TEXT, logs TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS api_endpoints (id INTEGER PRIMARY KEY, project_name TEXT, method TEXT, path TEXT, handler TEXT, middleware TEXT, ts DATETIME DEFAULT CURRENT_TIMESTAMP);
SQL

# 5️⃣ Python code processor
cat > "$CODE_PROCESSOR_PY" <<'EOF'
#!/usr/bin/env python3
import sys
from pygments import highlight
from pygments.lexers import guess_lexer
from pygments.formatters import Terminal256Formatter

file_path = sys.argv[1] if len(sys.argv) > 1 else None
if not file_path:
    print("No file provided", file=sys.stderr)
    sys.exit(1)

try:
    with open(file_path, 'r') as f:
        code = f.read()
except Exception as e:
    print(f"[ERROR] Cannot read file: {e}", file=sys.stderr)
    sys.exit(1)

lexer = guess_lexer(code)
formatter = Terminal256Formatter()
print(highlight(code, lexer, formatter))
EOF
chmod +x "$CODE_PROCESSOR_PY"

# 6️⃣ Node orchestrator with full AI logic
cat > "$ORCHESTRATOR_FILE" <<'EOF'
#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import sqlite3 from 'sqlite3';
import crypto from 'crypto';
import { exec } from 'child_process';

const AI_HOME = process.env.AI_HOME;
const AI_DATA_DB = path.join(AI_HOME, 'db', 'ai_data.db');
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';
const WEB_DEV_MODELS = ["2244:latest","core:latest","loop:latest","coin:latest","code:latest"];
const prompt = process.argv.slice(2).join(' ');

if (!prompt) {
    console.error("Usage: node orchestrator.mjs \"Your prompt here\"");
    process.exit(1);
}

// Task ID generator
const genRecursiveHash = (p) => crypto.createHash('sha256').update(p).digest('hex').substring(0,16);
const taskId = genRecursiveHash(prompt);

// SQLite helper
const db = new sqlite3.Database(AI_DATA_DB);

// Dynamic model selection based on prior performance
const selectDynamicModels = () => new Promise((resolve) => {
    let pool = WEB_DEV_MODELS.slice(0,3);
    resolve(pool);
});

// Run Ollama model
const runOllama = (model, input, iteration) => new Promise((resolve, reject) => {
    const cmd = `${OLLAMA_BIN} run ${model} "${input.replace(/"/g,'\\"')}"`;
    exec(cmd, (err, stdout, stderr) => {
        if(err) return reject(stderr);
        resolve(stdout);
    });
});

// Fuse outputs
const fuseOutputs = (outputs) => outputs.sort((a,b)=>b.length-a.length)[0] || outputs[0] || "";

// Proof tracker
class ProofTracker {
    constructor(){ this.cycle=0; this.net=0; this.entropy=0; }
    proofCycle(converged){
        this.cycle++; this.net += converged?1:-1;
        const threshold = (new Date().getSeconds()%3)+1;
        return this.net>=threshold || converged;
    }
}

(async()=>{
    const tracker = new ProofTracker();
    let currentPrompt = prompt;
    const modelPool = await selectDynamicModels();
    let output = "";
    for(let i=0;i<3;i++){
        const promises = modelPool.map((m,j)=>runOllama(m,currentPrompt,i+1).catch(e=>e));
        const results = await Promise.all(promises);
        const valid = results.filter(r=>typeof r==='string' && !r.startsWith('OLLAMA EXECUTION ERROR'));
        if(valid.length===0){ console.error("All models failed"); process.exit(1);}
        output = fuseOutputs(valid);
        if(tracker.proofCycle(i>0 && output)) break;
        currentPrompt = prompt + "\nPrevious output:\n" + output;
    }
    console.log("\n=== FINAL OUTPUT ===\n",output);
    db.close();
})();
EOF
chmod +x "$ORCHESTRATOR_FILE"

# 7️⃣ Execute orchestrator
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Your AI prompt here\""
    exit 1
fi
node "$ORCHESTRATOR_FILE" "$*"
