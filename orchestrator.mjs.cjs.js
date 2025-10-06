#!/usr/bin/env node
/**
 * Dynamic orchestrator with persistent regex registry + Ollama AI forwarding
 */

import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';

const HOME = process.env.HOME || process.cwd();
const PLUGIN_DIR = path.join(HOME, '.sysop-ai', 'plugins');
const BUILD_DIR  = path.join(HOME, '.sysop-ai', 'ai_build');
const REGISTRY_FILE = path.join(HOME, '.sysop-ai', 'pattern_registry.json');

// --------------------- Persistent Runtime Regex Registry ---------------------
let runtimePatterns = [];

function loadRegistry() {
  if (!fs.existsSync(REGISTRY_FILE)) return;
  const data = JSON.parse(fs.readFileSync(REGISTRY_FILE, 'utf-8'));
  runtimePatterns = data.map(p => ({ regex: new RegExp(p.regex), handlerCode: p.handlerCode }));
}

function saveRegistry() {
  const data = runtimePatterns.map(p => ({
    regex: p.regex.source,
    handlerCode: p.handlerCode
  }));
  fs.writeFileSync(REGISTRY_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

export function registerPattern(regex, handler) {
  if (!(regex instanceof RegExp)) throw new Error('Pattern must be a RegExp');
  if (typeof handler !== 'function') throw new Error('Handler must be a function');

  runtimePatterns.push({ regex, handlerCode: handler.toString() });
  saveRegistry();
}

function restoreHandlers() {
  runtimePatterns.forEach(p => {
    p.handler = eval(`(${p.handlerCode})`);
  });
}

// --------------------- Dynamic Plugin Loader ---------------------
async function loadPlugins() {
  if (!fs.existsSync(PLUGIN_DIR)) fs.mkdirSync(PLUGIN_DIR, { recursive: true });
  const files = fs.readdirSync(PLUGIN_DIR).filter(f => f.endsWith('.mjs'));
  const plugins = [];
  for (const file of files) {
    const plugin = await import(path.join(PLUGIN_DIR, file));
    if (plugin.default) plugins.push(plugin.default);
  }
  return plugins;
}

// --------------------- Ollama Forwarding ---------------------
async function ollamaQuery(prompt) {
  try {
    const result = spawnSync('ollama', ['query', prompt], { encoding: 'utf-8' });
    if (result.error) throw result.error;
    return { message: result.stdout.trim() || 'No response from Ollama' };
  } catch (err) {
    return { message: `Ollama query failed: ${err.message}` };
  }
}

// --------------------- Core Orchestrator ---------------------
async function runPrompt(prompt) {
  // 1️⃣ Runtime patterns
  for (const { regex, handler } of runtimePatterns) {
    const match = prompt.match(regex);
    if (match) return await handler({ prompt, match });
  }

  // 2️⃣ Plugins
  const plugins = await loadPlugins();
  for (const plugin of plugins) {
    if (!plugin.aliases || plugin.aliases.length === 0 || plugin.aliases.some(a => prompt.toLowerCase().includes(a.toLowerCase()))) {
      try {
        return await plugin({ prompt });
      } catch (err) {
        console.error('Plugin error:', err);
      }
    }
  }

  // 3️⃣ Fallback: Ollama AI
  return await ollamaQuery(prompt);
}

// --------------------- CLI ---------------------
const args = process.argv.slice(2);

if (args.includes('--help')) {
  console.log(`
Usage: ai "task prompt" [--project=name] [--setup]

Options:
  --setup          Initialize environment and example plugin
  --add-pattern    Add a persistent regex pattern dynamically
  --help           Show this help manual

Dynamic Regex Registry:
  registerPattern(regex, async ({prompt, match}) => {...})

Examples:
  ai "any prompt you like"
  ai --add-pattern "/check env/i" "async ({prompt}) => ({message:'Env checked: '+prompt})"
`);
  process.exit(0);
}

// --------------------- Setup ---------------------
if (args.includes('--setup')) {
  fs.mkdirSync(PLUGIN_DIR, { recursive: true });
  fs.mkdirSync(BUILD_DIR, { recursive: true });
  if (!fs.existsSync(REGISTRY_FILE)) fs.writeFileSync(REGISTRY_FILE, '[]', 'utf-8');

  const examplePlugin = path.join(PLUGIN_DIR, 'plugin-example.mjs');
  if (!fs.existsSync(examplePlugin)) {
    fs.writeFileSync(
      examplePlugin,
      `export default async function({prompt}) { return {message:'Example plugin ran: '+prompt}; };`,
      'utf-8'
    );
  }

  console.log('✅ Setup complete!');
  process.exit(0);
}

// --------------------- Add Pattern Dynamically ---------------------
if (args[0] === '--add-pattern') {
  const [,, regexString, handlerString] = args;
  if (!regexString || !handlerString) {
    console.error('Usage: ai --add-pattern "/regex/i" "async ({prompt}) => { ... }"');
    process.exit(1);
  }

  const regex = new RegExp(regexString.replace(/^\/|\/[gimsuy]*$/g, ''));
  const handler = eval(`(${handlerString})`);

  registerPattern(regex, handler);
  console.log('✅ Pattern added persistently!');
  process.exit(0);
}

// --------------------- Run Prompt ---------------------
loadRegistry();
restoreHandlers();
const prompt = args.join(' ');
runPrompt(prompt).then(console.log).catch(console.error);