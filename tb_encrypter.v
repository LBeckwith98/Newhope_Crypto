`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Author: Luke Beckwith 
// Module Name: tb_encrypter
// Description: 
//////////////////////////////////////////////////////////////////////////////////

module tb_encrypter;
    reg clk, rst, start;
    wire done;
    
    reg [31:0] input1_dia;
    reg input1_wea, input2_wea;
    reg [4:0] input1_addra;
    reg [7:0] input2_dia;
    reg [9:0] input2_addra;
    reg [10:0] output_addr;
    wire [7:0] output_do;
    
    encrypter uut(
        clk,
        rst,
        // control signals
        start,
        done,    
        // byte data input
        input1_dia,
        input1_wea,
        input1_addra,
        input2_dia,
        input2_wea,
        input2_addra,
        // output byte data
        output_addr, 
        output_do
        );

    // test vectors
    reg [0:16639] testvectors [99:0];
    reg [0:7935] input_vec;
    reg [0:255] coin, m;
    reg [0:7423] pk;
    reg [0:8703] output_vec;
    integer test_num, error_count, match_count, total_errors;
    reg [15:0] k;
    reg [7:0] out_check;

    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
        test_num = 0;
        out_check = 0;
    
        // initialize signals
        clk = 0;
        start = 0;
        
        input1_dia = 0;
        input1_wea = 0;
        input1_addra = 0;
        input2_dia = 0;
        input2_wea = 0;
        input2_addra = 0;
        output_addr = 0;
        
        rst = 1; #(`P); rst = 0; #(`P);

        $readmemh("D:/programming/git_backups/TMP_NewHope/encrypter.txt", testvectors);
        #(`P);
        for (test_num = 0; test_num < 100; test_num=test_num+1) begin
            input_vec = testvectors[test_num][0:7935];
            m = input_vec[7936-256:7935];
            coin = input_vec[7936-512:7935-256];
            pk = input_vec[0:7935-512];
            output_vec = testvectors[test_num][7936:16639];   
            @ (negedge clk);
            
            // 2) load input into poly ram 
            // load coin           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra = k;
                input1_dia = coin[k*32+:32];
                input1_wea = 1'b1; #(`P); input1_wea = 1'b0; #(`P);
            end
            // load h           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra = k+8;
                input1_dia = pk[7936-512-256+k*32+:32];
                input1_wea = 1'b1; #(`P); input1_wea = 1'b0; #(`P);
            end
            // load m           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra = k+16;
                input1_dia = m[k*32+:32];
                input1_wea = 1'b1; #(`P); input1_wea = 1'b0; #(`P);
            end
            // load pk
            for (k = 0; k < 896; k = k + 1) begin
                input2_addra = k;
                input2_dia = pk[k*8+:8];
                input2_wea = 1'b1; #(`P); input2_wea = 1'b0; #(`P);
            end
            
            // 3) run encrypter
            $display("Start Encryption"); 
            rst = 1'b1; #(`P); rst = 1'b0; #(`P); 
            start = 1'b1; #(`P);  start = 1'b0; #(`P); 
            while (done != 1) #(`P);
            $display("Encryption done"); 
            
            // 4) Check results
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 1088; k=k+1) begin
                out_check = output_vec[k*8+:8];
                output_addr = k; #(`P);
                if (out_check !== output_do) begin
                    error_count = error_count  + 1;
                    $display("Error at entry %d: %h %h", k, out_check, output_do); 
                    total_errors = total_errors + 1;
                end
                else begin
                    match_count = match_count  + 1;
                    $display("Match at entry %d: %h %h", k, out_check, output_do);
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
