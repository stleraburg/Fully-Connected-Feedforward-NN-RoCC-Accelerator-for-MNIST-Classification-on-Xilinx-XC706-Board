`timescale 1ns / 1ps

module OR_gate(
    input jump, and_out,
    output or_out);
    
    assign or_out = jump | and_out;
    
endmodule