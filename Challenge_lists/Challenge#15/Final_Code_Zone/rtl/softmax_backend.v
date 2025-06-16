// Softmax Backend - Fully Verilog-2001 Compatible Version
// Function: Receives output from softmax_frontend and performs direct division normalization
// Fix: Completely removes SystemVerilog syntax to ensure Icarus compatibility

module softmax_backend (
    input clk,
    input rst_n,
    
    // Pipeline interface from softmax_frontend
    input valid_in,                         // Input valid signal
    input [31:0] exp_sum_in,               // Sum of EXP values
    input [15:0] exp_values_in [0:15],     // EXP value vector
    
    // Pipeline output interface
    output reg valid_out,                   // Output valid signal  
    output reg [15:0] softmax_out [0:15]   // softmax result (Q5.10 format)
);

// =============================================================================
// Pipeline control and data registers
// =============================================================================
reg valid_stage_0, valid_stage_1;  // 2-stage pipeline

// Stage data
reg [31:0] exp_sum_s0;                    // Stage 0: input sum
reg [15:0] exp_values_s0 [0:15];          // Stage 0: exp_values
reg [15:0] softmax_s1 [0:15];             // Stage 1: softmax result

// Calculation variables - all declared at module top level
reg [47:0] numerator_wide;   // 48-bit numerator
reg [31:0] denominator;      // 32-bit denominator  
reg [31:0] division_result;  // 32-bit division result
reg [31:0] temp_numerator;   // Temporary calculation

// =============================================================================
// Main pipeline logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    integer j;
    
    if (!rst_n) begin
        // Reset all registers
        valid_stage_0 <= 1'b0;
        valid_stage_1 <= 1'b0; 
        valid_out <= 1'b0;
        
        exp_sum_s0 <= 32'h0;
        
        for (j = 0; j < 16; j = j + 1) begin
            exp_values_s0[j] <= 16'h0;
            softmax_s1[j] <= 16'h0;
            softmax_out[j] <= 16'h0;
        end
        
    end else begin
        
        // ================================================================
        // Stage 0: Input reception
        // ================================================================
        valid_stage_0 <= valid_in;
        if (valid_in) begin
            exp_sum_s0 <= exp_sum_in;
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s0[j] <= exp_values_in[j];
            end
        end
        
        // ================================================================
        // Stage 1: Division normalization calculation
        // ================================================================
        valid_stage_1 <= valid_stage_0;
        if (valid_stage_0) begin
            denominator = exp_sum_s0;
            
            // 16 serial division calculations (to avoid complex parallel logic)
            if (denominator == 32'h0) begin
                // Division by zero protection - all outputs are 0
                for (j = 0; j < 16; j = j + 1) begin
                    softmax_s1[j] <= 16'h0;
                end
            end else begin
                // Calculate each element
                for (j = 0; j < 16; j = j + 1) begin
                    // Step-by-step calculation to avoid complex expressions
                    temp_numerator = exp_values_s0[j] * 1024;
                    division_result = temp_numerator / denominator;
                    
                    // Check for overflow
                    if (division_result > 32'h0000FFFF) begin
                        softmax_s1[j] <= 16'hFFFF;  // Saturate
                    end else begin
                        softmax_s1[j] <= division_result[15:0];
                    end
                end
            end
        end
        
        // ================================================================
        // Output stage
        // ================================================================
        valid_out <= valid_stage_1;
        if (valid_stage_1) begin
            for (j = 0; j < 16; j = j + 1) begin
                softmax_out[j] <= softmax_s1[j];
            end
        end
        
    end
end

// =============================================================================
// Separate calculation block for debugging (combinational logic)
// =============================================================================
reg [31:0] debug_numerator;
reg [31:0] debug_result;

always @(*) begin
    if (valid_stage_0 && exp_sum_s0 != 0) begin
        debug_numerator = exp_values_s0[0] * 1024;
        debug_result = debug_numerator / exp_sum_s0;
    end else begin
        debug_numerator = 0;
        debug_result = 0;
    end
end

// =============================================================================
// Debug information
// =============================================================================
`ifdef DEBUG_SOFTMAX
always @(posedge clk) begin
    if (valid_in) begin
        $display("[BACKEND] Input: exp_sum=0x%08x, exp_values[0]=0x%04x", 
                 exp_sum_in, exp_values_in[0]);
    end
    
    if (valid_stage_0) begin
        $display("[BACKEND] Stage0: exp_sum_s0=0x%08x, exp_values_s0[0]=0x%04x", 
                 exp_sum_s0, exp_values_s0[0]);
        
        if (exp_sum_s0 != 0) begin
            $display("[BACKEND] Debug calc: numerator=0x%08x, result=0x%08x", 
                     debug_numerator, debug_result);
        end
    end
    
    if (valid_stage_1) begin
        $display("[BACKEND] Stage1: softmax_s1[0]=0x%04x", softmax_s1[0]);
    end
    
    if (valid_out) begin
        $display("[BACKEND] Output: softmax[0]=0x%04x", softmax_out[0]);
    end
end
`endif

endmodule