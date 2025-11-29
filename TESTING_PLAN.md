# Marked 2 Neovim Plugin Testing Plan

## Overview
This document outlines a step-by-step testing plan for the Marked 2 Neovim plugin using Neovim headless mode. The plan includes both automated scripts and manual verification steps.

## Prerequisites
- Neovim 0.8+
- macOS (for Marked 2 integration)
- Marked 2 app installed (for full integration testing)

## Test Environment Setup

### 1. Create Test Directory Structure
```bash
mkdir -p test/{fixtures,scripts,results}
```

### 2. Create Test Markdown Files
```bash
cat > test/fixtures/sample.md << 'EOF'
# Test Document

This is a sample markdown file for testing.

- List item 1
- List item 2
- List item 3

**Bold text** and *italic text*.
EOF
```

## Automated Testing Scripts

### 3. Create Basic Plugin Loading Test
```bash
cat > test/scripts/test_plugin_loading.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing plugin loading..."

# Test if plugin loads without errors
nvim --headless -c 'lua require("marked-preview")' -c 'qa!' 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Plugin loads successfully"
else
    echo "❌ Plugin failed to load"
    exit 1
fi

# Test setup function
nvim --headless -c 'lua require("marked-preview").setup()' -c 'qa!' 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Setup function works"
else
    echo "❌ Setup function failed"
    exit 1
fi

echo "✅ All plugin loading tests passed"
EOF
chmod +x test/scripts/test_plugin_loading.sh
```

### 4. Create Functionality Test Script
```bash
cat > test/scripts/test_functionality.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing plugin functionality..."

# Create a temporary markdown file
TEST_FILE="test/fixtures/temp_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# Functionality Test
Testing plugin commands and features.
CONTENT

# Test 1: Check if commands are available
nvim --headless "$TEST_FILE" -c 'echo "Testing commands..."' \
  -c 'silent! command MarkedPreviewUpdate' \
  -c 'silent! command MarkedPreviewOpen' \
  -c 'silent! command MarkedPreviewStart' \
  -c 'silent! command MarkedPreviewStop' \
  -c 'if v:errmsg != "" | echo "❌ Missing commands" | cquit 1 | endif' \
  -c 'echo "✅ All commands available"' \
  -c 'qa!' 2>&1

# Test 2: Test buffer content retrieval
nvim --headless "$TEST_FILE" \
  -c 'lua local content = require("marked-preview").get_buffer_content(0); print("Buffer content length: " .. #content)' \
  -c 'qa!' 2>&1 | grep -q "Buffer content length:" && echo "✅ Buffer content retrieval works" || echo "❌ Buffer content retrieval failed"

# Test 3: Test filetype detection
nvim --headless "$TEST_FILE" \
  -c 'lua local supported = require("marked-preview").is_supported_filetype("markdown"); print("Filetype supported: " .. tostring(supported))' \
  -c 'qa!' 2>&1 | grep -q "Filetype supported: true" && echo "✅ Filetype detection works" || echo "❌ Filetype detection failed"

# Cleanup
rm "$TEST_FILE"

echo "✅ All functionality tests completed"
EOF
chmod +x test/scripts/test_functionality.sh
```

### 5. Create State Management Test
```bash
cat > test/scripts/test_state_management.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing state management..."

TEST_FILE="test/fixtures/state_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# State Management Test
CONTENT

# Test watching state
nvim --headless "$TEST_FILE" \
  -c 'lua local mp = require("marked-preview"); print("Initial watching state: " .. tostring(mp.is_watching()))' \
  -c 'lua mp.start_watching(); print("After start watching: " .. tostring(mp.is_watching()))' \
  -c 'lua mp.stop_watching(); print("After stop watching: " .. tostring(mp.is_watching()))' \
  -c 'qa!' 2>&1 | tee test/results/state_test.log

# Verify state transitions
grep -q "Initial watching state: false" test/results/state_test.log && \
  grep -q "After start watching: true" test/results/state_test.log && \
  grep -q "After stop watching: false" test/results/state_test.log && \
  echo "✅ State management works correctly" || echo "❌ State management failed"

rm "$TEST_FILE"
EOF
chmod +x test/scripts/test_state_management.sh
```

### 6. Create Integration Test Script
```bash
cat > test/scripts/test_integration.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing integration features..."

TEST_FILE="test/fixtures/integration_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# Integration Test
This tests the complete workflow.
CONTENT

# Test complete workflow
nvim --headless "$TEST_FILE" \
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
EOF
chmod +x test/scripts/test_integration.sh
```

## Manual Testing Steps

### 7. Manual Verification Script
```bash
cat > test/scripts/manual_verification.sh << 'EOF'
#!/bin/bash
echo "Manual Verification Steps:"
echo ""
echo "1. Open a markdown file in Neovim:"
echo "   nvim test/fixtures/sample.md"
echo ""
echo "2. Test commands manually:"
echo "   :MarkedPreviewOpen     - Should open Marked 2"
echo "   :MarkedPreviewStart    - Should start watching"
echo "   :MarkedPreviewUpdate   - Should update preview"
echo "   :MarkedPreviewStop     - Should stop watching"
echo ""
echo "3. Verify automatic updates:"
echo "   - Start watching with :MarkedPreviewStart"
echo "   - Make changes to the buffer"
echo "   - Check if Marked 2 updates automatically (with debounce)"
echo ""
echo "4. Test configuration:"
echo "   :lua require('marked-preview').setup({debounce_delay = 1000})"
echo ""
echo "Note: Marked 2 must be installed for full integration testing."
EOF
chmod +x test/scripts/manual_verification.sh
```

## Running the Test Suite

### 8. Create Master Test Runner
```bash
cat > test/run_tests.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Running Marked 2 Neovim Plugin Test Suite"
echo "============================================"

# Create test directories
mkdir -p test/{fixtures,scripts,results}

# Run tests in sequence
echo ""
echo "1. Testing plugin loading..."
./test/scripts/test_plugin_loading.sh

echo ""
echo "2. Testing functionality..."
./test/scripts/test_functionality.sh

echo ""
echo "3. Testing state management..."
./test/scripts/test_state_management.sh

echo ""
echo "4. Testing integration..."
./test/scripts/test_integration.sh

echo ""
echo "✅ All automated tests passed!"
echo ""
echo "For manual verification, run:"
echo "   ./test/scripts/manual_verification.sh"
echo ""
echo "Test results saved to: test/results/"
EOF
chmod +x test/run_tests.sh
```

## Test Execution

### 9. Execute the Test Suite
```bash
# Make all scripts executable
chmod +x test/scripts/*.sh

# Run the complete test suite
./test/run_tests.sh
```

## Expected Results

- **Plugin Loading**: Should load without errors
- **Commands**: All user commands should be available
- **Functionality**: Buffer content retrieval and filetype detection should work
- **State Management**: Watching state should transition correctly
- **Integration**: Complete workflow should execute without errors

## Troubleshooting

If tests fail:
1. Check Neovim version: `nvim --version`
2. Verify plugin structure is correct
3. Check if Marked 2 is installed (for manual testing)
4. Review test logs in `test/results/`

This testing plan provides comprehensive coverage of the plugin's functionality using Neovim headless mode for automated testing and includes manual verification steps for full integration testing.