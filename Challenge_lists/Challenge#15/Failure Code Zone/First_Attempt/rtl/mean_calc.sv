module mean_calc #(
    parameter N = 4,
    parameter DW = 16  // Q8.8 format: 8 int + 8 frac
)(
    input  logic signed [DW-1:0] x [N],
    output logic signed [DW-1:0] mean
);

    // Sum needs to be wide enough: DW + ceil(log2(N)) + 1 for sign
    logic signed [DW+3:0] sum;

    always_comb begin
        sum = 0;
        for (int i = 0; i < N; i++) begin
            sum += {{3{x[i][DW-1]}}, x[i]}; // Explicit sign extension to match sum width
        end
        mean = sum[DW+1:2]; // Truncate safely: take [18:2] from 19-bit sum >>> 2
    end

endmodule

