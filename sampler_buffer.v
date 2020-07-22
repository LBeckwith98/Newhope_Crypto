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
    // SHAKE256 module signals
    output reg shake_rst,
    output [31:0] shake_in,
    output reg shake_in_ready,
    output reg shake_is_last,
    output reg [1:0] shake_byte_num,
    input [0:1023] shake_out,
    input shake_out_ready,
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
        LOAD_SHAKE = 3'd1,
        WAIT_SHAKE = 3'd2,
        PARSE      = 3'd3;
    reg [2:0] state = HOLD, state_next;
    reg parse_done;
    
    // CTRL signals
    reg [7:0] ctr = 0, j = 0;
    wire [7:0] nonce;
    reg [7:0] i = 0;
    
    assign nonce = (j < 64) ? 8'd0 
                    : (j < 128) ? 8'd1
                    : 8'd2;
    assign shake_in = (shake_is_last) ? {nonce, i[7:0], 16'b0} : byte_do;

    // Buffer signals
    reg [127:0] SI_0, SI_1,SI_2;
    reg load_0, load_1, load_2;
    wire en_0, en_1, en_2;
    
    // buffer ctrl signals
    assign en_0 = (state == HOLD) ? bs_en_0 : load_0;
    assign en_1 = (state == HOLD) ? bs_en_1 : load_1;
    assign en_2 = (state == HOLD) ? bs_en_2 : load_2;
    
    // SR BRAM
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR0 (clk, en_0, SI_0, SO_0);
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR1 (clk, en_1, SI_1, SO_1);
    shift_ram #(.DEPTH(64), .DATA_WIDTH(128)) SR2 (clk, en_2, SI_2, SO_2);
    

  
    // combinational state logic
    always @(*) begin
            state_next = HOLD;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? LOAD_SHAKE : HOLD;
        end
        LOAD_SHAKE: begin
            state_next = (shake_is_last) ? WAIT_SHAKE : LOAD_SHAKE;
        end
        WAIT_SHAKE: begin
            state_next = (shake_out_ready) ? PARSE : WAIT_SHAKE;
        end
        PARSE: begin
            state_next = (j == 192) ? HOLD : 
                    (parse_done) ? LOAD_SHAKE : PARSE;
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
        SI_0 <= 0;
        SI_1 <= 0;
        SI_2 <= 0;
        parse_done <= 0;
        ctr <= 0;
        j <= j;
        i <= i;
        
        // SHAKE
        shake_rst <= 1'b0;
        shake_in_ready <= 1'b0;
        shake_is_last  <= 1'b0;
        shake_byte_num <= 2'b0;
    
        case (state) 
        HOLD: begin
            ctr <= 0;
            j <= 0;
            i <= i;
            byte_addr <= 0;
            
            if (start) begin
                shake_rst <= 1'b1;
                ctr <= ctr + 1;
            end 
        end
        LOAD_SHAKE: begin
            ctr <= ctr;
            shake_rst <= 1'b0;
            if (ctr < 9) begin
                // load from RAM
                byte_addr <= ctr[2:0];
                ctr <= ctr + 1;

                // input into SHAKE
                if (ctr > 0)
                    shake_in_ready <= 1'b1;
            end else begin
                // last load in, append nonce and i
                shake_in_ready <= 1'b1;
                shake_is_last  <= 1'b1;
                shake_byte_num <= 2'd2;
           end
        end
        WAIT_SHAKE: begin
            ctr <= 0;
        end
        PARSE: begin
            if (j < 64) begin
                load_0 <= 1'b1;
                SI_0   <= shake_out[128*j[2:0]+:128];
            end else if (j < 128) begin
                load_1 <= 1'b1;
                SI_1   <= shake_out[128*j[2:0]+:128];
            end else begin
                load_2 <= 1'b1;
                SI_2   <= shake_out[128*j[2:0]+:128];
            end
            j <= j + 1;
            
            if (j[2:0] == 3'd7) begin
                parse_done <= 1'b1; // run SHAKE again
                i <= i + 1;
            end
            
            if (j[5:0] == 63)
                i <= 0;
            
            if (j == 192) 
                done <= 1'b1;
        end        
        endcase
    end
    
    
endmodule
