`timescale 1ns / 1ps

module tb_riscv_rx;

parameter CLK_PERIOD = 10; // 100MHz 
parameter CLKS_PER_BIT = 100; // 1_000_000 baud at 100MHz (for simulation, in real - 115200 baud)
parameter BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT; // ns per bit 

reg [7:0] im1 [783:0];
reg [7:0] im2 [783:0];
reg [7:0] im3 [783:0];
integer k;

reg clk = 0;
reg reset = 1;
reg rx = 1; // idle high 
wire [3:0] num_correct;

riscv_core #(.IMEM_INIT_FILE("mnist.mem")) cpu (.clk(clk), .reset(reset), .rx(rx), .result(num_correct));

always #(CLK_PERIOD/2) clk = ~clk;

// ---- Task: send one pixel over serial line ----
task send_pixel;
    input [7:0] byte_in;
    integer i;
    begin 
        rx = 1'b0;
        #(BIT_PERIOD);
        for (i=0; i<8; i=i+1) begin 
            rx = byte_in[i];
            #(BIT_PERIOD);
        end
        rx = 1'b1;
        #(BIT_PERIOD);
    end
endtask

// ---- Stimulus ----
initial begin 
    $dumpfile("tb_riscv_rx.vcd");
    $dumpvars(0, tb_riscv_rx);
    
    // test images (3 for now)
    $readmemb("im1.txt", im1);
    $readmemb("im2.txt", im2);
    $readmemb("im3.txt", im3);
    
    // reset 
    @(posedge clk);
    reset = 1;
    repeat(10) @(posedge clk);
    reset = 0;
    #(BIT_PERIOD); // idle gap 
    
    for (k=0; k<784; k=k+1) send_pixel(im1[k]);
    // @(posedge cpu.resp_valid);
    @(posedge cpu.rocc_net.tx_done);
    for (k=0; k<784; k=k+1) send_pixel(im2[k]);
    @(posedge cpu.rocc_net.tx_done);
    for (k=0; k<784; k=k+1) send_pixel(im3[k]);
    @(posedge cpu.rocc_net.tx_done);
    repeat(100) @(posedge clk);
    
    // This can be used if "result" represents the number of correct predictions, that is, predictions matching with labels
    // However, in real implementation, the labels are unknown, so I dropped this idea 
    /***
    if (num_correct == 4'd3)
        $display ("\nPASSED All images are correctly classified!"); 
    else 
        $display ("\nFAILED Some images are wrongly classified!");
   ***/
   
     $finish;    
end

endmodule
