`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2020 11:25:16 AM
// Design Name: 
// Module Name: decrypter_pl
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

// No layer submodules because of their relative simplicity

module decrypter_pl(
    input clk,
    input rst,
    input en,
    input ready,
    output valid,
    output reg start_stage,
    // SK in (BYTES)
    input bwe_sk,
    input [9:0] baddr_sk,
    input [7:0] bdi_sk,
    // Compress(V'') in (BYTES)
    input bwe_h,
    input [7:0] baddr_h,
    input [7:0] bdi_h,
    // EncodePoly(A) in (BYTES)
    input bwe_c,
    input [9:0] baddr_c,
    input [7:0] bi_c,
    // M output
    input [2:0] addr_m,
    output [31:0] do_m
    );
    
    reg start_components;
    
    
    // INPUT RAMS
    wire [9:0] baddr_c_s0, baddr_sk_s0;
    wire [7:0] bdout_c_s0, baddr_h_s0, bdout_h_s0, bdout_sk_s0;
    
    // CT encoded polynomial
    delay_block_ram #(.LENGTH(0), .WIDTH(8), .BLOCK_SIZE(1024)) 
        R0_0_C (clk, rst, start_stage,
                bwe_c, baddr_c, bi_c, // write in
                baddr_c_s0, bdout_c_s0 // read out
                );
    // CT compressed value
    delay_block_ram #(.LENGTH(0), .WIDTH(8), .BLOCK_SIZE(256)) 
        R0_1_H (clk, rst, start_stage,
                bwe_h, baddr_h, bdi_h, // write in
                baddr_h_s0, bdout_h_s0 // read out
                );
    
    // SK encoded value
//    delay_block_ram #(.LENGTH(0), .WIDTH(8), .BLOCK_SIZE(1024)) 
//        R0_2_SK (clk, rst, start_stage,
//                bwe_sk, baddr_sk, bdi_sk, // write in
//                baddr_sk_s0, bdout_sk_s0 // read out
//                );
    wire [7:0] SK_doa;
    dual_port_ram #(.WIDTH(8), .LENGTH(896)) R0_2_SK (clk,clk,1'b1,1'b1,bwe_sk,1'b0,baddr_sk,baddr_sk_s0,bdi_sk,8'd0,SK_doa,bdout_sk_s0);
    
    /* LAYER 0 */
    // In wires
    wire done_pd0, done_pd1, done_decomp, we_s_s0, we_u_s0, we_vp_s0;
    wire [8:0] addr_s_s0, addr_u_s0, addr_vp_s0;
    wire [15:0] di_s_s0, di_u_s0, di_vp_s0;
    
    // Out wires
    wire [8:0] addr_s_s1, addr_u_s1, addr_vp_s1;
    wire [15:0] do_s_s1, do_u_s1, do_vp_s1;
    
    // Modules
    polynomial_decoder PD0_C (clk, rst, start_components, done_pd0,
                                baddr_c_s0, bdout_c_s0, // Input RAM signals (CT poly)
                                we_u_s0, addr_u_s0, di_u_s0 // output RAM signals
                                ); 
    
    polynomial_decoder PD1_SK (clk, rst, start_components, done_pd1,
                                baddr_sk_s0, bdout_sk_s0, // Input RAM signals (CT poly)
                                we_s_s0, addr_s_s0, di_s_s0 // output RAM signals
                                ); 
    
    decompressor DECOMP (clk, rst, start_components, done_decomp,
                            baddr_h_s0, bdout_h_s0, // Input RAM signals (H compressed)
                            we_vp_s0, addr_vp_s0, di_vp_s0 // output RAM signals
                            );
    
    // Output BRAM
    delay_block_ram #(.LENGTH(0), .WIDTH(16), .BLOCK_SIZE(512)) 
        R1_0_U (clk, rst, start_stage,
                we_u_s0, addr_u_s0, di_u_s0, // write in
                addr_u_s1, do_u_s1 // read out
                );
    
    delay_block_ram #(.LENGTH(0), .WIDTH(16), .BLOCK_SIZE(512)) 
        R1_1_S (clk, rst, start_stage,
                we_s_s0, addr_s_s0, di_s_s0, // write in
                addr_s_s1, do_s_s1 // read out
                );
    
    delay_block_ram #(.LENGTH(4), .WIDTH(16), .BLOCK_SIZE(512)) 
        R1_2_VP (clk, rst, start_stage,
                we_vp_s0, addr_vp_s0, di_vp_s0, // write in
                addr_vp_s1, do_vp_s1 // read out
                );
    
    /* LAYER 1 */
    wire done_mult0, we_mult0;
    wire [8:0] addri_mult0, addro_mult0;
    wire [15:0] do_mult0;
    
    assign addr_u_s1 = addri_mult0;
    assign addr_s_s1 = addri_mult0;
    // Modules
    poly_mult #(.BITREV(1)) MULT1_B_SP(clk, rst, en, start_components, done_mult0,
                             we_mult0, addri_mult0, addro_mult0, do_u_s1, do_s_s1, do_mult0);

    /* LAYER 2 (2 stage) */ 
    wire done_ntt;
    wire [8:0] addr_ntt;
    wire [15:0] do_ntt;
    
    // Modules
    stacked_ntt #(.MODE(1)) NTT0(clk, rst, start_components, en, done_ntt,
                    we_mult0, addro_mult0, do_mult0, addr_ntt, do_ntt);
    
    /* LAYER 3 */
    wire done_multg;
    wire we_multg;
    wire [8:0] addr_multg, PR0_addra, addr_upp_s3;
    wire [15:0] do_multg, PR0_doa, do_upp_s3;
    
    assign addr_ntt = addr_multg;
    assign PR0_addra = addr_multg;
    // Modules
    single_port_ram #(.MEM_WIDTH(16), .MEM_SIZE(512), .FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas_inv.txt")) RAM0_GINV
            (clk,1'b0,en,PR0_addra,16'd0,PR0_doa); 
        
    poly_multg MULT0_GINV_B(clk, rst, en, start_components, done_multg,
                                we_multg, addr_multg, do_ntt, PR0_doa, do_multg);
    
    
    // Output BRAM
    delay_block_ram #(.LENGTH(0), .WIDTH(16), .BLOCK_SIZE(512)) 
        R3_0_UPP (clk, rst, start_stage,
                we_multg, addr_multg, do_multg, // write in
                addr_upp_s3, do_upp_s3 // read out
                );

    /* LAYER 4 */
    wire done_sub, we_sub;
    wire [8:0] addr_sub, addr_vpp_s4;
    wire [15:0] do_sub, do_vpp_s4;
    
    assign addr_upp_s3 = addr_sub;
    assign addr_vp_s1 = addr_sub;
    // Modules
    poly_sub SUB0_UPP_VP (clk, rst, en, start_components, done_sub,
                        we_sub, addr_sub, do_vp_s1, do_upp_s3, do_sub
                        );
    
    // Output BRAM
    delay_block_ram #(.LENGTH(0), .WIDTH(16), .BLOCK_SIZE(512)) 
        R4_0_VPP (clk, rst, start_stage,
                we_sub, addr_sub, do_sub, // write in
                addr_vpp_s4, do_vpp_s4 // read out
                );
    
    /* LAYER 5 */
    wire done_dec, bwe_dec;
    wire [2:0] baddr_dec;
    wire [31:0] bdi_dec;
    
    // Modules
    decoder DECODER(clk, rst, start_components, done_dec,
                    bwe_dec, baddr_dec, bdi_dec, // output RAM signals
                    addr_vpp_s4, do_vpp_s4 // input RAM signals
                    );
    
    // Output BRAM
    delay_block_ram #(.LENGTH(0), .WIDTH(32), .BLOCK_SIZE(8)) 
        R5_0_M (clk, rst, start_stage,
                bwe_dec, baddr_dec, bdi_dec, // write in
                addr_m, do_m // read out
                );
    
    
    /* Control logic */
    localparam SR_LEN = 8;
    reg running = 0;
    reg [SR_LEN-1:0] valid_sr = 0;
    assign valid = valid_sr[SR_LEN-1];
    
    reg [11:0] sys_ctr = 0;
    always @(posedge clk) begin
        start_stage <= 1'b0;
        start_components <= (start_stage) ? 1'b1 : 1'b0;
        valid_sr <= valid_sr;
        running <= (en) ? running : 1'b0;
        
        // start if round has finished
        if (en && (sys_ctr == 2305)) begin
            start_stage <= 1'b1;
            valid_sr <= {valid_sr[SR_LEN-2:0], ready};
            //$stop;
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
