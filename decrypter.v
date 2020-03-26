`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2020 02:50:52 PM
// Design Name: 
// Module Name: decrypter
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


module decrypter(
    input clk,
    input rst,
    // control signals
    input start,
    output reg decrypter_done,    
    // byte data input
    input [7:0] input_dia,
    input input_wea,
    input [10:0] input_addra,
    // output (size mismatch with input should be fixed)
    input [2:0] output_addr, 
    output [31:0] output_do
    );
    
    localparam
        HOLD       = 3'd0,
        UNPACK_1   = 3'd1,
        UNPACK_2   = 3'd2,
        MULT       = 3'd3,
        INV_NTT    = 3'd4,
        GAMMA_MULT = 3'd5,
        SUB        = 3'd6,
        DECODE     = 3'd7;
    reg [2:0] decrypter_state, decrypter_state_next;
          
    /* POLY DEC WIRES */
    reg start_pd;
    wire done_pd;
    wire [9:0] in_addr_pd;
    wire [8:0] poly_addra_pd;
    wire [15:0] poly_dia_pd;
    wire poly_wea_pd; 
    
    /* DECOMPRESSOR WIRES */
    reg start_decomp;
    wire done_decomp;
    wire [9:0] in_addrb_decomp;
    wire poly_web_decomp;
    wire [8:0] poly_addrb_decomp;
    wire [15:0] poly_dib_decomp;
    
    /* DECODER WIRES */
    reg start_dec;
    wire done_dec;
    wire out_we_dec;
    wire [2:0] out_addr_dec;
    wire [31:0] out_di_dec;
    wire [8:0] poly_addra_dec;
    
    /* POLY ARTHIMETIC WIRE */
    reg start_pa;
    wire done_pa;
    reg [1:0] op_code_pa;
    wire poly_wea_pa;
    wire [8:0] poly_addr_pa;
    wire [15:0] poly_dia_pa;
    
    /* NTT WIRES */
    reg start_ntt;
    wire done_ntt;
    wire poly_wea_ntt, poly_web_ntt;
    wire [8:0] poly_addra_ntt, poly_addrb_ntt;
    wire [15:0] poly_dia_ntt, poly_dib_ntt, poly_doa_ntt, poly_dob_ntt;
    
    /* ---  INPUT RAM --- */
    wire IR_clka, IR_clkb, IR_wea;
    wire [10:0] IR_addra, IR_addrb;
    wire [7:0] IR_dia, IR_doa, IR_dob;    
    
    assign IR_addra = (decrypter_state == HOLD) ? input_addra :
                        (decrypter_state == UNPACK_1) ? {1'b0, in_addr_pd} :
                        (decrypter_state == UNPACK_2) ? {1'b0, in_addr_pd} + 11'd1088 : 11'd0; // poly_decode offest for 2nd val
    assign IR_wea = input_wea;
    assign IR_dia = input_dia;
    assign IR_addrb = {1'b0, in_addrb_decomp} + 11'd896; // decomp addr is shifted
    dual_port_ram #(.MEM_WIDTH(8), .MEM_SIZE(1984)) I_RAM (clk,clk,1'b1,1'b1,IR_wea,1'b0,IR_addra,IR_addrb,IR_dia,8'd0,IR_doa,IR_dob);
    
    /* --- POLYNOMIAL RAM --- */    
    wire [15:0] PR_doa, PR_dob, PR_dia, PR_dib;
    wire PR_wea, PR_web;
    wire [10:0] PR_addra, PR_addrb;
    
   
    // A port assignments
    assign PR_addra = (decrypter_state == UNPACK_1) ? {2'd3, poly_addra_pd} :
                      (decrypter_state == UNPACK_2) ? {2'd1, poly_addra_pd} :
                      (decrypter_state == INV_NTT) ? {2'd3, poly_addra_ntt} :
                      (decrypter_state == DECODE) ? {2'd3, poly_addra_dec} :
                      {2'd3, poly_addr_pa}; // poly_arith
   assign PR_wea = (decrypter_state == UNPACK_1 || decrypter_state == UNPACK_2) ? poly_wea_pd :
                      (decrypter_state == INV_NTT) ? poly_wea_ntt :
                      (decrypter_state == DECODE) ? 1'd0 :
                      poly_wea_pa; // poly_arith
   assign PR_dia = (decrypter_state == UNPACK_1 || decrypter_state == UNPACK_2) ? poly_dia_pd :
                      (decrypter_state == INV_NTT) ? poly_dia_ntt :
                      (decrypter_state == DECODE) ? 16'd0:
                      poly_dia_pa; // poly_arithder            
    
    // B port assignments  
    assign PR_addrb = (decrypter_state == UNPACK_1 || decrypter_state == UNPACK_2) ? {2'd2, poly_addrb_decomp} :
                      (decrypter_state == INV_NTT) ? {2'd3, poly_addrb_ntt} :
                      (decrypter_state == MULT) ? {2'd1, poly_addr_pa} : 
                      (decrypter_state == GAMMA_MULT) ? {2'd0, poly_addr_pa} : {2'd2, poly_addr_pa}; // poly_arithmetic
    assign PR_web = (decrypter_state == UNPACK_1 || decrypter_state == UNPACK_2) ? poly_web_decomp :
                    (decrypter_state == INV_NTT) ? poly_web_ntt :
                    1'd0; // poly_arithmetic
    assign PR_dib = (decrypter_state == UNPACK_1 || decrypter_state == UNPACK_2) ? poly_dib_decomp :
                    (decrypter_state == INV_NTT) ? poly_dib_ntt :
                    16'd0; // poly_arithmetic 
    
    poly_ram #(.INVERSE_GAMMAS(1)) P_RAM(clk,clk,1'b1, 1'b1, PR_wea, PR_web, PR_addra, PR_addrb, PR_dia, PR_dib, PR_doa, PR_dob);       
        
    /* --- OUTPUT RAM --- */
    wire OR_we;
    wire [2:0] OR_addr;
    wire [31:0] OR_di;
    wire [31:0] OR_do;
    assign OR_di = out_di_dec;
    assign OR_we = out_we_dec;
    assign output_do = OR_do;
    assign OR_addr = (decrypter_state == HOLD) ? output_addr : out_addr_dec;
    
    single_port_ram #(.MEM_WIDTH(32), .MEM_SIZE(8)) O_RAM (clk, OR_we, 1'b1, OR_addr, OR_di, OR_do);
    
    /* --- SUBMODULE INSTANCES --- */   
    polynomial_decoder POLY_DEC (clk, rst, start_pd, done_pd, in_addr_pd, IR_doa, poly_wea_pd, poly_addra_pd, poly_dia_pd);
    
    decompressor DECOMP(clk, rst, start_decomp, done_decomp, in_addrb_decomp, IR_dob, 
                            poly_web_decomp, poly_addrb_decomp, poly_dib_decomp);
        
    decoder DEC (clk, rst, start_dec, done_dec, out_we_dec, out_addr_dec, out_di_dec, poly_addra_dec, PR_doa);
        
    poly_arithmetic POLY_ARITH(clk, rst, start_pa, done_pa, op_code_pa, poly_wea_pa,
                                poly_addr_pa, PR_doa, PR_dob, poly_dia_pa);
    
    ntt NTT(clk, rst, start_ntt, 1'b1, done_ntt, poly_wea_ntt, poly_web_ntt,
            poly_addra_ntt, poly_addrb_ntt, poly_dia_ntt, poly_dib_ntt, 
            PR_doa, PR_dob);
    
    /* --- Start controller logic --- */
    
    // combinational state logic
    always @(*) begin
        decrypter_state_next = decrypter_state;
    
        case (decrypter_state_next) 
        HOLD: begin
            decrypter_state_next = (start) ? UNPACK_1 : HOLD;
        end
        UNPACK_1: begin
            decrypter_state_next = (done_pd) ? UNPACK_2 : UNPACK_1;
        end
        UNPACK_2: begin
            decrypter_state_next = (done_pd) ? MULT : UNPACK_2;
        end
        MULT: begin
            decrypter_state_next = (done_pa) ? INV_NTT : MULT;
        end
        INV_NTT: begin
            decrypter_state_next = (done_ntt) ? GAMMA_MULT : INV_NTT;
        end
        GAMMA_MULT : begin
            decrypter_state_next = (done_pa) ? SUB : GAMMA_MULT;
        end
        SUB: begin
            decrypter_state_next = (done_pa) ? DECODE : SUB;
        end
        DECODE: begin
            decrypter_state_next = (done_dec) ? HOLD : DECODE;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        decrypter_state <= (rst) ? HOLD : decrypter_state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        // defaults
        start_pd <= 1'b0;
        start_decomp <= 1'b0;
        start_pa <= 1'b0;
        start_ntt <= 1'b0;
        start_dec <= 1'b0;
        decrypter_done <= 1'b0;
    
        case (decrypter_state) 
        HOLD: begin
            if (start) begin
                start_pd <= 1'b1;
                start_decomp <= 1'b1;
            end
        end
        UNPACK_1: begin
            if (done_pd) begin
                start_pd <= 1'b1;
            end
        end
        UNPACK_2: begin
            if (done_pd) begin
                start_pa <= 1'b1;
                op_code_pa <= 2'd0; // mult
            end
        end
        MULT: begin
            if (done_pa) begin
                start_ntt <= 1'b1;
            end
        end
        INV_NTT: begin
            if (done_ntt) begin
                start_pa <= 1'b1;
                op_code_pa <= 2'd3; // mult_precomp
            end
        end
        GAMMA_MULT: begin
            if (done_pa) begin
                start_pa <= 1'b1;
                op_code_pa <= 2'd2; // sub
            end
        end
        SUB: begin
            if (done_pa) begin
                start_dec <= 1'b1;
            end
        end
        DECODE: begin
            if (done_dec) begin
                decrypter_done <= 1'b1;
            end
        end
        endcase
    end
endmodule
