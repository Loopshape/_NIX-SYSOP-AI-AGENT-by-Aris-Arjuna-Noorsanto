#!/usr/bin/env bash

# This script correctly installs all dependencies for the current Node.js project.

# Navigate to the project root directory (where package.json is located)
# Your project files are in ~/ so we change directory there first
cd ~

echo "Installing project dependencies..."

# The standard command to install all dependencies (main and dev)
# We use 'npm ci' if a package-lock.json exists for clean, repeatable installs.
# We don't need 'sudo' unless the npm global install path is restricted.
npm ci || npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully."
else
    echo "❌ Dependencies installation failed. Check the npm logs."
fi

# We don't need to exit here, but it's good practice
exit 0
