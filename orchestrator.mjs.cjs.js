// orchestrator.mjs
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3Pkg from 'sqlite3';
import { promisify } from 'util';
const execAsync = promisify(exec);

const { verbose } = sqlite3Pkg;
const sqlite3 = verbose();

// Env vars
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR || path.join(AI_HOME, 'projects');
const AI_DATA_DB_PATH = process.env.AI_DATA_DB;
const BLOBS_DB_PATH = process.env.BLOBS_DB;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';

// Mandatory models
const MODEL_POOL = ['core', 'loop', '2244'];

// Databases
const aiDataDb = new sqlite3.Database(AI_DATA_DB_PATH);
const blobsDb = new sqlite3.Database(BLOBS_DB_PATH);

// --- Proof Tracker ---
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

// --- Orchestrator ---
export class AIOrchestrator {
    constructor(prompt, options = {}) {
        this.prompt = prompt;
        this.options = options;
        this.taskId = crypto.createHash('sha256').update(Date.now().toString()).digest('hex');
        this.proofTracker = new ProofTracker(prompt);
        this.forwardQueue = [];
    }

    async runOllama(model, currentPrompt) {
        const cmd = `${OLLAMA_BIN} run ${model} "${currentPrompt.replace(/"/g, '\\"')}"`;
        try {
            const { stdout } = await execAsync(cmd);
            process.stdout.write(stdout);
            return stdout.trim();
        } catch (err) {
            return `OLLAMA ERROR: ${err.message}`;
        }
    }

    async recursiveConsensus(iterations = 3) {
        const systemPrompt = `SYSTEM PROMPT: You are Agent Nemodian. Respond ONLY with requested artifacts.\n`;
        let currentPrompt = systemPrompt + this.prompt;
        let lastFused = '';
        let converged = false;

        for (let i = 0; i < iterations && !converged; i++) {
            const results = await Promise.all(MODEL_POOL.map(m => this.runOllama(m, currentPrompt)));
            const valid = results.filter(r => typeof r === 'string' && !r.startsWith('OLLAMA ERROR'));
            if (!valid.length) throw new Error('All models failed');

            this.proofTracker.crosslineEntropy(valid.join(''));
            const fused = valid.join('\n---\n').trim();

            converged = fused === lastFused;
            this.proofTracker.proofCycle(converged);
            lastFused = fused;

            // Modulo token forwarding
            const tokens = fused.split(/\s+/);
            const moduloForward = tokens.filter((_, idx) => idx % 2 === 0).join(' ');
            if (moduloForward) this.forwardQueue.push(moduloForward);

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

    async highlightWithPygments(code, lang) {
        try {
            const tempFile = path.join(PROJECTS_DIR, `tmp_${Date.now()}.txt`);
            fs.writeFileSync(tempFile, code);
            const cmd = `pygmentize -f html -l ${lang} ${tempFile}`;
            const { stdout } = await execAsync(cmd);
            fs.unlinkSync(tempFile);
            return stdout;
        } catch (err) {
            console.error('[PYGMENTS ERROR]', err);
            return null;
        }
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

            // Generate highlighted HTML
            const html = await this.highlightWithPygments(block.code, block.language);
            if (html) {
                const htmlFile = filePath + '.html';
                fs.writeFileSync(htmlFile, html);
                console.log(`[HIGHLIGHTED] ${htmlFile}`);
            }
        }
    }

    async execute() {
        console.log(`[ORCHESTRATION START] Task ${this.taskId}`);
        const output = await this.recursiveConsensus();
        console.log('\n--- FINAL CONSENSUS OUTPUT ---\n', output);
        this.saveMemory(this.prompt, output);
        await this.handleCodeGeneration(output);

        if (this.forwardQueue.length) console.log('[TOKEN FORWARD QUEUE]', this.forwardQueue);
        console.log(`[ORCHESTRATION END] Task ${this.taskId}`);
    }
}

// CLI execution
if (import.meta.url === `file://${process.argv[1]}`) {
    const prompt = process.argv.slice(2).join(' ');
    if (!prompt) process.exit(1);

    const orchestrator = new AIOrchestrator(prompt);
    orchestrator.execute().finally(() => { aiDataDb.close(); blobsDb.close(); });
}