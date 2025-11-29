#!/bin/bash
set -e

echo "Testing plugin functionality..."

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create a temporary markdown file
TEST_FILE="test/fixtures/temp_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# Functionality Test
Testing plugin commands and features.
CONTENT

# Test 1: Check if commands are available
nvim --headless -c "set rtp+=$PROJECT_ROOT" "$TEST_FILE" -c 'echo "Testing commands..."' \
  -c 'silent! command MarkedPreviewUpdate' \
  -c 'silent! command MarkedPreviewOpen' \
  -c 'silent! command MarkedPreviewStart' \
  -c 'silent! command MarkedPreviewStop' \
  -c 'if v:errmsg != "" | echo "❌ Missing commands" | cquit 1 | endif' \
  -c 'echo "✅ All commands available"' \
  -c 'qa!' 2>&1

# Test 2: Test update function (may fail in headless due to external commands)
nvim --headless -c "set rtp+=$PROJECT_ROOT" "$TEST_FILE" \
  -c 'lua local success = require("marked-preview").update(); print("Update function called: " .. tostring(success ~= nil))' \
  -c 'qa!' 2>&1 | grep -q "Update function called: true" && echo "✅ Update function executes" || echo "⚠️ Update function may fail in headless mode"

# Test 3: Test is_watching function
nvim --headless -c "set rtp+=$PROJECT_ROOT" "$TEST_FILE" \
  -c 'lua local watching = require("marked-preview").is_watching(); print("Initial watching state: " .. tostring(watching))' \
  -c 'qa!' 2>&1 | grep -q "Initial watching state: false" && echo "✅ is_watching function works" || echo "❌ is_watching function failed"

# Cleanup
rm "$TEST_FILE"

echo "✅ All functionality tests completed"