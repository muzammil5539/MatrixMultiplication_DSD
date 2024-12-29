`timescale 1ns / 1ps

module UART_Top_Original (
    input wire clk,        // System clock
    input wire reset,      // System reset
    input wire rx_in,      // Serial data input (RX)
    output wire tx_out,    // Serial data output (TX)
    output wire [7:0] rx_data, // Received data
    output reg [4:0] states,
    output reg rx_done,   // Reception done flag
    output wire rx_busy,   // Reception busy flag
    output wire rx_error,  // Reception error flag
    output wire tx_done,   // Transmission done flag
    output wire tx_busy,    // Transmission busy flag
	 input wire check,
	 output wire [7:0] rx_data_rr
);

    reg [7:0] tx_data; // Data to transmit
	 reg [7:0] rx_data_r;
	 assign rx_data_rr = rx_data_r;
        
    parameter CLOCK_RATE = 100000000; // 100 MHz
    parameter BAUD_RATE = 9600;
    reg start_tx;   // Start signal for transmitter

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
        .start(start_tx),
        .in(tx_data),
        .out(tx_out),
        .done(tx_done),
        .busy(tx_busy)
    );

    wire rx_done_w;

    // Instantiate UART Receiver
    Uart8Receiver uart_rx (
        .clk(baud_clk_rx),
        .en(!reset),
        .in(rx_in),
        .out(rx_data),
        .done(rx_done_w),
        .busy(rx_busy),
        .err(rx_error)
    );

    reg start; // Matrix Multiplication Start
    reg [71:0] A_flat;
    reg [71:0] B_flat;
    wire [71:0] C_flat;
    wire m_done;
    reg m_done_r;

    reg [3:0] counter;

    reg [7:0] addr_memory[0:8]; // Memory to hold start and end addresses

    initial begin
        counter <= 4'd0;
        start_tx = 1'b0;
    end

    MatrixMultiplication mm(
        .clk(clk),
        .reset(reset),
        .start(start),
        .A_flat(A_flat),  // Flattened 3x3 matrix A (9 elements × 8 bits)
        .B_flat(B_flat),  // Flattened 3x3 matrix B (9 elements × 8 bits)
        .C_flat(C_flat),  // Flattened resulting 3x3 matrix C
        .done(m_done)
    );

    reg [2:0] state, next_state;
    localparam 
        idle = 3'b000,
        rece_A = 3'b001,
        rece_B = 3'b010,
        mult = 3'b011,
        send_res = 3'b100,
		  check_A = 3'b101,
		  check_B = 3'b110,
		  check_result= 3'b111;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= idle;
            // Initialize address memory for matrix slicing
            addr_memory[0] <= 0;  // Start index for first element
            addr_memory[1] <= 8;  // Start index for second element
            addr_memory[2] <= 16; // Continue for all elements...
            addr_memory[3] <= 24;
            addr_memory[4] <= 32;
            addr_memory[5] <= 40;
            addr_memory[6] <= 48;
            addr_memory[7] <= 56;
            addr_memory[8] <= 64; // End index for last element
        end else begin
            state <= next_state;
        end
    end
	 
	 wire check_r;
	 
	 level_det lt(.clk(clk), .in(check), .pulse(check_r));
	 
	 

    always @(posedge clk) begin
        case (state)
            idle: begin
                if (!reset) begin
                    next_state <= rece_A;
                    states <= 1;
                end else begin
                    next_state <= idle;
                end
            end
            rece_A: begin
                states <= 2;
                if (!rx_done) begin
                    rx_done <= rx_done_w;
                end
                if (rx_done) begin
					  if (counter == 4'd8) begin
                        counter <= 4'd0;
                        next_state <= check_A;
                    end
						  else begin
                    A_flat[addr_memory[counter] +: 8] <= rx_data; // Use address memory
                    counter <= counter + 1'b1;
                    rx_done <= 1'b0;
						  end
                   
                end
            end
				
				check_A: begin
				
				if (check_r) begin
				if (counter == 4'd8) begin
                        counter <= 4'd0;
                        next_state <= rece_B;
                    end
						  else begin
					rx_data_r <=  A_flat[addr_memory[counter] +: 8];
					counter <= counter + 1'b1;
                    rx_done <= 1'b0;
                  end  
				end
				end

            rece_B: begin
                states <= 4;
                if (!rx_done) begin
                    rx_done <= rx_done_w;
                end
                if (rx_done) begin
					 if (counter == 4'd8) begin
                        counter <= 4'd0;
                        next_state <= check_B;
                    end
						  else begin
                    B_flat[addr_memory[counter] +: 8] <= rx_data; // Use address memory
                    counter <= counter + 1'b1;
                    rx_done <= 1'b0;
                    end
                end
            end
				
				check_B: begin		
				if (check_r) begin
				 if (counter == 4'd8) begin
                        counter <= 4'd0;
                        next_state <= mult;
                    end
						  else begin
					rx_data_r <=  B_flat[addr_memory[counter] +: 8];
					counter <= counter + 1'b1;
                    rx_done <= 1'b0;
                   end
				end
				end

            mult: begin
                states <= 8;
                m_done_r <= m_done;
                if (!m_done) begin
                    start <= 1'b1;
                end
                if (m_done_r) begin
                    next_state <= check_result;
                    counter <= 4'd0;
                    m_done_r <= 1'b1;
                end
            end
				
				check_result: begin
				
				if (check_r) begin
				 if (counter == 4'd8) begin
                        counter <= 4'd0;
                        next_state <= send_res;
                    end
						  else begin
					rx_data_r <=  C_flat[addr_memory[counter] +: 8];
					counter <= counter + 1'b1;
                    rx_done <= 1'b0;
                   end
				end
				end

            send_res: begin
                states <= 16;
                if (m_done_r) begin
                    m_done_r <= 1'b0;
                    counter <= 4'd0;
                    start_tx <= 1'b1;
                end
                if (tx_done) begin
                    counter <= counter + 1'b1;
                    if (counter == 8) begin
                        next_state <= idle;
                        start_tx <= 1'b0;
                    end
                end
                if (!tx_busy && start_tx) begin
                    tx_data <= C_flat[addr_memory[counter] +: 8]; // Use address memory
                end
            end
        endcase
    end

endmodule
