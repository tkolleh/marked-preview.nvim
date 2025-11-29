#!/bin/bash
set -e

TEST_FILE="test/fixtures/timer_test.md"
cat > "$TEST_FILE" << 'CONTENT'
# Timer Test
CONTENT

nvim --headless "$TEST_FILE" \
  -c 'lua require("marked-preview").setup()' \
  -c 'lua require("marked-preview").start_watching()' \
  -c 'for i=1,10 do \
        execute "normal! iabc\<Esc>" \
      end' \
  -c 'sleep 1000m' \
  -c 'qa!' 2>&1 | tee test/results/timer_test.log

if grep -q "handle is already closing" test/results/timer_test.log; then
    echo "❌ Timer error still present"
    exit 1
else
    echo "✅ Timer error fixed"
fi

rm "$TEST_FILE"
