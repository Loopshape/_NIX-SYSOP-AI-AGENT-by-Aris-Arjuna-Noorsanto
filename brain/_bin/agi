#!/usr/bin/env node

// ~/.bin/dex.js - Live AI Model Progress Monitor
// Usage: dex.js [--watch] [--models] [--system] [--verbose] [--log]

const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Configuration
const CONFIG = {
    AI_HOME: process.env.AI_HOME || path.join(process.env.HOME, '.webdev-ai'),
    OLLAMA_BIN: process.env.OLLAMA_BIN || 'ollama',
    POLL_INTERVAL: 2000, // 2 seconds
    MAX_LOG_LINES: 50,
    MODEL_UPDATE_INTERVAL: 30000 // 30 seconds
};

// Color codes for terminal output
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
    bgRed: '\x1b[41m',
    bgGreen: '\x1b[42m',
    bgYellow: '\x1b[43m'
};

// Utility functions
const colorize = (text, color) => `${color}${text}${colors.reset}`;
const bold = (text) => colorize(text, colors.bright);
const dim = (text) => colorize(text, colors.dim);
const red = (text) => colorize(text, colors.red);
const green = (text) => colorize(text, colors.green);
const yellow = (text) => colorize(text, colors.yellow);
const blue = (text) => colorize(text, colors.blue);
const magenta = (text) => colorize(text, colors.magenta);
const cyan = (text) => colorize(text, colors.cyan);
const gray = (text) => colorize(text, colors.gray);

class LiveMonitor {
    constructor(options = {}) {
        this.options = {
            watch: options.watch || false,
            models: options.models || false,
            system: options.system || false,
            verbose: options.verbose || false,
            log: options.log || false,
            ...options
        };
        
        this.stats = {
            startTime: new Date(),
            tasksCompleted: 0,
            modelsUsed: new Set(),
            errors: 0,
            totalTokens: 0
        };
        
        this.screen = {
            width: process.stdout.columns || 80,
            height: process.stdout.rows || 24
        };
        
        this.setupEventListeners();
    }
    
    setupEventListeners() {
        process.on('SIGINT', () => this.shutdown());
        process.on('SIGTERM', () => this.shutdown());
        process.stdout.on('resize', () => {
            this.screen.width = process.stdout.columns;
            this.screen.height = process.stdout.rows;
        });
    }
    
    clearScreen() {
        process.stdout.write('\x1b[2J\x1b[0f');
    }
    
    moveCursor(x, y) {
        process.stdout.write(`\x1b[${y};${x}H`);
    }
    
    printHeader() {
        const title = bold(magenta('🤖 DEX.JS - AI MODEL LIVE MONITOR'));
        const version = dim('v1.0.0');
        const timestamp = dim(new Date().toLocaleTimeString());
        
        console.log(`\n${title} ${version} | ${timestamp}`);
        console.log(dim('━'.repeat(this.screen.width - 2)));
    }
    
    async getSystemStats() {
        return new Promise((resolve) => {
            const stats = {
                cpu: 'N/A',
                memory: 'N/A',
                disk: 'N/A',
                uptime: 'N/A'
            };
            
            // CPU usage (simplified)
            const startUsage = process.cpuUsage();
            setTimeout(() => {
                const endUsage = process.cpuUsage(startUsage);
                stats.cpu = `${((endUsage.user + endUsage.system) / 1000000).toFixed(1)}%`;
                
                // Memory usage
                const used = process.memoryUsage();
                stats.memory = `${Math.round(used.heapUsed / 1024 / 1024)}MB`;
                
                // Uptime
                stats.uptime = `${Math.round(process.uptime())}s`;
                
                resolve(stats);
            }, 100);
        });
    }
    
    async getOllamaModels() {
        return new Promise((resolve) => {
            exec(`${CONFIG.OLLAMA_BIN} list`, (error, stdout) => {
                if (error) {
                    resolve([]);
                    return;
                }
                
                const models = [];
                const lines = stdout.trim().split('\n').slice(1); // Skip header
                
                for (const line of lines) {
                    const parts = line.split(/\s+/);
                    if (parts.length >= 4) {
                        models.push({
                            name: parts[0],
                            id: parts[1],
                            size: parts[2],
                            modified: parts.slice(3).join(' ')
                        });
                    }
                }
                
                resolve(models);
            });
        });
    }
    
    async getRecentTasks() {
        const dbPath = path.join(CONFIG.AI_HOME, 'db', 'ai_data.db');
        if (!fs.existsSync(dbPath)) {
            return [];
        }
        
        return new Promise((resolve) => {
            const sqlite3 = require('sqlite3').verbose();
            const db = new sqlite3.Database(dbPath);
            
            db.all(`
                SELECT task_id, prompt, framework, complexity, ts 
                FROM memories 
                ORDER BY ts DESC 
                LIMIT 10
            `, (err, rows) => {
                db.close();
                if (err) {
                    resolve([]);
                } else {
                    resolve(rows || []);
                }
            });
        });
    }
    
    async getLiveLogs() {
        const logPath = path.join(CONFIG.AI_HOME, 'ollama_logs', 'latest.log');
        if (!fs.existsSync(logPath)) {
            return ['No log file found'];
        }
        
        return new Promise((resolve) => {
            fs.readFile(logPath, 'utf8', (err, data) => {
                if (err) {
                    resolve(['Error reading log file']);
                } else {
                    const lines = data.split('\n').filter(line => line.trim());
                    resolve(lines.slice(-this.options.verbose ? 20 : 10));
                }
            });
        });
    }
    
    formatProgressBar(percentage, width = 20) {
        const filled = Math.round((percentage / 100) * width);
        const empty = width - filled;
        const bar = '█'.repeat(filled) + '░'.repeat(empty);
        return `[${bar}] ${percentage.toFixed(1)}%`;
    }
    
    renderSystemStats(stats) {
        console.log(bold(cyan('🖥️  SYSTEM STATUS:')));
        console.log(`  CPU:    ${green(stats.cpu)}`);
        console.log(`  Memory: ${blue(stats.memory)}`);
        console.log(`  Uptime: ${yellow(stats.uptime)}`);
        console.log('');
    }
    
    renderModelStatus(models) {
        console.log(bold(magenta('🧠 AI MODELS:')));
        
        if (models.length === 0) {
            console.log(dim('  No models found. Run: ollama pull <model>'));
            return;
        }
        
        models.forEach((model, index) => {
            const status = model.size ? green('✅ Ready') : yellow('⏳ Downloading');
            const size = model.size ? dim(`(${model.size})`) : '';
            console.log(`  ${index + 1}. ${bold(model.name)} ${status} ${size}`);
        });
        console.log('');
    }
    
    renderRecentTasks(tasks) {
        console.log(bold(yellow('📊 RECENT TASKS:')));
        
        if (tasks.length === 0) {
            console.log(dim('  No recent tasks found'));
            return;
        }
        
        tasks.slice(0, 5).forEach((task, index) => {
            const complexity = '★'.repeat(task.complexity || 1) + '☆'.repeat(5 - (task.complexity || 1));
            const time = new Date(task.ts).toLocaleTimeString();
            const preview = task.prompt.length > 40 ? 
                task.prompt.substring(0, 37) + '...' : task.prompt;
            
            console.log(`  ${index + 1}. ${dim(time)} ${cyan(preview)}`);
            console.log(`     ${dim(task.framework || 'general')} ${yellow(complexity)}`);
        });
        console.log('');
    }
    
    renderLiveLogs(logs) {
        console.log(bold(blue('📝 LIVE ACTIVITY:')));
        
        logs.forEach(log => {
            const level = log.includes('ERROR') ? red('ERROR') :
                         log.includes('WARN') ? yellow('WARN') :
                         log.includes('INFO') ? blue('INFO') :
                         gray('DEBUG');
            
            const message = log.replace(/.*(ERROR|WARN|INFO|DEBUG)\]\s*/, '');
            console.log(`  ${level} ${dim(message)}`);
        });
        
        if (logs.length === 0) {
            console.log(dim('  No recent activity'));
        }
        console.log('');
    }
    
    renderPerformanceMetrics() {
        console.log(bold(green('🚀 PERFORMANCE METRICS:')));
        
        const uptime = Date.now() - this.stats.startTime;
        const hours = Math.floor(uptime / 3600000);
        const minutes = Math.floor((uptime % 3600000) / 60000);
        
        console.log(`  Uptime:        ${yellow(`${hours}h ${minutes}m`)}`);
        console.log(`  Tasks:         ${cyan(this.stats.tasksCompleted)} completed`);
        console.log(`  Models Used:   ${magenta(this.stats.modelsUsed.size)}`);
        console.log(`  Errors:        ${this.stats.errors > 0 ? red(this.stats.errors) : green(this.stats.errors)}`);
        console.log(`  Avg Tokens/s:  ${blue('Calculating...')}`);
        console.log('');
    }
    
    renderWatcherStatus() {
        if (!this.options.watch) return;
        
        console.log(bold(red('👀 LIVE WATCHER ACTIVE')));
        console.log(dim('  Press Ctrl+C to exit | Auto-refresh every 2s'));
        console.log(dim('━'.repeat(this.screen.width - 2)));
    }
    
    async updateDashboard() {
        this.clearScreen();
        this.printHeader();
        
        // Get all data concurrently
        const [systemStats, models, tasks, logs] = await Promise.all([
            this.getSystemStats(),
            this.getOllamaModels(),
            this.getRecentTasks(),
            this.getLiveLogs()
        ]);
        
        // Render all sections
        this.renderSystemStats(systemStats);
        this.renderModelStatus(models);
        this.renderRecentTasks(tasks);
        
        if (this.options.verbose || this.options.log) {
            this.renderLiveLogs(logs);
        }
        
        this.renderPerformanceMetrics();
        this.renderWatcherStatus();
    }
    
    async startWatching() {
        console.log(bold(green('Starting live monitor...')));
        
        while (true) {
            try {
                await this.updateDashboard();
                
                if (!this.options.watch) {
                    break;
                }
                
                // Wait for next update
                await new Promise(resolve => 
                    setTimeout(resolve, CONFIG.POLL_INTERVAL)
                );
            } catch (error) {
                console.error(red(`Monitor error: ${error.message}`));
                await new Promise(resolve => setTimeout(resolve, 5000));
            }
        }
    }
    
    async startModelWatcher() {
        if (!this.options.models) return;
        
        console.log(bold(cyan('Starting model performance monitor...')));
        
        // Monitor Ollama processes
        setInterval(async () => {
            try {
                const processes = await this.getOllamaProcesses();
                if (processes.length > 0 && this.options.verbose) {
                    console.log(dim(`Active Ollama processes: ${processes.length}`));
                }
            } catch (error) {
                // Silent fail for process monitoring
            }
        }, 5000);
    }
    
    async getOllamaProcesses() {
        return new Promise((resolve) => {
            exec('ps aux | grep ollama | grep -v grep', (error, stdout) => {
                if (error) {
                    resolve([]);
                    return;
                }
                
                const processes = stdout.trim().split('\n')
                    .filter(line => line.includes('ollama'))
                    .map(line => {
                        const parts = line.split(/\s+/);
                        return {
                            pid: parts[1],
                            cpu: parts[2],
                            mem: parts[3],
                            command: parts.slice(10).join(' ')
                        };
                    });
                
                resolve(processes);
            });
        });
    }
    
    shutdown() {
        console.log('\n' + bold(yellow('🛑 Shutting down monitor...')));
        console.log(dim('Thanks for using DEX.js!'));
        process.exit(0);
    }
    
    showHelp() {
        console.log(bold(magenta('DEX.js - AI Model Monitor Help')));
        console.log('');
        console.log(bold('USAGE:'));
        console.log('  dex.js [options]');
        console.log('');
        console.log(bold('OPTIONS:'));
        console.log('  --watch     Enable live monitoring with auto-refresh');
        console.log('  --models    Show detailed model information');
        console.log('  --system    Show system resource usage');
        console.log('  --verbose   Show detailed logs and activity');
        console.log('  --log       Show recent log entries');
        console.log('  --help      Show this help message');
        console.log('');
        console.log(bold('EXAMPLES:'));
        console.log('  dex.js --watch              # Live monitoring dashboard');
        console.log('  dex.js --models --verbose   # Detailed model info');
        console.log('  dex.js --system --log       # System stats with logs');
        console.log('');
    }
}

// Command line argument parsing
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        watch: false,
        models: false,
        system: false,
        verbose: false,
        log: false
    };
    
    for (const arg of args) {
        switch (arg) {
            case '--watch':
                options.watch = true;
                break;
            case '--models':
                options.models = true;
                break;
            case '--system':
                options.system = true;
                break;
            case '--verbose':
                options.verbose = true;
                break;
            case '--log':
                options.log = true;
                break;
            case '--help':
            case '-h':
                return { showHelp: true };
            default:
                console.log(red(`Unknown option: ${arg}`));
                return { showHelp: true };
        }
    }
    
    // Default to watch mode if no specific options
    if (!options.watch && !options.models && !options.system && !options.verbose && !options.log) {
        options.watch = true;
        options.models = true;
        options.system = true;
    }
    
    return { options, showHelp: false };
}

// Main execution
async function main() {
    const { options, showHelp } = parseArgs();
    
    if (showHelp) {
        const monitor = new LiveMonitor();
        monitor.showHelp();
        return;
    }
    
    const monitor = new LiveMonitor(options);
    
    try {
        if (options.watch) {
            await monitor.startWatching();
        } else {
            await monitor.updateDashboard();
        }
        
        await monitor.startModelWatcher();
    } catch (error) {
        console.error(red(`Fatal error: ${error.message}`));
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = LiveMonitor;
