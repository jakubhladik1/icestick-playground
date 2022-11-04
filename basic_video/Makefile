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

PROJ = top
PIN_DEF = top.pcf
DEVICE = hx1k
PACKAGE = tq144

all: build/$(PROJ).rpt build/$(PROJ).bin prog

-include build/top.sv.d

build/%.json: rtl/%.sv
	mkdir -p $(@D)
	yosys -q -E build/$*.sv.d -p 'read_verilog -sv $< ; hierarchy -top top -libdir rtl ; synth_ice40 -top top -json $@' 

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 -q --$(DEVICE) --package $(PACKAGE) --asc $@ --pcf $< --json $*.json

build/%.bin: build/%.asc
	icepack $< $@

build/%.rpt: build/%.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: build/$(PROJ).bin
	iceprog $<

sim: build/Vvideo_generator
	PYTHONDONTWRITEBYTECODE=1 MODULE=sim/video_generator_tb TESTCASE= TOPLEVEL=video_generator TOPLEVEL_LANG=verilog build/Vtop
	mv dump.fst build/waveform.fst
	mv coverage.dat build/coverage.dat
	mv results.xml build/results.xml

build/Vvideo_generator: rtl/video_generator.sv
	mkdir -p build
	verilator -cc --build --exe -Mdir build -DCOCOTB_SIM=1 --top-module video_generator --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,`cocotb-config --lib-dir` -L`cocotb-config  --lib-dir` -lcocotbvpi_verilator" --trace-fst --trace-structs --coverage --timescale 1ns/1ps `cocotb-config --share`/lib/verilator/verilator.cpp rtl/video_generator.sv

clean:
	rm -rf build

.SECONDARY:
.PHONY: all prog clean