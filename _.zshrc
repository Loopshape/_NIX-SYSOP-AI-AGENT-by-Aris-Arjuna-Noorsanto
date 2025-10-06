# ~/.zshrc - Termux SysOp-AI Monokai Dark Theme

# -------------------------------
# Prevent duplicate sourcing
# -------------------------------
[ -n "$ZSHRC_LOADED" ] && return
export ZSHRC_LOADED=1

# -------------------------------
# Only interactive shells
# -------------------------------
[[ $- != *i* ]] && return

# -------------------------------
# History
# -------------------------------
HISTCONTROL=ignoreboth
setopt APPEND_HISTORY
HISTSIZE=5000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# -------------------------------
# Monokai Prompt + Ollama Status
# -------------------------------
autoload -U colors && colors
export MANDATORY_MODELS=("loop" "core" "2244" "coin" "code")

ollama_prompt_status() {
  local status=""
  for model in "${MANDATORY_MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
      if pgrep -f "ollama run $model" >/dev/null 2>&1; then
        status+="%F{green}${model}✔%f "
      else
        status+="%F{yellow}${model}✖%f "
      fi
    else
      status+="%F{red}${model}❌%f "
    fi
  done
  echo "$status"
}

PROMPT='%F{green}%n@%m%f:%F{cyan}%~%f $(ollama_prompt_status)$ '
RPROMPT='%F{magenta}SysOp-AI%f'
setopt prompt_subst

# -------------------------------
# LS colors
# -------------------------------
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
  alias ls='ls --color=auto'
fi

# -------------------------------
# Homebrew / Linuxbrew
# -------------------------------
[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# -------------------------------
# Node.js / NVM
# -------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# -------------------------------
# Aliases
# -------------------------------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ai="$HOME/.bin/ai"
alias angel="pkill ollama && nohup ollama serve & nohup ollama run 2244 &"
alias devil="pkill ollama && nohup ollama serve & nohup ollama run loop &"

# -------------------------------
# SSH agent auto-start
# -------------------------------
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi

# -------------------------------
# AI environment
# -------------------------------
[ -f "$HOME/.local_ai/.env.local" ] && \
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && export "$key=$value"
done < "$HOME/.local_ai/.env.local"

[ -f "$HOME/.sysop_ai_env/bin/activate" ] && source "$HOME/.sysop_ai_env/bin/activate"

# -------------------------------
# Ollama server / models management
# -------------------------------
wait_for_ollama() {
  local retries=10
  while (( retries > 0 )); do
    if ollama list >/dev/null 2>&1; then return 0; fi
    sleep 1
    ((retries--))
  done
  return 1
}

start_ollama_server() {
  if command -v ollama >/dev/null 2>&1 && ! pgrep -x ollama >/dev/null 2>&1; then
    mkdir -p "$HOME/logs"
    nohup ollama serve > "$HOME/logs/ollama_server.log" 2>&1 &
    echo "[INFO] Ollama server starting..."
  fi
}

ai_models_start() {
  start_ollama_server
  sleep 2
  for model in "${MANDATORY_MODELS[@]}"; do
    if ! ollama list | grep -q "$model"; then
      echo "[INFO] Pulling Ollama model: $model"
      if wait_for_ollama; then
        ollama pull "$model" >/dev/null 2>&1
        echo "[INFO] Model $model pull completed."
      else
        echo "[ERROR] Ollama server not responding. Could not pull $model."
      fi
    fi
    if ! pgrep -f "ollama run $model" >/dev/null 2>&1; then
      nohup ollama run "$model" > "$HOME/logs/ollama_${model}.log" 2>&1 &
      echo "[INFO] Ollama model '$model' running..."
    fi
  done
}

# Watchdog to auto-restart server/models
ai_watchdog() {
  while true; do
    start_ollama_server
    for model in "${MANDATORY_MODELS[@]}"; do
      if ! pgrep -f "ollama run $model" >/dev/null 2>&1; then
        echo "[WATCHDOG] Restarting model: $model"
        nohup ollama run "$model" > "$HOME/logs/ollama_${model}.log" 2>&1 &
      fi
    done
    sleep 10
  done
}

# Launch watchdog & models
(ai_watchdog) &
(ai_models_start) &

# -------------------------------
# Python3 + Pygments check
# -------------------------------
ai_status() {
  echo "===================== SysOp-AI Status ====================="
  echo "Python3: $(command -v python3 >/dev/null 2>&1 && python3 --version || echo 'Not installed')"
  echo "Pygments: $(python3 -m pip show Pygments >/dev/null 2>&1 && echo 'Installed' || echo 'Not installed')"
  echo "NodeJS: $(command -v node >/dev/null 2>&1 && node --version || echo 'Not installed')"
  echo "Ollama server: $(pgrep -x ollama >/dev/null 2>&1 && echo 'Running' || echo 'Not running')"
  for model in "${MANDATORY_MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
      if pgrep -f "ollama run $model" >/dev/null 2>&1; then
        echo "  - $model: Running"
      else
        echo "  - $model: Not running"
      fi
    else
      echo "  - $model: Not pulled"
    fi
  done
  echo "AI environment: $( [ -f "$HOME/.sysop_ai_env/bin/activate" ] && echo Active || echo Not found )"
  echo "============================================================"
}
