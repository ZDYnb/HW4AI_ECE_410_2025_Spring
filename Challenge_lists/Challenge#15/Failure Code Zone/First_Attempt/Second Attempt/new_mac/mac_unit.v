// ===========================================
// MAC Unit - Multiply-Accumulate Core (Final Revised for Systolic Array)
// ===========================================
`timescale 1ns/1ps
module mac_unit #(
    parameter DATA_WIDTH = 16,      // Input data width (S5.10)
    parameter WEIGHT_WIDTH = 8,     // Weight width (S1.6)
    parameter ACCUM_WIDTH = 32      // Accumulator width (e.g., S15.16 for 32-bit)
)(
    input                           clk,
    input                           rst_n,
    input                           enable_mac,    // MAC specific enable
    input                           clear_accum,   // Clear accumulator input
    input  [DATA_WIDTH-1:0]         data_in,
    input  [WEIGHT_WIDTH-1:0]       weight_in,
    
    output [ACCUM_WIDTH-1:0]        accum_out,
    output                          accum_valid_out // Indicates accum_out is valid
);
    // Internal Signals
    wire signed [DATA_WIDTH-1:0]                data_signed;
    wire signed [WEIGHT_WIDTH-1:0]              weight_signed;
    
    // Direct full-width multiplication result to avoid intermediate truncation issues
    // Extend data_in and weight_in to ACCUM_WIDTH before multiplication
    wire signed [ACCUM_WIDTH-1:0]               mult_result_full; 
    
    reg  signed [ACCUM_WIDTH-1:0]               accum_reg;
    reg                                         accum_valid_reg; // Internal valid for accumulator

    // Arithmetic Logic
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);

    // Multiply operation:
    // Explicitly extend data_in and weight_in to ACCUM_WIDTH before multiplication.
    // This guarantees the multiplication result is calculated at the full ACCUM_WIDTH,
    // preventing any intermediate truncation errors regardless of Verilog's implicit rules.
    assign mult_result_full = ($signed({{(ACCUM_WIDTH-DATA_WIDTH){data_signed[DATA_WIDTH-1]}}, data_signed})) * ($signed({{(ACCUM_WIDTH-WEIGHT_WIDTH){weight_signed[WEIGHT_WIDTH-1]}}, weight_signed}));

    // Accumulator logic
    // accum_reg updates when enable_mac is high.
    // accum_valid_reg goes high when enable_mac is high.
    // accum_valid_reg goes low when enable_mac is low.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg       <= {ACCUM_WIDTH{1'b0}};
            accum_valid_reg <= 1'b0;
        end else if (enable_mac) begin // Only update accum_reg when MAC is enabled
            if (clear_accum) begin
                accum_reg <= mult_result_full; // Clear and load with current product
            end else begin
                accum_reg <= accum_reg + mult_result_full; // Accumulate
            end
            accum_valid_reg <= 1'b1; // Accumulator output becomes valid in this cycle.
                                     // It stays valid as long as enable_mac is high.
        end else begin
            // If enable_mac is low, accum_reg holds its value.
            // But accum_valid_reg must go low to indicate no new valid output.
            accum_valid_reg <= 1'b0; 
        end
    end
    
    // Output Assignment
    assign accum_out = accum_reg;
    assign accum_valid_out = accum_valid_reg;

endmodule
