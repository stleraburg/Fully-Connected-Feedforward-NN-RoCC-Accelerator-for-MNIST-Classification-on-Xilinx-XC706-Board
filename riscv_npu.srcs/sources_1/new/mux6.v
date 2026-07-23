`timescale 1ns / 1ps

module mux6(
    input [31:0] A6, B6,
    input sel6, 
    output [31:0] mux6_out);
    
    assign mux6_out = (sel6 == 1'b0) ? A6 : B6;
    
endmodule
