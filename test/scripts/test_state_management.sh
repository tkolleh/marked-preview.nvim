#!/bin/bash
set -e

echo "Testing state management..."

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEST_FILE="test/fixtures/state_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# State Management Test
CONTENT

# Test watching state
nvim --headless -c "set rtp+=$PROJECT_ROOT" "$TEST_FILE" \
  -c 'lua print("Initial watching state: " .. tostring(require("marked-preview").is_watching()))' \
  -c 'lua require("marked-preview").start_watching(); print("After start watching: " .. tostring(require("marked-preview").is_watching()))' \
  -c 'lua require("marked-preview").stop_watching(); print("After stop watching: " .. tostring(require("marked-preview").is_watching()))' \
  -c 'qa!' 2>&1 | tee test/results/state_test.log

# Verify state transitions
grep -q "Initial watching state: false" test/results/state_test.log && \
  grep -q "After start watching: true" test/results/state_test.log && \
  grep -q "After stop watching: false" test/results/state_test.log && \
  echo "✅ State management works correctly" || echo "❌ State management failed"

rm "$TEST_FILE"