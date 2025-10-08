#!/usr/bin/env node
/**
 * ollama_converge_build.js
 *
 * Orchestrator that forces Ollama to build a fullscreen WebGL 3D Hamburg scene
 * using a strict mandatory model pool: ['loop','2244','core','code','coin'].
 *
 * It runs a proof-of-convergence loop:
 *  - runs models in parallel each iteration,
 *  - normalizes and scores outputs,
 *  - checks for convergence / validation,
 *  - iterates with "improve this" prompt if not converged.
 *
 * Output: hamburg_3d_final.html
 *
 * Usage:
 *   node ollama_converge_build.js
 *
 * Notes:
 *  - Ollama must be installed and accessible via `ollama` command.
 *  - This script relies on heuristics to validate HTML/Three.js presence.
 */

import { exec as _exec } from "child_process";
import { promisify } from "util";
import fs from "fs";
import os from "os";
const exec = promisify(_exec);

const MODELS = ["loop", "2244", "core", "code", "coin"]; // strict mandatory order/pool
const MAX_ITER = 5;
const CONVERGENCE_SIM_THRESHOLD = 0.88; // average similarity threshold to declare convergence
const MIN_VALID_SCORE = 0.6; // heuristic to accept candidate as valid
const OUTPUT_FILE = "hamburg_3d_final.html";

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

// Normalize output for comparison
function normalizeText(s) {
  if (!s) return "";
  return s
    .replace(/\r/g, "")
    .replace(/\t+/g, " ")
    .replace(/[ ]{2,}/g, " ")
    .trim();
}

// Simple token Jaccard similarity (fast, deterministic)
function jaccardSim(a, b) {
  const sa = new Set(a.split(/\W+/).filter(Boolean));
  const sb = new Set(b.split(/\W+/).filter(Boolean));
  if (sa.size === 0 && sb.size === 0) return 1;
  const inter = [...sa].filter((x) => sb.has(x)).length;
  const uni = new Set([...sa, ...sb]).size;
  return uni === 0 ? 0 : inter / uni;
}

// Compute average pairwise similarity among outputs
function avgPairwiseSim(arr) {
  const n = arr.length;
  if (n <= 1) return 1;
  let sum = 0;
  let count = 0;
  for (let i = 0; i < n; i++) {
    for (let j = i + 1; j < n; j++) {
      sum += jaccardSim(normalizeText(arr[i]), normalizeText(arr[j]));
      count++;
    }
  }
  return count === 0 ? 0 : sum / count;
}

// Heuristic scoring for an output: rewards DOCTYPE, three.js import, canvas/responsive resize, Hamburg coords
function heuristicScore(out) {
  const s = normalizeText(out).toLowerCase();
  let score = 0;

  // DOCTYPE / HTML root
  if (s.includes("<!doctype html") || s.includes("<html")) score += 0.25;

  // Three.js imports or usage
  if (s.includes("three.module") || s.includes("three.js") || /three\b/.test(s)) score += 0.25;

  // Fullscreen canvas or renderer setSize window.innerWidth/innerHeight
  if (s.includes("window.innerwidth") || s.includes("setsize(") || s.includes("canvas") || s.includes("renderer.setsize")) score += 0.15;

  // OrbitControls / controls
  if (s.includes("orbitcontrols") || s.includes("controls.enabled")) score += 0.05;

  // Hamburg coordinates (latitude/longitude)
  // Accept common variants and exact Hamburg coordinates
  const hamburgCandidates = ["53.5511", "9.9937", "hamburg", "hamburg, germany"];
  if (hamburgCandidates.some((c) => s.includes(c))) score += 0.2;

  // Marker/marker geometry or sphere for location
  if (s.includes("marker") || s.includes("spheregeometry") || s.includes("mesh")) score += 0.05;

  // Ensure comments & clear instructions (small bonus)
  if (s.includes("<!--") || s.includes("//") || s.includes("/*")) score += 0.05;

  // cap to 1
  return Math.min(1, score);
}

// Extract most plausible HTML or code block from model output
function extractBestBlock(out) {
  if (!out) return "";
  // If the model returned fenced code blocks (```html ... ```), prefer them
  const codeFenceRegex = /```(?:html|htm|x?html)?\s*([\s\S]*?)```/gi;
  let m;
  const blocks = [];
  while ((m = codeFenceRegex.exec(out)) !== null) {
    if (m[1]) blocks.push(m[1].trim());
  }
  if (blocks.length > 0) {
    // choose longest block
    blocks.sort((a, b) => b.length - a.length);
    return blocks[0];
  }

  // If no fences, try to find full HTML (from <!DOCTYPE to </html>)
  const htmlRegex = /<!doctype html[\s\S]*<\/html>/i;
  const htmlMatch = out.match(htmlRegex);
  if (htmlMatch) return htmlMatch[0];

  // fallback: if output is mostly HTML-ish (has <html> tag), return substring around <html>... </html>
  const open = out.indexOf("<html");
  const close = out.lastIndexOf("</html>");
  if (open >= 0 && close > open) return out.substring(open, close + 7);

  // as last resort: return the entire output
  return out
