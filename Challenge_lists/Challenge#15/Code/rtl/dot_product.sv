module dot_product #(
    parameter N = 4,
    parameter WIDTH = 16
)(
    input  logic signed [WIDTH-1:0] a [N],
    input  logic signed [WIDTH-1:0] b [N],
    output logic signed [WIDTH-1:0] result
);

    integer i;
    logic signed [WIDTH*2-1:0] temp_sum;  // prevent overflow

    always_comb begin
        temp_sum = 0;
        for (i = 0; i < N; i++) begin
            temp_sum += a[i] * b[i];
        end
        result = temp_sum[WIDTH-1:0]; // Truncate if needed
    end

endmodule

