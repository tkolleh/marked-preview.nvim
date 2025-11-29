#!/bin/bash
set -e

echo "Testing plugin loading..."

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test if plugin loads without errors
nvim --headless -c "set rtp+=$PROJECT_ROOT" -c 'lua require("marked-preview")' -c 'qa!' 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Plugin loads successfully"
else
    echo "❌ Plugin failed to load"
    exit 1
fi

# Test setup function
nvim --headless -c "set rtp+=$PROJECT_ROOT" -c 'lua require("marked-preview").setup()' -c 'qa!' 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Setup function works"
else
    echo "❌ Setup function failed"
    exit 1
fi

echo "✅ All plugin loading tests passed"