#!/usr/bin/env node
// nemodian.mjs -- full tactical runtime orchestrator (ESM, single-file)

import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';
import vm from 'vm';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const HOME = process.env.AI_HOME || process.env.HOME || process.cwd();
const AI_DIR = path.join(HOME, '.sysop-ai');
const PLUGIN_DIR = path.join(AI_DIR, 'plugins');
const BUILD_DIR = path.join(AI_DIR, 'ai_build');
const REGISTRY_FILE = path.join(AI_DIR, 'runtime_registry.json');
const HISTORY_FILE = path.join(AI_DIR, 'prompt_history.json');
const OLLAMA_LOG_DIR = path.join(AI_DIR, 'ollama_logs');

await fs.mkdir(AI_DIR, { recursive: true });
await fs.mkdir(PLUGIN_DIR, { recursive: true });
await fs.mkdir(BUILD_DIR, { recursive: true });
await fs.mkdir(OLLAMA_LOG_DIR, { recursive: true });
if (!fsSync.existsSync(REGISTRY_FILE)) await fs.writeFile(REGISTRY_FILE, '[]', 'utf-8');
if (!fsSync.existsSync(HISTORY_FILE)) await fs.writeFile(HISTORY_FILE, '[]', 'utf-8');

// ---------- runtime state ----------
/**
 * runtimeScripts: [
 *   { id, patternSource, pattern (RegExp), handlerCode (string), created, description }
 * ]
 */
let runtimeScripts = [];

// ---------- helpers ----------
const nowIso = () => (new Date()).toISOString().replace(/[:.]/g, '-');

async function loadRegistry() {
  try {
    const txt = await fs.readFile(REGISTRY_FILE, 'utf-8');
    const arr = JSON.parse(txt || '[]');
    runtimeScripts = arr.map(item => ({
      id: item.id,
      patternSource: item.patternSource,
      pattern: new RegExp(item.patternSource),
      handlerCode: item.handlerCode,
      created: item.created,
      description: item.description || ''
    }));
    console.debug(`[nemodian] loaded ${runtimeScripts.length} runtime scripts`);
  } catch (e) {
    console.error('[nemodian] loadRegistry error', e);
    runtimeScripts = [];
  }
}

async function saveRegistry() {
  const toSave = runtimeScripts.map(r => ({
    id: r.id,
    patternSource: r.patternSource,
    handlerCode: r.handlerCode,
    created: r.created,
    description: r.description || ''
  }));
  await fs.writeFile(REGISTRY_FILE, JSON.stringify(toSave, null, 2), 'utf-8');
}

// minimal safe API exposed to tactics
function makeSandboxAPI(prompt) {
  return {
    console: {
      log: (...args) => console.log('[tactic]', ...args),
      warn: (...args) => console.warn('[tactic]', ...args),
      error: (...args) => console.error('[tactic]', ...args)
    },
    env: {
      HOME,
      AI_DIR,
      BUILD_DIR,
      now: () => new Date().toISOString()
    },
    // minimal shell exec helper (synchronous wrapper) — you can modify permissively
    sh: (cmd, args = []) => {
      try {
        const r = spawnSync(cmd, Array.isArray(args) ? args : [args], { encoding: 'utf-8' });
        return { ok: !r.error && r.status === 0, stdout: r.stdout||'', stderr: r.stderr||'', status: r.status };
      } catch (e) {
        return { ok: false, error: e.message };
      }
    },
    // small file helpers (async not provided inside VM — tactics can call sync wrappers)
    fs: {
      read: (p) => fsSync.existsSync(p) ? fsSync.readFileSync(p,'utf-8') : null,
      write: (p, c) => fsSync.writeFileSync(p, c, 'utf-8'),
      exists: (p) => fsSync.existsSync(p)
    },
    prompt // original prompt string
  };
}

// compile a handler code string into a callable function in a VM.
// handlerCode must be an async function string or function expression that returns result object.
function compileHandler(handlerCode) {
  // We'll create a function that receives (api) and returns the handler function's return value.
  // Handler code MUST export an async function named "handler" or be a function expression that returns object.
  // To allow flexibility, support:
  //  - "async ({prompt, api}) => { ... }"
  //  - "export default async ({prompt, api}) => { ... }"
  //  - "async function handler({prompt, api}) { ... }"
  // We'll wrap safely.
  const wrapper = `
    (function() {
      const exports = {};
      const module = { exports };
      const __tactic = (function(){
        return (${handlerCode});
      })();
      // if handlerCode is a function, __tactic is a function. If it's an object, use module.exports
      if (typeof __tactic === 'function') {
        return { handler: __tactic };
      } else if (module && module.exports && typeof module.exports === 'function') {
        return { handler: module.exports };
      } else if (__tactic && typeof __tactic.handler === 'function') {
        return { handler: __tactic.handler };
      }
      throw new Error('Invalid tactic handler code');
    })()
  `;
  const script = new vm.Script(wrapper, { timeout: 2000 });
  const context = vm.createContext({}); // empty context, we'll pass API later
  const compiled = script.runInContext(context, { timeout: 2000 });
  if (!compiled || typeof compiled.handler !== 'function') throw new Error('Failed to compile tactic handler');
  return compiled.handler;
}

// execute handler in a sandboxed vm using a safe API object
async function executeHandler(handlerCode, prompt) {
  // compile to a real function
  let handlerFn;
  try {
    handlerFn = compileHandler(handlerCode);
  } catch (e) {
    console.error('[nemodian] compileHandler error:', e.message);
    return { error: 'compile error', detail: e.message };
  }

  // run handler inside vm but allow it to call provided safe API.
  // We'll use vm.runInNewContext to call a wrapper that invokes the handler.
  const sandbox = {
    console: { log: (...a)=>console.log('[tactic]',...a), warn: (...a)=>console.warn('[tactic]',...a), error: (...a)=>console.error('[tactic]',...a) },
  };
  const context = vm.createContext(sandbox);

  // We cannot pass functions compiled outside directly into another vm easily.
  // Simpler: invoke handlerFn in host (synchronously/async) with an API object (safe).
  // That keeps handler logic in host memory but the handler code was created by compileHandler (safe-ish).
  // Provide API:
  const api = makeSandboxAPI(prompt);
  try {
    // handlerFn may be async
    const result = await handlerFn({ prompt, api });
    return result;
  } catch (e) {
    return { error: 'runtime error', detail: e.message, stack: e.stack };
  }
}

// ---------- strategic script generation (tactical writer) ----------
// This is the core: generate a handlerCode string from prompt & response
function makeTacticFrom(prompt, response) {
  // Very simple strategy for example:
  // - find the first word (command token), generate a pattern ^token\b
  // - create a handler that returns a canned response referencing prompt
  // For a full tactical AI you'd call Ollama here to craft a script — we use an internal template.
  const token = (prompt.split(/\s+/)[0] || 'any').replace(/[^\w]/g,'');
  const patternSource = `^${token}\\b`;
  const id = `${token}-${Date.now()}`;
  const description = `Auto-generated tactic for token "${token}"`;

  // Handler template: an async function expression that accepts {prompt, api}
  const handlerCode = `
    async ({ prompt, api }) => {
      // Tactical script generated by Nemodian
      // Example actions: log, write a build file, run shell commands (via api.sh), return structured result.
      api.console.log('Nemodian tactic triggered for prompt:', prompt);
      // Example: if prompt contains "build", create a local build index.html
      if (/\\bbuild\\b/i.test(prompt)) {
        const outDir = api.env.AI_DIR ? api.env.AI_DIR + '/ai_build' : '${BUILD_DIR}';
        try {
          api.fs.write(outDir + '/index.html', '<!doctype><meta charset="utf-8"><title>Nemodian Build</title><body>Nemodian build for: ' + prompt + '</body>');
        } catch(e) { /* ignore */ }
      }
      // Example shell call (safe wrapper)
      const ls = api.sh('ls', ['-1', api.env.AI_DIR || '.']);
      return { id: '${id}', description: ${JSON.stringify(description)}, prompt, ls, note: 'Auto tactic response', originalResponse: ${JSON.stringify(response)} };
    }
  `;

  return { id, patternSource, handlerCode, description };
}

// ---------- Ollama query & logging ----------
function ollamaQuery(prompt) {
  try {
    const r = spawnSync('ollama', ['query', prompt], { encoding: 'utf-8' , timeout: 30_000});
    const response = (r.stdout || '').trim() || (r.stderr || '').trim() || 'No response from Ollama';
    const logFile = path.join(OLLAMA_LOG_DIR, `ollama_${Date.now()}.json`);
    fsSync.writeFileSync(logFile, JSON.stringify({ prompt, response, timestamp: Date.now() }, null, 2), 'utf-8');
    return { response };
  } catch (e) {
    return { response: 'Ollama error: ' + (e.message || e) };
  }
}

// ---------- plugins loader (ESM dynamic import) ----------
async function loadPlugins() {
  const list = [];
  if (!fsSync.existsSync(PLUGIN_DIR)) return list;
  const files = fsSync.readdirSync(PLUGIN_DIR).filter(f => f.endsWith('.mjs') || f.endsWith('.js'));
  for (const f of files) {
    try {
      // import with file:// and cache buster to allow reload
      const mod = await import('file://' + path.join(PLUGIN_DIR, f) + `?t=${Date.now()}`);
      const plugin = mod.default ?? mod;
      if (typeof plugin === 'function') list.push(plugin);
    } catch (e) {
      console.warn('[nemodian] plugin load failed', f, e.message);
    }
  }
  return list;
}

// ---------- runPrompt: main dispatch ----------
async function runPrompt(prompt) {
  // immediate pattern match
  for (const script of runtimeScripts) {
    try {
      if (script.pattern.test(prompt)) {
        // run its handler
        return await executeHandler(script.handlerCode, prompt);
      }
    } catch (e) {
      console.warn('[nemodian] pattern exec error', e.message);
      // continue
    }
  }

  // plugins
  const plugins = await loadPlugins();
  for (const p of plugins) {
    try {
      const res = await p({ prompt, AI_DIR, BUILD_DIR });
      if (res !== undefined) return res;
    } catch (e) {
      console.warn('[nemodian] plugin error', e.message);
    }
  }

  // fallback: Ollama & immediate tactic generation
  const { response } = ollamaQuery(prompt);

  // persist history
  const hist = JSON.parse(await fs.readFile(HISTORY_FILE, 'utf-8'));
  hist.push({ prompt, response, timestamp: Date.now() });
  await fs.writeFile(HISTORY_FILE, JSON.stringify(hist.slice(-500), null, 2), 'utf-8');

  // generate a tactic immediately from this prompt/response
  const tactic = makeTacticFrom(prompt, response);
  // register in memory and persist
  runtimeScripts.push({
    id: tactic.id,
    patternSource: tactic.patternSource,
    pattern: new RegExp(tactic.patternSource),
    handlerCode: tactic.handlerCode,
    created: Date.now(),
    description: tactic.description
  });
  await saveRegistry();

  // execute the newly created tactic immediately (instant learning)
  try {
    const execRes = await executeHandler(tactic.handlerCode, prompt);
    return { from: 'ollama', response, autoTacticResult: execRes };
  } catch (e) {
    return { from: 'ollama', response, error: String(e) };
  }
}

// ---------- CLI ----------
async function main() {
  const argv = process.argv.slice(2);
  if (argv.length === 0 || argv.includes('--help')) {
    console.log(`
Nemodian tactical orchestrator
Usage:
  node nemodian.mjs --setup
  node nemodian.mjs "your prompt here"

Flags:
  --setup           create plugin folder, registry files
  --add-pattern REGEX HANDLER_CODE   add a persistent tactic manually
`);
    process.exit(0);
  }

  if (argv.includes('--setup')) {
    // create example plugin and ensure registry exists
    const example = path.join(PLUGIN_DIR, 'example.mjs');
    if (!fsSync.existsSync(example)) {
      await fs.writeFile(example, `export default async ({prompt}) => { if (/^ping/i.test(prompt)) return {pong: true, prompt}; };`, 'utf-8');
      console.log('[nemodian] example plugin created:', example);
    }
    await loadRegistry();
    console.log('✅ setup complete');
    process.exit(0);
  }

  if (argv[0] === '--add-pattern') {
    const [, regexString, ...rest] = argv;
    const handlerString = rest.join(' ');
    if (!regexString || !handlerString) {
      console.error('Usage: --add-pattern "/regex/i" "async ({prompt, api}) => { ... }"');
      process.exit(1);
    }
    const patternSource = regexString.replace(/^\/|\/[gimsuy]*$/g, '');
    const id = `manual-${Date.now()}`;
    runtimeScripts.push({
      id,
      patternSource,
      pattern: new RegExp(patternSource),
      handlerCode: handlerString,
      created: Date.now(),
      description: 'manual pattern'
    });
    await saveRegistry();
    console.log('✅ pattern added:', patternSource);
    process.exit(0);
  }

  await loadRegistry();
  const prompt = argv.join(' ');
  const out = await runPrompt(prompt);
  console.log(JSON.stringify(out, null, 2));
}

await main();