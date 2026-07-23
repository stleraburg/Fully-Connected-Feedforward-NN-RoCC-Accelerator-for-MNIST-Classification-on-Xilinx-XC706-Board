`timescale 1ns / 1ps

module neuron #(parameter layerNo=0, neuronNo=0, numWeights=784, dataWidth=16, sigmoidSize=5, weightIntWidth=1, actType="sigmoid", biasFile="", weightFile="") (
    input clk, reset, 
    input [dataWidth-1:0] in,
    input inValid, weightValid, biasValid, 
    input [31:0] weightValue, biasValue, 
    input [31:0] config_layer_num, 
    input [31:0] config_neuron_num, 
    output [dataWidth-1:0] out, 
    output reg outValid);
    
    localparam addressWidth = $clog2(numWeights);
    
    reg wen;
    wire ren;
    reg [addressWidth-1:0] w_addr;
    reg [addressWidth:0] r_addr; //read address has to reach until numWeight hence width is 1 bit more
    reg [dataWidth-1:0] w_in; 
    wire [dataWidth-1:0] w_out;
    reg [2*dataWidth-1:0] mul;
    reg [2*dataWidth-1:0] sum;
    reg [2*dataWidth-1:0] bias;
    reg [31:0] biasReg [0:0];
    reg weight_valid;
    reg mult_valid;
    wire mux_valid;
    reg sigValid;
    wire [2*dataWidth:0] comboAdd;
    wire [2*dataWidth:0] biasAdd;
    reg [dataWidth-1:0] ind; 
    reg muxValid_d;
    reg muxValid_f;
    reg addr = 0;    
    
    
    // Loading weight values into the memory    
    always @ (posedge clk) begin 
        if (reset) begin 
            w_addr <= {addressWidth{1'b1}}; // set to all-1s so it wraps to 0 on first write
            wen <= 0; 
        end else if (weightValid && (config_layer_num==layerNo) && (config_neuron_num==neuronNo)) begin 
            w_in <= weightValue; // writes the weight to the weight memory BRAM at w_addr 
            w_addr <= w_addr + 1;
            wen <= 1;
        end else 
            wen <= 0;
    end
    
    assign ren = inValid;
    assign mux_valid = mult_valid; // pulses high once per valid input, for exactly as many cycles as there are inputs streaming in
    assign biasAdd = bias + sum;
    assign comboAdd = mul + sum;
    
    `ifdef pretrained 
        initial $readmemb(biasFile, biasReg);
        always @ (posedge clk) begin 
            bias <= {biasReg[addr][dataWidth-1:0],{dataWidth{1'b0}}};
        end
    `else 
        always @ (posedge clk) begin 
            if (biasValid && (config_layer_num==layerNo) && (config_neuron_num==neuronNo))
                bias <= {biasValue[dataWidth-1:0], {dataWidth{1'b0}}};
        end
    `endif
    
    always @ (posedge clk) begin 
        if (reset | outValid)
            r_addr <= 0;
        else if (inValid)
            r_addr <= r_addr + 1;
    end
    
    
    
    /*
    always @(posedge clk) begin
        if (reset | outValid) begin 
            muxValid_d   <= 1'b0;
            muxValid_f   <= 1'b0;
            weight_valid <= 1'b0;         // clear the whole valid pipeline too
            mult_valid   <= 1'b0;
        end else begin
            muxValid_d   <= mux_valid; 
            muxValid_f   <= !mux_valid & muxValid_d;
            weight_valid <= inValid;
            mult_valid   <= weight_valid;
        end
    end
    */
    
    /*
    always @(posedge clk) begin
        if (layerNo==1 && neuronNo==0) begin
            // sample a few points during streaming
            if (inValid && (r_addr == 125 || r_addr == 440 || r_addr == 782 || r_addr == 783 || r_addr == 784))
                $display("[%0t] L1N0: r_addr=%0d in=%b w_out=%h mul=%h sum=%h", 
                         $time, r_addr, in, w_out, mul, sum);
            if (outValid)
                $display("[%0t] L1N0: DONE sum=%h bias=%h out=%h", $time, sum, bias, out);
        end
    end
    */
    
    
    always @ (posedge clk) begin 
        mul <= $signed(ind) * $signed(w_out);
    end
    
    always @ (posedge clk) begin 
        if (reset | outValid) 
            sum <= 0;
        else if ((r_addr == numWeights) & muxValid_f) begin 
           if (!bias[2*dataWidth-1] && !sum[2*dataWidth-1] && biasAdd[2*dataWidth-1]) begin 
            sum[2*dataWidth-1] <= 1'b0;
            sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
           end 
           else if (bias[2*dataWidth-1] && sum[2*dataWidth-1] && !biasAdd[2*dataWidth-1]) begin 
            sum[2*dataWidth-1] <= 1'b1;
            sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
           end
           else 
            sum <= biasAdd;
        end 
        else if (mux_valid) begin 
            if (!mul[2*dataWidth-1] & !sum[2*dataWidth-1] & comboAdd[2*dataWidth-1]) begin 
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end else if (mul[2*dataWidth-1] & sum[2*dataWidth-1] & !comboAdd[2*dataWidth-1]) begin 
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            else 
                sum <= comboAdd;
        end
    end
    
    always @ (posedge clk) begin 
        ind <= in; // we still need "in" after once cycle of latency taken for synchronous BRAM's read 
        weight_valid <= inValid; // also needs to be delayed for the same reason
        mult_valid <= weight_valid; 
        // mult_valid delays weight_valid by one more cycle, 
        // so that when mul finally holds a real product, mult_valid (aliased as mux_valid) says "yes, trust this" at exactly that same cycle
        
        // outvalid delays sigValid by one more cycle, to align with when out 
        // (coming out of the activation module) is actually ready to be read 
        sigValid <= ((r_addr == numWeights) & muxValid_f) ? 1'b1 : 1'b0; // the last input has been processed through MAC 
        outValid <= sigValid; 
        
        muxValid_d <= mux_valid; 
        muxValid_f <= !mux_valid & muxValid_d; // checking: "was mux_valid high last cycle, but it's low this cycle?" - i.e., a falling edge
    end 
    
    
    /*
    always @ (posedge clk) begin 
        if (reset | outValid) begin
            sigValid <= 1'b0;
            outValid <= 1'b0;
        end else begin
            sigValid <= ((r_addr == numWeights) & muxValid_f) ? 1'b1 : 1'b0;
            outValid <= sigValid; 
        end
        ind <= in;
    end
    */
    
    // instantiation of memory for weights 
    weight_memory #(.numWeights(numWeights), .neuronNo(neuronNo), .layerNo(layerNo), .addressWidth(addressWidth), .dataWidth(dataWidth), .weightFile(weightFile)) WM (
        .clk(clk),
        .wen(wen),
        .ren(ren),
        .wadd(w_addr),
        .radd(r_addr),
        .win(w_in),
        .wout(w_out)
    );
    
    generate 
        if (actType == "sigmoid") 
        begin : siginst 
            sigROM #(.inWidth(sigmoidSize), .dataWidth(dataWidth)) sigmoid (.clk(clk), .x(sum[2*dataWidth-1-:sigmoidSize]), .out(out));
        end else 
        begin : reluinst
            ReLU #(.dataWidth(dataWidth), .weightIntWidth(weightIntWidth)) relu (.clk(clk), .x(sum), .out(out));
        end 
    endgenerate
    
endmodule
