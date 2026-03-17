#!/bin/bash
# Brendan Lynskey 2025
# Compile and run all SystemVerilog testbenches

set -e
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
RTL_DIR=rtl
TB_DIR=tb/sv

echo "=== SystemVerilog Tests ==="

# Address Decoder
echo "--- axi_addr_decoder ---"
iverilog -g2012 -o sim_addr_dec.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_addr_decoder.sv $TB_DIR/tb_axi_addr_decoder.sv
OUTPUT=$(vvp sim_addr_dec.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Arbiter
echo "--- axi_arbiter ---"
iverilog -g2012 -o sim_arbiter.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_arbiter.sv $TB_DIR/tb_axi_arbiter.sv
OUTPUT=$(vvp sim_arbiter.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Error Slave
echo "--- axi_err_slave ---"
iverilog -g2012 -o sim_err.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_err_slave.sv $TB_DIR/tb_axi_err_slave.sv
OUTPUT=$(vvp sim_err.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Write Path
echo "--- axi_w_path ---"
iverilog -g2012 -o sim_w_path.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_addr_decoder.sv $RTL_DIR/axi_arbiter.sv $RTL_DIR/axi_w_path.sv $TB_DIR/axi_slave_bfm.sv $TB_DIR/tb_axi_w_path.sv
OUTPUT=$(vvp sim_w_path.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Read Path
echo "--- axi_r_path ---"
iverilog -g2012 -o sim_r_path.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_addr_decoder.sv $RTL_DIR/axi_arbiter.sv $RTL_DIR/axi_r_path.sv $TB_DIR/axi_slave_bfm.sv $TB_DIR/tb_axi_r_path.sv
OUTPUT=$(vvp sim_r_path.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Crossbar Top
echo "--- axi_xbar_top ---"
iverilog -g2012 -o sim_xbar.vvp $RTL_DIR/axi_xbar_pkg.sv $RTL_DIR/axi_addr_decoder.sv $RTL_DIR/axi_arbiter.sv $RTL_DIR/axi_err_slave.sv $RTL_DIR/axi_w_path.sv $RTL_DIR/axi_r_path.sv $RTL_DIR/axi_xbar_top.sv $TB_DIR/axi_slave_bfm.sv $TB_DIR/tb_axi_xbar_top.sv
OUTPUT=$(timeout 300 vvp sim_xbar.vvp 2>&1)
echo "$OUTPUT"
P=$(echo "$OUTPUT" | grep -c "\[PASS\]" || true)
F=$(echo "$OUTPUT" | grep -c "\[FAIL\]" || true)
PASS=$((PASS + P))
FAIL=$((FAIL + F))

# Cleanup
rm -f sim_*.vvp *.vcd

echo ""
echo "=== SV Test Summary ==="
echo "Passed: $PASS  Failed: $FAIL"
[ $FAIL -eq 0 ] && echo "ALL SV TESTS PASSED" || echo "SOME SV TESTS FAILED"
exit $FAIL
