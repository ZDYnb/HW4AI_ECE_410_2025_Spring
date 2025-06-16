// =============================================================================
// GELU Cubic Calculator Sub-block (x^3 computation)
// =============================================================================
// Purpose: Compute x^3 for the GELU polynomial approximation
// Input: 24-bit fixed-point number (16 fractional bits)
// Output: 24-bit fixed-point x^3 result
// Method: Two-stage multiplication (x * x, then result * x)
// =============================================================================

module gelu_cubic_calculator #(
    parameter DATA_WIDTH = 24,        // Total data width
    parameter FRAC_BITS = 16          // Number of fractional bits
) (
    input wire clk,                   // Clock
    input wire rst_n,                 // Active-low reset
    input wire [DATA_WIDTH-1:0] x_in, // Input value x
    input wire valid_in,              // Input valid
    output reg [DATA_WIDTH-1:0] x_cubed_out, // Output x^3
    output reg valid_out,             // Output valid
    output reg overflow               // Overflow flag
);

// =============================================================================
// Internal Signals
// =============================================================================

// Intermediate multiplication results (need double width for multiplication)
reg [2*DATA_WIDTH-1:0] x_squared_full;    // Full-width x^2 result
reg [2*DATA_WIDTH-1:0] x_cubed_full;      // Full-width x^3 result

// Pipeline registers for 2-stage operation
reg [DATA_WIDTH-1:0] x_reg;               // Registered input
reg [DATA_WIDTH-1:0] x_squared;           // x^2 result (truncated)
reg valid_stage1;                         // Valid for stage 1
reg valid_stage2;                         // Valid for stage 2

// Overflow detection signals
wire overflow_stage1;                     // Overflow in x^2 calculation
wire overflow_stage2;                     // Overflow in x^3 calculation

// =============================================================================
// Stage 1: Calculate x^2
// =============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_reg <= 0;
        x_squared_full <= 0;
        x_squared <= 0;
        valid_stage1 <= 0;
    end else begin
        x_reg <= x_in;
        valid_stage1 <= valid_in;
        
        // Multiply x * x (signed multiplication)
        x_squared_full <= $signed(x_in) * $signed(x_in);
        
        // Truncate back to original width, adjusting for fractional bits
        // When multiplying two Q8.16 numbers, result is Q16.32
        // We need to shift right by FRAC_BITS to get back to Q8.16
        x_squared <= x_squared_full[2*FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];
    end
end

// Overflow detection for stage 1
// Check if significant bits are lost in truncation
assign overflow_stage1 = valid_stage1 && 
    (x_squared_full[2*DATA_WIDTH-1 : DATA_WIDTH + FRAC_BITS] != 0) &&
    (x_squared_full[2*DATA_WIDTH-1 : DATA_WIDTH + FRAC_BITS] != {(DATA_WIDTH-FRAC_BITS){1'b1}});

// =============================================================================
// Stage 2: Calculate x^3 = x^2 * x
// =============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_cubed_full <= 0;
        x_cubed_out <= 0;
        valid_stage2 <= 0;
    end else begin
        valid_stage2 <= valid_stage1;
        
        // Multiply x_squared * x_reg (signed multiplication)
        x_cubed_full <= $signed(x_squared) * $signed(x_reg);
        
        // Truncate back to original width
        x_cubed_out <= x_cubed_full[2*FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];
    end
end

// Overflow detection for stage 2
assign overflow_stage2 = valid_stage2 && 
    (x_cubed_full[2*DATA_WIDTH-1 : DATA_WIDTH + FRAC_BITS] != 0) &&
    (x_cubed_full[2*DATA_WIDTH-1 : DATA_WIDTH + FRAC_BITS] != {(DATA_WIDTH-FRAC_BITS){1'b1}});

// =============================================================================
// Output Control
// =============================================================================

// Output valid signal (2 cycles after input)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 0;
    end else begin
        valid_out <= valid_stage2;
    end
end

// Overflow flag (combine both stages)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        overflow <= 0;
    end else begin
        overflow <= overflow_stage1 || overflow_stage2;
    end
end

endmodule
