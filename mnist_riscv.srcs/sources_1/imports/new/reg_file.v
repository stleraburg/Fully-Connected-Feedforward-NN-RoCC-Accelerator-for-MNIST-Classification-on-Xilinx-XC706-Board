`timescale 1ns / 1ps

module reg_file(
    input clk, reset, RegWrite, 
    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,
    output [31:0] read_data1, read_data2);
    
    reg [31:0] registers [31:0];
    
    // asynchronous read, x0 is hardwired to 0
    assign read_data1 = (rs1 != 5'b00000) ? registers[rs1] : 32'b0;
    assign read_data2 = (rs2 != 5'b00000) ? registers[rs2] : 32'b0;
    
    // synchronous write, x0 is write-protected
    always @ (posedge clk) begin 
        if (RegWrite && rd != 5'd0)
            registers[rd] <= write_data;
    end    

endmodule
