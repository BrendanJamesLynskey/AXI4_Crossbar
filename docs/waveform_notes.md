<!-- Brendan Lynskey 2025 -->
# Waveform Notes — Key Signals to Probe

## General
- `clk`, `srst` — clock and synchronous reset

## Master-side (per master m)
- `m_awvalid[m]`, `m_awready[m]` — AW handshake
- `m_awaddr_flat[m*32 +: 32]` — write address
- `m_wvalid[m]`, `m_wready[m]`, `m_wlast[m]` — W handshake
- `m_bvalid[m]`, `m_bready[m]` — B handshake
- `m_bresp_flat[m*2 +: 2]` — write response (00=OKAY, 11=DECERR)
- `m_arvalid[m]`, `m_arready[m]` — AR handshake
- `m_rvalid[m]`, `m_rready[m]`, `m_rlast[m]` — R handshake
- `m_rdata_flat[m*32 +: 32]` — read data

## Write Path Internals (axi_w_path)
- `w_state_flat[m*2 +: 2]` — per-master write state (00=IDLE, 01=ADDR, 10=DATA, 11=RESP)
- `w_route_flat[m*3 +: 3]` — which slave this master is writing to
- `aw_lock` — per-slave lock (prevents new AW grants during W burst)
- `aw_grant_valid` — per-slave arbiter grant active

## Read Path Internals (axi_r_path)
- `ar_grant_valid` — per-slave arbiter grant active

## Slave-side (per slave s)
- `s_awvalid[s]`, `s_awready[s]` — slave AW handshake
- `s_awid_flat[s*5 +: 5]` — extended ID (upper bit = master index)
- `s_wvalid[s]`, `s_wready[s]` — slave W handshake
- `s_bvalid[s]`, `s_bready[s]` — slave B handshake
- `s_bid_flat[s*5 +: 5]` — response ID with master index

## Error Slave
- `u_err_slave.w_state` — write FSM (IDLE/DATA/RESP)
- `u_err_slave.r_state` — read FSM (IDLE/DATA)
- `u_err_slave.r_cnt` — read beat counter

## Debugging Tips
1. **Transaction stuck**: Check if arbiter is locked (`aw_lock`) — a previous master's W burst may not have completed
2. **Wrong slave**: Check `decoded_slave_flat` output of address decoders
3. **Missing response**: Check `s_bvalid`/`s_rvalid` and ID upper bits for correct master routing
4. **Data mismatch**: Verify `s_awsize` was captured correctly by slave BFM
