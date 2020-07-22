`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2020 09:04:42 PM
// Design Name: 
// Module Name: pl_state_3
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


module pl_stage_3(
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
    // B input
    input we_b,
    input [8:0] addr_b,
    input [15:0] dout_b,
    // Input NTT(E') OWNED
    output reg  [8:0] addr_epntt,
    input [15:0] dout_epntt,
    // NTT(E') passthrough output
    output reg we_ep,
    output reg [8:0] addr_ep,
    output reg [15:0] dout_ep,
    // output NTT(S') OWNED BY NTT
    output [8:0] addr_sp,
    input [15:0] do_sp,
    // A * NTT(S') output
    output we_r0,
    output [8:0] addr_r0,
    output [15:0] dout_r0,  
    // B * NTT(S') output
    output we_r1,
    output [8:0] addr_r1,
    output [15:0] dout_r1
    );

    reg start_components;
    
    // multiplier wires
    wire done_mult0, done_mult1;
    wire we_mult0, we_mult1;
    wire [8:0] addri_mult0, addro_mult0, addri_mult1, addro_mult1;
    wire [15:0] do_mult0, do_mult1;
    
    // RAM modules
    wire [15:0] do_a, do_b;
    // A
    delay_block_ram #(.LENGTH(3)) RAM_A (clk, rst, start_stage, we_a, addr_a, dout_a, addri_mult0, do_a);
                                    
    // B
    delay_block_ram #(.LENGTH(3)) RAM_B (clk, rst, start_stage, we_b, addr_b, dout_b, addri_mult1, do_b);
                                
    // Multiplier instances
    poly_mult #(.BITREV(0)) MULT0_A_SP(clk, rst, en,  start_components, done_mult0,
                    we_mult0, addri_mult0, addro_mult0, do_a, do_sp, do_mult0);
    
    poly_mult #(.BITREV(1)) MULT1_B_SP(clk, rst, en,  start_components, done_mult1,
                we_mult1, addri_mult1, addro_mult1, do_b, do_sp, do_mult1);
    
    assign addr_sp = addri_mult0; // should be synced with addri_mult1
    
    // output assignments
    assign we_r0 = we_mult0;
    assign addr_r0 = addro_mult0;
    assign dout_r0 = do_mult0;
    assign we_r1 = we_mult1;
    assign addr_r1 = addro_mult1;
    assign dout_r1 = do_mult1;

    // E' passthrough reg
    reg [9:0] ctr = 0;    
    
    // Output logic:
    always @(posedge clk) begin
        done_stage  <= (done_mult0) ? 1'b1 : 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
        ctr <= (start_components) ? 10'b0 : ctr;
        we_ep <= 1'b0;
        addr_ep <= 0;
        dout_ep <= 0;
        addr_epntt <= 0;

        // Transfer E from NTT to next layert buffer
        if (ctr < 512) begin
            ctr <= ctr + 1;
            addr_epntt <= ctr;
            
            if (ctr > 1) begin
                we_ep <= 1'b1;
                addr_ep <= ctr - 2;
                dout_ep <= dout_epntt;
            end
        end else if (ctr < 514) begin
            ctr <= ctr + 1;
            we_ep <= 1'b1;
            addr_ep <= ctr - 2;
            dout_ep <= dout_epntt;
        end    
    end
    
endmodule
