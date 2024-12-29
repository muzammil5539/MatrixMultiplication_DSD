module tb_MatrixMultiplication;
    reg clk;
    reg reset;
    reg start;
    reg [71:0] A_flat;
    reg [71:0] B_flat;
    wire [71:0] C_flat;
    wire done;
    
    // Instantiate the MatrixMultiplication module
    MatrixMultiplication uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A_flat(A_flat),
        .B_flat(B_flat),
        .C_flat(C_flat),
        .done(done)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start = 0;
        A_flat = 72'b0;
        B_flat = 72'b0;
        
        // Apply reset
        #10 reset = 0;
        
        // Load matrices A and B
        A_flat = {9'd1, 9'd2, 9'd3, 9'd4, 9'd5, 9'd6, 9'd7, 9'd8, 9'd9};
        B_flat = {9'd9, 9'd8, 9'd7, 9'd6, 9'd5, 9'd4, 9'd3, 9'd2, 9'd1};
        
        // Start multiplication
        #10 start = 1;
        #10 start = 0;
        
        // Wait for done signal
        wait (done);
        
        // Check the result
        $display("Matrix C_flat:");
        $display("%d %d %d", C_flat[71:64], C_flat[63:56], C_flat[55:48]);
        $display("%d %d %d", C_flat[47:40], C_flat[39:32], C_flat[31:24]);
        $display("%d %d %d", C_flat[23:16], C_flat[15:8],  C_flat[7:0]);
        
        // End simulation
        #10 $finish;
    end
endmodule
