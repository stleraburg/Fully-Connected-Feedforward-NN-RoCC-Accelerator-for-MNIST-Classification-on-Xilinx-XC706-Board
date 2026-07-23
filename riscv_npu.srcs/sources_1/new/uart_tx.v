`timescale 1ns / 1ps

module uart_tx #(parameter CLK_HZ = 200_000_000, BAUD = 1_000_000) (
    input wire clk,
    input wire reset, 
    input wire start,
    input wire [7:0] data, 
    output reg tx,
    output wire busy, 
    output reg done);
    
    localparam CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    
    reg [1:0] state; 
    reg [15:0] baud_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shift;
    
    assign busy = (state != IDLE);
    
    always @ (posedge clk) begin 
        done <= 1'b0;
        if (reset) begin 
            state <= IDLE; 
            tx <= 1'b1;
            baud_cnt <= 0;
            bit_idx <= 0;
        end else begin 
            case (state)
                IDLE : begin 
                    tx <= 1'b1;
                    if (start) begin 
                        shift <= data;
                        state <= START;
                        baud_cnt <= 0;
                    end
                end 
                START : begin 
                    tx <= 1'b0; 
                    if (baud_cnt == CLKS_PER_BIT-1) begin 
                        baud_cnt <= 0; 
                        bit_idx <= 0;
                        state <= DATA;
                    end else 
                        baud_cnt <= baud_cnt + 1;                
                end 
                DATA : begin 
                    tx <= shift[bit_idx];
                    if (baud_cnt == CLKS_PER_BIT-1) begin 
                        baud_cnt <= 0; 
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else 
                            bit_idx <= bit_idx + 1;
                    end else 
                        baud_cnt <= baud_cnt + 1;                
                end 
                STOP : begin 
                    tx <= 1'b1;
                    if (baud_cnt == CLKS_PER_BIT -1) begin 
                        baud_cnt <= 0;
                        state <= IDLE; 
                        done <= 1'b1;
                    end else 
                        baud_cnt <= baud_cnt + 1;
                end
            endcase 
        end
    end
    
endmodule
