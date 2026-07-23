`timescale 1ns / 1ps

module mux4(
    input [31:0] A4, B4,
    input sel4, 
    output [31:0] mux4_out);
    
    assign mux4_out = (sel4 == 1'b0) ? A4 : B4;
    
endmodule
