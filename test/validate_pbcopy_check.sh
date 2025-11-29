#!/bin/bash
set -e

# Temporarily remove pbcopy from PATH
export PATH=$(echo $PATH | sed 's|/usr/bin:||')

nvim --headless \
  -c 'lua require("marked-preview").setup()' \
  -c 'qa!' > test/results/pbcopy_check.log 2>&1

nvim --headless -c "set rtp+=." -c "lua local file = io.open('test/results/pbcopy_check.log', 'r'); if file then local content = file:read('*a'); file:close(); if string.find(content, '`pbcopy` command not found') then print('✅ pbcopy check works'); vim.cmd('cquit') else print('❌ pbcopy check failed'); vim.cmd('cquit 1') end end"
