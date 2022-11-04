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

clean:
	rm -rf build

.SECONDARY:
.PHONY: all prog clean