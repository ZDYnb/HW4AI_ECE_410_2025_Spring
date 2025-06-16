// LayerNorm Preprocessing Module - 9-stage Pipeline (Q5.10 format)
// Function: Calculate mean, variance, and difference vector
// Stage 0-8: Mean calculation (4 stages) + Variance calculation (5 stages)
// Data format: Q5.10 (1 sign bit + 5 integer bits + 10 fractional bits)

module layernorm_preprocess (
    input clk,
    input rst_n,
    
    // Input interface (Q5.10 format)
    input valid_in,
    input [15:0] input_vector_0,  input [15:0] input_vector_1,
    input [15:0] input_vector_2,  input [15:0] input_vector_3,
    input [15:0] input_vector_4,  input [15:0] input_vector_5,
    input [15:0] input_vector_6,  input [15:0] input_vector_7,
    input [15:0] input_vector_8,  input [15:0] input_vector_9,
    input [15:0] input_vector_10, input [15:0] input_vector_11,
    input [15:0] input_vector_12, input [15:0] input_vector_13,
    input [15:0] input_vector_14, input [15:0] input_vector_15,
    
    // Output interface (Q5.10 format)
    output reg valid_out,
    output reg signed [15:0] mean_out,      // Mean μ
    output reg signed [15:0] variance_out,  // Variance σ²
    // Difference vector (xi - μ), passed to subsequent modules
    output reg signed [15:0] diff_vector_0,  output reg signed [15:0] diff_vector_1,
    output reg signed [15:0] diff_vector_2,  output reg signed [15:0] diff_vector_3,
    output reg signed [15:0] diff_vector_4,  output reg signed [15:0] diff_vector_5,
    output reg signed [15:0] diff_vector_6,  output reg signed [15:0] diff_vector_7,
    output reg signed [15:0] diff_vector_8,  output reg signed [15:0] diff_vector_9,
    output reg signed [15:0] diff_vector_10, output reg signed [15:0] diff_vector_11,
    output reg signed [15:0] diff_vector_12, output reg signed [15:0] diff_vector_13,
    output reg signed [15:0] diff_vector_14, output reg signed [15:0] diff_vector_15
);

// =============================================================================
// Q5.10 format constant definition
// =============================================================================
localparam Q5_10_EPSILON = 16'h0001;  // epsilon = 1/1024 ≈ 0.001

// =============================================================================
// Pipeline data structure - each stage saves all required data
// =============================================================================

// Valid signal for each stage
reg valid_stage [0:8];

// Copy of original input vector at each stage
reg [15:0] xi_stage0 [0:15];
reg [15:0] xi_stage1 [0:15];
reg [15:0] xi_stage2 [0:15];
reg [15:0] xi_stage3 [0:15];
reg [15:0] xi_stage4 [0:15];
reg [15:0] xi_stage5 [0:15];
reg [15:0] xi_stage6 [0:15];
reg [15:0] xi_stage7 [0:15];
reg [15:0] xi_stage8 [0:15];

// Copy of mean at each stage (valid from stage3)
reg signed [15:0] mu_stage3;
reg signed [15:0] mu_stage4;
reg signed [15:0] mu_stage5;
reg signed [15:0] mu_stage6;
reg signed [15:0] mu_stage7;
reg signed [15:0] mu_stage8;

// Copy of difference vector at each stage (valid from stage4)
reg signed [15:0] diff_stage4 [0:15];
reg signed [15:0] diff_stage5 [0:15];
reg signed [15:0] diff_stage6 [0:15];
reg signed [15:0] diff_stage7 [0:15];
reg signed [15:0] diff_stage8 [0:15];

// =============================================================================
// Intermediate results for mean calculation
// =============================================================================
// Stage 0: 16→8 (extend to 17 bits to prevent overflow)
reg signed [16:0] mean_tree_8 [0:7];
// Stage 1: 8→4 (extend to 18 bits)
reg signed [17:0] mean_tree_4 [0:3];
// Stage 2: 4→2 (extend to 19 bits)
reg signed [18:0] mean_tree_2 [0:1];

// =============================================================================
// Intermediate results for variance calculation
// =============================================================================
// Stage 5: Square calculation (Q5.10 * Q5.10 = Q10.20, take high 16 bits)
reg signed [31:0] diff_squared [0:15];
// Stage 6: Variance adder tree 16→8
reg signed [32:0] var_tree_8 [0:7];
// Stage 7: Variance adder tree 8→4
reg signed [33:0] var_tree_4 [0:3];
// Stage 8: Variance adder tree 4→2
reg signed [34:0] var_tree_2 [0:1];

// =============================================================================
// Main pipeline logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all valid signals
        integer i;
        for (i = 0; i <= 8; i = i + 1) begin
            valid_stage[i] <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================
        // Stage 0: Save input vector + mean adder tree level 1 (16→8)
        // ================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // Save original input vector
            xi_stage0[0]  <= input_vector_0;  xi_stage0[1]  <= input_vector_1;
            xi_stage0[2]  <= input_vector_2;  xi_stage0[3]  <= input_vector_3;
            xi_stage0[4]  <= input_vector_4;  xi_stage0[5]  <= input_vector_5;
            xi_stage0[6]  <= input_vector_6;  xi_stage0[7]  <= input_vector_7;
            xi_stage0[8]  <= input_vector_8;  xi_stage0[9]  <= input_vector_9;
            xi_stage0[10] <= input_vector_10; xi_stage0[11] <= input_vector_11;
            xi_stage0[12] <= input_vector_12; xi_stage0[13] <= input_vector_13;
            xi_stage0[14] <= input_vector_14; xi_stage0[15] <= input_vector_15;
            
            // Mean adder tree level 1 (sign-extend to 17 bits)
            mean_tree_8[0] <= $signed(input_vector_0) + $signed(input_vector_1);
            mean_tree_8[1] <= $signed(input_vector_2) + $signed(input_vector_3);
            mean_tree_8[2] <= $signed(input_vector_4) + $signed(input_vector_5);
            mean_tree_8[3] <= $signed(input_vector_6) + $signed(input_vector_7);
            mean_tree_8[4] <= $signed(input_vector_8) + $signed(input_vector_9);
            mean_tree_8[5] <= $signed(input_vector_10) + $signed(input_vector_11);
            mean_tree_8[6] <= $signed(input_vector_12) + $signed(input_vector_13);
            mean_tree_8[7] <= $signed(input_vector_14) + $signed(input_vector_15);
        end
        
        // ================================================
        // Stage 1: Pass data + mean adder tree level 2 (8→4)
        // ================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // Pass original vector
            xi_stage1[0]  <= xi_stage0[0];  xi_stage1[1]  <= xi_stage0[1];
            xi_stage1[2]  <= xi_stage0[2];  xi_stage1[3]  <= xi_stage0[3];
            xi_stage1[4]  <= xi_stage0[4];  xi_stage1[5]  <= xi_stage0[5];
            xi_stage1[6]  <= xi_stage0[6];  xi_stage1[7]  <= xi_stage0[7];
            xi_stage1[8]  <= xi_stage0[8];  xi_stage1[9]  <= xi_stage0[9];
            xi_stage1[10] <= xi_stage0[10]; xi_stage1[11] <= xi_stage0[11];
            xi_stage1[12] <= xi_stage0[12]; xi_stage1[13] <= xi_stage0[13];
            xi_stage1[14] <= xi_stage0[14]; xi_stage1[15] <= xi_stage0[15];
            
            // Mean adder tree level 2
            mean_tree_4[0] <= mean_tree_8[0] + mean_tree_8[1];
            mean_tree_4[1] <= mean_tree_8[2] + mean_tree_8[3];
            mean_tree_4[2] <= mean_tree_8[4] + mean_tree_8[5];
            mean_tree_4[3] <= mean_tree_8[6] + mean_tree_8[7];
        end
        
        // ================================================
        // Stage 2: Pass data + mean adder tree level 3 (4→2)
        // ================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // Pass original vector
            xi_stage2[0]  <= xi_stage1[0];  xi_stage2[1]  <= xi_stage1[1];
            xi_stage2[2]  <= xi_stage1[2];  xi_stage2[3]  <= xi_stage1[3];
            xi_stage2[4]  <= xi_stage1[4];  xi_stage2[5]  <= xi_stage1[5];
            xi_stage2[6]  <= xi_stage1[6];  xi_stage2[7]  <= xi_stage1[7];
            xi_stage2[8]  <= xi_stage1[8];  xi_stage2[9]  <= xi_stage1[9];
            xi_stage2[10] <= xi_stage1[10]; xi_stage2[11] <= xi_stage1[11];
            xi_stage2[12] <= xi_stage1[12]; xi_stage2[13] <= xi_stage1[13];
            xi_stage2[14] <= xi_stage1[14]; xi_stage2[15] <= xi_stage1[15];
            
            // Mean adder tree level 3
            mean_tree_2[0] <= mean_tree_4[0] + mean_tree_4[1];
            mean_tree_2[1] <= mean_tree_4[2] + mean_tree_4[3];
        end
        
        // ================================================
        // Stage 3: Pass data + complete mean calculation μ = sum/16
        // ================================================
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            // Pass original vector
            xi_stage3[0]  <= xi_stage2[0];  xi_stage3[1]  <= xi_stage2[1];
            xi_stage3[2]  <= xi_stage2[2];  xi_stage3[3]  <= xi_stage2[3];
            xi_stage3[4]  <= xi_stage2[4];  xi_stage3[5]  <= xi_stage2[5];
            xi_stage3[6]  <= xi_stage2[6];  xi_stage3[7]  <= xi_stage2[7];
            xi_stage3[8]  <= xi_stage2[8];  xi_stage3[9]  <= xi_stage2[9];
            xi_stage3[10] <= xi_stage2[10]; xi_stage3[11] <= xi_stage2[11];
            xi_stage3[12] <= xi_stage2[12]; xi_stage3[13] <= xi_stage2[13];
            xi_stage3[14] <= xi_stage2[14]; xi_stage3[15] <= xi_stage2[15];
            
            // Calculate mean: sum/16, keep Q5.10 format
            mu_stage3 <= (mean_tree_2[0] + mean_tree_2[1]) >>> 4;  // divide by 16
        end
        
        // ================================================
        // Stage 4: Pass data + calculate difference (xi - μ)
        // ================================================
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            // Pass original vector
            xi_stage4[0]  <= xi_stage3[0];  xi_stage4[1]  <= xi_stage3[1];
            xi_stage4[2]  <= xi_stage3[2];  xi_stage4[3]  <= xi_stage3[3];
            xi_stage4[4]  <= xi_stage3[4];  xi_stage4[5]  <= xi_stage3[5];
            xi_stage4[6]  <= xi_stage3[6];  xi_stage4[7]  <= xi_stage3[7];
            xi_stage4[8]  <= xi_stage3[8];  xi_stage4[9]  <= xi_stage3[9];
            xi_stage4[10] <= xi_stage3[10]; xi_stage4[11] <= xi_stage3[11];
            xi_stage4[12] <= xi_stage3[12]; xi_stage4[13] <= xi_stage3[13];
            xi_stage4[14] <= xi_stage3[14]; xi_stage4[15] <= xi_stage3[15];
            
            // Pass mean
            mu_stage4 <= mu_stage3;
            
            // Calculate difference (xi - μ) in Q5.10
            diff_stage4[0]  <= $signed(xi_stage3[0])  - mu_stage3;
            diff_stage4[1]  <= $signed(xi_stage3[1])  - mu_stage3;
            diff_stage4[2]  <= $signed(xi_stage3[2])  - mu_stage3;
            diff_stage4[3]  <= $signed(xi_stage3[3])  - mu_stage3;
            diff_stage4[4]  <= $signed(xi_stage3[4])  - mu_stage3;
            diff_stage4[5]  <= $signed(xi_stage3[5])  - mu_stage3;
            diff_stage4[6]  <= $signed(xi_stage3[6])  - mu_stage3;
            diff_stage4[7]  <= $signed(xi_stage3[7])  - mu_stage3;
            diff_stage4[8]  <= $signed(xi_stage3[8])  - mu_stage3;
            diff_stage4[9]  <= $signed(xi_stage3[9])  - mu_stage3;
            diff_stage4[10] <= $signed(xi_stage3[10]) - mu_stage3;
            diff_stage4[11] <= $signed(xi_stage3[11]) - mu_stage3;
            diff_stage4[12] <= $signed(xi_stage3[12]) - mu_stage3;
            diff_stage4[13] <= $signed(xi_stage3[13]) - mu_stage3;
            diff_stage4[14] <= $signed(xi_stage3[14]) - mu_stage3;
            diff_stage4[15] <= $signed(xi_stage3[15]) - mu_stage3;
        end
        
        // ================================================
        // Stage 5: Pass data + calculate square (xi - μ)²
        // ================================================
        valid_stage[5] <= valid_stage[4];
        if (valid_stage[4]) begin
            // Pass data
            mu_stage5 <= mu_stage4;
            diff_stage5[0]  <= diff_stage4[0];  diff_stage5[1]  <= diff_stage4[1];
            diff_stage5[2]  <= diff_stage4[2];  diff_stage5[3]  <= diff_stage4[3];
            diff_stage5[4]  <= diff_stage4[4];  diff_stage5[5]  <= diff_stage4[5];
            diff_stage5[6]  <= diff_stage4[6];  diff_stage5[7]  <= diff_stage4[7];
            diff_stage5[8]  <= diff_stage4[8];  diff_stage5[9]  <= diff_stage4[9];
            diff_stage5[10] <= diff_stage4[10]; diff_stage5[11] <= diff_stage4[11];
            diff_stage5[12] <= diff_stage4[12]; diff_stage5[13] <= diff_stage4[13];
            diff_stage5[14] <= diff_stage4[14]; diff_stage5[15] <= diff_stage4[15];
            
            // Calculate square: Q5.10 * Q5.10 = Q10.20, need to adjust back to Q5.10
            diff_squared[0]  <= diff_stage4[0]  * diff_stage4[0];
            diff_squared[1]  <= diff_stage4[1]  * diff_stage4[1];
            diff_squared[2]  <= diff_stage4[2]  * diff_stage4[2];
            diff_squared[3]  <= diff_stage4[3]  * diff_stage4[3];
            diff_squared[4]  <= diff_stage4[4]  * diff_stage4[4];
            diff_squared[5]  <= diff_stage4[5]  * diff_stage4[5];
            diff_squared[6]  <= diff_stage4[6]  * diff_stage4[6];
            diff_squared[7]  <= diff_stage4[7]  * diff_stage4[7];
            diff_squared[8]  <= diff_stage4[8]  * diff_stage4[8];
            diff_squared[9]  <= diff_stage4[9]  * diff_stage4[9];
            diff_squared[10] <= diff_stage4[10] * diff_stage4[10];
            diff_squared[11] <= diff_stage4[11] * diff_stage4[11];
            diff_squared[12] <= diff_stage4[12] * diff_stage4[12];
            diff_squared[13] <= diff_stage4[13] * diff_stage4[13];
            diff_squared[14] <= diff_stage4[14] * diff_stage4[14];
            diff_squared[15] <= diff_stage4[15] * diff_stage4[15];
        end
        
        // ================================================
        // Stage 6: Pass data + variance adder tree level 1 (16→8)
        // ================================================
        valid_stage[6] <= valid_stage[5];
        if (valid_stage[5]) begin
            // Pass data
            mu_stage6 <= mu_stage5;
            diff_stage6[0]  <= diff_stage5[0];  diff_stage6[1]  <= diff_stage5[1];
            diff_stage6[2]  <= diff_stage5[2];  diff_stage6[3]  <= diff_stage5[3];
            diff_stage6[4]  <= diff_stage5[4];  diff_stage6[5]  <= diff_stage5[5];
            diff_stage6[6]  <= diff_stage5[6];  diff_stage6[7]  <= diff_stage5[7];
            diff_stage6[8]  <= diff_stage5[8];  diff_stage6[9]  <= diff_stage5[9];
            diff_stage6[10] <= diff_stage5[10]; diff_stage6[11] <= diff_stage5[11];
            diff_stage6[12] <= diff_stage5[12]; diff_stage6[13] <= diff_stage5[13];
            diff_stage6[14] <= diff_stage5[14]; diff_stage6[15] <= diff_stage5[15];
            
            // Variance adder tree level 1: take high part of square result
            var_tree_8[0] <= diff_squared[0][31:10]  + diff_squared[1][31:10];
            var_tree_8[1] <= diff_squared[2][31:10]  + diff_squared[3][31:10];
            var_tree_8[2] <= diff_squared[4][31:10]  + diff_squared[5][31:10];
            var_tree_8[3] <= diff_squared[6][31:10]  + diff_squared[7][31:10];
            var_tree_8[4] <= diff_squared[8][31:10]  + diff_squared[9][31:10];
            var_tree_8[5] <= diff_squared[10][31:10] + diff_squared[11][31:10];
            var_tree_8[6] <= diff_squared[12][31:10] + diff_squared[13][31:10];
            var_tree_8[7] <= diff_squared[14][31:10] + diff_squared[15][31:10];
        end
        
        // ================================================
        // Stage 7: Pass data + variance adder tree level 2 (8→4)
        // ================================================
        valid_stage[7] <= valid_stage[6];
        if (valid_stage[6]) begin
            // Pass data
            mu_stage7 <= mu_stage6;
            diff_stage7[0]  <= diff_stage6[0];  diff_stage7[1]  <= diff_stage6[1];
            diff_stage7[2]  <= diff_stage6[2];  diff_stage7[3]  <= diff_stage6[3];
            diff_stage7[4]  <= diff_stage6[4];  diff_stage7[5]  <= diff_stage6[5];
            diff_stage7[6]  <= diff_stage6[6];  diff_stage7[7]  <= diff_stage6[7];
            diff_stage7[8]  <= diff_stage6[8];  diff_stage7[9]  <= diff_stage6[9];
            diff_stage7[10] <= diff_stage6[10]; diff_stage7[11] <= diff_stage6[11];
            diff_stage7[12] <= diff_stage6[12]; diff_stage7[13] <= diff_stage6[13];
            diff_stage7[14] <= diff_stage6[14]; diff_stage7[15] <= diff_stage6[15];
            
            // Variance adder tree level 2
            var_tree_4[0] <= var_tree_8[0] + var_tree_8[1];
            var_tree_4[1] <= var_tree_8[2] + var_tree_8[3];
            var_tree_4[2] <= var_tree_8[4] + var_tree_8[5];
            var_tree_4[3] <= var_tree_8[6] + var_tree_8[7];
        end
        
        // ================================================
        // Stage 8: Pass data + variance adder tree level 3 (4→2) + final calculation
        // ================================================
        valid_stage[8] <= valid_stage[7];
        if (valid_stage[7]) begin
            // Pass data
            mu_stage8 <= mu_stage7;
            diff_stage8[0]  <= diff_stage7[0];  diff_stage8[1]  <= diff_stage7[1];
            diff_stage8[2]  <= diff_stage7[2];  diff_stage8[3]  <= diff_stage7[3];
            diff_stage8[4]  <= diff_stage7[4];  diff_stage8[5]  <= diff_stage7[5];
            diff_stage8[6]  <= diff_stage7[6];  diff_stage8[7]  <= diff_stage7[7];
            diff_stage8[8]  <= diff_stage7[8];  diff_stage8[9]  <= diff_stage7[9];
            diff_stage8[10] <= diff_stage7[10]; diff_stage8[11] <= diff_stage7[11];
            diff_stage8[12] <= diff_stage7[12]; diff_stage8[13] <= diff_stage7[13];
            diff_stage8[14] <= diff_stage7[14]; diff_stage8[15] <= diff_stage7[15];
            
            // Variance adder tree level 3
            var_tree_2[0] <= var_tree_4[0] + var_tree_4[1];
            var_tree_2[1] <= var_tree_4[2] + var_tree_4[3];
        end
        
        // ================================================
        // Output: Complete variance calculation and output all results
        // ================================================
        valid_out <= valid_stage[8];
        if (valid_stage[8]) begin
            // 方差 = sum/16 + epsilon (Q5.10格式)
            reg signed [35:0] var_sum;
            var_sum = (var_tree_2[0] + var_tree_2[1]) >>> 4;  // 除以16
            variance_out <= var_sum[15:0] + Q5_10_EPSILON;  // 加epsilon
            
            // 输出均值
            mean_out <= mu_stage8;
            
            // 输出差值向量
            diff_vector_0  <= diff_stage8[0];  diff_vector_1  <= diff_stage8[1];
            diff_vector_2  <= diff_stage8[2];  diff_vector_3  <= diff_stage8[3];
            diff_vector_4  <= diff_stage8[4];  diff_vector_5  <= diff_stage8[5];
            diff_vector_6  <= diff_stage8[6];  diff_vector_7  <= diff_stage8[7];
            diff_vector_8  <= diff_stage8[8];  diff_vector_9  <= diff_stage8[9];
            diff_vector_10 <= diff_stage8[10]; diff_vector_11 <= diff_stage8[11];
            diff_vector_12 <= diff_stage8[12]; diff_vector_13 <= diff_stage8[13];
            diff_vector_14 <= diff_stage8[14]; diff_vector_15 <= diff_stage8[15];
        end
        
    end
end

endmodule