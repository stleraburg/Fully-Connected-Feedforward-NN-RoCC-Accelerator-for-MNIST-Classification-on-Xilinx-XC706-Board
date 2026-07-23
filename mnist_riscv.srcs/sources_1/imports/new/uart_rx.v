`timescale 1ns / 1ps

module uart_rx # (
    parameter CLKS_PER_BIT = 100 // clocks per one UART clk (sys_clk / baud rate = 20M / 9600)
)(
    input clk, 
    input reset, 
    input rx,
    output reg [7:0] data, 
    output reg valid,
    output reg err
    );
    
    // oversample at 16x: ticks per oversample period 
    localparam OSAMP_DIV = CLKS_PER_BIT / 16;
    localparam HALF_BIT = 8; // 8 oversampling ticks = half bit period 
    localparam FULL_BIT = 16; // 16 oversampling ticks = full bit period 
    
    // FSM states 
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3; 
    
    reg [1:0] state = IDLE;
    reg [9:0] clk_cnt = 0; // counts system clocks for one oversample tick 
    reg [3:0] osamp_cnt = 0; // counts oversmapling ticks within a bit 
    reg [2:0] bit_idx = 0; // which data bit we are receiving (0-7)
    reg [7:0] shift_reg = 0; // shift register accumulates data bits 
    
    // double-flop rx input to meta-stabilize 
    reg rx_s1, rx_s2;
    always @ (posedge clk) begin 
        rx_s1 <= rx;
        rx_s2 <= rx_s1;
    end
    
    // Oversample tick strobe (pulses high once every OSAMP_DIV clocks) 
    reg tick; 
    always @ (posedge clk) begin 
        if (reset) begin 
            clk_cnt <= 0;
            tick <= 0; 
        end else begin 
            tick <= 0; 
            if (clk_cnt == OSAMP_DIV - 1) begin 
                clk_cnt <= 0; 
                tick <= 1; 
            end else begin 
                clk_cnt <= clk_cnt + 1;
            end
        end
    end
    
    // main receiver FSM 
    always @ (posedge clk) begin 
        if (reset) begin 
            state <= IDLE; 
            osamp_cnt <= 0; 
            bit_idx <= 0;
            shift_reg <= 0; 
            data <= 0; 
            valid <= 0; 
            err <= 0;
        end else begin 
            valid <= 0; 
            err <= 0; 
            case(state)
                IDLE : begin 
                    osamp_cnt <= 0; 
                    bit_idx <= 0; 
                    if (rx_s2 == 1'b0) // detect falling edge of start bit 
                        state <= START;
                end
                // Wait half a bit period, then re-check RX is still 0 
                START : begin 
                    if (tick) begin 
                        if (osamp_cnt == HALF_BIT - 1) begin 
                            osamp_cnt <= 0; 
                            if (rx_s2 == 1'b0) 
                                state <= DATA;
                            else 
                                state <= IDLE; 
                        end else begin 
                            osamp_cnt <= osamp_cnt + 1;
                        end
                    end
                end
                // Sample each data bit at its centre (every 16 ticks) 
                DATA : begin 
                    if (tick) begin 
                        if (osamp_cnt == FULL_BIT - 1) begin 
                            osamp_cnt <= 0; 
                            // sample bit at center 
                            shift_reg <= {rx_s2, shift_reg[7:1]}; // LSB first 
                            if (bit_idx == 3'd7) begin 
                                bit_idx <= 0; 
                                state <= STOP;
                            end else begin 
                                bit_idx <= bit_idx + 1;
                            end
                        end else begin 
                            osamp_cnt <= osamp_cnt + 1;
                        end
                    end
                end
                // wait one full bit period then sample stop bit 
                STOP : begin 
                    if (tick) begin 
                        if (osamp_cnt == FULL_BIT - 1) begin 
                            osamp_cnt <= 0;
                            state <= IDLE;
                            if (rx_s2 == 1'b1) begin 
                                data <= shift_reg;
                                valid <= 1; 
                            end else begin 
                                err <= 1; // framing error 
                            end
                        end else begin 
                            osamp_cnt <= osamp_cnt + 1;
                        end
                    end 
                end  
                default : state <= IDLE;                 
            endcase
        end
    end
    
endmodule
