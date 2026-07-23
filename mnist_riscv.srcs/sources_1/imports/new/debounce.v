`timescale 1ns / 1ps

// The idea: only accept a new button state if the input has been stable for N consecutive cycles. Any glitch shorter than N cycles is ignored.

module debounce #(parameter STABLE_COUNT = 3_000_000) (
    input wire clk,
    input wire btn_raw, // raw button input (may bounce)
    output reg btn_clean, // debounced stable output
    output wire btn_pulse); // one-cycle pulse on rising edge of btn_clean
    
    // two-flop synchronizer to prevent metastability 
    (* ASYNC_REG = "TRUE" *) reg ff1, ff2;
    always @(posedge clk) begin
        ff1 <= btn_raw; // first flop: may go metastable
        ff2 <= ff1;
    end
    wire btn_sync;
    assign btn_sync = ff2;
    
    reg [21:0] cnt; // up to 3M, needs 22 bits
    reg last_raw; // previous raw btn_clean
    
    initial begin 
        cnt <= 22'd0;
        btn_clean <= 1'b0;
        last_raw <= 1'b0;
    end
    
    
    always @(posedge clk) begin 
            if (btn_sync != last_raw) begin 
                cnt <= 22'd0; // input changed - restart timer 
            end else if (cnt < STABLE_COUNT - 1) begin 
                cnt <= cnt + 1; // still counting stability
            end else begin 
                btn_clean <= btn_sync; // stable for long enough - accept 
            end
            last_raw <= btn_sync;
    end
    
    // rising edge detector on btn_clean 
    reg btn_clean_r;
    always @ (posedge clk) btn_clean_r <= btn_clean;
    assign btn_pulse = btn_clean & ~btn_clean_r;
endmodule
