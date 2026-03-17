// Brendan Lynskey 2025
`timescale 1ns/1ps

module tb_axi_addr_decoder;

    import axi_xbar_pkg::*;

    logic [ADDR_W-1:0]             addr;
    logic [$clog2(N_SLAVES+1)-1:0] slave_idx;
    logic                          addr_valid;

    axi_addr_decoder dut (
        .addr       (addr),
        .slave_idx  (slave_idx),
        .addr_valid (addr_valid)
    );

    int pass_count = 0;
    int fail_count = 0;

    task check(
        input string name,
        input logic [$clog2(N_SLAVES+1)-1:0] exp_idx,
        input logic exp_valid
    );
        #1;
        if (slave_idx === exp_idx && addr_valid === exp_valid) begin
            $display("[PASS] %s", name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: addr=0x%08h got idx=%0d valid=%0b, expected idx=%0d valid=%0b",
                     name, addr, slave_idx, addr_valid, exp_idx, exp_valid);
            fail_count = fail_count + 1;
        end
    endtask

    initial begin
        $dumpfile("tb_axi_addr_decoder.vcd");
        $dumpvars(0, tb_axi_addr_decoder);

        // Test 1: Slave 0 base
        addr = 32'h0000_0000;
        check("test_slave0_base", 3'd0, 1'b1);

        // Test 2: Slave 0 end
        addr = 32'h0FFF_FFFF;
        check("test_slave0_end", 3'd0, 1'b1);

        // Test 3: Slave 1 base
        addr = 32'h1000_0000;
        check("test_slave1_base", 3'd1, 1'b1);

        // Test 4: Slave 2 mid
        addr = 32'h2800_0000;
        check("test_slave2_mid", 3'd2, 1'b1);

        // Test 5: Slave 3 base
        addr = 32'h4000_0000;
        check("test_slave3_base", 3'd3, 1'b1);

        // Test 6: Slave 3 end
        addr = 32'h7FFF_FFFF;
        check("test_slave3_end", 3'd3, 1'b1);

        // Test 7: Unmapped below — address 0x0000_0000 is slave 0, so use gap
        // Actually slave 0 starts at 0, so test gap between slave 1 and 2
        addr = 32'h1FFF_FFFF;
        // slave 1 mask is 0x0FFF_FFFF: base 0x1000_0000, top 0x1FFF_FFFF — this is slave 1
        // Let's use the gap: slave 2 ends at 0x3FFF_FFFF, slave 3 starts at 0x4000_0000
        // There is no gap there. Actually check: slave 0: 0x0-0x0FFF_FFFF, slave 1: 0x1000_0000-0x1FFF_FFFF,
        // slave 2: 0x2000_0000-0x3FFF_FFFF, slave 3: 0x4000_0000-0x7FFF_FFFF
        // Gap: 0x8000_0000 - 0xFFFF_FFFF is unmapped
        addr = 32'h8000_0000;
        check("test_unmapped_below", 3'd4, 1'b0);

        // Test 8: Unmapped gap — there's no gap in the default map, use high address
        addr = 32'hA000_0000;
        check("test_unmapped_gap", 3'd4, 1'b0);

        // Test 9: Unmapped above
        addr = 32'hFFFF_FFFF;
        check("test_unmapped_above", 3'd4, 1'b0);

        // Test 10: Boundary — slave 0 end / slave 1 start boundary
        addr = 32'h1000_0000;
        check("test_boundary", 3'd1, 1'b1);

        $display("\n=== Address Decoder: %0d/%0d tests passed ===",
                 pass_count, pass_count + fail_count);

        if (fail_count > 0) $stop;
        $finish;
    end

endmodule
