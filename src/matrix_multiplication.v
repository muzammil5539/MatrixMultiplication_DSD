module matrix_multiplication #(
    parameter DATA_WIDTH = 8,
    parameter MATRIX_SIZE_MIN = 3,
    parameter MATRIX_SIZE_MAX = 10
)(
    input  logic                   clock,
    input  logic                   reset,
    input  logic                   enable,
    input  logic [3:0]             matrix_size, // 4-bit to support sizes from 3 to 10
    input  logic [DATA_WIDTH-1:0]  matrix_a [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0],
    input  logic [DATA_WIDTH-1:0]  matrix_b [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0],
    output logic [DATA_WIDTH-1:0]  result_matrix [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0],
    output logic                   overflow
);

    logic [DATA_WIDTH-1:0] mac_results [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0];
    logic mac_overflows [MATRIX_SIZE_MAX*MATRIX_SIZE_MAX-1:0];
    logic overflow_internal;

    // Instantiate MAC units for each element in the result matrix
    genvar i, j, k;
    generate
        for (i = 0; i < MATRIX_SIZE_MAX; i = i + 1) begin : row
            for (j = 0; j < MATRIX_SIZE_MAX; j = j + 1) begin : col
                logic [DATA_WIDTH-1:0] sum;
                assign sum = '0;
                for (k = 0; k < MATRIX_SIZE_MAX; k = k + 1) begin : mac
                    if (i < matrix_size && j < matrix_size && k < matrix_size) begin
                        mac_unit #(
                            .DATA_WIDTH(DATA_WIDTH)
                        ) mac_inst (
                            .clock(clock),
                            .reset(reset),
                            .enable(enable),
                            .a(matrix_a[i*MATRIX_SIZE_MAX + k]),
                            .b(matrix_b[k*MATRIX_SIZE_MAX + j]),
                            .result(mac_results[i*MATRIX_SIZE_MAX + j]),
                            .overflow(mac_overflows[i*MATRIX_SIZE_MAX + j])
                        );
                        assign sum = sum + mac_results[i*MATRIX_SIZE_MAX + j];
                    end
                end
                assign result_matrix[i*MATRIX_SIZE_MAX + j] = sum;
            end
        end
    endgenerate

    // Check for overflow in any MAC unit
    always_comb begin
        overflow_internal = 1'b0;
        for (i = 0; i < MATRIX_SIZE_MAX; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE_MAX; j = j + 1) begin
                if (mac_overflows[i*MATRIX_SIZE_MAX + j]) begin
                    overflow_internal = 1'b1;
                end
            end
        end
    end

    assign overflow = overflow_internal;

endmodule
