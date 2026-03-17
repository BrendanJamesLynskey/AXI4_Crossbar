// Brendan Lynskey 2025
module axi_arbiter
    import axi_xbar_pkg::*;
#(
    parameter int N_REQ = 2,
    parameter arb_mode_t MODE = ARB_ROUND_ROBIN
)(
    input  logic                    clk,
    input  logic                    srst,
    input  logic [N_REQ-1:0]        req,
    output logic [N_REQ-1:0]        grant,
    output logic [$clog2(N_REQ)-1:0] grant_idx,
    output logic                    grant_valid,
    input  logic                    lock
);

    localparam int IDX_W = $clog2(N_REQ);

    logic [IDX_W-1:0] last_grant;

    always_ff @(posedge clk)
        if (srst)
            last_grant <= '0;
        else if (grant_valid && !lock)
            last_grant <= grant_idx;

    always @(*) begin
        grant       = '0;
        grant_idx   = '0;
        grant_valid = 1'b0;

        if (MODE == ARB_FIXED_PRIO) begin : fixed_prio
            // Fixed priority: lowest index wins
            begin : fp_loop
                integer i;
                for (i = 0; i < N_REQ; i = i + 1) begin
                    if (req[i]) begin
                        grant[i]    = 1'b1;
                        grant_idx   = i[IDX_W-1:0];
                        grant_valid = 1'b1;
                        disable fp_loop;
                    end
                end
            end
        end else begin : round_robin
            // If locked and current grantee still requesting, hold grant
            if (lock && req[last_grant]) begin
                grant[last_grant] = 1'b1;
                grant_idx         = last_grant;
                grant_valid       = 1'b1;
            end else begin
                // Scan from last_grant + 1, wrapping around
                begin : rr_loop
                    integer i;
                    integer idx;
                    for (i = 0; i < N_REQ; i = i + 1) begin
                        idx = (last_grant + 1 + i) % N_REQ;
                        if (req[idx[IDX_W-1:0]]) begin
                            grant[idx[IDX_W-1:0]] = 1'b1;
                            grant_idx              = idx[IDX_W-1:0];
                            grant_valid            = 1'b1;
                            disable rr_loop;
                        end
                    end
                end
            end
        end
    end

endmodule
