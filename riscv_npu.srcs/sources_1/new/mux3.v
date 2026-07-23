`timescale 1ns / 1ps

module mux3(
    input [31:0] A3, B3,
    input sel3, 
    output [31:0] mux3_out);
    
    assign mux3_out = (sel3 == 1'b0) ? A3 : B3;
    
endmodule
