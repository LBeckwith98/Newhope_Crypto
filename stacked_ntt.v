`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2020 05:38:54 PM
// Design Name: 
// Module Name: stacked_ntt
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


module stacked_ntt(
    input clk,
    input rst,
    input start_round,
    input en,
    output done,
    // input ram signals
    input IN_we,
    input [8:0]  IN_addr,
    input [15:0] IN_di,
    // output ram signals
    input  [8:0]  OUT_addr,
    output reg [15:0] OUT_do
    );
    
    parameter MODE = 1'b0; // forward -> 0, inverse -> 1* *still hase bitrev
    
    localparam 
        S0   = 3'd0,
        S1   = 3'd1,
        S2   = 3'd2,
        S3   = 3'd3,
        HOLD = 3'd4;
    reg [3:0] state, state_next;
    
    /* --- BRAM MODULE DECLARATIONS --- */
    reg        PR0_wea,   PR0_web;
    reg [8:0]  PR0_addra, PR0_addrb;
    reg [15:0] PR0_dia,   PR0_dib;
    wire [15:0] PR0_doa,   PR0_dob;
    dual_port_ram #(.WIDTH(16), .LENGTH(512)) PRAM0 (clk,clk,en,en,PR0_wea,PR0_web,PR0_addra,PR0_addrb,PR0_dia,PR0_dib,PR0_doa,PR0_dob);
    
    reg        PR1_wea,   PR1_web;
    reg [8:0]  PR1_addra, PR1_addrb;
    reg [15:0] PR1_dia,   PR1_dib;
    wire [15:0] PR1_doa,   PR1_dob;
    dual_port_ram #(.WIDTH(16), .LENGTH(512)) PRAM1 (clk,clk,en,en,PR1_wea,PR1_web,PR1_addra,PR1_addrb,PR1_dia,PR1_dib,PR1_doa,PR1_dob);
      
    reg        PR2_wea,   PR2_web;
    reg [8:0]  PR2_addra, PR2_addrb;
    reg [15:0] PR2_dia,   PR2_dib;
    wire [15:0] PR2_doa,   PR2_dob;
    dual_port_ram #(.WIDTH(16), .LENGTH(512)) PRAM2 (clk,clk,en,en,PR2_wea,PR2_web,PR2_addra,PR2_addrb,PR2_dia,PR2_dib,PR2_doa,PR2_dob);
    
    reg        PR3_wea,   PR3_web;
    reg [8:0]  PR3_addra, PR3_addrb;
    reg [15:0] PR3_dia,   PR3_dib;
    wire [15:0] PR3_doa,   PR3_dob;
    dual_port_ram #(.WIDTH(16), .LENGTH(512)) PRAM3 (clk,clk,en,en,PR3_wea,PR3_web,PR3_addra,PR3_addrb,PR3_dia,PR3_dib,PR3_doa,PR3_dob);
    
    /* --- NTT MODULE DECLARATIONS --- */
    reg         ntt1_start;
    wire        ntt1_done;
    wire        ntt1_poly_wea, ntt1_poly_web;
    wire [8:0]  ntt1_poly_addra, ntt1_poly_addrb;
    wire [15:0] ntt1_poly_dia, ntt1_poly_dib;
    reg  [15:0] ntt1_doa, ntt1_dob;
    ntt #(.BITREV(0)) NTT1 (clk, rst, ntt1_start, MODE, ntt1_done,
                ntt1_poly_wea, ntt1_poly_web, ntt1_poly_addra, ntt1_poly_addrb,
                ntt1_poly_dia, ntt1_poly_dib, ntt1_doa, ntt1_dob);
    
    reg         ntt2_start;
    wire        ntt2_done;
    wire        ntt2_poly_wea, ntt2_poly_web;
    wire [8:0]  ntt2_poly_addra, ntt2_poly_addrb;
    wire [15:0] ntt2_poly_dia, ntt2_poly_dib;
    reg  [15:0] ntt2_doa, ntt2_dob;
    ntt #(.BITREV(0)) NTT2 (clk, rst, ntt2_start, MODE, ntt2_done,
                ntt2_poly_wea, ntt2_poly_web, ntt2_poly_addra, ntt2_poly_addrb,
                ntt2_poly_dia, ntt2_poly_dib, ntt2_doa, ntt2_dob);
    
    /* --- CONNECTIONS --- */
    always @(*) begin
        // DEFAULT ALL SIGNALS TO 0
        PR0_wea   = 0; PR0_web = 0;
        PR0_addra = 0; PR0_addrb = 0;
        PR0_dia   = 0; PR0_dib =  0;
        
        PR1_wea   = 0; PR1_web = 0;
        PR1_addra = 0; PR1_addrb = 0;
        PR1_dia   = 0; PR1_dib =  0;
        
        PR2_wea   = 0; PR2_web = 0;
        PR2_addra = 0; PR2_addrb = 0;
        PR2_dia   = 0; PR2_dib =  0;
        
        PR3_wea   = 0; PR3_web = 0;
        PR3_addra = 0; PR3_addrb = 0;
        PR3_dia   = 0; PR3_dib =  0;
        
        ntt1_doa  = 0; ntt1_dob = 0;
        ntt2_doa  = 0; ntt2_dob = 0;
        
        OUT_do = 0;
        
        case (state)
        HOLD: begin
            // DATA ENTERS INTO R0
            PR0_wea   = IN_we;
            PR0_addra = IN_addr;
            PR0_dia   = IN_di;
            
            // DATA EXITS R2
            PR2_addra = OUT_addr;
            OUT_do    = PR2_doa;
            
            // NO NTT ACCESS
        end
        S0: begin
            // DATA ENTERS INTO R1
            PR1_wea   = IN_we;
            PR1_addra = IN_addr;
            PR1_dia   = IN_di;
            
            // DATA EXITS R2
            PR2_addra = OUT_addr;
            OUT_do    = PR2_doa;
            
            // NTT1: R0
            PR0_wea = ntt1_poly_wea;     PR0_web = ntt1_poly_web;
            PR0_addra = ntt1_poly_addra; PR0_addrb = ntt1_poly_addrb;
            PR0_dia = ntt1_poly_dia;     PR0_dib =  ntt1_poly_dib;
            ntt1_doa = PR0_doa;          ntt1_dob = PR0_dob;
            
            // NTT2: R3
            PR3_wea = ntt2_poly_wea;     PR3_web = ntt2_poly_web;
            PR3_addra = ntt2_poly_addra; PR3_addrb = ntt2_poly_addrb;
            PR3_dia = ntt2_poly_dia;     PR3_dib =  ntt2_poly_dib;
            ntt2_doa = PR3_doa;          ntt2_dob = PR3_dob;
        end
        S1: begin
            // DATA ENTERS INTO R2
            PR2_wea   = IN_we;
            PR2_addra = IN_addr;
            PR2_dia   = IN_di;
            
            // DATA EXITS R3
            PR3_addra = OUT_addr;
            OUT_do    = PR3_doa;
            
            // NTT1: R0
            PR0_wea = ntt1_poly_wea;     PR0_web = ntt1_poly_web;
            PR0_addra = ntt1_poly_addra; PR0_addrb = ntt1_poly_addrb;
            PR0_dia = ntt1_poly_dia;     PR0_dib =  ntt1_poly_dib;
            ntt1_doa = PR0_doa;          ntt1_dob = PR0_dob;
            
            // NTT2: R1
            PR1_wea = ntt2_poly_wea;     PR1_web = ntt2_poly_web;
            PR1_addra = ntt2_poly_addra; PR1_addrb = ntt2_poly_addrb;
            PR1_dia = ntt2_poly_dia;     PR1_dib =  ntt2_poly_dib;
            ntt2_doa = PR1_doa;          ntt2_dob = PR1_dob;
        end
        S2: begin
            // DATA ENTERS INTO R3
            PR3_wea   = IN_we;
            PR3_addra = IN_addr;
            PR3_dia   = IN_di;
            
            // DATA EXITS R0
            PR0_addra = OUT_addr;
            OUT_do    = PR0_doa;
            
            // NTT1: R2
            PR2_wea = ntt1_poly_wea;     PR2_web = ntt1_poly_web;
            PR2_addra = ntt1_poly_addra; PR2_addrb = ntt1_poly_addrb;
            PR2_dia = ntt1_poly_dia;     PR2_dib =  ntt1_poly_dib;
            ntt1_doa = PR2_doa;          ntt1_dob = PR2_dob;
            
            // NTT2: R1
            PR1_wea = ntt2_poly_wea;     PR1_web = ntt2_poly_web;
            PR1_addra = ntt2_poly_addra; PR1_addrb = ntt2_poly_addrb;
            PR1_dia = ntt2_poly_dia;     PR1_dib =  ntt2_poly_dib;
            ntt2_doa = PR1_doa;          ntt2_dob = PR1_dob;
        end
        S3: begin
            // DATA ENTERS INTO R0
            PR0_wea   = IN_we;
            PR0_addra = IN_addr;
            PR0_dia   = IN_di;
            
            // DATA EXITS R1
            PR1_addra = OUT_addr;
            OUT_do    = PR1_doa;
            // NTT1: R2
            PR2_wea = ntt1_poly_wea;     PR2_web = ntt1_poly_web;
            PR2_addra = ntt1_poly_addra; PR2_addrb = ntt1_poly_addrb;
            PR2_dia = ntt1_poly_dia;     PR2_dib =  ntt1_poly_dib;
            ntt1_doa = PR2_doa;          ntt1_dob = PR2_dob;
            
            // NTT2: R3
            PR3_wea = ntt2_poly_wea;     PR3_web = ntt2_poly_web;
            PR3_addra = ntt2_poly_addra; PR3_addrb = ntt2_poly_addrb;
            PR3_dia = ntt2_poly_dia;     PR3_dib =  ntt2_poly_dib;
            ntt2_doa = PR3_doa;          ntt2_dob = PR3_dob;
        end
        endcase
    end
    
    
    
    /* --- STATE LOGIC --- */ 
    always @(*) begin
        state_next = HOLD;
    
        case (state)
        HOLD: begin
            state_next = (start_round) ? S0 : HOLD;
        end
        S0: begin
            state_next = (start_round) ? S1 : S0;
        end
        S1: begin
            state_next = (start_round) ? S2 : S1;
        end
        S2: begin
            state_next = (start_round) ? S3 : S2;
        end
        S3: begin
            state_next = (start_round) ? S0 : S3;        
        end
        endcase
    end
    
    always @(posedge clk) begin
       state <= (rst) ? HOLD : state_next; 
    end
   
   
    assign done = ntt1_done | ntt2_done;
    /* --- CTRL LOGIC --- */
    always @(posedge clk) begin
        ntt1_start <= 1'b0;
        ntt2_start <= 1'b0;
        
        case (state)
        HOLD: begin
            ntt1_start <= (start_round) ? 1'b1 : 1'b0;
        end
        S0: begin
            ntt2_start <= (start_round) ? 1'b1 : 1'b0;
        end
        S1: begin
            ntt1_start <= (start_round) ? 1'b1 : 1'b0;
        end
        S2: begin
            ntt2_start <= (start_round) ? 1'b1 : 1'b0;
        end
        S3: begin
            ntt1_start <= (start_round) ? 1'b1 : 1'b0;
        end
        endcase

    end
   
endmodule
