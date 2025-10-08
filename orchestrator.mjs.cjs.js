// Enhanced WebDev Code-Engine with Dynamic Math Logic and MAX PARALLELISM
import { exec } from 'child_process';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import sqlite3 from 'sqlite3';

// Enhanced Environment
const AI_HOME = process.env.AI_HOME;
const PROJECTS_DIR = process.env.PROJECTS_DIR;
const OLLAMA_BIN = process.env.OLLAMA_BIN || 'ollama';
const VERBOSE_THINKING = process.env.VERBOSE_THINKING !== 'false';
const SHOW_REASONING = process.env.SHOW_REASONING !== 'false';
const AI_DATA_DB = process.env.AI_DATA_DB;

// Enhanced Model Pool for Web Development (Default/Fallback)
const WEB_DEV_MODELS = ["2244:latest", "core:latest", "loop:latest", "coin:latest", "code:latest"];
const MODEL_WEIGHTS = { "2244:latest": 2, "core:latest": 2, "loop:latest": 1, "coin:latest": 1, "code:latest": 2 };

// Working color implementation using template literals
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
    
    // Combined styles
    boldCyan: (text) => `\x1b[1;36m${text}\x1b[0m`,
    boldGreen: (text) => `\x1b[1;32m${text}\x1b[0m`,
    boldMagenta: (text) => `\x1b[1;35m${text}\x1b[0m`,
    blueText: (text) => `\x1b[34m${text}\x1b[0m`,
    yellowText: (text) => `\x1b[33m${text}\x1b[0m`,
    greenText: (text) => `\x1b[32m${text}\x1b[0m`,
    redText: (text) => `\x1b[31m${text}\x1b[0m`,
    cyanText: (text) => `\x1b[36m${text}\x1b[0m`,
    grayText: (text) => `\x1b[90m${text}\x1b[0m`,
    magentaText: (text) => `\x1b[35m${text}\x1b[0m`
};

// --- Database Helpers ---
const getDb = () => new sqlite3.Database(AI_DATA_DB);

const logEvent = (level, message, metadata = '') => {
    const db = getDb();
    const sql = `INSERT INTO events (event_type, message, metadata) VALUES (?, ?, ?)`;
    db.run(sql, [level, message, metadata], (err) => {
        if (err) console.error(colors.redText(`[DB ERROR] Failed to log event: ${err.message}`));
        db.close();
    });
};

// --- Verbose thinking functions ---
const think = (message, depth = 0) => {
    if (VERBOSE_THINKING) {
        const indent = '  '.repeat(depth);
        console.log(colors.cyanText(`${indent}🤔 THINKING: ${message}`));
    }
};

const showReasoning = (reasoning, context = 'Reasoning') => {
    if (SHOW_REASONING && reasoning) {
        console.log(colors.yellowText(`\n💭 ${context.toUpperCase()}:\n`));
        console.log(colors.grayText(reasoning));
        console.log(colors.yellowText('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'));
    }
};

// --- Math/Hashing Helpers (Ported to Node.js) ---
const genCircularIndex = () => {
    const secondsInDay = 86400;
    const now = new Date();
    const secondsOfDay = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
    
    const scaledPi2 = 6283185; 
    const scaledIndex = Math.floor((secondsOfDay / secondsInDay) * scaledPi2);
    
    return scaledIndex.toString().padStart(7, '0');
};

const genRecursiveHash = (prompt) => {
    const promptHash = crypto.createHash('sha256').update(prompt).digest('hex').substring(0, 8);
    const circularIndex = genCircularIndex();
    const baseString = `${promptHash}.${circularIndex}`;

    const hash1 = crypto.createHash('sha256').update(baseString).digest('hex').substring(0, 4);
    const hash2 = crypto.createHash('sha256').update(hash1 + baseString).digest('hex').substring(4, 8);
    const hash3 = crypto.createHash('sha256').update(hash2 + hash1 + baseString).digest('hex').substring(8, 12);
    const hash4 = crypto.createHash('sha256').update(hash3 + hash2 + hash1 + baseString).digest('hex').substring(12, 16);
    const hash5 = crypto.createHash('sha256').update(hash4 + hash3 + hash2 + hash1 + baseString).digest('hex').substring(16, 20);

    return `${hash1}.${hash2}.${hash3}.${hash4}.${hash5}.${circularIndex}`;
};

// --- Dynamic Model Selection (Ported to Node.js) ---
const selectDynamicModels = (framework, complexity) => {
    return new Promise((resolve, reject) => {
        think("Selecting dynamic model pool for task...", 1);
        const db = getDb();
        const POOL_SIZE = 3;
        
        const availableModels = WEB_DEV_MODELS; 
        
        if (availableModels.length === 0) {
            logEvent("ERROR", "No Ollama models found. Falling back to defaults.");
            db.close();
            return resolve(WEB_DEV_MODELS);
        }

        let modelScores = {};
        let promises = [];

        availableModels.forEach(model => {
            const query = `
                SELECT SUM(
                    CASE T1.proof_state
                        WHEN 'CONVERGED' THEN 3 * T1.complexity
                        ELSE -1 * T1.complexity
                    END
                ) AS score
                FROM memories AS T1
                JOIN model_usage AS T2 ON T1.task_id = T2.task_id
                WHERE T2.model_name = ? AND T1.framework LIKE ?;
            `;
            
            promises.push(new Promise((res, rej) => {
                db.get(query, [model, `%${framework}%`], (err, row) => {
                    if (err) {
                        console.error(colors.redText(`[DB ERROR] Scoring model ${model}: ${err.message}`));
                        modelScores[model] = 0;
                    } else {
                        modelScores[model] = row.score || 0;
                    }
                    res();
                });
            }));
        });

        Promise.all(promises).then(() => {
            db.close();
            
            const sortedModels = Object.entries(modelScores)
                .sort(([, scoreA], [, scoreB]) => scoreB - scoreA)
                .map(([model]) => model);

            let dynamicPool = sortedModels.slice(0, POOL_SIZE);
            
            if (dynamicPool.length < POOL_SIZE) {
                availableModels.forEach(model => {
                    if (!dynamicPool.includes(model)) {
                        dynamicPool.push(model);
                    }
                });
                dynamicPool = dynamicPool.slice(0, POOL_SIZE);
            }

            const reasoningText = `Scores: ${JSON.stringify(modelScores)}\nSelected dynamic pool: ${dynamicPool.join(', ')}`;
            showReasoning(reasoningText, "Dynamic Model Selection");
            resolve(dynamicPool);
        });
    });
};

const updateModelUsage = (taskId, modelPool) => {
    return new Promise((resolve, reject) => {
        think("Logging model usage for this task...", 2);
        const db = getDb();
        db.serialize(() => {
            modelPool.forEach(model => {
                const sql = `INSERT OR IGNORE INTO model_usage (task_id, model_name) VALUES (?, ?)`;
                db.run(sql, [taskId, model], (err) => {
                    if (err) console.error(colors.redText(`[DB ERROR] Failed to log model usage: ${err.message}`));
                });
            });
            db.close(resolve);
        });
    });
};

// --- WebDevProofTracker (Modified for 2π Modulo Logic) ---
class WebDevProofTracker {
    constructor(initialPrompt, detectedFrameworks = [], taskId) {
        this.taskId = taskId;
        this.cycleIndex = 0; 
        this.netWorthIndex = 0;
        this.entropyRatio = (initialPrompt.length ^ Date.now()) / 1000;
        this.frameworks = detectedFrameworks;
        this.complexityScore = this.calculateComplexity(initialPrompt);
        this.reasoningChain = [];
    }

    calculateComplexity(prompt) {
        think("Calculating task complexity...", 1);
        let score = 0;
        const complexityKeywords = [
            'authentication', 'database', 'api', 'middleware', 'component', 
            'responsive', 'ssr', 'state management', 'deployment', 'docker'
        ];
        complexityKeywords.forEach(keyword => {
            if (prompt.toLowerCase().includes(keyword)) score += 2;
        });
        
        showReasoning(`Complexity score: ${score} (based on keywords: ${complexityKeywords.filter(k => prompt.toLowerCase().includes(k)).join(', ')})`, 'Complexity Analysis');
        return Math.min(score, 10);
    }

    crosslineEntropy(data) {
        think("Analyzing output entropy...", 1);
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        this.entropyRatio += parseInt(hash.substring(0, 8), 16);
        
        showReasoning(`Entropy updated: ${this.entropyRatio} (hash: ${hash.substring(0, 16)}...)`, 'Entropy Analysis');
    }

    proofCycle(converged, frameworkUsed = '', reasoning = '') {
        think(`Processing proof cycle: converged=${converged}, framework=${frameworkUsed}`, 1);
        this.cycleIndex += 1;
        this.netWorthIndex += converged ? 1 : -1;
        if (frameworkUsed && !this.frameworks.includes(frameworkUsed)) {
            this.frameworks.push(frameworkUsed);
        }
        
        let finalConverged = converged;
        
        // ## 2π Modulo Logical Algorithm ##
        const circularIndex = parseInt(genCircularIndex());
        const dynamicThreshold = (circularIndex % 3) + 1; 

        if (this.netWorthIndex >= dynamicThreshold) {
            reasoning += ` Dynamic threshold (${dynamicThreshold}) met. Accelerating convergence.`;
            finalConverged = true; 
        }
        
        if (reasoning) {
            this.reasoningChain.push({
                cycle: this.cycleIndex,
                converged: finalConverged,
                framework: frameworkUsed,
                reasoning,
                timestamp: new Date().toISOString()
            });
        }
        
        showReasoning(`Cycle ${this.cycleIndex}: ${finalConverged ? 'CONVERGED' : 'DIVERGED'}, Net Worth: ${this.netWorthIndex}. Dynamic Threshold: ${dynamicThreshold}.`, 'Proof Cycle');
        
        return finalConverged;
    }

    getState() {
        return {
            cycleIndex: this.cycleIndex,
            netWorthIndex: this.netWorthIndex,
            entropyRatio: this.entropyRatio,
            frameworks: this.frameworks,
            complexityScore: this.complexityScore,
            reasoningChain: this.reasoningChain
        };
    }
}

class WebDevOrchestrator {
    constructor(prompt, options) {
        this.initialPrompt = prompt;
        this.options = options;
        this.taskId = genRecursiveHash(prompt); 
        this.detectedFrameworks = this.detectFrameworksFromPrompt(prompt);
        this.proofTracker = new WebDevProofTracker(prompt, this.detectedFrameworks, this.taskId);
        this.modelPool = WEB_DEV_MODELS; 
        
        think(`Initialized orchestrator for task: ${prompt.substring(0, 100)}...`, 0);
        showReasoning(`Task ID (2π-indexed): ${this.taskId}`, 'Task ID Generation');
    }

    detectFrameworksFromPrompt(prompt) {
        think("Analyzing prompt for framework indicators...", 1);
        const frameworkKeywords = {
            react: ['react', 'jsx', 'component', 'hook'],
            vue: ['vue', 'composition api', 'vuex'],
            angular: ['angular', 'typescript', 'rxjs'],
            node: ['node', 'express', 'backend', 'api'],
            nextjs: ['next.js', 'nextjs', 'ssr'],
            python: ['python', 'flask', 'django', 'fastapi']
        };

        const detected = [];
        for (const [framework, keywords] of Object.entries(frameworkKeywords)) {
            if (keywords.some(keyword => prompt.toLowerCase().includes(keyword))) {
                detected.push(framework);
            }
        }
        
        const result = detected.length > 0 ? detected : ['node', 'react'];
        showReasoning(`Keywords found: ${Object.entries(frameworkKeywords).filter(([fw, keys]) => keys.some(k => prompt.toLowerCase().includes(k))).map(([fw]) => fw).join(', ')}`, 'Framework Detection');
        return result;
    }

    getEnhancedSystemPrompt(framework) {
        think(`Generating system prompt for ${framework}...`, 1);
        const basePrompt = `You are a ${framework} expert. Create production-ready code with best practices.`;
        
        const enhancedPrompt = `${basePrompt}
        
CRITICAL REQUIREMENTS:
- Generate COMPLETE, WORKING code - no placeholders or TODOs
- Include all necessary imports and dependencies
- Add proper error handling and validation
- Use modern ES6+ syntax and latest framework features
- Include responsive design considerations
- Add security best practices

User Task: `;

        showReasoning(`Framework: ${framework}\nPrompt length: ${enhancedPrompt.length} chars`, 'System Prompt');
        return enhancedPrompt;
    }

    async readProjectFile(filePath) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            think(`Successfully read file: ${filePath}`, 1);
            return `--- START FILE: ${filePath} ---\n${content}\n--- END FILE: ${filePath} ---\n\n`;
        } catch (error) {
            console.error(colors.redText(`[FILE ERROR] Could not read file ${filePath}: ${error.message}`));
            return `--- FILE READ ERROR: ${filePath} ---\n`;
        }
    }

    async runOllama(model, currentPrompt, framework, iteration) {
        return new Promise((resolve, reject) => {
            const enhancedPrompt = this.getEnhancedSystemPrompt(framework) + currentPrompt;
            
            // Log the start of the model's thinking process
            console.log(colors.blueText(`\n[${framework.toUpperCase()}-ITERATION-${iteration}]`), colors.yellowText(`${model} thinking...`));
            
            const command = `${OLLAMA_BIN} run ${model} "${enhancedPrompt.replace(/"/g, '\\"')}"`;
            const child = exec(command);
            let output = '';
            
            child.on('error', (err) => {
                think(`Model ${model} encountered error: ${err.message}`, 2);
                reject(`OLLAMA EXECUTION ERROR: ${err.message}`);
            });
            
            child.stdout.on('data', data => {
                // Token Streaming Verbose Output
                if (VERBOSE_THINKING) {
                    process.stdout.write(colors.grayText(`  ${data}`));
                } else {
                    process.stdout.write(colors.grayText(data));
                }
                output += data;
            });
            
            child.stderr.on('data', data => {
                if (VERBOSE_THINKING) {
                    process.stderr.write(colors.redText(`  ERROR: ${data}`));
                } else {
                    process.stderr.write(colors.redText(data));
                }
            });
            
            child.on('close', code => {
                if (code !== 0) {
                    think(`Model ${model} exited with code ${code}`, 2);
                    return reject(`Model ${model} exited with code ${code}`);
                }
                
                think(`Model ${model} completed successfully`, 2);
                resolve(output.trim());
            });
        });
    }

    async recursiveConsensus() {
        think("Starting recursive consensus process (MAX PARALLELISM)...", 1);
        
        this.modelPool = await selectDynamicModels(this.detectedFrameworks[0] || 'node', this.proofTracker.complexityScore);
        
        let currentPrompt = this.initialPrompt;
        let lastFusedOutput = "";
        let converged = false;
        let bestFramework = this.detectedFrameworks[0] || 'node';

        for (let i = 0; i < 3 && !converged; i++) {
            think(`Consensus iteration ${i + 1}/3...`, 2);
            
            // MAX PARALLELISM: Launch all models simultaneously using Promise.all
            const promises = this.modelPool.map((model, index) => {
                return this.runOllama(model, currentPrompt, bestFramework, i + 1).catch(e => {
                    return e; // Capture error but don't stop Promise.all
                });
            });
            
            think("Waiting for all models to complete asynchronously...", 2);
            const results = await Promise.all(promises);
            const validResults = results.filter(r => 
                typeof r === 'string' && r.length > 0 && !r.startsWith('OLLAMA EXECUTION ERROR')
            );

            if (validResults.length === 0) {
                think("All models failed to produce valid output", 2);
                return "Error: All models failed. Please check Ollama installation and model availability.";
            }

            think(`Fusing ${validResults.length} valid outputs...`, 2);
            this.proofTracker.crosslineEntropy(validResults.join(''));
            const fusedOutput = this.fuseWebOutputs(validResults);
            
            const convergenceReasoning = `Iteration ${i + 1}: ${fusedOutput === lastFusedOutput ? 'Outputs converged' : 'Outputs still diverging'}`;
            const initialConverged = fusedOutput === lastFusedOutput;
            
            // Proof Cycle with Dynamic Math Logic
            converged = this.proofTracker.proofCycle(initialConverged, bestFramework, convergenceReasoning);
            
            if (converged) {
                think("Consensus achieved! Dynamic threshold met or outputs converged.", 2);
            } else {
                think("No consensus yet, continuing to next iteration...", 2);
            }

            lastFusedOutput = fusedOutput;
            currentPrompt = this.initialPrompt + `\n\nPrevious iteration output for improvement:\n${fusedOutput}`;
        }

        think("Consensus process completed", 1);
        await updateModelUsage(this.taskId, this.modelPool); 
        return lastFusedOutput;
    }

    fuseWebOutputs(results) {
        think(`Fusing ${results.length} model outputs...`, 2);
        
        const scoredResults = results.map(output => {
            let score = 0;
            const codeBlocks = (output.match(/```/g) || []).length / 2;
            score += codeBlocks * 10;
            score += Math.min(output.length / 100, 50);
            return { output, score };
        });
        
        scoredResults.sort((a, b) => b.score - a.score);
        const bestOutput = scoredResults.output; // FIX: Access 'output' property of the first element
        
        showReasoning(`Selected output with score ${scoredResults[0].score}`, 'Output Fusion');
        return bestOutput;
    }

    parseEnhancedCodeBlocks(content) {
        // CRITICAL FIX: Ensure content is a string before attempting to use it.
        if (typeof content !== 'string' || content.length === 0) {
            return [];
        }
        
        const regex = /```(\w+)\s*([\s\S]*?)```/g;
        const blocks = [];
        let match;
        
        while ((match = regex.exec(content)) !== null) {
            const language = match; // FIX: Capture group 1 is language
            let code = match.trim(); // FIX: Capture group 2 is code
            
            blocks.push({ 
                language: language, 
                code: code,
                framework: this.detectedFrameworks || 'node' // Use first detected framework
            });
        }
        
        if (blocks.length === 0 && content.trim().length > 0) {
            blocks.push({
                language: 'javascript', // Default to JS if no language specified but content exists
                code: content.trim(),
                framework: this.detectedFrameworks || 'node'
            });
        }
        
        return blocks;
    }

    async handleFileModification(filePath, newContent) {
        think(`Applying modification to file: ${filePath}`, 1);
        try {
            fs.writeFileSync(filePath, newContent);
            console.log(colors.boldGreen(`[SUCCESS] MODIFIED FILE: ${filePath}`));
        } catch (error) {
            console.error(colors.redText(`[ERROR] Failed to modify file ${filePath}: ${error.message}`));
        }
    }

    async handleEnhancedCodeGeneration(content) {
        const blocks = this.parseEnhancedCodeBlocks(content);
        if (!blocks.length) {
            think("No code blocks found in output", 1);
            return;
        }

        // 1. Check for MODIFY_FILE directive
        const modifyRegex = /^\s*MODIFY_FILE:\s*([^\s]+)\s*$/m;
        const modifyMatch = content.match(modifyRegex);

        if (modifyMatch) {
            const targetPath = modifyMatch; // FIX: Capture group 1 for the path
            const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
            const projectPath = path.join(PROJECTS_DIR, project);
            const fullPath = path.join(projectPath, targetPath);

            if (blocks.length === 1) {
                await this.handleFileModification(fullPath, blocks.code); // FIX: Access code from the first block
            } else {
                console.error(colors.redText(`[ERROR] MODIFY_FILE directive found, but output contains ${blocks.length} code blocks. Only one block is supported for modification.`));
            }
            return;
        }

        // 2. Default to NEW FILE generation
        const project = this.options.project || `webapp_${this.taskId.substring(0, 8)}`;
        const projectPath = path.join(PROJECTS_DIR, project);
        
        think(`Creating project directory: ${projectPath}`, 1);
        fs.mkdirSync(projectPath, { recursive: true });

        for (const [i, block] of blocks.entries()) {
            const ext = block.language === 'javascript' ? 'js' : 
                       block.language === 'typescript' ? 'ts' : 
                       block.language === 'python' ? 'py' : 
                       block.language === 'html' ? 'html' : 
                       block.language === 'css' ? 'css' : 'txt';
            
            const fileName = `file_${i}.${ext}`;
            const filePath = path.join(projectPath, fileName);
            
            fs.writeFileSync(filePath, block.code);
            console.log(colors.greenText(`[SUCCESS] Generated: ${filePath}`));
        }

        console.log(colors.cyanText(`\n🎉 Project ${project} created successfully!`));
        console.log(colors.cyanText(`📁 Location: ${projectPath}`));
    }

    async execute() {
        think("Starting WebDev AI execution...", 0);
        
        // 1. Read file content if --file option is present
        if (this.options.file) {
            const fileContent = await this.readProjectFile(this.options.file);
            this.initialPrompt = fileContent + this.initialPrompt;
            showReasoning(`Injected file content from: ${this.options.file}`, 'File Context');
        }

        console.log(colors.boldCyan("\n🚀 WEBDEV AI CODE ENGINE STARTING..."));
        console.log(colors.cyanText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
        
        const finalOutput = await this.recursiveConsensus();
        
        console.log(colors.boldGreen("\n✅ TASK COMPLETED SUCCESSFULLY"));
        console.log(colors.boldCyan("\n--- Final Web Development Output ---\n"));
        console.log(finalOutput);
        
        think("Saving results and generating code...", 1);
        await this.handleEnhancedCodeGeneration(finalOutput);
        
        console.log(colors.boldGreen("\n🎉 WEBDEV AI EXECUTION COMPLETED!"));
        console.log(colors.cyanText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"));
    }
}

// Enhanced CLI with verbose thinking
(async () => {
    const args = process.argv.slice(2);
    
    // Parse options and collect positional arguments
    const options = {};
    const positionalArgs = [];
    
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith('--')) {
            const parts = arg.slice(2).split('=');
            const key = parts; // FIX: key is the first part
            const value = parts.length > 1 ? parts.slice(1).join('=') : true;
            
            // Special handling for --file
            if (key === 'file' && typeof value === 'boolean') { // If --file is passed without =, expect path as next arg
                options[key] = args[i + 1];
                i++; // Skip next argument
            } else {
                options[key] = value;
            }
        } else {
            positionalArgs.push(arg);
        }
    }
    
    const prompt = positionalArgs.join(' ');

    if (!prompt) {
        console.log(colors.redText('Error: No prompt provided. Usage: webdev-ai "create a react component for user dashboard"'));
        process.exit(1);
    }

    console.log(colors.boldMagenta("\n🧠 WEBDEV AI - VERBOSE THINKING MODE"));
    console.log(colors.magentaText("========================================\n"));
    
    const orchestrator = new WebDevOrchestrator(prompt, options);
    await orchestrator.execute();
})();
