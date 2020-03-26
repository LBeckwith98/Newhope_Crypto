`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_add_coeff
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
module poly_add_coeff(
  // data signals
  input [15:0] dia,
  input [15:0] dib,
  output [15:0] dout
  );
  integer NEWHOPE_Q = 12289;
  reg [15:0] sum;
  
  assign dout = (sum > NEWHOPE_Q) ? sum - NEWHOPE_Q : sum;
  
  always @(*) begin
    sum = dia + dib;
  end

endmodule
