`timescale 1ns / 1ps

`define ADD                     4'b0000
`define SUB                     4'b0001 
`define less_than               4'b0010
`define less_than_unsigned      4'b0011
`define greater_than            4'b0100
`define greater_than_unsigned   4'b0101
`define XOR                     4'b0110
`define OR                      4'b0111
`define AND                     4'b1000
`define SLL                     4'b1001
`define SRL                     4'b1010
`define SRA                     4'b1011
`define equal                   4'b1100
`define not_equal               4'b1101
`define pc_plus_4               4'b1110
// `define MOD                     4'b1111

module ALU(
    input [31:0] A, B,
    input [3:0] control_in,
    output zero,
    output reg [31:0] C);
    
    always @ (control_in or A or B) begin 
        case (control_in) 
            `ADD, `pc_plus_4 : C = A + B;
            `SUB : C = A - B;
            `less_than : C = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            `less_than_unsigned : C = ($unsigned(A) < $unsigned(B)) ? 32'd1 : 32'd0;
            `greater_than : C = ($signed(A) >= $signed(B)) ? 32'd1 : 32'd0;
            `greater_than_unsigned : C = ($unsigned(A) >= $unsigned(B)) ? 32'd1 : 32'd0;
            `XOR : C = A ^ B;
            `OR : C = A | B;
            `AND : C = A & B; 
            `SLL : C = A << B; 
            `SRL : C = A >> B;
            `SRA : C = $signed(A) >>> B;
            `equal : C = (A == B) ? 32'd1 : 32'd0;
            `not_equal : C = (A != B) ? 32'd1 : 32'd0;
            //`MOD : C = A % B;
            default : C = 32'b0;
        endcase
    end
    
    // assign zero = (C == 32'b0);
    assign zero = C[0];

endmodule
