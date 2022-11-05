#
#    Copyright (C) 2022  Jakub Hladik
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

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
