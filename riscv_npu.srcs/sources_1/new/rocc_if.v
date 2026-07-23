`timescale 1ns / 1ps

// the bridge between Rochet RISC-V CPU & FCNN (RoCC accelerator)
// custom-0 operations: start inference, set config, push weight, push bias, read result, soft reset (), read status (
module rocc_if #(parameter DATA_WIDTH=32) (
    input clk, reset, 
    // ??? RoCC Command Channel (from CPU) ??????????????????????????????? 
    input cmd_valid, 
    output cmd_ready, 
    input [31:0] cmd_inst, 
    input [31:0] cmd_rs1, 
    input [31:0] cmd_rs2,
    // ??? RoCC Response Channel (to CPU)?????????????????????????????? 
    output reg resp_valid, 
    input resp_ready, 
    output reg [4:0] resp_rd,
    output reg [31:0] resp_data,
    ////////////////////////////////////////////////////////////////
    output reg [31:0] layerNum,
    output reg [31:0] neuronNum,
    output reg [31:0] weightValue,
    output reg weightValid,
    output reg [31:0] biasValue,
    output reg biasValid,
    output reg softReset,
    input nnOut_valid, 
    input [31:0] nnOut
);

    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [4:0] rd;
    assign funct7 = cmd_inst[31:25];
    assign funct3 = cmd_inst[14:12];
    assign rd = cmd_inst[11:7]; 
    
    reg pending_result;
    reg [4:0] pending_rd;
    
    assign cmd_ready = 1'b1;
    
    always @ (posedge clk) begin 
        if (reset) begin 
            resp_valid <= 0;  
            resp_rd <= 5'b0; 
            resp_data <= 0;
            softReset <= 0;
            pending_result <= 0;
            pending_rd <= 0;
        end 
        else begin 
            weightValid <= 0; 
            biasValid <= 0; 
            // resp_valid <= resp_valid && !resp_ready; 
            
            if (pending_result && nnOut_valid) begin
                resp_valid     <= 1'b1;
                resp_rd        <= pending_rd;
                resp_data      <= nnOut;
                pending_result <= 1'b0;
            end
        
            if (cmd_valid && cmd_ready) begin 
                case ({funct7, funct3})
                    10'b0000001_000 : begin // SET_CONFIG
                        resp_valid <= 1'b1;
                        layerNum <= cmd_rs1;
                        neuronNum <= cmd_rs2;
                    end
                    10'b0000001_001 : begin // PUSH_WEIGHT
                        resp_valid <= 1'b1;
                        weightValue <= cmd_rs1;
                        weightValid <= 1'b1;
                    end
                    10'b0000001_010 : begin // PUSH_BIAS
                        resp_valid <= 1'b1;
                        biasValue <= cmd_rs1;
                        biasValid  <= 1'b1;
                    end
                    10'b0000001_011 : begin // READ_RESULT
                        pending_result <= 1'b1;
                        pending_rd <= rd;
                    end
                    10'd6 : begin // SOFT_RESET
                        resp_valid <= 1'b1;
                        softReset <= 1'b1;
                    end
                endcase
            end
            if (resp_valid && resp_ready) begin // Clear response after CPU accepts
                resp_valid <= 0;
            end
        end    
    end

endmodule
