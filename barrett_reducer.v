`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2020 04:33:24 PM
// Design Name: 
// Module Name: barrett_reducer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: pipelined barrett reducer for NEWHOPE_Q == 12289
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module barrett_reducer(
    input clk,
    input rst,
    input en,
    input [15:0] a,
    input valid,
    output reg out_valid,
    output reg [13:0] result
    );
    
    wire [15:0] NEWHOPE_Q_MULTIPLE;
    
    assign NEWHOPE_Q_MULTIPLE = (a[15:14] == 0) ? 16'd0 :
                                (a[15:14] == 1) ? 16'd12289 :
                                (a[15:14] == 2) ? 16'd24578 :
                                (a[15:14] == 3) ? 16'd36867 : 0;
    
    reg [15:0] a_1;
    reg valid_1;
    
    always @(posedge clk) begin
        if (rst) begin
            valid_1 <= 0;
            out_valid <= 0;
        end else if (en) begin
            a_1 <= a - NEWHOPE_Q_MULTIPLE;
            valid_1 <= valid;
            
            result <= (16'd24578 <= a_1) ? a_1 - 16'd24578 :
                        (16'd12289 <= a_1) ?  a_1 - 16'd12289 : a_1;
            out_valid <= valid_1;
        end
    end
    
endmodule
