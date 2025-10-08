#!/bin/env bash

pkill -f "ollama serve|ollama run" 2>/dev/null; \
mkdir -p "$HOME/logs"; \
nohup ollama serve >"$HOME/logs/ollama_server.log" 2>&1 & sleep 2; \
for model in loop core 2244 coin code; do \
  nohup ollama run "$model" >"$HOME/logs/ollama_${model}.log" 2>&1 & \
done; \

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PATH="$PATH:~/.bin:~/_"

bash
