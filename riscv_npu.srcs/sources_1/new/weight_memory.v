`timescale 1ns / 1ps

module weight_memory #(parameter numWeights=3, neuronNo=5, layerNo=1, addressWidth=10, dataWidth=16, weightFile="") (
    input clk, 
    input ren, wen, 
    input [addressWidth-1:0] wadd,
    input [addressWidth:0] radd,
    input [dataWidth-1:0] win,
    output reg [dataWidth-1:0] wout);
    
    reg [dataWidth-1:0] mem [numWeights-1:0];
    
    `ifdef pretrained 
        initial $readmemb(weightFile, mem);
    `else 
        always @ (posedge clk) begin 
            if (wen) begin 
                mem[wadd] <= win;
            end
        end 
    `endif
    
    always @ (posedge clk) begin 
        if (ren) begin 
            wout <= mem[radd];
        end
    end
    

    
endmodule
