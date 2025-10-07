#!/bin/env bash
sudo npm install --save-all ~/ai package*.json
node_modules --devDependencies --build .
