`timescale 1ns / 1ps
// soft-core: a CPU built from FPGA LUTs

`include "include.v"

module riscv_core #(parameter IMEM_INIT_FILE="mnist.mem") (input clk_p, clk_n, reset_raw, input rx, output tx, output wire [3:0] result);
// module riscv_core #(parameter IMEM_INIT_FILE="mnist.mem") (input clk, reset, input rx, output tx, output wire [3:0] result); // for sim
    wire clk;
    wire locked;

    //IBUFDS clk_ibuf (.I(clk_p), .IB(clk_n), .O(clk));
    
    clk_wiz_0 clk_div (.clk_out1(clk), .reset(1'b0), .locked(locked), .clk_in1_p(clk_p), .clk_in1_n(clk_n));
    
    // ?? RESET button debouncer ????????????????????????????????????????????
    wire reset;
    wire reset_debounced;
    debounce rst_debounce (.clk(clk), .btn_raw(reset_raw), .btn_clean(reset_debounced), .btn_pulse());
    assign reset = reset_debounced | ~locked;   // held in reset until PLL locks

    // ??  Program Counter ????????????????????????????????????????
    wire [31:0] pc_in, pc;
    wire stall;
    program_counter program_counter (.clk(clk), .reset(~reset), .stall(stall), .pc_in(pc_in), .pc_out(pc));
    
    // ?? BRAM Instruction Memory ???????????????????????????????????
    // Xilinx BRAM inferred from initialized reg array
    // Vivado will map this to block RAM automatically
    reg [31:0] imem [0:255];
    initial $readmemb(IMEM_INIT_FILE, imem);
    wire [31:0] instruction = imem[pc[31:2]]; // word-addressed
    // instruction_memory instruction_memory (.clk(clk), .read_addr(pc), .instruction(instruction));
    
    // ??  Instruction Decode ????????????????????????????????????? 
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];
    
    // ??   Control Unit ??????????????????????????????????????????? 
    wire RegWrite, MemRead, MemWrite, Branch, Jump, MemToReg, PCSrc, Lui;
    wire [1:0] ALUSrc;
    wire [2:0] ALUOp;
    control_unit ctrl (.opcode(opcode), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch), 
                       .Jump(Jump), .MemToReg(MemToReg), .PCSrc(PCSrc), .Lui(Lui), .ALUSrc(ALUSrc), .ALUOp(ALUOp));
                       
    // ??  Register File ?????????????????????????????????????????? 
    wire [31:0] rdata1, rdata2, write_data;
    wire [4:0] final_rd;
    reg_file rf (.clk(clk), .reset(~reset), .RegWrite(RegWrite), .rs1(rs1), .rs2(rs2), .rd(final_rd), .write_data(write_data), .read_data1(rdata1), .read_data2(rdata2));
    
    // ??  Immediate Generator ???????????????????????????????????? 
    wire [31:0] imm;
    imm_gen ig (.opcode(opcode), .instruction(instruction), .immediate(imm));
    
     // ?? ALU ???????????????????????????????????????????????????? 
     wire [3:0] alu_ctrl;
     wire alu_zero;
     wire [31:0] alu_result;
     wire [31:0] mux1_res, mux2_res, mux3_res, mux4_res, mux5_res, mux6_res;
     wire [31:0] rocc_wb;
     ALU_control alu_control (.aluop(ALUOp), .funct3(funct3), .funct7(funct7), .alu_control(alu_ctrl));
     ALU alu (.A(mux2_res), .B(mux1_res), .control_in(alu_ctrl), .zero(alu_zero), .C(alu_result));
     
     // ?? Data Memory ???????????????????????????????????????????? 
     wire [31:0] dmem_rdata;
     wire [3:0] led_result;
     data_memory dmem (.clk(clk), .reset(~reset), .address(alu_result), .write_data(rdata2), .mem_write(MemWrite), 
                       .mem_read(MemRead), .read_data(dmem_rdata), .led_result(led_result));

    // ?? MUXes ???????????????????????????????????????????? 
    wire and_res, or_res;
    wire is_custom_opcode = (opcode == 7'b0001011);
    mux1 m1 (.A1(rdata2), .B1(imm), .sel1(ALUSrc[0]), .mux1_out(mux1_res));
    mux2 m2 (.A2(pc), .B2(rdata1), .sel2(ALUSrc[1]), .mux2_out(mux2_res));
    mux3 m3 (.A3(alu_result), .B3(dmem_rdata), .sel3(MemToReg), .mux3_out(mux3_res));
    mux4 m4 (.A4(pc), .B4(rdata1), .sel4(PCSrc), .mux4_out(mux4_res));
    mux5 m5 (.A5(4), .B5(imm), .sel5(or_res), .mux5_out(mux5_res));
    mux6 m6 (.A6(mux3_res), .B6(imm), .sel6(Lui), .mux6_out(mux6_res));
    mux7 m7 (.A7(mux6_res), .B7(rocc_wb), .sel7(is_custom_opcode), .mux7_out(write_data));
    
    // ?? Gates ???????????????????????????????????????????? 
    AND_gate and_gate (.branch(Branch), .zero(alu_zero), .and_out(and_res));
    OR_gate or_gate (.jump(Jump), .and_out(and_res), .or_out(or_res));
    
    // ?? Adder ????????????????????????????????????????????
    adder pc_adder (.in_1(mux4_res), .in_2(mux5_res), .out(pc_in));
    
    assign result = led_result;
    
    // to check if the input data (image) is being transmitted 
    //assign result[0] = ~rx;
    //assign result[3:1] = 3'b0;
    
    // ?? RoCC accelerator FCNN coprocessor????????????????????????????????????????????
    reg cmd_valid;
    wire cmd_ready;
    reg [31:0] cmd_inst;
    reg [31:0] cmd_rs1, cmd_rs2;
    wire resp_valid;
    wire [31:0] resp_data;
    wire [4:0] resp_rd; 
    wire resp_ready;
   
    reg rocc_waiting; 
    reg is_read_result_pending;
    //reg [15:0] labels [0:`numTestImages-1];
    reg [7:0] right; // up to 255 correct answers
    reg [7:0] wrong;    
    reg rocc_done;
    wire [2:0] im_count;
    
    /*
    initial begin
        labels[0] = 16'd7;
        labels[1] = 16'd8;
        labels[2] = 16'd9;
    end
    */
    
    fcnn rocc_net (.clk(clk), .rst(~reset), .rx(rx), .tx(tx), .im_count(im_count), .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_inst(cmd_inst), .cmd_rs1(cmd_rs1), .cmd_rs2(cmd_rs2),
        .resp_valid(resp_valid), .resp_ready(resp_ready), .resp_rd(resp_rd), .resp_data(resp_data));
        
    assign resp_ready = 1'b1; 
    assign rocc_wb = resp_data;
    assign final_rd = (resp_valid && resp_ready) ? resp_rd : rd;
    
    always @ (posedge clk) begin 
        if (reset) begin 
            rocc_waiting <= 1'b0;
            right <= 0;
            wrong <= 0;
            is_read_result_pending <= 0; 
            rocc_done = 1'b0;           
        end
        else if (is_custom_opcode && !rocc_waiting && !rocc_done) begin 
            cmd_valid <= 1'b1;
            rocc_waiting <= 1'b1;
            cmd_inst <= instruction;
            cmd_rs1 <= rdata1;
            cmd_rs2 <= rdata2;
            is_read_result_pending <= (funct7 == 7'b0000001 && funct3 == 3'b011);
        end 
        else begin 
            if (resp_valid && resp_ready) begin
                cmd_valid <= 1'b0; 
                rocc_done = 1'b1;
                rocc_waiting <= 1'b0;
                if (is_read_result_pending) begin
                    is_read_result_pending <= 1'b0;
                    //if (resp_data == labels[im_count-1]) right <= right + 1;
                    //else wrong <= wrong + 1;
                    //$display("Detected number: %x, Expected: %x", resp_data, labels[im_count]);
                    $display("Detected number: %d.", resp_data);
                end
            end else rocc_done <= 1'b0;        
        end
    end
    
    assign stall = (is_custom_opcode && !rocc_done) || rocc_waiting;
   
endmodule
