// LayerNorm Post-Processing Module - 3-stage Pipeline (Q5.10 format)
// Function: Normalization, Scaling, Offset
// Stage 0: Normalization normalized = diff × inv_sigma (16 multiplications)
// Stage 1: Scaling scaled = normalized × γ (16 multiplications)  
// Stage 2: Offset output = scaled + β (16 additions)

module layernorm_postprocess (
    input clk,
    input rst_n,
    
    // Input interface from sqrt module (Q5.10 format)
    input valid_in,
    input signed [15:0] inv_sigma_in,     // 1/σ (Q5.10)
    input signed [15:0] mean_in,          // Mean μ (pass-through, for verification)
    // Difference vector (xi - μ)
    input signed [15:0] diff_vector_in_0,  input signed [15:0] diff_vector_in_1,
    input signed [15:0] diff_vector_in_2,  input signed [15:0] diff_vector_in_3,
    input signed [15:0] diff_vector_in_4,  input signed [15:0] diff_vector_in_5,
    input signed [15:0] diff_vector_in_6,  input signed [15:0] diff_vector_in_7,
    input signed [15:0] diff_vector_in_8,  input signed [15:0] diff_vector_in_9,
    input signed [15:0] diff_vector_in_10, input signed [15:0] diff_vector_in_11,
    input signed [15:0] diff_vector_in_12, input signed [15:0] diff_vector_in_13,
    input signed [15:0] diff_vector_in_14, input signed [15:0] diff_vector_in_15,
    
    // LayerNorm parameters (Q5.10 format)
    input [15:0] gamma_0,  input [15:0] gamma_1,  input [15:0] gamma_2,  input [15:0] gamma_3,
    input [15:0] gamma_4,  input [15:0] gamma_5,  input [15:0] gamma_6,  input [15:0] gamma_7,
    input [15:0] gamma_8,  input [15:0] gamma_9,  input [15:0] gamma_10, input [15:0] gamma_11,
    input [15:0] gamma_12, input [15:0] gamma_13, input [15:0] gamma_14, input [15:0] gamma_15,
    
    input [15:0] beta_0,   input [15:0] beta_1,   input [15:0] beta_2,   input [15:0] beta_3,
    input [15:0] beta_4,   input [15:0] beta_5,   input [15:0] beta_6,   input [15:0] beta_7,
    input [15:0] beta_8,   input [15:0] beta_9,   input [15:0] beta_10,  input [15:0] beta_11,
    input [15:0] beta_12,  input [15:0] beta_13,  input [15:0] beta_14,  input [15:0] beta_15,
    
    // Output interface (Q5.10 format)
    output reg valid_out,
    output reg signed [15:0] output_vector_0,  output reg signed [15:0] output_vector_1,
    output reg signed [15:0] output_vector_2,  output reg signed [15:0] output_vector_3,
    output reg signed [15:0] output_vector_4,  output reg signed [15:0] output_vector_5,
    output reg signed [15:0] output_vector_6,  output reg signed [15:0] output_vector_7,
    output reg signed [15:0] output_vector_8,  output reg signed [15:0] output_vector_9,
    output reg signed [15:0] output_vector_10, output reg signed [15:0] output_vector_11,
    output reg signed [15:0] output_vector_12, output reg signed [15:0] output_vector_13,
    output reg signed [15:0] output_vector_14, output reg signed [15:0] output_vector_15
);

// =============================================================================
// Pipeline Data Structure
// =============================================================================

// Stage valid signals
reg valid_stage [0:2];  // Stage 0-2

// Stage 0: Receive input data
reg signed [15:0] inv_sigma_s0;
reg signed [15:0] mean_s0;
reg signed [15:0] diff_s0 [0:15];

// Stage 1: Normalization result normalized = diff × inv_sigma
reg signed [15:0] normalized_s1 [0:15];

// Stage 2: Scaling result scaled = normalized × γ
reg signed [15:0] scaled_s2 [0:15];

// Temporary calculation variables - independent for each stage
reg signed [31:0] temp_norm_mult [0:15];  // Stage 0: normalization multiplication
reg signed [31:0] temp_scale_mult [0:15]; // Stage 1: scaling multiplication

// =============================================================================
// Main Pipeline Logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all valid signals
        integer i;
        for (i = 0; i <= 2; i = i + 1) begin
            valid_stage[i] <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================================
        // Stage 0: Receive input + normalization normalized = diff × inv_sigma (16 multiplications)
        // ================================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // Save input data to Stage 0
            inv_sigma_s0 <= inv_sigma_in;
            mean_s0 <= mean_in;
            
            // Save difference vector
            diff_s0[0]  <= diff_vector_in_0;  diff_s0[1]  <= diff_vector_in_1;
            diff_s0[2]  <= diff_vector_in_2;  diff_s0[3]  <= diff_vector_in_3;
            diff_s0[4]  <= diff_vector_in_4;  diff_s0[5]  <= diff_vector_in_5;
            diff_s0[6]  <= diff_vector_in_6;  diff_s0[7]  <= diff_vector_in_7;
            diff_s0[8]  <= diff_vector_in_8;  diff_s0[9]  <= diff_vector_in_9;
            diff_s0[10] <= diff_vector_in_10; diff_s0[11] <= diff_vector_in_11;
            diff_s0[12] <= diff_vector_in_12; diff_s0[13] <= diff_vector_in_13;
            diff_s0[14] <= diff_vector_in_14; diff_s0[15] <= diff_vector_in_15;
            
            //$display("Stage0: NEW INPUT inv_sigma=0x%04x", inv_sigma_in);
        end
        
        // ================================================================
        // Stage 1: Normalization calculation normalized = diff × inv_sigma
        // ================================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // Stage 1 calculation: normalization normalized = diff × inv_sigma (blocking assignment)
            // Q5.10 × Q5.10 = Q10.20, right shift 10 bits back to Q5.10 format
            temp_norm_mult[0]  = diff_s0[0]  * inv_sigma_s0;
            temp_norm_mult[1]  = diff_s0[1]  * inv_sigma_s0;
            temp_norm_mult[2]  = diff_s0[2]  * inv_sigma_s0;
            temp_norm_mult[3]  = diff_s0[3]  * inv_sigma_s0;
            temp_norm_mult[4]  = diff_s0[4]  * inv_sigma_s0;
            temp_norm_mult[5]  = diff_s0[5]  * inv_sigma_s0;
            temp_norm_mult[6]  = diff_s0[6]  * inv_sigma_s0;
            temp_norm_mult[7]  = diff_s0[7]  * inv_sigma_s0;
            temp_norm_mult[8]  = diff_s0[8]  * inv_sigma_s0;
            temp_norm_mult[9]  = diff_s0[9]  * inv_sigma_s0;
            temp_norm_mult[10] = diff_s0[10] * inv_sigma_s0;
            temp_norm_mult[11] = diff_s0[11] * inv_sigma_s0;
            temp_norm_mult[12] = diff_s0[12] * inv_sigma_s0;
            temp_norm_mult[13] = diff_s0[13] * inv_sigma_s0;
            temp_norm_mult[14] = diff_s0[14] * inv_sigma_s0;
            temp_norm_mult[15] = diff_s0[15] * inv_sigma_s0;
            
            normalized_s1[0]  <= temp_norm_mult[0] >>> 10;  // Right shift 10 bits back to Q5.10
            normalized_s1[1]  <= temp_norm_mult[1] >>> 10;
            normalized_s1[2]  <= temp_norm_mult[2] >>> 10;
            normalized_s1[3]  <= temp_norm_mult[3] >>> 10;
            normalized_s1[4]  <= temp_norm_mult[4] >>> 10;
            normalized_s1[5]  <= temp_norm_mult[5] >>> 10;
            normalized_s1[6]  <= temp_norm_mult[6] >>> 10;
            normalized_s1[7]  <= temp_norm_mult[7] >>> 10;
            normalized_s1[8]  <= temp_norm_mult[8] >>> 10;
            normalized_s1[9]  <= temp_norm_mult[9] >>> 10;
            normalized_s1[10] <= temp_norm_mult[10] >>> 10;
            normalized_s1[11] <= temp_norm_mult[11] >>> 10;
            normalized_s1[12] <= temp_norm_mult[12] >>> 10;
            normalized_s1[13] <= temp_norm_mult[13] >>> 10;
            normalized_s1[14] <= temp_norm_mult[14] >>> 10;
            normalized_s1[15] <= temp_norm_mult[15] >>> 10;
            
            //$display("Stage1: normalized[0]=0x%04x", temp_norm_mult[0] >>> 10);
        end
        
        // ================================================================
        // Stage 2: Scaling calculation scaled = normalized × γ  
        // ================================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // Stage 2 calculation: scaling scaled = normalized × γ (blocking assignment)
            // Q5.10 × Q5.10 = Q10.20, right shift 10 bits back to Q5.10 format
            temp_scale_mult[0]  = normalized_s1[0]  * $signed({1'b0, gamma_0});
            temp_scale_mult[1]  = normalized_s1[1]  * $signed({1'b0, gamma_1});
            temp_scale_mult[2]  = normalized_s1[2]  * $signed({1'b0, gamma_2});
            temp_scale_mult[3]  = normalized_s1[3]  * $signed({1'b0, gamma_3});
            temp_scale_mult[4]  = normalized_s1[4]  * $signed({1'b0, gamma_4});
            temp_scale_mult[5]  = normalized_s1[5]  * $signed({1'b0, gamma_5});
            temp_scale_mult[6]  = normalized_s1[6]  * $signed({1'b0, gamma_6});
            temp_scale_mult[7]  = normalized_s1[7]  * $signed({1'b0, gamma_7});
            temp_scale_mult[8]  = normalized_s1[8]  * $signed({1'b0, gamma_8});
            temp_scale_mult[9]  = normalized_s1[9]  * $signed({1'b0, gamma_9});
            temp_scale_mult[10] = normalized_s1[10] * $signed({1'b0, gamma_10});
            temp_scale_mult[11] = normalized_s1[11] * $signed({1'b0, gamma_11});
            temp_scale_mult[12] = normalized_s1[12] * $signed({1'b0, gamma_12});
            temp_scale_mult[13] = normalized_s1[13] * $signed({1'b0, gamma_13});
            temp_scale_mult[14] = normalized_s1[14] * $signed({1'b0, gamma_14});
            temp_scale_mult[15] = normalized_s1[15] * $signed({1'b0, gamma_15});
            
            scaled_s2[0]  <= temp_scale_mult[0] >>> 10;
            scaled_s2[1]  <= temp_scale_mult[1] >>> 10;
            scaled_s2[2]  <= temp_scale_mult[2] >>> 10;
            scaled_s2[3]  <= temp_scale_mult[3] >>> 10;
            scaled_s2[4]  <= temp_scale_mult[4] >>> 10;
            scaled_s2[5]  <= temp_scale_mult[5] >>> 10;
            scaled_s2[6]  <= temp_scale_mult[6] >>> 10;
            scaled_s2[7]  <= temp_scale_mult[7] >>> 10;
            scaled_s2[8]  <= temp_scale_mult[8] >>> 10;
            scaled_s2[9]  <= temp_scale_mult[9] >>> 10;
            scaled_s2[10] <= temp_scale_mult[10] >>> 10;
            scaled_s2[11] <= temp_scale_mult[11] >>> 10;
            scaled_s2[12] <= temp_scale_mult[12] >>> 10;
            scaled_s2[13] <= temp_scale_mult[13] >>> 10;
            scaled_s2[14] <= temp_scale_mult[14] >>> 10;
            scaled_s2[15] <= temp_scale_mult[15] >>> 10;
            
            //$display("Stage2: scaled[0]=0x%04x", temp_scale_mult[0] >>> 10);
        end
        
        // ================================================================
        // Output: Offset calculation output = scaled + β (16 additions)
        // ================================================================
        valid_out <= valid_stage[2];
        if (valid_stage[2]) begin
            // Final calculation: offset output = scaled + β
            output_vector_0  <= scaled_s2[0]  + $signed({1'b0, beta_0});
            output_vector_1  <= scaled_s2[1]  + $signed({1'b0, beta_1});
            output_vector_2  <= scaled_s2[2]  + $signed({1'b0, beta_2});
            output_vector_3  <= scaled_s2[3]  + $signed({1'b0, beta_3});
            output_vector_4  <= scaled_s2[4]  + $signed({1'b0, beta_4});
            output_vector_5  <= scaled_s2[5]  + $signed({1'b0, beta_5});
            output_vector_6  <= scaled_s2[6]  + $signed({1'b0, beta_6});
            output_vector_7  <= scaled_s2[7]  + $signed({1'b0, beta_7});
            output_vector_8  <= scaled_s2[8]  + $signed({1'b0, beta_8});
            output_vector_9  <= scaled_s2[9]  + $signed({1'b0, beta_9});
            output_vector_10 <= scaled_s2[10] + $signed({1'b0, beta_10});
            output_vector_11 <= scaled_s2[11] + $signed({1'b0, beta_11});
            output_vector_12 <= scaled_s2[12] + $signed({1'b0, beta_12});
            output_vector_13 <= scaled_s2[13] + $signed({1'b0, beta_13});
            output_vector_14 <= scaled_s2[14] + $signed({1'b0, beta_14});
            output_vector_15 <= scaled_s2[15] + $signed({1'b0, beta_15});
            
            //$display("Output: final[0]=0x%04x", scaled_s2[0] + $signed({1'b0, beta_0}));
        end
        
    end
end

endmodule