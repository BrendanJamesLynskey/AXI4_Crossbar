// Brendan Lynskey 2025
module axi_xbar_top
    import axi_xbar_pkg::*;
(
    input  logic                clk,
    input  logic                srst,

    // ---- Master-side AW ----
    input  logic [N_MASTERS-1:0]                m_awvalid,
    output logic [N_MASTERS-1:0]                m_awready,
    input  logic [N_MASTERS*ID_W-1:0]           m_awid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]         m_awaddr_flat,
    input  logic [N_MASTERS*8-1:0]              m_awlen_flat,
    input  logic [N_MASTERS*3-1:0]              m_awsize_flat,
    input  logic [N_MASTERS*2-1:0]              m_awburst_flat,

    // ---- Master-side W ----
    input  logic [N_MASTERS-1:0]                m_wvalid,
    output logic [N_MASTERS-1:0]                m_wready,
    input  logic [N_MASTERS*DATA_W-1:0]         m_wdata_flat,
    input  logic [N_MASTERS*STRB_W-1:0]         m_wstrb_flat,
    input  logic [N_MASTERS-1:0]                m_wlast,

    // ---- Master-side B ----
    output logic [N_MASTERS-1:0]                m_bvalid,
    input  logic [N_MASTERS-1:0]                m_bready,
    output logic [N_MASTERS*ID_W-1:0]           m_bid_flat,
    output logic [N_MASTERS*2-1:0]              m_bresp_flat,

    // ---- Master-side AR ----
    input  logic [N_MASTERS-1:0]                m_arvalid,
    output logic [N_MASTERS-1:0]                m_arready,
    input  logic [N_MASTERS*ID_W-1:0]           m_arid_flat,
    input  logic [N_MASTERS*ADDR_W-1:0]         m_araddr_flat,
    input  logic [N_MASTERS*8-1:0]              m_arlen_flat,
    input  logic [N_MASTERS*3-1:0]              m_arsize_flat,
    input  logic [N_MASTERS*2-1:0]              m_arburst_flat,

    // ---- Master-side R ----
    output logic [N_MASTERS-1:0]                m_rvalid,
    input  logic [N_MASTERS-1:0]                m_rready,
    output logic [N_MASTERS*ID_W-1:0]           m_rid_flat,
    output logic [N_MASTERS*DATA_W-1:0]         m_rdata_flat,
    output logic [N_MASTERS*2-1:0]              m_rresp_flat,
    output logic [N_MASTERS-1:0]                m_rlast,

    // ---- Slave-side AW ----
    output logic [N_SLAVES-1:0]                 s_awvalid,
    input  logic [N_SLAVES-1:0]                 s_awready,
    output logic [N_SLAVES*SID_W-1:0]           s_awid_flat,
    output logic [N_SLAVES*ADDR_W-1:0]          s_awaddr_flat,
    output logic [N_SLAVES*8-1:0]               s_awlen_flat,
    output logic [N_SLAVES*3-1:0]               s_awsize_flat,
    output logic [N_SLAVES*2-1:0]               s_awburst_flat,

    // ---- Slave-side W ----
    output logic [N_SLAVES-1:0]                 s_wvalid,
    input  logic [N_SLAVES-1:0]                 s_wready,
    output logic [N_SLAVES*DATA_W-1:0]          s_wdata_flat,
    output logic [N_SLAVES*STRB_W-1:0]          s_wstrb_flat,
    output logic [N_SLAVES-1:0]                 s_wlast,

    // ---- Slave-side B ----
    input  logic [N_SLAVES-1:0]                 s_bvalid,
    output logic [N_SLAVES-1:0]                 s_bready,
    input  logic [N_SLAVES*SID_W-1:0]           s_bid_flat,
    input  logic [N_SLAVES*2-1:0]               s_bresp_flat,

    // ---- Slave-side AR ----
    output logic [N_SLAVES-1:0]                 s_arvalid,
    input  logic [N_SLAVES-1:0]                 s_arready,
    output logic [N_SLAVES*SID_W-1:0]           s_arid_flat,
    output logic [N_SLAVES*ADDR_W-1:0]          s_araddr_flat,
    output logic [N_SLAVES*8-1:0]               s_arlen_flat,
    output logic [N_SLAVES*3-1:0]               s_arsize_flat,
    output logic [N_SLAVES*2-1:0]               s_arburst_flat,

    // ---- Slave-side R ----
    input  logic [N_SLAVES-1:0]                 s_rvalid,
    output logic [N_SLAVES-1:0]                 s_rready,
    input  logic [N_SLAVES*SID_W-1:0]           s_rid_flat,
    input  logic [N_SLAVES*DATA_W-1:0]          s_rdata_flat,
    input  logic [N_SLAVES*2-1:0]               s_rresp_flat,
    input  logic [N_SLAVES-1:0]                 s_rlast
);

    localparam int NS1 = N_SLAVES + 1; // includes error slave

    // Internal wires for NS1 slave ports (real slaves + error slave)
    // Write path internal signals
    logic [NS1-1:0]             wp_s_awvalid;
    logic [NS1-1:0]             wp_s_awready;
    logic [NS1*SID_W-1:0]      wp_s_awid_flat;
    logic [NS1*ADDR_W-1:0]     wp_s_awaddr_flat;
    logic [NS1*8-1:0]          wp_s_awlen_flat;
    logic [NS1*3-1:0]          wp_s_awsize_flat;
    logic [NS1*2-1:0]          wp_s_awburst_flat;

    logic [NS1-1:0]             wp_s_wvalid;
    logic [NS1-1:0]             wp_s_wready;
    logic [NS1*DATA_W-1:0]     wp_s_wdata_flat;
    logic [NS1*STRB_W-1:0]     wp_s_wstrb_flat;
    logic [NS1-1:0]             wp_s_wlast;

    logic [NS1-1:0]             wp_s_bvalid;
    logic [NS1-1:0]             wp_s_bready;
    logic [NS1*SID_W-1:0]      wp_s_bid_flat;
    logic [NS1*2-1:0]          wp_s_bresp_flat;

    // Read path internal signals
    logic [NS1-1:0]             rp_s_arvalid;
    logic [NS1-1:0]             rp_s_arready;
    logic [NS1*SID_W-1:0]      rp_s_arid_flat;
    logic [NS1*ADDR_W-1:0]     rp_s_araddr_flat;
    logic [NS1*8-1:0]          rp_s_arlen_flat;
    logic [NS1*3-1:0]          rp_s_arsize_flat;
    logic [NS1*2-1:0]          rp_s_arburst_flat;

    logic [NS1-1:0]             rp_s_rvalid;
    logic [NS1-1:0]             rp_s_rready;
    logic [NS1*SID_W-1:0]      rp_s_rid_flat;
    logic [NS1*DATA_W-1:0]     rp_s_rdata_flat;
    logic [NS1*2-1:0]          rp_s_rresp_flat;
    logic [NS1-1:0]             rp_s_rlast;

    // ---- Write Path ----
    axi_w_path u_w_path (
        .clk            (clk),
        .srst           (srst),
        .m_awvalid      (m_awvalid),
        .m_awready      (m_awready),
        .m_awid_flat    (m_awid_flat),
        .m_awaddr_flat  (m_awaddr_flat),
        .m_awlen_flat   (m_awlen_flat),
        .m_awsize_flat  (m_awsize_flat),
        .m_awburst_flat (m_awburst_flat),
        .m_wvalid       (m_wvalid),
        .m_wready       (m_wready),
        .m_wdata_flat   (m_wdata_flat),
        .m_wstrb_flat   (m_wstrb_flat),
        .m_wlast        (m_wlast),
        .m_bvalid       (m_bvalid),
        .m_bready       (m_bready),
        .m_bid_flat     (m_bid_flat),
        .m_bresp_flat   (m_bresp_flat),
        .s_awvalid      (wp_s_awvalid),
        .s_awready      (wp_s_awready),
        .s_awid_flat    (wp_s_awid_flat),
        .s_awaddr_flat  (wp_s_awaddr_flat),
        .s_awlen_flat   (wp_s_awlen_flat),
        .s_awsize_flat  (wp_s_awsize_flat),
        .s_awburst_flat (wp_s_awburst_flat),
        .s_wvalid       (wp_s_wvalid),
        .s_wready       (wp_s_wready),
        .s_wdata_flat   (wp_s_wdata_flat),
        .s_wstrb_flat   (wp_s_wstrb_flat),
        .s_wlast        (wp_s_wlast),
        .s_bvalid       (wp_s_bvalid),
        .s_bready       (wp_s_bready),
        .s_bid_flat     (wp_s_bid_flat),
        .s_bresp_flat   (wp_s_bresp_flat)
    );

    // ---- Read Path ----
    axi_r_path u_r_path (
        .clk            (clk),
        .srst           (srst),
        .m_arvalid      (m_arvalid),
        .m_arready      (m_arready),
        .m_arid_flat    (m_arid_flat),
        .m_araddr_flat  (m_araddr_flat),
        .m_arlen_flat   (m_arlen_flat),
        .m_arsize_flat  (m_arsize_flat),
        .m_arburst_flat (m_arburst_flat),
        .m_rvalid       (m_rvalid),
        .m_rready       (m_rready),
        .m_rid_flat     (m_rid_flat),
        .m_rdata_flat   (m_rdata_flat),
        .m_rresp_flat   (m_rresp_flat),
        .m_rlast        (m_rlast),
        .s_arvalid      (rp_s_arvalid),
        .s_arready      (rp_s_arready),
        .s_arid_flat    (rp_s_arid_flat),
        .s_araddr_flat  (rp_s_araddr_flat),
        .s_arlen_flat   (rp_s_arlen_flat),
        .s_arsize_flat  (rp_s_arsize_flat),
        .s_arburst_flat (rp_s_arburst_flat),
        .s_rvalid       (rp_s_rvalid),
        .s_rready       (rp_s_rready),
        .s_rid_flat     (rp_s_rid_flat),
        .s_rdata_flat   (rp_s_rdata_flat),
        .s_rresp_flat   (rp_s_rresp_flat),
        .s_rlast        (rp_s_rlast)
    );

    // ---- Error Slave (index N_SLAVES) ----
    axi_err_slave u_err_slave (
        .clk     (clk),
        .srst    (srst),
        // AW
        .awvalid (wp_s_awvalid[N_SLAVES]),
        .awready (wp_s_awready[N_SLAVES]),
        .awid    (wp_s_awid_flat[N_SLAVES*SID_W +: SID_W]),
        .awaddr  (wp_s_awaddr_flat[N_SLAVES*ADDR_W +: ADDR_W]),
        .awlen   (wp_s_awlen_flat[N_SLAVES*8 +: 8]),
        .awsize  (wp_s_awsize_flat[N_SLAVES*3 +: 3]),
        .awburst (wp_s_awburst_flat[N_SLAVES*2 +: 2]),
        // W
        .wvalid  (wp_s_wvalid[N_SLAVES]),
        .wready  (wp_s_wready[N_SLAVES]),
        .wdata   (wp_s_wdata_flat[N_SLAVES*DATA_W +: DATA_W]),
        .wstrb   (wp_s_wstrb_flat[N_SLAVES*STRB_W +: STRB_W]),
        .wlast   (wp_s_wlast[N_SLAVES]),
        // B
        .bvalid  (wp_s_bvalid[N_SLAVES]),
        .bready  (wp_s_bready[N_SLAVES]),
        .bid     (wp_s_bid_flat[N_SLAVES*SID_W +: SID_W]),
        .bresp   (wp_s_bresp_flat[N_SLAVES*2 +: 2]),
        // AR
        .arvalid (rp_s_arvalid[N_SLAVES]),
        .arready (rp_s_arready[N_SLAVES]),
        .arid    (rp_s_arid_flat[N_SLAVES*SID_W +: SID_W]),
        .araddr  (rp_s_araddr_flat[N_SLAVES*ADDR_W +: ADDR_W]),
        .arlen   (rp_s_arlen_flat[N_SLAVES*8 +: 8]),
        .arsize  (rp_s_arsize_flat[N_SLAVES*3 +: 3]),
        .arburst (rp_s_arburst_flat[N_SLAVES*2 +: 2]),
        // R
        .rvalid  (rp_s_rvalid[N_SLAVES]),
        .rready  (rp_s_rready[N_SLAVES]),
        .rid     (rp_s_rid_flat[N_SLAVES*SID_W +: SID_W]),
        .rdata   (rp_s_rdata_flat[N_SLAVES*DATA_W +: DATA_W]),
        .rresp   (rp_s_rresp_flat[N_SLAVES*2 +: 2]),
        .rlast   (rp_s_rlast[N_SLAVES])
    );

    // ---- Connect real slaves (index 0..N_SLAVES-1) to external ports ----
    genvar gi;
    generate
        for (gi = 0; gi < N_SLAVES; gi = gi + 1) begin : gen_slave_connect
            // Write AW
            assign s_awvalid[gi]                          = wp_s_awvalid[gi];
            assign wp_s_awready[gi]                       = s_awready[gi];
            assign s_awid_flat[gi*SID_W +: SID_W]         = wp_s_awid_flat[gi*SID_W +: SID_W];
            assign s_awaddr_flat[gi*ADDR_W +: ADDR_W]     = wp_s_awaddr_flat[gi*ADDR_W +: ADDR_W];
            assign s_awlen_flat[gi*8 +: 8]                = wp_s_awlen_flat[gi*8 +: 8];
            assign s_awsize_flat[gi*3 +: 3]               = wp_s_awsize_flat[gi*3 +: 3];
            assign s_awburst_flat[gi*2 +: 2]              = wp_s_awburst_flat[gi*2 +: 2];

            // Write W
            assign s_wvalid[gi]                           = wp_s_wvalid[gi];
            assign wp_s_wready[gi]                        = s_wready[gi];
            assign s_wdata_flat[gi*DATA_W +: DATA_W]      = wp_s_wdata_flat[gi*DATA_W +: DATA_W];
            assign s_wstrb_flat[gi*STRB_W +: STRB_W]      = wp_s_wstrb_flat[gi*STRB_W +: STRB_W];
            assign s_wlast[gi]                            = wp_s_wlast[gi];

            // Write B
            assign wp_s_bvalid[gi]                        = s_bvalid[gi];
            assign s_bready[gi]                           = wp_s_bready[gi];
            assign wp_s_bid_flat[gi*SID_W +: SID_W]       = s_bid_flat[gi*SID_W +: SID_W];
            assign wp_s_bresp_flat[gi*2 +: 2]             = s_bresp_flat[gi*2 +: 2];

            // Read AR
            assign s_arvalid[gi]                          = rp_s_arvalid[gi];
            assign rp_s_arready[gi]                       = s_arready[gi];
            assign s_arid_flat[gi*SID_W +: SID_W]         = rp_s_arid_flat[gi*SID_W +: SID_W];
            assign s_araddr_flat[gi*ADDR_W +: ADDR_W]     = rp_s_araddr_flat[gi*ADDR_W +: ADDR_W];
            assign s_arlen_flat[gi*8 +: 8]                = rp_s_arlen_flat[gi*8 +: 8];
            assign s_arsize_flat[gi*3 +: 3]               = rp_s_arsize_flat[gi*3 +: 3];
            assign s_arburst_flat[gi*2 +: 2]              = rp_s_arburst_flat[gi*2 +: 2];

            // Read R
            assign rp_s_rvalid[gi]                        = s_rvalid[gi];
            assign s_rready[gi]                           = rp_s_rready[gi];
            assign rp_s_rid_flat[gi*SID_W +: SID_W]       = s_rid_flat[gi*SID_W +: SID_W];
            assign rp_s_rdata_flat[gi*DATA_W +: DATA_W]   = s_rdata_flat[gi*DATA_W +: DATA_W];
            assign rp_s_rresp_flat[gi*2 +: 2]             = s_rresp_flat[gi*2 +: 2];
            assign rp_s_rlast[gi]                         = s_rlast[gi];
        end
    endgenerate

endmodule
