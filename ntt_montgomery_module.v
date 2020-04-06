`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 10:37:11 PM
// Module Name: ntt_montgomery_module
// Project Name:  NTT
// Description: calculates the second butterfly calculation red(W* (a - 3q - a_d))
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////

module ntt_montgomery_module(
    input clk,
    input load,
    input en,
    input reset,
    input [15:0] a,
    input [15:0] a_pair,
    input [15:0] omega,
    output [15:0] b_pair,
    output valid
    );

    // pipeline registers
    reg [31:0] REDUCE_a = 32'd0;
    reg [15:0] SUB_a_pair = 16'd0, SUB_omega = 16'd0,  MULT_omega = 16'd0, SUB_a = 16'd0, MULT_a = 16'd0;
    reg SUB_load = 1'd0, MULT_load = 1'd0, REDUCE_load = 1'd0;
    
        
    // instance of pipelined reduction module
    montgomery_reduction reducer(clk, REDUCE_load, en, reset, REDUCE_a, b_pair, valid);
    
    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin
            SUB_load <= 1'b0;
            MULT_load <= 1'b0;
            REDUCE_load <= 1'b0;
        end
        else if (en) begin
            // ADD_3Q calculation
            SUB_a <= a + 16'd36867;
            SUB_a_pair <= a_pair;
            SUB_omega <= omega;
            SUB_load <= load;
            
            // SUB_A calculation
            MULT_a <= SUB_a - {16'd0, SUB_a_pair};
            MULT_omega <= SUB_omega;
            MULT_load <= SUB_load;
            
            // MULT_OMEGA CALCULATION
            REDUCE_a <= MULT_a * MULT_omega;
            REDUCE_load <= MULT_load;
            
            /*
             * pipelined calculation continues in montgomery_reduction
             */
           
        end 
    end
    
endmodule
