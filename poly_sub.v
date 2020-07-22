`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2020 12:08:48 PM
// Design Name: 
// Module Name: poly_sub
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


module poly_sub(
  // basic control signals
  input clk,
  input rst,
  input en,
  input start,
  output reg done = 0,
  // Poly RAM access signals
  output reg ram_we,
  output wire [8:0] ram_addr_out,
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

  localparam PIPELINE_LENGTH = 3'd2;
  reg [2:0] pipeline_count = 0;

   // states operations
  reg [1:0] state, state_next;
  localparam 
    HOLD      = 2'b00, 
    LOAD      = 2'b01, 
    UNLOAD    = 2'b10;

  // keeps track of which coefficients are being affected
  reg [9:0] coeff_count, coeff_count_next;
  wire [9:0] ram_addr;
  assign ram_addr = (state == UNLOAD) ? coeff_count - pipeline_count : coeff_count;
  assign ram_addr_out = ram_addr[8:0];

  // arithmetic modules
  wire [15:0] sub_out;

  assign dout = sub_out;

  poly_sub_coeff sub_module(clk, en, ram_doa, ram_dob, sub_out);
  
  // combination state logic
  always @(*) begin
    // defaults
    state_next = state;
    coeff_count_next = coeff_count;
    
    case (state) 
    HOLD: begin
        coeff_count_next = 0;
        if (start) begin
            state_next = LOAD;
        end
    end
    LOAD: begin
        state_next = (done) ? HOLD 
                    : (pipeline_count == PIPELINE_LENGTH) ? UNLOAD : LOAD;
                    
        coeff_count_next = coeff_count + 1;
    end
    UNLOAD: begin
        state_next = (done) ? HOLD :
                (pipeline_count == 1) ? LOAD : UNLOAD;
    end
    endcase
  end

  // synchronous state logic
  always @(posedge clk) begin
    state <= (rst) ? HOLD : state_next;
    coeff_count <= (rst) ? 9'd0 : coeff_count_next;
  end

  // sequential output logic 
  always @(posedge clk) begin
    // default
    ram_we <= 1'b0;
    done <= 1'b0;
  
    case (state) 
    HOLD: begin
        ram_we <= 1'b0;
        pipeline_count <= 0;
    end
    LOAD: begin
        pipeline_count <= pipeline_count + 1;
        ram_we <= (pipeline_count == PIPELINE_LENGTH) ? 1'b1 : 1'b0; 
    end
    UNLOAD: begin
        if (ram_addr >= 511 && pipeline_count > 0) begin
            if (ram_addr == 511)
                done <= 1'b1;
            ram_we <= 1'b0;
        end else begin
            done <= 1'b0;
            ram_we <= 1'b1;
        end
       
        pipeline_count <= (pipeline_count == 1) ? 0 : pipeline_count - 1;
    end
    endcase
  end
endmodule
