#!/usr/bin/env node
import chalk from "chalk";

const args = process.argv.slice(2);
const prompt = args.filter(a => !a.startsWith("--")).join(" ");
const options = Object.fromEntries(args.filter(a => a.startsWith("--")).map(a => {
  const parts = a.slice(2).split("=");
  return [parts[0], parts[1] ?? true];
}));

let WEB_DEV_MODELS = ["code", "loop", "2244", "coin", "core"];
if (options.models) WEB_DEV_MODELS = options.models.split(",");
const VERBOSE = options.verbose !== "false";

console.log(chalk.bold.cyan("\n🚀 WEBDEV VERBOSE AI ENGINE START"));
console.log(chalk.cyan("──────────────────────────────────────────────"));
console.log(chalk.bold.cyan(`🧩 Active Model Pool: ${WEB_DEV_MODELS.join(", ")}`));
console.log(chalk.gray(`💬 Prompt: "${prompt}"\n`));

const think = (msg, lvl = 0) => {
  if (VERBOSE) console.log(chalk.gray("  ".repeat(lvl) + `🤔 ${msg}`));
};

async function runModel(model, text, iteration) {
  think(`Model ${model} begins iteration ${iteration}`, 1);
  // simulate delay
  await new Promise(r => setTimeout(r, 400 + Math.random() * 400));
  const simulated = `(${model.toUpperCase()}): analyzed prompt fragment [${text.slice(0, 20)}...]`;
  if (VERBOSE) console.log(chalk.blueBright(simulated));
  return simulated;
}

async function consensus(promptText) {
  let fused = "", converged = false;
  for (let i = 0; i < 3 && !converged; i++) {
    think(`Consensus iteration ${i + 1}`, 0);
    const outputs = await Promise.all(
      WEB_DEV_MODELS.map(m => runModel(m, promptText, i + 1))
    );
    const fusion = outputs.join("\n");
    if (fusion === fused) {
      converged = true;
      think(`Consensus converged at iteration ${i + 1}`, 1);
    } else {
      fused = fusion;
      think(`Consensus not yet stable; continuing`, 1);
    }
  }
  return fused;
}

const result = await consensus(prompt);
console.log(chalk.bold.green("\n✅ FINAL CONSENSUS OUTPUT"));
console.log(chalk.cyan(result));
console.log(chalk.cyan("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"));
