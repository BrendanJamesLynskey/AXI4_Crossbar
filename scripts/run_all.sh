#!/bin/bash
# Brendan Lynskey 2025
# Run all SV and CocoTB tests, print summary

cd "$(dirname "$0")/.."

SV_FAIL=0
COCOTB_FAIL=0

echo "========================================"
echo " AXI4 Crossbar — Full Test Suite"
echo "========================================"
echo ""

echo "=== Running SystemVerilog Tests ==="
bash scripts/run_sv_tests.sh || SV_FAIL=1
echo ""

echo "=== Running CocoTB Tests ==="
bash scripts/run_cocotb_tests.sh || COCOTB_FAIL=1
echo ""

echo "========================================"
echo " Final Summary"
echo "========================================"
if [ $SV_FAIL -eq 0 ] && [ $COCOTB_FAIL -eq 0 ]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    [ $SV_FAIL -ne 0 ] && echo "SV tests: FAILED"
    [ $COCOTB_FAIL -ne 0 ] && echo "CocoTB tests: FAILED"
    exit 1
fi
