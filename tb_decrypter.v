`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Author: Luke Beckwith 
// Module Name: tb_decrypter
// Description: 
//////////////////////////////////////////////////////////////////////////////////


module tb_decrypter;
    reg clk, rst, start;
    wire done;

    // input signals
    reg [7:0] input_dia;
    reg input_wea;
    reg [10:0] input_addra;
    
    // output signals
    reg [2:0] output_addr;
    wire [31:0] output_do;

    decrypter uut(
        clk,
        rst,
        // control signals
        start,
        done,    
        // byte data input
        input_dia,
        input_wea,
        input_addra,
        // output (size mismatch with input should be fixed)
        output_addr, 
        output_do
        );

    // test vectors
    reg [0:16127] testvectors [99:0];
    reg [0:15871] input_vec;
    reg [0:255] output_vec;
    integer test_num, error_count, match_count, total_errors;
    reg [15:0] k;
    reg [31:0] out_check;
    
    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
    
        // initialize signals
        clk = 0;
        start = 0;
        
        input_dia = 0;
        input_wea = 0;
        input_addra = 0;
        output_addr = 0;
        
        rst = 1; #(`P); rst = 0; #(`P);
        
        test_num = 0;
        $readmemh("D:/programming/git_backups/NewHope_Decryption/decrypter.txt", testvectors);
        #(`P);
        for (test_num = 0; test_num < 100; test_num=test_num+1) begin
            input_vec = testvectors[test_num][0:15871];
            output_vec = testvectors[test_num][15872:16127];   
            @ (negedge clk);
        
            // 2) load input into poly ram            
            for (k = 0; k < 1984; k = k + 1) begin
                input_addra = k;
                input_dia = input_vec[k*8+:8];
                input_wea = 1'b1; #(`P); input_wea = 1'b0; #(`P);
            end
        
        
            // 3) run decrypter
            $display("Start Decryption"); 
            rst = 1'b1; #(`P); rst = 1'b0; #(`P); 
            start = 1'b1; #(`P);  start = 1'b0; #(`P); 
            while (done != 1) #(`P);
            $display("Decryption done"); 
        
        
            // 4) Check results
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 8; k=k+1) begin
                out_check = output_vec[k*32+:32];
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