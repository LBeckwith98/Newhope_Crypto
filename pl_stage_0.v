`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2020 06:40:06 PM
// Design Name: 
// Module Name: pl_stage_0
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



module pl_stage_0(
    // basic signals
    input clk,
    input rst,
    input en,
    input start_stage,
    output reg done_stage,
    // Coin/Message input
    input we_c,
    input [3:0] addr_c,
    input [31:0] di_c,
    // pubseed input
    input we_ps,
    input [2:0] addr_ps,
    input [31:0] di_ps,
    // pk_poly input
    input we_pk,
    input [9:0] addr_pk,
    input [7:0] di_pk,
    // S' output
    output we_sp,
    output [8:0] addr_sp,
    output [15:0] dout_sp,
    // E' output
    output we_ep,
    output [8:0] addr_ep,
    output [15:0] dout_ep,
    // E'' output
    output we_epp,
    output [8:0] addr_epp,
    output [15:0] dout_epp,
    // V output
    output we_v,
    output [8:0] addr_v,
    output [15:0] dout_v,
    // A output
    output we_a,    
    output [8:0] addr_a,    
    output [15:0] dout_a,    
    // B output
    output we_b,    
    output [8:0] addr_b,    
    output [15:0] dout_b   
    );
    
    localparam
        HOLD           = 2'd0,
        LOAD_BS_BUFFER = 2'd1,
        GEN_A          = 2'd2;
    reg [1:0] state, state_next;    
    
    /* BRAM INSTANCES */
    // COIN/MESSAGE BRAM
    reg COIN_web;
    reg [3:0] COIN_addrb;
    wire [31:0] COIN_doa, COIN_dob;
    dual_port_ram #(.WIDTH(32), .LENGTH(16)) R0_COIN (clk,clk,1'b1,1'b1,we_c,COIN_web,addr_c,COIN_addrb,di_c,32'd0,COIN_doa,COIN_dob);
    
    // PUBSEED BRAM
    wire [2:0] PSEED_addrb;
    wire [31:0] PSEED_doa, PSEED_dob;
    dual_port_ram #(.WIDTH(32), .LENGTH(8)) R1_PSEED (clk,clk,1'b1,1'b1,we_ps,1'b0, addr_ps,PSEED_addrb,di_ps,32'd0,PSEED_doa,PSEED_dob);
    
    // PK_POLY BRAM
    wire [9:0] PK_addrb;
    wire [7:0] PK_doa, PK_dob;
    dual_port_ram #(.WIDTH(8), .LENGTH(896)) R2_PK (clk,clk,1'b1,1'b1,we_pk,1'b0,addr_pk,PK_addrb,di_pk,8'd0,PK_doa,PK_dob);
    
    
    /* SHAKE256 Wires */
    reg en_prng = 1;
//    reg [255:0] seed;
//    wire [127:0] rdi_data;
//    reg reseed;
//    wire reseed_ack, rdi_valid;
//    reg rdi_ready;
    
//    prng_trivium_enhanced #(.N(2)) PRNG (.clk(clk), .rst(rst), .en_prng(en_prng), .seed(seed), .reseed(reseed),
//                        .reseed_ack(reseed_ack), .rdi_data(rdi_data), .rdi_ready(rdi_ready), .rdi_valid(rdi_valid));   
    
    reg [31:0] shake_in;
    reg shake_in_ready, shake_is_last, shake_squeeze, shake_rst;
    reg [1:0] shake_byte_num;
    wire shake_buffer_full;
    wire [1087:0] shake_out;
    wire shake_out_ready;
    keccak SHAKE256 (clk, shake_rst, shake_in, shake_in_ready, shake_is_last, shake_squeeze, shake_byte_num, shake_buffer_full, shake_out, shake_out_ready);
    
    // Module instances
    /* SAMPLER BUFFER */
    wire done_sb, reseed_sb, rdi_ready_sb;
    wire sb_next_0, sb_next_1, sb_next_2;
    // IR
    wire [2:0] baddr_sb;
    // RDI
    wire [255:0] seed_sb;
    wire [127:0] sb_0, sb_1, sb_2;
    
    wire [31:0] shake_in_sb;
    wire shake_in_ready_sb, shake_is_last_sb, shake_rst_sb;
    wire [1:0] shake_byte_num_sb;
    
    sampler_buffer SAMPLER_BUF (clk, rst, start_stage, done_sb, baddr_sb, COIN_dob,
                        shake_rst_sb, shake_in_sb, shake_in_ready_sb, 
                        shake_is_last_sb, shake_byte_num_sb,
                        shake_out[1087:1087-1023], shake_out_ready, // shake wires
                        sb_next_0, sb_next_1, sb_next_2, sb_0, sb_1, sb_2);
    
    /* BINOMIAL SAMPLERS */
    reg start_bs;
    wire done_bs0, done_bs1, done_bs2;
    // S' sampler
    binomial_sampler_pl BS0_SP (clk, rst, start_bs, done_bs0, we_sp, addr_sp, dout_sp, sb_next_0, sb_0);
    // E' sampler
    binomial_sampler_pl BS1_EP (clk, rst, start_bs, done_bs1, we_ep, addr_ep, dout_ep, sb_next_1, sb_1);
    // E'' sampler
    binomial_sampler_pl BS2_EPP (clk, rst, start_bs, done_bs2, we_epp, addr_epp, dout_epp, sb_next_2, sb_2);
    
    
    /* GEN A */
    reg start_enc_ga;
    wire done_ga;
    
    wire [31:0] shake_in_ga;
    wire shake_in_ready_ga, shake_is_last_ga, shake_squeeze_ga, shake_rst_ga;
    wire [1:0] shake_byte_num_ga;
    
    gen_a GENA (clk, rst, start_enc_ga, done_ga, // ctrl
                 PSEED_addrb, PSEED_dob,    // in ram
                 we_a, addr_a, dout_a,      // out ram
                 shake_rst_ga, shake_in_ga, shake_in_ready_ga, 
                 shake_is_last_ga, shake_byte_num_ga,
                 shake_squeeze_ga, shake_out, shake_out_ready);
   
    /* ENCODER */ 
    wire done_enc;
    wire [2:0] baddr_enc;
    encoder_pl ENC(clk, rst, start_enc_ga, done_enc, baddr_enc, COIN_dob, 
                        we_v, addr_v, dout_v);
    
    /* POLYNOMIAL DECODER */
    wire done_pd;
    polynomial_decoder POLY_DEC(clk, rst, start_stage, done_pd, PK_addrb, PK_dob,
                                we_b, addr_b, dout_b);
    
    // TRIVIUM access wires
    always @(*) begin
        // default to first user
        shake_in = shake_in_sb;
        shake_in_ready = shake_in_ready_sb;
        shake_is_last = shake_is_last_sb;
        shake_squeeze = 0;
        shake_rst = shake_rst_sb;
        shake_byte_num = shake_byte_num_sb;
        
        case (state) 
        LOAD_BS_BUFFER: begin
            // BS BUFFER
            shake_in = shake_in_sb;
            shake_in_ready = shake_in_ready_sb;
            shake_is_last = shake_is_last_sb;
            shake_squeeze = 0;
            shake_rst = shake_rst_sb;
            shake_byte_num = shake_byte_num_sb;
        end
        GEN_A: begin
            // GEN A MODULE
            shake_in = shake_in_ga;
            shake_in_ready = shake_in_ready_ga;
            shake_is_last = shake_is_last_ga;
            shake_squeeze = shake_squeeze_ga;
            shake_rst = shake_rst_ga;
            shake_byte_num = shake_byte_num_ga;
        end
        endcase
    end
    
    // RAM access wires
    always @(*) begin
        // defaults to first user
        COIN_web = 0;
        COIN_addrb = {1'b0, baddr_sb};
        
        case (state) 
        LOAD_BS_BUFFER: begin
            // BS BUFFER
            COIN_web = 0;
            COIN_addrb = {1'b0, baddr_sb};
        end
        GEN_A: begin
            // ENCODER
            COIN_web = 0;
            COIN_addrb = {1'b1, baddr_enc};
        end
        endcase
    end
    
    // Control logic
    always @(*) begin       
        state_next = HOLD;
     
        case (state) 
        HOLD: begin
            state_next = (start_stage) ? LOAD_BS_BUFFER : HOLD;
        end
        LOAD_BS_BUFFER: begin
            state_next = (done_sb) ? GEN_A : LOAD_BS_BUFFER;
        end
        GEN_A: begin
            state_next = (done_bs0) ? HOLD : GEN_A;
        end
        endcase
    end
    
    always @(posedge clk) begin
        if (en)
            state = (rst) ? HOLD : state_next;    
    end
    
    // output logic
    always @(posedge clk) begin 
        start_bs <= 1'b0;
        start_enc_ga <= 1'b0;
        
        done_stage <= 1'b0;
        start_bs <= (done_sb) ? 1'b1 : 1'b0;
        start_enc_ga <= (done_sb) ? 1'b1 : 1'b0;
        done_stage <= (done_bs0) ? 1'b1 : 1'b0;
    end
    
endmodule

