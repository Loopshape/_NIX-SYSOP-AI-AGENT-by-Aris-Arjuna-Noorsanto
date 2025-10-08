======================================================================
​.bash_profile - Bash Login Shell Configuration
​======================================================================
​This file is executed when you log in (e.g., via SSH or a terminal emulator).
​It's primarily used for setting environment variables and defining the PATH.
​----------------------------------------------------------------------
​1. PATH Configuration
​----------------------------------------------------------------------
​Ensure common user binaries directories are included and prioritized.
​The default system paths are usually set automatically, but these ensure
​that custom user installs and local binaries are available.
​export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
​Example: Add a specific development tool's bin folder to the PATH
​export PATH="/opt/devtools/bin:$PATH"
​----------------------------------------------------------------------
​2. Environment Variables
​----------------------------------------------------------------------
​Set the default editor for commands like 'git commit' or 'crontab -e'
​export EDITOR='nano' # Or 'vim', 'emacs', 'code', etc.
​Set the pager for viewing long output (e.g., man pages)
​export PAGER='less'
​Set default locale to UTF-8
​export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
​----------------------------------------------------------------------
​3. Source .bashrc for interactive shells
​----------------------------------------------------------------------
​If the shell is interactive, we need to explicitly source .bashrc
​because .bash_profile is only read for login shells, and .bashrc holds
​the crucial aliases, functions, and prompt settings for interactivity.
​if [ -f "$HOME/.bashrc" ]; then
# The 'source' command (or '.') reads the contents of the file
source "$HOME/.bashrc"
fi
​----------------------------------------------------------------------
​4. Source NVM (Node Version Manager) or similar tools (optional)
​----------------------------------------------------------------------
​Uncomment and adjust if you use Node Version Manager
​export NVM_DIR="$HOME/.nvm"
​[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
​[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # This loads nvm bash_completion
​----------------------------------------------------------------------
​5. Welcome/Message of the Day (optional)
​----------------------------------------------------------------------
​Clear the screen after the profile runs (optional)
​clear
