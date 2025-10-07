# ~/.bashrc - Termux SysOp-AI Adapted

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
HISTSIZE=5000
HISTFILESIZE=10000

# -------------------------------
# Prompt (with colors if supported)
# -------------------------------
case "$TERM" in xterm-color | *-256color) color_prompt=yes ;; esac
if [ "$color_prompt" = yes ]; then
	PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	PS1='\u@\h:\w\$ '
fi
unset color_prompt

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
# AI environment activation
# -------------------------------
[ -f "$HOME/.local_ai/.env.local" ] &&
	while IFS='=' read -r key value; do
		[[ -z "$key" || "$key" =~ ^# ]] && continue
		[[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && export "$key=$value"
	done <"$HOME/.local_ai/.env.local"

[ -f "$HOME/.sysop_ai_env/bin/activate" ] && source "$HOME/.sysop_ai_env/bin/activate"

# -------------------------------
# Mandatory Ollama models
# -------------------------------
export MANDATORY_MODELS=("loop" "core" "2244" "coin" "code")

# Wait for Ollama server to respond
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

# Start Ollama server if not running
start_ollama_server() {
	if command -v ollama >/dev/null 2>&1 && ! pgrep -x ollama >/dev/null 2>&1; then
		mkdir -p "$HOME/logs"
		nohup ollama serve >"$HOME/logs/ollama_server.log" 2>&1 &
		echo "[INFO] Ollama server starting in background..."
	fi
}

# Pull and run mandatory models
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
			#            echo "[INFO] Ollama model '$model' running in background..."
		fi
	done
}

# Auto-start models in background after login
(ai_models_start) &

# -------------------------------
# SysOp-AI Environment Status
# -------------------------------
ai_status() {
	echo "===================== SysOp-AI Status ====================="
	echo "User: $USER"
	echo "Home: $HOME"
	echo
	# Python3 + Pygments
	if command -v python3 >/dev/null 2>&1; then
		echo "Python3: $(python3 --version)"
		if python3 -m pip show Pygments >/dev/null 2>&1; then
			echo "Pygments: Installed"
		else
			echo "Pygments: Not installed"
		fi
	else
		echo "Python3: Not installed"
	fi
	# Node.js / NVM
	if command -v node >/dev/null 2>&1; then
		echo "NodeJS: $(node --version)"
	else
		echo "NodeJS: Not installed"
	fi
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
	# AI environment
	if [ -f "$HOME/.sysop_ai_env/bin/activate" ]; then
		echo "AI environment: Active ($HOME/.sysop_ai_env)"
	else
		echo "AI environment: Not found"
	fi
	echo "============================================================"
}

source /home/loop/.env.local/bin/activate

# ====== Monokai-style shell prompt ======
if [ -d "$HOME/.env.local" ]; then
	source "$HOME/.env.local/bin/activate"
	export VIRTUAL_ENV_PROMPT="(ai) "
fi

# Define Monokai color palette
MONOKAI_YELLOW='\[\033[38;5;221m\]'
MONOKAI_GREEN='\[\033[38;5;148m\]'
MONOKAI_PINK='\[\033[38;5;205m\]'
MONOKAI_CYAN='\[\033[38;5;81m\]'
MONOKAI_GRAY='\[\033[38;5;240m\]'
RESET='\[\033[0m\]'

# Custom PS1 prompt with Monokai styling
PS1="${MONOKAI_PINK}(ai)${RESET} ${MONOKAI_GREEN}\u${RESET}@${MONOKAI_CYAN}\h${RESET}:${MONOKAI_YELLOW}\w${RESET}\$ "

# ====== ALL-IN-ONE MONOKAI OLLAMA DEV ENVIRONMENT ======

# 1️⃣ Auto-activate venv globally
if [ -d "$HOME/.env.local" ]; then
	source "$HOME/.env.local/bin/activate"
	export VIRTUAL_ENV_PROMPT="(ai) "
fi

# 2️⃣ Monokai terminal colors
MONOKAI_BLACK='\[\033[38;5;232m\]'
MONOKAI_RED='\[\033[38;5;203m\]'
MONOKAI_ORANGE='\[\033[38;5;215m\]'
MONOKAI_YELLOW='\[\033[38;5;229m\]'
MONOKAI_GREEN='\[\033[38;5;121m\]'
MONOKAI_CYAN='\[\033[38;5;81m\]'
MONOKAI_BLUE='\[\033[38;5;69m\]'
MONOKAI_PURPLE='\[\033[38;5;207m\]'
MONOKAI_PINK='\[\033[38;5;205m\]'
MONOKAI_GRAY='\[\033[38;5;245m\]'
RESET='\[\033[0m\]'

# 3️⃣ Monokai shell prompt
PS1="${MONOKAI_PINK}(ai)${RESET} ${MONOKAI_GREEN}\u${RESET}@${MONOKAI_CYAN}\h${RESET}:${MONOKAI_YELLOW}\w${RESET}\$ "

# 4️⃣ AI pipeline Monokai wrapper
function ai-monokai() {
	ai "$@" 2>&1 | while IFS= read -r line; do
		if [[ "$line" == *"[INFO]"* ]]; then
			echo -e "${MONOKAI_CYAN}${line}${RESET}"
		elif [[ "$line" == *"[TASK_START]"* ]]; then
			echo -e "${MONOKAI_GREEN}${line}${RESET}"
		elif [[ "$line" == *"[ERROR]"* ]]; then
			echo -e "${MONOKAI_RED}${line}${RESET}"
		elif [[ "$line" == *"Model"* ]]; then
			echo -e "${MONOKAI_PURPLE}${line}${RESET}"
		else
			echo -e "${MONOKAI_GRAY}${line}${RESET}"
		fi
	done
}

# Alias original AI command to the Monokai wrapper
alias ai='ai-monokai'

# 5️⃣ Python / Rich Monokai environment variable
export PYGMENTS_STYLE=monokai

# 6️⃣ Optional: IPython Monokai
ipython_profile="$HOME/.ipython/profile_default/ipython_config.py"
if [ ! -f "$ipython_profile" ]; then
	ipython profile create
fi
echo "c.TerminalInteractiveShell.highlighting_style = 'monokai'" >>"$ipython_profile"
echo "c.TerminalInteractiveShell.highlighting_style_overrides = {}" >>"$ipython_profile"

# 7️⃣ Jupyter Monokai (if jupyterthemes installed)
if command -v jt >/dev/null 2>&1; then
	jt -t monokai -fs 11 -nf ptsans -tf ptsans -ofs 11 -T -N
fi

# ===============================================

export PATH="$PATH:/home/loop/_"
