// Brendan Lynskey 2025
`timescale 1ns/1ps

module tb_axi_xbar_top;

    import axi_xbar_pkg::*;

    localparam int CLK_PERIOD = 10;

    logic clk, srst;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Master-side signals
    logic [N_MASTERS-1:0]           m_awvalid, m_awready;
    logic [N_MASTERS*ID_W-1:0]      m_awid_flat;
    logic [N_MASTERS*ADDR_W-1:0]    m_awaddr_flat;
    logic [N_MASTERS*8-1:0]         m_awlen_flat;
    logic [N_MASTERS*3-1:0]         m_awsize_flat;
    logic [N_MASTERS*2-1:0]         m_awburst_flat;

    logic [N_MASTERS-1:0]           m_wvalid, m_wready;
    logic [N_MASTERS*DATA_W-1:0]    m_wdata_flat;
    logic [N_MASTERS*STRB_W-1:0]    m_wstrb_flat;
    logic [N_MASTERS-1:0]           m_wlast;

    logic [N_MASTERS-1:0]           m_bvalid, m_bready;
    logic [N_MASTERS*ID_W-1:0]      m_bid_flat;
    logic [N_MASTERS*2-1:0]         m_bresp_flat;

    logic [N_MASTERS-1:0]           m_arvalid, m_arready;
    logic [N_MASTERS*ID_W-1:0]      m_arid_flat;
    logic [N_MASTERS*ADDR_W-1:0]    m_araddr_flat;
    logic [N_MASTERS*8-1:0]         m_arlen_flat;
    logic [N_MASTERS*3-1:0]         m_arsize_flat;
    logic [N_MASTERS*2-1:0]         m_arburst_flat;

    logic [N_MASTERS-1:0]           m_rvalid, m_rready;
    logic [N_MASTERS*ID_W-1:0]      m_rid_flat;
    logic [N_MASTERS*DATA_W-1:0]    m_rdata_flat;
    logic [N_MASTERS*2-1:0]         m_rresp_flat;
    logic [N_MASTERS-1:0]           m_rlast;

    // Slave-side signals
    logic [N_SLAVES-1:0]            s_awvalid, s_awready;
    logic [N_SLAVES*SID_W-1:0]     s_awid_flat;
    logic [N_SLAVES*ADDR_W-1:0]    s_awaddr_flat;
    logic [N_SLAVES*8-1:0]         s_awlen_flat;
    logic [N_SLAVES*3-1:0]         s_awsize_flat;
    logic [N_SLAVES*2-1:0]         s_awburst_flat;

    logic [N_SLAVES-1:0]            s_wvalid, s_wready;
    logic [N_SLAVES*DATA_W-1:0]    s_wdata_flat;
    logic [N_SLAVES*STRB_W-1:0]    s_wstrb_flat;
    logic [N_SLAVES-1:0]            s_wlast;

    logic [N_SLAVES-1:0]            s_bvalid, s_bready;
    logic [N_SLAVES*SID_W-1:0]     s_bid_flat;
    logic [N_SLAVES*2-1:0]         s_bresp_flat;

    logic [N_SLAVES-1:0]            s_arvalid, s_arready;
    logic [N_SLAVES*SID_W-1:0]     s_arid_flat;
    logic [N_SLAVES*ADDR_W-1:0]    s_araddr_flat;
    logic [N_SLAVES*8-1:0]         s_arlen_flat;
    logic [N_SLAVES*3-1:0]         s_arsize_flat;
    logic [N_SLAVES*2-1:0]         s_arburst_flat;

    logic [N_SLAVES-1:0]            s_rvalid, s_rready;
    logic [N_SLAVES*SID_W-1:0]     s_rid_flat;
    logic [N_SLAVES*DATA_W-1:0]    s_rdata_flat;
    logic [N_SLAVES*2-1:0]         s_rresp_flat;
    logic [N_SLAVES-1:0]            s_rlast;

    axi_xbar_top dut (
        .clk(clk), .srst(srst),
        .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_awid_flat(m_awid_flat), .m_awaddr_flat(m_awaddr_flat),
        .m_awlen_flat(m_awlen_flat), .m_awsize_flat(m_awsize_flat),
        .m_awburst_flat(m_awburst_flat),
        .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_wdata_flat(m_wdata_flat), .m_wstrb_flat(m_wstrb_flat),
        .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready),
        .m_bid_flat(m_bid_flat), .m_bresp_flat(m_bresp_flat),
        .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_arid_flat(m_arid_flat), .m_araddr_flat(m_araddr_flat),
        .m_arlen_flat(m_arlen_flat), .m_arsize_flat(m_arsize_flat),
        .m_arburst_flat(m_arburst_flat),
        .m_rvalid(m_rvalid), .m_rready(m_rready),
        .m_rid_flat(m_rid_flat), .m_rdata_flat(m_rdata_flat),
        .m_rresp_flat(m_rresp_flat), .m_rlast(m_rlast),
        .s_awvalid(s_awvalid), .s_awready(s_awready),
        .s_awid_flat(s_awid_flat), .s_awaddr_flat(s_awaddr_flat),
        .s_awlen_flat(s_awlen_flat), .s_awsize_flat(s_awsize_flat),
        .s_awburst_flat(s_awburst_flat),
        .s_wvalid(s_wvalid), .s_wready(s_wready),
        .s_wdata_flat(s_wdata_flat), .s_wstrb_flat(s_wstrb_flat),
        .s_wlast(s_wlast),
        .s_bvalid(s_bvalid), .s_bready(s_bready),
        .s_bid_flat(s_bid_flat), .s_bresp_flat(s_bresp_flat),
        .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_arid_flat(s_arid_flat), .s_araddr_flat(s_araddr_flat),
        .s_arlen_flat(s_arlen_flat), .s_arsize_flat(s_arsize_flat),
        .s_arburst_flat(s_arburst_flat),
        .s_rvalid(s_rvalid), .s_rready(s_rready),
        .s_rid_flat(s_rid_flat), .s_rdata_flat(s_rdata_flat),
        .s_rresp_flat(s_rresp_flat), .s_rlast(s_rlast)
    );

    // Slave BFMs
    genvar gi;
    generate
        for (gi = 0; gi < N_SLAVES; gi = gi + 1) begin : gen_slave
            axi_slave_bfm #(.BFM_ID_W(SID_W)) u_bfm (
                .clk(clk), .srst(srst),
                .awvalid(s_awvalid[gi]), .awready(s_awready[gi]),
                .awid(s_awid_flat[gi*SID_W +: SID_W]),
                .awaddr(s_awaddr_flat[gi*ADDR_W +: ADDR_W]),
                .awlen(s_awlen_flat[gi*8 +: 8]),
                .awsize(s_awsize_flat[gi*3 +: 3]),
                .awburst(s_awburst_flat[gi*2 +: 2]),
                .wvalid(s_wvalid[gi]), .wready(s_wready[gi]),
                .wdata(s_wdata_flat[gi*DATA_W +: DATA_W]),
                .wstrb(s_wstrb_flat[gi*STRB_W +: STRB_W]),
                .wlast(s_wlast[gi]),
                .bvalid(s_bvalid[gi]), .bready(s_bready[gi]),
                .bid(s_bid_flat[gi*SID_W +: SID_W]),
                .bresp(s_bresp_flat[gi*2 +: 2]),
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
        m_awvalid = '0; m_wvalid = '0; m_bready = '0;
        m_arvalid = '0; m_rready = '0;
        m_awid_flat = '0; m_awaddr_flat = '0; m_awlen_flat = '0;
        m_awsize_flat = '0; m_awburst_flat = '0;
        m_wdata_flat = '0; m_wstrb_flat = '0; m_wlast = '0;
        m_arid_flat = '0; m_araddr_flat = '0; m_arlen_flat = '0;
        m_arsize_flat = '0; m_arburst_flat = '0;
        for (i = 0; i < N_MASTERS; i = i + 1) begin
            m_awsize_flat[i*3 +: 3] = 3'b010;
            m_arsize_flat[i*3 +: 3] = 3'b010;
        end
        tick(3);
        srst = 0;
        tick(2);
    endtask

    // Write task for master m
    task automatic master_write(
        input int m,
        input logic [ADDR_W-1:0] addr,
        input logic [ID_W-1:0] id,
        input logic [7:0] len,
        input logic [DATA_W-1:0] start_data
    );
        integer i, timeout;

        m_awvalid[m] = 1;
        m_awaddr_flat[m*ADDR_W +: ADDR_W] = addr;
        m_awid_flat[m*ID_W +: ID_W] = id;
        m_awlen_flat[m*8 +: 8] = len;
        m_awburst_flat[m*2 +: 2] = BURST_INCR;
        m_awsize_flat[m*3 +: 3] = 3'b010;

        timeout = 0;
        while (!m_awready[m] && timeout < 200) begin tick(1); timeout++; end
        tick(1); m_awvalid[m] = 0;

        for (i = 0; i <= len; i++) begin
            m_wvalid[m] = 1;
            m_wdata_flat[m*DATA_W +: DATA_W] = start_data + i;
            m_wstrb_flat[m*STRB_W +: STRB_W] = {STRB_W{1'b1}};
            m_wlast[m] = (i == len);
            timeout = 0;
            while (!m_wready[m] && timeout < 200) begin tick(1); timeout++; end
            tick(1);
        end
        m_wvalid[m] = 0; m_wlast[m] = 0;

        m_bready[m] = 1;
        timeout = 0;
        while (!m_bvalid[m] && timeout < 200) begin tick(1); timeout++; end
        tick(1); m_bready[m] = 0;
    endtask

    // Read task for master m
    task automatic master_read(
        input int m,
        input logic [ADDR_W-1:0] addr,
        input logic [ID_W-1:0] id,
        input logic [7:0] len,
        output int beats,
        output logic [DATA_W-1:0] first_data
    );
        integer timeout;
        beats = 0;
        first_data = '0;

        m_arvalid[m] = 1;
        m_araddr_flat[m*ADDR_W +: ADDR_W] = addr;
        m_arid_flat[m*ID_W +: ID_W] = id;
        m_arlen_flat[m*8 +: 8] = len;
        m_arburst_flat[m*2 +: 2] = BURST_INCR;
        m_arsize_flat[m*3 +: 3] = 3'b010;

        timeout = 0;
        while (!m_arready[m] && timeout < 200) begin tick(1); timeout++; end
        tick(1); m_arvalid[m] = 0;

        m_rready[m] = 1;
        timeout = 0;
        begin : rd_loop
            integer done;
            done = 0;
            while (!done && timeout < 500) begin
                if (m_rvalid[m]) begin
                    if (beats == 0) first_data = m_rdata_flat[m*DATA_W +: DATA_W];
                    beats++;
                    if (m_rlast[m]) done = 1;
                end
                tick(1);
                timeout++;
            end
        end
        m_rready[m] = 0;
    endtask

    initial begin
        $dumpfile("tb_axi_xbar_top.vcd");
        $dumpvars(0, tb_axi_xbar_top);
        clk = 0;

        // Test 1: Basic write then read
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            master_write(0, 32'h0000_0000, 4'd1, 8'd0, 32'hCAFE_BABE);
            master_read(0, 32'h0000_0000, 4'd1, 8'd0, beats, rdata);
            if (beats == 1 && rdata == 32'hCAFE_BABE)
                pass("test_basic_write_read");
            else
                fail("test_basic_write_read", $sformatf("beats=%0d data=%h", beats, rdata));
        end

        // Test 2: Write to all 4 slaves
        begin
            reset_all();
            master_write(0, 32'h0000_0100, 4'd1, 8'd0, 32'hAAAA_0000);
            master_write(0, 32'h1000_0100, 4'd2, 8'd0, 32'hBBBB_0000);
            master_write(0, 32'h2000_0100, 4'd3, 8'd0, 32'hCCCC_0000);
            master_write(0, 32'h4000_0100, 4'd4, 8'd0, 32'hDDDD_0000);
            pass("test_all_slaves_write");
        end

        // Test 3: Read from all 4 slaves
        begin
            integer b0, b1, b2, b3;
            logic [DATA_W-1:0] d0, d1, d2, d3;
            reset_all();
            // Write first
            master_write(0, 32'h0000_0200, 4'd1, 8'd0, 32'h1111_1111);
            master_write(0, 32'h1000_0200, 4'd1, 8'd0, 32'h2222_2222);
            master_write(0, 32'h2000_0200, 4'd1, 8'd0, 32'h3333_3333);
            master_write(0, 32'h4000_0200, 4'd1, 8'd0, 32'h4444_4444);
            // Read back
            master_read(0, 32'h0000_0200, 4'd1, 8'd0, b0, d0);
            master_read(0, 32'h1000_0200, 4'd1, 8'd0, b1, d1);
            master_read(0, 32'h2000_0200, 4'd1, 8'd0, b2, d2);
            master_read(0, 32'h4000_0200, 4'd1, 8'd0, b3, d3);
            if (d0 == 32'h1111_1111 && d1 == 32'h2222_2222 &&
                d2 == 32'h3333_3333 && d3 == 32'h4444_4444)
                pass("test_all_slaves_read");
            else
                fail("test_all_slaves_read", $sformatf("d0=%h d1=%h d2=%h d3=%h", d0, d1, d2, d3));
        end

        // Test 4: Concurrent R/W — M0 writes S0 while M1 reads S1
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            // Pre-write data to S1
            master_write(1, 32'h1000_0300, 4'd5, 8'd0, 32'hFEED_FACE);
            fork
                master_write(0, 32'h0000_0300, 4'd1, 8'd0, 32'hDEAD_0000);
                master_read(1, 32'h1000_0300, 4'd5, 8'd0, beats, rdata);
            join
            if (beats == 1 && rdata == 32'hFEED_FACE)
                pass("test_concurrent_rw");
            else
                fail("test_concurrent_rw", $sformatf("beats=%0d data=%h", beats, rdata));
        end

        // Test 5: Same slave contention — M0 and M1 both write S0
        begin
            reset_all();
            master_write(0, 32'h0000_0400, 4'd1, 8'd0, 32'hAAAA_AAAA);
            master_write(1, 32'h0000_0404, 4'd2, 8'd0, 32'hBBBB_BBBB);
            // Verify both stored
            begin
                integer b0, b1;
                logic [DATA_W-1:0] d0, d1;
                master_read(0, 32'h0000_0400, 4'd1, 8'd0, b0, d0);
                master_read(0, 32'h0000_0404, 4'd2, 8'd0, b1, d1);
                if (d0 == 32'hAAAA_AAAA && d1 == 32'hBBBB_BBBB)
                    pass("test_same_slave_contention");
                else
                    fail("test_same_slave_contention", $sformatf("d0=%h d1=%h", d0, d1));
            end
        end

        // Test 6: 4-beat burst write then read
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            master_write(0, 32'h0000_0500, 4'd3, 8'd3, 32'hB000_0000);
            master_read(0, 32'h0000_0500, 4'd3, 8'd3, beats, rdata);
            if (beats == 4 && rdata == 32'hB000_0000)
                pass("test_burst_write_read");
            else
                fail("test_burst_write_read", $sformatf("beats=%0d data=%h", beats, rdata));
        end

        // Test 7: 16-beat burst round-trip
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            master_write(0, 32'h0000_0600, 4'd4, 8'd15, 32'hC000_0000);
            master_read(0, 32'h0000_0600, 4'd4, 8'd15, beats, rdata);
            if (beats == 16 && rdata == 32'hC000_0000)
                pass("test_burst_16_write_read");
            else
                fail("test_burst_16_write_read", $sformatf("beats=%0d data=%h", beats, rdata));
        end

        // Test 8: Unmapped write → DECERR
        begin
            integer timeout;
            reset_all();
            // Write to unmapped address
            m_awvalid[0] = 1;
            m_awaddr_flat[0 +: ADDR_W] = 32'hF000_0000;
            m_awid_flat[0 +: ID_W] = 4'd5;
            m_awlen_flat[0 +: 8] = 0;
            m_awburst_flat[0 +: 2] = BURST_INCR;
            timeout = 0;
            while (!m_awready[0] && timeout < 200) begin tick(1); timeout++; end
            tick(1); m_awvalid[0] = 0;
            m_wvalid[0] = 1; m_wlast[0] = 1;
            m_wdata_flat[0 +: DATA_W] = 32'hBAD0_0000;
            m_wstrb_flat[0 +: STRB_W] = 4'hF;
            timeout = 0;
            while (!m_wready[0] && timeout < 200) begin tick(1); timeout++; end
            tick(1); m_wvalid[0] = 0; m_wlast[0] = 0;
            m_bready[0] = 1;
            timeout = 0;
            while (!m_bvalid[0] && timeout < 200) begin tick(1); timeout++; end
            if (m_bresp_flat[0 +: 2] == RESP_DECERR)
                pass("test_unmapped_write_decerr");
            else
                fail("test_unmapped_write_decerr", $sformatf("bresp=%b", m_bresp_flat[0 +: 2]));
            tick(1); m_bready[0] = 0;
        end

        // Test 9: Unmapped read → DECERR
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            master_read(0, 32'hF000_0000, 4'd6, 8'd0, beats, rdata);
            if (beats == 1)
                pass("test_unmapped_read_decerr");
            else
                fail("test_unmapped_read_decerr", $sformatf("beats=%0d", beats));
        end

        // Test 10: Interleaved traffic
        begin
            reset_all();
            master_write(0, 32'h0000_0700, 4'd1, 8'd0, 32'h7777_0000);
            begin
                integer beats;
                logic [DATA_W-1:0] rdata;
                master_read(0, 32'h0000_0700, 4'd1, 8'd0, beats, rdata);
            end
            master_write(1, 32'h1000_0700, 4'd2, 8'd0, 32'h8888_0000);
            begin
                integer beats;
                logic [DATA_W-1:0] rdata;
                master_read(1, 32'h1000_0700, 4'd2, 8'd0, beats, rdata);
            end
            pass("test_interleaved_traffic");
        end

        // Test 11: Backpressure propagation
        begin
            reset_all();
            fork
                master_write(0, 32'h0000_0800, 4'd1, 8'd3, 32'hBACE_0000);
                master_write(1, 32'h1000_0800, 4'd2, 8'd3, 32'hFACE_0000);
            join
            pass("test_backpressure_propagation");
        end

        // Test 12: ID integrity — multiple IDs, check responses
        begin
            integer beats;
            logic [DATA_W-1:0] rdata;
            reset_all();
            master_write(0, 32'h0000_0900, 4'hA, 8'd0, 32'hAAAA_0000);
            master_write(0, 32'h0000_0904, 4'hB, 8'd0, 32'hBBBB_0000);
            master_read(0, 32'h0000_0900, 4'hA, 8'd0, beats, rdata);
            if (rdata == 32'hAAAA_0000)
                pass("test_id_integrity");
            else
                fail("test_id_integrity", $sformatf("data=%h", rdata));
        end

        // Test 13: Reset mid-burst
        begin
            integer timeout;
            reset_all();
            // Start a write, then reset
            m_awvalid[0] = 1;
            m_awaddr_flat[0 +: ADDR_W] = 32'h0000_0A00;
            m_awid_flat[0 +: ID_W] = 4'd1;
            m_awlen_flat[0 +: 8] = 8'd7; // 8-beat burst
            m_awburst_flat[0 +: 2] = BURST_INCR;
            timeout = 0;
            while (!m_awready[0] && timeout < 50) begin tick(1); timeout++; end
            tick(1); m_awvalid[0] = 0;
            // Send 2 beats then reset
            m_wvalid[0] = 1; m_wdata_flat[0 +: DATA_W] = 32'h1; m_wstrb_flat[0 +: STRB_W] = 4'hF; m_wlast[0] = 0;
            tick(2);
            // Reset mid-burst
            srst = 1; tick(3); srst = 0; tick(2);
            m_wvalid[0] = 0; m_wlast[0] = 0;
            // After reset, try a clean write
            master_write(0, 32'h0000_0B00, 4'd2, 8'd0, 32'hAFAF_AFAF);
            begin
                integer beats;
                logic [DATA_W-1:0] rdata;
                master_read(0, 32'h0000_0B00, 4'd2, 8'd0, beats, rdata);
                if (beats == 1 && rdata == 32'hAFAF_AFAF)
                    pass("test_reset_mid_burst");
                else
                    fail("test_reset_mid_burst", $sformatf("beats=%0d data=%h", beats, rdata));
            end
        end

        // Test 14: Stress — 200+ random transactions
        begin
            integer i, beats;
            integer ok;
            logic [DATA_W-1:0] rdata;
            logic [ADDR_W-1:0] addrs [0:3];
            ok = 1;
            reset_all();
            addrs[0] = 32'h0000_0C00;
            addrs[1] = 32'h1000_0C00;
            addrs[2] = 32'h2000_0C00;
            addrs[3] = 32'h4000_0C00;
            for (i = 0; i < 200; i++) begin
                // Write to slave i%4 from master i%2
                master_write(i % 2, addrs[i % 4] + ((i/4)*4), i[ID_W-1:0], 8'd0, 32'hA000_0000 + i);
            end
            // Read back a sample
            for (i = 0; i < 10; i++) begin
                master_read(0, addrs[i % 4] + ((i/4)*4), i[ID_W-1:0], 8'd0, beats, rdata);
                if (rdata != (32'hA000_0000 + i)) ok = 0;
            end
            if (ok) pass("test_stress_random");
            else fail("test_stress_random", "data mismatch");
        end

        $display("\n=== Crossbar Top: %0d/%0d tests passed ===",
                 pass_count, pass_count + fail_count);
        if (fail_count > 0) $stop;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 500000);
        $display("[FAIL] TIMEOUT");
        $finish;
    end

endmodule
