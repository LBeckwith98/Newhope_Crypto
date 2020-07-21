`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2020 06:07:09 PM
// Design Name: 
// Module Name: binomial_sampler_pl
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


module binomial_sampler_pl(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done = 0,
    // output RAM signals
    output reg poly_wea = 0,
    output reg [8:0] poly_addra = 0,
    output reg [15:0] poly_dia = 0,
    // RDI buffer signals
    output reg rdi_ready,
    input [127:0] rdi_data
    );
    
    // state variables
    localparam 
        WAIT       = 2'd0,
        PARSE      = 2'd1;
    reg [1:0]  state;
    reg [1:0] state_next;
    reg [15:0] i, j;

    // PARSE Step
    localparam HAMMING_WEIGHT = 2'd0, CALCULATE = 2'd1, STORE = 2'd2;
    reg [1:0] parse_state;
    reg [3:0] hw_a, hw_b;
    reg [15:0] r_val;
    reg [8:0] r_addr;

    // Combination state logic
    always @(*) begin
        case(state)
            WAIT: begin
                state_next = (start) ? PARSE : WAIT;
            end
            PARSE: begin
                state_next = (j == 8 && i == 63 && parse_state == STORE) ? WAIT : PARSE;
            end
            default: begin
                state_next = WAIT;
            end
        endcase
    end

    // Seq state logic
    always @(posedge clk) begin
        state <= (rst) ? WAIT : state_next;
    end

    // output (action) logic
    always @(posedge clk) begin
        // default outputs
        done       <= 1'b0;

        // output ram (polynomial)
        poly_wea   <= 1'b0;
        poly_addra <= 9'b0;
        poly_dia   <= 16'b0;

        // parse state data
        parse_state <= HAMMING_WEIGHT;
        hw_a  <= 0;
        hw_b  <= 0;
        r_val <= 16'b0;
        r_addr <= 9'b0;
    
        // Random data
        rdi_ready <= 1'b0;

        // reset logic
        if (rst == 1'b1) begin
            j <= 0;
            i <= 0;
            rdi_ready <= 1'b0;
        end else begin
            // functional logic
            case(state)
                WAIT: begin
                    // default outputs -> just waiting
                    i <= 0; 
                    j <= 0;

                end
                PARSE: begin
                    // hand outputs of SHAKE
                    case (parse_state) 
                        HAMMING_WEIGHT: begin
                            hw_a <= rdi_data[16*j+7]  + rdi_data[16*j+6]  + rdi_data[16*j+5]  + rdi_data[16*j+4]  + rdi_data[16*j+3]  + rdi_data[16*j+2]  + rdi_data[16*j+1] + rdi_data[16*j+0]; 
                            hw_b <= rdi_data[16*j+15] + rdi_data[16*j+14] + rdi_data[16*j+13] + rdi_data[16*j+12] + rdi_data[16*j+11] + rdi_data[16*j+10] + rdi_data[16*j+9] + rdi_data[16*j+8]; 
                            parse_state <= CALCULATE;
                        end
                        CALCULATE: begin
                            r_val <= hw_a + 14'd12289 - hw_b; // q = 12289
                            r_addr <= 8*i + j;
                            j <= j + 1; 
                            parse_state <= STORE;
                        end 
                        STORE: begin
                            poly_wea <= 1'b1;
                            poly_addra <= r_addr;
                            poly_dia <= r_val;
                            // need exit condition
                            parse_state <= HAMMING_WEIGHT;
                            
                            if (j == 8) begin
                                rdi_ready <= 1'b1;
                                j <= 0;

                                if (i == 63) begin
                                    done <= 1'b1;
                                end else begin
                                    i <= i + 1;
                                end
                            end
                        end
                      endcase
                end
            endcase
        end
    end


endmodule
