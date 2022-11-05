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
  output wire [2:0] tmds_data_po,
  output wire [2:0] tmds_data_no,
  output wire       tmds_clk_po,
  output wire       tmds_clk_no,
  output wire       led_o
);

    logic clk_ser_raw;
    logic clk_ser_locked;
    logic clk_ser;
    logic rst_ser;
    logic [2:0] cnt_q, cnt_d;
    logic clk_pxl_d, clk_pxl_q;
    logic clk_pxl;
    logic rst_pxl;
    logic vg_den;
    logic vg_pix;
    logic [9:0] pix_tmds;
    logic pix_ser_re;
    logic pix_ser_fe;
    logic ser_rdy;
    logic clk_ser_re;
    logic clk_ser_fe;

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
    synchronizer #(
        .InitialValue (1'b1),
        .NumStages    (2)
    ) inst_synchronizer_rst_ser (
        .clk_i (clk_ser),
        .rst_i (~clk_ser_locked),
        .sig_i (~clk_ser_locked),
        .sig_o (rst_ser)
    );

    // There are no more PLL to use, create clk_pxl by dividing the ser_clk by 10
    assign cnt_d = (cnt_q == 3'd4) ? 3'd0 : cnt_q + 3'd1;

    assign clk_pxl_d = (cnt_q == 3'd0) ? 1'b1 :
                       (cnt_q == 3'd4) ? 1'b0 :
                       clk_pxl_q              ;

    always_ff @(posedge clk_ser, posedge rst_ser) begin
        if (rst_ser) begin
            cnt_q     <= 3'b0;
            clk_pxl_q <= 1'b1;
        end else begin
            cnt_q     <= cnt_d;
            clk_pxl_q <= clk_pxl_d;
        end
    end

    // Buffer the generated clk_pxl
    SB_GB inst_gb_clk_pxl (
        .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_pxl_q),
        .GLOBAL_BUFFER_OUTPUT         (clk_pxl)
    );

    // Create an asynchronous reset release synchronously with clk_pxl from the PLL locked signal
    synchronizer #(
        .InitialValue (1'b1),
        .NumStages    (2)
    ) inst_synchronizer_rst_pxl (
        .clk_i (clk_pxl),
        .rst_i (~clk_ser_locked),
        .sig_i (~clk_ser_locked),
        .sig_o (rst_pxl)
    );

    video_generator #(
        .NumColTotal  (10'd800),
        .NumColActive (10'd640),
        .NumRowTotal  (10'd525),
        .NumRowActive (10'd480)
    ) inst_timing_generator (
        .clk_i (clk_ser),
        .rst_i (rst_ser),
        .rdy_i (ser_rdy),
        .den_o (vg_den),
        .pix_o (vg_pix)
    );

    tmds_encoder inst_tmds_encoder (
        .clk_i  (clk_ser),
        .rst_i  (rst_ser),
        .rdy_i  (ser_rdy),
        .de_i   (vg_den),
        .d_i    (vg_pix),
        .tmds_o (pix_tmds)
    );

    serializer_ddr inst_serializer_ddr_tmds_data (
        .clk_i     (clk_ser),
        .rst_i     (rst_ser),
        .dat_i     (pix_tmds),
        .rdy_o     (ser_rdy),
        .ser_re_o  (pix_ser_re),
        .ser_fe_o  (pix_ser_fe)
    );

    // Assign outputs
    assign led_o = ~rst_pxl;

    // Instantiate three differential data channels using DDR register outputs
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin
            SB_IO #(
                .PIN_TYPE    (6'b010010)
            ) inst_io_tmds_data_p (
                .PACKAGE_PIN (tmds_data_po[i]),
                .OUTPUT_CLK  (clk_ser),
                .D_OUT_0     (pix_ser_fe),
                .D_OUT_1     (pix_ser_re)
            );

            SB_IO #(
                .PIN_TYPE    (6'b010010)
            ) inst_io_tmds_data_n (
                .PACKAGE_PIN (tmds_data_no[i]),
                .OUTPUT_CLK  (clk_ser),
                .D_OUT_0     (~pix_ser_fe),
                .D_OUT_1     (~pix_ser_re)
            );
        end
    endgenerate

    // Generate TMDS CLK
    serializer_ddr inst_serializer_ddr_tmds_clk (
        .clk_i     (clk_ser),
        .rst_i     (rst_ser),
        .dat_i     (10'b1111100000),
        .rdy_o     ( ),
        .ser_re_o  (clk_ser_re),
        .ser_fe_o  (clk_ser_fe)
    );

    // Instantiate differential pixel clock channel using DDR register output
    SB_IO #(
        .PIN_TYPE    (6'b010010)
    ) inst_io_tmds_clk_p (
        .PACKAGE_PIN (tmds_clk_po),
        .OUTPUT_CLK  (clk_ser),
        .D_OUT_0     (clk_ser_fe),
        .D_OUT_1     (clk_ser_re)
    );
    SB_IO #(
        .PIN_TYPE    (6'b010010)
    ) inst_io_tmds_clk_n (
        .PACKAGE_PIN (tmds_clk_no),
        .OUTPUT_CLK  (clk_ser),
        .D_OUT_0     (~clk_ser_fe),
        .D_OUT_1     (~clk_ser_re)
    );

endmodule
