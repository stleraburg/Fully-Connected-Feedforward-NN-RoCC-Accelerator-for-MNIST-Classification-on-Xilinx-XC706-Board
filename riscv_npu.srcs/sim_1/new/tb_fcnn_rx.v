`timescale 1ns / 1ps

module tb_fcnn_rx;

parameter CLK_PERIOD = 10; // 100MHz (for simulation, in real - 20MHz)
parameter CLKS_PER_BIT = 100; // 115200 baud at 100MHz (for simulation, in real - 9600 baud)
parameter BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT; // ns per bit 

reg clk = 0;
reg reset = 0;
wire [2:0] im_count; 
reg rx = 1; // idle high 
reg cmd_valid;
wire cmd_ready;
reg [31:0] cmd_inst;
reg [31:0] cmd_rs1, cmd_rs2;
wire resp_valid;
wire [31:0] resp_data;
wire [4:0] resp_rd; 

reg [7:0] right = 0; // up to 255 correct answers
reg [7:0] wrong = 0;
reg [7:0] im1 [783:0];
reg [7:0] im2 [783:0];
reg [7:0] im3 [783:0];
reg [15:0] labels [2:0];
integer k;

fcnn #(.imageSize(784)) dut (.clk(clk), .rst(reset), .rx(rx), .im_count(im_count), 
                             .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_inst(cmd_inst), .cmd_rs1(cmd_rs1), .cmd_rs2(cmd_rs2),
                             .resp_valid(resp_valid), .resp_ready(1'b1), .resp_rd(resp_rd), .resp_data(resp_data));

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

// ---- Task: processor's reading inference result ----
task read_result;
    input [31:0] instruction;
    input [31:0] rdata1; 
    input [31:0] rdata2; 
    begin 
        cmd_valid = 1'b1;
         @(posedge clk);
         cmd_inst = instruction;
         cmd_rs1 = rdata1;
         cmd_rs2 = rdata2;
         @(posedge clk);
        //cmd_valid = 1'b0; 
    end
endtask

// ---- Task: check the inference result ----
task check_result;
    input [15:0] label;
    begin 
        @(posedge resp_valid); 
        @(posedge clk);
        if (resp_data == label) begin 
            right <= right + 1;
            $display("PASS: detected number: %x, expected: %x", resp_data, label);
        end else begin 
            wrong <= wrong + 1;
            $display("FAIL: detected number: %x, expected: %x", resp_data, label);
        end
        cmd_valid = 1'b0;
    end
endtask

// ---- Stimulus ----
initial begin 
    $dumpfile("tb_fcnn_rx.vcd");
    $dumpvars(0, tb_fcnn_rx);
    
    // labels array population
    labels[0] = 16'd5;
    labels[1] = 16'd2;
    labels[2] = 16'd1;
    // test images 
    $readmemb("im1.txt", im1);
    $readmemb("im2.txt", im2);
    $readmemb("im3.txt", im3);
    
    // reset 
    @(posedge clk);
    reset = 0;
    repeat(10) @(posedge clk);
    reset = 1;
    #(BIT_PERIOD); // idle gap 
    
    // Test 1: 1st image (5)
    fork
        for (k=0; k<784; k=k+1) send_pixel(im1[k]);
        read_result(32'h2003B0B, 32'b0, 32'b0);
        check_result(labels[im_count]);
    join
    #(BIT_PERIOD * 2);
    
    // Test 2: 1st image (2)
    fork
        for (k=0; k<784; k=k+1) send_pixel(im2[k]);
        read_result(32'h2003B0B, 32'b0, 32'b0);
        check_result(labels[im_count]);
    join 
    #(BIT_PERIOD * 2);
    
    // Test 1: 1st image (1)
    fork
        for (k=0; k<784; k=k+1) send_pixel(im3[k]);
        read_result(32'h2003B0B, 32'b0, 32'b0);
        check_result(labels[im_count]);
    join
    #(BIT_PERIOD * 2);
    
    // Summary 
    if (wrong == 0)
        $display ("\nALL TESTS PASSED (%0d/%0d)", right, right+wrong);
    else 
        $display("\nFAILED: %0d/%0d tests passed", right, right+wrong);
    
     $finish;    
end

// ---- Timeout watchdog ----
/*
initial begin
    #(BIT_PERIOD * 100);
    $display("TIMEOUT");
    $finish;
end
*/

endmodule
