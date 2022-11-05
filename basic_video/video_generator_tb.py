import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

@cocotb.test()
async def test_video_generator(dut):
    
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())
    dut.rst_i.value = 1
    await ClockCycles(dut.clk_i, 4, rising=True)
    dut.rst_i.value = 0
    await FallingEdge(dut.den_o)
    await FallingEdge(dut.den_o)
    await FallingEdge(dut.den_o)
    await FallingEdge(dut.den_o)
    await FallingEdge(dut.den_o)
    await FallingEdge(dut.den_o)
