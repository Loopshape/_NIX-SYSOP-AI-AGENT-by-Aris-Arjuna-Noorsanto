#!/usr/bin/env bash
set -euo pipefail

OLLAMA_HOST="http://localhost:11434"
DEFAULT_MODEL="codellama"
AI_SESSION_FILE="$HOME/.ai_last_session.json"
MANDATORY_MODELS=("code" "loop" "2244" "coin" "core")

COLOR_RESET="\x1b[0m"; COLOR_CYAN="\x1b[36m"; COLOR_RED="\x1b[31m"; COLOR_YELLOW="\x1b[33m"
log_info(){ echo -e "${COLOR_CYAN}[INFO] $1${COLOR_RESET}" >&2; }
log_error(){ echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}" >&2; }

run_webdev_task() {
    local PROMPT="$1"
    local ENGINE_PATH="$(dirname "$0")/webdev-engine.js"
    if [[ ! -f "$ENGINE_PATH" ]]; then
        log_error "WebDev engine not found at $ENGINE_PATH"
        exit 1
    fi
    local MODEL_LIST; MODEL_LIST=$(IFS=,; echo "${MANDATORY_MODELS[*]}")
    log_info "Launching WebDev AI Engine (verbose) with models: $MODEL_LIST"
    node "$ENGINE_PATH" "$PROMPT" --models="$MODEL_LIST" --verbose=true
}

case "${1:-}" in
  dev)
    [[ -z "${2:-}" ]] && { log_error "Missing prompt."; exit 1; }
    run_webdev_task "$2"
    ;;
  *)
    echo -e "${COLOR_YELLOW}Usage: $0 dev 'prompt for WebDev AI'${COLOR_RESET}"
    ;;
esac
