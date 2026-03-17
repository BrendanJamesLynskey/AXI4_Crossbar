// Brendan Lynskey 2025
package axi_xbar_pkg;

    // Configurable top-level parameters
    parameter int N_MASTERS     = 2;
    parameter int N_SLAVES      = 4;
    parameter int ADDR_W        = 32;
    parameter int DATA_W        = 32;
    parameter int STRB_W        = DATA_W / 8;
    parameter int ID_W          = 4;                           // Master-side ID width
    parameter int SID_W         = ID_W + $clog2(N_MASTERS);   // Slave-side ID width (extended)
    parameter int MSTR_IDX_W    = $clog2(N_MASTERS);           // Bits needed to encode master index

    // Arbiter mode
    typedef enum logic {
        ARB_ROUND_ROBIN = 1'b0,
        ARB_FIXED_PRIO  = 1'b1
    } arb_mode_t;

    // Burst type encoding
    localparam logic [1:0] BURST_FIXED = 2'b00;
    localparam logic [1:0] BURST_INCR  = 2'b01;

    // Response encoding
    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_EXOKAY = 2'b01;
    localparam logic [1:0] RESP_SLVERR = 2'b10;
    localparam logic [1:0] RESP_DECERR = 2'b11;

    // Address map — packed into flat vectors for iverilog compatibility
    // Access: SLAVE_BASE_FLAT[i*ADDR_W +: ADDR_W]
    localparam logic [N_SLAVES*ADDR_W-1:0] SLAVE_BASE_FLAT = {
        32'h4000_0000,   // Slave 3: GPIO / misc
        32'h2000_0000,   // Slave 2: External memory controller
        32'h1000_0000,   // Slave 1: Peripheral bus
        32'h0000_0000    // Slave 0: Boot ROM / SRAM
    };

    localparam logic [N_SLAVES*ADDR_W-1:0] SLAVE_MASK_FLAT = {
        32'h3FFF_FFFF,   // Slave 3: 1 GB
        32'h1FFF_FFFF,   // Slave 2: 512 MB
        32'h0FFF_FFFF,   // Slave 1: 256 MB
        32'h0FFF_FFFF    // Slave 0: 256 MB
    };

endpackage
