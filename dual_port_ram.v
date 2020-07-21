`timescale 1ns / 1ps
// Dual-Port Block RAM with Two Write Ports
// File: HDL_Coding_Techniques/rams/rams_16.v
module dual_port_ram (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
    parameter WIDTH = 16, LENGTH = 512;

    input clka, clkb, ena, enb, wea, web;
    input [$clog2(LENGTH)-1:0] addra, addrb;
    input [WIDTH-1:0] dia, dib;
    output reg [WIDTH-1:0] doa, dob;
    reg [WIDTH-1:0] ram [LENGTH-1:0];

    integer i;
    initial begin
        for (i = 0; i < LENGTH; i = i + 1)
            ram[i] = 0;
    end

    always @(posedge clka) begin 
        if (ena) begin
            if (wea)
                ram[addra] <= dia;
            doa <= ram[addra];
        end
    end
        
    always @(posedge clkb) begin 
        if (enb) begin
            if (web)
               ram[addrb] <= dib; 
            dob <= ram[addrb];
        end
    end
    
    endmodule
