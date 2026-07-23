`timescale 1ns / 1ps

`include "include.v"
`define MEM_SIZE 1024

module data_memory(
    input clk, reset,
    input [31:0] address,
    input [31:0] write_data,
    input mem_write, mem_read,
    output [31:0] read_data,
    output reg [3:0] led_result);
    
    integer i; 
    reg [31:0] mem [`MEM_SIZE-1:0]; // byte-addressable memory
    
    initial begin
        for(i=0;i<1024;i=i+1)
            mem[i]=0;
    end
    
    // distributed RAM: write = sync, read = async
    always @ (posedge clk) begin 
        if (~reset) begin 
            led_result <= 4'b0;
        end
        else if (mem_write) begin 
            mem[address[9:2]] <= write_data;
            if (address[31] == 1'b1) begin 
                led_result <= write_data[3-:4]; // just a fancy way to write [3:0]
            end
        end
    end
    
    assign read_data = (mem_read) ? mem[address[9:2]] : 32'b0;
    
endmodule
