module mac_unit #(
    parameter DATA_WIDTH = 8
)(
    input  logic                   clock,
    input  logic                   reset,
    input  logic                   enable,
    input  logic [DATA_WIDTH-1:0]  a,
    input  logic [DATA_WIDTH-1:0]  b,
    output logic [DATA_WIDTH-1:0]  result,
    output logic                   overflow
);

    // Double width for multiplication and accumulation to prevent overflow
    logic [2*DATA_WIDTH-1:0] mult_result_reg1;
    logic [2*DATA_WIDTH-1:0] acc_value;
    logic overflow_internal;

    // Pipeline stage 1: Multiplication
    always_ff @(posedge clock) begin
        if (!reset)
            mult_result_reg1 <= '0;
        else if (enable)
            mult_result_reg1 <= a * b;
    end

    // Pipeline stage 2: Accumulation
    always_ff @(posedge clock) begin
        if (!reset) begin
            acc_value <= '0;
            overflow_internal <= 1'b0;
        end else if (enable) begin
            acc_value <= acc_value + mult_result_reg1;
            // Check for overflow
            overflow_internal <= (acc_value + mult_result_reg1) > {(2*DATA_WIDTH){1'b1}};
        end
    end

    // Output stage with truncation
    assign result = acc_value[DATA_WIDTH-1:0];
    assign overflow = overflow_internal;

endmodule