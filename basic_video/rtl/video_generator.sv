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

module video_generator #(
    parameter logic [9:0] NumColTotal  = 10'd800,
    parameter logic [9:0] NumColActive = 10'd640,
    parameter logic [9:0] NumRowTotal  = 10'd525,
    parameter logic [9:0] NumRowActive = 10'd480
) (
    input  logic clk_i,
    input  logic rst_i,
    input  logic ce_i,
    output logic de_o,
    output logic pix_o
);
    
    logic [9:0] row_d, row_q;
    logic [9:0] col_d, col_q;
    logic [9:0] square_x_d, square_x_q;
    logic [9:0] square_y_d, square_y_q;
    logic square_x_dir_d, square_x_dir_q;
    logic square_y_dir_d, square_y_dir_q;
    
    logic row_last;
    logic col_last;
    
    logic de_q, de_d;
    
    logic row_active;
    logic col_active;

    logic pix_q, pix_d;
    logic square_pix;

    logic [9:0] frm_d, frm_q;
    
    
    // Create comparators for last row and last column
    assign row_last = (row_q == (NumRowTotal-1));
    assign col_last = (col_q == (NumColTotal-1));
    
    // Creat row counter
    assign row_d = !ce_i                ? row_q         : // Stall pipeline
                   row_last && col_last ? 10'd0         : // Last pixel of a frame
                   col_last             ? row_q + 10'd1 : // Last pixel of a line
                   row_q                                ; // Not last pixel of a line
    
    // Create column counter
    assign col_d = !ce_i    ? col_q         : // Stall pipeline
                   col_last ? 10'd0         : // Last pixel of a line
                              col_q + 10'd1 ; // Not last pixel of a line

    assign frm_d = !ce_i                ? frm_q         : // Stall pipeline
                   row_last && col_last ? frm_q + 10'd1 : // Last pixel of a frame
                   frm_q                                ;
    
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            row_q <= 10'd0;
            col_q <= 10'd0;
            frm_q <= 10'd0;
        end else begin
            row_q <= row_d;
            col_q <= col_d;
            frm_q <= frm_d;
        end
    end
    
    assign row_active = (row_q < NumRowActive);
    assign col_active = (col_q < NumColActive);
    
    // Create data enable signal when in active area
    assign de_d = row_active && col_active;

    assign square_x_d = !ce_i                                   ? square_x_q         : // Stall pipeline
                        row_last && col_last && !square_x_dir_q ? square_x_q + 10'd1 : // End of frame
                        row_last && col_last && square_x_dir_q  ? square_x_q - 10'd1 : // End of frame
                        square_x_q;

    assign square_y_d = !ce_i                                   ? square_y_q         : // Stall pipeline
                        row_last && col_last && !square_y_dir_q ? square_y_q + 10'd1 : // End of frame
                        row_last && col_last && square_y_dir_q  ? square_y_q - 10'd1 : // End of frame
                        square_y_q;
    
    assign square_x_dir_d = !ce_i                  ? square_x_dir_q : // Stall pipeline
                            square_x_q == 10'd0    ? 1'b0           :
                            square_x_q == 10'd607  ? 1'b1           :
                            square_x_dir_q                          ;
    
    assign square_y_dir_d = !ce_i                 ? square_y_dir_q   : // Stall pipeline
                            square_y_q == 10'd0   ? 1'b0   :
                            square_y_q == 10'd447 ? 1'b1 :
                            square_y_dir_q;

    assign square_pix = (row_q > square_y_q) &&
                   (row_q < square_y_q+32) &&
                   (col_q > square_x_q) &&
                   (col_q < square_x_q+32) ? 1'b1 : 1'b0;

    assign pix_d = !ce_i ? pix_q : // Stall pipeline
                   square_pix ? 1'b1 : 
                   col_q & row_q ? 1'b1 : 1'b0;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            de_q       <= 1'b0;
            pix_q      <= 1'b0;
            square_x_q <= 10'b0;
            square_y_q <= 10'b0;
            square_x_dir_q <= 1'b0;
            square_y_dir_q <= 1'b0;
        end else begin
            de_q  <= de_d;
            pix_q <= pix_d;
            square_x_q <= square_x_d;
            square_y_q <= square_y_d;
            square_x_dir_q <= square_x_dir_d;
            square_y_dir_q <= square_y_dir_d;
        end
    end
    
    // Assign output
    assign de_o  = de_q;
    assign pix_o = pix_q;
    
endmodule
