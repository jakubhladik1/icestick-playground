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

all: $(PROJ).rpt $(PROJ).bin

-include top.sv.d

%.json: %.sv
	yosys -q -E $*.sv.d -p 'read_verilog -sv $< ; hierarchy -top top -libdir . ; synth_ice40 -top top -json $@' 

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 -q --$(DEVICE) --package $(PACKAGE) --asc $@ --pcf $< --json $*.json

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.sv %.sv
	iverilog -o $@ $^

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.sv: %.json
	yosys -p 'read_json $^; write_verilog $@'

%_syntb: %_tb.sv %_syn.sv
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

sim: $(PROJ)_tb.vcd

postsim: $(PROJ)_syntb.vcd

prog: $(PROJ).bin
	iceprog $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).sv.d

.SECONDARY:
.PHONY: all prog clean