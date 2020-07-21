`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2020 05:17:35 PM
// Design Name: 
// Module Name: sampler_buffer
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


module sampler_buffer(
    input clk,
    input rst,
    input start,
    output reg done,
    // input RAM signals
    output reg [2:0] byte_addr = 0,
    input [31:0] byte_do,
    // Trivium module signals
    output reg [255:0] seed = 0,
    output reg reseed = 0,
    input reseed_ack,
	input [127:0] rdi_data,
	input rdi_valid,
	output reg rdi_ready = 0,
    // buffer outputs
    input bs_en_0,
    input bs_en_1,
    input bs_en_2,
    output [127:0] SO_0,
    output [127:0] SO_1,
    output [127:0] SO_2
    );
    
    localparam
        HOLD       = 3'd0,
        SETUP_SEED = 3'd1,
        RUN_PRNG   = 3'd2,
        PARSE      = 3'd3;
    reg [2:0] state = HOLD, state_next;
    
    // Buffer signals
    wire [127:0] SI_0, SI_1,SI_2;
    reg load_0, load_1, load_2;
    wire en_0, en_1, en_2;
    
    // buffer ctrl signals
    assign en_0 = (state == HOLD) ? bs_en_0 : load_0;
    assign en_1 = (state == HOLD) ? bs_en_1 : load_1;
    assign en_2 = (state == HOLD) ? bs_en_2 : load_2;
    
    assign SI_0 = rdi_data;
    assign SI_1 = rdi_data;
    assign SI_2 = rdi_data;
    
    // SR BRAM
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR0 (clk, en_0, SI_0, SO_0);
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR1 (clk, en_1, SI_1, SO_1);
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR2 (clk, en_2, SI_2, SO_2);
    
    // CTRL signals
    reg [7:0] ctr, j;
  
    // combinational state logic
    always @(*) begin
            state_next = HOLD;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? SETUP_SEED : HOLD;
        end
        SETUP_SEED: begin
            state_next = (reseed_ack) ? RUN_PRNG : SETUP_SEED;
        end
        RUN_PRNG: begin
            state_next = (rdi_valid) ? PARSE : RUN_PRNG;
        end
        PARSE: begin
            state_next = (j == 192) ? HOLD : PARSE;
        end        
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    // output logic
    always @(posedge clk) begin
        done <= 1'b0;
        load_0 <= 1'b0;
        load_1 <= 1'b0;
        load_2 <= 1'b0;
        ctr <= 0;
        j <= 0;
        reseed <= 1'b0;
        rdi_ready <= 1'b0;
    
        case (state) 
        HOLD: begin
            ctr <= 0;
            j <= 0;
            byte_addr <= 0;
        end
        SETUP_SEED: begin
            if (ctr < 10) begin
                byte_addr <= ctr;

                ctr <= ctr + 1;
                if (ctr > 1)
                    seed[(ctr-2)*32+:32] <= byte_do;
            end else begin
                byte_addr <= 0;
                ctr <= ctr;
                reseed <= 1'b1;
            end
           
        end
        RUN_PRNG: begin
            rdi_ready <= 1'b0;
        end
        PARSE: begin
            if (j < 64) begin
                load_0 <= 1'b1;
            end else if (j < 128) begin
                load_1 <= 1'b1;
            end else begin
                load_2 <= 1'b1;
            end
            rdi_ready <= 1'b1;
            j <= j + 1;
            
            if (j == 192) 
                done <= 1'b1;
        end        
        endcase
    end
    
    
endmodule
