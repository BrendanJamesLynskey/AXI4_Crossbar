<!-- Brendan Lynskey 2025 -->
# AXI4 Crossbar Interconnect

A fully synthesisable, parameterised AXI4 crossbar interconnect written in SystemVerilog. Designed as the central on-chip fabric for a RISC-V SoC, connecting multiple AXI4 masters (CPU, DMA, GPU) to multiple AXI4 slaves (memory controller, peripherals, GPIO) with independent read and write routing.

## Features

- **Parameterised geometry** — configurable master count (default 2) and slave count (default 4)
- **Full AXI4 protocol** — all five channels: AW, W, B, AR, R
- **Independent read/write paths** — simultaneous read and write transactions without blocking
- **Per-slave arbitration** — round-robin (default) or fixed-priority, one arbiter per slave endpoint
- **Outstanding transaction support** — multiple in-flight transactions per master via ID field extension
- **Write path locking** — write data channel locked to granted master until `WLAST` (no write interleaving)
- **ID-based response routing** — master index prepended to transaction IDs; responses routed back without lookup tables
- **Error slave** — unmapped addresses receive `DECERR` responses with correct beat counts
- **Full backpressure propagation** — slave stalls propagate to the requesting master without cross-blocking other paths
- **Single clock domain** — synchronous active-high reset (`srst`)

## Architecture

```
                 Master 0          Master 1
                   │  │              │  │
                  AW  AR            AW  AR
                   │  │              │  │
         ┌─────────┴──┴──────────────┴──┴─────────┐
         │            axi_xbar_top                 │
         │                                         │
         │  ┌───────────────┐  ┌───────────────┐   │
         │  │  axi_w_path   │  │  axi_r_path   │   │
         │  │               │  │               │   │
         │  │ ┌───────────┐ │  │ ┌───────────┐ │   │
         │  │ │ AW Demux  │ │  │ │ AR Demux  │ │   │
         │  │ │ + Arbiter │ │  │ │ + Arbiter │ │   │
         │  │ │ per slave │ │  │ │ per slave │ │   │
         │  │ └─────┬─────┘ │  │ └─────┬─────┘ │   │
         │  │       │       │  │       │       │   │
         │  │ ┌─────┴─────┐ │  │       │       │   │
         │  │ │ W Switch  │ │  │       │       │   │
         │  │ │ (locked   │ │  │       │       │   │
         │  │ │ per burst)│ │  │       │       │   │
         │  │ └─────┬─────┘ │  │       │       │   │
         │  │       │       │  │       │       │   │
         │  │ ┌─────┴─────┐ │  │ ┌─────┴─────┐ │   │
         │  │ │ B Return  │ │  │ │ R Return  │ │   │
         │  │ │ Mux (by   │ │  │ │ Mux (by   │ │   │
         │  │ │ ID bits)  │ │  │ │ ID bits)  │ │   │
         │  │ └───────────┘ │  │ └───────────┘ │   │
         │  └───────┬───────┘  └───────┬───────┘   │
         │          │                  │           │
         │     ┌────┴────┐        ┌────┴────┐      │
         │     │err_slave│        │err_slave│      │
         │     └─────────┘        └─────────┘      │
         └────────┬──┬──────────────┬──┬───────────┘
                 AW  AR            AW  AR
                  │  │              │  │
               Slave 0 .. 3     Slave 0 .. 3
```

### ID Width Extension

Transaction IDs are extended on the slave side by prepending the master index. This enables response routing without any lookup tables:

```
Master-side ID:  [ID_W-1 : 0]                       → 4 bits (default)
Slave-side ID:   [MSTR_IDX_W + ID_W - 1 : 0]        → 5 bits (2 masters)

Slave-side ID = { master_index, original_id }
```

## Module Hierarchy

```
axi_xbar_top                  Top-level crossbar
├── axi_xbar_pkg              Parameters, types, address map
├── axi_addr_decoder          Combinational address → slave index decoder
├── axi_arbiter               N-input round-robin / fixed-priority arbiter
├── axi_w_path                Write routing: AW demux, W switch, B return mux
│   ├── axi_addr_decoder ×N   Per-master address decode
│   ├── axi_arbiter ×(S+1)    Per-slave arbitration (including error slave)
│   └── axi_err_slave         DECERR for unmapped write addresses
├── axi_r_path                Read routing: AR demux, R return mux
│   ├── axi_addr_decoder ×N   Per-master address decode
│   ├── axi_arbiter ×(S+1)    Per-slave arbitration (including error slave)
│   └── axi_err_slave         DECERR for unmapped read addresses
└── axi_err_slave             Generates DECERR + sinks data for unmapped regions
```

## Default Address Map

| Slave | Base Address | Mask | Size | Description |
|-------|-------------|------|------|-------------|
| 0 | `0x0000_0000` | `0x0FFF_FFFF` | 256 MB | Boot ROM / SRAM |
| 1 | `0x1000_0000` | `0x0FFF_FFFF` | 256 MB | Peripheral bus |
| 2 | `0x2000_0000` | `0x1FFF_FFFF` | 512 MB | External memory controller |
| 3 | `0x4000_0000` | `0x3FFF_FFFF` | 1 GB | GPIO / misc |

Decode rule: slave `i` matches when `(addr & ~SLAVE_MASK[i]) == SLAVE_BASE[i]`. Unmapped addresses route to the internal error slave.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N_MASTERS` | 2 | Number of AXI4 master ports |
| `N_SLAVES` | 4 | Number of AXI4 slave ports |
| `ADDR_W` | 32 | Address width (bits) |
| `DATA_W` | 32 | Data width (bits) |
| `ID_W` | 4 | Master-side transaction ID width |
| `SID_W` | `ID_W + $clog2(N_MASTERS)` | Slave-side ID width (auto-computed) |

## Getting Started

### Prerequisites

- [Icarus Verilog](http://iverilog.icarus.com/) >= 10.0 with `-g2012` support
- [GTKWave](http://gtkwave.sourceforge.net/) (waveform viewing)
- Python 3.8+
- [cocotb](https://docs.cocotb.org/) (`pip install cocotb`)

### Run all tests

```bash
./scripts/run_all.sh
```

### Run SystemVerilog testbenches only

```bash
./scripts/run_sv_tests.sh
```

### Run CocoTB tests only

```bash
./scripts/run_cocotb_tests.sh
```

### Run a single module's tests

```bash
# SV testbench
iverilog -g2012 -o sim.vvp rtl/axi_xbar_pkg.sv rtl/axi_arbiter.sv tb/sv/tb_axi_arbiter.sv
vvp sim.vvp

# CocoTB
cd tb/cocotb/test_axi_arbiter && make SIM=icarus
```

### Viewing waveforms

Every testbench dumps a `.vcd` file. Open with GTKWave:

```bash
gtkwave tb_axi_arbiter.vcd
```

See [docs/waveform_notes.md](docs/waveform_notes.md) for key signals to probe.

## Verification

109 tests across SystemVerilog self-checking testbenches and CocoTB:

| Module | SV Tests | CocoTB Tests | Total |
|--------|----------|-------------|-------|
| `axi_addr_decoder` | 10 | 6 | 16 |
| `axi_arbiter` | 12 | 7 | 19 |
| `axi_err_slave` | 10 | 6 | 16 |
| `axi_w_path` | 12 | 6 | 18 |
| `axi_r_path` | 10 | 6 | 16 |
| `axi_xbar_top` | 14 | 10 | 24 |
| **Total** | **68** | **41** | **109** |

Tests cover: basic functionality, burst transfers (1–256 beats), arbitration fairness, write path locking, ID extension and stripping, backpressure propagation, cross-blocking absence, unmapped address DECERR, reset recovery, and random stress traffic.

## File Structure

```
AXI4_Crossbar/
├── rtl/
│   ├── axi_xbar_pkg.sv          # Package: parameters, types, address map
│   ├── axi_addr_decoder.sv      # Address → slave index (combinational)
│   ├── axi_arbiter.sv           # Round-robin / fixed-priority arbiter
│   ├── axi_err_slave.sv         # DECERR generator for unmapped addresses
│   ├── axi_w_path.sv            # Write path: AW demux, W switch, B mux
│   ├── axi_r_path.sv            # Read path: AR demux, R mux
│   └── axi_xbar_top.sv          # Top-level integration
├── tb/
│   ├── sv/                      # SystemVerilog self-checking testbenches
│   │   ├── axi_slave_bfm.sv     # AXI4 slave behavioural model
│   │   └── tb_*.sv              # Per-module testbenches
│   └── cocotb/                  # CocoTB Python testbenches
│       └── test_*/              # Per-module test directories with Makefiles
├── scripts/
│   ├── run_sv_tests.sh
│   ├── run_cocotb_tests.sh
│   └── run_all.sh
└── docs/
    ├── axi_xbar_architecture.md # Detailed technical report
    └── waveform_notes.md        # GTKWave signal guide
```

## Coding Conventions

- SystemVerilog targeting `iverilog -g2012` — no vendor primitives
- Synchronous active-high reset (`srst`), first branch in every `always_ff`
- `always @(*)` for combinational blocks reading submodule outputs (iverilog compatibility)
- `valid`/`ready` handshake on all interfaces (AXI4 protocol)
- `snake_case` naming throughout
- ANSI-style port declarations, one signal per line

## Design Documentation

- [Architecture Report](docs/axi_xbar_architecture.md) — block diagrams, microarchitecture details, and design rationale
- [Waveform Notes](docs/waveform_notes.md) — key signals for debugging in GTKWave

## License

MIT
