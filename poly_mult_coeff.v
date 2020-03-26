`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_mult_coeff
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

// sequential module, takes multiple clock cycles
module poly_mult_coeff(
  // basic control signals
  input clk,
  input rst,
  input start,
  input precomp,
  output reg done,
  // data signals
  input [15:0] doa,
  input [15:0] dob,
  output reg [15:0] dout
  );

  // FSM states
  localparam 
    HOLD     = 2'd0, 
    BUFFER   = 2'd1,
    REDUCE_T = 2'd2, 
    REDUCE_R = 2'd3;
  reg [1:0] state = HOLD, state_next;
  
  // montgomery reduction module
  reg [31:0] mont_in;
  reg mont_start;
  wire [15:0] mont_out;
  reg [15:0] dob_buffer, doa_buffer;
  wire mont_en, mont_done;
  assign mont_en = 1'b1;
  montgomery_reduction reducer (clk, mont_start, mont_en, rst, mont_in, mont_out, mont_done);

  // combinational state logic
  always @(*) begin
    state_next = state;
    case (state)
    HOLD: begin
      if (start) begin
        state_next = BUFFER;
      end
    end
    BUFFER: begin
        state_next = REDUCE_T;
    end
    REDUCE_T: begin
      if (mont_done == 1'b1 || precomp == 1'b1) begin
        state_next = REDUCE_R;
      end
    end
    REDUCE_R: begin
      if (mont_done) begin
        state_next = HOLD;
      end 
    end
    endcase
  end


  // sequential state logic
  always @(posedge clk) begin
     state <= (rst) ? HOLD : state_next;
  end


  // sequential output logic
  always @(posedge clk) begin
    done <= 1'b0;
    mont_start <= 1'b0;
    dout <= dout;

    case (state)
    HOLD: begin
      if (start ==1'b1) begin
        dob_buffer <= dob;
        doa_buffer <= doa;
      end
    end
    BUFFER: begin
      if (precomp == 1'b0) begin
        mont_in <= 16'd3186 * dob_buffer;
        mont_start <= 1'b1;
      end
    end
    REDUCE_T: begin
      if (mont_done == 1'b1) begin
        mont_in <= mont_out * doa_buffer;
        mont_start <= 1'b1;
      end else if (precomp == 1'b1) begin
         mont_in <= doa_buffer * dob_buffer;
         mont_start <= 1'b1;
      end
       
    end
    REDUCE_R: begin
      if (mont_done) begin
        done <= 1'b1;    
        dout <= mont_out;  
      end 
    end
    endcase
  end

endmodule