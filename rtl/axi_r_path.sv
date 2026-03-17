// Brendan Lynskey 2025
module axi_r_path
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // ---- Master-side AR channel (N_MASTERS) ----
    input  logic [N_MASTERS-1:0]                    m_arvalid,
    output logic [N_MASTERS-1:0]                    m_arready,
    input  logic [N_MASTERS*ID_W-1:0]               m_arid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]             m_araddr_flat,
    input  logic [N_MASTERS*8-1:0]                  m_arlen_flat,
    input  logic [N_MASTERS*3-1:0]                  m_arsize_flat,
    input  logic [N_MASTERS*2-1:0]                  m_arburst_flat,

    // ---- Master-side R channel (N_MASTERS) ----
    output logic [N_MASTERS-1:0]                    m_rvalid,
    input  logic [N_MASTERS-1:0]                    m_rready,
    output logic [N_MASTERS*ID_W-1:0]               m_rid_flat,
    output logic [N_MASTERS*DATA_W-1:0]             m_rdata_flat,
    output logic [N_MASTERS*2-1:0]                  m_rresp_flat,
    output logic [N_MASTERS-1:0]                    m_rlast,

    // ---- Slave-side AR channel (N_SLAVES + 1) ----
    output logic [N_SLAVES:0]                       s_arvalid,
    input  logic [N_SLAVES:0]                       s_arready,
    output logic [(N_SLAVES+1)*SID_W-1:0]           s_arid_flat,
    output logic [(N_SLAVES+1)*ADDR_W-1:0]          s_araddr_flat,
    output logic [(N_SLAVES+1)*8-1:0]               s_arlen_flat,
    output logic [(N_SLAVES+1)*3-1:0]               s_arsize_flat,
    output logic [(N_SLAVES+1)*2-1:0]               s_arburst_flat,

    // ---- Slave-side R channel (N_SLAVES + 1) ----
    input  logic [N_SLAVES:0]                       s_rvalid,
    output logic [N_SLAVES:0]                       s_rready,
    input  logic [(N_SLAVES+1)*SID_W-1:0]           s_rid_flat,
    input  logic [(N_SLAVES+1)*DATA_W-1:0]          s_rdata_flat,
    input  logic [(N_SLAVES+1)*2-1:0]               s_rresp_flat,
    input  logic [N_SLAVES:0]                       s_rlast
);

    localparam int SIDX_W = $clog2(N_SLAVES+1);
    localparam int NS1    = N_SLAVES + 1;

    // ---- Per-master address decode ----
    wire [N_MASTERS*SIDX_W-1:0] decoded_slave_flat;
    wire [N_MASTERS-1:0]        decoded_valid;

    genvar gm;
    generate
        for (gm = 0; gm < N_MASTERS; gm = gm + 1) begin : gen_ar_decode
            axi_addr_decoder u_dec (
                .addr      (m_araddr_flat[gm*ADDR_W +: ADDR_W]),
                .slave_idx (decoded_slave_flat[gm*SIDX_W +: SIDX_W]),
                .addr_valid(decoded_valid[gm])
            );
        end
    endgenerate

    // ---- Per-slave arbiter ----
    reg  [NS1*N_MASTERS-1:0]    ar_req_flat;
    wire [NS1*N_MASTERS-1:0]    ar_grant_flat;
    wire [NS1*MSTR_IDX_W-1:0]  ar_grant_idx_flat;
    wire [NS1-1:0]              ar_grant_valid;
    reg  [NS1-1:0]              ar_lock;

    genvar gs;
    generate
        for (gs = 0; gs < NS1; gs = gs + 1) begin : gen_ar_arb
            axi_arbiter #(.N_REQ(N_MASTERS), .MODE(ARB_ROUND_ROBIN)) u_arb (
                .clk        (clk),
                .srst       (srst),
                .req        (ar_req_flat[gs*N_MASTERS +: N_MASTERS]),
                .grant      (ar_grant_flat[gs*N_MASTERS +: N_MASTERS]),
                .grant_idx  (ar_grant_idx_flat[gs*MSTR_IDX_W +: MSTR_IDX_W]),
                .grant_valid(ar_grant_valid[gs]),
                .lock       (ar_lock[gs])
            );
        end
    endgenerate

    // ---- Per-master read state ----
    // No write-style locking needed, but we track outstanding reads for AR arbitration
    // 1-bit per master: 0=idle (can issue AR), 1=waiting for R completion
    // Actually, to support outstanding reads we don't block AR. Keep it simple:
    // just arbitrate AR requests. No per-master state needed for AR.

    // Lock: no lock for read path (each AR is independent)
    always @(*) begin
        integer s;
        for (s = 0; s < NS1; s = s + 1)
            ar_lock[s] = 1'b0;
    end

    // ---- Build arbiter request vectors ----
    always @(*) begin
        integer m, s;
        for (s = 0; s < NS1; s = s + 1) begin
            for (m = 0; m < N_MASTERS; m = m + 1) begin
                ar_req_flat[s*N_MASTERS + m] = m_arvalid[m] &&
                    (decoded_slave_flat[m*SIDX_W +: SIDX_W] == s[SIDX_W-1:0]);
            end
        end
    end

    // ---- AR channel muxing ----
    always @(*) begin
        integer s, m_int;

        for (s = 0; s < NS1; s = s + 1) begin
            s_arvalid[s] = 1'b0;
            s_arid_flat[s*SID_W +: SID_W]     = '0;
            s_araddr_flat[s*ADDR_W +: ADDR_W]  = '0;
            s_arlen_flat[s*8 +: 8]             = '0;
            s_arsize_flat[s*3 +: 3]            = '0;
            s_arburst_flat[s*2 +: 2]           = '0;
        end

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1)
            m_arready[m_int] = 1'b0;

        for (s = 0; s < NS1; s = s + 1) begin
            if (ar_grant_valid[s]) begin
                m_int = ar_grant_idx_flat[s*MSTR_IDX_W +: MSTR_IDX_W];
                s_arvalid[s]                        = m_arvalid[m_int];
                s_arid_flat[s*SID_W +: SID_W]       = {m_int[MSTR_IDX_W-1:0], m_arid_flat[m_int*ID_W +: ID_W]};
                s_araddr_flat[s*ADDR_W +: ADDR_W]    = m_araddr_flat[m_int*ADDR_W +: ADDR_W];
                s_arlen_flat[s*8 +: 8]               = m_arlen_flat[m_int*8 +: 8];
                s_arsize_flat[s*3 +: 3]              = m_arsize_flat[m_int*3 +: 3];
                s_arburst_flat[s*2 +: 2]             = m_arburst_flat[m_int*2 +: 2];
                m_arready[m_int]                     = s_arready[s];
            end
        end
    end

    // ---- R channel muxing: route by upper bits of rid ----
    // For each slave with rvalid, extract master_idx from rid upper bits,
    // route to that master. Lock the R mux per slave during a burst.

    // Per-slave R burst lock: tracks which master a slave is currently delivering to
    reg [NS1-1:0]               r_locked;
    reg [NS1*MSTR_IDX_W-1:0]   r_locked_master_flat;

    always_ff @(posedge clk)
        if (srst) begin
            r_locked             <= '0;
            r_locked_master_flat <= '0;
        end else begin
            integer s_i;
            integer m_tgt;
            for (s_i = 0; s_i < NS1; s_i = s_i + 1) begin
                m_tgt = s_rid_flat[s_i*SID_W + ID_W +: MSTR_IDX_W];
                if (!r_locked[s_i] && s_rvalid[s_i] && m_rready[m_tgt]) begin
                    // Start of burst (or single beat) — lock
                    r_locked[s_i] <= 1'b1;
                    r_locked_master_flat[s_i*MSTR_IDX_W +: MSTR_IDX_W] <= m_tgt[MSTR_IDX_W-1:0];
                    if (s_rlast[s_i])
                        r_locked[s_i] <= 1'b0; // single beat, unlock immediately
                end else if (r_locked[s_i] && s_rvalid[s_i] && s_rlast[s_i]) begin
                    m_tgt = r_locked_master_flat[s_i*MSTR_IDX_W +: MSTR_IDX_W];
                    if (m_rready[m_tgt])
                        r_locked[s_i] <= 1'b0;
                end
            end
        end

    always @(*) begin
        integer s, m_int;

        for (m_int = 0; m_int < N_MASTERS; m_int = m_int + 1) begin
            m_rvalid[m_int]                       = 1'b0;
            m_rid_flat[m_int*ID_W +: ID_W]        = '0;
            m_rdata_flat[m_int*DATA_W +: DATA_W]  = '0;
            m_rresp_flat[m_int*2 +: 2]            = '0;
            m_rlast[m_int]                        = 1'b0;
        end

        for (s = 0; s < NS1; s = s + 1)
            s_rready[s] = 1'b0;

        for (s = 0; s < NS1; s = s + 1) begin
            if (s_rvalid[s]) begin
                m_int = s_rid_flat[s*SID_W + ID_W +: MSTR_IDX_W];
                m_rvalid[m_int]                       = 1'b1;
                m_rid_flat[m_int*ID_W +: ID_W]        = s_rid_flat[s*SID_W +: ID_W];
                m_rdata_flat[m_int*DATA_W +: DATA_W]  = s_rdata_flat[s*DATA_W +: DATA_W];
                m_rresp_flat[m_int*2 +: 2]            = s_rresp_flat[s*2 +: 2];
                m_rlast[m_int]                        = s_rlast[s];
                s_rready[s]                           = m_rready[m_int];
            end
        end
    end

endmodule
