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
    input  wire clk_i,
    input  wire rst_i,
    output wire den_o,
    output wire pix_o
);
    
    logic [9:0] row_d, row_q;
    logic [9:0] col_d, col_q;
    
    logic row_last;
    logic col_last;
    
    logic den_q, den_d;
    
    logic row_active;
    logic col_active;

    logic pix_q, pix_d;
    
    
    // Create comparators for last row and last column
    assign row_last = (row_q == (NumRowTotal-1));
    assign col_last = (col_q == (NumColTotal-1));
    
    // Creat row counter
    assign row_d = row_last && col_last ? 10'd0         : // Last pixel of a frame
                   col_last             ? row_q + 10'd1 : // Last pixel of a line
                   row_q                                ; // Not last pixel of a line
    
    // Create column counter
    assign col_d = col_last ? 10'd0         : // Last pixel of a line
                              col_q + 10'd1 ; // Not last pixel of a line
    
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            row_q <= 10'd0;
            col_q <= 10'd0;
        end else begin
            row_q <= row_d;
            col_q <= col_d;
        end
    end
    
    assign row_active = (row_q < NumRowActive);
    assign col_active = (col_q < NumColActive);
    
    // Create data enable signal when in active area
    assign den_d = row_active && col_active;

    // Create a one pixel thick frame inside the active area
    assign pix_d = (row_q == 10'd0)              || 
                   (row_q == NumRowActive-10'b1) ||
                   (col_q == 10'd0)              ||
                   (col_q == NumColActive-10'b1)    ? 1'b1 : 1'b0;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            den_q <= 1'b0;
            pix_q <= 1'b0;
        end else begin
            den_q <= den_d;
            pix_q <= pix_d;
        end
    end
    
    // Assign output
    assign den_o = den_q;
    assign pix_o = pix_q;
    
endmodule
