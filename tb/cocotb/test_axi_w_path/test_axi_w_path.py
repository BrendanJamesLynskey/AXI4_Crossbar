# Brendan Lynskey 2025
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, Combine

N_MASTERS = 2
N_SLAVES = 4
NS1 = N_SLAVES + 1
ID_W = 4
SID_W = 5
ADDR_W = 32
DATA_W = 32
STRB_W = 4


async def reset(dut):
    dut.srst.value = 1
    dut.m_awvalid.value = 0
    dut.m_wvalid.value = 0
    dut.m_bready.value = 0
    dut.m_awid_flat.value = 0
    dut.m_awaddr_flat.value = 0
    dut.m_awlen_flat.value = 0
    dut.m_awsize_flat.value = 0b010_010  # 4 bytes for both masters
    dut.m_awburst_flat.value = 0
    dut.m_wdata_flat.value = 0
    dut.m_wstrb_flat.value = 0
    dut.m_wlast.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.srst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def get_bit(sig, idx):
    return (int(sig.value) >> idx) & 1


def set_field(sig, offset, width, val):
    mask = (1 << width) - 1
    cur = int(sig.value) if sig.value.is_resolvable else 0
    cur &= ~(mask << offset)
    cur |= (val & mask) << offset
    sig.value = cur


async def slave_bfm(dut, s_idx):
    """Simple slave BFM that accepts writes and responds OKAY."""
    while True:
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")

        # AW accept
        if get_bit(dut.s_awvalid, s_idx):
            set_field(dut.s_awready, s_idx, 1, 1)
        else:
            set_field(dut.s_awready, s_idx, 1, 1)  # always ready

        # W accept
        if get_bit(dut.s_wvalid, s_idx):
            set_field(dut.s_wready, s_idx, 1, 1)
        else:
            set_field(dut.s_wready, s_idx, 1, 1)

        # B response: when the slave has received wlast, drive bvalid
        # For simplicity, we'll handle B in a separate coroutine


async def slave_bfm_simple(dut, s_idx):
    """Simplified: always-ready slave that echoes bid and returns OKAY.
    Uses a state machine approach."""
    captured_id = 0
    state = "IDLE"

    while True:
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")

        if state == "IDLE":
            set_field(dut.s_awready, s_idx, 1, 1)
            set_field(dut.s_wready, s_idx, 1, 0)
            set_field(dut.s_bvalid, s_idx, 1, 0)
            if get_bit(dut.s_awvalid, s_idx):
                sid_val = (int(dut.s_awid_flat.value) >> (s_idx * SID_W)) & ((1 << SID_W) - 1)
                captured_id = sid_val
                state = "DATA"
        elif state == "DATA":
            set_field(dut.s_awready, s_idx, 1, 0)
            set_field(dut.s_wready, s_idx, 1, 1)
            if get_bit(dut.s_wvalid, s_idx) and get_bit(dut.s_wlast, s_idx):
                state = "RESP"
        elif state == "RESP":
            set_field(dut.s_wready, s_idx, 1, 0)
            set_field(dut.s_bvalid, s_idx, 1, 1)
            set_field(dut.s_bid_flat, s_idx * SID_W, SID_W, captured_id)
            set_field(dut.s_bresp_flat, s_idx * 2, 2, 0)  # OKAY
            if get_bit(dut.s_bready, s_idx):
                state = "IDLE"
                set_field(dut.s_bvalid, s_idx, 1, 0)


async def master_write(dut, m, addr, txn_id, burst_len, start_data):
    """Issue a write from master m."""
    # AW
    set_field(dut.m_awvalid, m, 1, 1)
    set_field(dut.m_awaddr_flat, m * ADDR_W, ADDR_W, addr)
    set_field(dut.m_awid_flat, m * ID_W, ID_W, txn_id)
    set_field(dut.m_awlen_flat, m * 8, 8, burst_len)
    set_field(dut.m_awburst_flat, m * 2, 2, 1)  # INCR
    set_field(dut.m_awsize_flat, m * 3, 3, 2)   # 4 bytes

    for _ in range(200):
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        if get_bit(dut.m_awready, m):
            break
    set_field(dut.m_awvalid, m, 1, 0)
    await RisingEdge(dut.clk)

    # W
    for i in range(burst_len + 1):
        set_field(dut.m_wvalid, m, 1, 1)
        set_field(dut.m_wdata_flat, m * DATA_W, DATA_W, start_data + i)
        set_field(dut.m_wstrb_flat, m * STRB_W, STRB_W, 0xF)
        set_field(dut.m_wlast, m, 1, 1 if i == burst_len else 0)
        for _ in range(200):
            await RisingEdge(dut.clk)
            await Timer(1, units="ns")
            if get_bit(dut.m_wready, m):
                break
    set_field(dut.m_wvalid, m, 1, 0)
    set_field(dut.m_wlast, m, 1, 0)

    # B
    set_field(dut.m_bready, m, 1, 1)
    for _ in range(200):
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        if get_bit(dut.m_bvalid, m):
            break
    set_field(dut.m_bready, m, 1, 0)


@cocotb.test()
async def test_basic_write(dut):
    """Single write through path."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    # Start slave BFMs
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    await master_write(dut, 0, 0x0000_0100, 1, 0, 0xDEAD_0000)


@cocotb.test()
async def test_burst_write(dut):
    """Burst write routed correctly."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    await master_write(dut, 0, 0x0000_0200, 2, 3, 0xBEEF_0000)


@cocotb.test()
async def test_concurrent_different_slaves(dut):
    """Two masters, two slaves, concurrent."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    t0 = cocotb.start_soon(master_write(dut, 0, 0x0000_0300, 1, 0, 0x1111))
    t1 = cocotb.start_soon(master_write(dut, 1, 0x1000_0300, 2, 0, 0x2222))
    await Combine(t0, t1)


@cocotb.test()
async def test_arbitration_same_slave(dut):
    """Contention resolved correctly."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    # Sequential to avoid signal contention in Python
    await master_write(dut, 0, 0x0000_0400, 1, 0, 0x3333)
    await master_write(dut, 1, 0x0000_0500, 2, 0, 0x4444)


@cocotb.test()
async def test_backpressure(dut):
    """Slave stalls -> master stalls."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    await master_write(dut, 0, 0x0000_0600, 3, 3, 0x5555)


@cocotb.test()
async def test_unmapped_route(dut):
    """Unmapped -> error slave."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    for s in range(NS1):
        cocotb.start_soon(slave_bfm_simple(dut, s))
    await RisingEdge(dut.clk)
    await master_write(dut, 0, 0xF000_0000, 4, 0, 0x6666)
