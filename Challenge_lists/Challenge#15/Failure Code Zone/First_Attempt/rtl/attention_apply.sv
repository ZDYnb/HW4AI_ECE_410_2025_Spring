module attention_apply #(
    parameter N = 4,
    parameter DW = 16  // Q8.8
)(
    input  logic signed [DW-1:0] weights[N],  // softmax output
    input  logic signed [DW-1:0] v[N],        // value vector
    output logic signed [DW-1:0] out          // weighted sum result
);

    logic signed [2*DW-1:0] mul[N];           // Q16.16 products
    logic signed [2*DW+2:0] sum;              // Accumulator (enough headroom)

    always_comb begin
        sum = 0;
        for (int i = 0; i < N; i++) begin
            mul[i] = weights[i] * v[i];       // Q8.8 × Q8.8 = Q16.16
            sum += mul[i];
        end
        out = sum[23:8];  // Q16.16 → Q8.8 (truncation)
    end

endmodule
