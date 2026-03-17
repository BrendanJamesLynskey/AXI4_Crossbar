# Brendan Lynskey 2025
import cocotb
from cocotb.triggers import Timer


async def set_addr(dut, addr):
    dut.addr.value = addr
    await Timer(1, units="ns")


@cocotb.test()
async def test_each_slave_base(dut):
    """Hit base address of each slave."""
    bases = [0x0000_0000, 0x1000_0000, 0x2000_0000, 0x4000_0000]
    for i, base in enumerate(bases):
        await set_addr(dut, base)
        assert dut.slave_idx.value == i, f"Base {base:#x}: got idx={dut.slave_idx.value}, expected {i}"
        assert dut.addr_valid.value == 1


@cocotb.test()
async def test_each_slave_end(dut):
    """Hit top address of each slave."""
    tops = [0x0FFF_FFFF, 0x1FFF_FFFF, 0x3FFF_FFFF, 0x7FFF_FFFF]
    expected = [0, 1, 2, 3]
    for i, (top, exp) in enumerate(zip(tops, expected)):
        await set_addr(dut, top)
        assert dut.slave_idx.value == exp, f"Top {top:#x}: got idx={dut.slave_idx.value}, expected {exp}"
        assert dut.addr_valid.value == 1


@cocotb.test()
async def test_unmapped(dut):
    """Multiple unmapped addresses."""
    unmapped = [0x8000_0000, 0xA000_0000, 0xC000_0000, 0xFFFF_0000]
    for addr in unmapped:
        await set_addr(dut, addr)
        assert dut.addr_valid.value == 0, f"Addr {addr:#x}: should be unmapped"


@cocotb.test()
async def test_sweep(dut):
    """Sweep through address space at 0x1000_0000 increments."""
    expected_slaves = {
        0x0000_0000: 0, 0x1000_0000: 1, 0x2000_0000: 2, 0x3000_0000: 2,
        0x4000_0000: 3, 0x5000_0000: 3, 0x6000_0000: 3, 0x7000_0000: 3,
        0x8000_0000: None, 0x9000_0000: None, 0xA000_0000: None,
    }
    for addr, exp in expected_slaves.items():
        await set_addr(dut, addr)
        if exp is not None:
            assert dut.addr_valid.value == 1, f"Addr {addr:#x}: expected valid"
            assert dut.slave_idx.value == exp, f"Addr {addr:#x}: got {dut.slave_idx.value}, expected {exp}"
        else:
            assert dut.addr_valid.value == 0, f"Addr {addr:#x}: expected unmapped"


@cocotb.test()
async def test_all_zeros(dut):
    """Address 0x0000_0000."""
    await set_addr(dut, 0x0000_0000)
    assert dut.slave_idx.value == 0
    assert dut.addr_valid.value == 1


@cocotb.test()
async def test_all_ones(dut):
    """Address 0xFFFF_FFFF."""
    await set_addr(dut, 0xFFFF_FFFF)
    assert dut.addr_valid.value == 0
