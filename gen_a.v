`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/18/2020 01:53:01 PM
// Design Name: 
// Module Name: gen_a
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


module gen_a(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
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
    output [1:0] shake_byte_num,
    output reg shake_squeeze,
    input [0:1087] shake_out,
    input shake_out_ready);
    
    integer NEWHOPE_5Q = 61445;
    localparam
        HOLD    = 3'd0,
        ABSORB  = 3'd1,
        SQUEEZE = 3'd2,
        PARSE   = 3'd3;
    reg [2:0] state, state_next;
    
    // iterate registers registers
    reg [7:0] i;
    reg [6:0] ctr;
    reg [7:0] j;
    reg [3:0] absorb_ctr;
    
    // parse state registers
    reg parse_done;
    
    // connect byte out to shake_in
    assign shake_in = (shake_is_last) ? {i[7:0], 24'b0} : byte_do;
    assign shake_byte_num = 2'd1;
    
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? ABSORB : HOLD;
        end
        ABSORB: begin
            state_next = (shake_is_last == 1'b1) ? SQUEEZE : ABSORB;
        end
        SQUEEZE: begin
            state_next = (shake_squeeze == 1'b0 & shake_out_ready == 1'b1) ? PARSE : SQUEEZE;
        end
        PARSE: begin
            // this logic may need adjustment (need to add squeeze logic)
            state_next = (j == 134 & ctr < 64) ? SQUEEZE : 
                         (ctr == 64 & i == 7) ? HOLD :
                         (ctr == 64 & i < 7) ? ABSORB : PARSE;
        end        
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        // defaults
        done <= 1'b0;
        absorb_ctr <= 0;
    
       // output ram (polynomial)
        poly_wea   <= 1'b0;
        poly_addra <= 9'b0;
        poly_dia   <= 16'b0;
    
        // SHAKE
        shake_rst      <= 1'b0;
        shake_squeeze  <= 1'b0;
        shake_in_ready <= 1'b0;
        shake_is_last  <= 1'b0;
        
        // parse state defaults
        j <= 0;
        i <= i;
        
        // input ram (byte)
        byte_addr <= 3'b0;
        
        if (rst == 1'b1) begin
            shake_rst <= 1;
            i   <= 0;
            j   <= 0;
            ctr <= 0;
        end else begin
               
            case (state) 
            HOLD: begin
                if (start) begin
                    absorb_ctr <= 1; // account for delay of RAM access
                end
            end
            ABSORB: begin
                ctr <= 0;
                if (absorb_ctr < 9) begin
                    // load from RAM
                    byte_addr <= absorb_ctr[2:0];
                    absorb_ctr <= absorb_ctr + 1;

                    // input into SHAKE
                    if (absorb_ctr > 0)
                        shake_in_ready <= 1'b1;
                end else begin
                    // last load in, appends i in assign statement
                    shake_in_ready <= 1'b1;
                    shake_is_last <= 1'b1;
                end
            end
            SQUEEZE: begin
                // just waiting for shake to finish
                ctr <= ctr;
            end
            PARSE: begin
                if ({shake_out[(j+1)*8+:8], shake_out[j*8+:8]} < NEWHOPE_5Q) begin
                    // write value to poly memory
                    poly_wea <= 1'b1;
                    poly_addra <= i*64 + ctr;
                    poly_dia <= {shake_out[(j+1)*8+:8], shake_out[j*8+:8]};
                    ctr <= ctr + 1;
                end else begin
                    ctr <= ctr;
                end
                
                if (j == 134 & ctr < 64) begin
                    // start squeeze if end of current parse state and not done
                    shake_squeeze <= 1'b1;
                end else if (ctr == 64) begin
                    if (i == 7) begin
                        done <= 1'b1;
                        poly_wea <= 1'b0;
                        i <= 0;
                    end else begin
                        // start absorb
                        shake_rst <= 1'b1;
                        absorb_ctr <= 1'b1; // account for delay of RAM access                    
                        i <= i + 1;
                    end
                end else begin
                    // continue parse
                    j <= j + 2;
                end
                
            end        
            endcase
        end
    end
    
endmodule
