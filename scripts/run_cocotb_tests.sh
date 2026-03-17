#!/bin/bash
# Brendan Lynskey 2025
# Run all CocoTB tests

set -e
cd "$(dirname "$0")/.."

FAIL=0

echo "=== CocoTB Tests ==="
for dir in tb/cocotb/test_*/; do
    name=$(basename "$dir")
    echo "--- $name ---"
    (cd "$dir" && rm -rf sim_build results.xml __pycache__ && make SIM=icarus 2>&1 | tail -5) || FAIL=$((FAIL+1))
done

echo ""
echo "=== CocoTB Summary ==="
[ $FAIL -eq 0 ] && echo "ALL COCOTB TESTS PASSED" || echo "$FAIL test suite(s) FAILED"
exit $FAIL
