// orchestrator.mjs
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3Pkg from 'sqlite3';
const { verbose } = sqlite3Pkg;
const sqlite3 = verbose();

const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR;
const DB_DIR = process.env.DB_DIR;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';
const MODEL_POOL = ["phi3", "llama3", "codegemma"];
const aiDataDb = new sqlite3.Database(path.join(DB_DIR, "ai_data.db"));
const blobsDb = new sqlite3.Database(path.join(DB_DIR, "blobs.db"));

// [Full AIOrchestrator class goes here]
// For brevity, the class from your previous orchestrator.mjs is placed here

