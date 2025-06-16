// Reciprocal Divider - Simplified True Pipeline (Q5.10 format)  
// Function: Calculate 1/exp_sum using a simplified shift division
// Input: exp_sum (from softmax_frontend)
// Output: reciprocal + pass-through exp_values
// Pipeline: 3-stage simple pipeline

module reciprocal_divider (
    input clk,
    input rst_n,
    
    // Pipeline interface from softmax_frontend
    input valid_in,                         // Input valid signal
    input [31:0] exp_sum_in,               // Divisor (denominator)
    input [15:0] exp_values_in [0:15],     // Pass-through exp_values
    
    // Pipeline interface to softmax_backend
    output reg valid_out,                   // Output valid signal
    output reg [15:0] reciprocal_out,      // Reciprocal result (Q5.10)
    output reg [15:0] exp_values_out [0:15] // Pass-through exp_values
);

// =============================================================================
// Simplified scheme: use approximation algorithm
// For softmax, we know the approximate range of exp_sum, so we can use LUT + adjustment
// =============================================================================

// Pipeline control
reg valid_stage [0:2];  // 3-stage pipeline

// Stage data
reg [19:0] exp_sum_s0;                    // Stage 0: input sum (lower 20 bits)
reg [15:0] exp_values_s0 [0:15];          // Stage 0: exp_values

reg [15:0] reciprocal_approx_s1;          // Stage 1: approximate reciprocal
reg [15:0] exp_values_s1 [0:15];          // Stage 1: exp_values

reg [15:0] reciprocal_final_s2;           // Stage 2: final reciprocal
reg [15:0] exp_values_s2 [0:15];          // Stage 2: exp_values

// =============================================================================
// Main pipeline logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    integer j;
    
    if (!rst_n) begin
        // Reset
        valid_stage[0] <= 1'b0;
        valid_stage[1] <= 1'b0; 
        valid_stage[2] <= 1'b0;
        valid_out <= 1'b0;
        reciprocal_out <= 16'h0;
        
    end else begin
        
        // ================================================================
        // Stage 0: Input reception
        // ================================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // Save input data
            exp_sum_s0 <= exp_sum_in[19:0];  // Take lower 20 bits
            
            // Pass-through exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s0[j] <= exp_values_in[j];
            end
        end
        
        // ================================================================
        // Stage 1: Simple reciprocal calculation
        // ================================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // Correct reciprocal calculation:
            // We want to calculate 1/exp_sum, result in Q5.10 format
            // In Q5.10 format, 1.0 = 1024
            // So 1/exp_sum = 1024*1024 / exp_sum = 1048576 / exp_sum
            
            reg [31:0] dividend;
            reg [19:0] divisor;
            reg [15:0] result;
            
            dividend = 32'h00100000;  // 1048576 = 1024*1024 
            divisor = exp_sum_s0;
            
            // Simple division: check divisor is not zero
            if (divisor == 0) begin
                result = 16'hFFFF;  // Division by zero protection
            end else if (divisor > dividend) begin
                result = 16'h0001;  // Result less than 1, set to minimum
            end else begin
                // Perform division
                result = dividend / divisor;
                // Limit to 16-bit range
                if (result > 16'hFFFF) begin
                    result = 16'hFFFF;
                end
            end
            
            reciprocal_approx_s1 <= result;
            
            // Pass-through exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s1[j] <= exp_values_s0[j];
            end
        end
        
        // ================================================================
        // Stage 2: Output preparation (fine-tuning can be added here)
        // ================================================================  
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // Directly output approximate result (fine-tuning can be added here)
            reciprocal_final_s2 <= reciprocal_approx_s1;
            
            // Pass-through exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s2[j] <= exp_values_s1[j];
            end
        end
        
        // ================================================================
        // Output stage
        // ================================================================
        valid_out <= valid_stage[2];
        if (valid_stage[2]) begin
            reciprocal_out <= reciprocal_final_s2;
            
            // Output exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_out[j] <= exp_values_s2[j];
            end
        end
        
    end
end

// =============================================================================
// Debug information
// =============================================================================
`ifdef DEBUG_RECIPROCAL
always @(posedge clk) begin
    if (valid_in) begin
        $display("[RECIPROCAL] Input: exp_sum=0x%05x (%d)", exp_sum_in[19:0], exp_sum_in[19:0]);
    end
    if (valid_out) begin
        $display("[RECIPROCAL] Output: reciprocal=0x%04x (%d)", reciprocal_out, reciprocal_out);
    end
end
`endif

endmodule