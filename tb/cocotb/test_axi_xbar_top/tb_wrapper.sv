// Brendan Lynskey 2025
module tb_xbar_wrapper
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // Master-side AW
    input  logic [N_MASTERS-1:0]           m_awvalid,
    output logic [N_MASTERS-1:0]           m_awready,
    input  logic [N_MASTERS*ID_W-1:0]      m_awid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]    m_awaddr_flat,
    input  logic [N_MASTERS*8-1:0]         m_awlen_flat,
    input  logic [N_MASTERS*3-1:0]         m_awsize_flat,
    input  logic [N_MASTERS*2-1:0]         m_awburst_flat,

    // Master-side W
    input  logic [N_MASTERS-1:0]           m_wvalid,
    output logic [N_MASTERS-1:0]           m_wready,
    input  logic [N_MASTERS*DATA_W-1:0]    m_wdata_flat,
    input  logic [N_MASTERS*STRB_W-1:0]    m_wstrb_flat,
    input  logic [N_MASTERS-1:0]           m_wlast,

    // Master-side B
    output logic [N_MASTERS-1:0]           m_bvalid,
    input  logic [N_MASTERS-1:0]           m_bready,
    output logic [N_MASTERS*ID_W-1:0]      m_bid_flat,
    output logic [N_MASTERS*2-1:0]         m_bresp_flat,

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

    // Slave-side wires
    logic [N_SLAVES-1:0]           s_awvalid, s_awready;
    logic [N_SLAVES*SID_W-1:0]    s_awid_flat;
    logic [N_SLAVES*ADDR_W-1:0]   s_awaddr_flat;
    logic [N_SLAVES*8-1:0]        s_awlen_flat;
    logic [N_SLAVES*3-1:0]        s_awsize_flat;
    logic [N_SLAVES*2-1:0]        s_awburst_flat;

    logic [N_SLAVES-1:0]           s_wvalid, s_wready;
    logic [N_SLAVES*DATA_W-1:0]   s_wdata_flat;
    logic [N_SLAVES*STRB_W-1:0]   s_wstrb_flat;
    logic [N_SLAVES-1:0]           s_wlast;

    logic [N_SLAVES-1:0]           s_bvalid, s_bready;
    logic [N_SLAVES*SID_W-1:0]    s_bid_flat;
    logic [N_SLAVES*2-1:0]        s_bresp_flat;

    logic [N_SLAVES-1:0]           s_arvalid, s_arready;
    logic [N_SLAVES*SID_W-1:0]    s_arid_flat;
    logic [N_SLAVES*ADDR_W-1:0]   s_araddr_flat;
    logic [N_SLAVES*8-1:0]        s_arlen_flat;
    logic [N_SLAVES*3-1:0]        s_arsize_flat;
    logic [N_SLAVES*2-1:0]        s_arburst_flat;

    logic [N_SLAVES-1:0]           s_rvalid, s_rready;
    logic [N_SLAVES*SID_W-1:0]    s_rid_flat;
    logic [N_SLAVES*DATA_W-1:0]   s_rdata_flat;
    logic [N_SLAVES*2-1:0]        s_rresp_flat;
    logic [N_SLAVES-1:0]           s_rlast;

    axi_xbar_top u_xbar (
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

endmodule
