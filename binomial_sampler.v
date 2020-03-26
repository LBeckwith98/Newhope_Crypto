`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2020 10:55:28 AM
// Design Name: 
// Module Name: binomial_sampler
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

/*
BASIC OPERATION: Load input seed into byte_ram. Send start signal. Wait until
done signal. Output will be located in poly_ram.
*/

module binomial_sampler(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    input [7:0] nonce,
    output reg done,
    // Input RAM signals
    output reg [2:0] byte_addr,
    input [31:0] byte_do,
    // output RAM signals
    output reg poly_wea,
    output reg [8:0] poly_addra,
    output reg [15:0] poly_dia,
    // SHAKE256 module signals
    output reg shake_rst,
    output [31:0] shake_in,
    output reg shake_in_ready,
    output reg shake_is_last,
    output reg [1:0] shake_byte_num,
    input [0:1023] shake_out,
    input shake_out_ready);
    
    // state variables
    parameter WAIT = 2'd0, LOAD_SHAKE = 2'd1, WAIT_SHAKE = 2'd2, PARSE = 2'd3;
    reg [1:0]  state;
    reg [1:0] state_next;
    reg [15:0] i, j;
    reg parse_done;

    // PARSE Step
    parameter HAMMING_WEIGHT = 2'd0, CALCULATE = 2'd1, STORES = 2'd2;
    reg [1:0] parse_state;
    reg [3:0] hw_a, hw_b;
    reg [15:0] r_val;
    reg [8:0] r_addr;

    assign shake_in = (shake_is_last) ? {nonce, i[7:0], 16'b0} : byte_do;

    // Combination state logic
    always @(*) begin
        case(state)
            WAIT: begin
                if (start == 1'b1) begin
                    state_next = LOAD_SHAKE;
                end else begin
                    state_next = WAIT;
                end
            end
            LOAD_SHAKE: begin
                if (shake_is_last == 1'b1) begin
                    state_next = WAIT_SHAKE;
                end else begin
                    state_next = LOAD_SHAKE;
                end
            end
            WAIT_SHAKE: begin
                if (shake_out_ready == 1'b1) begin
                    state_next = PARSE;
                end else begin
                    state_next = WAIT_SHAKE;
                end
            end
            PARSE: begin
                if (parse_done == 1'b1 && i < 8) begin
                    state_next = LOAD_SHAKE;
                end else if (parse_done == 1'b1 && i == 8) begin
                    state_next = WAIT;
                end else begin
                    state_next = PARSE;
                end

            end
        endcase
    end

    // Seq state logic
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= #1 WAIT;
        end else begin
            state <= #1 state_next;
        end
    end

    // output (action) logic
    always @(posedge clk) begin
        // default outputs
        done <= #1 1'b0;
        parse_done <= #1 1'b0;

        // output ram (polynomial)
        poly_wea <= #1 1'b0;
        poly_addra <= #1 9'b0;
        poly_dia <= #1 16'b0;

        // SHAKE
        shake_rst <= #1 1'b0;
        // shake_in <= #1 32'b0;
        shake_in_ready <= #1 1'b0;
        shake_is_last <= #1 1'b0;
        shake_byte_num <= #1 2'b0;

        // input ram (byte)
        byte_addr <= #1 3'b0;

        // parse state data
        parse_state <= HAMMING_WEIGHT;
        hw_a <= 0;
        hw_b <= 0;
        r_val <= 16'b0;
        r_addr <= 9'b0;

        // reset logic
        if (rst == 1'b1) begin
            shake_rst <= #1 1'b1;
            j <= 0;
            i <= 0;
        end else begin
            // functional logic
            case(state_next)
                WAIT: begin
                    // default outputs -> just waiting
                    i <= #1 0; 
                    j <= #1 0;
                    shake_rst <= #1 1'b1;

                    if (start) begin
                        shake_rst <= #1 1'b0;
                        j <= #1 j + 1;
                    end
                end
                LOAD_SHAKE: begin
                    shake_rst <= #1 1'b0;
                    if (j < 9) begin
                        // load from RAM
                        byte_addr <= #1 j[2:0];
                        j <= #1 j + 1;

                        // input into SHAKE
                        if (j > 0)
                            shake_in_ready <= #1 1'b1;
                    end else begin
                        // last load in, append nonce and i
                        shake_in_ready <= #1 1'b1;
                        shake_is_last <= #1 1'b1;
                        shake_byte_num <= #1 2'd2;

                    end
                end
                WAIT_SHAKE: begin
                    // default outputs
                    j <= #1 0;
                end
                PARSE: begin
                    // hand outputs of SHAKE
                    case (parse_state) 
                        HAMMING_WEIGHT: begin
                            hw_a <= #1 shake_out[16*j+7]  + shake_out[16*j+6]  + shake_out[16*j+5]  + shake_out[16*j+4]  + shake_out[16*j+3]  + shake_out[16*j+2]  + shake_out[16*j+1] + shake_out[16*j+0];       //shake_out[2*j+7:2*j];
                            hw_b <= #1 shake_out[16*j+15] + shake_out[16*j+14] + shake_out[16*j+13] + shake_out[16*j+12] + shake_out[16*j+11] + shake_out[16*j+10] + shake_out[16*j+9] + shake_out[16*j+8]; //shake_out[2*j+15:2*j+8];
                            parse_state <= #1 CALCULATE;
                        end
                        CALCULATE: begin
                            r_val <= #1 hw_a + 12289 - hw_b; // q = 12289
                            r_addr <= #1 64*i + j;
                            j <= #1 j + 1; // latch probably
                            parse_state <= #1 STORES;
                        end 
                        STORES: begin
                            poly_wea <= #1 1'b1;
                            poly_addra <= #1 r_addr;
                            poly_dia <= #1 r_val;
                            // need exit condition
                            parse_state <= HAMMING_WEIGHT;
                            
                            if (j == 64) begin
                                parse_done <= #1 1'b1;
                                shake_rst <= #1 1'b1;
                                j <= #1 0;

                                if (i == 7) begin
                                    done <= #1 1'b1;
                                end else begin
                                    i <= #1 i + 1;
                                end
                            end
                        end
                      endcase
                end
            endcase
        end
    end


endmodule
