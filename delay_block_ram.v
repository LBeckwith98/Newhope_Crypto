`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2020 10:09:02 PM
// Design Name: 
// Module Name: delay_block_ram
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


module delay_block_ram (
    clk,
    rst,
    shift,
    // write in
    we_in,
    addr_in,
    di_in,
    // read out
    addr_out,
    do_out
    );
    
    parameter LENGTH = 6, WIDTH = 16, BLOCK_SIZE = 512;
    genvar i;
    
    // I/O
    input clk;
    input rst;
    input shift;
    // write in
    input we_in;
    input [$clog2(BLOCK_SIZE)-1:0] addr_in;
    input [WIDTH-1:0] di_in;
    // read out
    input [$clog2(BLOCK_SIZE)-1:0] addr_out;
    output reg [WIDTH-1:0] do_out;
    
    // CTRL logic signals
    reg [$clog2(LENGTH+2)-1:0] state_num = 0;
    
    // BRAM port connections
    reg en, wea, web;
    reg [$clog2((LENGTH+2)*BLOCK_SIZE)-1:0] addra, addrb;
    reg [WIDTH-1:0] dia, dib;
    wire [WIDTH-1:0] doa, dob;
    
    
    // BRAM unit
    dual_port_ram #(.LENGTH((LENGTH+2)*BLOCK_SIZE), .WIDTH(WIDTH)) BRAM (clk,clk,en,en,wea,web,addra,addrb,dia,dib,doa,dob);

    
    // generate control logic  
    always @(*) begin
        en = 1'b1;
    
        // input assignment
        addra = {state_num, addr_in};
        wea = we_in;        
        dia = di_in;
              
        // output assignment
        addrb =  (state_num == LENGTH+1) ? {8'd0, addr_out} : {state_num+1, addr_out};
        web = 1'b0;
        dib = 16'd0;
        do_out = dob;
    end
      
      
    // state logic
    always @(posedge clk) begin
        if (rst) begin
            state_num <= 0;
        end else if (shift) begin
            state_num <= (state_num < LENGTH + 1) ? state_num + 1 : 0;
        end else begin
            state_num <= state_num;
        end
    end
         

endmodule
