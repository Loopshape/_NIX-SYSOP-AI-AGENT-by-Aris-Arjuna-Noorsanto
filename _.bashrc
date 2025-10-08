# ~/.bashrc - Termux SysOp-AI Adapted (Fixed)

# Prevent duplicate sourcing
[ -n "$BASHRC_LOADED" ] && return
export BASHRC_LOADED=1

# Only interactive shells
case $- in *i*) ;; *) return ;; esac

# -------------------------------
# History
# -------------------------------
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
HISTSIZE=2048
HISTFILESIZE=8096

# -------------------------------
# Prompt (Monokai-style colors)
# -------------------------------
MONOKAI_YELLOW='\033[38;5;221m'
MONOKAI_GREEN='\033[38;5;148m'
MONOKAI_PINK='\033[38;5;205m'
MONOKAI_CYAN='\033[38;5;81m'
MONOKAI_GRAY='\033[38;5;240m'
RESET='\033[0m'

PS1="${MONOKAI_PINK}(ai)${RESET} ${MONOKAI_GREEN}\u${RESET}@${MONOKAI_CYAN}\h${RESET}:${MONOKAI_YELLOW}\w${RESET}\$ "

# -------------------------------
# LS colors
# -------------------------------
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
fi

# -------------------------------
# Homebrew (Linuxbrew)
# -------------------------------
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# -------------------------------
# Node.js / NVM
# -------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# -------------------------------
# AI Environment
# -------------------------------
[ -f "$HOME/.local_ai/.env.local" ] &&
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && export "$key=$value"
done <"$HOME/.local_ai/.env.local"

[ -f "$HOME/.sysop_ai_env/bin/activate" ] && source "$HOME/.sysop_ai_env/bin/activate"

# -------------------------------
# Ollama logs
# -------------------------------
export OLLAMA_LOG_DIR="$HOME/.ollama_logs"
mkdir -p "$OLLAMA_LOG_DIR"

# -------------------------------
# Ollama multi-model vertical stream
# -------------------------------
ollama_stream() {
    local MODEL="$1"
    shift
    local PROMPT="$*"

    if [ -z "$MODEL" ] || [ -z "$PROMPT" ]; then
        echo "Usage: ollama_stream <model> <prompt>"
        return 1
    fi

    local LOGFILE="$OLLAMA_LOG_DIR/${MODEL}_$(date '+%Y%m%d_%H%M%S').log"
    local count=0

    echo "🧠 Streaming model '$MODEL' vertically..."
    echo "Prompt: $PROMPT"
    echo "Logging to: $LOGFILE"
    echo "-----------------------------------"

    # Stream tokens from Ollama
    ollama run "$MODEL" "$PROMPT" --stream | while IFS= read -r line; do
        for token in $line; do
            ((count++))
            printf "%04d | %s\n" "$count" "$token" | tee -a "$LOGFILE"
        done
    done

    echo "-----------------------------------"
    echo "🪶 Stream complete. Log saved at: $LOGFILE"
}

# -------------------------------
# Ollama interactive vertical/horizontal stream
# -------------------------------
ollama_stream_interactive() {
    local MODEL="$1"
    shift
    local PROMPT="$*"

    if [ -z "$MODEL" ] || [ -z "$PROMPT" ]; then
        echo "Usage: ollama_stream_interactive <model> <prompt>"
        return 1
    fi

    local LOGFILE="$OLLAMA_LOG_DIR/${MODEL}_$(date '+%Y%m%d_%H%M%S').log"
    local count=0
    local MODE="vertical"   # default display mode

    echo "🧠 Interactive streaming model '$MODEL'..."
    echo "Prompt: $PROMPT"
    echo "Logging to: $LOGFILE"
    echo "Toggle display mode: press 't', stop: Ctrl+C"
    echo "-----------------------------------"

    # Start a background listener for keypress to toggle mode
    ( while true; do
          read -rsn1 key
          if [[ "$key" == "t" ]]; then
              if [[ "$MODE" == "vertical" ]]; then MODE="horizontal"
              else MODE="vertical"
              fi
              echo -e "\n[MODE SWITCHED → $MODE]\n"
          fi
      done ) &

    local LISTENER_PID=$!

    # Stream tokens from Ollama
    ollama run "$MODEL" "$PROMPT" --stream | while IFS= read -r line; do
        for token in $line; do
            ((count++))
            if [[ "$MODE" == "vertical" ]]; then
                printf "%04d | %s\n" "$count" "$token" | tee -a "$LOGFILE"
            else
                printf "%s " "$token" | tee -a "$LOGFILE"
            fi
        done
        if [[ "$MODE" == "horizontal" ]]; then
            echo
        fi
    done

    # Stop background listener
    kill $LISTENER_PID 2>/dev/null

    echo "-----------------------------------"
    echo "🪶 Stream complete. Log saved at: $LOGFILE"
}

# -------------------------------
# Ollama vertical stream function
# -------------------------------
ollama_vertical() {
    local PROMPT="$*"
    local LOGFILE="$OLLAMA_LOG_DIR/vertical_$(date '+%Y%m%d_%H%M%S').log"
    local count=0

    echo "🧠 Vertical streaming initiated..."
    echo "Prompt: $PROMPT"
    echo "Logging to: $LOGFILE"
    echo "-----------------------------------"

    ollama run coin "$PROMPT" --stream | while IFS= read -r line; do
        for token in $line; do
            ((count++))
            printf "%04d | %s\n" "$count" "$token" | tee -a "$LOGFILE"
        done
    done

    echo "-----------------------------------"
    echo "🪶 Stream complete. Log saved at: $LOGFILE"
}

# Horizontal (normal) Ollama stream
ollama_flat() {
    local PROMPT="$*"
    echo "🧠 Horizontal streaming initiated..."
    ollama run 2244 "$PROMPT"
}

# Quick aliases
alias ollv='ollama_vertical'
alias ollh='ollama_flat'

# -------------------------------
# Other aliases
# -------------------------------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ai="$HOME/.bin/ai"
alias angel="pkill ollama && nohup ollama serve & nohup ollama run 2244 &"
alias devil="pkill ollama && nohup ollama serve & nohup ollama run loop &"
alias surf="ai /usr/bin/* | $0 .ai '.ai ai'"

# -------------------------------
# SSH agent auto-start
# -------------------------------
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)"
fi

# -------------------------------
# Ollama server helpers
# -------------------------------
MANDATORY_MODELS=("loop" "core" "2244" "coin" "code")

wait_for_ollama() {
    local retries=10
    while ((retries > 0)); do
        if ollama list >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((retries--))
    done
    return 1
}

start_ollama_server() {
    if command -v ollama >/dev/null 2>&1 && ! pgrep -x ollama >/dev/null 2>&1; then
        mkdir -p "$HOME/logs"
        nohup ollama serve >"$HOME/logs/ollama_server.log" 2>&1 &
        echo "[INFO] Ollama server starting in background..."
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
                continue
            fi
        fi
        if ! pgrep -f "ollama run $model" >/dev/null 2>&1; then
            nohup ollama run "$model" >"$HOME/logs/ollama_${model}.log" 2>&1 &
        fi
    done
}

# Start mandatory models in background after login
(ai_models_start) &

# -------------------------------
# SysOp-AI Status Function
# -------------------------------
ai_status() {
    echo "===================== SysOp-AI Status ====================="
    echo "User: $USER"
    echo "Home: $HOME"
    echo
    # Ollama server
    if pgrep -x ollama >/dev/null 2>&1; then
        echo "Ollama server: Running"
    else
        echo "Ollama server: Not running"
    fi
    # Ollama models
    if command -v ollama >/dev/null 2>&1; then
        echo "Ollama models:"
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
    fi
    echo "============================================================"
}

# -------------------------------
# Aliases for Monokai AI wrapper
# -------------------------------
function ai-monokai() {
    ai "$@" 2>&1 | while IFS= read -r line; do
        case "$line" in
            *"[INFO]"*) echo -e "${MONOKAI_CYAN}${line}${RESET}" ;;
            *"[TASK_START]"*) echo -e "${MONOKAI_GREEN}${line}${RESET}" ;;
            *"[ERROR]"*) echo -e "${MONOKAI_RED}${line}${RESET}" ;;
            *"Model"*) echo -e "${MONOKAI_PINK}${line}${RESET}" ;;
            *) echo -e "${MONOKAI_GRAY}${line}${RESET}" ;;
        esac
    done
}
alias ai='ai-monokai'

# -------------------------------
# End of fixed .bashrc
# -------------------------------

exec /home/loop/.profile
