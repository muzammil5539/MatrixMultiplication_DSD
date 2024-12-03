module uart_top #(
    parameter DATA_WIDTH = 8,
    parameter MATRIX_SIZE_MIN = 3,
    parameter MATRIX_SIZE_MAX = 10,
    parameter CLK_FREQ = 100_000_000
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [1:0]            baud_sel,
    input  logic                   rx,
    output logic                   tx,
    input  logic [3:0]            matrix_size
);

    // Internal signals
    logic tx_baud_clk, rx_baud_clk;
    logic tx_start, tx_done, rx_done;
    logic [7:0] tx_data, rx_data;
    
    // Matrix signals
    logic [DATA_WIDTH-1:0] matrix_a [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0];
    logic [DATA_WIDTH-1:0] matrix_b [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0];
    logic [DATA_WIDTH-1:0] result_matrix [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0];
    logic matrix_overflow;
    logic matrix_enable;

    // State machine for data control
    localparam [2:0]
        IDLE            = 3'b000,
        RECEIVE_MATRIX_A = 3'b001,
        RECEIVE_MATRIX_B = 3'b010,
        MULTIPLY        = 3'b011,
        TRANSMIT_RESULT = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;
    reg [$clog2(MATRIX_SIZE_MAX*MATRIX_SIZE_MAX):0] data_counter;
    
    // Instruction ROM for state transitions
    reg [2:0] state_rom [0:31]; // 32 possible state transitions
    reg [4:0] rom_addr;

    // Initialize state ROM
    initial begin
        // Default transitions
        state_rom[0] = IDLE;            // Reset state
        state_rom[1] = RECEIVE_MATRIX_A; // From IDLE on rx_done
        state_rom[2] = RECEIVE_MATRIX_B; // From RECEIVE_MATRIX_A when done
        state_rom[3] = MULTIPLY;         // From RECEIVE_MATRIX_B when done
        state_rom[4] = TRANSMIT_RESULT;  // From MULTIPLY when done
        // ...add more state transitions as needed
    end

    // Baud rate generator
    baud_rate_generator #(
        .CLK_FREQ(CLK_FREQ)
    ) baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_sel(baud_sel),
        .tx_baud_clk(tx_baud_clk),
        .rx_baud_clk(rx_baud_clk)
    );

    // UART modules
    uart_transmitter tx_inst (
        .clk(tx_baud_clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx(tx)
    );

    uart_receiver rx_inst (
        .clk(rx_baud_clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    // Matrix multiplication module
    matrix_multiplication #(
        .DATA_WIDTH(DATA_WIDTH),
        .MATRIX_SIZE_MIN(MATRIX_SIZE_MIN),
        .MATRIX_SIZE_MAX(MATRIX_SIZE_MAX)
    ) matrix_mult (
        .clock(clk),
        .reset(rst_n),
        .enable(matrix_enable),
        .matrix_size(matrix_size),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .result_matrix(result_matrix),
        .overflow(matrix_overflow)
    );

    // Control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_counter <= '0;
            matrix_enable <= 1'b0;
            tx_start <= 1'b0;
            // Reset matrices
            // ...existing code...
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (rx_done) begin
                        state <= RECEIVE_MATRIX_A;
                        data_counter <= '0;
                    end
                end

                RECEIVE_MATRIX_A: begin
                    if (rx_done) begin
                        matrix_a[data_counter] <= rx_data;
                        if (data_counter == matrix_size * matrix_size - 1) begin
                            state <= RECEIVE_MATRIX_B;
                            data_counter <= '0;
                        end else begin
                            data_counter <= data_counter + 1;
                        end
                    end
                end

                RECEIVE_MATRIX_B: begin
                    if (rx_done) begin
                        matrix_b[data_counter] <= rx_data;
                        if (data_counter == matrix_size * matrix_size - 1) begin
                            state <= MULTIPLY;
                            data_counter <= '0;
                            matrix_enable <= 1'b1;
                        end else begin
                            data_counter <= data_counter + 1;
                        end
                    end
                end

                MULTIPLY: begin
                    matrix_enable <= 1'b0;
                    state <= TRANSMIT_RESULT;
                end

                TRANSMIT_RESULT: begin
                    if (!tx_start && !tx_done) begin
                        tx_data <= result_matrix[data_counter];
                        tx_start <= 1'b1;
                    end else if (tx_done) begin
                        tx_start <= 1'b0;
                        if (data_counter == matrix_size * matrix_size - 1) begin
                            state <= IDLE;
                        end else begin
                            data_counter <= data_counter + 1;
                        end
                    end
                end
            endcase
        end
    end

    // State transition logic using ROM
    always @(*) begin
        case(state)
            IDLE: rom_addr = rx_done ? 5'd1 : 5'd0;
            RECEIVE_MATRIX_A: rom_addr = (data_counter == matrix_size * matrix_size - 1) ? 5'd2 : 5'd1;
            RECEIVE_MATRIX_B: rom_addr = (data_counter == matrix_size * matrix_size - 1) ? 5'd3 : 5'd2;
            MULTIPLY: rom_addr = 5'd4;
            TRANSMIT_RESULT: rom_addr = (data_counter == matrix_size * matrix_size - 1) ? 5'd0 : 5'd4;
            default: rom_addr = 5'd0;
        endcase
        next_state = state_rom[rom_addr];
    end

endmodule
