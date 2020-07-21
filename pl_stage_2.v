`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2020 07:51:59 PM
// Design Name: 
// Module Name: pl_stage_2
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


module pl_stage_2(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // S' * G input
    input we_r0,
    input [8:0] addr_r0,
    input [15:0] dout_r0,    
    // E' * G input
    input we_r1,
    input [8:0] addr_r1,
    input [15:0] dout_r1,
    // output NTT(S') OWNED
    input [8:0] addr_sp,
    output [15:0] do_sp,
    // output NTT(E') OWNED
    input  [8:0] addr_ep,
    output [15:0] do_ep
    );
    
    // Stacked NTT implementation
    wire done_n0, done_n1;
    reg start_components;
    
    stacked_ntt #(.MODE(0)) NTT0(clk, rst, start_components, en, done_n0,
                        we_r0, addr_r0, dout_r0, addr_sp, do_sp);
    
    stacked_ntt  #(.MODE(0)) NTT1(clk, rst, start_components, en, done_n1,
                        we_r1, addr_r1, dout_r1, addr_ep, do_ep);
    
    // Output logic:
    always @(posedge clk) begin
        done_stage <= (done_n0 || done_n1) ? 1'b1 : 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
    end
                   
endmodule
