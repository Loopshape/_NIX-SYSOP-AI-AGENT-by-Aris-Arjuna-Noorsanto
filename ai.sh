#!/usr/bin/env bash
set -euo pipefail

# ███████╗██╗   ██╗███████╗ ██████╗ ██████╗ █████╗ ██╗    ██████╗ ██████╗ ██████╗ ███████╗
# ██╔════╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║    ██╔══██╗██╔══██╗██╔══██╗██╔════╝
# ███████╗ ╚████╔╝ █████╗  ██║   ██║██████╔╝███████║██║    ██║  ██║██████╔╝██████╔╝█████╗  
# ╚════██║  ╚██╔╝  ██╔══╝  ██║   ██║██╔═══╝ ██╔══██║██║    ██║  ██║██╔═══╝ ██╔═══╝ ██╔══╝  
# ███████║   ██║   ███████╗╚██████╔╝██║     ██║  ██║███████╗██████╔╝██║     ██║     ███████╗
# ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝     ╚══════╝
#
# WebDev Code-Engine with Verbose Thinking (Default)
# Version: 4.1.1 (Fixed Function Ordering)

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

# Verbose thinking configuration
export VERBOSE_THINKING="${VERBOSE_THINKING:-true}"
export THINKING_DELAY="${THINKING_DELAY:-0.5}"
export SHOW_REASONING="${SHOW_REASONING:-true}"

# --- Enhanced Status Function ---
enhanced_status() {
    echo -e "\n\x1b[1;36m🌐 WEBDEV AI CODE ENGINE STATUS\x1b[0m"
    echo -e "\x1b[90m==========================================\x1b[0m"
    echo "AI_HOME: $AI_HOME"
    echo "Projects: $(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l) created"
    echo "Active Session: $([ -f "$SESSION_FILE" ] && cat "$SESSION_FILE" || echo "None")"
    echo "Verbose Thinking: $VERBOSE_THINKING"
    echo "Show Reasoning: $SHOW_REASONING"
    
    # Check if dependencies are available
    echo -e "\n\x1b[1;34m🔧 DEPENDENCIES:\x1b[0m"
    local deps=("sqlite3" "node" "python3" "git" "$OLLAMA_BIN")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo "  ✅ $dep"
        else
            echo "  ❌ $dep"
        fi
    done
    
    # Show recent projects
    echo -e "\n\x1b[1;35m📁 RECENT PROJECTS:\x1b[0m"
    if [ -f "$WEB_CONFIG_DB" ]; then
        sqlite3 "$WEB_CONFIG_DB" "SELECT name, framework, status, datetime(ts) FROM projects ORDER BY ts DESC LIMIT 5;" 2>/dev/null | while IFS='|' read name framework status timestamp; do
            echo "  🗂️  $name ($framework) - $status"
            echo "     📅 $timestamp"
        done || echo "  No projects yet"
    else
        echo "  No projects database found"
    fi
    
    # Show system stats
    echo -e "\n\x1b[1;32m📊 SYSTEM STATS:\x1b[0m"
    if [ -f "$AI_DATA_DB" ]; then
        local total_tasks=$(sqlite3 "$AI_DATA_DB" "SELECT COUNT(*) FROM memories;" 2>/dev/null || echo "0")
        local total_events=$(sqlite3 "$AI_DATA_DB" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "0")
        echo "  Total Tasks: $total_tasks"
        echo "  Total Events: $total_events"
    fi
    
    # Show disk usage
    if [ -d "$AI_HOME" ]; then
        local disk_usage=$(du -sh "$AI_HOME" 2>/dev/null | cut -f1)
        echo "  Disk Usage: $disk_usage"
    fi
    
    echo -e "\n\x1b[1;33m💡 TIP: Use '--verbose' to toggle thinking mode, '--quiet' for silent mode\x1b[0m"
}

# --- Enhanced Logging with Verbose Support ---
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
        "THINKING") color="\x1b[36m" ;;
        *) color="\x1b[36m" ;;
    esac
    
    echo "[${color}${level}\x1b[0m] $(date): $message"
    sqlite3 "$AI_DATA_DB" "INSERT INTO events (event_type, message) VALUES ('$level', '$message');" 2>/dev/null || true
}

# --- Thinking Animation and Verbose Output ---
thinking() {
    local message="$1"
    local depth="${2:-0}"
    local indent=""
    
    for ((i=0; i<depth; i++)); do
        indent+="  "
    done
    
    if [ "$VERBOSE_THINKING" = "true" ]; then
        echo -e "${indent}🤔 \x1b[36mTHINKING\x1b[0m: $message"
        sleep "$THINKING_DELAY"
    fi
}

show_reasoning() {
    local reasoning="$1"
    local context="$2"
    
    if [ "$SHOW_REASONING" = "true" ] && [ -n "$reasoning" ]; then
        echo -e "\n\x1b[33m💭 REASONING [$context]:\x1b[0m"
        echo -e "\x1b[90m$reasoning\x1b[0m"
        echo -e "\x1b[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m\n"
    fi
}

# --- Enhanced Dependency Checks ---
check_node_modules() {
    thinking "Checking Node.js modules..." 1
    local required_modules=("sqlite3" "express" "axios" "chalk" "inquirer" "ws" "body-parser" "cors")
    
    for module in "${required_modules[@]}"; do
        if [ ! -d "$NODE_MODULES/$module" ]; then
            log_event "INFO" "Installing Node module: $module"
            npm install --prefix "$AI_HOME" $module --silent
        fi
    done
}

check_dependencies() {
    thinking "Checking system dependencies..." 1
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
    thinking "Checking web development dependencies..." 1
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
    
    thinking "Detecting frameworks in: $project_path" 1
    
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

    log_event "SUCCESS" "Web development templates installed"
}

# --- Enhanced Orchestrator with Verbose Thinking ---
setup_orchestrator() {
    log_event "INFO" "Setting up enhanced orchestrator with verbose thinking..."
    mkdir -p "$AI_HOME"
    cat > "$ORCHESTRATOR_FILE" <<'EOF_JS'
// Enhanced WebDev Code-Engine with Verbose Thinking
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
const VERBOSE_THINKING = process.env.VERBOSE_THINKING !== 'false';
const SHOW_REASONING = process.env.SHOW_REASONING !== 'false';

// Enhanced Model Pool for Web Development
const WEB_DEV_MODELS = ["2244", "loop", "core", "coin", "code"];

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

// Verbose thinking functions
const think = (message, depth = 0) => {
    if (VERBOSE_THINKING) {
        const indent = '  '.repeat(depth);
        console.log(chalk.cyan(`${indent}🤔 THINKING: ${message}`));
    }
};

const showReasoning = (reasoning, context = 'Reasoning') => {
    if (SHOW_REASONING && reasoning) {
        console.log(chalk.yellow(`\n💭 ${context.toUpperCase()}:\n`));
        console.log(chalk.gray(reasoning));
        console.log(chalk.yellow('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'));
    }
};

class WebDevProofTracker {
    constructor(initialPrompt, detectedFrameworks = []) {
        this.cycleIndex = initialPrompt.length;
        this.netWorthIndex = (this.cycleIndex % 128) << 2;
        this.entropyRatio = (this.cycleIndex ^ Date.now()) / 1000;
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
        this.cycleIndex += converged ? 1 : 0;
        this.netWorthIndex -= converged ? 0 : 1;
        if (frameworkUsed && !this.frameworks.includes(frameworkUsed)) {
            this.frameworks.push(frameworkUsed);
        }
        
        if (reasoning) {
            this.reasoningChain.push({
                cycle: this.cycleIndex,
                converged,
                framework: frameworkUsed,
                reasoning,
                timestamp: new Date().toISOString()
            });
        }
        
        showReasoning(`Cycle ${this.cycleIndex}: ${converged ? 'CONVERGED' : 'DIVERGED'}, Net Worth: ${this.netWorthIndex}`, 'Proof Cycle');
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
        this.taskId = crypto.createHash('sha256').update(Date.now().toString()).digest('hex');
        this.detectedFrameworks = this.detectFrameworksFromPrompt(prompt);
        this.proofTracker = new WebDevProofTracker(prompt, this.detectedFrameworks);
        
        think(`Initialized orchestrator for task: ${prompt.substring(0, 100)}...`, 0);
        showReasoning(`Detected frameworks: ${this.detectedFrameworks.join(', ')}`, 'Framework Detection');
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
        const basePrompt = FRAMEWORK_PROMPTS[framework] || 
            "You are a full-stack web developer expert. Create production-ready code with best practices.";
        
        const enhancedPrompt = `${basePrompt}
        
CRITICAL REQUIREMENTS:
- Generate COMPLETE, WORKING code - no placeholders or TODOs
- Include all necessary imports and dependencies
- Add proper error handling and validation
- Use modern ES6+ syntax and latest framework features
- Include responsive design considerations
- Add security best practices
- Include deployment configuration where applicable

THINKING PROCESS:
Please reason step-by-step about:
1. What the user is asking for
2. Best practices for this type of component/feature
3. Potential edge cases to handle
4. Performance considerations
5. Security implications

User Task: `;

        showReasoning(`Framework: ${framework}\nPrompt length: ${enhancedPrompt.length} chars`, 'System Prompt');
        return enhancedPrompt;
    }

    async runOllama(model, currentPrompt, framework, iteration) {
        return new Promise((resolve, reject) => {
            const enhancedPrompt = this.getEnhancedSystemPrompt(framework) + currentPrompt;
            think(`Model ${model} processing (iteration ${iteration})...`, 2);
            
            console.log(chalk.blue(`\n[${framework.toUpperCase()}-ITERATION-${iteration}]`), chalk.yellow(`${model} thinking...`));
            
            const command = `${OLLAMA_BIN} run ${model} "${enhancedPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(command);
            let output = '';
            let reasoning = '';
            
            child.on('error', (err) => {
                think(`Model ${model} encountered error: ${err.message}`, 2);
                reject(`OLLAMA EXECUTION ERROR: ${err.message}`);
            });
            
            child.stdout.on('data', data => {
                if (VERBOSE_THINKING) {
                    process.stdout.write(chalk.gray(`  ${data}`));
                } else {
                    process.stdout.write(chalk.gray(data));
                }
                output += data;
                
                // Extract reasoning from thinking patterns
                if (data.includes('think') || data.includes('reason') || data.includes('consider')) {
                    reasoning += data;
                }
            });
            
            child.stderr.on('data', data => {
                if (VERBOSE_THINKING) {
                    process.stderr.write(chalk.red(`  ERROR: ${data}`));
                } else {
                    process.stderr.write(chalk.red(data));
                }
            });
            
            child.on('close', code => {
                if (code !== 0) {
                    think(`Model ${model} exited with code ${code}`, 2);
                    return reject(`Model ${model} exited with code ${code}`);
                }
                
                think(`Model ${model} completed successfully`, 2);
                if (reasoning) {
                    showReasoning(reasoning, `Model ${model} Reasoning`);
                }
                resolve(output.trim());
            });
        });
    }

    async recursiveConsensus() {
        think("Starting recursive consensus process...", 1);
        let currentPrompt = this.initialPrompt;
        let lastFusedOutput = "";
        let converged = false;
        let bestFramework = this.detectedFrameworks[0] || 'node';

        for (let i = 0; i < 3 && !converged; i++) {
            think(`Consensus iteration ${i + 1}/3...`, 2);
            
            const promises = WEB_DEV_MODELS.map((model, index) => {
                think(`Launching model ${index + 1}/${WEB_DEV_MODELS.length}: ${model}`, 3);
                return this.runOllama(model, currentPrompt, bestFramework, i + 1).catch(e => {
                    think(`Model ${model} failed: ${e}`, 3);
                    return e;
                });
            });
            
            think("Waiting for all models to complete...", 2);
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
            if (fusedOutput === lastFusedOutput) {
                converged = true;
                this.proofTracker.proofCycle(true, bestFramework, convergenceReasoning);
                think("Consensus achieved! Outputs converged.", 2);
            } else {
                this.proofTracker.proofCycle(false, bestFramework, convergenceReasoning);
                think("No consensus yet, continuing to next iteration...", 2);
            }

            lastFusedOutput = fusedOutput;
            currentPrompt = this.initialPrompt + `\n\nPrevious iteration output for improvement:\n${fusedOutput}`;
            this.logEvent('CONSENSUS_LOOP', `Iteration ${i + 1}, Framework: ${bestFramework}, Converged: ${converged}`);
        }

        think("Consensus process completed", 1);
        return lastFusedOutput;
    }

    fuseWebOutputs(results) {
        think(`Fusing ${results.length} model outputs...`, 2);
        
        // Enhanced fusion: consider code quality, completeness, and structure
        const scoredResults = results.map(output => {
            let score = 0;
            
            // Score based on code block presence
            const codeBlocks = (output.match(/```/g) || []).length / 2;
            score += codeBlocks * 10;
            
            // Score based on length (but not too long)
            score += Math.min(output.length / 100, 50);
            
            // Score based on framework alignment
            if (output.toLowerCase().includes(this.detectedFrameworks[0])) {
                score += 20;
            }
            
            // Penalize error messages
            if (output.includes('error') || output.includes('sorry')) {
                score -= 15;
            }
            
            return { output, score };
        });
        
        // Sort by score and take the best
        scoredResults.sort((a, b) => b.score - a.score);
        const bestOutput = scoredResults[0].output;
        
        showReasoning(`Selected output with score ${scoredResults[0].score} (runner-up: ${scoredResults[1]?.score || 0})`, 'Output Fusion');
        return bestOutput;
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
            const fileName = `file_${i}.${ext}`;
            const filePath = path.join(projectPath, fileName);
            
            fs.writeFileSync(filePath, block.code);
            this.saveBlob(project, filePath, block.code);
            console.log(chalk.green(`[SUCCESS] Generated: ${filePath}`));
        }

        this.registerProject(project);
        this.gitCommit(project);
        
        console.log(chalk.cyan(`\n🎉 Project ${project} created successfully!`));
        console.log(chalk.cyan(`📁 Location: ${projectPath}`));
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
        const projectPath = path.join(PROJECTS_DIR, project);
        if (!fs.existsSync(path.join(projectPath, '.git'))) {
            const cmd = `cd ${projectPath} && git init && git add . && git commit -m "feat: Initial web app generated by WebDev AI"`;
            exec(cmd, (err) => {
                if (err) this.logEvent('GIT_ERROR', `Failed to commit ${project}`);
                else this.logEvent('GIT_SUCCESS', `Committed ${project}`);
            });
        }
    }

    async execute() {
        think("Starting WebDev AI execution...", 0);
        this.logEvent('WEB_DEV_START', `Task ${this.taskId} for frameworks: ${this.detectedFrameworks.join(',')}`);
        
        console.log(chalk.bold.cyan("\n🚀 WEBDEV AI CODE ENGINE STARTING..."));
        console.log(chalk.cyan("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
        
        const finalOutput = await this.recursiveConsensus();
        
        console.log(chalk.bold.green("\n✅ TASK COMPLETED SUCCESSFULLY"));
        console.log(chalk.bold.cyan("\n--- Final Web Development Output ---\n"));
        console.log(finalOutput);
        
        think("Saving results and generating code...", 1);
        this.saveMemory(this.initialPrompt, finalOutput);
        await this.handleEnhancedCodeGeneration(finalOutput);
        
        console.log(chalk.bold.green("\n🎉 WEBDEV AI EXECUTION COMPLETED!"));
        console.log(chalk.cyan("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
        
        this.logEvent('WEB_DEV_END', `Task ${this.taskId} completed successfully`);
    }
}

// Enhanced CLI with verbose thinking
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

    console.log(chalk.bold.magenta("\n🧠 WEBDEV AI - VERBOSE THINKING MODE"));
    console.log(chalk.magenta("========================================\n"));
    
    const orchestrator = new WebDevOrchestrator(prompt, options);
    await orchestrator.execute();
})();
EOF_JS

    log_event "SUCCESS" "Enhanced orchestrator with verbose thinking created"
}

# --- Enhanced AI Task Runner with Verbose Thinking ---
run_webdev_task() {
    local full_prompt="$*"
    local frameworks=$(detect_frameworks)

    thinking "Analyzing user request..." 0
    show_reasoning "User request: $full_prompt" "Input Analysis"

    # Enhanced prompt analysis for web development
    if [[ "$full_prompt" =~ (component|api|server|database|deploy|build|responsive) ]]; then
        thinking "Web development task detected" 1
        full_prompt="WEB DEVELOPMENT: $full_prompt - Generate complete, production-ready code with all necessary files."
    fi

    # Framework-specific enhancements
    if [[ "$full_prompt" =~ (react|vue|angular) ]]; then
        thinking "Frontend framework detected" 1
        full_prompt="$full_prompt --framework=frontend"
    elif [[ "$full_prompt" =~ (node|express|python|flask) ]]; then
        thinking "Backend framework detected" 1
        full_prompt="$full_prompt --framework=backend"
    fi

    if [ -f "$SESSION_FILE" ]; then
        local proj=$(cat "$SESSION_FILE")
        thinking "Active session detected: $proj" 1
        full_prompt="$full_prompt --project=$proj"
    fi

    log_event "TASK_START" "WebDev Prompt: $full_prompt | Frameworks: $frameworks"
    
    echo -e "\n\x1b[35m🎯 STARTING WEBDEV AI TASK\x1b[0m"
    echo -e "\x1b[90mTask: $full_prompt\x1b[0m"
    echo -e "\x1b[35m──────────────────────────────────────────────────────────────\x1b[0m\n"
    
    node "$ORCHESTRATOR_FILE" $full_prompt
    log_event "TASK_END" "Web development task completed"
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

# --- Main Enhanced Execution ---
main() {
    # Ensure AI_HOME exists
    mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$DB_DIR" "$TEMPLATES_DIR" "$SCRIPTS_DIR"
    
    # Initialize core systems
    check_dependencies
    init_databases
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
