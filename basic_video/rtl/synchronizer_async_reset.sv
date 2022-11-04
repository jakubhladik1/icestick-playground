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

module synchronizer_async_reset #(
    parameter logic        InitialValue = 1'b1,
    parameter int unsigned NumStages    = 2
) (
    input  wire       clk_dest_i,
    input  wire       rst_src_i,
    output wire       rst_dest_o
);

    logic [NumStages-1:0] sync_q, sync_d;

    // Create a chain of flip-flops to synchronize the input d_i
    assign sync_d = {sync_q[NumStages-2:0], rst_src_i};

    always_ff @(posedge clk_dest_i, posedge rst_src_i) begin
        if (rst_src_i) begin
            sync_q <= {NumStages{InitialValue}};
        end else begin
            sync_q <= sync_d;
        end
    end

    // Assign output
    assign rst_dest_o = sync_q[NumStages-1];

endmodule
