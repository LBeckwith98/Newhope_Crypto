`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2020 05:58:56 PM
// Design Name: 
// Module Name: shift_ram
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


module shift_ram(clk, en, SI, SO);
    parameter DATA_WIDTH = 32,
              DEPTH = 24;
              
    input clk, en;
    input [DATA_WIDTH-1:0] SI;
    output [DATA_WIDTH-1:0] SO;
    
    reg [$clog2(DEPTH)-1:0] addr_in = 0;
    wire we;
    wire [DATA_WIDTH-1:0] NONE;
    
    assign we = en;
    
    dual_port_ram #(.WIDTH(DATA_WIDTH), .LENGTH(DEPTH)) DP_RAM (clk, clk, 1'b1, 1'b1, we, 1'b0, addr_in, 0, SI, 0, SO, NONE);
    
    always @(posedge clk) begin
        if (en) begin
            addr_in <= (addr_in != DEPTH - 1) ? addr_in + 1 : 0;
        end
    end

endmodule
