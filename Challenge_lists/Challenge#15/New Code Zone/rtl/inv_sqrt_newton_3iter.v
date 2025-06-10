// 开平方模块 - 12级流水线牛顿法 (Q5.10格式) - 3次迭代
// 功能：计算 1/√variance 
// Stage 0-11: 牛顿法3次迭代求平方根倒数
// 输入：方差 σ² (Q5.10格式)
// 输出：1/σ (Q5.10格式)

module inv_sqrt_newton_3iter (
    input clk,
    input rst_n,
    
    // 输入接口 (来自前处理模块)
    input valid_in,
    input signed [15:0] variance_in,     // 方差 σ² (Q5.10)
    input signed [15:0] mean_in,         // 均值 μ (透传)
    // 差值向量 (透传给后处理模块)
    input signed [15:0] diff_vector_in_0,  input signed [15:0] diff_vector_in_1,
    input signed [15:0] diff_vector_in_2,  input signed [15:0] diff_vector_in_3,
    input signed [15:0] diff_vector_in_4,  input signed [15:0] diff_vector_in_5,
    input signed [15:0] diff_vector_in_6,  input signed [15:0] diff_vector_in_7,
    input signed [15:0] diff_vector_in_8,  input signed [15:0] diff_vector_in_9,
    input signed [15:0] diff_vector_in_10, input signed [15:0] diff_vector_in_11,
    input signed [15:0] diff_vector_in_12, input signed [15:0] diff_vector_in_13,
    input signed [15:0] diff_vector_in_14, input signed [15:0] diff_vector_in_15,
    
    // 输出接口 (传递给后处理模块)
    output reg valid_out,
    output reg signed [15:0] inv_sigma_out,  // 1/σ (Q5.10)
    output reg signed [15:0] mean_out,       // 均值 μ (透传)
    // 差值向量输出 (透传)
    output reg signed [15:0] diff_vector_out_0,  output reg signed [15:0] diff_vector_out_1,
    output reg signed [15:0] diff_vector_out_2,  output reg signed [15:0] diff_vector_out_3,
    output reg signed [15:0] diff_vector_out_4,  output reg signed [15:0] diff_vector_out_5,
    output reg signed [15:0] diff_vector_out_6,  output reg signed [15:0] diff_vector_out_7,
    output reg signed [15:0] diff_vector_out_8,  output reg signed [15:0] diff_vector_out_9,
    output reg signed [15:0] diff_vector_out_10, output reg signed [15:0] diff_vector_out_11,
    output reg signed [15:0] diff_vector_out_12, output reg signed [15:0] diff_vector_out_13,
    output reg signed [15:0] diff_vector_out_14, output reg signed [15:0] diff_vector_out_15
);

// =============================================================================
// Q5.10格式常数定义
// =============================================================================
localparam Q5_10_ONE = 16'h0400;      // 1.0 in Q5.10
localparam Q5_10_THREE = 16'h0C00;    // 3.0 in Q5.10
localparam Q5_10_HALF = 16'h0200;     // 0.5 in Q5.10

// =============================================================================
// 流水线数据结构 - 每个stage保存所有需要的数据
// =============================================================================

// 每个stage的valid信号 (0-11共12级)
reg valid_stage [0:11];

// 透传数据在每个stage的副本
reg signed [15:0] mean_stage [0:11];
reg signed [15:0] diff_stage0 [0:15];  reg signed [15:0] diff_stage1 [0:15];
reg signed [15:0] diff_stage2 [0:15];  reg signed [15:0] diff_stage3 [0:15];
reg signed [15:0] diff_stage4 [0:15];  reg signed [15:0] diff_stage5 [0:15];
reg signed [15:0] diff_stage6 [0:15];  reg signed [15:0] diff_stage7 [0:15];
reg signed [15:0] diff_stage8 [0:15];  reg signed [15:0] diff_stage9 [0:15];
reg signed [15:0] diff_stage10 [0:15]; reg signed [15:0] diff_stage11 [0:15];

// 方差在每个stage的副本
reg signed [15:0] variance_stage [0:11];

// 牛顿法迭代变量
// 第1次迭代 (Stage 0-3)
reg signed [15:0] x0;              // 初始猜测 (Stage 0)
reg signed [15:0] x0_sq;           // x0² (Stage 1)
reg signed [31:0] var_x0_sq_full;  // variance*x0² 完整32位 (Stage 2)
reg signed [15:0] var_x0_sq;       // variance*x0² 截断到Q5.10 (Stage 2)
reg signed [15:0] three_minus_1;   // 3-variance*x0² (Stage 3)

// 第2次迭代 (Stage 4-7)
reg signed [31:0] x1_full;         // x1完整计算结果 (Stage 4)
reg signed [15:0] x1;              // 第1次迭代结果 (Stage 4)
reg signed [15:0] x1_sq;           // x1² (Stage 5)
reg signed [31:0] var_x1_sq_full;  // variance*x1² 完整32位 (Stage 6)
reg signed [15:0] var_x1_sq;       // variance*x1² 截断到Q5.10 (Stage 6)
reg signed [15:0] three_minus_2;   // 3-variance*x1² (Stage 7)

// 第3次迭代 (Stage 8-11)
reg signed [31:0] x2_full;         // x2完整计算结果 (Stage 8)
reg signed [15:0] x2;              // 第2次迭代结果 (Stage 8)
reg signed [15:0] x2_sq;           // x2² (Stage 9)
reg signed [31:0] var_x2_sq_full;  // variance*x2² 完整32位 (Stage 10)
reg signed [15:0] var_x2_sq;       // variance*x2² 截断到Q5.10 (Stage 10)
reg signed [15:0] three_minus_3;   // 3-variance*x2² (Stage 11)

// =============================================================================
// 初始猜测查找表 (改进版，更准确的初始值)
// =============================================================================
function [15:0] get_initial_guess;
    input [15:0] variance;
    begin
        // 更精确的初始猜测，基于1/√x的特性
        casez (variance[15:10])  // 使用更多位进行判断
            6'b000000: get_initial_guess = 16'h8000;  // ~32.0 (极小方差)
            6'b000001: get_initial_guess = 16'h4000;  // ~16.0
            6'b00001?: get_initial_guess = 16'h2000;  // ~8.0
            6'b0001??: get_initial_guess = 16'h1000;  // ~4.0
            6'b001???: get_initial_guess = 16'h0800;  // ~2.0
            6'b01????: get_initial_guess = 16'h0600;  // ~1.5
            6'b1?????: get_initial_guess = 16'h0400;  // ~1.0
            default:   get_initial_guess = 16'h0300;  // ~0.75 (大方差)
        endcase
    end
endfunction

// 临时变量用于乘法计算
reg signed [31:0] temp_mult_1, temp_mult_2, temp_mult_3, temp_mult_4;
reg signed [31:0] temp_mult_5, temp_mult_6, temp_mult_7, temp_mult_8;
reg signed [31:0] inv_sigma_full;

// =============================================================================
// 主流水线逻辑 - 12级流水线
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有valid信号
        integer i;
        for (i = 0; i <= 11; i = i + 1) begin
            valid_stage[i] <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================
        // Stage 0: 保存输入数据 + 初始猜测查表
        // ================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // 保存所有输入数据
            variance_stage[0] <= variance_in;
            mean_stage[0] <= mean_in;
            diff_stage0[0]  <= diff_vector_in_0;  diff_stage0[1]  <= diff_vector_in_1;
            diff_stage0[2]  <= diff_vector_in_2;  diff_stage0[3]  <= diff_vector_in_3;
            diff_stage0[4]  <= diff_vector_in_4;  diff_stage0[5]  <= diff_vector_in_5;
            diff_stage0[6]  <= diff_vector_in_6;  diff_stage0[7]  <= diff_vector_in_7;
            diff_stage0[8]  <= diff_vector_in_8;  diff_stage0[9]  <= diff_vector_in_9;
            diff_stage0[10] <= diff_vector_in_10; diff_stage0[11] <= diff_vector_in_11;
            diff_stage0[12] <= diff_vector_in_12; diff_stage0[13] <= diff_vector_in_13;
            diff_stage0[14] <= diff_vector_in_14; diff_stage0[15] <= diff_vector_in_15;
            
            // 初始猜测查表
            x0 <= get_initial_guess(variance_in);
            
            $display("Stage0: variance_in=0x%04x, x0=0x%04x", variance_in, get_initial_guess(variance_in));
        end
        
        // ================================================
        // Stage 1: 透传数据 + 计算 x0²
        // ================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // 透传数据
            variance_stage[1] <= variance_stage[0];
            mean_stage[1] <= mean_stage[0];
            diff_stage1[0]  <= diff_stage0[0];  diff_stage1[1]  <= diff_stage0[1];
            diff_stage1[2]  <= diff_stage0[2];  diff_stage1[3]  <= diff_stage0[3];
            diff_stage1[4]  <= diff_stage0[4];  diff_stage1[5]  <= diff_stage0[5];
            diff_stage1[6]  <= diff_stage0[6];  diff_stage1[7]  <= diff_stage0[7];
            diff_stage1[8]  <= diff_stage0[8];  diff_stage1[9]  <= diff_stage0[9];
            diff_stage1[10] <= diff_stage0[10]; diff_stage1[11] <= diff_stage0[11];
            diff_stage1[12] <= diff_stage0[12]; diff_stage1[13] <= diff_stage0[13];
            diff_stage1[14] <= diff_stage0[14]; diff_stage1[15] <= diff_stage0[15];
            
            // 计算 x0²
            temp_mult_1 = ($signed(x0) * $signed(x0));
            x0_sq <= temp_mult_1 >>> 10;
            
            $display("Stage1: x0=0x%04x, x0_sq=0x%04x", x0, temp_mult_1 >>> 10);
        end
        
        // ================================================
        // Stage 2: 透传数据 + 计算 variance × x0²
        // ================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // 透传数据
            variance_stage[2] <= variance_stage[1];
            mean_stage[2] <= mean_stage[1];
            diff_stage2[0]  <= diff_stage1[0];  diff_stage2[1]  <= diff_stage1[1];
            diff_stage2[2]  <= diff_stage1[2];  diff_stage2[3]  <= diff_stage1[3];
            diff_stage2[4]  <= diff_stage1[4];  diff_stage2[5]  <= diff_stage1[5];
            diff_stage2[6]  <= diff_stage1[6];  diff_stage2[7]  <= diff_stage1[7];
            diff_stage2[8]  <= diff_stage1[8];  diff_stage2[9]  <= diff_stage1[9];
            diff_stage2[10] <= diff_stage1[10]; diff_stage2[11] <= diff_stage1[11];
            diff_stage2[12] <= diff_stage1[12]; diff_stage2[13] <= diff_stage1[13];
            diff_stage2[14] <= diff_stage1[14]; diff_stage2[15] <= diff_stage1[15];
            
            // 计算 variance × x0²
            temp_mult_2 = $signed(variance_stage[1]) * $signed(x0_sq);
            var_x0_sq_full <= temp_mult_2;
            var_x0_sq <= temp_mult_2 >>> 10;

            $display("Stage2: variance=0x%04x, x0_sq=0x%04x, var_x0_sq=0x%04x", variance_stage[1], x0_sq, temp_mult_2 >>> 10);
        end
        
        // ================================================
        // Stage 3: 透传数据 + 计算 3 - variance×x0²
        // ================================================
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            // 透传数据
            variance_stage[3] <= variance_stage[2];
            mean_stage[3] <= mean_stage[2];
            diff_stage3[0]  <= diff_stage2[0];  diff_stage3[1]  <= diff_stage2[1];
            diff_stage3[2]  <= diff_stage2[2];  diff_stage3[3]  <= diff_stage2[3];
            diff_stage3[4]  <= diff_stage2[4];  diff_stage3[5]  <= diff_stage2[5];
            diff_stage3[6]  <= diff_stage2[6];  diff_stage3[7]  <= diff_stage2[7];
            diff_stage3[8]  <= diff_stage2[8];  diff_stage3[9]  <= diff_stage2[9];
            diff_stage3[10] <= diff_stage2[10]; diff_stage3[11] <= diff_stage2[11];
            diff_stage3[12] <= diff_stage2[12]; diff_stage3[13] <= diff_stage2[13];
            diff_stage3[14] <= diff_stage2[14]; diff_stage3[15] <= diff_stage2[15];
            
            // 计算 3 - variance×x0²
            three_minus_1 <= Q5_10_THREE - var_x0_sq;
            
            $display("Stage3: 3-var_x0_sq=0x%04x", Q5_10_THREE - var_x0_sq);
        end
        
        // ================================================
        // Stage 4: 透传数据 + 计算第1次迭代结果 x1
        // ================================================
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            // 透传数据
            variance_stage[4] <= variance_stage[3];
            mean_stage[4] <= mean_stage[3];
            diff_stage4[0]  <= diff_stage3[0];  diff_stage4[1]  <= diff_stage3[1];
            diff_stage4[2]  <= diff_stage3[2];  diff_stage4[3]  <= diff_stage3[3];
            diff_stage4[4]  <= diff_stage3[4];  diff_stage4[5]  <= diff_stage3[5];
            diff_stage4[6]  <= diff_stage3[6];  diff_stage4[7]  <= diff_stage3[7];
            diff_stage4[8]  <= diff_stage3[8];  diff_stage4[9]  <= diff_stage3[9];
            diff_stage4[10] <= diff_stage3[10]; diff_stage4[11] <= diff_stage3[11];
            diff_stage4[12] <= diff_stage3[12]; diff_stage4[13] <= diff_stage3[13];
            diff_stage4[14] <= diff_stage3[14]; diff_stage4[15] <= diff_stage3[15];
            
            // 计算 x1 = x0×(3-variance×x0²)÷2
            temp_mult_3 = $signed(x0) * $signed(three_minus_1);
            x1_full <= temp_mult_3;
            x1 <= temp_mult_3 >>> 11;  // 右移11位 (10位Q格式 + 1位除2)
            
            $display("Stage4: x1=0x%04x", temp_mult_3 >>> 11);
        end
        
        // ================================================
        // Stage 5: 透传数据 + 计算 x1²
        // ================================================
        valid_stage[5] <= valid_stage[4];
        if (valid_stage[4]) begin
            // 透传数据
            variance_stage[5] <= variance_stage[4];
            mean_stage[5] <= mean_stage[4];
            diff_stage5[0]  <= diff_stage4[0];  diff_stage5[1]  <= diff_stage4[1];
            diff_stage5[2]  <= diff_stage4[2];  diff_stage5[3]  <= diff_stage4[3];
            diff_stage5[4]  <= diff_stage4[4];  diff_stage5[5]  <= diff_stage4[5];
            diff_stage5[6]  <= diff_stage4[6];  diff_stage5[7]  <= diff_stage4[7];
            diff_stage5[8]  <= diff_stage4[8];  diff_stage5[9]  <= diff_stage4[9];
            diff_stage5[10] <= diff_stage4[10]; diff_stage5[11] <= diff_stage4[11];
            diff_stage5[12] <= diff_stage4[12]; diff_stage5[13] <= diff_stage4[13];
            diff_stage5[14] <= diff_stage4[14]; diff_stage5[15] <= diff_stage4[15];
            
            // 计算 x1²
            temp_mult_4 = $signed(x1) * $signed(x1);
            x1_sq <= temp_mult_4 >>> 10;
            
            $display("Stage5: x1_sq=0x%04x", temp_mult_4 >>> 10);
        end
        
        // ================================================
        // Stage 6: 透传数据 + 计算 variance × x1²
        // ================================================
        valid_stage[6] <= valid_stage[5];
        if (valid_stage[5]) begin
            // 透传数据
            variance_stage[6] <= variance_stage[5];
            mean_stage[6] <= mean_stage[5];
            diff_stage6[0]  <= diff_stage5[0];  diff_stage6[1]  <= diff_stage5[1];
            diff_stage6[2]  <= diff_stage5[2];  diff_stage6[3]  <= diff_stage5[3];
            diff_stage6[4]  <= diff_stage5[4];  diff_stage6[5]  <= diff_stage5[5];
            diff_stage6[6]  <= diff_stage5[6];  diff_stage6[7]  <= diff_stage5[7];
            diff_stage6[8]  <= diff_stage5[8];  diff_stage6[9]  <= diff_stage5[9];
            diff_stage6[10] <= diff_stage5[10]; diff_stage6[11] <= diff_stage5[11];
            diff_stage6[12] <= diff_stage5[12]; diff_stage6[13] <= diff_stage5[13];
            diff_stage6[14] <= diff_stage5[14]; diff_stage6[15] <= diff_stage5[15];
            
            // 计算 variance × x1²
            temp_mult_5 = $signed(variance_stage[5]) * $signed(x1_sq);
            var_x1_sq_full <= temp_mult_5;
            var_x1_sq <= temp_mult_5 >>> 10;
            
            $display("Stage6: var_x1_sq=0x%04x", temp_mult_5 >>> 10);
        end
        
        // ================================================
        // Stage 7: 透传数据 + 计算 3 - variance×x1²
        // ================================================
        valid_stage[7] <= valid_stage[6];
        if (valid_stage[6]) begin
            // 透传数据
            variance_stage[7] <= variance_stage[6];
            mean_stage[7] <= mean_stage[6];
            diff_stage7[0]  <= diff_stage6[0];  diff_stage7[1]  <= diff_stage6[1];
            diff_stage7[2]  <= diff_stage6[2];  diff_stage7[3]  <= diff_stage6[3];
            diff_stage7[4]  <= diff_stage6[4];  diff_stage7[5]  <= diff_stage6[5];
            diff_stage7[6]  <= diff_stage6[6];  diff_stage7[7]  <= diff_stage6[7];
            diff_stage7[8]  <= diff_stage6[8];  diff_stage7[9]  <= diff_stage6[9];
            diff_stage7[10] <= diff_stage6[10]; diff_stage7[11] <= diff_stage6[11];
            diff_stage7[12] <= diff_stage6[12]; diff_stage7[13] <= diff_stage6[13];
            diff_stage7[14] <= diff_stage6[14]; diff_stage7[15] <= diff_stage6[15];
            
            // 计算 3 - variance×x1²
            three_minus_2 <= Q5_10_THREE - var_x1_sq;
            
            $display("Stage7: 3-var_x1_sq=0x%04x", Q5_10_THREE - var_x1_sq);
        end
        
        // ================================================
        // Stage 8: 透传数据 + 计算第2次迭代结果 x2
        // ================================================
        valid_stage[8] <= valid_stage[7];
        if (valid_stage[7]) begin
            // 透传数据
            variance_stage[8] <= variance_stage[7];
            mean_stage[8] <= mean_stage[7];
            diff_stage8[0]  <= diff_stage7[0];  diff_stage8[1]  <= diff_stage7[1];
            diff_stage8[2]  <= diff_stage7[2];  diff_stage8[3]  <= diff_stage7[3];
            diff_stage8[4]  <= diff_stage7[4];  diff_stage8[5]  <= diff_stage7[5];
            diff_stage8[6]  <= diff_stage7[6];  diff_stage8[7]  <= diff_stage7[7];
            diff_stage8[8]  <= diff_stage7[8];  diff_stage8[9]  <= diff_stage7[9];
            diff_stage8[10] <= diff_stage7[10]; diff_stage8[11] <= diff_stage7[11];
            diff_stage8[12] <= diff_stage7[12]; diff_stage8[13] <= diff_stage7[13];
            diff_stage8[14] <= diff_stage7[14]; diff_stage8[15] <= diff_stage7[15];
            
            // 计算 x2 = x1×(3-variance×x1²)÷2
            temp_mult_6 = $signed(x1) * $signed(three_minus_2);
            x2_full <= temp_mult_6;
            x2 <= temp_mult_6 >>> 11;
            
            $display("Stage8: x2=0x%04x", temp_mult_6 >>> 11);
        end
        
        // ================================================
        // Stage 9: 透传数据 + 计算 x2²
        // ================================================
        valid_stage[9] <= valid_stage[8];
        if (valid_stage[8]) begin
            // 透传数据
            variance_stage[9] <= variance_stage[8];
            mean_stage[9] <= mean_stage[8];
            diff_stage9[0]  <= diff_stage8[0];  diff_stage9[1]  <= diff_stage8[1];
            diff_stage9[2]  <= diff_stage8[2];  diff_stage9[3]  <= diff_stage8[3];
            diff_stage9[4]  <= diff_stage8[4];  diff_stage9[5]  <= diff_stage8[5];
            diff_stage9[6]  <= diff_stage8[6];  diff_stage9[7]  <= diff_stage8[7];
            diff_stage9[8]  <= diff_stage8[8];  diff_stage9[9]  <= diff_stage8[9];
            diff_stage9[10] <= diff_stage8[10]; diff_stage9[11] <= diff_stage8[11];
            diff_stage9[12] <= diff_stage8[12]; diff_stage9[13] <= diff_stage8[13];
            diff_stage9[14] <= diff_stage8[14]; diff_stage9[15] <= diff_stage8[15];
            
            // 计算 x2²
            temp_mult_7 = $signed(x2) * $signed(x2);
            x2_sq <= temp_mult_7 >>> 10;
            
            $display("Stage9: x2_sq=0x%04x", temp_mult_7 >>> 10);
        end
        
        // ================================================
        // Stage 10: 透传数据 + 计算 variance × x2²
        // ================================================
        valid_stage[10] <= valid_stage[9];
        if (valid_stage[9]) begin
            // 透传数据
            variance_stage[10] <= variance_stage[9];
            mean_stage[10] <= mean_stage[9];
            diff_stage10[0]  <= diff_stage9[0];  diff_stage10[1]  <= diff_stage9[1];
            diff_stage10[2]  <= diff_stage9[2];  diff_stage10[3]  <= diff_stage9[3];
            diff_stage10[4]  <= diff_stage9[4];  diff_stage10[5]  <= diff_stage9[5];
            diff_stage10[6]  <= diff_stage9[6];  diff_stage10[7]  <= diff_stage9[7];
            diff_stage10[8]  <= diff_stage9[8];  diff_stage10[9]  <= diff_stage9[9];
            diff_stage10[10] <= diff_stage9[10]; diff_stage10[11] <= diff_stage9[11];
            diff_stage10[12] <= diff_stage9[12]; diff_stage10[13] <= diff_stage9[13];
            diff_stage10[14] <= diff_stage9[14]; diff_stage10[15] <= diff_stage9[15];
            
            // 计算 variance × x2²
            temp_mult_8 = $signed(variance_stage[9]) * $signed(x2_sq);
            var_x2_sq_full <= temp_mult_8;
            var_x2_sq <= temp_mult_8 >>> 10;
            
            $display("Stage10: var_x2_sq=0x%04x", temp_mult_8 >>> 10);
        end
        
        // ================================================
        // Stage 11: 透传数据 + 计算 3 - variance×x2²
        // ================================================
        valid_stage[11] <= valid_stage[10];
        if (valid_stage[10]) begin
            // 透传数据
            mean_stage[11] <= mean_stage[10];
            diff_stage11[0]  <= diff_stage10[0];  diff_stage11[1]  <= diff_stage10[1];
            diff_stage11[2]  <= diff_stage10[2];  diff_stage11[3]  <= diff_stage10[3];
            diff_stage11[4]  <= diff_stage10[4];  diff_stage11[5]  <= diff_stage10[5];
            diff_stage11[6]  <= diff_stage10[6];  diff_stage11[7]  <= diff_stage10[7];
            diff_stage11[8]  <= diff_stage10[8];  diff_stage11[9]  <= diff_stage10[9];
            diff_stage11[10] <= diff_stage10[10]; diff_stage11[11] <= diff_stage10[11];
            diff_stage11[12] <= diff_stage10[12]; diff_stage11[13] <= diff_stage10[13];
            diff_stage11[14] <= diff_stage10[14]; diff_stage11[15] <= diff_stage10[15];
            
            // 计算 3 - variance×x2²
            three_minus_3 <= Q5_10_THREE - var_x2_sq;
            
            $display("Stage11: 3-var_x2_sq=0x%04x", Q5_10_THREE - var_x2_sq);
        end
        
        // ================================================
        // 输出: 计算最终结果 inv_sigma = x2×(3-variance×x2²)÷2
        // ================================================
        valid_out <= valid_stage[11];
        if (valid_stage[11]) begin
            // 计算最终的1/σ = x2×(3-variance×x2²)÷2 (第3次迭代)
            inv_sigma_full = $signed(x2) * $signed(three_minus_3);
            inv_sigma_out <= inv_sigma_full >>> 11;  // 右移11位 (10位Q格式 + 1位除2)
            
            $display("Output: x2=0x%04x, three_minus_3=0x%04x, inv_sigma_out=0x%04x", x2, three_minus_3, inv_sigma_full >>> 11);
            
            // 透传其他数据给后处理模块
            mean_out <= mean_stage[11];
            diff_vector_out_0  <= diff_stage11[0];  diff_vector_out_1  <= diff_stage11[1];
            diff_vector_out_2  <= diff_stage11[2];  diff_vector_out_3  <= diff_stage11[3];
            diff_vector_out_4  <= diff_stage11[4];  diff_vector_out_5  <= diff_stage11[5];
            diff_vector_out_6  <= diff_stage11[6];  diff_vector_out_7  <= diff_stage11[7];
            diff_vector_out_8  <= diff_stage11[8];  diff_vector_out_9  <= diff_stage11[9];
            diff_vector_out_10 <= diff_stage11[10]; diff_vector_out_11 <= diff_stage11[11];
            diff_vector_out_12 <= diff_stage11[12]; diff_vector_out_13 <= diff_stage11[13];
            diff_vector_out_14 <= diff_stage11[14]; diff_vector_out_15 <= diff_stage11[15];
        end
        
    end
end

endmodule