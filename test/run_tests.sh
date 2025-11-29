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