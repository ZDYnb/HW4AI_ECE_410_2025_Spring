module variance_calc #(
    parameter N = 4,
    parameter DW = 16  // Q8.8
)(
    input  logic signed [DW-1:0] x [N],
    input  logic signed [DW-1:0] mean,
    output logic signed [DW-1:0] variance  // Q8.8 output
);

    logic signed [DW:0] diff;               // Q8.8 diff with safe subtract
    logic signed [2*DW-1:0] diff_sq;        // Q16.16
    logic signed [2*DW-1:0] sum;            // 32-bit sum

    // verilator lint_off UNUSEDSIGNAL
    logic signed [2*DW-1:0] avg;            // 32-bit average
    // verilator lint_on UNUSEDSIGNAL

    always_comb begin
        sum = 0;

        for (int i = 0; i < N; i++) begin
            diff = x[i] - mean;
            diff_sq = diff * diff;
            sum += diff_sq;
        end

        // Divide by 4 and assign top 16 bits
        avg = sum >>> 2;
        variance = avg[23:8];  // Q8.8 output
    end

endmodule
