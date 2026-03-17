// Brendan Lynskey 2025
// Simple AXI4 slave BFM with associative array memory
module axi_slave_bfm
    import axi_xbar_pkg::*;
#(
    parameter int BFM_ID_W = SID_W
)(
    input  logic                    clk,
    input  logic                    srst,

    // AW
    input  logic                    awvalid,
    output logic                    awready,
    input  logic [BFM_ID_W-1:0]    awid,
    input  logic [ADDR_W-1:0]      awaddr,
    input  logic [7:0]             awlen,
    input  logic [2:0]             awsize,
    input  logic [1:0]             awburst,

    // W
    input  logic                    wvalid,
    output logic                    wready,
    input  logic [DATA_W-1:0]      wdata,
    input  logic [STRB_W-1:0]      wstrb,
    input  logic                    wlast,

    // B
    output logic                    bvalid,
    input  logic                    bready,
    output logic [BFM_ID_W-1:0]    bid,
    output logic [1:0]             bresp,

    // AR
    input  logic                    arvalid,
    output logic                    arready,
    input  logic [BFM_ID_W-1:0]    arid,
    input  logic [ADDR_W-1:0]      araddr,
    input  logic [7:0]             arlen,
    input  logic [2:0]             arsize,
    input  logic [1:0]             arburst,

    // R
    output logic                    rvalid,
    input  logic                    rready,
    output logic [BFM_ID_W-1:0]    rid,
    output logic [DATA_W-1:0]      rdata,
    output logic [1:0]             rresp,
    output logic                    rlast
);

    // Memory storage — 1K words (4KB), word-addressed by addr[11:2]
    localparam int MEM_DEPTH = 1024;
    logic [DATA_W-1:0] mem [0:MEM_DEPTH-1];

    // Write path FSM
    typedef enum logic [1:0] {
        BFM_W_IDLE = 2'b00,
        BFM_W_DATA = 2'b01,
        BFM_W_RESP = 2'b10
    } bfm_w_state_t;

    bfm_w_state_t bfm_w_state, bfm_w_state_next;
    logic [BFM_ID_W-1:0] bfm_w_id, bfm_w_id_next;
    logic [ADDR_W-1:0]   bfm_w_addr, bfm_w_addr_next;
    logic [7:0]          bfm_w_len, bfm_w_len_next;
    logic [2:0]          bfm_w_size; // captured awsize

    always_ff @(posedge clk)
        if (srst) begin
            bfm_w_state <= BFM_W_IDLE;
            bfm_w_id    <= '0;
            bfm_w_addr  <= '0;
            bfm_w_len   <= '0;
            bfm_w_size  <= '0;
        end else begin
            bfm_w_state <= bfm_w_state_next;
            bfm_w_id    <= bfm_w_id_next;
            bfm_w_addr  <= bfm_w_addr_next;
            bfm_w_len   <= bfm_w_len_next;
            if (bfm_w_state == BFM_W_IDLE && awvalid)
                bfm_w_size <= awsize;
        end

    always @(*) begin
        bfm_w_state_next = bfm_w_state;
        bfm_w_id_next    = bfm_w_id;
        bfm_w_addr_next  = bfm_w_addr;
        bfm_w_len_next   = bfm_w_len;
        awready          = 1'b0;
        wready           = 1'b0;
        bvalid           = 1'b0;
        bid              = bfm_w_id;
        bresp            = RESP_OKAY;

        case (bfm_w_state)
            BFM_W_IDLE: begin
                awready = 1'b1;
                if (awvalid) begin
                    bfm_w_id_next    = awid;
                    bfm_w_addr_next  = awaddr;
                    bfm_w_len_next   = awlen;
                    bfm_w_state_next = BFM_W_DATA;
                end
            end
            BFM_W_DATA: begin
                wready = 1'b1;
                if (wvalid) begin
                    // wlast signals last beat (no need to use in always @* for mem write)
                    if (wlast)
                        bfm_w_state_next = BFM_W_RESP;
                end
            end
            BFM_W_RESP: begin
                bvalid = 1'b1;
                if (bready)
                    bfm_w_state_next = BFM_W_IDLE;
            end
            default: bfm_w_state_next = BFM_W_IDLE;
        endcase
    end

    // Memory write on clock edge
    always_ff @(posedge clk) begin
        if (!srst && bfm_w_state == BFM_W_DATA && wvalid && wready) begin
            // Apply byte strobes — word-addressed
            integer b;
            for (b = 0; b < STRB_W; b = b + 1) begin
                if (wstrb[b])
                    mem[bfm_w_addr[11:2]][b*8 +: 8] <= wdata[b*8 +: 8];
            end
            bfm_w_addr <= bfm_w_addr + (1 << bfm_w_size);
        end
    end

    // Read path FSM
    typedef enum logic [1:0] {
        BFM_R_IDLE = 2'b00,
        BFM_R_DATA = 2'b01
    } bfm_r_state_t;

    bfm_r_state_t bfm_r_state, bfm_r_state_next;
    logic [BFM_ID_W-1:0] bfm_r_id, bfm_r_id_next;
    logic [ADDR_W-1:0]   bfm_r_addr, bfm_r_addr_next;
    logic [7:0]          bfm_r_cnt, bfm_r_cnt_next;
    logic [2:0]          bfm_r_size;

    always_ff @(posedge clk)
        if (srst) begin
            bfm_r_state <= BFM_R_IDLE;
            bfm_r_id    <= '0;
            bfm_r_addr  <= '0;
            bfm_r_cnt   <= '0;
            bfm_r_size  <= '0;
        end else begin
            bfm_r_state <= bfm_r_state_next;
            bfm_r_id    <= bfm_r_id_next;
            bfm_r_addr  <= bfm_r_addr_next;
            bfm_r_cnt   <= bfm_r_cnt_next;
            if (bfm_r_state == BFM_R_IDLE && arvalid)
                bfm_r_size <= arsize;
        end

    always @(*) begin
        bfm_r_state_next = bfm_r_state;
        bfm_r_id_next    = bfm_r_id;
        bfm_r_addr_next  = bfm_r_addr;
        bfm_r_cnt_next   = bfm_r_cnt;
        arready          = 1'b0;
        rvalid           = 1'b0;
        rid              = bfm_r_id;
        rdata            = '0;
        rresp            = RESP_OKAY;
        rlast            = 1'b0;

        case (bfm_r_state)
            BFM_R_IDLE: begin
                arready = 1'b1;
                if (arvalid) begin
                    bfm_r_id_next    = arid;
                    bfm_r_addr_next  = araddr;
                    bfm_r_cnt_next   = arlen;
                    bfm_r_state_next = BFM_R_DATA;
                end
            end
            BFM_R_DATA: begin
                rvalid = 1'b1;
                rdata = mem[bfm_r_addr[11:2]];
                rlast = (bfm_r_cnt == 8'd0);
                if (rready) begin
                    if (bfm_r_cnt == 8'd0)
                        bfm_r_state_next = BFM_R_IDLE;
                    else begin
                        bfm_r_cnt_next  = bfm_r_cnt - 8'd1;
                        bfm_r_addr_next = bfm_r_addr + (1 << bfm_r_size);
                    end
                end
            end
            default: bfm_r_state_next = BFM_R_IDLE;
        endcase
    end

endmodule
