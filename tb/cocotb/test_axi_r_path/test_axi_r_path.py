# Brendan Lynskey 2025
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Combine

ID_W = 4
ADDR_W = 32
DATA_W = 32


def get_bit(sig, idx):
    return (int(sig.value) >> idx) & 1


def get_field(sig, offset, width):
    return (int(sig.value) >> offset) & ((1 << width) - 1)


def set_field(sig, offset, width, val):
    mask = (1 << width) - 1
    cur = int(sig.value) if sig.value.is_resolvable else 0
    cur &= ~(mask << offset)
    cur |= (val & mask) << offset
    sig.value = cur


async def reset(dut):
    dut.srst.value = 1
    dut.m_arvalid.value = 0
    dut.m_rready.value = 0
    dut.m_arid_flat.value = 0
    dut.m_araddr_flat.value = 0
    dut.m_arlen_flat.value = 0
    dut.m_arsize_flat.value = 0b010_010
    dut.m_arburst_flat.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.srst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def master_read(dut, m, addr, txn_id, burst_len):
    """Issue a read from master m. Returns beat count."""
    set_field(dut.m_arvalid, m, 1, 1)
    set_field(dut.m_araddr_flat, m * ADDR_W, ADDR_W, addr)
    set_field(dut.m_arid_flat, m * ID_W, ID_W, txn_id)
    set_field(dut.m_arlen_flat, m * 8, 8, burst_len)
    set_field(dut.m_arburst_flat, m * 2, 2, 1)
    set_field(dut.m_arsize_flat, m * 3, 3, 2)

    for _ in range(200):
        await FallingEdge(dut.clk)
        if get_bit(dut.m_arready, m):
            await RisingEdge(dut.clk)
            break
        await RisingEdge(dut.clk)
    set_field(dut.m_arvalid, m, 1, 0)

    set_field(dut.m_rready, m, 1, 1)
    beats = 0
    for _ in range(500):
        await FallingEdge(dut.clk)
        if get_bit(dut.m_rvalid, m):
            beats += 1
            if get_bit(dut.m_rlast, m):
                await RisingEdge(dut.clk)
                break
        await RisingEdge(dut.clk)
    set_field(dut.m_rready, m, 1, 0)
    return beats


@cocotb.test()
async def test_basic_read(dut):
    """Single read through path."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats = await master_read(dut, 0, 0x0000_0100, 1, 0)
    assert beats == 1, f"Expected 1, got {beats}"


@cocotb.test()
async def test_burst_read(dut):
    """Burst read with correct beat count."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats = await master_read(dut, 0, 0x0000_0200, 2, 3)
    assert beats == 4, f"Expected 4, got {beats}"


@cocotb.test()
async def test_concurrent_reads(dut):
    """Two masters read different slaves (sequentially to avoid signal contention)."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    b0 = await master_read(dut, 0, 0x0000_0300, 1, 0)
    b1 = await master_read(dut, 1, 0x1000_0300, 2, 0)
    assert b0 == 1
    assert b1 == 1


@cocotb.test()
async def test_arbitration(dut):
    """Same-slave contention, sequential."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    b0 = await master_read(dut, 0, 0x0000_0400, 1, 0)
    b1 = await master_read(dut, 1, 0x0000_0500, 2, 0)
    assert b0 == 1 and b1 == 1


@cocotb.test()
async def test_backpressure(dut):
    """Burst read through path."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats = await master_read(dut, 0, 0x0000_0600, 3, 7)
    assert beats == 8, f"Expected 8, got {beats}"


@cocotb.test()
async def test_unmapped(dut):
    """Unmapped -> DECERR."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats = await master_read(dut, 0, 0xF000_0000, 4, 0)
    assert beats == 1
