#!/bin/env node

// Modular Ollama API client for Nemodian-compatible models
// Supports: model ⇄ token ⇄ prompt flow
// Uses streaming responses from /api/generate

import http from "http";

// Base configuration
const OLLAMA_HOST = process.env.OLLAMA_HOST || "localhost";
const OLLAMA_PORT = process.env.OLLAMA_PORT || 11434;

/**
 * Run a prompt on a given model using Ollama/Nemodian API.
 * @param {Object} opts
 * @param {string} opts.model - Model name (e.g. nemodian-coder)
 * @param {string} opts.prompt - Text prompt or task
 * @param {Object} [opts.modulo] - Optional metadata or token info
 * @param {boolean} [opts.stream=true] - Whether to stream tokens
 * @returns {Promise<string>} Full model output
 */
export async function runModelAPI({ model, prompt, modulo = {}, stream = true }) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      model,
      prompt,
      ...modulo,
      stream,
    });

    const req = http.request(
      {
        hostname: OLLAMA_HOST,
        port: OLLAMA_PORT,
        path: "/api/generate",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(payload),
        },
      },
      (res) => {
        if (res.statusCode !== 200) {
          reject(new Error(`Ollama API error: ${res.statusCode}`));
          return;
        }

        let fullOutput = "";
        let buffer = "";

        res.on("data", (chunk) => {
          buffer += chunk.toString();

          // Process streamed JSON lines
          const parts = buffer.split("\n");
          buffer = parts.pop() || "";

          for (const line of parts) {
            if (!line.trim()) continue;
            try {
              const json = JSON.parse(line);
              if (json.response) {
                process.stdout.write(json.response); // Live stream to terminal
                fullOutput += json.response;
              }
              if (json.done) {
                resolve(fullOutput.trim());
              }
            } catch {
              // Partial chunk, ignore
            }
          }
        });

        res.on("end", () => {
          if (fullOutput.trim()) resolve(fullOutput.trim());
        });
      }
    );

    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}
