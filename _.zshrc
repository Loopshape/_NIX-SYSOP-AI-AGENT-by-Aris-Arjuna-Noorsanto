======================================================================
​.zshrc - Zsh Initialization File
​======================================================================
​This file is sourced when starting an interactive shell.
​----------------------------------------------------------------------
​1. Essential Zsh Options and History Management
​----------------------------------------------------------------------
​Set path to history file
​HISTFILE=~/.zsh_history
​Set history size limits
​HISTSIZE=50000
SAVEHIST=10000
​Share history across all sessions
​setopt sharehistory
​Immediately append commands to history
​setopt inc_append_history
​Don't record duplicates
​setopt hist_ignore_all_dups
​Auto-correct misspelled commands
​setopt correct
​Allow filenames with hyphens
​setopt nomatch
​----------------------------------------------------------------------
​2. Advanced Completion Setup
​----------------------------------------------------------------------
​Initialize the completion system
​autoload -Uz compinit
compinit
​Enable case-insensitive matching in completion
​_comp_options+=(globdots)
​----------------------------------------------------------------------
​3. Oh My Zsh (OMZ) Integration (Uncomment to use)
​----------------------------------------------------------------------
​If you choose to use Oh My Zsh, uncomment the following lines.
​ZSH_CUSTOM defines where your custom OMZ files are.
​ZSH_THEME="agnoster"
​plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
​source $ZSH/oh-my-zsh.sh
​----------------------------------------------------------------------
​4. Git Integration (Used if OMZ is NOT sourced)
​----------------------------------------------------------------------
​Zsh function to display Git branch information in the prompt
​git_prompt_info() {
# Check if we are inside a Git repository
if command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
# Get the current branch name
local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
​Check if there are uncommitted changes
​local dirty=$(git status --porcelain 2>/dev/null)
