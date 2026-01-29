module level_det(input clk, input in, output reg pulse);
    reg last_state;

    always @(posedge clk) begin
        pulse <= in & ~last_state;
        last_state <= in;
    end
endmodule
