`timescale 1ns / 1ps

module imm_gen(
    input [6:0] opcode, 
    input [31:0] instruction,
    output reg [31:0] immediate);
    
    initial immediate <= 0;
    
    always @ (*) begin 
        case (opcode) 
            7'b0010011 : begin 
                case (instruction[14:12])
                    3'b001, 3'b101 : immediate <= {27'b0, instruction[24:20]};
                    default : immediate <= $signed({{20{instruction[31]}}, instruction[31:20]});
                endcase
            end 
            7'b0000011, 7'b1100111 : immediate = {{20{instruction[31]}}, instruction[31:20]}; // load
            7'b0100011 : immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type 
            7'b1100011 : immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            7'b1101111 : immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
            7'b0010111, 7'b0110111 : immediate = {instruction[31:12], 12'b0}; // AUPIC or LUI
        endcase
    end
endmodule 
