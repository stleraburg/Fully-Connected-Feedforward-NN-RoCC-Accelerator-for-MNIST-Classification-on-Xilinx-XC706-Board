`timescale 1ns / 1ps

module layer2 #(parameter NN = 30,numWeights=784,dataWidth=16,layerNum=1,sigmoidSize=10,weightIntWidth=4,actType="sigmoid") (
    input clk, reset, 
    input weightValid, 
    input biasValid, 
    input [31:0] weightValue, biasValue,
    input [31:0] config_layer_num, 
    input [31:0] config_neuron_num, 
    input x_valid, 
    input [dataWidth-1:0] x_in,
    output [NN-1:0] o_valid, 
    output [NN*dataWidth-1:0] x_out
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(0), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_0.mif"), .weightFile("w_2_0.mif")) n0 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[0*dataWidth+:dataWidth]), 
        .outValid(o_valid[0])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(1), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_1.mif"), .weightFile("w_2_1.mif")) n1 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[1*dataWidth+:dataWidth]), 
        .outValid(o_valid[1])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(2), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_2.mif"), .weightFile("w_2_2.mif")) n2 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[2*dataWidth+:dataWidth]), 
        .outValid(o_valid[2])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(3), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_3.mif"), .weightFile("w_2_3.mif")) n3 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[3*dataWidth+:dataWidth]), 
        .outValid(o_valid[3])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(4), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_4.mif"), .weightFile("w_2_4.mif")) n4 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[4*dataWidth+:dataWidth]), 
        .outValid(o_valid[4])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(5), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_5.mif"), .weightFile("w_2_5.mif")) n5 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[5*dataWidth+:dataWidth]), 
        .outValid(o_valid[5])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(6), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_6.mif"), .weightFile("w_2_6.mif")) n6 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[6*dataWidth+:dataWidth]), 
        .outValid(o_valid[6])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(7), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_7.mif"), .weightFile("w_2_7.mif")) n7 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[7*dataWidth+:dataWidth]), 
        .outValid(o_valid[7])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(8), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_8.mif"), .weightFile("w_2_8.mif")) n8 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[8*dataWidth+:dataWidth]), 
        .outValid(o_valid[8])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(9), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_9.mif"), .weightFile("w_2_9.mif")) n9 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[9*dataWidth+:dataWidth]), 
        .outValid(o_valid[9])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(10), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_10.mif"), .weightFile("w_2_10.mif")) n10 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[10*dataWidth+:dataWidth]), 
        .outValid(o_valid[10])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(11), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_11.mif"), .weightFile("w_2_11.mif")) n11 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[11*dataWidth+:dataWidth]), 
        .outValid(o_valid[11])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(12), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_12.mif"), .weightFile("w_2_12.mif")) n12 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[12*dataWidth+:dataWidth]), 
        .outValid(o_valid[12])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(13), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_13.mif"), .weightFile("w_2_13.mif")) n13 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[13*dataWidth+:dataWidth]), 
        .outValid(o_valid[13])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(14), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_14.mif"), .weightFile("w_2_14.mif")) n14 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[14*dataWidth+:dataWidth]), 
        .outValid(o_valid[14])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(15), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_15.mif"), .weightFile("w_2_15.mif")) n15 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[15*dataWidth+:dataWidth]), 
        .outValid(o_valid[15])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(16), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_16.mif"), .weightFile("w_2_16.mif")) n16 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[16*dataWidth+:dataWidth]), 
        .outValid(o_valid[16])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(17), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_17.mif"), .weightFile("w_2_17.mif")) n17 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[17*dataWidth+:dataWidth]), 
        .outValid(o_valid[17])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(18), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_18.mif"), .weightFile("w_2_18.mif")) n18 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[18*dataWidth+:dataWidth]), 
        .outValid(o_valid[18])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(19), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_19.mif"), .weightFile("w_2_19.mif")) n19 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[19*dataWidth+:dataWidth]), 
        .outValid(o_valid[19])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(20), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_20.mif"), .weightFile("w_2_20.mif")) n20 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[20*dataWidth+:dataWidth]), 
        .outValid(o_valid[20])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(21), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_21.mif"), .weightFile("w_2_21.mif")) n21 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[21*dataWidth+:dataWidth]), 
        .outValid(o_valid[21])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(22), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_22.mif"), .weightFile("w_2_22.mif")) n22 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[22*dataWidth+:dataWidth]), 
        .outValid(o_valid[22])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(23), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_23.mif"), .weightFile("w_2_23.mif")) n23 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[23*dataWidth+:dataWidth]), 
        .outValid(o_valid[23])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(24), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_24.mif"), .weightFile("w_2_24.mif")) n24 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[24*dataWidth+:dataWidth]), 
        .outValid(o_valid[24])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(25), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_25.mif"), .weightFile("w_2_25.mif")) n25 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[25*dataWidth+:dataWidth]), 
        .outValid(o_valid[25])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(26), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_26.mif"), .weightFile("w_2_26.mif")) n26 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[26*dataWidth+:dataWidth]), 
        .outValid(o_valid[26])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(27), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_27.mif"), .weightFile("w_2_27.mif")) n27 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[27*dataWidth+:dataWidth]), 
        .outValid(o_valid[27])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(28), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_28.mif"), .weightFile("w_2_28.mif")) n28 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[28*dataWidth+:dataWidth]), 
        .outValid(o_valid[28])
    );
    
    neuron #(.layerNo(layerNum), .neuronNo(29), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_2_29.mif"), .weightFile("w_2_29.mif")) n29 (
        .clk(clk),
        .reset(reset),
        .in(x_in),
        .inValid(x_valid), 
        .weightValid(weightValid), 
        .biasValid(biasValid), 
        .weightValue(weightValue), 
        .biasValue(biasValue), 
        .config_layer_num(config_layer_num), 
        .config_neuron_num(config_neuron_num), 
        .out(x_out[29*dataWidth+:dataWidth]), 
        .outValid(o_valid[29])
    );

endmodule
