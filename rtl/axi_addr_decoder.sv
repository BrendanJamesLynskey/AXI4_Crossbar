// Brendan Lynskey 2025
module axi_addr_decoder
    import axi_xbar_pkg::*;
(
    input  logic [ADDR_W-1:0]             addr,
    output logic [$clog2(N_SLAVES+1)-1:0] slave_idx,
    output logic                          addr_valid
);

    localparam int SIDX_W = $clog2(N_SLAVES+1);

    always @(*) begin
        slave_idx  = N_SLAVES[SIDX_W-1:0]; // default: error slave
        addr_valid = 1'b0;
        begin : decode_loop
            integer i;
            for (i = 0; i < N_SLAVES; i = i + 1) begin
                if ((addr & ~SLAVE_MASK_FLAT[i*ADDR_W +: ADDR_W]) == SLAVE_BASE_FLAT[i*ADDR_W +: ADDR_W]) begin
                    slave_idx  = i[SIDX_W-1:0];
                    addr_valid = 1'b1;
                    disable decode_loop;
                end
            end
        end
    end

endmodule
