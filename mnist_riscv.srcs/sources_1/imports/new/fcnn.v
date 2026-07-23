`timescale 1ns / 1ps

`include "include.v"

module fcnn # (parameter integer imageSize=784) (
    input clk,
    input rst,
    input rx,
    output tx,
    output reg [2:0] im_count,
    // RoCC command channel (from CPU)
    input cmd_valid,
    output cmd_ready,
    input [31:0] cmd_inst,  
    input [31:0] cmd_rs1, cmd_rs2,
    // RoCC response channel (to CPU)
    output resp_valid, 
    input resp_ready, 
    output [4:0] resp_rd,
    output [31:0] resp_data
   );
    
    wire [31:0] config_layer_num;
    wire [31:0] config_neuron_num;
    wire [31:0] weightValue;
    wire [31:0] biasValue;
    wire [31:0] out;
    wire out_valid;
    wire weightValid;
    wire biasValid;
    wire softReset;
    
    wire reset;
    assign reset = ~rst | softReset;
    
    reg pixel_valid_prev; 
    reg pixel_valid; 
    
    // localparam addressWidth = $clog2(imageSize*`numTestImages);
    localparam addressWidth = $clog2(imageSize);
    
    reg wen;
    wire ren;
    reg [addressWidth-1:0] w_addr;
    reg [addressWidth:0] r_addr; 
    reg [`dataWidth-1:0] p_in; 
    wire [`dataWidth-1:0] p_out;
    wire [7:0] rx_data;
    wire rx_valid;
    reg rx_valid_d;
    wire rx_err;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx_done;
    wire [`dataWidth-1:0] pixelValue = {1'b0, rx_data, 7'b0}; 
    reg [15:0] cycle_count;
    
    // Module-level phase FSM (controls load vs stream)`
    localparam M_IDLE = 2'd0, M_LOAD = 2'd1, M_STREAM = 2'd2, M_SEND = 2'd3;
    reg [1:0] state_m;
    
    always @ (posedge clk) begin 
        if (reset) begin 
            w_addr <= 0;
            wen <= 0;
            im_count <= 0;
            r_addr <= 0;
            pixel_valid_prev <= 0;
            tx_start <= 0;
            tx_data <= 8'd0;
            state_m <= M_IDLE; 
            cycle_count <= 0;
        end
        else begin 
            case(state_m) 
                M_IDLE : begin 
                    wen <= 0;
                    pixel_valid_prev <= 0;
                    tx_data <= 8'd0;
                    if (rx_valid) state_m <= M_LOAD;
                end 
                M_LOAD : begin
                    wen <= 0;
                    if (rx_valid_d) begin 
                        if (w_addr == imageSize-1) begin 
                            w_addr <= 0;
                            state_m <= M_STREAM;
                        end else begin 
                            p_in <= pixelValue; 
                            w_addr <= w_addr + 1;
                            wen <= 1;
                        end 
                    end
                end
                M_STREAM : begin
                    if (out_valid) begin
                        tx_start <= 1;
                        tx_data <= out[7:0];
                        state_m <= M_SEND;
                   end else if (r_addr == imageSize) begin 
                        // this is the LAST pixel; stop after it
                        pixel_valid_prev <= 0;   // drops and STAYS dropped
                   end else begin 
                        r_addr <= r_addr + 1;
                        pixel_valid_prev <= 1;
                   end
                end
                M_SEND : begin 
                    tx_start <= 0;
                    if (tx_done) begin
                        r_addr <= 0;
                        state_m <= M_IDLE;
                        im_count <= im_count + 1;
                    end
                end 
            endcase
        end
    end
    
    assign ren = pixel_valid_prev;

    always @ (posedge clk) begin 
        if (reset) begin
            pixel_valid <= 0;
            rx_valid_d <= 0;
        end else begin 
            pixel_valid <= pixel_valid_prev;
            rx_valid_d <= rx_valid;
        end   
    end

    always @(posedge clk) begin
        if (state_m == M_STREAM && !out_valid)
            cycle_count <= cycle_count + 1;
        else if (out_valid) begin
            $display("Inference took %0d clock cycles", cycle_count);
            cycle_count <= 0;
        end
    end
    
    
    rocc_if #(.DATA_WIDTH(`dataWidth)) rocc_net (
        .clk(clk), 
        .reset(reset), 
        .cmd_valid(cmd_valid), 
        .cmd_ready(cmd_ready), 
        .cmd_inst(cmd_inst), 
        .cmd_rs1(cmd_rs1), 
        .cmd_rs2(cmd_rs2),
        .resp_valid(resp_valid), 
        .resp_ready(resp_ready), 
        .resp_rd(resp_rd),
        .resp_data(resp_data),
        .layerNum(config_layer_num),
        .neuronNum(config_neuron_num),
        .weightValue(weightValue),
        .weightValid(weightValid),
        .biasValue(biasValue),
        .biasValid(biasValid),
        .softReset(softReset),
        .nnOut_valid(out_valid), 
        .nnOut(out)
    );
    
    // Serializer FSMs (control inter-layer shifting) - their own 1-bit encoding
    localparam IDLE = 1'd0, SEND = 1'd1;
    
    wire[`numNeuronsL1-1:0] o1_valid;
    wire[`numNeuronsL1*`dataWidth-1:0] x1_out;
    reg[`numNeuronsL1*`dataWidth-1:0] holdData_1;
    reg [`dataWidth-1:0] out_data_1; 
    reg data_out_valid_1;
    
    layer1 #(.NN(`numNeuronsL1), .numWeights(`numWeightsL1), .dataWidth(`dataWidth), .layerNum(1), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`actTypeL1)) l1 (
        .clk(clk), 
        .reset(reset), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue),
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .x_valid(pixel_valid), 
        .x_in(p_out),
        .o_valid(o1_valid), 
        .x_out(x1_out)
    );
    
    //State machine for data pipelining
    reg state_1;
    integer count_1;
    always @ (posedge clk) begin 
        if (reset) begin 
            state_1 <= IDLE;
            count_1 <= 0;
            data_out_valid_1 <= 0;
        end
        else begin 
            case(state_1)
                IDLE : begin 
                    count_1 <= 0;
                    data_out_valid_1 <= 0;
                    if (o1_valid[0] == 1'b1) begin 
                         holdData_1 <= x1_out;
                         state_1 <= SEND;
                     end else begin 
                        holdData_1 <= 0;
                        state_1 <= IDLE;
                     end
                    end
                SEND :  begin 
                        out_data_1 <= holdData_1[`dataWidth-1:0];
                        holdData_1 <= holdData_1 >> `dataWidth;
                        count_1 <= count_1 + 1;
                        data_out_valid_1 <= 1;
                        if (count_1 == `numNeuronsL1) begin 
                            state_1 <= IDLE; 
                            data_out_valid_1 <= 0;
                        end 
                end 
            endcase
        end
    end
    
    wire[`numNeuronsL2-1:0] o2_valid;
    wire[`numNeuronsL2*`dataWidth-1:0] x2_out;
    reg[`numNeuronsL2*`dataWidth-1:0] holdData_2;
    reg [`dataWidth-1:0] out_data_2; 
    reg data_out_valid_2;
    
    layer2 #(.NN(`numNeuronsL2), .numWeights(`numWeightsL2), .dataWidth(`dataWidth), .layerNum(2), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`actTypeL2)) l2 (
        .clk(clk), 
        .reset(reset), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue),
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .x_valid(data_out_valid_1), 
        .x_in(out_data_1),
        .o_valid(o2_valid), 
        .x_out(x2_out)
    );
    
    reg state_2;
    integer count_2;
    always @ (posedge clk) begin 
        if (reset) begin 
            state_2 <= IDLE;
            count_2 <= 0;
            data_out_valid_2 <= 0;
        end
        else begin 
            case(state_2)
                IDLE : begin 
                    count_2 <= 0;
                    data_out_valid_2 <= 0;
                    if (o2_valid[0] == 1'b1) begin 
                        holdData_2 <= x2_out;
                        state_2 <= SEND;
                    end
                    end
                SEND :  begin 
                    out_data_2 <= holdData_2[`dataWidth-1:0];
                    holdData_2 <= holdData_2 >> `dataWidth;
                    count_2 <= count_2 + 1;
                    data_out_valid_2 <= 1;
                    if (count_2 == `numNeuronsL2) begin 
                        state_2 <= IDLE; 
                        data_out_valid_2 <= 0;
                    end 
                end 
            endcase
        end
    end
    
    wire[`numNeuronsL3-1:0] o3_valid;
    wire[`numNeuronsL3*`dataWidth-1:0] x3_out;
    reg[`numNeuronsL3*`dataWidth-1:0] holdData_3;
    reg [`dataWidth-1:0] out_data_3; 
    reg data_out_valid_3;
    
    layer3 #(.NN(`numNeuronsL3), .numWeights(`numWeightsL3), .dataWidth(`dataWidth), .layerNum(3), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`actTypeL3)) l3 (
        .clk(clk), 
        .reset(reset), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue),
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .x_valid(data_out_valid_2), 
        .x_in(out_data_2),
        .o_valid(o3_valid), 
        .x_out(x3_out)
    );
    
    reg state_3;
    integer count_3;
    always @ (posedge clk) begin 
        if (reset) begin 
            state_3 <= IDLE;
            count_3 <= 0;
            data_out_valid_3 <= 0;
        end
        else begin 
            case(state_3)
                IDLE : begin 
                    count_3 <= 0;
                    data_out_valid_3 <= 0;
                    if (o3_valid[0] == 1'b1) begin 
                        holdData_3 <= x3_out;
                        state_3 <= SEND;
                    end
                    end
                SEND :  begin 
                    out_data_3 <= holdData_3[`dataWidth-1:0];
                    holdData_3 <= holdData_3 >> `dataWidth;
                    count_3 <= count_3 + 1;
                    data_out_valid_3 <= 1;
                    if (count_3 == `numNeuronsL3) begin 
                        state_3 <= IDLE; 
                        data_out_valid_3 <= 0;
                    end 
                end 
            endcase
        end
    end
    
    wire[`numNeuronsL4-1:0] o4_valid;
    wire[`numNeuronsL4*`dataWidth-1:0] x4_out;
    reg[`numNeuronsL4*`dataWidth-1:0] holdData_4;
    reg [`dataWidth-1:0] out_data_4; 
    reg data_out_valid_4;
    
    layer4 #(.NN(`numNeuronsL4), .numWeights(`numWeightsL4), .dataWidth(`dataWidth), .layerNum(4), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`actTypeL4)) l4 (
        .clk(clk), 
        .reset(reset), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue),
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .x_valid(data_out_valid_3), 
        .x_in(out_data_3),
        .o_valid(o4_valid), 
        .x_out(x4_out)
    );
    
    reg state_4;
    integer count_4;
    always @ (posedge clk) begin 
        if (reset) begin 
            state_4 <= IDLE;
            count_4 <= 0;
            data_out_valid_4 <= 0;
        end
        else begin 
            case(state_4)
                IDLE : begin 
                    count_4 <= 0;
                    data_out_valid_4 <= 0;
                    if (o4_valid[0] == 1'b1) begin 
                        holdData_4 <= x4_out;
                        state_4 <= SEND;
                    end
                    end
                SEND :  begin 
                    out_data_4 <= holdData_4[`dataWidth-1:0];
                    holdData_4 <= holdData_4 >> `dataWidth;
                    count_4 <= count_4 + 1;
                    data_out_valid_4 <= 1;
                    if (count_4 == `numNeuronsL4) begin 
                        state_4 <= IDLE; 
                        data_out_valid_4 <= 0;
                    end 
                end 
            endcase
        end
    end
    
    scratchpad_mem #(.inSize(imageSize), .addrWidth(addressWidth), .dataWidth(`dataWidth), .testFile("test_data_2.txt")) scratchpad (
        .clk(clk), 
        .wen(wen), 
        .ren(ren), 
        .wadd(w_addr), 
        .radd(r_addr), 
        .pin(p_in), 
        .pout(p_out)
        );
        
    //uart_tx #(.CLK_HZ(100_000_000), .BAUD(115200)) tx_trans (.clk(clk), .reset(reset), .start(tx_start), .data(tx_data), .tx(tx), .busy(tx_busy), .done(tx_done));    
    //uart_rx # (.CLKS_PER_BIT(868)) rx_loader (.clk(clk), .reset(reset), .rx(rx), .data(rx_data), .valid(rx_valid), .err(rx_err));
    
    // for simulation
    uart_tx #(.CLK_HZ(100_000_000), .BAUD(1_000_000)) tx_trans (.clk(clk), .reset(reset), .start(tx_start), .data(tx_data), .tx(tx), .busy(tx_busy), .done(tx_done));    
    uart_rx # (.CLKS_PER_BIT(100)) rx_loader (.clk(clk), .reset(reset), .rx(rx), .data(rx_data), .valid(rx_valid), .err(rx_err));
    
    
    hardmax #(.numInput(`numNeuronsL4), .inputWidth(`dataWidth)) max_finder (
        .clk(clk),
        .i_data(x4_out),
        .i_valid(o4_valid[0]),
        .o_data(out),
        .o_data_valid(out_valid));
    
endmodule
