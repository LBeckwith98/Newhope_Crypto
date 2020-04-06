`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2020 05:40:10 PM
// Design Name: 
// Module Name: poly_arithmetic
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


module poly_arithmetic(
  // basic control signals
  input clk,
  input rst,
  input start,
  output reg done,
  // operation control signals
  input [1:0] opCode,
  // Poly RAM access signals
  output reg ram_we,
  output wire [8:0] ram_addr,
  input [15:0] ram_doa,
  input [15:0] ram_dob,
  output [15:0] dout
  );

   // Module operations
   localparam 
    MULTIPLY         = 2'b00, 
    ADD              = 2'b01, 
    SUBTRACT         = 2'b10,
    MULTIPLY_PRECOMP = 2'b11;

   // states operations
   localparam 
    HOLD  = 2'b00, 
    LOAD       = 2'b01, 
    CALCULATE = 2'b10,
    UNLOAD = 2'b11;
   reg [1:0] state = HOLD, state_next;
   
  // keeps track of which coefficients are being affected
  reg [8:0] coeff_count = 0, coeff_count_next;
  assign ram_addr = coeff_count;

  // arithmetic modules
  wire [15:0] add_out, sub_out, mult_out;
  reg mult_start, sub_start, add_start;
  wire mult_done, sub_done, add_done;
  wire precomp;
  
  assign precomp = (opCode == MULTIPLY_PRECOMP) ? 1'b1 : 1'b0;
  
  assign dout = (opCode == MULTIPLY) ? mult_out :
                    (opCode == ADD) ? add_out :
                    (opCode == SUBTRACT) ? sub_out : 
                    (opCode == MULTIPLY_PRECOMP) ? mult_out :16'd0;

  poly_add_coeff add_module(clk, add_start, ram_doa, ram_dob, add_done, add_out);
  poly_sub_coeff sub_module(clk, rst, sub_start, ram_doa, ram_dob, sub_done, sub_out);
  poly_mult_coeff mult_module(clk, rst, mult_start, precomp, mult_done, ram_doa, ram_dob, mult_out);
  
  // combination state logic
  always @(*) begin
    // defaults
    state_next = state;
    coeff_count_next = coeff_count;
    
    case (state) 
    HOLD: begin
        if (start) begin
            state_next = LOAD;
        end
    end
    LOAD: begin
        state_next = CALCULATE;
    end
    CALCULATE: begin
        if (mult_done || sub_done || add_done)
            state_next = UNLOAD;        
    end
    UNLOAD: begin
        if (coeff_count == 511) begin
            state_next = HOLD;
            coeff_count_next = 0;
        end else begin
            state_next = LOAD;
            coeff_count_next = coeff_count + 1;
        end

    end
    endcase
  end

  // synchronous state logic
  always @(posedge clk) begin
    state <= (rst) ? HOLD : state_next;
    coeff_count <= (rst) ? 0 : coeff_count_next;
  end

  // sequential output logic 
  always @(posedge clk) begin
    // default
    done <= 1'b0;
    mult_start <= 1'b0;
    sub_start <= 1'b0;
    add_start <= 1'b0;
    ram_we <= 1'b0;
  
    case (state) 
    HOLD: begin
        ram_we <= 1'b0;
    end
    LOAD: begin
        if (opCode == MULTIPLY || opCode == MULTIPLY_PRECOMP) begin
            mult_start <= 1'b1;
            ram_we <= 1'b0;
        end else if (opCode == SUBTRACT) begin
            sub_start <= 1'b1;
            ram_we <= 1'b0;
        end else if (opCode == ADD) begin
            add_start <= 1'b1;
            ram_we <= 1'b0;
        end
        
    end
    CALCULATE: begin
        if (mult_done || sub_done || add_done) begin
            ram_we <= 1'b1;
        end else begin
            ram_we <= 1'b0;
        end
    end
    UNLOAD: begin
        ram_we <= 1'b0;
        if (coeff_count == 511) begin
            done <= 1'b1;
        end
    end
    endcase
  end
endmodule
