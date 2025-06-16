module softmax #(
    parameter N = 4,
    parameter DW = 16  // Q8.8
)(
    input  logic signed [DW-1:0] x[N],
    output logic signed [DW-1:0] y[N]
);

    // Step 1: compute exp(x[i]) using exp_taylor
    logic signed [DW-1:0] exp_out[N];

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : exp_gen
            exp_taylor exp_inst (
                .x_q88(x[i]),
                .y_q88(exp_out[i])
            );
        end
    endgenerate

    // Step 2: sum all exp values
    logic signed [DW+2:0] sum_exp;
    always_comb begin
        sum_exp = 0;
        for (int i = 0; i < N; i++) begin
            sum_exp += exp_out[i];
        end
    end

    // Step 5: normalize each y[i] = (exp_out[i] << 8) / sum_exp
    // Since Q8.8 × 256 = Q16.8 → division will bring it back to Q8.8
    always_comb begin
        for (int i = 0; i < N; i++) begin
            if (sum_exp != 0)
                y[i] = (exp_out[i] <<< 8) / sum_exp;  // output in Q8.8
            else
                y[i] = 0;
        end
    end

endmodule
