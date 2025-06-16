// variance_epsilon_adder_unit.v
// Adds a small epsilon to the variance.
module variance_epsilon_adder_unit #(
    parameter DATA_WIDTH      = 24,   // Should match variance_unit's output width
    parameter FRAC_BITS       = 20,   // Fractional bits for variance (e.g., S3.20)
    // Integer value of epsilon scaled by 2^FRAC_BITS
    // For epsilon = 1e-5 and FRAC_BITS = 20, EPSILON_INT_VAL = round(1e-5 * 2^20) = 11
    parameter EPSILON_INT_VAL = 11
) (
    input wire clk,
    input wire rst_n,

    input wire signed [DATA_WIDTH-1:0]  variance_in,       // From variance_unit
    input wire                          variance_valid_in,

    output reg signed [DATA_WIDTH-1:0]  var_plus_eps_out,  // To sqrt_unit
    output reg                          var_plus_eps_valid_out
);

    // Epsilon value in fixed-point format
    // For S3.20 (1s, 3i, 20f), epsilon (a small positive) will have 0 for integer part.
    // The EPSILON_INT_VAL (e.g., 11) represents the fractional part's scaled integer.
    wire signed [DATA_WIDTH-1:0] epsilon_fixed_point_w;
    assign epsilon_fixed_point_w = EPSILON_INT_VAL; // Directly assign integer val; Verilog handles sizing.
                                                  // For 24'd11, it's 0...01011.
                                                  // This correctly represents a small positive in S3.20.

    // Combinational sum
    wire signed [DATA_WIDTH-1:0] sum_comb_w;
    // Variance_in is S3.20 (always positive). Epsilon is tiny positive.
    // Sum should still fit S3.20 unless variance is extremely close to max positive value.
    // For safety, could use DATA_WIDTH+1 for sum_comb_w and then saturate.
    // But given epsilon is tiny, direct sum is usually fine.
    assign sum_comb_w = variance_in + epsilon_fixed_point_w;

    // Register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            var_plus_eps_out <= 0;
            var_plus_eps_valid_out <= 1'b0;
        end else begin
            var_plus_eps_valid_out <= variance_valid_in; // Pass valid signal (delayed by 1 cycle)
            if (variance_valid_in) begin
                var_plus_eps_out <= sum_comb_w;
                // Add $display here for debugging if needed
                // $display("[%0t] variance_epsilon_adder: var_in=%d, eps_fp=%d -> sum_comb=%d. Valid out next cycle.",
                //          $time, variance_in, epsilon_fixed_point_w, sum_comb_w);
            end
        end
    end

endmodule
