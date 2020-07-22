`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2020 10:41:25 PM
// Design Name: 
// Module Name: pl_state_4
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


module pl_stage_4(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // A input
    input we_a,
    input [8:0] addr_a,
    input [15:0] dout_a,  
    // E' input
    input we_ep,
    input [8:0] addr_ep,
    input [15:0] dout_ep,  
    // B input
    input we_b,
    input [8:0] addr_b,
    input [15:0] dout_b,  
    // A + E' output
    output we_r0,
    output [8:0] addr_r0,
    output [15:0] dout_r0,
    // output NTT_INV(B) OWNED BY NTT
    input [8:0] addr_bntt,
    output [15:0] do_bntt
    );
    
    reg start_components;
    
    // Module wires
    wire done_add, done_ntt;
    wire we_add;
    wire [8:0] addr_add;
    wire [15:0] dout_add;
    
    // RAM modules
    wire [15:0] do_a, do_ep;
    // A
    delay_block_ram #(.LENGTH(0)) RAM_A (clk, rst, start_stage, we_a, addr_a, dout_a, addr_add, do_a);
                                    
    // E'
    delay_block_ram #(.LENGTH(0)) RAM_EP (clk, rst, start_stage, we_ep, addr_ep, dout_ep, addr_add, do_ep);
    
    // module instances
    poly_add ADD_V_EPP (clk, rst, en, start_components, done_add,
                        we_add, addr_add, do_a, do_ep, dout_add);
    
    stacked_ntt #(.MODE(1)) NTT0(clk, rst, start_components, en, done_ntt,
                    we_b, addr_b, dout_b, addr_bntt, do_bntt);
    
    // assign output
    assign we_r0 = we_add;
    assign addr_r0 = addr_add;
    assign dout_r0 = dout_add;
     
    // Output logic:
    always @(posedge clk) begin
        done_stage  <= (done_ntt) ? 1'b1 : 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
    end
    
endmodule
