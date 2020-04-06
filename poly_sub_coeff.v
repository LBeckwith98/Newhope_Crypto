`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_sub_coeff
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

// combinational module, take one cycle.
module poly_sub_coeff(
  // data signals
  input clk,
  input rst,
  input start,
  input [15:0] dia,
  input [15:0] dib,
  output done,
  output [15:0] dout
  );
  
  localparam 
    NEWHOPE_Q = 16'd12289;
    
  reg [15:0] red_in;
  reg valid;
  wire [13:0] red_out;
  
  assign dout = {2'b0, red_out};
  
  barrett_reducer BAR_RED (clk, rst, 1'b1, red_in, valid, done, red_out);

  always @(posedge clk) begin
    valid <= 1'b0;
    if (start) begin
        red_in <= dia + 16'd36867 - dib;
        valid <= 1'b1;
    end
  end

endmodule