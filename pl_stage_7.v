`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2020 03:50:50 PM
// Design Name: 
// Module Name: pl_stage_7
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


module pl_stage_7(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output done_stage,
    // A input
    input we_a,
    input [8:0] addr_a,
    input [15:0] dout_a, 
    // V'' input
    input we_vpp,
    input [8:0] addr_vpp,
    input [15:0] dout_vpp, 
    // Compress(V'') out (BYTES)
    output bwe_r0,
    output [7:0] baddr_r0,
    output [7:0] bdi_r0,
    // EncodePoly(A) out (BYTES)
    output bwe_r1,
    output [9:0] baddr_r1,
    output [7:0] bdi_r1
    );
        
    // Module wires
    wire done_c, done_pe;
    wire [8:0] addr_c, addr_pe;
    
    // delay cycle to let ram flip
    reg start_components;
    always @(posedge clk) begin
        start_components <= (start_stage) ? 1'b1 : 1'b0;
    end
    
    // RAM modules
    wire [15:0] do_a, do_vpp;
    // A
    delay_block_ram #(.LENGTH(3)) RAM_A (clk, rst, start_stage, we_a, addr_a, dout_a, addr_pe, do_a);
                                    
    // V''
    delay_block_ram #(.LENGTH(0)) RAM_B (clk, rst, start_stage, we_vpp, addr_vpp, dout_vpp, addr_c, do_vpp);
    
    // module instances
    compressor COMPRESSOR (clk, rst, start_components, done_c, baddr_r0, bdi_r0, bwe_r0, addr_c, do_vpp);
    
    polynomial_encoder POLY_ENCODER(clk, rst, start_components, done_pe, bwe_r1, 
                                    baddr_r1, bdi_r1, addr_pe, do_a);
    
    assign done_stage = done_pe;
    
endmodule
