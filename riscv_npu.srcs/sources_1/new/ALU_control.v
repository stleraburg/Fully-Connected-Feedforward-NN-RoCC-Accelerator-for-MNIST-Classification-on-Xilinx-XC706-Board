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
`define CUSTOM                  4'b1111

module ALU_control(
    input [2:0] aluop, 
    input [2:0] funct3, 
    input [6:0] funct7,
    output reg [3:0] alu_control);
    
    always @ (*) begin 
        casez ({aluop, funct7, funct3})
            // ADD, LW, SW, AUIPC, ADDI
            {3'b010, 7'b???????, 3'b???}, {3'b100, 7'b???????, 3'b???}, {3'b000, 7'b0000000, 3'b000}, {3'b110, 7'b???????, 3'b???},
            {3'b001, 7'b???????, 3'b000} : alu_control = `ADD;
            
            {3'b000, 7'b0100000, 3'b000} : alu_control = `SUB; // SUB
            
            {3'b011, 7'b???????, 3'b100}, {3'b001, 7'b???????, 3'b010}, {3'b000, 7'b0000000, 3'b010} : alu_control <= `less_than; // SLT, SLTI, BLT
            
            {3'b011, 7'b???????, 3'b101} : alu_control <= `greater_than; // BGE     
            
            {3'b000, 7'b0000000, 3'b011}, {3'b011, 7'b???????, 3'b110}, {3'b001, 7'b???????, 3'b011} : alu_control <= `less_than_unsigned; // SLTU, SLTIU, BLTU
            
            {3'b011, 7'b???????, 3'b111} : alu_control <= `greater_than_unsigned; // BGEU
            
            {3'b000, 7'b0000000, 3'b100}, {3'b001, 7'b???????, 3'b100} : alu_control <= `XOR;
            {3'b000, 7'b0000000, 3'b110}, {3'b001, 7'b???????, 3'b110} : alu_control <= `OR;
            {3'b000, 7'b0000000, 3'b111}, {3'b001, 7'b???????, 3'b111} : alu_control <= `AND;
            
            {3'b000, 7'b0000000, 3'b001}, {3'b001, 7'b0000000, 3'b001} : alu_control <= `SLL;
            {3'b000, 7'b0000000, 3'b101}, {3'b001, 7'b0000000, 3'b101} : alu_control <= `SRL;
            {3'b000, 7'b0100000, 3'b101}, {3'b001, 7'b0100000, 3'b101} : alu_control <= `SRA;
            {3'b011, 7'b???????, 3'b000} : alu_control <= `equal; //BEQ
            {3'b011, 7'b???????, 3'b001} : alu_control <= `not_equal; // BNE
            {3'b101, 7'b???????, 3'b???} : alu_control <= `pc_plus_4; // JAL, JALR
            //{3'b000, 7'b0000001, 3'b000}, {3'b000, 7'b0000001, 3'b001}, {3'b000, 7'b0000001, 3'b010},
            //{3'b000, 7'b0000001, 3'b011}, {3'b000, 7'b0000001, 3'b100} : alu_control <= `CUSTOM; // SET_CONFIG, PUSH_WEIGHT, PUSH_BIAS, SOFT_RESET, READ_RESULT
            default : alu_control <= 4'b0000; 
        endcase
    end
endmodule