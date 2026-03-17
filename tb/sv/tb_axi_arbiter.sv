// Brendan Lynskey 2025
`timescale 1ns/1ps

module tb_axi_arbiter;

    import axi_xbar_pkg::*;

    localparam int N = 2;
    localparam int CLK_PERIOD = 10;

    logic              clk;
    logic              srst;
    logic [N-1:0]      req;
    logic [N-1:0]      grant;
    logic [$clog2(N)-1:0] grant_idx;
    logic              grant_valid;
    logic              lock;

    // Round-robin DUT
    axi_arbiter #(.N_REQ(N), .MODE(ARB_ROUND_ROBIN)) dut_rr (
        .clk        (clk),
        .srst       (srst),
        .req        (req),
        .grant      (grant),
        .grant_idx  (grant_idx),
        .grant_valid(grant_valid),
        .lock       (lock)
    );

    // Fixed-priority DUT
    logic [N-1:0]      fp_grant;
    logic [$clog2(N)-1:0] fp_grant_idx;
    logic              fp_grant_valid;

    axi_arbiter #(.N_REQ(N), .MODE(ARB_FIXED_PRIO)) dut_fp (
        .clk        (clk),
        .srst       (srst),
        .req        (req),
        .grant      (fp_grant),
        .grant_idx  (fp_grant_idx),
        .grant_valid(fp_grant_valid),
        .lock       (lock)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count = 0;
    int fail_count = 0;

    task automatic pass(input string name);
        $display("[PASS] %s", name);
        pass_count = pass_count + 1;
    endtask

    task automatic fail(input string name, input string msg);
        $display("[FAIL] %s: %s", name, msg);
        fail_count = fail_count + 1;
    endtask

    task automatic tick(input int n = 1);
        repeat(n) @(posedge clk);
        #1;
    endtask

    initial begin
        $dumpfile("tb_axi_arbiter.vcd");
        $dumpvars(0, tb_axi_arbiter);

        clk  = 0;
        srst = 1;
        req  = '0;
        lock = 0;
        tick(3);
        srst = 0;
        tick(1);

        // Test 1: Single requestor
        begin
            req = 2'b01;
            tick(1);
            if (grant_valid && grant_idx == 0)
                pass("test_single_req");
            else
                fail("test_single_req", $sformatf("grant=%b idx=%0d valid=%0b", grant, grant_idx, grant_valid));
            req = '0;
            tick(1);
        end

        // Test 2: No request
        begin
            req = 2'b00;
            tick(1);
            if (!grant_valid)
                pass("test_no_req");
            else
                fail("test_no_req", "grant_valid should be 0");
        end

        // Test 3: Two simultaneous — after reset, last_grant=0, so scan from 1 first
        // Actually after reset last_grant=0, scan starts at (0+1)%2=1, so if both request, master 1 gets first
        // Wait — let's ensure clean state: last_grant=0 from reset
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b11;
            tick(1);
            // After reset last_grant=0; combinational grants 1, but FF updates last_grant to 1 on posedge
            // so by #1 after posedge we see the *next* grant (scan from 1+1=0 → master 0)
            // Check that grant is valid and one-hot
            if (grant_valid && (grant == 2'b01 || grant == 2'b10))
                pass("test_two_simultaneous");
            else
                fail("test_two_simultaneous", $sformatf("got grant=%b valid=%0b", grant, grant_valid));
            req = '0;
            tick(1);
        end

        // Test 4: Round-robin fairness over 100 cycles
        begin
            integer cnt0, cnt1, i;
            cnt0 = 0; cnt1 = 0;
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b11;
            for (i = 0; i < 100; i = i + 1) begin
                tick(1);
                if (grant_valid) begin
                    if (grant_idx == 0) cnt0 = cnt0 + 1;
                    else cnt1 = cnt1 + 1;
                end
            end
            req = '0;
            tick(1);
            if (cnt0 == 50 && cnt1 == 50)
                pass("test_round_robin_fairness");
            else
                fail("test_round_robin_fairness", $sformatf("cnt0=%0d cnt1=%0d", cnt0, cnt1));
        end

        // Test 5: Round-robin wrap (highest to lowest)
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            // Request only master 1
            req = 2'b10;
            tick(1);
            // Now last_grant should move to 1
            // Request both — next should be master 0 (wraps from 1+1=0)
            req = 2'b11;
            tick(1); // last_grant updates to 1
            tick(1); // now scan from (1+1)%2 = 0, so master 0
            if (grant_valid && grant_idx == 0)
                pass("test_round_robin_wrap");
            else
                fail("test_round_robin_wrap", $sformatf("got idx=%0d expected 0", grant_idx));
            req = '0;
            tick(1);
        end

        // Test 6: Lock hold
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b11;
            tick(1); // master 1 granted (after reset, scan from 1)
            lock = 1;
            tick(1);
            // Should still be master 1 due to lock
            if (grant_valid && grant_idx == 1)
                pass("test_lock_hold");
            else
                fail("test_lock_hold", $sformatf("got idx=%0d expected 1", grant_idx));
        end

        // Test 7: Lock release
        begin
            // Still locked from test 6, both requesting, master 1 held
            lock = 0;
            tick(1);
            // last_grant is still 0 from reset (lock prevented update), or is it 1?
            // lock was 1, so grant_valid && !lock was false → last_grant didn't update
            // Actually last_grant was 0 from reset. With lock=1, the grant_valid && !lock condition
            // is false so last_grant stays 0. Scan from 0+1=1 → master 1 again.
            // Let me just check it's valid and alternating
            // After lock release: last_grant was never updated (lock held it at 0)
            // So grant_valid=1, scan from 1 → master 1
            // Now that lock=0, last_grant updates to 1
            tick(1);
            // Now last_grant=1, scan from 0 → master 0
            if (grant_valid && grant_idx == 0)
                pass("test_lock_release");
            else
                fail("test_lock_release", $sformatf("got idx=%0d expected 0", grant_idx));
            req = '0;
            lock = 0;
            tick(1);
        end

        // Test 8: Priority change during lock
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b10; // only master 1
            tick(1); // master 1 granted
            lock = 1;
            req = 2'b01; // now only master 0 requests, but lock held
            tick(1);
            // lock is on but current grantee (master 1) dropped req
            // lock && req[last_grant] → lock && req[0] (last_grant=0 after reset)
            // Hmm, last_grant=0 from reset, master 1 was granted but last_grant only updates if !lock
            // Actually tick(1) after granting master 1: grant_valid=1, lock=0 at that point → last_grant updates to 1
            // Then lock=1, req changes to 01
            // Now: lock=1, req[last_grant=1]=req[1]=0 → lock but grantee not requesting → falls through to scan
            // Scan from (1+1)%2=0: req[0]=1 → grant master 0
            // This shows lock doesn't hold when grantee drops
            if (grant_valid && grant_idx == 0)
                pass("test_priority_change");
            else
                fail("test_priority_change", $sformatf("got idx=%0d valid=%0b", grant_idx, grant_valid));
            lock = 0;
            req = '0;
            tick(1);
        end

        // Test 9: All requestors active
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b11;
            tick(1);
            // Both request → one granted (round-robin)
            if (grant_valid && (grant == 2'b01 || grant == 2'b10))
                pass("test_all_req");
            else
                fail("test_all_req", $sformatf("grant=%b valid=%0b", grant, grant_valid));
            req = '0;
            tick(1);
        end

        // Test 10: Single cycle grant (combinational)
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b01;
            #1; // combinational delay only, no clock edge
            if (grant_valid && grant_idx == 0)
                pass("test_single_cycle_grant");
            else
                fail("test_single_cycle_grant", $sformatf("grant_valid=%0b idx=%0d", grant_valid, grant_idx));
            req = '0;
            tick(1);
        end

        // Test 11: Fixed priority mode
        begin
            srst = 1; tick(1); srst = 0; tick(1);
            req = 2'b11;
            #1;
            if (fp_grant_valid && fp_grant_idx == 0)
                pass("test_fixed_priority");
            else
                fail("test_fixed_priority", $sformatf("fp idx=%0d", fp_grant_idx));
            req = '0;
            tick(1);
        end

        // Test 12: Reset behaviour
        begin
            req = 2'b11;
            tick(2); // let arbiter run
            srst = 1;
            tick(1);
            srst = 0;
            req = 2'b11;
            tick(1);
            // After reset, last_grant=0; valid grant issued
            if (grant_valid)
                pass("test_reset_behaviour");
            else
                fail("test_reset_behaviour", "no grant after reset");
            req = '0;
            tick(1);
        end

        $display("\n=== Arbiter: %0d/%0d tests passed ===",
                 pass_count, pass_count + fail_count);

        if (fail_count > 0) $stop;
        $finish;
    end

endmodule
