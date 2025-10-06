#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
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