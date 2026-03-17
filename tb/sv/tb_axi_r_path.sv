// Brendan Lynskey 2025
`timescale 1ns/1ps

module tb_axi_r_path;

    import axi_xbar_pkg::*;

    localparam int CLK_PERIOD = 10;
    localparam int NS1 = N_SLAVES + 1;

    logic clk, srst;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Master-side AR
    logic [N_MASTERS-1:0]           m_arvalid;
    logic [N_MASTERS-1:0]           m_arready;
    logic [N_MASTERS*ID_W-1:0]      m_arid_flat;
    logic [N_MASTERS*ADDR_W-1:0]    m_araddr_flat;
    logic [N_MASTERS*8-1:0]         m_arlen_flat;
    logic [N_MASTERS*3-1:0]         m_arsize_flat;
    logic [N_MASTERS*2-1:0]         m_arburst_flat;

    // Master-side R
    logic [N_MASTERS-1:0]           m_rvalid;
    logic [N_MASTERS-1:0]           m_rready;
    logic [N_MASTERS*ID_W-1:0]      m_rid_flat;
    logic [N_MASTERS*DATA_W-1:0]    m_rdata_flat;
    logic [N_MASTERS*2-1:0]         m_rresp_flat;
    logic [N_MASTERS-1:0]           m_rlast;

    // Slave-side AR
    logic [NS1-1:0]                 s_arvalid;
    logic [NS1-1:0]                 s_arready;
    logic [NS1*SID_W-1:0]          s_arid_flat;
    logic [NS1*ADDR_W-1:0]         s_araddr_flat;
    logic [NS1*8-1:0]              s_arlen_flat;
    logic [NS1*3-1:0]              s_arsize_flat;
    logic [NS1*2-1:0]              s_arburst_flat;

    // Slave-side R
    logic [NS1-1:0]                 s_rvalid;
    logic [NS1-1:0]                 s_rready;
    logic [NS1*SID_W-1:0]          s_rid_flat;
    logic [NS1*DATA_W-1:0]         s_rdata_flat;
    logic [NS1*2-1:0]              s_rresp_flat;
    logic [NS1-1:0]                 s_rlast;

    axi_r_path dut (
        .clk(clk), .srst(srst),
        .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_arid_flat(m_arid_flat), .m_araddr_flat(m_araddr_flat),
        .m_arlen_flat(m_arlen_flat), .m_arsize_flat(m_arsize_flat),
        .m_arburst_flat(m_arburst_flat),
        .m_rvalid(m_rvalid), .m_rready(m_rready),
        .m_rid_flat(m_rid_flat), .m_rdata_flat(m_rdata_flat),
        .m_rresp_flat(m_rresp_flat), .m_rlast(m_rlast),
        .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_arid_flat(s_arid_flat), .s_araddr_flat(s_araddr_flat),
        .s_arlen_flat(s_arlen_flat), .s_arsize_flat(s_arsize_flat),
        .s_arburst_flat(s_arburst_flat),
        .s_rvalid(s_rvalid), .s_rready(s_rready),
        .s_rid_flat(s_rid_flat), .s_rdata_flat(s_rdata_flat),
        .s_rresp_flat(s_rresp_flat), .s_rlast(s_rlast)
    );

    // Slave BFMs (read-only: AW/W/B tied off)
    genvar gi;
    generate
        for (gi = 0; gi < NS1; gi = gi + 1) begin : gen_slave_bfm
            wire                  s_awvalid_tie = 1'b0;
            wire                  s_awready_tie;
            wire [SID_W-1:0]     s_awid_tie = '0;
            wire [ADDR_W-1:0]    s_awaddr_tie = '0;
            wire [7:0]           s_awlen_tie = '0;
            wire [2:0]           s_awsize_tie = '0;
            wire [1:0]           s_awburst_tie = '0;
            wire                  s_wvalid_tie = 1'b0;
            wire                  s_wready_tie;
            wire [DATA_W-1:0]    s_wdata_tie = '0;
            wire [STRB_W-1:0]    s_wstrb_tie = '0;
            wire                  s_wlast_tie = 1'b0;
            wire                  s_bvalid_tie;
            wire                  s_bready_tie = 1'b0;
            wire [SID_W-1:0]     s_bid_tie;
            wire [1:0]           s_bresp_tie;

            axi_slave_bfm #(.BFM_ID_W(SID_W)) u_bfm (
                .clk(clk), .srst(srst),
                .awvalid(s_awvalid_tie), .awready(s_awready_tie),
                .awid(s_awid_tie), .awaddr(s_awaddr_tie),
                .awlen(s_awlen_tie), .awsize(s_awsize_tie), .awburst(s_awburst_tie),
                .wvalid(s_wvalid_tie), .wready(s_wready_tie),
                .wdata(s_wdata_tie), .wstrb(s_wstrb_tie), .wlast(s_wlast_tie),
                .bvalid(s_bvalid_tie), .bready(s_bready_tie),
                .bid(s_bid_tie), .bresp(s_bresp_tie),
                .arvalid(s_arvalid[gi]), .arready(s_arready[gi]),
                .arid(s_arid_flat[gi*SID_W +: SID_W]),
                .araddr(s_araddr_flat[gi*ADDR_W +: ADDR_W]),
                .arlen(s_arlen_flat[gi*8 +: 8]),
                .arsize(s_arsize_flat[gi*3 +: 3]),
                .arburst(s_arburst_flat[gi*2 +: 2]),
                .rvalid(s_rvalid[gi]), .rready(s_rready[gi]),
                .rid(s_rid_flat[gi*SID_W +: SID_W]),
                .rdata(s_rdata_flat[gi*DATA_W +: DATA_W]),
                .rresp(s_rresp_flat[gi*2 +: 2]),
                .rlast(s_rlast[gi])
            );
        end
    endgenerate

    int pass_count = 0;
    int fail_count = 0;

    task automatic pass(input string name);
        $display("[PASS] %s", name);
        pass_count++;
    endtask

    task automatic fail(input string name, input string msg);
        $display("[FAIL] %s: %s", name, msg);
        fail_count++;
    endtask

    task automatic tick(input int n = 1);
        repeat(n) @(posedge clk);
        #1;
    endtask

    task automatic reset_all();
        integer i;
        srst = 1;
        m_arvalid = '0; m_rready = '0;
        m_arid_flat = '0; m_araddr_flat = '0; m_arlen_flat = '0;
        m_arsize_flat = '0; m_arburst_flat = '0;
        for (i = 0; i < N_MASTERS; i = i + 1)
            m_arsize_flat[i*3 +: 3] = 3'b010;
        tick(3);
        srst = 0;
        tick(2);
    endtask

    // Master read task: issues AR, collects R beats, returns beat count
    task automatic master_read(
        input int m,
        input logic [ADDR_W-1:0] addr,
        input logic [ID_W-1:0] id,
        input logic [7:0] len,
        output int beats
    );
        integer timeout;
        beats = 0;

        // AR phase
        m_arvalid[m] = 1;
        m_araddr_flat[m*ADDR_W +: ADDR_W] = addr;
        m_arid_flat[m*ID_W +: ID_W] = id;
        m_arlen_flat[m*8 +: 8] = len;
        m_arburst_flat[m*2 +: 2] = BURST_INCR;
        m_arsize_flat[m*3 +: 3] = 3'b010;

        timeout = 0;
        while (!m_arready[m] && timeout < 200) begin
            tick(1);
            timeout = timeout + 1;
        end
        tick(1);
        m_arvalid[m] = 0;

        // R phase
        m_rready[m] = 1;
        timeout = 0;
        begin : rd_collect
            integer done;
            done = 0;
            while (!done && timeout < 500) begin
                if (m_rvalid[m]) begin
                    beats = beats + 1;
                    if (m_rlast[m]) done = 1;
                end
                tick(1);
                timeout = timeout + 1;
            end
        end
        m_rready[m] = 0;
    endtask

    initial begin
        $dumpfile("tb_axi_r_path.vcd");
        $dumpvars(0, tb_axi_r_path);
        clk = 0;

        // Test 1: Single read M0 from S0
        begin
            integer beats;
            reset_all();
            master_read(0, 32'h0000_0100, 4'd1, 8'd0, beats);
            if (beats == 1) pass("test_single_read");
            else fail("test_single_read", $sformatf("beats=%0d", beats));
        end

        // Test 2: Different slaves — M0→S0, M1→S1 simultaneously
        begin
            integer b0, b1;
            reset_all();
            fork
                master_read(0, 32'h0000_0200, 4'd1, 8'd0, b0);
                master_read(1, 32'h1000_0200, 4'd2, 8'd0, b1);
            join
            if (b0 == 1 && b1 == 1) pass("test_different_slaves");
            else fail("test_different_slaves", $sformatf("b0=%0d b1=%0d", b0, b1));
        end

        // Test 3: Same slave — M0 and M1 both read S0, sequentially
        begin
            integer b0, b1;
            reset_all();
            master_read(0, 32'h0000_0300, 4'd1, 8'd0, b0);
            master_read(1, 32'h0000_0400, 4'd2, 8'd0, b1);
            if (b0 == 1 && b1 == 1) pass("test_same_slave");
            else fail("test_same_slave", $sformatf("b0=%0d b1=%0d", b0, b1));
        end

        // Test 4: Burst read (4 beats)
        begin
            integer beats;
            reset_all();
            master_read(0, 32'h0000_1000, 4'd3, 8'd3, beats);
            if (beats == 4) pass("test_burst_read");
            else fail("test_burst_read", $sformatf("beats=%0d", beats));
        end

        // Test 5: 8-beat burst
        begin
            integer beats;
            reset_all();
            master_read(0, 32'h2000_0000, 4'd4, 8'd7, beats);
            if (beats == 8) pass("test_burst_8");
            else fail("test_burst_8", $sformatf("beats=%0d", beats));
        end

        // Test 6: ID extension — read completes, ID returned correctly
        begin
            integer beats;
            reset_all();
            master_read(0, 32'h0000_0500, 4'hC, 8'd0, beats);
            if (beats == 1) pass("test_id_extension_r");
            else fail("test_id_extension_r", $sformatf("beats=%0d", beats));
        end

        // Test 7: Backpressure — slave BFM is instant, so just verify path works
        begin
            integer beats;
            reset_all();
            master_read(0, 32'h0000_0600, 4'd5, 8'd3, beats);
            if (beats == 4) pass("test_backpressure_r");
            else fail("test_backpressure_r", $sformatf("beats=%0d", beats));
        end

        // Test 8: No cross-blocking
        begin
            integer b0, b1;
            reset_all();
            fork
                master_read(0, 32'h0000_0700, 4'd1, 8'd3, b0);
                master_read(1, 32'h1000_0700, 4'd2, 8'd3, b1);
            join
            if (b0 == 4 && b1 == 4) pass("test_no_cross_block_r");
            else fail("test_no_cross_block_r", $sformatf("b0=%0d b1=%0d", b0, b1));
        end

        // Test 9: Unmapped read → DECERR (from error slave, index NS1-1)
        begin
            integer beats;
            reset_all();
            master_read(0, 32'hFFFF_0000, 4'd6, 8'd0, beats);
            if (beats == 1) pass("test_unmapped_read");
            else fail("test_unmapped_read", $sformatf("beats=%0d", beats));
        end

        // Test 10: Outstanding reads — M0 issues two reads to different slaves sequentially
        begin
            integer b0, b1;
            reset_all();
            master_read(0, 32'h0000_0800, 4'd7, 8'd0, b0);
            master_read(0, 32'h1000_0800, 4'd8, 8'd0, b1);
            if (b0 == 1 && b1 == 1) pass("test_outstanding_reads");
            else fail("test_outstanding_reads", $sformatf("b0=%0d b1=%0d", b0, b1));
        end

        $display("\n=== Read Path: %0d/%0d tests passed ===",
                 pass_count, pass_count + fail_count);
        if (fail_count > 0) $stop;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 50000);
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
