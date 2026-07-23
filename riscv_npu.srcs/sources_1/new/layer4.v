`timescale 1ns / 1ps

module layer4 #(parameter NN = 30,numWeights=784,dataWidth=16,layerNum=1,sigmoidSize=10,weightIntWidth=4,actType="sigmoid") (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(0), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_0.mif"), .weightFile("w_4_0.mif")) n0 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(1), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_1.mif"), .weightFile("w_4_1.mif")) n1 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(2), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_2.mif"), .weightFile("w_4_2.mif")) n2 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(3), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_3.mif"), .weightFile("w_4_3.mif")) n3 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(4), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_4.mif"), .weightFile("w_4_4.mif")) n4 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(5), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_5.mif"), .weightFile("w_4_5.mif")) n5 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(6), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_6.mif"), .weightFile("w_4_6.mif")) n6 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(7), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_7.mif"), .weightFile("w_4_7.mif")) n7 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(8), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_8.mif"), .weightFile("w_4_8.mif")) n8 (
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
    
    neuron #(.layerNo(layerNum), .neuronNo(9), .numWeights(numWeights), .dataWidth(dataWidth), .sigmoidSize(sigmoidSize), .weightIntWidth(weightIntWidth), .actType(actType), .biasFile("b_4_9.mif"), .weightFile("w_4_9.mif")) n9 (
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
    
endmodule
