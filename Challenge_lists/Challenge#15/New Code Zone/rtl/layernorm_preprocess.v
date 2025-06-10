// LayerNorm前处理模块 - 9级流水线 (Q5.10格式)
// 功能：计算均值、方差和差值向量
// Stage 0-8: 均值计算(4级) + 方差计算(5级)
// 数据格式：Q5.10 (1符号位 + 5整数位 + 10小数位)

module layernorm_preprocess (
    input clk,
    input rst_n,
    
    // 输入接口 (Q5.10格式)
    input valid_in,
    input [15:0] input_vector_0,  input [15:0] input_vector_1,
    input [15:0] input_vector_2,  input [15:0] input_vector_3,
    input [15:0] input_vector_4,  input [15:0] input_vector_5,
    input [15:0] input_vector_6,  input [15:0] input_vector_7,
    input [15:0] input_vector_8,  input [15:0] input_vector_9,
    input [15:0] input_vector_10, input [15:0] input_vector_11,
    input [15:0] input_vector_12, input [15:0] input_vector_13,
    input [15:0] input_vector_14, input [15:0] input_vector_15,
    
    // 输出接口 (Q5.10格式)
    output reg valid_out,
    output reg signed [15:0] mean_out,      // 均值 μ
    output reg signed [15:0] variance_out,  // 方差 σ²
    // 差值向量 (xi - μ)，传递给后续模块
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
// Q5.10格式常数定义
// =============================================================================
localparam Q5_10_EPSILON = 16'h0001;  // epsilon = 1/1024 ≈ 0.001

// =============================================================================
// 流水线数据结构 - 每个stage保存所有需要的数据
// =============================================================================

// 每个stage的valid信号
reg valid_stage [0:8];

// 原始输入向量在每个stage的副本
reg [15:0] xi_stage0 [0:15];
reg [15:0] xi_stage1 [0:15];
reg [15:0] xi_stage2 [0:15];
reg [15:0] xi_stage3 [0:15];
reg [15:0] xi_stage4 [0:15];
reg [15:0] xi_stage5 [0:15];
reg [15:0] xi_stage6 [0:15];
reg [15:0] xi_stage7 [0:15];
reg [15:0] xi_stage8 [0:15];

// 均值在每个stage的副本（从stage3开始有效）
reg signed [15:0] mu_stage3;
reg signed [15:0] mu_stage4;
reg signed [15:0] mu_stage5;
reg signed [15:0] mu_stage6;
reg signed [15:0] mu_stage7;
reg signed [15:0] mu_stage8;

// 差值向量在每个stage的副本（从stage4开始有效）
reg signed [15:0] diff_stage4 [0:15];
reg signed [15:0] diff_stage5 [0:15];
reg signed [15:0] diff_stage6 [0:15];
reg signed [15:0] diff_stage7 [0:15];
reg signed [15:0] diff_stage8 [0:15];

// =============================================================================
// 均值计算的中间结果
// =============================================================================
// Stage 0: 16→8 (扩展到17位防止溢出)
reg signed [16:0] mean_tree_8 [0:7];
// Stage 1: 8→4 (扩展到18位)
reg signed [17:0] mean_tree_4 [0:3];
// Stage 2: 4→2 (扩展到19位)
reg signed [18:0] mean_tree_2 [0:1];

// =============================================================================
// 方差计算的中间结果
// =============================================================================
// Stage 5: 平方计算 (Q5.10 * Q5.10 = Q10.20，取高16位)
reg signed [31:0] diff_squared [0:15];
// Stage 6: 方差加法树 16→8
reg signed [32:0] var_tree_8 [0:7];
// Stage 7: 方差加法树 8→4
reg signed [33:0] var_tree_4 [0:3];
// Stage 8: 方差加法树 4→2
reg signed [34:0] var_tree_2 [0:1];

// =============================================================================
// 主流水线逻辑
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有valid信号
        integer i;
        for (i = 0; i <= 8; i = i + 1) begin
            valid_stage[i] <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================
        // Stage 0: 保存输入向量 + 均值加法树第1级 (16→8)
        // ================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // 保存原始输入向量
            xi_stage0[0]  <= input_vector_0;  xi_stage0[1]  <= input_vector_1;
            xi_stage0[2]  <= input_vector_2;  xi_stage0[3]  <= input_vector_3;
            xi_stage0[4]  <= input_vector_4;  xi_stage0[5]  <= input_vector_5;
            xi_stage0[6]  <= input_vector_6;  xi_stage0[7]  <= input_vector_7;
            xi_stage0[8]  <= input_vector_8;  xi_stage0[9]  <= input_vector_9;
            xi_stage0[10] <= input_vector_10; xi_stage0[11] <= input_vector_11;
            xi_stage0[12] <= input_vector_12; xi_stage0[13] <= input_vector_13;
            xi_stage0[14] <= input_vector_14; xi_stage0[15] <= input_vector_15;
            
            // 均值加法树第1级 (符号扩展到17位)
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
        // Stage 1: 传递数据 + 均值加法树第2级 (8→4)
        // ================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // 传递原始向量
            xi_stage1[0]  <= xi_stage0[0];  xi_stage1[1]  <= xi_stage0[1];
            xi_stage1[2]  <= xi_stage0[2];  xi_stage1[3]  <= xi_stage0[3];
            xi_stage1[4]  <= xi_stage0[4];  xi_stage1[5]  <= xi_stage0[5];
            xi_stage1[6]  <= xi_stage0[6];  xi_stage1[7]  <= xi_stage0[7];
            xi_stage1[8]  <= xi_stage0[8];  xi_stage1[9]  <= xi_stage0[9];
            xi_stage1[10] <= xi_stage0[10]; xi_stage1[11] <= xi_stage0[11];
            xi_stage1[12] <= xi_stage0[12]; xi_stage1[13] <= xi_stage0[13];
            xi_stage1[14] <= xi_stage0[14]; xi_stage1[15] <= xi_stage0[15];
            
            // 均值加法树第2级
            mean_tree_4[0] <= mean_tree_8[0] + mean_tree_8[1];
            mean_tree_4[1] <= mean_tree_8[2] + mean_tree_8[3];
            mean_tree_4[2] <= mean_tree_8[4] + mean_tree_8[5];
            mean_tree_4[3] <= mean_tree_8[6] + mean_tree_8[7];
        end
        
        // ================================================
        // Stage 2: 传递数据 + 均值加法树第3级 (4→2)
        // ================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // 传递原始向量
            xi_stage2[0]  <= xi_stage1[0];  xi_stage2[1]  <= xi_stage1[1];
            xi_stage2[2]  <= xi_stage1[2];  xi_stage2[3]  <= xi_stage1[3];
            xi_stage2[4]  <= xi_stage1[4];  xi_stage2[5]  <= xi_stage1[5];
            xi_stage2[6]  <= xi_stage1[6];  xi_stage2[7]  <= xi_stage1[7];
            xi_stage2[8]  <= xi_stage1[8];  xi_stage2[9]  <= xi_stage1[9];
            xi_stage2[10] <= xi_stage1[10]; xi_stage2[11] <= xi_stage1[11];
            xi_stage2[12] <= xi_stage1[12]; xi_stage2[13] <= xi_stage1[13];
            xi_stage2[14] <= xi_stage1[14]; xi_stage2[15] <= xi_stage1[15];
            
            // 均值加法树第3级
            mean_tree_2[0] <= mean_tree_4[0] + mean_tree_4[1];
            mean_tree_2[1] <= mean_tree_4[2] + mean_tree_4[3];
        end
        
        // ================================================
        // Stage 3: 传递数据 + 完成均值计算 μ = sum/16
        // ================================================
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            // 传递原始向量
            xi_stage3[0]  <= xi_stage2[0];  xi_stage3[1]  <= xi_stage2[1];
            xi_stage3[2]  <= xi_stage2[2];  xi_stage3[3]  <= xi_stage2[3];
            xi_stage3[4]  <= xi_stage2[4];  xi_stage3[5]  <= xi_stage2[5];
            xi_stage3[6]  <= xi_stage2[6];  xi_stage3[7]  <= xi_stage2[7];
            xi_stage3[8]  <= xi_stage2[8];  xi_stage3[9]  <= xi_stage2[9];
            xi_stage3[10] <= xi_stage2[10]; xi_stage3[11] <= xi_stage2[11];
            xi_stage3[12] <= xi_stage2[12]; xi_stage3[13] <= xi_stage2[13];
            xi_stage3[14] <= xi_stage2[14]; xi_stage3[15] <= xi_stage2[15];
            
            // 计算均值：sum/16，保持Q5.10格式
            mu_stage3 <= (mean_tree_2[0] + mean_tree_2[1]) >>> 4;  // 除以16
        end
        
        // ================================================
        // Stage 4: 传递数据 + 计算差值 (xi - μ)
        // ================================================
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            // 传递原始向量
            xi_stage4[0]  <= xi_stage3[0];  xi_stage4[1]  <= xi_stage3[1];
            xi_stage4[2]  <= xi_stage3[2];  xi_stage4[3]  <= xi_stage3[3];
            xi_stage4[4]  <= xi_stage3[4];  xi_stage4[5]  <= xi_stage3[5];
            xi_stage4[6]  <= xi_stage3[6];  xi_stage4[7]  <= xi_stage3[7];
            xi_stage4[8]  <= xi_stage3[8];  xi_stage4[9]  <= xi_stage3[9];
            xi_stage4[10] <= xi_stage3[10]; xi_stage4[11] <= xi_stage3[11];
            xi_stage4[12] <= xi_stage3[12]; xi_stage4[13] <= xi_stage3[13];
            xi_stage4[14] <= xi_stage3[14]; xi_stage4[15] <= xi_stage3[15];
            
            // 传递均值
            mu_stage4 <= mu_stage3;
            
            // 计算差值 (xi - μ) in Q5.10
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
        // Stage 5: 传递数据 + 计算平方 (xi - μ)²
        // ================================================
        valid_stage[5] <= valid_stage[4];
        if (valid_stage[4]) begin
            // 传递数据
            mu_stage5 <= mu_stage4;
            diff_stage5[0]  <= diff_stage4[0];  diff_stage5[1]  <= diff_stage4[1];
            diff_stage5[2]  <= diff_stage4[2];  diff_stage5[3]  <= diff_stage4[3];
            diff_stage5[4]  <= diff_stage4[4];  diff_stage5[5]  <= diff_stage4[5];
            diff_stage5[6]  <= diff_stage4[6];  diff_stage5[7]  <= diff_stage4[7];
            diff_stage5[8]  <= diff_stage4[8];  diff_stage5[9]  <= diff_stage4[9];
            diff_stage5[10] <= diff_stage4[10]; diff_stage5[11] <= diff_stage4[11];
            diff_stage5[12] <= diff_stage4[12]; diff_stage5[13] <= diff_stage4[13];
            diff_stage5[14] <= diff_stage4[14]; diff_stage5[15] <= diff_stage4[15];
            
            // 计算平方：Q5.10 * Q5.10 = Q10.20，需要调整回Q5.10
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
        // Stage 6: 传递数据 + 方差加法树第1级 (16→8)
        // ================================================
        valid_stage[6] <= valid_stage[5];
        if (valid_stage[5]) begin
            // 传递数据
            mu_stage6 <= mu_stage5;
            diff_stage6[0]  <= diff_stage5[0];  diff_stage6[1]  <= diff_stage5[1];
            diff_stage6[2]  <= diff_stage5[2];  diff_stage6[3]  <= diff_stage5[3];
            diff_stage6[4]  <= diff_stage5[4];  diff_stage6[5]  <= diff_stage5[5];
            diff_stage6[6]  <= diff_stage5[6];  diff_stage6[7]  <= diff_stage5[7];
            diff_stage6[8]  <= diff_stage5[8];  diff_stage6[9]  <= diff_stage5[9];
            diff_stage6[10] <= diff_stage5[10]; diff_stage6[11] <= diff_stage5[11];
            diff_stage6[12] <= diff_stage5[12]; diff_stage6[13] <= diff_stage5[13];
            diff_stage6[14] <= diff_stage5[14]; diff_stage6[15] <= diff_stage5[15];
            
            // 方差加法树第1级：取平方结果的高位部分
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
        // Stage 7: 传递数据 + 方差加法树第2级 (8→4)
        // ================================================
        valid_stage[7] <= valid_stage[6];
        if (valid_stage[6]) begin
            // 传递数据
            mu_stage7 <= mu_stage6;
            diff_stage7[0]  <= diff_stage6[0];  diff_stage7[1]  <= diff_stage6[1];
            diff_stage7[2]  <= diff_stage6[2];  diff_stage7[3]  <= diff_stage6[3];
            diff_stage7[4]  <= diff_stage6[4];  diff_stage7[5]  <= diff_stage6[5];
            diff_stage7[6]  <= diff_stage6[6];  diff_stage7[7]  <= diff_stage6[7];
            diff_stage7[8]  <= diff_stage6[8];  diff_stage7[9]  <= diff_stage6[9];
            diff_stage7[10] <= diff_stage6[10]; diff_stage7[11] <= diff_stage6[11];
            diff_stage7[12] <= diff_stage6[12]; diff_stage7[13] <= diff_stage6[13];
            diff_stage7[14] <= diff_stage6[14]; diff_stage7[15] <= diff_stage6[15];
            
            // 方差加法树第2级
            var_tree_4[0] <= var_tree_8[0] + var_tree_8[1];
            var_tree_4[1] <= var_tree_8[2] + var_tree_8[3];
            var_tree_4[2] <= var_tree_8[4] + var_tree_8[5];
            var_tree_4[3] <= var_tree_8[6] + var_tree_8[7];
        end
        
        // ================================================
        // Stage 8: 传递数据 + 方差加法树第3级 (4→2) + 最终计算
        // ================================================
        valid_stage[8] <= valid_stage[7];
        if (valid_stage[7]) begin
            // 传递数据
            mu_stage8 <= mu_stage7;
            diff_stage8[0]  <= diff_stage7[0];  diff_stage8[1]  <= diff_stage7[1];
            diff_stage8[2]  <= diff_stage7[2];  diff_stage8[3]  <= diff_stage7[3];
            diff_stage8[4]  <= diff_stage7[4];  diff_stage8[5]  <= diff_stage7[5];
            diff_stage8[6]  <= diff_stage7[6];  diff_stage8[7]  <= diff_stage7[7];
            diff_stage8[8]  <= diff_stage7[8];  diff_stage8[9]  <= diff_stage7[9];
            diff_stage8[10] <= diff_stage7[10]; diff_stage8[11] <= diff_stage7[11];
            diff_stage8[12] <= diff_stage7[12]; diff_stage8[13] <= diff_stage7[13];
            diff_stage8[14] <= diff_stage7[14]; diff_stage8[15] <= diff_stage7[15];
            
            // 方差加法树第3级
            var_tree_2[0] <= var_tree_4[0] + var_tree_4[1];
            var_tree_2[1] <= var_tree_4[2] + var_tree_4[3];
        end
        
        // ================================================
        // 输出: 完成方差计算并输出所有结果
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