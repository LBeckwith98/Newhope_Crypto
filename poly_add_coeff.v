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
  input clk,
  input start,
  input [15:0] dia,
  input [15:0] dib,
  output reg done,
  output reg [15:0] dout
  );
  reg [15:0] sum;
  localparam 
    NEWHOPE_2Q = 16'd24578,
    NEWHOPE_Q = 16'd12289;
  
  reg start_in;
  
  always @(posedge clk) begin
    sum <= dia + dib;
    start_in <= start;
    
    dout <= (sum >= NEWHOPE_2Q) ? sum - NEWHOPE_2Q : 
                (sum >= NEWHOPE_Q) ? sum - NEWHOPE_Q : sum;
    done <= start_in;
  end

endmodule
