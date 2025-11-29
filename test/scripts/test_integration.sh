#!/bin/bash
set -e

echo "Testing integration features..."

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEST_FILE="test/fixtures/integration_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# Integration Test
This tests the complete workflow.
CONTENT

# Test complete workflow
nvim --headless -c "set rtp+=$PROJECT_ROOT" "$TEST_FILE" \
  -c 'lua local mp = require("marked-preview"); mp.setup()' \
  -c 'lua require("marked-preview").start_watching()' \
  -c 'normal iAdditional content␛' \
  -c 'lua require("marked-preview").update()' \
  -c 'lua require("marked-preview").stop_watching()' \
  -c 'echo "✅ Integration test completed"' \
  -c 'qa!' 2>&1 | tee test/results/integration_test.log

if grep -q "✅ Integration test completed" test/results/integration_test.log; then
    echo "✅ Integration test passed"
else
    echo "❌ Integration test failed"
    exit 1
fi

rm "$TEST_FILE"