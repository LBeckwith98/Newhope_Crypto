`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2020 08:12:48 PM
// Design Name: 
// Module Name: gen_ss
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


module gen_ss(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // RAM signals
    output reg [2:0] byte_addr,
    input [31:0] byte_do,
    output reg [31:0] byte_di,
    output reg byte_we,
    // Trivium module signals
    output reg [255:0] seed = 0,
    output reg reseed = 0,
	input [127:0] rdi_data,
	input rdi_valid,
	output reg rdi_ready = 0
    );
    
    localparam 
        HOLD = 2'd0, 
        SETUP_SEED = 2'd1, 
        RUN_PRNG = 2'd2,
        UNLOAD = 2'd3;
    reg [1:0]  state = HOLD;
    reg [1:0] state_next = HOLD;
    reg [3:0] ctr;
    
    // Combination state logic
    always @(*) begin
        case(state)
            HOLD: begin
                state_next = (start == 1'b1) ? SETUP_SEED : HOLD;
            end
            SETUP_SEED: begin
                state_next = (ctr == 7) ? RUN_PRNG : SETUP_SEED;
            end
            RUN_PRNG: begin
                state_next = (rdi_valid) ? UNLOAD : RUN_PRNG;
            end
            UNLOAD: begin
                state_next = (done) ? HOLD : UNLOAD;
            end
        endcase
    end

    // Seq state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    // output (action) logic
    always @(posedge clk) begin
        // default outputs
        done <= 1'b0;
        ctr <= ctr;
    
        // input ram (byte)
        byte_addr <= 3'b0;
        byte_di <= 0;
        byte_we <= 1'b0;

        // reset logic
        if (rst == 1'b1) begin
            ctr <= 0;
        end else begin
            // functional logic
            case(state_next)
                HOLD: begin
                    ctr <= 0;
                end
                SETUP_SEED: begin
                    if (ctr < 8) begin
                        byte_addr <= ctr;
                        seed[ctr*32+:32] <= byte_do;
                        ctr <= ctr + 1;
                    end else begin
                        ctr <= ctr;
                    end
                
                    if (ctr == 7) begin          
                        reseed <= 1'b1;
                        ctr <= 0;
                    end
                end
                RUN_PRNG: begin
                    rdi_ready <= 1'b0;
                end
                UNLOAD: begin
                    if (ctr[2:0] < 4) begin
                        byte_addr <= ctr[2:0];
                        byte_di <= rdi_data[ctr*32+:32];
                        byte_we <= 1'b1;
                        ctr <= ctr + 1;
                    end else if (ctr == 7) begin
                        done <= 1'b1;
                    end else begin
                        rdi_ready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
endmodule
