// LayerNorm 21-stage pipelined processor - Fully rewritten
// Each stage performs only one operation, unified 16-bit Q12 format

module layernorm_optimized_pipeline (
    input clk,
    input rst_n,
    
    // Vector stream interface
    input valid_in,
    output reg valid_out,
    input [15:0] input_vector [0:15],
    output reg [15:0] output_vector [0:15],
    
    // Parameters
    input [15:0] gamma [0:15], 
    input [15:0] beta [0:15]
);

// =============================================================================
// Pipeline data structure - all data unified to 16-bit Q12 format
// =============================================================================
typedef struct packed {
    reg [15:0] xi [0:15];           // Original input vector (Q12)
    reg signed [15:0] mu;           // Mean (Q12)
    reg signed [15:0] diff [0:15];  // Difference vector (Q12) 
    reg signed [15:0] variance;     // Variance (Q12)
    reg signed [15:0] x0;           // Initial guess (Q12)
    reg signed [15:0] x0_sq;        // x0² (Q12)
    reg signed [15:0] var_x0_sq;    // variance*x0² (Q12)
    reg signed [15:0] three_minus_1; // 3-variance*x0² (Q12)
    reg signed [15:0] x1;           // 1st iteration (Q12)
    reg signed [15:0] x1_sq;        // x1² (Q12)
    reg signed [15:0] var_x1_sq;    // variance*x1² (Q12)
    reg signed [15:0] three_minus_2; // 3-variance*x1² (Q12)
    reg signed [15:0] inv_sigma;    // Final 1/σ (Q12)
    reg signed [15:0] normalized [0:15]; // Normalization result (Q12)
    reg signed [15:0] scaled [0:15];     // Scaling result (Q12)
    reg valid;
} pipeline_data_t;

// Pipeline stages
pipeline_data_t stage [0:20];  // 21-stage pipeline

// =============================================================================
// Intermediate results for mean calculation
// =============================================================================
reg signed [16:0] mean_tree_8 [0:7];    // Stage 0: 16→8
reg signed [17:0] mean_tree_4 [0:3];    // Stage 1: 8→4  
reg signed [18:0] mean_tree_2 [0:1];    // Stage 2: 4→2

// =============================================================================
// Intermediate results for variance calculation
// =============================================================================
reg signed [31:0] diff_squared [0:15];   // Stage 5: (xi-μ)²
reg signed [32:0] var_tree_8 [0:7];      // Stage 6: 16→8
reg signed [33:0] var_tree_4 [0:3];      // Stage 7: 8→4
reg signed [34:0] var_tree_2 [0:1];      // Stage 8: 4→2

// =============================================================================
// Main pipeline logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all pipeline stages
        for (integer i = 0; i <= 20; i = i + 1) begin
            stage[i].valid <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================
        // Stage 0: Mean adder tree level 1 (16→8)
        // ================================================
        stage[0].valid <= valid_in;
        if (valid_in) begin
            // Save input vector
            for (integer i = 0; i < 16; i = i + 1) begin
                stage[0].xi[i] <= input_vector[i];
            end
            
            // Level 1 adder tree: 16→8
            for (integer j = 0; j < 8; j = j + 1) begin
                mean_tree_8[j] <= $signed({1'b0, input_vector[j*2]}) + 
                                 $signed({1'b0, input_vector[j*2 + 1]});
            end
        end
        
        // ================================================
        // Stage 1: Mean adder tree level 2 (8→4)
        // ================================================
        stage[1] <= stage[0];
        if (stage[0].valid) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                mean_tree_4[j] <= mean_tree_8[j*2] + mean_tree_8[j*2 + 1];
            end
        end
        
        // ================================================
        // Stage 2: Mean adder tree level 3 (4→2)
        // ================================================
        stage[2] <= stage[1];
        if (stage[1].valid) begin
            for (integer j = 0; j < 2; j = j + 1) begin
                mean_tree_2[j] <= mean_tree_4[j*2] + mean_tree_4[j*2 + 1];
            end
        end
        
        // ================================================
        // Stage 3: Complete mean calculation μ = sum/16
        // ================================================
        stage[3] <= stage[2];
        if (stage[2].valid) begin
            stage[3].mu <= (mean_tree_2[0] + mean_tree_2[1]) >>> 4;  // Divide by 16
        end
        
        // ================================================
        // Stage 4: Calculate difference (xi - μ)
        // ================================================
        stage[4] <= stage[3];
        if (stage[3].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                stage[4].diff[i] <= $signed({1'b0, stage[3].xi[i]}) - stage[3].mu;
            end
        end
        
        // ================================================
        // Stage 5: Calculate square (xi - μ)²
        // ================================================
        stage[5] <= stage[4];
        if (stage[4].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                diff_squared[i] <= stage[4].diff[i] * stage[4].diff[i];
            end
        end
        
        // ================================================
        // Stage 6: Variance adder tree level 1 (16→8)
        // ================================================
        stage[6] <= stage[5];
        if (stage[5].valid) begin
            for (integer j = 0; j < 8; j = j + 1) begin
                var_tree_8[j] <= diff_squared[j*2] + diff_squared[j*2 + 1];
            end
        end
        
        // ================================================
        // Stage 7: Variance adder tree level 2 (8→4)
        // ================================================
        stage[7] <= stage[6];
        if (stage[6].valid) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                var_tree_4[j] <= var_tree_8[j*2] + var_tree_8[j*2 + 1];
            end
        end
        
        // ================================================
        // Stage 8: Variance adder tree level 3 (4→2)
        // ================================================
        stage[8] <= stage[7];
        if (stage[7].valid) begin
            for (integer j = 0; j < 2; j = j + 1) begin
                var_tree_2[j] <= var_tree_4[j*2] + var_tree_4[j*2 + 1];
            end
        end
        
        // ================================================
        // Stage 9: Complete variance calculation σ² = sum/16 + ε
        // ================================================
        stage[9] <= stage[8];
        if (stage[8].valid) begin
            reg signed [35:0] var_sum;
            var_sum = (var_tree_2[0] + var_tree_2[1]) >>> 4;  // Divide by 16
            stage[9].variance <= var_sum[15:0] + 16'h0001;     // Add epsilon, keep Q12
        end
        
        // ================================================
        // Stage 10: Initial guess x0 (lookup table)
        // ================================================
        stage[10] <= stage[9];
        if (stage[9].valid) begin
            casez (stage[9].variance[15:12])  // Based on high 4 bits
                4'b0000: stage[10].x0 <= 16'h4000;  // 4.0 in Q12
                4'b0001: stage[10].x0 <= 16'h2D41;  // ~2.83 in Q12
                4'b001?: stage[10].x0 <= 16'h2000;  // 2.0 in Q12
                4'b01??: stage[10].x0 <= 16'h1642;  // ~1.41 in Q12
                4'b1???: stage[10].x0 <= 16'h1000;  // 1.0 in Q12
                default: stage[10].x0 <= 16'h0800;  // 0.5 in Q12
            endcase
        end
        
        // ================================================
        // Stage 11: Calculate x0² (one multiplication)
        // ================================================
        stage[11] <= stage[10];
        if (stage[10].valid) begin
            reg signed [31:0] temp;
            temp = stage[10].x0 * stage[10].x0;
            stage[11].x0_sq <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
        end
        
        // ================================================
        // Stage 12: Calculate variance × x0² (one multiplication)
        // ================================================
        stage[12] <= stage[11];
        if (stage[11].valid) begin
            reg signed [31:0] temp;
            temp = stage[11].variance * stage[11].x0_sq;
            stage[12].var_x0_sq <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
        end
        
        // ================================================
        // Stage 13: Calculate 3 - variance×x0² (one subtraction)
        // ================================================
        stage[13] <= stage[12];
        if (stage[12].valid) begin
            stage[13].three_minus_1 <= 16'h3000 - stage[12].var_x0_sq;  // 3.0-result
        end
        
        // ================================================
        // Stage 14: Calculate x1 = x0×(3-variance×x0²)÷2 (one multiplication + shift)
        // ================================================
        stage[14] <= stage[13];
        if (stage[13].valid) begin
            reg signed [31:0] temp;
            temp = stage[13].x0 * stage[13].three_minus_1;
            stage[14].x1 <= temp[28:13];  // Q12*Q12=Q24, right shift 13 bits (12-bit format + 1 bit for divide by 2)
        end
        
        // ================================================
        // Stage 15: Calculate x1² (one multiplication)
        // ================================================
        stage[15] <= stage[14];
        if (stage[14].valid) begin
            reg signed [31:0] temp;
            temp = stage[14].x1 * stage[14].x1;
            stage[15].x1_sq <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
        end
        
        // ================================================
        // Stage 16: Calculate variance × x1² (one multiplication)
        // ================================================
        stage[16] <= stage[15];
        if (stage[15].valid) begin
            reg signed [31:0] temp;
            temp = stage[15].variance * stage[15].x1_sq;
            stage[16].var_x1_sq <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
        end
        
        // ================================================
        // Stage 17: Calculate 3 - variance×x1² (one subtraction)
        // ================================================
        stage[17] <= stage[16];
        if (stage[16].valid) begin
            stage[17].three_minus_2 <= 16'h3000 - stage[16].var_x1_sq;  // 3.0-result
        end
        
        // ================================================
        // Stage 18: Calculate inv_sigma = x1×(3-variance×x1²)÷2 (one multiplication + shift)
        // ================================================
        stage[18] <= stage[17];
        if (stage[17].valid) begin
            reg signed [31:0] temp;
            temp = stage[17].x1 * stage[17].three_minus_2;
            stage[18].inv_sigma <= temp[28:13];  // Q12*Q12=Q24, right shift 13 bits (12-bit format + 1 bit for divide by 2)
        end
        
        // ================================================
        // Stage 19: Normalize normalized = diff × inv_sigma (16 multiplications)
        // ================================================
        stage[19] <= stage[18];
        if (stage[18].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                reg signed [31:0] temp;
                temp = stage[18].diff[i] * stage[18].inv_sigma;
                stage[19].normalized[i] <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
            end
        end
        
        // ================================================
        // Stage 20: Scale scaled = normalized × γ (16 multiplications)
        // ================================================
        stage[20] <= stage[19];
        if (stage[19].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                reg signed [31:0] temp;
                temp = stage[19].normalized[i] * $signed({1'b0, gamma[i]});
                stage[20].scaled[i] <= temp[27:12];  // Q12*Q12=Q24, take middle 16 bits back to Q12
            end
        end
        
        // ================================================
        // Stage 21: Offset output = scaled + β (16 additions) - combinational logic output
        // ================================================
        valid_out <= stage[20].valid;
        if (stage[20].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                output_vector[i] <= stage[20].scaled[i] + $signed({1'b0, beta[i]});
            end
        end
        
    end
end

endmodule