// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Tobias Senti <git@tsenti.li>

`include "common_cells/registers.svh"

module int8inator import user_pkg::*; import croc_pkg::*; #(
    parameter type word_t = logic [31:0]
) (
    input  logic clk_i,
    input  logic rst_ni,

    input word_t func_i,
    input word_t a_i,
    input word_t b_i,

    output word_t result_o
);
    typedef logic [7:0] byte_t;

    byte_t [3:0] a_bytes, b_bytes, result_bytes;

    for(genvar i = 0; i < 4; i++) begin : byte_loop
        assign a_bytes[i] = a_i[8*i +: 8];
        assign b_bytes[i] = b_i[8*i +: 8];

        always_comb begin
            case(func_i)
            'd0: result_bytes[i] = a_bytes[i] + b_bytes[i];
            'd1: result_bytes[i] = a_bytes[i] - b_bytes[i];
            'd2: result_bytes[i] = a_bytes[i] * b_bytes[i];
            default: result_bytes[i] = 8'h00;
            endcase
        end

        assign result_o[8*i +: 8] = result_bytes[i];
    end

endmodule : int8inator
