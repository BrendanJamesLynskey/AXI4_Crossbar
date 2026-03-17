// Brendan Lynskey 2025
module tb_r_path_wrapper
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // Master-side AR
    input  logic [N_MASTERS-1:0]           m_arvalid,
    output logic [N_MASTERS-1:0]           m_arready,
    input  logic [N_MASTERS*ID_W-1:0]      m_arid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]    m_araddr_flat,
    input  logic [N_MASTERS*8-1:0]         m_arlen_flat,
    input  logic [N_MASTERS*3-1:0]         m_arsize_flat,
    input  logic [N_MASTERS*2-1:0]         m_arburst_flat,

    // Master-side R
    output logic [N_MASTERS-1:0]           m_rvalid,
    input  logic [N_MASTERS-1:0]           m_rready,
    output logic [N_MASTERS*ID_W-1:0]      m_rid_flat,
    output logic [N_MASTERS*DATA_W-1:0]    m_rdata_flat,
    output logic [N_MASTERS*2-1:0]         m_rresp_flat,
    output logic [N_MASTERS-1:0]           m_rlast
);

    localparam int NS1 = N_SLAVES + 1;

    // Slave-side AR
    logic [NS1-1:0]             s_arvalid, s_arready;
    logic [NS1*SID_W-1:0]      s_arid_flat;
    logic [NS1*ADDR_W-1:0]     s_araddr_flat;
    logic [NS1*8-1:0]          s_arlen_flat;
    logic [NS1*3-1:0]          s_arsize_flat;
    logic [NS1*2-1:0]          s_arburst_flat;

    // Slave-side R
    logic [NS1-1:0]             s_rvalid, s_rready;
    logic [NS1*SID_W-1:0]      s_rid_flat;
    logic [NS1*DATA_W-1:0]     s_rdata_flat;
    logic [NS1*2-1:0]          s_rresp_flat;
    logic [NS1-1:0]             s_rlast;

    axi_r_path u_r_path (
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

    // Slave BFMs
    genvar gi;
    generate
        for (gi = 0; gi < NS1; gi = gi + 1) begin : gen_slave
            // Tie off write side
            wire aw_v = 1'b0, w_v = 1'b0, w_l = 1'b0, b_r = 1'b0;
            wire [SID_W-1:0] aw_id = '0;
            wire [ADDR_W-1:0] aw_addr = '0;
            wire [7:0] aw_len = '0;
            wire [2:0] aw_size = '0;
            wire [1:0] aw_burst = '0;
            wire [DATA_W-1:0] w_data = '0;
            wire [STRB_W-1:0] w_strb = '0;
            wire aw_rdy, w_rdy, b_valid;
            wire [SID_W-1:0] b_id;
            wire [1:0] b_resp;

            axi_slave_bfm #(.BFM_ID_W(SID_W)) u_bfm (
                .clk(clk), .srst(srst),
                .awvalid(aw_v), .awready(aw_rdy),
                .awid(aw_id), .awaddr(aw_addr), .awlen(aw_len),
                .awsize(aw_size), .awburst(aw_burst),
                .wvalid(w_v), .wready(w_rdy),
                .wdata(w_data), .wstrb(w_strb), .wlast(w_l),
                .bvalid(b_valid), .bready(b_r),
                .bid(b_id), .bresp(b_resp),
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

endmodule
