#!/bin/env bash
sudo npm install --save-all .ai/api package*.json
node_modules --devDependencies --build .
