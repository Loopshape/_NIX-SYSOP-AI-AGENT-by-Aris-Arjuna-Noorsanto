#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import os from 'os';
import chalk from 'chalk';

/**
 * Run shell command
 */
function runCommand(cmd) {
  return new Promise((resolve) => {
    exec(cmd, (error, stdout, stderr) => {
      resolve({
        success: !error,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
      });
    });
  });
}

/**
 * Detect project/environment
 */
function detectProject() {
  const cwd = process.cwd();
  const packageJson = path.join(cwd, 'package.json');
  if (fs.existsSync(packageJson)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(packageJson, 'utf-8'));
      return pkg.name || path.basename(cwd);
    } catch {
      return path.basename(cwd);
    }
  }
  return path.basename(cwd);
}

/**
 * Log results
 */
function logResult(projectName, task, data) {
  const logDir = path.join(process.cwd(), '.ai_logs');
  if (!fs.existsSync(logDir)) fs.mkdirSync(logDir);

  const timestamp = new Date().toISOString().replace(/:/g, '-');
  const logFile = path.join(logDir, `${projectName}_${task.replace(/\s+/g,'_')}_${timestamp}.log`);

  fs.writeFileSync(logFile, JSON.stringify(data, null, 2), 'utf-8');
  console.log(chalk.green(`✅ Log saved to ${logFile}`));
}

/**
 * Probe environment
 */
async function probeEnvironment(projectName) {
  const [node, npm, python, pip, git, go, gcc, make, sqlite3] = await Promise.all([
    runCommand('node -v'),
    runCommand('npm -v'),
    runCommand('python3 --version'),
    runCommand('pip3 --version'),
    runCommand('git --version'),
    runCommand('go version'),
    runCommand('gcc --version'),
    runCommand('make --version'),
    runCommand('sqlite3 --version'),
  ]);

  const files = fs.readdirSync(process.cwd());

  return {
    project: projectName,
    cwd: process.cwd(),
    platform: os.platform(),
    node, npm, python, pip, git, go, gcc, make, sqlite3,
    files,
  };
}

/**
 * Analyze dependencies
 */
async function analyzeDependencies() {
  const nodeDeps = fs.existsSync('package.json')
    ? JSON.parse(fs.readFileSync('package.json', 'utf-8')).dependencies || {}
    : {};
  const pyDepsCmd = await runCommand('pip3 list --format=json');
  let pyDeps = [];
  try { pyDeps = JSON.parse(pyDepsCmd.stdout); } catch {}
  return { nodeDeps, pyDeps };
}

/**
 * List files
 */
function listFiles() {
  return fs.readdirSync(process.cwd());
}

/**
 * Print colored summary
 */
function printSummary(title, data) {
  console.log(chalk.yellow(`\n--- ${title} ---`));
  console.dir(data, { depth: 3, colors: true });
}

/**
 * Run setup
 */
async function runSetup() {
  console.log(chalk.cyanBright('Running AI CLI setup...'));

  const logDir = path.join(process.cwd(), '.ai_logs');
  if (!fs.existsSync(logDir)) fs.mkdirSync(logDir);

  try {
    require.resolve('chalk');
    console.log(chalk.green('✅ chalk is installed'));
  } catch {
    console.log(chalk.yellow('⚠ chalk not found. Installing...'));
    await runCommand('npm install chalk');
    console.log(chalk.green('✅ chalk installed'));
  }

  const tools = ['node -v', 'npm -v', 'python3 --version', 'pip3 --version', 'git --version', 'go version', 'gcc --version', 'make --version', 'sqlite3 --version'];
  console.log(chalk.cyan('Checking required tools...'));
  for (const cmd of tools) {
    const result = await runCommand(cmd);
    console.log(result.success ? chalk.green(`✅ ${cmd.split(' ')[0]} found: ${result.stdout}`) : chalk.red(`❌ ${cmd.split(' ')[0]} not found`));
  }

  console.log(chalk.cyanBright('Setup complete!'));
}

/**
 * Self-update
 */
async function runUpdate() {
  console.log(chalk.cyanBright('Updating AI CLI...'));

  // 1. Pull latest code if this is a Git repo
  if (fs.existsSync('.git')) {
    console.log(chalk.cyan('Pulling latest code from Git...'));
    const gitPull = await runCommand('git pull');
    console.log(gitPull.stdout || gitPull.stderr);
  } else {
    console.log(chalk.yellow('⚠ Not a Git repository, skipping git pull.'));
  }

  // 2. Update chalk
  console.log(chalk.cyan('Ensuring chalk is up-to-date...'));
  await runCommand('npm install chalk@latest');
  console.log(chalk.green('✅ chalk updated'));

  // 3. Re-run setup
  await runSetup();

  console.log(chalk.cyanBright('Update complete!'));
}

/**
 * Main orchestrator
 */
async function runOrchestrator() {
  const projectName = detectProject();
  const args = process.argv.slice(2);
  const taskPrompt = args.join(' ').trim().toLowerCase() || 'scan env .';

  if (taskPrompt === 'setup') {
    await runSetup();
    return;
  }

  if (taskPrompt === 'update') {
    await runUpdate();
    return;
  }

  console.log(chalk.cyanBright(`AI Task: ${taskPrompt}`));
  let result;

  if (taskPrompt.includes('scan env')) {
    result = await probeEnvironment(projectName);
    printSummary('Environment Summary', result);
  } else if (taskPrompt.includes('analyze dependencies')) {
    result = await analyzeDependencies();
    printSummary('Dependency Analysis', result);
  } else if (taskPrompt.includes('check python packages')) {
    const pyDeps = await analyzeDependencies();
    result = pyDeps.pyDeps;
    printSummary('Python Packages', result);
  } else if (taskPrompt.includes('list files')) {
    result = listFiles();
    printSummary('Files in Directory', result);
  } else {
    result = { message: `Prompt "${taskPrompt}" not recognized. Try: setup, update, scan env, analyze dependencies, check python packages, list files.` };
    printSummary('AI Response', result);
  }

  if (!['setup', 'update'].includes(taskPrompt)) {
    logResult(projectName, taskPrompt, result);
  }
}

/**
 * Entry point
 */
(async () => {
  await runOrchestrator();
})();