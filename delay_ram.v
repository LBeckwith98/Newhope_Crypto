`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module that holds mutliple NewHope polynomials in BRAM. Allows values 
// to be delayed to later stages of the pipeline
//////////////////////////////////////////////////////////////////////////////////


module delay_ram(
    input clk,
    input rst,
    input shift,
    // write in
    input we_in,
    input [8:0] addr_in,
    input [15:0] di_in,
    // read out
    input [8:0] addr_out,
    output reg [15:0] do_out
    );
    
    parameter LENGTH = 6;
    genvar i;
    
    // CTRL logic signals
    reg [$clog2(LENGTH+2)-1:0] state_num;
    integer j;
    
    // BRAM port connections
    reg [LENGTH+1:0] en, wea, web;
    reg [8:0] addra [LENGTH+1:0], addrb [LENGTH+1:0];
    reg [15:0] dia [LENGTH+1:0], dib [LENGTH+1:0];
    wire [15:0] doa [LENGTH+1:0], dob [LENGTH+1:0];
    
    
    // generate BRAM units
    generate
        for (i = 0; i < LENGTH + 2; i = i + 1) begin
            dual_port_ram BRAM (clk,clk,en[i],en[i],wea[i],web[i],
                                addra[i],addrb[i],dia[i],dib[i],doa[i],dob[i]);
        end
    endgenerate
    
    // generate control logic  
    always @(*) begin
        // output ram is state_num - 1
        do_out = (state_num == LENGTH+1) ? doa[0] : doa[state_num+1];

    
        for (j = 0; j < LENGTH + 2; j = j + 1) begin
            addrb[j] = 0;
            web[j]   = 0;
            dib[j]   = 0;
        
            if (state_num == j) begin
                // input
                addra[j] = addr_in;
                wea[j] = we_in;
                dia[j] = di_in;
                en[j] = 1'b1;
            end else if (state_num == j - 1 || ((state_num == LENGTH+1) && j==0)) begin
                // output (j-1) mod LENGTH
                wea[j]   = 0;
                dia[j]   = 0;
                addra[j] = addr_out;
                en[j] = 1'b1;
            end else begin
                addra[j] = 0;
                wea[j]   = 0;
                dia[j]   = 0;
                en[j]    = 0;
            end
        end
     end
      
    // state logic
    always @(posedge clk) begin
        if (rst) begin
            state_num <= 0;
        end else if (shift) begin
            state_num <= (state_num < LENGTH + 1) ? state_num + 1 : 0;
        end else begin
            state_num <= state_num;
        end
    end
         
endmodule
