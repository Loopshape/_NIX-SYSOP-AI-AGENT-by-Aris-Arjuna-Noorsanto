#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { spawn // orchestrator.mjs
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3Pkg from 'sqlite3';

const { verbose } = sqlite3Pkg;
const sqlite3 = verbose();

// Environment variables
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR || path.join(AI_HOME, 'projects');
const AI_DATA_DB_PATH = process.env.AI_DATA_DB;
const BLOBS_DB_PATH = process.env.BLOBS_DB;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';

// Mandatory model pool
const MODEL_POOL = ['core', 'loop', '2244'];

// Databases
const aiDataDb = new sqlite3.Database(AI_DATA_DB_PATH);
const blobsDb = new sqlite3.Database(BLOBS_DB_PATH);

/**
 * Tracks proof state and convergence across consensus loops
 */
class ProofTracker {
    constructor(initialPrompt) {
        this.cycleIndex = initialPrompt.length;
        this.netWorthIndex = (this.cycleIndex % 128) << 2;
        this.entropyRatio = (this.cycleIndex ^ Date.now()) / 1000;
    }

    crosslineEntropy(data) {
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(hash.substring(0, 8), 16);
    }

    proofCycle(converged) {
        this.cycleIndex += converged ? 1 : 0;
        this.netWorthIndex -= converged ? 0 : 1;
    }

    getState() {
        return {
            cycleIndex: this.cycleIndex,
            netWorthIndex: this.netWorthIndex,
            entropyRatio: this.entropyRatio
        };
    }
}

/**
 * Core orchestrator class
 */
export class AIOrchestrator {
    constructor(prompt, options = {}) {
        this.prompt = prompt;
        this.options = options;
        this.taskId = crypto.createHash('sha256').update(Date.now().toString()).digest('hex');
        this.proofTracker = new ProofTracker(prompt);
    }

    async runOllama(model, currentPrompt) {
        return new Promise((resolve, reject) => {
            console.log(`\n[INFO] Model '${model}' thinking...`);
            const cmd = `${OLLAMA_BIN} run ${model} "${currentPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(cmd);
            let output = '';

            child.stdout.on('data', data => {
                process.stdout.write(data);
                output += data;
            });
            child.stderr.on('data', data => process.stderr.write(data));

            child.on('error', err => reject(`OLLAMA EXECUTION ERROR: ${err.message}`));
            child.on('close', code => {
                if (code !== 0) return reject(`Model ${model} exited with code ${code}`);
                resolve(output.trim());
            });
        });
    }

    async recursiveConsensus(iterations = 3) {
        let systemPrompt = `SYSTEM PROMPT: You are a world-class software engineer. Respond only with requested artifacts.\n`;
        let currentPrompt = systemPrompt + this.prompt;
        let lastFused = '';
        let converged = false;

        for (let i = 0; i < iterations && !converged; i++) {
            const results = await Promise.all(
                MODEL_POOL.map(model => this.runOllama(model, currentPrompt).catch(e => e))
            );
            const valid = results.filter(r => typeof r === 'string' && !r.startsWith('OLLAMA EXECUTION ERROR'));
            if (!valid.length) throw new Error('All models failed');

            this.proofTracker.crosslineEntropy(valid.join(''));
            const fused = valid.join('\n---\n').trim();

            converged = fused === lastFused;
            this.proofTracker.proofCycle(converged);
            lastFused = fused;

            currentPrompt = systemPrompt + this.prompt + `\n\n[PREVIOUS ITERATION]\n${fused}`;
        }

        return lastFused;
    }

    getFileExtension(lang) {
        return { python: 'py', javascript: 'js', bash: 'sh', html: 'html', css: 'css', sql: 'sql' }[lang] || 'txt';
    }

    saveMemory(prompt, response) {
        aiDataDb.run(
            `INSERT INTO memories (task_id,prompt,response,proof_state) VALUES (?,?,?,?)`,
            [this.taskId, prompt, response, JSON.stringify(this.proofTracker.getState())]
        );
    }

    saveBlob(project, file, content) {
        blobsDb.run(
            `INSERT INTO blobs (project_name,file_path,content) VALUES (?,?,?)`,
            [project, path.basename(file), content]
        );
    }

    parseCodeBlocks(content) {
        const regex = /```(\w+)\s*([\s\S]*?)```/g;
        const blocks = [];
        let m;
        while ((m = regex.exec(content))) blocks.push({ language: m[1], code: m[2] });
        return blocks;
    }

    async handleCodeGeneration(content) {
        const blocks = this.parseCodeBlocks(content);
        if (!blocks.length) return;

        const project = this.options.project || `task_${this.taskId.slice(0, 8)}`;
        const projectPath = path.join(PROJECTS_DIR, project);
        fs.mkdirSync(projectPath, { recursive: true });

        for (const [i, block] of blocks.entries()) {
            const ext = this.getFileExtension(block.language);
            const filePath = path.join(projectPath, `${block.language}_${i}.${ext}`);
            fs.writeFileSync(filePath, block.code);
            this.saveBlob(project, filePath, block.code);
            console.log(`[SUCCESS] Generated ${filePath}`);
        }
    }

    async execute() {
        console.log(`[ORCHESTRATION START] Task ${this.taskId}`);
        const output = await this.recursiveConsensus();
        console.log('\n--- FINAL CONSENSUS OUTPUT ---\n');
        console.log(output);
        this.saveMemory(this.prompt, output);
        await this.handleCodeGeneration(output);
        console.log(`[ORCHESTRATION END] Task ${this.taskId}`);
    }
} from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const HOME = process.env.HOME || process.cwd();
const PLUGIN_DIR = path.join(HOME, '.sysop-ai', 'plugins');
const LOG_DIR = path.join(HOME, '.sysop-ai', 'ollama_logs');
const REGISTRY_FILE = path.join(HOME, '.sysop-ai', 'pattern_registry.json');
const SUGGESTION_FILE = path.join(HOME, '.sysop-ai', 'pattern_suggestions.json');
const HISTORY_FILE = path.join(HOME, '.sysop-ai', 'prompt_history.json');

// ----------------- Ensure directories -----------------
[PLUGIN_DIR, LOG_DIR].forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }); });
if (!fs.existsSync(REGISTRY_FILE)) fs.writeFileSync(REGISTRY_FILE, '[]');
if (!fs.existsSync(SUGGESTION_FILE)) fs.writeFileSync(SUGGESTION_FILE, '[]');
if (!fs.existsSync(HISTORY_FILE)) fs.writeFileSync(HISTORY_FILE, '[]');

// ----------------- Runtime regex registry -----------------
let runtimePatterns = [];

function loadRegistry() {
  const data = JSON.parse(fs.readFileSync(REGISTRY_FILE, 'utf-8'));
  runtimePatterns = data.map(p => ({
    regex: new RegExp(p.regex),
    handler: eval('(' + p.handlerCode + ')')
  }));
}

function saveRegistry() {
  const data = runtimePatterns.map(p => ({ regex: p.regex.source, handlerCode: p.handler.toString() }));
  fs.writeFileSync(REGISTRY_FILE, JSON.stringify(data, null, 2));
}

function registerPattern(regex, handler) {
  runtimePatterns.push({ regex, handler });
  saveRegistry();
}

// ----------------- Plugin loader -----------------
async function loadPlugins() {
  const plugins = [];
  if (fs.existsSync(PLUGIN_DIR)) {
    const files = fs.readdirSync(PLUGIN_DIR).filter(f => f.endsWith('.js'));
    for (const file of files) {
      try {
        const module = await import(path.join(PLUGIN_DIR, file));
        const plugin = module.default || module;
        if (typeof plugin === 'function') plugins.push(plugin);
      } catch (err) {
        console.error('Plugin load error:', err);
      }
    }
  }
  return plugins;
}

// ----------------- Prompt history -----------------
function logPromptHistory(prompt, response) {
  const history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf-8'));
  history.push({ prompt, response, timestamp: Date.now() });
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
}

// ----------------- Natural pattern suggestion -----------------
function generateNaturalRegex(prompts) {
  if (!prompts.length) return null;
  const tokenized = prompts.map(p => p.prompt.split(/\s+/));
  const maxLen = Math.max(...tokenized.map(t => t.length));
  const patternTokens = [];
  for (let i = 0; i < maxLen; i++) {
    const column = tokenized.map(t => t[i] || '');
    const unique = [...new Set(column)];
    patternTokens.push(unique.length === 1 ? unique[0] : '\\S+');
  }
  return new RegExp(patternTokens.join('\\s+'), 'i');
}

function naturalPatternSuggestion(prompt, response) {
  logPromptHistory(prompt, response);
  const history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf-8'));
  const recent = history.slice(-20);
  const similar = recent.filter(p => prompt.split(/\s+/)[0].toLowerCase() === p.prompt.split(/\s+/)[0].toLowerCase());
  if (similar.length > 1) {
    const regex = generateNaturalRegex(similar);
    const suggestions = JSON.parse(fs.readFileSync(SUGGESTION_FILE, 'utf-8'));
    if (!suggestions.some(s => s.regex === regex.source)) {
      suggestions.push({ regex: regex.source, examples: similar });
      fs.writeFileSync(SUGGESTION_FILE, JSON.stringify(suggestions, null, 2));
      console.log(`💡 Natural pattern suggested: ${regex}`);
    }
  }
}

// ----------------- Ollama streaming fallback -----------------
function ollamaQueryStream(prompt) {
  return new Promise((resolve, reject) => {
    try {
      const child = spawn('ollama', ['query', prompt], { stdio: ['pipe', 'pipe', 'pipe'] });

      let response = '';
      child.stdout.on('data', (chunk) => {
        const text = chunk.toString();
        process.stdout.write(text); // stream to console live
        response += text;
      });

      child.stderr.on('data', (errChunk) => {
        process.stderr.write(errChunk.toString());
      });

      child.on('close', (code) => {
        const logFile = path.join(LOG_DIR, `ollama_${Date.now()}.json`);
        fs.writeFileSync(logFile, JSON.stringify({ prompt, response }, null, 2));
        naturalPatternSuggestion(prompt, response);
        resolve({ message: response.trim() || 'No response from Ollama' });
      });
    } catch (err) {
      reject({ message: 'Ollama query failed: ' + err.message });
    }
  });
}

// ----------------- Core orchestrator -----------------
async function runPrompt(prompt) {
  // 1️⃣ Runtime patterns
  for (const { regex, handler } of runtimePatterns) {
    const match = prompt.match(regex);
    if (match) return await handler({ prompt, match });
  }

  // 2️⃣ Plugins
  const plugins = await loadPlugins();
  for (const plugin of plugins) {
    try { return await plugin({ prompt }); } catch (err) { console.error('Plugin error:', err); }
  }

  // 3️⃣ Ollama fallback streaming
  return await ollamaQueryStream(prompt);
}

// ----------------- CLI -----------------
const args = process.argv.slice(2);
if (!args.length || args.includes('--help')) {
  console.log(`
Usage: ai "task prompt" [--project=name] [--setup] [--add-pattern]

Options:
  --setup          Initialize environment and example plugin
  --add-pattern    Add persistent regex dynamically
  --help           Show this manual
`);
  process.exit(0);
}

if (args.includes('--setup')) {
  const examplePlugin = path.join(PLUGIN_DIR, 'plugin-example.js');
  if (!fs.existsSync(examplePlugin)) {
    fs.writeFileSync(
      examplePlugin,
      "export default async ({prompt}) => ({message:'Example plugin ran: '+prompt});",
      'utf-8'
    );
  }
  if (!fs.existsSync(REGISTRY_FILE)) fs.writeFileSync(REGISTRY_FILE, '[]', 'utf-8');
  console.log('✅ Setup complete!');
  process.exit(0);
}

if (args[0] === '--add-pattern') {
  const [,, regexString, handlerString] = args;
  if (!regexString || !handlerString) {
    console.error('Usage: ai --add-pattern "/regex/i" "async ({prompt}) => { ... }"');
    process.exit(1);
  }
  const regex = new RegExp(regexString.replace(/^\/|\/[gimsuy]*$/g, ''));
  const handler = eval('(' + handlerString + ')');
  registerPattern(regex, handler);
  console.log('✅ Pattern added persistently!');
  process.exit(0);
}

// ----------------- Run prompt -----------------
(async () => {
  loadRegistry();
  const prompt = args.join(' ');
  const result = await runPrompt(prompt);
  console.log(result);
})();