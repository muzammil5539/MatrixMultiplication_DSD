module uart_receiver #(
    parameter CLKS_PER_BIT = 868 // 100MHz/115200 baud rate
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rx,
    output logic        rx_done,
    output logic [7:0]  rx_data
);

    // State encodings using localparam
    localparam [1:0] 
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg [1:0] state, next_state;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_data_reg;
    logic rx_sync, rx_meta;

    // ROM for state transitions (16 possible transitions)
    reg [1:0] state_rom [0:15];
    reg [3:0] rom_addr;

    // Initialize state ROM
    initial begin
        // Default to IDLE state
        for (int i = 0; i < 16; i = i + 1)
            state_rom[i] = IDLE;
        
        // Program specific transitions
        state_rom[{IDLE,  2'b01}] = START;  // IDLE to START when !rx_sync
        state_rom[{START, 2'b01}] = DATA;   // START to DATA at middle of bit
        state_rom[{DATA,  2'b11}] = STOP;   // DATA to STOP when count done & last bit
        state_rom[{STOP,  2'b01}] = IDLE;   // STOP to IDLE when count done
    end

    // 2-FF Synchronizer for rx input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ROM-based state transition logic
    always @(*) begin
        case(state)
            IDLE:  rom_addr = {state, 1'b0, !rx_sync};
            START: rom_addr = {state, 1'b0, (clk_count == (CLKS_PER_BIT-1)>>1)};
            DATA:  rom_addr = {state, (bit_index == 7), (clk_count == CLKS_PER_BIT-1)};
            STOP:  rom_addr = {state, 1'b0, (clk_count == CLKS_PER_BIT-1)};
        endcase
        next_state = state_rom[rom_addr];
    end

    // Output and counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_count <= '0;
            bit_index <= '0;
            rx_done <= 1'b0;
            rx_data_reg <= '0;
            rx_data <= '0;
        end else begin
            case (state)
                IDLE: begin
                    clk_count <= '0;
                    bit_index <= '0;
                    rx_done <= 1'b0;
                end
                START: begin
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= '0;
                end
                DATA: begin
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= '0;
                        bit_index <= bit_index + 1;
                        rx_data_reg[bit_index] <= rx_sync;
                    end
                end
                STOP: begin
                    if (clk_count < CLKS_PER_BIT-1)
                        clk_count <= clk_count + 1;
                    else begin
                        rx_done <= 1'b1;
                        rx_data <= rx_data_reg;
                    end
                end
            endcase
        end
    end

endmodule
