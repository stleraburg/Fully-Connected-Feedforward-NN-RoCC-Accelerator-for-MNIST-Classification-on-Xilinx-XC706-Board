`timescale 1ns / 1ps

module mux5(
    input [31:0] A5, B5,
    input sel5, 
    output [31:0] mux5_out);
    
    assign mux5_out = (sel5 == 1'b0) ? A5 : B5;
    
endmodule
