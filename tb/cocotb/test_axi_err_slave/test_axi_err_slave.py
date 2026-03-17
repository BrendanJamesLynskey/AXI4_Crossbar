# Brendan Lynskey 2025
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge


async def reset(dut):
    dut.srst.value = 1
    dut.awvalid.value = 0
    dut.wvalid.value = 0
    dut.bready.value = 0
    dut.arvalid.value = 0
    dut.rready.value = 0
    dut.awid.value = 0
    dut.awaddr.value = 0
    dut.awlen.value = 0
    dut.awsize.value = 2
    dut.awburst.value = 1
    dut.wdata.value = 0
    dut.wstrb.value = 0xF
    dut.wlast.value = 0
    dut.arid.value = 0
    dut.araddr.value = 0
    dut.arlen.value = 0
    dut.arsize.value = 2
    dut.arburst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.srst.value = 0
    await RisingEdge(dut.clk)


async def do_write(dut, txn_id, burst_len):
    """Perform a write transaction. Returns (bresp, bid)."""
    # AW phase
    dut.awvalid.value = 1
    dut.awid.value = txn_id
    dut.awlen.value = burst_len
    while True:
        await FallingEdge(dut.clk)
        if dut.awready.value == 1:
            await RisingEdge(dut.clk)  # let the handshake register
            break
    dut.awvalid.value = 0

    # W phase
    for i in range(burst_len + 1):
        dut.wvalid.value = 1
        dut.wdata.value = 0xABCD_0000 + i
        dut.wlast.value = 1 if i == burst_len else 0
        while True:
            await FallingEdge(dut.clk)
            if dut.wready.value == 1:
                await RisingEdge(dut.clk)
                break
    dut.wvalid.value = 0
    dut.wlast.value = 0

    # B phase
    dut.bready.value = 1
    while True:
        await FallingEdge(dut.clk)
        if dut.bvalid.value == 1:
            resp = int(dut.bresp.value)
            bid = int(dut.bid.value)
            await RisingEdge(dut.clk)
            break
    dut.bready.value = 0
    return resp, bid


async def do_read(dut, txn_id, burst_len):
    """Perform a read transaction. Returns (beats, rresp, rid)."""
    # AR phase
    dut.arvalid.value = 1
    dut.arid.value = txn_id
    dut.arlen.value = burst_len
    while True:
        await FallingEdge(dut.clk)
        if dut.arready.value == 1:
            await RisingEdge(dut.clk)
            break
    dut.arvalid.value = 0

    # R phase
    dut.rready.value = 1
    beats = 0
    rresp = 0
    rid = 0
    while True:
        await FallingEdge(dut.clk)
        if dut.rvalid.value == 1:
            beats += 1
            rresp = int(dut.rresp.value)
            rid = int(dut.rid.value)
            if dut.rlast.value == 1:
                await RisingEdge(dut.clk)
                break
        await RisingEdge(dut.clk)
    dut.rready.value = 0
    return beats, rresp, rid


@cocotb.test()
async def test_write_decerr(dut):
    """Single write -> DECERR."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    resp, _ = await do_write(dut, 5, 0)
    assert resp == 0b11, f"Expected DECERR (11), got {resp:02b}"


@cocotb.test()
async def test_write_burst_decerr(dut):
    """Burst write -> DECERR."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    resp, _ = await do_write(dut, 7, 3)
    assert resp == 0b11


@cocotb.test()
async def test_read_decerr(dut):
    """Single read -> DECERR."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats, rresp, _ = await do_read(dut, 10, 0)
    assert beats == 1
    assert rresp == 0b11


@cocotb.test()
async def test_read_burst_decerr(dut):
    """Burst read -> DECERR + correct beat count."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    beats, rresp, _ = await do_read(dut, 2, 7)
    assert beats == 8, f"Expected 8 beats, got {beats}"
    assert rresp == 0b11


@cocotb.test()
async def test_id_echo(dut):
    """IDs echoed correctly."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    _, bid = await do_write(dut, 19, 0)
    assert bid == 19, f"Expected bid=19, got {bid}"
    _, _, rid = await do_read(dut, 23, 0)
    assert rid == 23, f"Expected rid=23, got {rid}"


@cocotb.test()
async def test_back_to_back(dut):
    """Sequential transactions without gaps."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    resp1, _ = await do_write(dut, 1, 0)
    resp2, _ = await do_write(dut, 2, 0)
    assert resp1 == 0b11
    assert resp2 == 0b11
    b1, _, _ = await do_read(dut, 3, 0)
    b2, _, _ = await do_read(dut, 4, 0)
    assert b1 == 1 and b2 == 1
