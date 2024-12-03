module baud_rate_generator #(
    parameter CLK_FREQ = 100_000_000  // 100 MHz
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  baud_sel,     // For different baud rates
    output logic        tx_baud_clk,   // Transmitter clock
    output logic        rx_baud_clk    // Receiver clock (8x faster)
);

    // Baud rate divider values for common rates
    localparam BAUD_9600   = CLK_FREQ / (9600 * 8);
    localparam BAUD_19200  = CLK_FREQ / (19200 * 8);
    localparam BAUD_57600  = CLK_FREQ / (57600 * 8);
    localparam BAUD_115200 = CLK_FREQ / (115200 * 8);

    logic [$clog2(BAUD_9600)-1:0] counter;
    logic [$clog2(BAUD_9600)-1:0] baud_limit;
    logic [2:0] rx_div_counter;

    // Baud rate selection
    always_comb begin
        case(baud_sel)
            2'b00: baud_limit = BAUD_9600;
            2'b01: baud_limit = BAUD_19200;
            2'b10: baud_limit = BAUD_57600;
            2'b11: baud_limit = BAUD_115200;
        endcase
    end

    // Counter for baud rate generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            tx_baud_clk <= 1'b0;
        end else begin
            if (counter >= baud_limit - 1) begin
                counter <= '0;
                tx_baud_clk <= ~tx_baud_clk;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // Generate 8x faster clock for receiver
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_div_counter <= '0;
            rx_baud_clk <= 1'b0;
        end else begin
            if (rx_div_counter == 3'b111) begin
                rx_baud_clk <= ~rx_baud_clk;
            end
            rx_div_counter <= rx_div_counter + 1;
        end
    end

endmodule
