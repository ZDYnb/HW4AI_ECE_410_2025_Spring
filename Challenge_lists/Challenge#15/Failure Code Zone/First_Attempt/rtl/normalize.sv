module normalize #(
    parameter N = 4,
    parameter DW = 16  // Q8.8
)(
    input  logic signed [DW-1:0] x     [N],     // Input vector
    input  logic signed [DW-1:0] mean,         // Mean (Q8.8)
    input  logic signed [DW-1:0] stddev,       // Stddev (Q8.8)
    output logic signed [DW-1:0] norm_x [N]    // Normalized output (Q8.8)
);

    logic signed [DW:0] diff;                  // Q8.8 with safe subtraction
    logic signed [2*DW-1:0] scaled_diff;       // Q16.8 (after << 8)
    // verilator lint_off UNUSEDSIGNAL
    logic signed [2*DW-1:0] result;
    // verilator lint_on UNUSEDSIGNAL   

    always_comb begin
        for (int i = 0; i < N; i++) begin
            diff = x[i] - mean;                    // Step 1: Q8.8 subtraction
            // verilator lint_off WIDTHEXPAND
            scaled_diff = diff <<< 8;  // Add inline suppression if needed
            // verilator lint_on WIDTHEXPAND
            // verilator lint_off WIDTHEXPAND
            result = scaled_diff / stddev;
            // verilator lint_on WIDTHEXPAND

            norm_x[i] = result[15:0];              // Step 4: truncate to Q8.8
        end
    end

endmodule
