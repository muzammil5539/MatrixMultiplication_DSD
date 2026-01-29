`timescale 1ns / 1ps

/*
 * Baud rate generator to divide {CLOCK_RATE} (internal board clock) into
 * a rx/tx {BAUD_RATE} pair with rx oversamples by 16x.
 */
module BaudRateGenerator  #(
    parameter CLOCK_RATE = 100000000, // board internal clock (def == 100MHz)
    parameter BAUD_RATE = 9600
)(
    input wire clk, // board clock
    output reg rxClk, // baud rate for rx
    output reg txClk // baud rate for tx
);

// Calculate the counter limits
parameter integer MAX_RATE_RX = CLOCK_RATE / (2 * BAUD_RATE * 16);
parameter integer MAX_RATE_TX = CLOCK_RATE / (2 * BAUD_RATE);
parameter integer RX_CNT_WIDTH = $clog2(MAX_RATE_RX + 1);
parameter integer TX_CNT_WIDTH = $clog2(MAX_RATE_TX + 1);

// Counters
reg [RX_CNT_WIDTH-1:0] rxCounter = 0;
reg [TX_CNT_WIDTH-1:0] txCounter = 0;

initial begin
    rxClk = 1'b0;
    txClk = 1'b0;
end

always @(posedge clk) begin
    // RX clock generation
    if (rxCounter == MAX_RATE_RX - 1) begin
        rxCounter <= 0;
        rxClk <= ~rxClk;
    end else begin
        rxCounter <= rxCounter + 1'b1;
    end
    
    // TX clock generation
    if (txCounter == MAX_RATE_TX - 1) begin
        txCounter <= 0;
        txClk <= ~txClk;
    end else begin
        txCounter <= txCounter + 1'b1;
    end
end

endmodule
