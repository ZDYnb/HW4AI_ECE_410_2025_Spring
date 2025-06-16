module layernorm_top #(
    parameter N = 4,
    parameter DW = 16
)(
    input  logic signed [DW-1:0] x     [N],
    output logic signed [DW-1:0] norm_x[N]
);

    // Intermediate signals
    logic signed [DW-1:0] mean;
    logic signed [DW-1:0] variance;
    logic signed [DW-1:0] stddev;

    // Step 1: Compute Mean
    mean_calc #(.N(N), .DW(DW)) mean_inst (
        .x(x),
        .mean(mean)
    );

    // Step 2: Compute Variance
    variance_calc #(.N(N), .DW(DW)) var_inst (
        .x(x),
        .mean(mean),
        .variance(variance)
    );

    // Step 3: Compute Stddev = sqrt(variance)
    sqrt_lut sqrt_inst (
        .in_q88(variance),
        .out_q88(stddev)
    );

    // Step 4: Normalize
    normalize #(.N(N), .DW(DW)) norm_inst (
        .x(x),
        .mean(mean),
        .stddev(stddev),
        .norm_x(norm_x)
    );

endmodule
