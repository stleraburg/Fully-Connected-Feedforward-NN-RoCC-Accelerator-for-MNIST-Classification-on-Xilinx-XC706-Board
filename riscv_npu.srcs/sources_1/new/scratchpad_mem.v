`timescale 1ns / 1ps

`include "include.v"
module scratchpad_mem #(parameter inSize=784, addrWidth=10, dataWidth=16, testFile="test_data_5.txt") (
    input clk, 
    input wen, 
    input ren, 
    input [addrWidth-1:0] wadd, 
    input [addrWidth:0] radd, 
    input [dataWidth-1:0] pin, 
    output reg [dataWidth-1:0] pout
    );
    
    // reg [dataWidth-1:0] mem [(numImages*inSize):0];
    reg [dataWidth-1:0] mem [inSize:0];
    
    `ifdef preloaded
        initial begin 
            $readmemb(testFile, mem);
        end
     `else 
        integer i;
        initial begin
            for (i=0; i<=inSize; i=i+1) mem[i] = 0; 
        end
        always @(posedge clk) begin 
            if (wen) mem[wadd] <= pin;
        end
    `endif  
     
     always @ (posedge clk) begin 
        if (ren) pout <= mem[radd];
     end
     
endmodule
