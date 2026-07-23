`timescale 1ns / 1ps
module riscv_sim();
    
    reg clk = 0;
    reg reset = 0;
    
    wire result;
    
    riscv_core riscv (.clk(clk), .reset(reset), .result(result));
    
    always #5 clk = ~clk;
    
    integer i;    
    initial begin 
        repeat(2) @(posedge clk);
        reset = 1;  // release reset
        
        repeat(500) @(posedge clk);  // enough cycles for loop to complete
        #1;
        
        $display("PC=%h instr=%h MemWrite=%b addr=%h data=%d",
          riscv.pc,
          riscv.instruction,
          riscv.MemWrite,
          riscv.alu_result,
          riscv.rdata2);
        
        begin : check_result
            reg [31:0] check;
            check = riscv.dmem.mem[0];
            if (check == 32'd15)
                $display("PASS: sum(1..5) = %0d", check);
            else 
                $display("FAIL: got %0d (expected 15)", check);
         end
        
        $display("--- Register File Snapshot ---");
        for (i = 0; i < 8; i = i+1)
            $display("  x%0d = %0d", i, riscv.rf.registers[i]);

        $finish;
    end
 
endmodule