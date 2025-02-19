// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Tobias Senti <git@tsenti.li>

`include "common_cells/registers.svh"

module obi_reg import croc_pkg::*; #(
    parameter int unsigned        NumRegs = 1,
    parameter logic [NumRegs-1:0] RW      = '1,
    parameter type reg_t = logic [31:0]
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  sbr_obi_req_t obi_req_i,
    output sbr_obi_rsp_t obi_rsp_o,

    output logic [NumRegs-1:0] written_to_reg_o,
    output reg_t [NumRegs-1:0] regs_o,

    input  logic [NumRegs-1:0] write_to_reg_i,
    input  reg_t [NumRegs-1:0] regs_i,

    input  logic [NumRegs-1:0] reg_gnt_read_i
);
    localparam int unsigned RegNumWidth = $clog2(NumRegs);

    logic [31:0] rsp_data; // data sent back
    logic obi_err;
    logic we_d, we_q;
    logic req_d, req_q;
    logic [RegNumWidth-1:0] word_addr_d, word_addr_q;  // relevant part of the word-aligned address
    logic [SbrObiCfg.IdWidth-1:0] id_d, id_q; // id of the request, must be same for response
    logic [31:0] wdata_d, wdata_q; // data to write
    logic obi_error;

    // Step 1: Request phase
    // grant the request (ROM is always ready so this can be assigned directly)
    // safe important info
    assign id_d          = obi_req_i.a.aid;
    assign word_addr_d   = obi_req_i.a.addr[31:2];
    assign we_d          = obi_req_i.a.we;
    assign req_d         = obi_req_i.req;
    assign wdata_d       = obi_req_i.a.wdata;

    // Register file
    reg_t [NumRegs-1:0] regs_d, regs_q;

    // Request phase
    always_comb begin
        // Default
        obi_error = 1'b0;
        obi_rsp_o.gnt = 1'b0;

        if(obi_req_i.req) begin
            // Allow access if address is inside number of registers
            // Read is always allowed
            // For write RW bit must be set
            if(!(word_addr_d < NumRegs && (!obi_req_i.a.we || RW[word_addr_d]))) begin
                `ifndef SYNTHESIS
                    $display("obi_reg: Access to address %0x : WE %b RW %b reg_num: %d denied", obi_req_i.a.addr, obi_req_i.a.we, RW[word_addr_d], word_addr_d);
                    $stop();
                `endif
                obi_error = 1'b1;
            end else begin
                obi_rsp_o.gnt = reg_gnt_read_i[word_addr_d];
            end
        end 
    end

    // Phase 2: Response phase
    always_comb begin
        // Default
        obi_rsp_o.r.rdata = regs_q[word_addr_q];
        obi_rsp_o.r.rid = id_q;
        obi_rsp_o.r.err = obi_err;
        obi_rsp_o.r.r_optional = '0;
        obi_rsp_o.rvalid = req_q;
        obi_rsp_o.r.err = obi_error;
    end

    // Ouput regs
    assign regs_o[NumRegs-1:0] = regs_q[NumRegs-1:0];

    // Write logic
    always_comb begin
        // Default
        regs_d[NumRegs-1:0] = regs_q[NumRegs-1:0];
        written_to_reg_o = '0;
    
        if(req_q && we_q && RW[word_addr_q] && !obi_error) begin : obi_write
            regs_d[word_addr_q] = wdata_q;
            written_to_reg_o[word_addr_q] = 1'b1;
        end

        for(int i = 0; i < NumRegs; i++) begin : gen_reg_write
            if(write_to_reg_i[i])
                regs_d[i] = regs_i[i];
        end
    end

    // Sequential logic
    `FF(req_q, req_d, '0, clk_i, rst_ni)
    `FF(we_q, we_d, '0, clk_i, rst_ni)
    `FF(word_addr_q, word_addr_d, '0, clk_i, rst_ni)
    `FF(id_q, id_d, '0, clk_i, rst_ni)
    `FF(wdata_q, wdata_d, '0, clk_i, rst_ni)

    for(genvar i = 0; i < NumRegs; i++) begin : gen_reg_ffs
        `FF(regs_q[i], regs_d[i], '0, clk_i, rst_ni);
    end

    `ifndef SYNTHESIS
    always_ff @(posedge clk_i) begin
        if(req_q && !obi_err) begin
            if(!we_q) begin
                $display("obi_reg: Read from reg %d, data: %0x", word_addr_q, regs_q[word_addr_q]);
            end else begin
                $display("obi_reg: Write to reg %d, data: %0x", word_addr_q, obi_req_i.a.wdata);
            end
        end
    end
    `endif

endmodule : obi_reg
