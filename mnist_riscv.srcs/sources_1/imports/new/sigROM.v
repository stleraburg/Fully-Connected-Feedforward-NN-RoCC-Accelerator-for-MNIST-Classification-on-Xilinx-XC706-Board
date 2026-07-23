`timescale 1ns / 1ps

module sigROM #(parameter inWidth=10, dataWidth=16) (
    input clk, 
    input [inWidth-1:0] x,
    output [dataWidth-1:0] out
    ); 
    
    reg [dataWidth-1:0] mem [2**inWidth-1:0];
    reg [inWidth-1:0] y; // address
    
    initial $readmemb("sigContent.mif", mem);
    
    always @ (posedge clk) begin
        if ($signed(x) >= 0) 
            y <= x+(2**(inWidth-1));
        else 
            y <= x-(2**(inWidth-1));
    end
    assign out = mem[y];    
endmodule