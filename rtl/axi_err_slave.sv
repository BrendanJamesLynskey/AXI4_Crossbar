// Brendan Lynskey 2025
module axi_err_slave
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // AW channel
    input  logic                awvalid,
    output logic                awready,
    input  logic [SID_W-1:0]    awid,
    input  logic [ADDR_W-1:0]   awaddr,
    input  logic [7:0]          awlen,
    input  logic [2:0]          awsize,
    input  logic [1:0]          awburst,

    // W channel
    input  logic                wvalid,
    output logic                wready,
    input  logic [DATA_W-1:0]   wdata,
    input  logic [STRB_W-1:0]   wstrb,
    input  logic                wlast,

    // B channel
    output logic                bvalid,
    input  logic                bready,
    output logic [SID_W-1:0]    bid,
    output logic [1:0]          bresp,

    // AR channel
    input  logic                arvalid,
    output logic                arready,
    input  logic [SID_W-1:0]    arid,
    input  logic [ADDR_W-1:0]   araddr,
    input  logic [7:0]          arlen,
    input  logic [2:0]          arsize,
    input  logic [1:0]          arburst,

    // R channel
    output logic                rvalid,
    input  logic                rready,
    output logic [SID_W-1:0]    rid,
    output logic [DATA_W-1:0]   rdata,
    output logic [1:0]          rresp,
    output logic                rlast
);

    // ---- Write path FSM ----
    typedef enum logic [1:0] {
        ERR_W_IDLE = 2'b00,
        ERR_W_DATA = 2'b01,
        ERR_W_RESP = 2'b10
    } err_w_state_t;

    err_w_state_t w_state, w_state_next;
    logic [SID_W-1:0] w_id, w_id_next;

    always_ff @(posedge clk)
        if (srst) begin
            w_state <= ERR_W_IDLE;
            w_id    <= '0;
        end else begin
            w_state <= w_state_next;
            w_id    <= w_id_next;
        end

    always @(*) begin
        w_state_next = w_state;
        w_id_next    = w_id;
        awready      = 1'b0;
        wready       = 1'b0;
        bvalid       = 1'b0;
        bid          = w_id;
        bresp        = RESP_DECERR;

        case (w_state)
            ERR_W_IDLE: begin
                awready = 1'b1;
                if (awvalid) begin
                    w_id_next    = awid;
                    w_state_next = ERR_W_DATA;
                end
            end
            ERR_W_DATA: begin
                wready = 1'b1;
                if (wvalid && wlast)
                    w_state_next = ERR_W_RESP;
            end
            ERR_W_RESP: begin
                bvalid = 1'b1;
                if (bready)
                    w_state_next = ERR_W_IDLE;
            end
            default: w_state_next = ERR_W_IDLE;
        endcase
    end

    // ---- Read path FSM ----
    typedef enum logic [1:0] {
        ERR_R_IDLE = 2'b00,
        ERR_R_DATA = 2'b01
    } err_r_state_t;

    err_r_state_t r_state, r_state_next;
    logic [SID_W-1:0] r_id, r_id_next;
    logic [7:0] r_cnt, r_cnt_next;

    always_ff @(posedge clk)
        if (srst) begin
            r_state <= ERR_R_IDLE;
            r_id    <= '0;
            r_cnt   <= '0;
        end else begin
            r_state <= r_state_next;
            r_id    <= r_id_next;
            r_cnt   <= r_cnt_next;
        end

    always @(*) begin
        r_state_next = r_state;
        r_id_next    = r_id;
        r_cnt_next   = r_cnt;
        arready      = 1'b0;
        rvalid       = 1'b0;
        rid          = r_id;
        rdata        = 32'hDEAD_BEEF;
        rresp        = RESP_DECERR;
        rlast        = 1'b0;

        case (r_state)
            ERR_R_IDLE: begin
                arready = 1'b1;
                if (arvalid) begin
                    r_id_next    = arid;
                    r_cnt_next   = arlen;
                    r_state_next = ERR_R_DATA;
                end
            end
            ERR_R_DATA: begin
                rvalid = 1'b1;
                rlast  = (r_cnt == 8'd0);
                if (rready) begin
                    if (r_cnt == 8'd0)
                        r_state_next = ERR_R_IDLE;
                    else
                        r_cnt_next = r_cnt - 8'd1;
                end
            end
            default: r_state_next = ERR_R_IDLE;
        endcase
    end

endmodule
