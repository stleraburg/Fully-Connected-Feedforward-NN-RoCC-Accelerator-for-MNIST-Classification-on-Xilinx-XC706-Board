`timescale 1ns / 1ps

module mux1(
    input [31:0] A1, B1,
    input sel1, 
    output [31:0] mux1_out);
    
    assign mux1_out = (sel1 == 1'b0) ? A1 : B1;
    
endmodule
