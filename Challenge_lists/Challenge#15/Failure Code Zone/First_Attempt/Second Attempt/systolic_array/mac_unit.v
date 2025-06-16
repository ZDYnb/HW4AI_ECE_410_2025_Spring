`timescale 1ns/1ps

// ===========================================
// MAC Unit (Original Naming, Modified for 24-bit Accum)
// ===========================================
module mac_unit_basic #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 24     // *** MODIFIED: Accumulator width is now 24 bits ***
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,

    input  [DATA_WIDTH-1:0]       data_in,    // Original name: Activation
    input  [WEIGHT_WIDTH-1:0]     weight_in,  // Original name: Weight

    output [ACCUM_WIDTH-1:0]      accum_out,  // Original name: Accumulator output
    output                        valid_out   // Original name: Indicates accum_out is valid
);

    localparam PRODUCT_WIDTH = DATA_WIDTH + WEIGHT_WIDTH; // Should be 24

    // Internal signals using original naming style where possible
    wire signed [DATA_WIDTH-1:0]      data_signed;
    wire signed [WEIGHT_WIDTH-1:0]    weight_signed;
    wire signed [PRODUCT_WIDTH-1:0]   mult_result;  // Product of data_in and weight_in
    
    reg signed [ACCUM_WIDTH-1:0]      accum_reg;    // The accumulator itself
    wire signed [ACCUM_WIDTH-1:0]     next_accum;   // Value to be loaded into accum_reg
    reg                               valid_out_reg;

    // Convert inputs to signed values for multiplication
    assign data_signed   = $signed(data_in);
    assign weight_signed = $signed(weight_in);

    // Multiplication
    assign mult_result   = data_signed * weight_signed; // Result is PRODUCT_WIDTH (24) bits

    // Accumulation logic
    // Sign-extend product to ACCUM_WIDTH before adding or assigning
    wire signed [ACCUM_WIDTH-1:0] product_extended;
    // Since PRODUCT_WIDTH is expected to be equal to ACCUM_WIDTH (both 24), 
    // direct assignment is fine, but explicit extension handles general cases.
    assign product_extended = $signed({{(ACCUM_WIDTH - PRODUCT_WIDTH){mult_result[PRODUCT_WIDTH-1]}}, mult_result});

    assign next_accum = clear_accum ? product_extended : (accum_reg + product_extended);

    // Register for accumulator and valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg     <= {ACCUM_WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end else if (enable) begin
            accum_reg     <= next_accum;
            valid_out_reg <= 1'b1;
        end else begin
            // accum_reg <= accum_reg; // Implicitly holds value if not enabled
            valid_out_reg <= 1'b0;      // If not enabled, output is not considered valid for this cycle
        end
    end

    // Outputs
    assign accum_out = accum_reg;
    assign valid_out = valid_out_reg;

endmodule
