`timescale 1ns / 1ps
// 16-bit, 5 length Shift Register
// Rising edge clock
// Active high clock enable
// Concatenation-based template
// File: shift_registers_bf.v

module shift_registers_addr (
input clk, 
input clken, 
input [17:0] SI, 
output [17:0] SO
);
    parameter LENGTH = 11;

    reg [17:0] shreg[LENGTH-1:0];
    integer i;
    
    assign SO = shreg[LENGTH-1];
        
    initial begin
       for (i = 0; i < LENGTH; i = i+1)
          shreg[i] <= 0;
//        shreg[0] = 0;
//        shreg[1] = 0;
//        shreg[2] = 0;
//        shreg[3] = 0;
//        shreg[4] = 0;
//        shreg[5] = 0;
//        shreg[6] = 0;
//        shreg[7] = 0;
//        shreg[8] = 0;
//        shreg[9] = 0;
//        shreg[10] = 0;
    end
    
    always @(posedge clk) begin
     if (clken) begin
         for (i = 0; i < LENGTH-1; i = i+1)
            shreg[i+1] <= shreg[i];
         shreg[0] <= SI; 
        end
     end
      
endmodule