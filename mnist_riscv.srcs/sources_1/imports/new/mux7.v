`timescale 1ns / 1ps

module mux7(
    input [31:0] A7, B7,
    input sel7, 
    output [31:0] mux7_out);
    
    assign mux7_out = (sel7 == 1'b0) ? A7 : B7;
    
endmodule
