module MatrixMultiplication (
    input clk,
    input reset,
    input start,
    input [71:0] A_flat,  // Flattened 3x3 matrix A (9 elements × 8 bits)
    input [71:0] B_flat,  // Flattened 3x3 matrix B (9 elements × 8 bits)
    output reg [71:0] C_flat, // Flattened resulting 3x3 matrix C
    output reg done
);
    // Changed to 8 bits to match input size
    reg [7:0] A [2:0][2:0];
    reg [7:0] B [2:0][2:0];
    reg [7:0] C [2:0][2:0];
    
    reg [1:0] i, j, k;
    reg [15:0] sum; // Made wider to handle multiplication result
    reg [1:0] state;
    
    localparam IDLE = 0,
               MULT = 1,
               DONE = 2;

    // Unpack flattened inputs into 2D arrays
    integer m, n;
    always @(*) begin
        for (m = 0; m < 3; m = m + 1) begin
            for (n = 0; n < 3; n = n + 1) begin
                // Corrected bit slicing: 8 bits per element
                A[m][n] = A_flat[(m * 3 + n) * 8 +: 8];
                B[m][n] = B_flat[(m * 3 + n) * 8 +: 8];
            end
        end
    end

    // Pack 2D array result into flattened output
    always @(*) begin
        for (m = 0; m < 3; m = m + 1) begin
            for (n = 0; n < 3; n = n + 1) begin
                // Corrected bit slicing: 8 bits per element
                C_flat[(m * 3 + n) * 8 +: 8] = C[m][n];
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
            sum <= 0;
            // Initialize result matrix
            for (m = 0; m < 3; m = m + 1) begin
                for (n = 0; n < 3; n = n + 1) begin
                    C[m][n] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= MULT;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        sum <= 0;
                        done <= 0;
                    end
                end

                MULT: begin
                    if (k == 0) begin
                        // Initialize sum for new element calculation
                        sum <= A[i][k] * B[k][j];
                        k <= k + 1;
                    end
                    else if (k < 3) begin
                        // Accumulate products
                        sum <= sum + (A[i][k] * B[k][j]);
                        k <= k + 1;
                    end else begin
                        // Store result with modulo 256 to keep within 8 bits
                        C[i][j] <= sum[7:0];  // Take lower 8 bits
                        sum <= 0;
                        k <= 0;
                        
                        if (j < 2) begin
                            j <= j + 1;
                        end else if (i < 2) begin
                            j <= 0;
                            i <= i + 1;
                        end else begin
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
