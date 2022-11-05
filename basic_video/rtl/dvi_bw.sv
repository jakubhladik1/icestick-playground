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

module dvi_bw (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic       de_i,
    input  logic       dat_i,
    output logic       ce_o,
    output logic [3:0] tmds_re_o,
    output logic [3:0] tmds_fe_o
);

    localparam logic [9:0] C_CTL_00 = 10'b1101010100; // Blanking symbol with neutral disparity
    localparam logic [9:0] C_DAT_10 = 10'b0111110000; // Most black symbol with neutral disparity
    localparam logic [9:0] C_DAT_EF = 10'b1011110000; // Most white symbol with neutral disparity
    localparam logic [9:0] C_CLK    = 10'b1111100000; // Clock pattern

    logic [9:0] sym_d        , sym_q       ;
    logic [2:0] cnt_d        , cnt_q       ;
    logic       ld_d         , ld_q        ;
    logic [4:0] shr_dat_re_q , shr_dat_re_d;
    logic [4:0] shr_dat_fe_q , shr_dat_fe_d;
    logic [4:0] shr_clk_re_q , shr_clk_re_d;
    logic [4:0] shr_clk_fe_q , shr_clk_fe_d;

    // Choose symbol to serialize
    assign sym_d = ld_q  ? sym_q    : // Only update when serializer is ready for next symbol
                   !de_i ? C_CTL_00 : // Output blanking when de_i == 0
                   dat_i ? C_DAT_EF : // Output white when de_i == 1 && dat_i == 1
                           C_DAT_10 ; // Output black when de_i == 1 && dat_i == 0

    // Create a 0-4 counter
    assign cnt_d = cnt_q == 3'd4 ? 3'd0 : cnt_q + 3'd1;

    // Generate a registered clock enable which pulses when data is parallel loaded into the shift
    // register
    assign ld_d = cnt_q == 3'd3 ? 1'b1 : 1'b0;

    // Create a shift register for data channels which parallel loads all even bits (targeted for 
    // rising edge DDR output) every clock enable
    assign shr_dat_re_d = ld_q ? {sym_q[8], sym_q[6], sym_q[4], sym_q[2], sym_q[0]} : 
                                 {1'b0, shr_dat_re_q[4:1]}                          ;

    // Create a shift register for data channels which parallel loads all odd bits (targeted for 
    // falling edge DDR output) every clock enable
    assign shr_dat_fe_d = ld_q ? {sym_q[9], sym_q[7], sym_q[5], sym_q[3], sym_q[1]} : 
                                 {1'b0, shr_dat_fe_q[4:1]}                          ;


    // Create a shift register for clock channel which parallel loads all even bits (targeted for 
    // rising edge DDR output) every clock enable
    assign shr_clk_re_d = cnt_q == 3'd4 ? {C_CLK[8], C_CLK[6], C_CLK[4], C_CLK[2], C_CLK[0]} : 
                                          {1'b0, shr_clk_re_q[4:1]}                          ;

    // Create a shift register for clock channels which parallel loads all odd bits (targeted for 
    // falling edge DDR output) every clock enable
    assign shr_clk_fe_d = cnt_q == 3'd4 ? {C_CLK[9], C_CLK[7], C_CLK[5], C_CLK[3], C_CLK[1]} : 
                                          {1'b0, shr_clk_fe_q[4:1]}                          ;
    
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            sym_q        <= 10'b0;
            cnt_q        <= 3'd0;
            ld_q         <= 1'b0;
            shr_dat_re_q <= 5'b0;
            shr_dat_fe_q <= 5'b0;
            shr_clk_re_q <= 5'b0;
            shr_clk_fe_q <= 5'b0;
        end else begin
            sym_q <= sym_d;
            cnt_q        <= cnt_d;
            ld_q         <= ld_d;
            shr_dat_re_q <= shr_dat_re_d;
            shr_dat_fe_q <= shr_dat_fe_d;
            shr_clk_re_q <= shr_clk_re_d;
            shr_clk_fe_q <= shr_clk_fe_d;

        end
    end

    // Assign outputs
    assign ce_o         = ld_q; 
    assign tmds_re_o[0] = shr_dat_re_q[0];
    assign tmds_re_o[1] = shr_dat_re_q[0];
    assign tmds_re_o[2] = shr_dat_re_q[0];
    assign tmds_re_o[3] = shr_clk_re_q[0];
    assign tmds_fe_o[0] = shr_dat_fe_q[0];
    assign tmds_fe_o[1] = shr_dat_fe_q[0];
    assign tmds_fe_o[2] = shr_dat_fe_q[0];
    assign tmds_fe_o[3] = shr_clk_fe_q[0];

endmodule
