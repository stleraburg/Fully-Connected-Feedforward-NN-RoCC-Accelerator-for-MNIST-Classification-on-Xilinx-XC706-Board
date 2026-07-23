`timescale 1ns / 1ps

module mux2(
    input [31:0] A2, B2,
    input sel2, 
    output [31:0] mux2_out);
    
    assign mux2_out = (sel2 == 1'b1) ? A2 : B2;
    
endmodule
