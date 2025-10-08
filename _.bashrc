======================================================================
​.bashrc - Bash Initialization File
​======================================================================
​This file is sourced for interactive non-login shells.
​For login shells, use ~/.bash_profile or ~/.profile.
​----------------------------------------------------------------------
​1. Essential Check: Only run for interactive shells
​----------------------------------------------------------------------
​Ensure this script only runs when the shell is interactive.
​if [ -z "$PS1" ]; then
return
fi
​----------------------------------------------------------------------
​2. Color Settings and LS_COLORS
​----------------------------------------------------------------------
​Enable color support for ls and other utilities
​if [ -x /usr/bin/dircolors ]; then
# Use pre-configured colors if available
test -r ~/.dircolors && eval "(dircolors -b ~/.dircolors)" || eval "(dircolors -b)"
