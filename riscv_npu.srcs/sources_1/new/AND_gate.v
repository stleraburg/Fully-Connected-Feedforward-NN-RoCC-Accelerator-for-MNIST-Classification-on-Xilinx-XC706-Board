`timescale 1ns / 1ps

module AND_gate(
    input branch, zero,
    output and_out);
    
    assign and_out = branch & zero;
     
endmodule
