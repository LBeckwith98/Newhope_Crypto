`timescale 1ns / 1ps
`define P 10

//////////////////////////////////////////////////////////////////////////////////
// Author: Luke Beckwith 
// Module Name: tb_newhope
// Description: Test bench that encrypts and decrypts a 32-byte message using
//      the Newhope algorithm
//////////////////////////////////////////////////////////////////////////////////


module tb_newhope;
    reg clk, rst_enc, start_enc;
    wire done_enc;
    
    reg [31:0] input1_dia_enc;
    reg input1_wea_enc, input2_wea_enc;
    reg [4:0] input1_addra_enc;
    reg [7:0] input2_dia_enc;
    reg [9:0] input2_addra_enc;
    reg [10:0] output_addr_enc;
    wire [7:0] output_do_enc;
    
    encrypter ENC(
        clk,
        rst_enc,
        // control signals
        start_enc,
        done_enc,    
        // byte data input
        input1_dia_enc,
        input1_wea_enc,
        input1_addra_enc,
        input2_dia_enc,
        input2_wea_enc,
        input2_addra_enc,
        // output byte data
        output_addr_enc, 
        output_do_enc
        );

    reg rst_dec, start_dec;
    wire done_dec;

    // input signals
    reg [7:0] input_dia_dec;
    reg input_wea_dec;
    reg [10:0] input_addra_dec;
    
    // output signals
    reg [2:0] output_addr_dec;
    wire [31:0] output_do_dec;

    decrypter DEC(
        clk,
        rst_dec,
        // control signals
        start_dec,
        done_dec,    
        // byte data input
        input_dia_dec,
        input_wea_dec,
        input_addra_dec,
        // output (size mismatch with input should be fixed)
        output_addr_dec, 
        output_do_dec
        );

    // test vectors
    reg [0:16639] testvectors_enc [99:0];
    reg [0:255] coin, m, pubseed;
    reg [0:7167] pk_poly;
    reg [0:16127] testvectors_dec [99:0];
    reg [0:7167] sk;
    integer test_num, error_count, match_count, total_errors;
    reg [15:0] k;
    reg [31:0] out_check;

    
    
    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
    
        // initialize signals to zero
        clk = 0;
        rst_enc = 0;
        rst_dec = 0;
        input1_dia_enc = 0;
        input1_wea_enc = 0;
        input2_wea_enc = 0;
        input1_addra_enc = 0;
        input2_dia_enc = 0;
        input2_addra_enc = 0;
        output_addr_enc = 0;
        start_dec = 0;
        start_enc = 0;
        input_dia_dec = 0;
        input_wea_dec = 0;
        input_addra_dec = 0;
        output_addr_dec = 0;
        
        test_num = 0;
        error_count = 0;
        match_count = 0;
        total_errors = 0;
        // read in test data
        $readmemh("D:/programming/git_backups/TMP_NewHope/encrypter.txt", testvectors_enc);
        $readmemh("D:/programming/git_backups/TMP_NewHope/decrypter.txt", testvectors_dec);
         for (test_num = 0; test_num < 100; test_num=test_num+1) begin
            rst_enc = 1'b1; #(`P); rst_enc = 1'b0; #(`P); 
            rst_dec = 1'b1; #(`P); rst_dec = 1'b0; #(`P); 
         
            // 1) initialize test inputs
            // enc inputs
            m = testvectors_enc[test_num][7936-256:7935];
            coin = testvectors_enc[test_num][7936-512:7935-256];  
            pubseed = testvectors_enc[test_num][7935-512-256:7935-512];
            pk_poly = testvectors_enc[test_num][0:7935-512-256];    
            
            // dec inputs
            sk = testvectors_dec[test_num][8704:8704+7167];
            @ (negedge clk);
            
            // 2) load input into encrypter 
            // load coin           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra_enc = k;
                input1_dia_enc = coin[k*32+:32];
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
            end
            // load pubseed           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra_enc = k+8;
                input1_dia_enc = pubseed[k*32+:32];
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
            end
            // load m           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra_enc = k+16;
                input1_dia_enc = m[k*32+:32];
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
            end
            // load pk
            for (k = 0; k < 896; k = k + 1) begin
                input2_addra_enc = k;
                input2_dia_enc = pk_poly[k*8+:8];
                input2_wea_enc = 1'b1; #(`P); input2_wea_enc = 1'b0; #(`P);
            end
            
            // 3) run encrypter
            $display("Start Encryption"); 
            start_enc = 1'b1; #(`P);  start_enc = 1'b0; #(`P); 
            while (done_enc != 1) #(`P);
            $display("Encryption done"); 
            
            // 4) load cipher text from encrypter into decrypter
            for (k = 0; k < 1088; k = k + 1) begin
                output_addr_enc = k; #(`P);
                input_addra_dec = k;
                input_dia_dec = output_do_enc;
                input_wea_dec = 1'b1; #(`P); input_wea_dec = 1'b0; #(`P);
            end
            
            // 5) load sk into decrypter
            for (k = 0; k < 896; k = k + 1) begin
                input_addra_dec = k + 1088;
                input_dia_dec = sk[k*8+:8];
                input_wea_dec = 1'b1; #(`P); input_wea_dec = 1'b0; #(`P);
            end
            
            // 6) run decrypter
            $display("Start Decryption"); 
            start_dec = 1'b1; #(`P);  start_dec = 1'b0; #(`P); 
            while (done_dec != 1) #(`P);
            $display("Decryption done"); 
            
            // 7) Compare plaintext and input
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 8; k=k+1) begin
                out_check = m[k*32+:32];
                output_addr_dec = k; #(`P);
                if (out_check !== output_do_dec) begin
                    error_count = error_count  + 1;
                    $display("Error at entry %d: %h %h", k, out_check, output_do_dec); 
                    total_errors = total_errors + 1;
                end
                else begin
                    match_count = match_count  + 1;
                    $display("Match at entry %d: %h %h", k, out_check, output_do_dec);
                end
                
                #(`P);
            end
            $display("Done checking test %d. Correct: %d, Errors: %d", test_num, match_count, error_count);
        end
            


        $display("Total errors: %d", total_errors);
        
        $finish;
    end
    
    always #(`P/2) clk = ~ clk;

endmodule
`undef P