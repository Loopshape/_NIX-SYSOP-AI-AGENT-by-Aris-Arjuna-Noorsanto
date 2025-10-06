#!/usr/bin/env node
/**
 * Fully flexible single-file orchestrator
 * - No default patterns
 * - Dynamic plugin loading
 * - Minimal core logic
 */

import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';

const HOME = process.env.HOME || process.cwd();
const PLUGIN_DIR = path.join(HOME, '.sysop-ai', 'plugins');
const BUILD_DIR  = path.join(HOME, '.sysop-ai', 'ai_build');

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

// --------------------- Core Orchestrator ---------------------
async function runPrompt(prompt) {
  const plugins = await loadPlugins();

  // Run all plugins dynamically
  for (const plugin of plugins) {
    // If plugin has aliases, match; otherwise always run
    if (!plugin.aliases || plugin.aliases.length === 0 || plugin.aliases.some(a => prompt.toLowerCase().includes(a.toLowerCase()))) {
      try {
        return await plugin({ prompt });
      } catch (err) {
        console.error('Plugin error:', err);
      }
    }
  }

  // Fallback: return raw prompt
  return { message: `No matching plugin found for prompt: "${prompt}"` };
}

// --------------------- CLI ---------------------
const args = process.argv.slice(2);

if (args.includes('--help')) {
  console.log(`
Usage: ai "task prompt" [--project=name] [--setup]

Options:
  --setup       Initialize environment and example plugin
  --help        Show this help manual

Examples:
  ai "any prompt you like"
  ai "check env" --setup
`);
  process.exit(0);
}

if (args.includes('--setup')) {
  fs.mkdirSync(PLUGIN_DIR, { recursive: true });
  fs.mkdirSync(BUILD_DIR, { recursive: true });

  const examplePlugin = path.join(PLUGIN_DIR, 'plugin-example.mjs');
  if (!fs.existsSync(examplePlugin)) {
    fs.writeFileSync(
      examplePlugin,
      `export default async function({prompt}) { return {message:'Example dynamic plugin ran for: '+prompt}; };`,
      'utf-8'
    );
  }

  console.log('✅ Setup complete!');
  process.exit(0);
}

// --------------------- Run Prompt ---------------------
const prompt = args.join(' ');
runPrompt(prompt).then(console.log).catch(console.error);