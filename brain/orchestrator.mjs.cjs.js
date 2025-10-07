// orchestrator.mjs in your BRAIN_DIR (e.g. ~/_/orchestrator.mjs)

import { exec } from "child_process";
import fs from "fs";
import path from "path";
import crypto from "crypto";
import sqlite3 from "sqlite3";

const BRAIN_DIR = process.env.BRAIN_DIR || `${process.env.HOME}/_`;
const DB_PATH = path.join(BRAIN_DIR, "brain.db");
const BLOBS_PATH = path.join(BRAIN_DIR, "blobs.db");

const MODEL_POOL = ["core", "loop", "2244"];  // mandatory pool

// open DBs
const db = new sqlite3.Database(DB_PATH);
const blobs = new sqlite3.Database(BLOBS_PATH);

function log(msg) {
  console.log(`[LOG] ${new Date().toISOString()} — ${msg}`);
}

// function to run ollama model
function runOllama(model, prompt) {
  return new Promise((resolve, reject) => {
    const cmd = `ollama run ${model} "${prompt.replace(/"/g, '\\"')}"`;
    const proc = exec(cmd, { maxBuffer: 10 * 1024 * 1024 });
    let out = "";
    proc.stdout.on("data", d => { out += d; });
    proc.stderr.on("data", d => { console.error(d); });
    proc.on("error", err => reject(err));
    proc.on("close", code => {
      if (code !== 0) {
        reject(new Error(`Exit ${code}`));
      } else {
        resolve(out.trim());
      }
    });
  });
}

// hash / rehash function based on timestamp, pot index, etc.
function computeRehash(index, previousHash, content) {
  const ts = Date.now().toString();
  const data = `${index}|${previousHash}|${ts}|${content}`;
  return crypto.createHash("sha256").update(data).digest("hex");
}

async function consensusLoop(prompt) {
  let lastFusion = "";
  let prevHash = "";
  for (let i = 0; i < 3; i++) {
    const promises = MODEL_POOL.map(m => runOllama(m, prompt).catch(e => `ERROR:${e}`));
    const results = await Promise.all(promises);
    const ok = results.filter(r => !r.startsWith("ERROR:"));
    if (ok.length === 0) {
      throw new Error("All models failed");
    }
    const fused = ok.join("\n---\n");
    const rehash = computeRehash(i, prevHash, fused);
    log(`Iteration ${i}, hash=${rehash}`);
    prevHash = rehash;
    if (fused === lastFusion) {
      break;
    }
    lastFusion = fused;
    // you can modify prompt to feed the fused output
    prompt = prompt + "\n[PREV] " + fused;
  }
  return lastFusion;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    console.error("Usage: orchestrator.mjs <prompt>");
    process.exit(1);
  }
  const prompt = args.join(" ");
  log("Starting consensus on prompt: " + prompt);
  try {
    const out = await consensusLoop(prompt);
    console.log("\n=== FINAL ===\n" + out);
    // You may also store prompt/out in DB, or blobs
  } catch (e) {
    console.error("Error in orchestration:", e);
  }
}

main();