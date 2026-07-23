`timescale 1ns / 1ps
`define MEM_DEPTH 64

module instruction_memory(
    input clk, 
    input [31:0] read_addr, 
    output [31:0] instruction);
    
    reg [31:0] mem [0:`MEM_DEPTH-1];
    
    initial begin 
        $readmemh("data_sum.mem", mem);
    end
    
    // saved as ROM in BRAM (synchronous)
    // always @ (posedge clk) begin 
    assign instruction = mem[read_addr[31:2]];
    // end
endmodule
