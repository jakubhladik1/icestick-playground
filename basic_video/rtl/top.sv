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

module top (
  input  wire       clk_ref_i,
  output wire [3:0] tmds_po,
  output wire [3:0] tmds_no,
  output wire       led_o
);

    logic clk_ser_raw;
    logic clk_ser_locked;
    logic clk_ser;
    logic rst_ser_meta;
    logic rst_ser;
    logic vg_de;
    logic vg_pix;
    logic dvi_ce;
    logic [3:0] tmds_re;
    logic [3:0] tmds_fe;

    // Create clk_ser (124.5 MHz) from clk_ref (12 MHz)
    // From Lattice FPGA-TN-02052:
    //     F_PLLOUT = (F_REFCLK*(DIVF+1))/((2^DIVQ)*(DIVR+1))
    //      124.5 = (12*(82+1))/((2^3)*(0+1))
    // 
    SB_PLL40_CORE #(
        .FEEDBACK_PATH ("SIMPLE"),
        .DIVR          (4'd0),
        .DIVF          (7'd82),
        .DIVQ          (3'd3),
        .FILTER_RANGE  (3'b1)
    ) inst_pll_clk_ser (
        .REFERENCECLK  (clk_ref_i),
        .PLLOUTGLOBAL  (clk_ser_raw),
        .LOCK          (clk_ser_locked),
        .BYPASS        (1'b0),
        .RESETB        (1'b1)
    );

    // Buffer the generated clk_ser
    SB_GB inst_gb_clk_ser (
        .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_ser_raw),
        .GLOBAL_BUFFER_OUTPUT         (clk_ser)
    );

    // Create an asynchronous reset release synchronously with clk_ser from the PLL locked signal
    always_ff @(posedge clk_ser, negedge clk_ser_locked) begin
        if (!clk_ser_locked) begin
            rst_ser_meta <= 1'b1;
            rst_ser      <= 1'b1;
        end else begin
            rst_ser_meta <= ~clk_ser_locked;
            rst_ser      <= rst_ser_meta;
        end
    end

    video_generator #(
        .NumColTotal  (10'd800),
        .NumColActive (10'd640),
        .NumRowTotal  (10'd525),
        .NumRowActive (10'd480)
    ) inst_video_generator (
        .clk_i (clk_ser),
        .rst_i (rst_ser),
        .ce_i  (dvi_ce),
        .de_o  (vg_de),
        .pix_o (vg_pix)
    );

    dvi_bw inst_dvi_bw (
        .clk_i     (clk_ser),
        .rst_i     (rst_ser),
        .de_i      (vg_de),
        .dat_i     (vg_pix),
        .ce_o      (dvi_ce),
        .tmds_re_o (tmds_re),
        .tmds_fe_o (tmds_fe)
    );
    
    // Instantiate four differential output channels using DDR output registers inside SB_IO
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin
            SB_IO #(
                .PIN_TYPE    (6'b010010)
            ) inst_io_tmds_data_p (
                .PACKAGE_PIN (tmds_po[i]),
                .OUTPUT_CLK  (clk_ser),
                .D_OUT_0     (tmds_fe[i]),
                .D_OUT_1     (tmds_re[i])
            );

            SB_IO #(
                .PIN_TYPE    (6'b010010)
            ) inst_io_tmds_data_n (
                .PACKAGE_PIN (tmds_no[i]),
                .OUTPUT_CLK  (clk_ser),
                .D_OUT_0     (~tmds_fe[i]),
                .D_OUT_1     (~tmds_re[i])
            );
        end
    endgenerate

    // Assign outputs
    assign led_o = ~rst_ser;

endmodule
