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

module tmds_encoder (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire       de_i,
    input  wire       d_i,
    output wire [9:0] tmds_o
);

    localparam logic [9:0] C_CTL_00 = 10'b1101010100; // Blanking symbol with neutral disparity
    localparam logic [9:0] C_DAT_10 = 10'b0111110000; // Most black symbol with neutral disparity
    localparam logic [9:0] C_DAT_EF = 10'b1011110000; // Most white symbol with neutral disparity

    logic [9:0] sym_d, sym_q;

    assign sym_d = !de_i ? C_CTL_00 : // Output blanking when de_i == 0
                    d_i  ? C_DAT_EF : // Output white when de_i == 1 && d_i == 1
                           C_DAT_10 ; // Output black when de_i == 1 && d_i == 0

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            sym_q <= 10'b0;
        end else begin
            sym_q <= sym_d;
        end
    end

    // Assign output
    assign tmds_o = sym_q;


endmodule
