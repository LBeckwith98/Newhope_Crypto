`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/08/2019 02:24:04 PM
// Module Name: ntt_adder
// Project Name: NTT 
// Description: Performs addition with or without reduction  based on 'lazy'
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////


module ntt_adder(
    input clk,
    input load,
    input en,
    input reset,
    input lazy,
    input [15:0] a,
    input [15:0] a_pair,
    output [15:0] b,
    output valid // signals valid output
);

    // pipeline registers
    reg [15:0] REDUCE_a = 0, OUT_a;
    reg REDUCE_lazy = 0, REDUCE_load = 0, OUT_load = 0;
    
    assign b = OUT_a;
    assign valid = OUT_load;
    
    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin
            OUT_a <= 16'b0;
            OUT_load <= 1'b0;
        end
        else if (en) begin
            // ADDITION calculation
            REDUCE_a <= a + a_pair;
            REDUCE_lazy <= lazy;
            REDUCE_load <= load;
            
            // REDUCTION calculation (if not lazy)
            OUT_a <= (REDUCE_lazy) ? REDUCE_a : REDUCE_a % 16'd12289;
            OUT_load <= REDUCE_load;
            
        end
    end

endmodule
