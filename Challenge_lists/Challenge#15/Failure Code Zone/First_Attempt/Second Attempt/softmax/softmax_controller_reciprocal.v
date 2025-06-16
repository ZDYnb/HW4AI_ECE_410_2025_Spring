`timescale 1ns/1ps

module softmax_controller_reciprocal (
    input clk,
    input rst_n,
    input start,                    // Start processing
    input [1023:0] qk_input,       // 64×16 Q×K^T values (S5.10)
    output reg [1023:0] softmax_out, // 64×16 softmax results (S5.10)
    output reg valid_out            // Processing complete
);

// =========================================== 
// Internal signals
// ===========================================
reg [15:0] qk_values [63:0];       // Unpacked Q×K^T values
reg [15:0] exp_values [63:0];      // Exponential values
reg [15:0] softmax_results [63:0]; // Final softmax results

// Max finder signals
reg [1023:0] max_finder_input;
wire [15:0] max_value;
wire max_valid;

// EXP LUT signals  
reg [15:0] exp_input;
wire [15:0] exp_output;
wire exp_valid;

// Tree sum signals
reg [1023:0] tree_sum_input;
reg tree_start;
wire [23:0] sum_result;      // S13.10 format
wire sum_valid;

// Reciprocal unit signals
wire signed [23:0] reciprocal_input;
reg reciprocal_start;
wire signed [23:0] reciprocal_output;   // 2^14/sum format
wire reciprocal_valid;

// Control signals
reg [5:0] exp_counter;
reg [5:0] mult_counter;
integer i;

// FSM states
parameter IDLE = 4'b0000;
parameter FIND_MAX = 4'b0001;
parameter CALC_EXP = 4'b0010;
parameter WAIT_EXP = 4'b0011;
parameter SUM_EXP = 4'b0100;
parameter CALC_RECIPROCAL = 4'b0101;
parameter MULTIPLY = 4'b0110;
parameter DONE = 4'b0111;

reg [3:0] state;

// =========================================== 
// Unpack input
// ===========================================
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = qk_input[i*16 +: 16];
    end
end

// =========================================== 
// Pack output  
// ===========================================
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        softmax_out[i*16 +: 16] = softmax_results[i];
    end
end

// =========================================== 
// Module instantiations
// ===========================================

// Max finder (combinational only - no clk/rst/valid)
max_finder_64 max_finder (
    .data_in(max_finder_input),
    .max_out(max_value)
);

// EXP LUT (actual port names)
exp_lut_unit exp_lut (
    .clk(clk),
    .rst_n(rst_n),
    .x_in(exp_input),           // Actual port name
    .exp_out(exp_output),       // Actual port name
    .valid_out(exp_valid)       // Actual port name
);

// Tree sum accumulator
tree_sum_accumulator tree_sum (
    .clk(clk),
    .rst_n(rst_n),
    .start(tree_start),
    .exp_values_in(tree_sum_input),
    .sum_out(sum_result),
    .sum_valid(sum_valid)
);

// Reciprocal unit
reciprocal_unit #(
    .INPUT_X_WIDTH(24),
    .DIVISOR_WIDTH(24), 
    .QUOTIENT_WIDTH(24),
    .FINAL_OUT_WIDTH(24)
) reciprocal_calc (
    .clk(clk),
    .rst_n(rst_n),
    .X_in(reciprocal_input),
    .valid_in(reciprocal_start),
    .reciprocal_out(reciprocal_output),
    .valid_out(reciprocal_valid)
);

assign reciprocal_input = sum_result;

// =========================================== 
// Main FSM
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        valid_out <= 1'b0;
        exp_counter <= 6'b0;
        mult_counter <= 6'b0;
        tree_start <= 1'b0;
        reciprocal_start <= 1'b0;
        
        for (i = 0; i < 64; i = i + 1) begin
            exp_values[i] <= 16'b0;
            softmax_results[i] <= 16'b0;
        end
    end
    else begin
        case (state)
            IDLE: begin
                valid_out <= 1'b0;
                if (start) begin
                    state <= FIND_MAX;
                    max_finder_input <= qk_input;
                    // Max finder is combinational, proceed immediately
                    state <= CALC_EXP;
                    exp_counter <= 6'b0;
                end
            end
            
            FIND_MAX: begin
                // This state is now unused since max_finder is combinational
                state <= CALC_EXP;
                exp_counter <= 6'b0;
            end
            
            CALC_EXP: begin
                if (exp_counter < 64) begin
                    // Calculate exp(x_i - max) for each element
                    exp_input <= qk_values[exp_counter] - max_value;
                    state <= WAIT_EXP;
                end else begin
                    // All 64 exp values calculated, proceed to sum
                    state <= SUM_EXP;
                end
            end
            
            WAIT_EXP: begin
                if (exp_valid) begin
                    exp_values[exp_counter] <= exp_output;
                    exp_counter <= exp_counter + 1;
                    // Check if we've processed all 64 elements
                    if (exp_counter == 63) begin
                        state <= SUM_EXP;  // Go directly to SUM_EXP after last element
                    end else begin
                        state <= CALC_EXP;  // Continue with next element
                    end
                end
            end
            
            SUM_EXP: begin
                // Pack exp values for tree sum
                for (i = 0; i < 64; i = i + 1) begin
                    tree_sum_input[i*16 +: 16] <= exp_values[i];
                end
                tree_start <= 1'b1;
                state <= CALC_RECIPROCAL;
            end
            
            CALC_RECIPROCAL: begin
                tree_start <= 1'b0;
                if (sum_valid) begin
                    reciprocal_start <= 1'b1;
                    state <= MULTIPLY;
                    mult_counter <= 6'b0;
                end
            end
            
            MULTIPLY: begin
                reciprocal_start <= 1'b0;
                // Once reciprocal is available, multiply all exp values
                if (mult_counter < 64) begin
                    // exp_i (S5.10) × reciprocal_output (2^14/sum) >> 10 = exp_i/sum scaled
                    softmax_results[mult_counter] <= 
                        (exp_values[mult_counter] * reciprocal_output) >> 10;
                    
                    // Check if this is the last element
                    if (mult_counter == 63) begin
                        state <= DONE;  // Go to DONE after processing last element
                    end else begin
                        mult_counter <= mult_counter + 1;
                    end
                end else begin
                    state <= DONE;
                end
            end
            
            DONE: begin
                valid_out <= 1'b1;
                if (!start) begin
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule
