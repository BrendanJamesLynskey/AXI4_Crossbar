// Brendan Lynskey 2025
module axi_w_path
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // ---- Master-side AW channel (N_MASTERS) ----
    input  logic [N_MASTERS-1:0]                    m_awvalid,
    output logic [N_MASTERS-1:0]                    m_awready,
    input  logic [N_MASTERS*ID_W-1:0]               m_awid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]             m_awaddr_flat,
    input  logic [N_MASTERS*8-1:0]                  m_awlen_flat,
    input  logic [N_MASTERS*3-1:0]                  m_awsize_flat,
    input  logic [N_MASTERS*2-1:0]                  m_awburst_flat,

    // ---- Master-side W channel (N_MASTERS) ----
    input  logic [N_MASTERS-1:0]                    m_wvalid,
    output logic [N_MASTERS-1:0]                    m_wready,
    input  logic [N_MASTERS*DATA_W-1:0]             m_wdata_flat,
    input  logic [N_MASTERS*STRB_W-1:0]             m_wstrb_flat,
    input  logic [N_MASTERS-1:0]                    m_wlast,

    // ---- Master-side B channel (N_MASTERS) ----
    output logic [N_MASTERS-1:0]                    m_bvalid,
    input  logic [N_MASTERS-1:0]                    m_bready,
    output logic [N_MASTERS*ID_W-1:0]               m_bid_flat,
    output logic [N_MASTERS*2-1:0]                  m_bresp_flat,

    // ---- Slave-side AW channel (N_SLAVES + 1, includes error slave) ----
    output logic [N_SLAVES:0]                       s_awvalid,
    input  logic [N_SLAVES:0]                       s_awready,
    output logic [(N_SLAVES+1)*SID_W-1:0]           s_awid_flat,
    output logic [(N_SLAVES+1)*ADDR_W-1:0]          s_awaddr_flat,
    output logic [(N_SLAVES+1)*8-1:0]               s_awlen_flat,
    output logic [(N_SLAVES+1)*3-1:0]               s_awsize_flat,
    output logic [(N_SLAVES+1)*2-1:0]               s_awburst_flat,

    // ---- Slave-side W channel (N_SLAVES + 1) ----
    output logic [N_SLAVES:0]                       s_wvalid,
    input  logic [N_SLAVES:0]                       s_wready,
    output logic [(N_SLAVES+1)*DATA_W-1:0]          s_wdata_flat,
    output logic [(N_SLAVES+1)*STRB_W-1:0]          s_wstrb_flat,
    output logic [N_SLAVES:0]                       s_wlast,

    // ---- Slave-side B channel (N_SLAVES + 1) ----
    input  logic [N_SLAVES:0]                       s_bvalid,
    output logic [N_SLAVES:0]                       s_bready,
    input  logic [(N_SLAVES+1)*SID_W-1:0]           s_bid_flat,
    input  logic [(N_SLAVES+1)*2-1:0]               s_bresp_flat
);

    localparam int SIDX_W = $clog2(N_SLAVES+1);
    localparam int NS1    = N_SLAVES + 1;

    // ---- Per-master address decode ----
    // Use generate to instantiate decoders
    wire [N_MASTERS*SIDX_W-1:0] decoded_slave_flat;
    wire [N_MASTERS-1:0]        decoded_valid;

    genvar gm;
    generate
        for (gm = 0; gm < N_MASTERS; gm = gm + 1) begin : gen_aw_decode
            axi_addr_decoder u_dec (
                .addr      (m_awaddr_flat[gm*ADDR_W +: ADDR_W]),
                .slave_idx (decoded_slave_flat[gm*SIDX_W +: SIDX_W]),
                .addr_valid(decoded_valid[gm])
            );
        end
    endgenerate

    // ---- Per-master write state (flat encoded) ----
    // 2-bit state per master: 00=IDLE, 01=ADDR, 10=DATA, 11=RESP
    localparam [1:0] W_IDLE = 2'b00;
    localparam [1:0] W_ADDR = 2'b01;
    localparam [1:0] W_DATA = 2'b10;
    localparam [1:0] W_RESP = 2'b11;

    reg [N_MASTERS*2-1:0]      w_state_flat;
    reg [N_MASTERS*2-1:0]      w_state_next_flat;
    reg [N_MASTERS*SIDX_W-1:0] w_route_flat;
    reg [N_MASTERS*SIDX_W-1:0] w_route_next_flat;

    // ---- Per-slave arbiter (using generate) ----
    // Arbiter request/grant as flat vectors: N_MASTERS bits per slave
    reg  [NS1*N_MASTERS-1:0] aw_req_flat;
    wire [NS1*N_MASTERS-1:0] aw_grant_flat;
    wire [NS1*MSTR_IDX_W-1:0] aw_grant_idx_flat;
    wire [NS1-1:0]           aw_grant_valid;
    reg  [NS1-1:0]           aw_lock;

    genvar gs;
    generate
        for (gs = 0; gs < NS1; gs = gs + 1) begin : gen_aw_arb
            axi_arbiter #(.N_REQ(N_MASTERS), .MODE(ARB_ROUND_ROBIN)) u_arb (
                .clk        (clk),
                .srst       (srst),
                .req        (aw_req_flat[gs*N_MASTERS +: N_MASTERS]),
                .grant      (aw_grant_flat[gs*N_MASTERS +: N_MASTERS]),
                .grant_idx  (aw_grant_idx_flat[gs*MSTR_IDX_W +: MSTR_IDX_W]),
                .grant_valid(aw_grant_valid[gs]),
                .lock       (aw_lock[gs])
            );
        end
    endgenerate

    // ---- Build arbiter request vectors ----
    always @(*) begin
        integer m, s;
        for (s = 0; s < NS1; s = s + 1) begin
            for (m = 0; m < N_MASTERS; m = m + 1) begin
                aw_req_flat[s*N_MASTERS + m] = m_awvalid[m] &&
                    (w_state_flat[m*2 +: 2] == W_IDLE) &&
                    (decoded_slave_flat[m*SIDX_W +: SIDX_W] == s[SIDX_W-1:0]);
            end
        end
    end

    // ---- Lock logic ----
    always @(*) begin
        integer m, s;
        for (s = 0; s < NS1; s = s + 1) begin
            aw_lock[s] = 1'b0;
            for (m = 0; m < N_MASTERS; m = m + 1) begin
                if ((w_state_flat[m*2 +: 2] == W_ADDR || w_state_flat[m*2 +: 2] == W_DATA) &&
                    w_route_flat[m*SIDX_W +: SIDX_W] == s[SIDX_W-1:0])
                    aw_lock[s] = 1'b1;
            end
        end
    end

    // ---- AW channel muxing ----
    always @(*) begin
        integer s, m_int;

        for (s = 0; s < NS1; s = s + 1) begin
            s_awvalid[s] = 1'b0;
            s_awid_flat[s*SID_W +: SID_W]     = '0;
            s_awaddr_flat[s*ADDR_W +: ADDR_W]  = '0;
            s_awlen_flat[s*8 +: 8]             = '0;
            s_awsize_flat[s*3 +: 3]            = '0;
            s_awburst_flat[s*2 +: 2]           = '0;
        end

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1)
            m_awready[m_int] = 1'b0;

        for (s = 0; s < NS1; s = s + 1) begin
            if (aw_grant_valid[s]) begin
                m_int = aw_grant_idx_flat[s*MSTR_IDX_W +: MSTR_IDX_W];
                s_awvalid[s]                        = m_awvalid[m_int] && (w_state_flat[m_int*2 +: 2] == W_IDLE);
                s_awid_flat[s*SID_W +: SID_W]       = {m_int[MSTR_IDX_W-1:0], m_awid_flat[m_int*ID_W +: ID_W]};
                s_awaddr_flat[s*ADDR_W +: ADDR_W]    = m_awaddr_flat[m_int*ADDR_W +: ADDR_W];
                s_awlen_flat[s*8 +: 8]               = m_awlen_flat[m_int*8 +: 8];
                s_awsize_flat[s*3 +: 3]              = m_awsize_flat[m_int*3 +: 3];
                s_awburst_flat[s*2 +: 2]             = m_awburst_flat[m_int*2 +: 2];
                m_awready[m_int]                     = s_awready[s] && (w_state_flat[m_int*2 +: 2] == W_IDLE);
            end
        end
    end

    // ---- W channel muxing ----
    always @(*) begin
        integer s, m_int;
        integer route_s;

        for (s = 0; s < NS1; s = s + 1) begin
            s_wvalid[s]                       = 1'b0;
            s_wdata_flat[s*DATA_W +: DATA_W]  = '0;
            s_wstrb_flat[s*STRB_W +: STRB_W]  = '0;
            s_wlast[s]                        = 1'b0;
        end

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1)
            m_wready[m_int] = 1'b0;

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1) begin
            if (w_state_flat[m_int*2 +: 2] == W_ADDR || w_state_flat[m_int*2 +: 2] == W_DATA) begin
                route_s = w_route_flat[m_int*SIDX_W +: SIDX_W];
                s_wvalid[route_s]                          = m_wvalid[m_int];
                s_wdata_flat[route_s*DATA_W +: DATA_W]     = m_wdata_flat[m_int*DATA_W +: DATA_W];
                s_wstrb_flat[route_s*STRB_W +: STRB_W]     = m_wstrb_flat[m_int*STRB_W +: STRB_W];
                s_wlast[route_s]                           = m_wlast[m_int];
                m_wready[m_int]                            = s_wready[route_s];
            end
        end
    end

    // ---- B channel muxing ----
    always @(*) begin
        integer s, m_int;

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1) begin
            m_bvalid[m_int]                   = 1'b0;
            m_bid_flat[m_int*ID_W +: ID_W]    = '0;
            m_bresp_flat[m_int*2 +: 2]        = '0;
        end

        for (s = 0; s < NS1; s = s + 1)
            s_bready[s] = 1'b0;

        for (s = 0; s < NS1; s = s + 1) begin
            if (s_bvalid[s]) begin
                m_int = s_bid_flat[s*SID_W + ID_W +: MSTR_IDX_W];
                m_bvalid[m_int]                   = 1'b1;
                m_bid_flat[m_int*ID_W +: ID_W]    = s_bid_flat[s*SID_W +: ID_W];
                m_bresp_flat[m_int*2 +: 2]        = s_bresp_flat[s*2 +: 2];
                s_bready[s]                       = m_bready[m_int];
            end
        end
    end

    // ---- Per-master state machine ----
    always @(*) begin
        integer m, s;
        for (m = 0; m < N_MASTERS; m = m + 1) begin
            w_state_next_flat[m*2 +: 2] = w_state_flat[m*2 +: 2];
            w_route_next_flat[m*SIDX_W +: SIDX_W] = w_route_flat[m*SIDX_W +: SIDX_W];

            case (w_state_flat[m*2 +: 2])
                W_IDLE: begin
                    if (m_awvalid[m] && m_awready[m]) begin
                        w_state_next_flat[m*2 +: 2] = W_ADDR;
                        w_route_next_flat[m*SIDX_W +: SIDX_W] = decoded_slave_flat[m*SIDX_W +: SIDX_W];
                    end
                end
                W_ADDR: begin
                    if (m_wvalid[m] && m_wready[m]) begin
                        if (m_wlast[m])
                            w_state_next_flat[m*2 +: 2] = W_RESP;
                        else
                            w_state_next_flat[m*2 +: 2] = W_DATA;
                    end
                end
                W_DATA: begin
                    if (m_wvalid[m] && m_wready[m] && m_wlast[m])
                        w_state_next_flat[m*2 +: 2] = W_RESP;
                end
                W_RESP: begin
                    if (m_bvalid[m] && m_bready[m])
                        w_state_next_flat[m*2 +: 2] = W_IDLE;
                end
                default: w_state_next_flat[m*2 +: 2] = W_IDLE;
            endcase
        end
    end

    // Sequential update
    integer mi;
    always_ff @(posedge clk)
        if (srst) begin
            w_state_flat <= '0;
            w_route_flat <= '0;
        end else begin
            w_state_flat <= w_state_next_flat;
            w_route_flat <= w_route_next_flat;
        end

endmodule
