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

TOP_MODULE = video_generator

all: dump.vcd results.xml

build/Vtop: ../../rtl/$(TOP_MODULE).sv
	mkdir -p $(@D)
	verilator -cc --build --exe -Mdir build -DCOCOTB_SIM=1 --top-module $(TOP_MODULE) \
		--vpi --public-flat-rw --prefix Vtop \
		-LDFLAGS \
			"-Wl,-rpath,`cocotb-config --lib-dir` -L`cocotb-config --lib-dir` \
			-lcocotbvpi_verilator -lgpi -lcocotb -lgpilog -lcocotbutils" \
		--trace --trace-structs --timescale 1ns/1ps \
		`cocotb-config --share`/lib/verilator/verilator.cpp $<

%.vcd %.xml: build/Vtop $(TOP_MODULE)_tb.py
	LIBPYTHON_LOC=`cocotb-config --libpython` \
		PYTHONDONTWRITEBYTECODE=1 \
		MODULE=$(TOP_MODULE)_tb \
		TESTCASE= \
		TOPLEVEL=$(TOP_MODULE) \
		TOPLEVEL_LANG=verilog \
		build/Vtop

clean:
	rm -rf build dump.vcd results.xml

.PHONY: all clean
