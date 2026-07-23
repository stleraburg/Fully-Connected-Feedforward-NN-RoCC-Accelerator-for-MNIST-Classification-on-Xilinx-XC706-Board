`timescale 1ns / 1ps

module control_unit(
    input [6:0] opcode,
    output reg RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui,
    output reg [1:0] ALUSrc,
    output reg [2:0] ALUOp);
    
    always @ (*) begin 
        {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} = 13'b0;
        case (opcode) 
            // R-type (ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA)
            7'b0110011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10000000_00_000;
            // I-type (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI, JALR)
            7'b0010011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10000000_01_001;
            //LOAD (LW, LH, LB, LHU, LBU)
            7'b0000011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b11000100_01_110;
            //STORE (SB, SH, SW)
            7'b0100011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b00100100_01_010;
            //BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            // we compare Rs1 and Rs2 and then perform op with pc
            7'b1100011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b00010000_00_011;
            //JAL 
            7'b1101111 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10001000_11_101;
            //JALR 
            7'b1100111 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10001010_11_101;
            // LUI 
            7'b0110111 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10000001_00_100;
            //AUIPC 
            7'b0010111 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10000000_11_100;
            // custom-0 
            7'b0001011 : {RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui, ALUSrc, ALUOp} <= 13'b10000000_00_000;
            default : ;
        endcase
    end
    
endmodule
