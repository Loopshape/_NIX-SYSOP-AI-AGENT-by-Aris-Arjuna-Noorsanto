#!/usr/bin/env bash
set -euo pipefail

# ███████╗██╗   ██╗███████╗ ██████╗ ██████╗ █████╗ ██╗    ██████╗ ██████╗ ██████╗ ███████╗
# ██╔════╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║    ██╔══██╗██╔══██╗██╔══██╗██╔════╝
# ███████╗ ╚████╔╝ █████╗  ██║   ██║██████╔╝███████║██║    ██║  ██║██████╔╝██████╔╝█████╗  
# ╚════██║  ╚██╔╝  ██╔══╝  ██║   ██║██╔═══╝ ██╔══██║██║    ██║  ██║██╔═══╝ ██╔═══╝ ██╔══╝  
# ███████║   ██║   ███████╗╚██████╔╝██║     ██║  ██║███████╗██████╔╝██║     ██║     ███████╗
# ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝     ╚══════╝
#
# WebDev Code-Engine Scripting Assistant
# Version: 4.0.1 (Fixed Function Ordering)

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

# --- Enhanced Logging ---
log_event() {
    local level="$1"
    local message="$2"
    local color=""
    
    case "$level" in
        "ERROR") color="\x1b[31m" ;;
        "WARN") color="\x1b[33m" ;;
        "SUCCESS") color="\x1b[32m" ;;
        "INFO") color="\x1b[34m" ;;
        "DEBUG") color="\x1b[35m" ;;
        *) color="\x1b[36m" ;;
    esac
    
    echo "[${color}${level}\x1b[0m] $(date): $message"
    sqlite3 "$AI_DATA_DB" "INSERT INTO events (event_type, message) VALUES ('$level', '$message');" 2>/dev/null || true
}

# --- Enhanced Dependency Checks ---
check_node_modules() {
    log_event "INFO" "Checking Node.js modules..."
    local required_modules=("sqlite3" "express" "axios" "chalk" "inquirer" "ws" "body-parser" "cors")
    
    for module in "${required_modules[@]}"; do
        if [ ! -d "$NODE_MODULES/$module" ]; then
            log_event "INFO" "Installing Node module: $module"
            npm install --prefix "$AI_HOME" $module --silent
        fi
    done
}

check_dependencies() {
    log_event "INFO" "Checking system dependencies..."
    local missing_deps=()
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    check_node_modules
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_event "ERROR" "Missing dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    log_event "SUCCESS" "All dependencies satisfied"
}

check_web_dependencies() {
    log_event "INFO" "Checking web development dependencies..."
    local missing_deps=()
    local web_deps=("curl" "jq" "nginx" "certbot" "docker" "git" "node" "python3" "php" "sqlite3")
    
    for dep in "${web_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_event "WARN" "Missing web dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    log_event "SUCCESS" "All web dependencies satisfied"
    return 0
}

# Web Development Framework Detection
detect_frameworks() {
    local project_path="${1:-$PWD}"
    local frameworks=()
    
    [ -f "$project_path/package.json" ] && frameworks+=("nodejs")
    [ -f "$project_path/requirements.txt" ] && frameworks+=("python")
    [ -f "$project_path/composer.json" ] && frameworks+=("php")
    [ -f "$project_path/go.mod" ] && frameworks+=("go")
    [ -f "$project_path/Cargo.toml" ] && frameworks+=("rust")
    [ -f "$project_path/Gemfile" ] && frameworks+=("ruby")
    [ -d "$project_path/.next" ] && frameworks+=("nextjs")
    [ -f "$project_path/nuxt.config.js" ] || [ -f "$project_path/nuxt.config.ts" ] && frameworks+=("nuxtjs")
    [ -f "$project_path/vue.config.js" ] && frameworks+=("vue")
    [ -f "$project_path/angular.json" ] && frameworks+=("angular")
    [ -f "$project_path/react-native.config.js" ] && frameworks+=("react-native")
    
    echo "${frameworks[@]}"
}

# --- Enhanced Database Initialization ---
init_databases() {
    log_event "INFO" "Initializing databases..."
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

# --- Web Development Templates ---
setup_web_templates() {
    log_event "INFO" "Setting up web development templates..."
    mkdir -p "$TEMPLATES_DIR"
    
    # React Component Template
    cat > "$TEMPLATES_DIR/react_component.jsx" <<'REACT'
import React from 'react';
import './{{componentName}}.css';

const {{componentName}} = ({ {{props}} }) => {
    return (
        <div className="{{componentName}}">
            {/* Component content */}
        </div>
    );
};

export default {{componentName}};
REACT

    # Express API Template
    cat > "$TEMPLATES_DIR/express_api.js" <<'EXPRESS'
const express = require('express');
const router = express.Router();

// {{routeDescription}}
router.{{method}}('{{routePath}}', async (req, res) => {
    try {
        // Implementation here
        res.json({ success: true, data: {} });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
EXPRESS

    # Database Migration Template
    cat > "$TEMPLATES_DIR/migration.sql" <<'SQL'
-- Migration: {{migrationName}}
-- Created: {{timestamp}}

BEGIN TRANSACTION;

{{migrationSQL}}

COMMIT;
SQL

    log_event "SUCCESS" "Web development templates installed"
}

# --- Enhanced Orchestrator with WebDev Focus ---
setup_orchestrator() {
    log_event "INFO" "Setting up enhanced orchestrator..."
    mkdir -p "$AI_HOME"
    cat > "$ORCHESTRATOR_FILE" <<'EOF_JS'
// Enhanced WebDev Code-Engine Orchestrator
import { exec, spawn } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3Pkg from 'sqlite3';
import axios from 'axios';
import chalk from 'chalk';
const { verbose } = sqlite3Pkg;
const sqlite3 = verbose();

// Enhanced Environment
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR;
const TEMPLATES_DIR = process.env.TEMPLATES_DIR;
const SCRIPTS_DIR = process.env.SCRIPTS_DIR;
const AI_DATA_DB_PATH = process.env.AI_DATA_DB;
const BLOBS_DB_PATH = process.env.BLOBS_DB;
const WEB_CONFIG_DB_PATH = process.env.WEB_CONFIG_DB;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';

// Enhanced Model Pool for Web Development
const WEB_DEV_MODELS = ["llama3.1:8b", "codellama:13b", "mistral:7b", "starling-lm:7b", "wizardcoder:15b"];

// Framework-specific prompts
const FRAMEWORK_PROMPTS = {
    react: "You are an expert React developer. Create modern, responsive React components with hooks and best practices.",
    vue: "You are a Vue.js specialist. Build Vue 3 components with Composition API and TypeScript.",
    angular: "You are an Angular expert. Create Angular components with RxJS, services, and dependency injection.",
    node: "You are a Node.js backend expert. Build scalable APIs with Express.js, middleware, and database integration.",
    python: "You are a Python web developer. Create Flask/FastAPI applications with async support.",
    nextjs: "You are a Next.js expert. Build server-side rendered React applications with API routes.",
    nuxtjs: "You are a Nuxt.js specialist. Create Vue.js applications with SSR and static site generation."
};

class WebDevProofTracker {
    constructor(initialPrompt, detectedFrameworks = []) {
        this.cycleIndex = initialPrompt.length;
        this.netWorthIndex = (this.cycleIndex % 128) << 2;
        this.entropyRatio = (this.cycleIndex ^ Date.now()) / 1000;
        this.frameworks = detectedFrameworks;
        this.complexityScore = this.calculateComplexity(initialPrompt);
    }

    calculateComplexity(prompt) {
        let score = 0;
        const complexityKeywords = [
            'authentication', 'database', 'api', 'middleware', 'component', 
            'responsive', 'ssr', 'state management', 'deployment', 'docker'
        ];
        complexityKeywords.forEach(keyword => {
            if (prompt.toLowerCase().includes(keyword)) score += 2;
        });
        return Math.min(score, 10);
    }

    crosslineEntropy(data) {
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(hash.substring(0, 8), 16);
    }

    proofCycle(converged, frameworkUsed = '') {
        this.cycleIndex += converged ? 1 : 0;
        this.netWorthIndex -= converged ? 0 : 1;
        if (frameworkUsed && !this.frameworks.includes(frameworkUsed)) {
            this.frameworks.push(frameworkUsed);
        }
    }

    getState() {
        return {
            cycleIndex: this.cycleIndex,
            netWorthIndex: this.netWorthIndex,
            entropyRatio: this.entropyRatio,
            frameworks: this.frameworks,
            complexityScore: this.complexityScore
        };
    }
}

class WebDevOrchestrator {
    constructor(prompt, options) {
        this.initialPrompt = prompt;
        this.options = options;
        this.taskId = crypto.createHash('sha256').update(Date.now().toString()).digest('hex');
        this.detectedFrameworks = this.detectFrameworksFromPrompt(prompt);
        this.proofTracker = new WebDevProofTracker(prompt, this.detectedFrameworks);
    }

    detectFrameworksFromPrompt(prompt) {
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
        return detected.length > 0 ? detected : ['node', 'react']; // Default frameworks
    }

    getEnhancedSystemPrompt(framework) {
        const basePrompt = FRAMEWORK_PROMPTS[framework] || 
            "You are a full-stack web developer expert. Create production-ready code with best practices.";
        
        return `${basePrompt}
        
CRITICAL REQUIREMENTS:
- Generate COMPLETE, WORKING code - no placeholders or TODOs
- Include all necessary imports and dependencies
- Add proper error handling and validation
- Use modern ES6+ syntax and latest framework features
- Include responsive design considerations
- Add security best practices
- Include deployment configuration where applicable

User Task: `;
    }

    async runOllama(model, currentPrompt, framework) {
        return new Promise((resolve, reject) => {
            const enhancedPrompt = this.getEnhancedSystemPrompt(framework) + currentPrompt;
            console.log(chalk.blue(`\n[${framework.toUpperCase()}]`), chalk.yellow(`Model '${model}' generating...`));
            
            const command = `${OLLAMA_BIN} run ${model} "${enhancedPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(command);
            let output = '';
            
            child.on('error', (err) => {
                reject(`OLLAMA EXECUTION ERROR: ${err.message}`);
            });
            
            child.stdout.on('data', data => {
                process.stdout.write(chalk.gray(data));
                output += data;
            });
            
            child.stderr.on('data', data => process.stderr.write(chalk.red(data)));
            
            child.on('close', code => {
                if (code !== 0) return reject(`Model ${model} exited with code ${code}`);
                resolve(output.trim());
            });
        });
    }

    async recursiveConsensus() {
        let currentPrompt = this.initialPrompt;
        let lastFusedOutput = "";
        let converged = false;
        let bestFramework = this.detectedFrameworks[0] || 'node';

        for (let i = 0; i < 3 && !converged; i++) {
            const promises = WEB_DEV_MODELS.map(model => 
                this.runOllama(model, currentPrompt, bestFramework).catch(e => e)
            );
            
            const results = await Promise.all(promises);
            const validResults = results.filter(r => 
                typeof r === 'string' && r.length > 0 && !r.startsWith('OLLAMA EXECUTION ERROR')
            );

            if (validResults.length === 0) {
                return "Error: All models failed. Please check Ollama installation and model availability.";
            }

            this.proofTracker.crosslineEntropy(validResults.join(''));
            const fusedOutput = this.fuseWebOutputs(validResults);
            
            if (fusedOutput === lastFusedOutput) {
                converged = true;
                this.proofTracker.proofCycle(true, bestFramework);
            } else {
                this.proofTracker.proofCycle(false, bestFramework);
            }

            lastFusedOutput = fusedOutput;
            currentPrompt = this.initialPrompt + `\n\nPrevious iteration output for improvement:\n${fusedOutput}`;
            this.logEvent('CONSENSUS_LOOP', `Iteration ${i + 1}, Framework: ${bestFramework}, Converged: ${converged}`);
        }

        return lastFusedOutput;
    }

    fuseWebOutputs(results) {
        // Simple fusion: take the longest valid output (usually most complete)
        return results.reduce((longest, current) => 
            current.length > longest.length ? current : longest, ""
        );
    }

    // Enhanced file type detection
    getFileEnhancedExtension(language, framework) {
        const extensions = {
            javascript: framework === 'react' ? 'jsx' : 'js',
            typescript: framework === 'react' ? 'tsx' : 'ts',
            python: 'py',
            html: 'html',
            css: 'css',
            php: 'php',
            sql: 'sql',
            bash: 'sh',
            docker: 'Dockerfile',
            nginx: 'conf',
            json: 'json'
        };
        return extensions[language] || 'txt';
    }

    parseEnhancedCodeBlocks(content) {
        const regex = /```(\w+)\s*([\s\S]*?)```/g;
        const blocks = [];
        let match;
        
        while ((match = regex.exec(content)) !== null) {
            const language = match[1];
            let code = match[2].trim();
            
            // Remove language specification from the first line if present
            if (code.startsWith(match[1])) {
                code = code.substring(match[1].length).trim();
            }
            
            blocks.push({ 
                language: language, 
                code: code,
                framework: this.detectBlockFramework(code, language)
            });
        }
        
        // If no code blocks found, treat entire content as a file
        if (blocks.length === 0 && content.trim().length > 0) {
            blocks.push({
                language: 'javascript',
                code: content.trim(),
                framework: this.detectedFrameworks[0] || 'node'
            });
        }
        
        return blocks;
    }

    detectBlockFramework(code, language) {
        if (language === 'jsx' || code.includes('import React') || code.includes('export default function')) {
            return 'react';
        }
        if (code.includes('const express = require') || code.includes('app.get') || code.includes('app.post')) {
            return 'node';
        }
        if (code.includes('from flask import') || code.includes('@app.route')) {
            return 'python';
        }
        return this.detectedFrameworks[0] || 'node';
    }

    async handleEnhancedCodeGeneration(content) {
        const blocks = this.parseEnhancedCodeBlocks(content);
        if (!blocks.length) return;

        const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
        const projectPath = path.join(PROJECTS_DIR, project);
        
        // Create project structure
        const dirs = ['src', 'public', 'api', 'components', 'styles', 'config'];
        dirs.forEach(dir => fs.mkdirSync(path.join(projectPath, dir), { recursive: true }));

        // Create package.json for Node projects
        if (this.detectedFrameworks.includes('node') || this.detectedFrameworks.includes('react')) {
            const packageJson = {
                name: project,
                version: "1.0.0",
                scripts: {
                    dev: "next dev" || "node server.js",
                    build: "next build",
                    start: "next start" || "node server.js"
                },
                dependencies: {}
            };
            fs.writeFileSync(path.join(projectPath, 'package.json'), JSON.stringify(packageJson, null, 2));
        }

        // Generate files from code blocks
        for (const [i, block] of blocks.entries()) {
            const ext = this.getFileEnhancedExtension(block.language, block.framework);
            const fileName = this.generateFileName(block, i, ext);
            const filePath = path.join(projectPath, fileName);
            
            fs.writeFileSync(filePath, block.code);
            this.saveBlob(project, filePath, block.code);
            console.log(chalk.green(`[SUCCESS] Generated: ${filePath}`));
        }

        // Create deployment configurations
        this.generateDeploymentConfigs(projectPath, project);
        this.registerProject(project);
        this.gitCommit(project);
        
        console.log(chalk.cyan(`\n🎉 Project ${project} created successfully!`));
        console.log(chalk.cyan(`📁 Location: ${projectPath}`));
    }

    generateFileName(block, index, ext) {
        const baseNames = {
            react: 'components/Component',
            node: 'api/server',
            python: 'app/main',
            html: 'public/index',
            css: 'styles/main',
            docker: 'Dockerfile',
            nginx: 'config/nginx'
        };
        
        const base = baseNames[block.framework] || `src/file_${index}`;
        return `${base}.${ext}`;
    }

    generateDeploymentConfigs(projectPath, projectName) {
        // Dockerfile
        const dockerfile = `FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]`;
        
        fs.writeFileSync(path.join(projectPath, 'Dockerfile'), dockerfile);

        // Nginx config
        const nginxConf = `server {
    listen 80;
    server_name ${projectName}.local;
    root /app/public;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}`;
        
        fs.writeFileSync(path.join(projectPath, 'nginx.conf'), nginxConf);
    }

    // Enhanced persistence methods
    saveMemory(prompt, response) {
        const db = new sqlite3.Database(AI_DATA_DB_PATH);
        db.run(
            `INSERT INTO memories (task_id, prompt, response, proof_state, framework, complexity) VALUES (?, ?, ?, ?, ?, ?)`,
            [this.taskId, prompt, response, JSON.stringify(this.proofTracker.getState()), this.detectedFrameworks.join(','), this.proofTracker.complexityScore],
            err => { if (err) console.error(chalk.red('DB Error:'), err); db.close(); }
        );
    }

    saveBlob(project, file, content) {
        const db = new sqlite3.Database(BLOBS_DB_PATH);
        const fileType = path.extname(file).substring(1);
        db.run(
            `INSERT INTO blobs (project_name, file_path, content, file_type, framework) VALUES (?, ?, ?, ?, ?)`,
            [project, path.basename(file), content, fileType, this.detectedFrameworks.join(',')],
            err => { if (err) console.error(chalk.red('DB Error:'), err); db.close(); }
        );
    }

    registerProject(projectName) {
        const db = new sqlite3.Database(WEB_CONFIG_DB_PATH);
        db.run(
            `INSERT OR REPLACE INTO projects (name, framework, port, status) VALUES (?, ?, ?, ?)`,
            [projectName, this.detectedFrameworks.join(','), 3000, 'created'],
            err => { if (err) console.error(chalk.red('Project registration error:'), err); db.close(); }
        );
    }

    logEvent(type, msg) {
        const db = new sqlite3.Database(AI_DATA_DB_PATH);
        db.run(
            `INSERT INTO events (event_type, message) VALUES (?, ?)`,
            [type, msg],
            err => { if (err) console.error(chalk.red('Event logging error:'), err); db.close(); }
        );
    }

    gitCommit(project) {
        const cmd = `cd ${PROJECTS_DIR}/${project} && git init && git add . && git commit -m "feat: Initial web app generated by WebDev AI"`;
        exec(cmd, (err) => {
            if (err) this.logEvent('GIT_ERROR', `Failed to commit ${project}`);
            else this.logEvent('GIT_SUCCESS', `Committed ${project}`);
        });
    }

    async execute() {
        this.logEvent('WEB_DEV_START', `Task ${this.taskId} for frameworks: ${this.detectedFrameworks.join(',')}`);
        const finalOutput = await this.recursiveConsensus();
        
        console.log(chalk.bold.cyan("\n--- Final Web Development Output ---\n"));
        console.log(finalOutput);
        
        this.saveMemory(this.initialPrompt, finalOutput);
        await this.handleEnhancedCodeGeneration(finalOutput);
        
        this.logEvent('WEB_DEV_END', `Task ${this.taskId} completed successfully`);
    }
}

// Enhanced CLI with web development focus
(async () => {
    const args = process.argv.slice(2);
    const prompt = args.filter(arg => !arg.startsWith('--')).join(' ');

    const options = Object.fromEntries(
        args.filter(arg => arg.startsWith('--')).map(arg => {
            const parts = arg.slice(2).split('=');
            return [parts[0], parts.length > 1 ? parts.slice(1).join('=') : true];
        })
    );

    if (!prompt) {
        console.log(chalk.red('Error: No prompt provided. Usage: webdev-ai "create a react component for user dashboard"'));
        process.exit(1);
    }

    const orchestrator = new WebDevOrchestrator(prompt, options);
    await orchestrator.execute();
})();
EOF_JS

    log_event "SUCCESS" "Enhanced orchestrator created at $ORCHESTRATOR_FILE"
}

# --- Web Development Commands ---
setup_web_server() {
    local project_name="$1"
    local port="${2:-3000}"
    
    log_event "INFO" "Setting up web server for $project_name on port $port"
    
    # Create simple development server script
    cat > "$SCRIPTS_DIR/serve_$project_name.js" <<SERVER_JS
const express = require('express');
const path = require('path');
const app = express();
const port = $port;

app.use(express.static(path.join('$PROJECTS_DIR', '$project_name')));
app.use(express.json());

app.get('/', (req, res) => {
    res.sendFile(path.join('$PROJECTS_DIR', '$project_name', 'index.html'));
});

app.listen(port, () => {
    console.log(\`🚀 $project_name running at http://localhost:\${port}\`);
});
SERVER_JS

    node "$SCRIPTS_DIR/serve_$project_name.js" &
    echo $! > "$AI_HOME/server_$project_name.pid"
    log_event "SUCCESS" "Web server started for $project_name on port $port"
}

stop_web_server() {
    local project_name="$1"
    local pid_file="$AI_HOME/server_$project_name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        kill "$pid" 2>/dev/null && rm -f "$pid_file"
        log_event "INFO" "Stopped web server for $project_name"
    else
        log_event "WARN" "No running server found for $project_name"
    fi
}

deploy_project() {
    local project_name="$1"
    local environment="${2:-development}"
    
    log_event "INFO" "Deploying $project_name to $environment"
    
    # Simple deployment script
    case $environment in
        "development")
            setup_web_server "$project_name"
            ;;
        "production")
            # Build and deploy for production
            local project_path="$PROJECTS_DIR/$project_name"
            if [ -f "$project_path/package.json" ]; then
                cd "$project_path" && npm run build
                log_event "SUCCESS" "Project $project_name built for production"
            fi
            ;;
    esac
}

# --- Enhanced AI Task Runner ---
run_webdev_task() {
    local full_prompt="$*"
    local frameworks=$(detect_frameworks)

    # Enhanced prompt analysis for web development
    if [[ "$full_prompt" =~ (component|api|server|database|deploy|build|responsive) ]]; then
        log_event "INFO" "Web development task detected: $full_prompt"
        full_prompt="WEB DEVELOPMENT: $full_prompt - Generate complete, production-ready code with all necessary files."
    fi

    # Framework-specific enhancements
    if [[ "$full_prompt" =~ (react|vue|angular) ]]; then
        full_prompt="$full_prompt --framework=frontend"
    elif [[ "$full_prompt" =~ (node|express|python|flask) ]]; then
        full_prompt="$full_prompt --framework=backend"
    fi

    if [ -f "$SESSION_FILE" ]; then
        local proj=$(cat "$SESSION_FILE")
        full_prompt="$full_prompt --project=$proj"
    fi

    log_event "TASK_START" "WebDev Prompt: $full_prompt | Frameworks: $frameworks"
    node "$ORCHESTRATOR_FILE" $full_prompt
    log_event "TASK_END" "Web development task completed"
}

# --- Enhanced Status ---
enhanced_status() {
    echo "WebDev Code-Engine Status:"
    echo "AI_HOME: $AI_HOME"
    echo "Projects: $(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l) created"
    echo "Active Session: $([ -f "$SESSION_FILE" ] && cat "$SESSION_FILE" || echo "None")"
    
    # Show recent projects
    echo -e "\nRecent Projects:"
    sqlite3 "$WEB_CONFIG_DB" "SELECT name, framework, status FROM projects ORDER BY ts DESC LIMIT 3;" 2>/dev/null | while IFS='|' read name framework status; do
        echo "  - $name ($framework): $status"
    done || echo "  No projects yet"
}

# --- Installation Function ---
install_webdev_ai() {
    log_event "INFO" "Installing WebDev AI Code-Engine..."
    
    # Create directories
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR" "$LOG_DIR"
    
    # Initialize system
    check_dependencies
    init_databases
    setup_web_templates
    setup_orchestrator
    
    log_event "SUCCESS" "WebDev AI Code-Engine installation completed!"
    echo "🎉 Installation complete! You can now use:"
    echo "   webdev-ai 'create a react component for user dashboard'"
    echo "   webdev-ai --start my-project"
    echo "   webdev-ai status"
}

# --- Main Enhanced Execution ---
main() {
    # Ensure AI_HOME exists
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR"
    
    # Initialize core systems
    check_dependencies
    init_databases
    setup_web_templates
    setup_orchestrator

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
            ;;
        --stop)
            [ -f "$SESSION_FILE" ] && proj=$(cat "$SESSION_FILE") && log_event "SESSION" "Stopped session for $proj"
            rm -f "$SESSION_FILE"
            ;;
        --serve)
            proj="${1:-$(cat "$SESSION_FILE" 2>/dev/null)}"
            if [ -n "$proj" ]; then
                setup_web_server "$proj" "$2"
            else
                echo "Error: No project specified and no active session"
            fi
            ;;
        --stop-server)
            proj="${1:-$(cat "$SESSION_FILE" 2>/dev/null)}"
            if [ -n "$proj" ]; then
                stop_web_server "$proj"
            else
                echo "Error: No project specified"
            fi
            ;;
        --deploy)
            proj="${1:-$(cat "$SESSION_FILE" 2>/dev/null)}"
            env="${2:-development}"
            if [ -n "$proj" ]; then
                deploy_project "$proj" "$env"
            else
                echo "Error: No project specified"
            fi
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
        --install)
            install_webdev_ai
            ;;
        *)
            run_webdev_task "$COMMAND $@"
            ;;
    esac
}

# --- Execute Main Function ---
main "$@"