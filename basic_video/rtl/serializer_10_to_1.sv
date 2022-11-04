//
//    Copyright (C) 2022  Jakub Hladik
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

`default_nettype none

module serializer_10_to_1 (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire [9:0] d_i,
    output wire       ser_o
);

    logic [3:0] cnt_d, cnt_q;
    logic [9:0] sreg_d, sreg_q;

    // Create a 0-9 counter
    assign cnt_d = cnt_q == 4'd9 ? 4'd0 : cnt_q + 4'd1;

    // Create a shift register which parallel loads after cnt_q is 9
    assign sreg_d = cnt_q == 4'd9 ? d_i : {1'b0, sreg_q[9:1]};

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            cnt_q  <= 4'd0;
            sreg_q <= 10'b0;
        end else begin
            cnt_q  <= cnt_d;
            sreg_q <= sreg_d;
        end
    end

    // Assign output
    assign ser_o = sreg_q[0];


endmodule
