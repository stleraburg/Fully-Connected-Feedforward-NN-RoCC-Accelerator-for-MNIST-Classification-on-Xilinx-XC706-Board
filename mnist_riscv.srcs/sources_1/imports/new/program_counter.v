`timescale 1ns / 1ps

module program_counter(
    input clk, reset, 
    input stall,
    input [31:0] pc_in, 
    output reg [31:0] pc_out);
    
    always @(posedge clk or negedge reset) begin 
        if (~reset)
            pc_out <= 32'b0;             
        else if (!stall)   
            pc_out <= pc_in; // if stall is high, pc_out just holds its current value implicitly
    end
endmodule
