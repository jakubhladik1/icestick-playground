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
//
// Both the rising edge and falling edge data should be sampled at the rising 
// edge of the serial clock by the DDR register input and outputted at their 
// corresponding edges.
//
//                 ____      ____      ____      ____      ____      ____
// clk_i      ____|    |____|    |____|    |____|    |____|    |____|    |
//
//               0         0         1_________1_________0         0
// ser_re_o   _______________________|                   |_______________
//
//                0         1_________0         0         0         0
// ser_fe_o   ______________|         |___________________________________
//
//                          0    0    0    1____1____0    1____0    0    0
// DDR Output _____________________________|         |____|    |__________
//

`default_nettype none

module serializer_ddr (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire [9:0] d_i,
    output wire       ser_re_o,
    output wire       ser_fe_o
);

    logic [2:0] cnt_d, cnt_q;
    logic [4:0] sreg_re_d, sreg_re_q;
    logic [4:0] sreg_fe_d, sreg_fe_q;

    // Create a 0-9 counter
    assign cnt_d = cnt_q == 3'd4 ? 3'd0 : cnt_q + 3'd1;

    // Create a shift register which parallel loads all even bits (targeted for rising edge DDR
    // output after cnt_q is 4
    assign sreg_re_d = cnt_q == 3'd4 ? {d_i[8], d_i[6], d_i[4], d_i[2], d_i[0]} : 
                                       {1'b0, sreg_re_q[4:1]}                   ;

    // Create a shift register which parallel loads all odd bits (targeted for falling edge DDR
    // output after cnt_q is 4
    assign sreg_fe_d = cnt_q == 3'd4 ? {d_i[9], d_i[7], d_i[5], d_i[3], d_i[1]} : 
                                       {1'b0, sreg_fe_q[4:1]}                   ;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            cnt_q     <= 3'd0;
            sreg_re_q <= 5'b0;
            sreg_fe_q <= 5'b0;
        end else begin
            cnt_q  <= cnt_d;
            sreg_re_q <= sreg_re_d;
            sreg_fe_q <= sreg_fe_d;
        end
    end

    // Assign outputs
    assign ser_re_o = sreg_re_q[0];
    assign ser_fe_o = sreg_fe_q[0];

endmodule
