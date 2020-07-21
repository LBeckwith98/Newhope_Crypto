`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2020 03:50:50 PM
// Design Name: 
// Module Name: pl_stage_5
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


module pl_stage_5(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // B input (NTT OWNED)
    output [8:0] addr_b,
    input [15:0] dout_b,
    // B * G_inv output
    output we_r1,
    output [8:0] addr_r1,
    output [15:0] dout_r1
    );
    
    reg start_components;
    
    // Module wires
    wire [8:0] addr_multg;
    wire done_multg;
        
    // gamma_inb RAM     
    wire [8:0] PR0_addra;
    wire [15:0] PR0_doa;
    single_port_ram #(.MEM_WIDTH(16), .MEM_SIZE(512), .FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas_inv.txt")) RAM0_GINV
            (clk,1'b0,en,PR0_addra,16'd0,PR0_doa); 
        
    // module instances
    poly_multg MULT0_GINV_B(clk, rst, en, start_components, done_multg,
                                we_r1, addr_multg, dout_b, PR0_doa, dout_r1);
                            
    assign addr_r1 = addr_multg;
    assign addr_b = addr_multg;
    assign PR0_addra = addr_multg;
        
    // Output logic:
    always @(posedge clk) begin
        done_stage  <= (done_multg) ? 1'b1 : 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
    end
    
endmodule
