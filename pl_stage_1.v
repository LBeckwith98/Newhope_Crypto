`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2020 08:18:48 PM
// Design Name: 
// Module Name: pl_stage_1
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


module pl_stage_1(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // S' input signals
    input        we_sp,
    input [8:0]  addr_sp,
    input [15:0] di_sp,
    // E' input signals
    input        we_ep,
    input [8:0]  addr_ep,
    input [15:0] di_ep,
    // E'' input signals
    input        we_epp,
    input [8:0]  addr_epp,
    input [15:0] di_epp,
    // v input signals
    input        we_v,
    input [8:0]  addr_v,
    input [15:0] di_v,
    // S' * G out (result 0)
    output reg we_r0,
    output reg [8:0] addr_r0,
    output reg [15:0] dout_r0,    
    // E' * G out (result 1)
    output reg we_r1,
    output reg [8:0] addr_r1,
    output reg [15:0] dout_r1,   
    // E'' + V out (result 2)
    output reg we_r2,
    output reg [8:0] addr_r2,
    output reg [15:0] dout_r2   
    );
    
    reg start_components;
        
    // 3 BRAM units
    reg  [8:0]  PR0_addra, PR1_addra;
    wire [15:0] PR0_doa, PR1_doa;
    
    // module wires
    wire done_mult0, done_mult1, done_add;
    wire we_mult0, we_mult1, we_add;
    wire [8:0] addr_mult0, addr_mult1, addr_add;
    wire [15:0] dout_mult0, dout_mult1, dout_add;
    
    // S'
    wire [15:0] do_sp, do_ep, do_epp, do_v;
    delay_block_ram #(.LENGTH(0)) RAM_SP (clk, rst, start_stage, we_sp, addr_sp,
                                    di_sp, addr_mult0, do_sp);
    // gamma RAM     
    single_port_ram #(.MEM_WIDTH(16), .MEM_SIZE(512), .FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas.txt")) RAM0_G
            (clk,1'b0,en,PR0_addra,16'd0,PR0_doa);
    
    // E'
    delay_block_ram #(.LENGTH(0)) RAM_EP (clk, rst, start_stage, we_ep, addr_ep,
                                    di_ep, addr_mult1, do_ep);
    // gamma RAM                                
    single_port_ram #(.MEM_WIDTH(16), .MEM_SIZE(512), .FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas.txt")) RAM1_G
            (clk,1'b0,en,PR1_addra,16'd0,PR1_doa);
            
    // V | E''
    delay_block_ram #(.LENGTH(0)) RAM_EPP (clk, rst, start_stage, we_epp, addr_epp,
                                di_epp, addr_add, do_epp);
                                
    delay_block_ram #(.LENGTH(0)) RAM_v (clk, rst, start_stage, we_v, addr_v,
                                di_v, addr_add, do_v);
    
    // Operation modules
    poly_multg MULT0_G_SP(clk, rst, en, start_components, done_mult0,
                            we_mult0, addr_mult0, do_sp, PR0_doa, dout_mult0);
  
    poly_multg MULT1_G_EP(clk, rst, en, start_components, done_mult1,
                            we_mult1, addr_mult1, do_ep, PR1_doa, dout_mult1);
  
    poly_add ADD_V_EPP (clk, rst, en, start_components, done_add,
                            we_add, addr_add, do_v,  do_epp, dout_add);
  
    // BRAM wire assignments
    always @(*) begin
        we_r0   = we_mult0;
        addr_r0 = addr_mult0;
        dout_r0 = dout_mult0;
        // E' * G out (result 1)
        we_r1   = we_mult1;
        addr_r1 = addr_mult1;
        dout_r1 = dout_mult1;
        // E'' + V out (result 2)
        we_r2   = we_add;
        addr_r2 = addr_add;
        dout_r2 = dout_add;
        
        PR0_addra = addr_mult0;
        PR1_addra = addr_mult1;             
    end
  

    // Output logic:
    always @(posedge clk) begin
        done_stage  <= (done_mult0) ? 1'b1 : 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
    end
    
endmodule
