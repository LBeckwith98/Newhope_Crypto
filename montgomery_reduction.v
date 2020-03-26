`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 09:23:33 PM
// Module Name: montgomery_reduction
// Project Name:  NTT
// Description:  Performs montgomery reduction of a 32-bit values
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////

module montgomery_reduction(
    input clk,
    input load,
    input en,
    input reset,
    input [31:0] in,
    output [15:0] out,
    output valid
    );
   
    // reg used to stor intermediate states
    reg [17:0] MASK_stage_u = 0;
    reg [31:0] MASK_stage_in = 0, MULT_Q_stage_u = 0, MULT_Q_stage_in = 0,
                ADD_stage_u = 0, ADD_stage_in = 0, out_reg = 0, delay_reg = 0;
                
    reg MASK_stage_load = 0, MULT_Q_stage_load = 0, ADD_stage_load = 0, done_reg = 0, delay = 0;
    
    assign out = {2'b00, out_reg[31:18]};
    assign valid = done_reg;
    
    // state logic
    initial begin
        out_reg = 32'b0;
        done_reg = 1'b0;
    end
    
    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin           
            MASK_stage_load <= 1'b0;
            MULT_Q_stage_load <= 1'b0;
            ADD_stage_load <= 1'b0;
            delay <= 1'b0;
            done_reg <= 1'b0;
        end
        else if (en) begin
            // MULT_QINV calculation
            MASK_stage_u <= in * 32'd12287;
            MASK_stage_in <= in;
            MASK_stage_load <= load;
            
            // MASK calculation
            MULT_Q_stage_u <= MASK_stage_u & 32'd262143;
            MULT_Q_stage_in <= MASK_stage_in;
            MULT_Q_stage_load <= MASK_stage_load;

            // MULT_Q calculation
            ADD_stage_u <= MULT_Q_stage_u * 32'd12289;
            ADD_stage_in <= MULT_Q_stage_in;
            ADD_stage_load <= MULT_Q_stage_load;
            
            // A_ADD calculation
            delay_reg <= ADD_stage_in + ADD_stage_u;
            delay <= ADD_stage_load;

            out_reg <= delay_reg;
            done_reg <= delay;
        end 
        
    end

    
endmodule
