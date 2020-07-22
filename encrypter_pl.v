`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipelined NewHope implementation
//////////////////////////////////////////////////////////////////////////////////


module encrypter_pl(
    input clk,
    input rst,
    input en,
    input ready,
    output valid,
    output reg start_stage,
    // coin input
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
    // Compress(V'') out (BYTES)
    input [7:0] baddr_h,
    output [7:0] bdout_h,
    // EncodePoly(A) out (BYTES)
    input [9:0] baddr_c,
    output [7:0] bdout_c
    );
    
    wire done_s0, done_s1, done_s2, done_s3, done_s4, done_s5, done_s6, done_s7;
    
    // STAGE 0 WIRES
    wire we_sp_s0, we_ep_s0, we_epp_s0, we_v_s0, we_a_s0, we_b_s0;
    wire [8:0] addr_sp_s0, addr_ep_s0, addr_epp_s0, addr_v_s0, addr_a_s0, addr_b_s0;
    wire [15:0] dout_sp_s0, dout_ep_s0, dout_epp_s0, dout_v_s0, dout_a_s0, dout_b_s0;
    
    pl_stage_0 STAGE_0 (clk, rst, en, start_stage, done_s0,
                        we_c, addr_c, di_c,                  // Coin input
                        we_ps, addr_ps, di_ps,               // pubseed input
                        we_pk, addr_pk, di_pk,               // pk_poly input
                        we_sp_s0, addr_sp_s0, dout_sp_s0,    // S' output
                        we_ep_s0, addr_ep_s0, dout_ep_s0,    // E' output
                        we_epp_s0, addr_epp_s0, dout_epp_s0, // E'' output
                        we_v_s0, addr_v_s0, dout_v_s0,       // V output
                        we_a_s0, addr_a_s0, dout_a_s0,       // A output  
                        we_b_s0, addr_b_s0, dout_b_s0        // B output
                        );
    
    // STAGE 1 WIRES
    wire we_r0_s1, we_r1_s1, we_r2_s1;
    wire [8:0] addr_r0_s1, addr_r1_s1, addr_r2_s1;
    wire [15:0] dout_r0_s1, dout_r1_s1, dout_r2_s1;
    pl_stage_1 STAGE_1 (clk, rst, en, start_stage, done_s1,
                        we_sp_s0, addr_sp_s0, dout_sp_s0,    // S' input signals
                        we_ep_s0, addr_ep_s0, dout_ep_s0,    // E' input signals
                        we_epp_s0, addr_epp_s0, dout_epp_s0, // E'' input signals
                        we_v_s0, addr_v_s0, dout_v_s0,       // v input signals
                        we_r0_s1, addr_r0_s1, dout_r0_s1,    // S' * G out (result 0)
                        we_r1_s1, addr_r1_s1, dout_r1_s1,    // E' * G out (result 1) 
                        we_r2_s1, addr_r2_s1, dout_r2_s1     // E'' + V out (result 2)
                        );
    
    // STAGE 2 WIRES
    wire [8:0] addr_sp_s2, addr_ep_s2;
    wire [15:0] do_sp_s2, do_ep_s2;
    
    pl_stage_2 STAGE_2 (clk, rst, en, start_stage, done_s2,
                        we_r0_s1, addr_r0_s1, dout_r0_s1, // S' * G input   
                        we_r1_s1, addr_r1_s1, dout_r1_s1, // E' * G input
                        addr_sp_s2, do_sp_s2,             // output NTT(S') OWNED
                        addr_ep_s2, do_ep_s2              // output NTT(E') OWNED
                        );
    
    // STAGE 3 WIRES
    wire we_ep_s3, we_r0_s3, we_r1_s3;
    wire [8:0] addr_ep_s3, addr_r0_s3, addr_r1_s3;
    wire [15:0] dout_ep_s3, dout_r0_s3, dout_r1_s3;
    
    pl_stage_3 STAGE_3(clk, rst, en, start_stage, done_s3,
                        we_a_s0, addr_a_s0, dout_a_s0,    // A input  
                        we_b_s0, addr_b_s0, dout_b_s0,    // B input
                        addr_ep_s2, do_ep_s2,             // Input NTT(E') OWNED
                        we_ep_s3, addr_ep_s3, dout_ep_s3, // NTT(E') passthrough output
                        addr_sp_s2, do_sp_s2,             // output NTT(S') OWNED BY NTT
                        we_r0_s3, addr_r0_s3, dout_r0_s3, // A * NTT(S') output
                        we_r1_s3, addr_r1_s3, dout_r1_s3  // B * NTT(S') output
                        );
        
    // STAGE 4 WIRES
    wire we_r0_s4;
    wire [8:0] addr_r0_s4, addr_bntt_s4;
    wire [15:0] dout_r0_s4, do_bntt_s4;
    
    pl_stage_4 STAGE_4(clk, rst, en, start_stage, done_s4,
                        we_r0_s3, addr_r0_s3, dout_r0_s3, // A * NTT(S') input
                        we_ep_s3, addr_ep_s3, dout_ep_s3, // E' input
                        we_r1_s3, addr_r1_s3, dout_r1_s3, // B * NTT(S') input 
                        we_r0_s4, addr_r0_s4, dout_r0_s4, // A * NTT(S') + E' output
                        addr_bntt_s4, do_bntt_s4          // output NTT_INV(B) OWNED BY NTT
                        );
                
    // STAGE 5 WIRES            
    wire we_r1_s5;
    wire [8:0] addr_r1_s5;
    wire [15:0] dout_r1_s5;
    pl_stage_5 STAGE_5 (clk, rst, en, start_stage, done_s5,
                        addr_bntt_s4, do_bntt_s4,        // NTT_INV(B* NTT(S')) input (NTT OWNED)
                        we_r1_s5, addr_r1_s5, dout_r1_s5 // B * G_inv output
                        );     
    
    // STAGE 6 WIRES
    wire we_r0_s6;
    wire [8:0] addr_r0_s6;
    wire [15:0] dout_r0_s6;
    
    pl_stage_6 STAGE_6 (clk, rst, en, start_stage, done_s6,
                        we_r1_s5, addr_r1_s5, dout_r1_s5, // NTT_INV(B* NTT(S')) * G_inv INPUT
                        we_r2_s1, addr_r2_s1, dout_r2_s1, // E'' + V INPUT 
                        we_r0_s6, addr_r0_s6, dout_r0_s6  // B + V' OUTPUT
                        );
    
    // STAGE 7 WIRES
    wire bwe_h_s7, bwe_c_s7;
    wire [9:0] baddr_c_s7;
    wire [7:0] baddr_h_s7, bdi_h_s7, bdi_c_s7;
    pl_stage_7 STAGE_7 (clk, rst, en, start_stage, done_s7,
                        we_r0_s4, addr_r0_s4, dout_r0_s4, //  A * NTT(S') + E' input
                        we_r0_s6, addr_r0_s6, dout_r0_s6, // V'' <- B + V' input 
                        bwe_h_s7, baddr_h_s7, bdi_h_s7,   // Compress(V'') out (BYTES)
                        bwe_c_s7, baddr_c_s7, bdi_c_s7    // EncodePoly(A) out (BYTES)
                        );

    // blocks are larger than neccessary to keep addressing simple
    delay_block_ram #(.LENGTH(0), .WIDTH(8), .BLOCK_SIZE(256)) 
        R1_H (clk, rst, start_stage,
                bwe_h_s7, baddr_h_s7, bdi_h_s7, // write in
                baddr_h, bdout_h // read out
                );
    
    // blocks are larger than neccessary to keep addressing simple
    delay_block_ram #(.LENGTH(0), .WIDTH(8), .BLOCK_SIZE(1024)) 
        R2_C (clk, rst, start_stage,
                bwe_c_s7, baddr_c_s7, bdi_c_s7, // write in
                baddr_c, bdout_c // read out
                );
    
    // Control logic
    localparam SR_LEN = 11;
    reg running = 0;
    reg [SR_LEN-1:0] valid_sr = 0;
    assign valid = valid_sr[SR_LEN-1];
    
    reg [11:0] sys_ctr = 0;
    always @(posedge clk) begin
        start_stage <= 1'b0;
        valid_sr <= valid_sr;
        running <= (en) ? running : 1'b0;
        
        // start if round has finished
        if (en && (sys_ctr == 2305)) begin
            start_stage <= 1'b1;
            valid_sr <= {valid_sr[SR_LEN-2:0], ready};
//            $stop;
        end
        
        // start if en and not running yet (starting operation)
        if (en && !running && ready) begin
            start_stage <= 1'b1;
            running <= 1'b1;
            valid_sr <= {valid_sr[SR_LEN-2:0], ready};
//            $stop;
        end
    end
   
   
    always @(posedge clk) begin
        sys_ctr <= (rst) ? 0 
                    : (running) ? sys_ctr + 1 : sys_ctr;
        
        if (sys_ctr == 2305) begin
            sys_ctr <= 0;
        end
    end
    
                
endmodule
