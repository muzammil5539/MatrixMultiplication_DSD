`timescale 1ns / 1ps

module UART_Top_Original (
    input wire clk,        // System clock
    input wire reset,      // System reset
    input wire start_tx,   // Start signal for transmitter
    input wire [7:0] tx_data, // Data to transmit
    input wire rx_in,      // Serial data input (RX)
    output wire tx_out,    // Serial data output (TX)
    output wire [7:0] rx_data, // Received data
    output wire rx_done,   // Reception done flag
    output wire rx_busy,   // Reception busy flag
    output wire rx_error,  // Reception error flag
    output wire tx_done,   // Transmission done flag
    output wire tx_busy    // Transmission busy flag
);

    parameter CLOCK_RATE = 100000000; // 100 MHz
    parameter BAUD_RATE = 9600;

    // Internal signals
    wire baud_clk_tx;
	 wire baud_clk_rx;

    // Instantiate Baud Rate Generator
    BaudRateGenerator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) baud_rate_gen (
        .clk(clk),
        .rxClk(baud_clk_rx),
        .txClk(baud_clk_tx)
    );
	 

    // Instantiate UART Transmitter
    Uart8Transmitter uart_tx (
        .clk(baud_clk_tx),
        .en(!reset),
        .start(start_tx),
        .in(tx_data),
        .out(tx_out),
        .done(tx_done),
        .busy(tx_busy)
    );

    // Instantiate UART Receiver
     Uart8Receiver uart_rx (
        .clk(baud_clk_rx),
        .en(!reset),
        .in(rx_in),
        .out(rx_data),
        .done(rx_done),
        .busy(rx_busy),
        .err(rx_error)
    );
	 
	 

	 
	 

endmodule
