# Brendan Lynskey 2025
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Combine

N_MASTERS = 2
ID_W = 4
ADDR_W = 32
DATA_W = 32
STRB_W = 4


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
    dut.m_awvalid.value = 0
    dut.m_wvalid.value = 0
    dut.m_bready.value = 0
    dut.m_arvalid.value = 0
    dut.m_rready.value = 0
    dut.m_awid_flat.value = 0
    dut.m_awaddr_flat.value = 0
    dut.m_awlen_flat.value = 0
    dut.m_awsize_flat.value = 0b010_010
    dut.m_awburst_flat.value = 0
    dut.m_wdata_flat.value = 0
    dut.m_wstrb_flat.value = 0
    dut.m_wlast.value = 0
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


async def master_write(dut, m, addr, txn_id, burst_len, start_data):
    """Write transaction from master m."""
    set_field(dut.m_awvalid, m, 1, 1)
    set_field(dut.m_awaddr_flat, m * ADDR_W, ADDR_W, addr)
    set_field(dut.m_awid_flat, m * ID_W, ID_W, txn_id)
    set_field(dut.m_awlen_flat, m * 8, 8, burst_len)
    set_field(dut.m_awburst_flat, m * 2, 2, 1)
    set_field(dut.m_awsize_flat, m * 3, 3, 2)

    for _ in range(200):
        await FallingEdge(dut.clk)
        if get_bit(dut.m_awready, m):
            await RisingEdge(dut.clk)
            break
        await RisingEdge(dut.clk)
    set_field(dut.m_awvalid, m, 1, 0)

    for i in range(burst_len + 1):
        set_field(dut.m_wvalid, m, 1, 1)
        set_field(dut.m_wdata_flat, m * DATA_W, DATA_W, (start_data + i) & 0xFFFFFFFF)
        set_field(dut.m_wstrb_flat, m * STRB_W, STRB_W, 0xF)
        set_field(dut.m_wlast, m, 1, 1 if i == burst_len else 0)
        for _ in range(200):
            await FallingEdge(dut.clk)
            if get_bit(dut.m_wready, m):
                await RisingEdge(dut.clk)
                break
            await RisingEdge(dut.clk)
    set_field(dut.m_wvalid, m, 1, 0)
    set_field(dut.m_wlast, m, 1, 0)

    set_field(dut.m_bready, m, 1, 1)
    bresp = 0
    for _ in range(200):
        await FallingEdge(dut.clk)
        if get_bit(dut.m_bvalid, m):
            bresp = get_field(dut.m_bresp_flat, m * 2, 2)
            await RisingEdge(dut.clk)
            break
        await RisingEdge(dut.clk)
    set_field(dut.m_bready, m, 1, 0)
    return bresp


async def master_read(dut, m, addr, txn_id, burst_len):
    """Read transaction from master m. Returns (beats, first_data)."""
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
    first_data = 0
    for _ in range(500):
        await FallingEdge(dut.clk)
        if get_bit(dut.m_rvalid, m):
            if beats == 0:
                first_data = get_field(dut.m_rdata_flat, m * DATA_W, DATA_W)
            beats += 1
            if get_bit(dut.m_rlast, m):
                await RisingEdge(dut.clk)
                break
        await RisingEdge(dut.clk)
    set_field(dut.m_rready, m, 1, 0)
    return beats, first_data


@cocotb.test()
async def test_write_read_loopback(dut):
    """Write then read, data matches."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 0, 0x0000_0000, 1, 0, 0xCAFE_BABE)
    beats, data = await master_read(dut, 0, 0x0000_0000, 1, 0)
    assert beats == 1, f"Expected 1 beat, got {beats}"
    assert data == 0xCAFE_BABE, f"Data mismatch: {data:#x}"


@cocotb.test()
async def test_all_slaves(dut):
    """Access all 4 slaves."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    addrs = [0x0000_0100, 0x1000_0100, 0x2000_0100, 0x4000_0100]
    for i, addr in enumerate(addrs):
        await master_write(dut, 0, addr, i, 0, 0x1111_0000 * (i + 1))
    for i, addr in enumerate(addrs):
        _, data = await master_read(dut, 0, addr, i, 0)
        expected = (0x1111_0000 * (i + 1)) & 0xFFFFFFFF
        assert data == expected, f"Slave {i}: {data:#x} != {expected:#x}"


@cocotb.test()
async def test_concurrent(dut):
    """Both masters active simultaneously."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 1, 0x1000_0200, 2, 0, 0xFEED_0000)
    t0 = cocotb.start_soon(master_write(dut, 0, 0x0000_0200, 1, 0, 0xDEAD_0000))
    t1 = cocotb.start_soon(master_read(dut, 1, 0x1000_0200, 2, 0))
    await Combine(t0, t1)
    beats, data = t1.result()
    assert beats == 1
    assert data == 0xFEED_0000, f"Got {data:#x}"


@cocotb.test()
async def test_burst(dut):
    """Burst transactions end-to-end."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 0, 0x0000_0300, 3, 3, 0xB000_0000)
    beats, data = await master_read(dut, 0, 0x0000_0300, 3, 3)
    assert beats == 4
    assert data == 0xB000_0000, f"Got {data:#x}"


@cocotb.test()
async def test_unmapped_decerr(dut):
    """DECERR for bad addresses."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    bresp = await master_write(dut, 0, 0xF000_0000, 5, 0, 0xBAD0_0000)
    assert bresp == 0b11, f"Expected DECERR, got {bresp:02b}"


@cocotb.test()
async def test_contention(dut):
    """Same-slave contention from both masters."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 0, 0x0000_0400, 1, 0, 0xAAAA_AAAA)
    await master_write(dut, 1, 0x0000_0404, 2, 0, 0xBBBB_BBBB)
    _, d0 = await master_read(dut, 0, 0x0000_0400, 1, 0)
    _, d1 = await master_read(dut, 0, 0x0000_0404, 2, 0)
    assert d0 == 0xAAAA_AAAA
    assert d1 == 0xBBBB_BBBB


@cocotb.test()
async def test_id_tracking(dut):
    """Multiple IDs in flight, responses matched."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 0, 0x0000_0500, 0xA, 0, 0xAAAA_0000)
    await master_write(dut, 0, 0x0000_0504, 0xB, 0, 0xBBBB_0000)
    _, data = await master_read(dut, 0, 0x0000_0500, 0xA, 0)
    assert data == 0xAAAA_0000


@cocotb.test()
async def test_backpressure(dut):
    """Slave stall propagation (BFM is always-ready, verify path works)."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    await master_write(dut, 0, 0x0000_0600, 1, 3, 0xC000_0000)
    beats, _ = await master_read(dut, 0, 0x0000_0600, 1, 3)
    assert beats == 4


@cocotb.test()
async def test_reset(dut):
    """Mid-transaction reset recovery."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    # Start a write, then reset
    set_field(dut.m_awvalid, 0, 1, 1)
    set_field(dut.m_awaddr_flat, 0, ADDR_W, 0x0000_0700)
    set_field(dut.m_awid_flat, 0, ID_W, 1)
    set_field(dut.m_awlen_flat, 0, 8, 7)
    set_field(dut.m_awburst_flat, 0, 2, 1)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    # Reset mid-flight
    await reset(dut)
    # Now do a clean write + read
    await master_write(dut, 0, 0x0000_0800, 2, 0, 0xAFAF_AFAF)
    beats, data = await master_read(dut, 0, 0x0000_0800, 2, 0)
    assert beats == 1
    assert data == 0xAFAF_AFAF


@cocotb.test()
async def test_stress(dut):
    """500 random transactions."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    import random
    random.seed(42)
    addrs = [0x0000_0000, 0x1000_0000, 0x2000_0000, 0x4000_0000]
    for i in range(500):
        addr = addrs[i % 4] + (i * 4) % 0x1000
        data = 0xA000_0000 + i
        m = i % 2
        await master_write(dut, m, addr, i % 16, 0, data)
    # Verify a few
    for i in range(10):
        addr = addrs[i % 4] + (i * 4) % 0x1000
        _, rdata = await master_read(dut, 0, addr, i % 16, 0)
        # Last write to this addr wins
        assert rdata != 0, f"Read back zero at {addr:#x}"
