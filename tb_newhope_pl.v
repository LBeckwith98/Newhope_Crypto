`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2020 01:03:07 PM
// Design Name: 
// Module Name: tb_newhope_pl
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


module tb_newhope_pl;
    localparam NUM_TESTS = 5;

    reg clk, rst_enc, rst_key, en_key, start_key;
    wire done_key;
    
    
    // input signals
    reg [31:0] input_dia_key;
    reg input_wea_key;
    reg [3:0] input_addra_key;
    
    // output signals
    reg [10:0] output_addr_key;
    wire [7:0] output_do_key;
    
    keygen KEYGEN(
        clk,
        rst_key,
        en_key,
        // control signals
        start_key,
        done_key,    
        // byte data input
        input_dia_key,
        input_wea_key,
        input_addra_key,
        // output (size mismatch with input should be fixed)
        output_addr_key, 
        output_do_key
    );
    
    reg en_enc, ready_enc;
    wire valid_enc;

    // INPUT
    reg we_c, we_ps, we_pk;
    reg [3:0] addr_c;
    reg [2:0] addr_ps;
    reg [31:0] di_c, di_ps;
    reg [9:0] addr_pk;
    reg [7:0] di_pk;
    
    // OUTPUT
    reg [7:0] baddr_hout;
    reg [9:0] baddr_cout;
    wire [7:0] bdout_h, bdout_c;
    wire step_enc;
    encrypter_pl ENC (clk, rst_enc, en_enc, ready_enc, valid_enc, step_enc,
                        we_c, addr_c, di_c, // coin input
                        we_ps, addr_ps, di_ps, // pubseed input
                        we_pk, addr_pk, di_pk, // pk_poly input
                        baddr_hout, bdout_h, // Compress(V'') out (BYTES)
                        baddr_cout, bdout_c // EncodePoly(A) out (BYTES)c
                        );

    
    reg rst_dec, en_dec, ready_dec;
    wire valid_dec;

    // input signals
    reg bwe_sk, bwe_h, bwe_c;
    reg [9:0] baddr_sk, baddr_c;
    reg [7:0] bdi_sk, bdi_h, bdi_c, baddr_h;
    
    // output signals
    reg [2:0] addr_m;
    wire [31:0] do_m;
    wire step_dec;
    decrypter_pl DEC(clk, rst_dec, en_dec, ready_dec, valid_dec, step_dec,
                    bwe_sk, baddr_sk, bdi_sk, // SK in (BYTES)
                    bwe_h, baddr_h, bdi_h, // Compress(V'') in (BYTES)
                    bwe_c, baddr_c, bdi_c, // EncodePoly(U) in (BYTES)
                    addr_m, do_m // M output
                    );

    // test vectors
    reg [511:0] testvectors [9:0];
    reg [0:255] coin, m, seed;
    integer test_num, error_count, match_count, total_errors;
    integer k;
    reg [31:0] out_check, buffer32;    
    
    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
    
        // initialize signals to zero
        rst_enc   = 0;
        en_enc    = 0;
        ready_enc = 0;
        
        // INPUT ENC
        we_c    = 0; we_ps = 0; we_pk = 0;
        addr_c  = 0; addr_ps = 0;
        di_c    = 0; di_ps = 0;
        addr_pk = 0;
        di_pk   = 0;
        
        // OUTPUT ENC
        baddr_h = 0;
        baddr_c = 0;
        
        // DEC
        en_dec = 0;
        bwe_sk = 0; bwe_h = 0; bwe_c = 0;
        baddr_sk = 0; baddr_c = 0;
        bdi_sk = 0; bdi_h = 0; bdi_c = 0; baddr_h = 0;
        addr_m = 0;
        
        clk = 0;
        ready_dec = 0;
        buffer32 = 0;
        
        // keygen signals
        en_key = 0; 
        start_key = 0;    
    
        input_dia_key = 32'd0;
        input_wea_key = 0;
        input_addra_key = 4'd0;
    
        // output signals
        output_addr_key = 10'd0;
        
        test_num = 0;
        error_count = 0;
        match_count = 0;
        total_errors = 0;
        @ (posedge clk);
        rst_enc = 1'b1; rst_dec = 1'b1; rst_key = 1'b1; #(`P); 
        rst_enc = 1'b0; rst_dec = 1'b0; rst_key = 1'b0; #(`P); 
        
        
        
        // Hardcoded test values:
        seed = 256'h7C9935A0B0769FAA0C6D10E4DB6B1ADD2FD81A25CCB148032DCD739936737F2D;
        coin = 256'hA056B4E015FD9EB0237338FB0EFCC59556D9656EDA3A4AEC68F1F2E7B083DF78;
        m    = 256'h000102030405060708090a0b0c0d0E0f101112131415161718191a1b1c1d1e1f;
        
        
            @ (posedge clk);
         
        // 1) KEY GENERATION
        en_key = 1'b1; #(`P);
        for (k = 0; k < 8; k = k + 1) begin
            input_addra_key = k;
            input_dia_key = seed[k*32+:32];
            #(`P); input_wea_key = 1'b1; #(`P); input_wea_key = 1'b0; #(`P);
        end
    
        $display("Start KeyGen"); 
        start_key = 1'b1; #(`P);  start_key = 1'b0; #(`P); 
        while (done_key != 1) #(`P);
        rst_key = 1'b1; #(`P); rst_key = 1'b0; #(`P); 
        $display("KeyGen done"); 

        
        // read in test data
        $readmemh("D:/programming/NewHopeTrivium/NewHopeCrypto/newhope_tv.txt", testvectors);
        #(`P);
         
        // 2) ENCRYPTION
        en_enc = 1;
        // load message           
        for (k = 0; k < 8; k = k + 1) begin
            addr_c = k+8;
            di_c = m[k*32+:32];
            we_c = 1'b1; #(`P); we_c = 1'b0; #(`P);
        end
        // load pubseed           
        for (k = 0; k < 32; k = k + 4) begin
            output_addr_key = k + 11'd1792; #(`P);
            buffer32[7:0] = output_do_key; #(`P);
            
            output_addr_key = k + 11'd1793; #(`P);
            buffer32[15:8] = output_do_key; #(`P);
            
            output_addr_key = k + 11'd1794; #(`P);
            buffer32[23:16] = output_do_key; #(`P);
            
            output_addr_key = k + 11'd1795; #(`P);
            buffer32[31:24] = output_do_key; #(`P);
            
            addr_ps = (k>>2)+8;
            di_ps = buffer32;
            we_ps = 1'b1; #(`P); we_ps = 1'b0; #(`P);
            
        end
        // load pk
        for (k = 0; k < 896; k = k + 1) begin
            output_addr_key = k + 11'd896; #(`P);
    
            addr_pk = k;
            di_pk = output_do_key;
            we_pk = 1'b1; #(`P); we_pk = 1'b0; #(`P);

        end

        // load sk into decrypter
        for (k = 0; k < 896; k = k + 1) begin
            output_addr_key = k; #(`P);
        
            baddr_sk = k;
            bdi_sk = output_do_key;
            bwe_sk = 1'b1; #(`P); bwe_sk = 1'b0; #(`P);
        end
        
        //$stop;
        
        rst_enc = 1'b1; #(`P); rst_enc = 1'b0; #(`P); 
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin
            coin = testvectors[test_num][255:0];

            // load coin           
            for (k = 0; k < 8; k = k + 1) begin
                addr_c = k;
                di_c = coin[k*32+:32];
                we_c = 1'b1; #(`P); we_c = 1'b0; #(`P);
            end
//            $stop;
            $display("Start Encryption"); 
            ready_enc = 1'b1; #(`P);  ready_enc = 1'b0; #(`P);    
            while (step_enc == 1'b1) #(`P);
            
               
        end
        
        while (valid_enc != 1) #(`P);
        $display("Encryption valid"); #50;
        en_enc = 0; 
//        $stop;
        
        en_dec = 1; #(`P);
        rst_dec = 1'b1; #(`P); rst_dec = 1'b0; #(`P);
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin    
            // 3) DECRYPTION
            // load ct poly into decrypter
            
            for (k = 0; k < 896; k = k + 1) begin                
                if (k < 192) begin
                    baddr_hout = k; baddr_cout = k; #(`P);
                    bdi_c = bdout_c;
                    baddr_c = k;
                    
                    bdi_h = bdout_h;
                    baddr_h = k;
                    bwe_c = 1'b1; bwe_h = 1'b1; #(`P); bwe_c = 1'b0;  bwe_h = 1'b0;#(`P);
                end else begin
                    baddr_cout = k; #(`P);
                    bdi_c = bdout_c;
                    baddr_c = k;
                
                    bwe_h = 0;
                    bwe_c = 1'b1; #(`P); bwe_c = 1'b0; #(`P);
                end
            end
            
//            $stop;
            $display("Start Decryption"); 
            
            ready_dec = 1'b1; #(`P);  ready_dec = 1'b0; #(`P); 
            while (step_dec == 1'b1) #(`P);
            
            en_enc = 1;
            while (step_enc == 1'b1) #(`P);
            #50;
            en_enc = 0;
        end
        
        while (valid_dec != 1) #(`P);
        $display("Decryption valid"); 
        en_dec = 0; #(`P);
        
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin               
            // 4) CHECK RESULTS ** WILL NOT MATCH UNTIL DECAPS IS ADDED)
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 8; k=k+1) begin
                out_check = m[k*32+:32];
                addr_m = k; #(`P);
                if (out_check !== do_m) begin
                    error_count = error_count  + 1;
                    $display("Error at entry %d: %h %h", k, out_check, do_m); 
                    total_errors = total_errors + 1;
                end
                else begin
                    match_count = match_count  + 1;
                    $display("Match at entry %d: %h %h", k, out_check, do_m);
                end
                
                #(`P);
            end
            $display("Done checking test %d. Correct: %d, Errors: %d", test_num, match_count, error_count);
            
            en_dec = 1;
//            $stop;
            while (step_dec == 1'b1) #(`P);
            en_dec = 0;
        end
            


        $display("Total errors: %d", total_errors);
        
        $finish;
    end
    
    always #(`P/2) clk = ~ clk;

endmodule
`undef P
