#!/bin/env node

// soulPulseFull.mjs
import crypto from 'crypto';
import { exec } from 'child_process';
import bip39 from 'bip39';

// --- Config ---
const INITIAL_SKIP_MS = 3200;
const AURAL_UNIT_MS = 8000;
const MICRO_FREQ_HZ = 220;
const HASH_SIZE_BYTES = 2048; // 2kB per seed
const SEED_COUNT = 2;
const INDICES = [6, 8];
const OLLAMA_BIN = 'ollama';
const MODEL_POOL = ['core', 'loop', '2244']; // mandatory
let pulseIndex = 0;

// --- Deterministic Hash Seed Generation ---
function generateHashSeed(prevSeed = '') {
  const buf = crypto.randomBytes(HASH_SIZE_BYTES);
  return crypto.createHash('sha256')
               .update(prevSeed + buf.toString('hex'))
               .digest('hex');
}

// --- Pick token index using hash modulo ---
function pickTokenIndex(hash) {
  return parseInt(hash.slice(0, 8), 16) % 256; // 0–255
}

// --- Map index to mnemonic word for checkpointing ---
function mnemonicFromIndex(index) {
  const wordlist = bip39.wordlists.english;
  return wordlist[index % wordlist.length];
}

// --- Decide action based on index (sell/pay/buy) ---
function tradeDecision(index) {
  return index % 2 === 0 ? 'buy' : 'sell';
}

// --- Run Ollama model ---
function runOllamaModel(model, prompt) {
  return new Promise((resolve, reject) => {
    const cmd = `${OLLAMA_BIN} run ${model} "${prompt}"`;
    const child = exec(cmd);
    let output = '';
    child.stdout.on('data', data => { output += data; process.stdout.write(data); });
    child.stderr.on('data', data => process.stderr.write(data));
    child.on('close', code => code === 0 ? resolve(output.trim()) : reject(code));
  });
}

// --- Micro-pulse loop ---
async function microPulseUnit(seedHash, macroIndex) {
  const microInterval = 1000 / MICRO_FREQ_HZ;
  const totalPulses = Math.floor(AURAL_UNIT_MS / microInterval);

  for (let i = 0; i < totalPulses; i++) {
    const combinedHash = crypto.createHash('sha256').update(seedHash + i).digest('hex');
    const tokenIndex = pickTokenIndex(combinedHash);
    const word = mnemonicFromIndex(tokenIndex);
    const action = tradeDecision(tokenIndex);

    const prompt = `Macro#${macroIndex} | Micro#${i} | Token:${tokenIndex} (${word}) | Action:${action}`;

    for (const model of MODEL_POOL) {
      try { await runOllamaModel(model, prompt); }
      catch(e) { console.error(`[ERROR] Model ${model} failed:`, e); }
    }

    await new Promise(r => setTimeout(r, microInterval));
  }
}

// --- Macro loop ---
async function macroPulseLoop() {
  let lastSeed = '';
  console.log(`[INFO] Skipping initial ${INITIAL_SKIP_MS} ms`);
  await new Promise(r => setTimeout(r, INITIAL_SKIP_MS));

  setInterval(async () => {
    pulseIndex += 1;
    const seedHash = generateHashSeed(lastSeed);
    lastSeed = seedHash;

    console.log(`[INFO] Starting macro aural unit #${pulseIndex} with ${MICRO_FREQ_HZ} Hz micro pulses`);
    await microPulseUnit(seedHash, pulseIndex);
  }, AURAL_UNIT_MS);
}

// --- Start ---
macroPulseLoop();
