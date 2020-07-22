`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2020 03:50:50 PM
// Design Name: 
// Module Name: pl_stage_6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pl_stage_6(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // B INPUT
    input we_b,
    input [8:0] addr_b,
    input [15:0] dout_b,  
    // V' INPUT
    input we_vp,
    input [8:0] addr_vp,
    input [15:0] dout_vp,  
    // B + V' OUTPUT
    output we_r0,
    output [8:0] addr_r0,
    output [15:0] dout_r0
    );
    
    // Module wires
    reg start_components;
    wire we_add, done_add;
    wire [8:0] addr_add;
    wire [15:0] dout_add;
        
    // RAM MODULES
    wire [15:0] do_b, do_vp;
    // B
    delay_block_ram #(.LENGTH(0)) RAM_B (clk, rst, start_stage, we_b, addr_b, dout_b, addr_add, do_b);
    
    // V'
    delay_block_ram #(.LENGTH(6)) RAM_VP (clk, rst, start_stage, we_vp, addr_vp, dout_vp, addr_add, do_vp);
    
    // module instances
    poly_add ADD_B_VP (clk, rst, en, start_components, done_add,
                            we_add, addr_add, do_b, do_vp, dout_add);                           
   
    assign we_r0 = we_add;
    assign addr_r0 = addr_add;
    assign dout_r0 = dout_add;
      
    // Output logic:
    always @(posedge clk) begin
        done_stage  <= 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
        done_stage <= (done_add) ? 1'b1 : 1'b0;
    end
    
    
endmodule
