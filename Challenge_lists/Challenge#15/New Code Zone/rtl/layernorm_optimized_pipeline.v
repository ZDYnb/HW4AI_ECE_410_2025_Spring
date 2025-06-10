// LayerNorm 21级流水线处理器 - 完全重写
// 每个阶段只执行一个操作，统一使用16位Q12格式

module layernorm_optimized_pipeline (
    input clk,
    input rst_n,
    
    // 向量流接口
    input valid_in,
    output reg valid_out,
    input [15:0] input_vector [0:15],
    output reg [15:0] output_vector [0:15],
    
    // 参数
    input [15:0] gamma [0:15], 
    input [15:0] beta [0:15]
);

// =============================================================================
// 流水线数据结构 - 所有数据统一16位Q12格式
// =============================================================================
typedef struct packed {
    reg [15:0] xi [0:15];           // 原始输入向量 (Q12)
    reg signed [15:0] mu;           // 均值 (Q12)
    reg signed [15:0] diff [0:15];  // 差值向量 (Q12) 
    reg signed [15:0] variance;     // 方差 (Q12)
    reg signed [15:0] x0;           // 初始猜测 (Q12)
    reg signed [15:0] x0_sq;        // x0² (Q12)
    reg signed [15:0] var_x0_sq;    // variance*x0² (Q12)
    reg signed [15:0] three_minus_1; // 3-variance*x0² (Q12)
    reg signed [15:0] x1;           // 第1次迭代 (Q12)
    reg signed [15:0] x1_sq;        // x1² (Q12)
    reg signed [15:0] var_x1_sq;    // variance*x1² (Q12)
    reg signed [15:0] three_minus_2; // 3-variance*x1² (Q12)
    reg signed [15:0] inv_sigma;    // 最终1/σ (Q12)
    reg signed [15:0] normalized [0:15]; // 标准化结果 (Q12)
    reg signed [15:0] scaled [0:15];     // 缩放结果 (Q12)
    reg valid;
} pipeline_data_t;

// 流水线各阶段
pipeline_data_t stage [0:20];  // 21级流水线

// =============================================================================
// 均值计算的中间结果
// =============================================================================
reg signed [16:0] mean_tree_8 [0:7];    // 阶段0: 16→8
reg signed [17:0] mean_tree_4 [0:3];    // 阶段1: 8→4  
reg signed [18:0] mean_tree_2 [0:1];    // 阶段2: 4→2

// =============================================================================
// 方差计算的中间结果
// =============================================================================
reg signed [31:0] diff_squared [0:15];   // 阶段5: (xi-μ)²
reg signed [32:0] var_tree_8 [0:7];      // 阶段6: 16→8
reg signed [33:0] var_tree_4 [0:3];      // 阶段7: 8→4
reg signed [34:0] var_tree_2 [0:1];      // 阶段8: 4→2

// =============================================================================
// 主流水线逻辑
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有流水线阶段
        for (integer i = 0; i <= 20; i = i + 1) begin
            stage[i].valid <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================
        // 阶段0：均值加法树第1级 (16→8)
        // ================================================
        stage[0].valid <= valid_in;
        if (valid_in) begin
            // 保存输入向量
            for (integer i = 0; i < 16; i = i + 1) begin
                stage[0].xi[i] <= input_vector[i];
            end
            
            // 第1级加法树：16→8
            for (integer j = 0; j < 8; j = j + 1) begin
                mean_tree_8[j] <= $signed({1'b0, input_vector[j*2]}) + 
                                 $signed({1'b0, input_vector[j*2 + 1]});
            end
        end
        
        // ================================================
        // 阶段1：均值加法树第2级 (8→4)
        // ================================================
        stage[1] <= stage[0];
        if (stage[0].valid) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                mean_tree_4[j] <= mean_tree_8[j*2] + mean_tree_8[j*2 + 1];
            end
        end
        
        // ================================================
        // 阶段2：均值加法树第3级 (4→2)
        // ================================================
        stage[2] <= stage[1];
        if (stage[1].valid) begin
            for (integer j = 0; j < 2; j = j + 1) begin
                mean_tree_2[j] <= mean_tree_4[j*2] + mean_tree_4[j*2 + 1];
            end
        end
        
        // ================================================
        // 阶段3：完成均值计算 μ = sum/16
        // ================================================
        stage[3] <= stage[2];
        if (stage[2].valid) begin
            stage[3].mu <= (mean_tree_2[0] + mean_tree_2[1]) >>> 4;  // 除以16
        end
        
        // ================================================
        // 阶段4：计算差值 (xi - μ)
        // ================================================
        stage[4] <= stage[3];
        if (stage[3].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                stage[4].diff[i] <= $signed({1'b0, stage[3].xi[i]}) - stage[3].mu;
            end
        end
        
        // ================================================
        // 阶段5：计算平方 (xi - μ)²
        // ================================================
        stage[5] <= stage[4];
        if (stage[4].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                diff_squared[i] <= stage[4].diff[i] * stage[4].diff[i];
            end
        end
        
        // ================================================
        // 阶段6：方差加法树第1级 (16→8)
        // ================================================
        stage[6] <= stage[5];
        if (stage[5].valid) begin
            for (integer j = 0; j < 8; j = j + 1) begin
                var_tree_8[j] <= diff_squared[j*2] + diff_squared[j*2 + 1];
            end
        end
        
        // ================================================
        // 阶段7：方差加法树第2级 (8→4)
        // ================================================
        stage[7] <= stage[6];
        if (stage[6].valid) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                var_tree_4[j] <= var_tree_8[j*2] + var_tree_8[j*2 + 1];
            end
        end
        
        // ================================================
        // 阶段8：方差加法树第3级 (4→2)
        // ================================================
        stage[8] <= stage[7];
        if (stage[7].valid) begin
            for (integer j = 0; j < 2; j = j + 1) begin
                var_tree_2[j] <= var_tree_4[j*2] + var_tree_4[j*2 + 1];
            end
        end
        
        // ================================================
        // 阶段9：完成方差计算 σ² = sum/16 + ε
        // ================================================
        stage[9] <= stage[8];
        if (stage[8].valid) begin
            reg signed [35:0] var_sum;
            var_sum = (var_tree_2[0] + var_tree_2[1]) >>> 4;  // 除以16
            stage[9].variance <= var_sum[15:0] + 16'h0001;     // 加epsilon，保持Q12
        end
        
        // ================================================
        // 阶段10：初始猜测 x0 (查表)
        // ================================================
        stage[10] <= stage[9];
        if (stage[9].valid) begin
            casez (stage[9].variance[15:12])  // 基于高4位
                4'b0000: stage[10].x0 <= 16'h4000;  // 4.0 in Q12
                4'b0001: stage[10].x0 <= 16'h2D41;  // ~2.83 in Q12
                4'b001?: stage[10].x0 <= 16'h2000;  // 2.0 in Q12
                4'b01??: stage[10].x0 <= 16'h1642;  // ~1.41 in Q12
                4'b1???: stage[10].x0 <= 16'h1000;  // 1.0 in Q12
                default: stage[10].x0 <= 16'h0800;  // 0.5 in Q12
            endcase
        end
        
        // ================================================
        // 阶段11：计算 x0² (一个乘法)
        // ================================================
        stage[11] <= stage[10];
        if (stage[10].valid) begin
            reg signed [31:0] temp;
            temp = stage[10].x0 * stage[10].x0;
            stage[11].x0_sq <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
        end
        
        // ================================================
        // 阶段12：计算 variance × x0² (一个乘法)
        // ================================================
        stage[12] <= stage[11];
        if (stage[11].valid) begin
            reg signed [31:0] temp;
            temp = stage[11].variance * stage[11].x0_sq;
            stage[12].var_x0_sq <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
        end
        
        // ================================================
        // 阶段13：计算 3 - variance×x0² (一个减法)
        // ================================================
        stage[13] <= stage[12];
        if (stage[12].valid) begin
            stage[13].three_minus_1 <= 16'h3000 - stage[12].var_x0_sq;  // 3.0-result
        end
        
        // ================================================
        // 阶段14：计算 x1 = x0×(3-variance×x0²)÷2 (一个乘法+移位)
        // ================================================
        stage[14] <= stage[13];
        if (stage[13].valid) begin
            reg signed [31:0] temp;
            temp = stage[13].x0 * stage[13].three_minus_1;
            stage[14].x1 <= temp[28:13];  // Q12*Q12=Q24, 右移13位(12位格式+1位除以2)
        end
        
        // ================================================
        // 阶段15：计算 x1² (一个乘法)
        // ================================================
        stage[15] <= stage[14];
        if (stage[14].valid) begin
            reg signed [31:0] temp;
            temp = stage[14].x1 * stage[14].x1;
            stage[15].x1_sq <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
        end
        
        // ================================================
        // 阶段16：计算 variance × x1² (一个乘法)
        // ================================================
        stage[16] <= stage[15];
        if (stage[15].valid) begin
            reg signed [31:0] temp;
            temp = stage[15].variance * stage[15].x1_sq;
            stage[16].var_x1_sq <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
        end
        
        // ================================================
        // 阶段17：计算 3 - variance×x1² (一个减法)
        // ================================================
        stage[17] <= stage[16];
        if (stage[16].valid) begin
            stage[17].three_minus_2 <= 16'h3000 - stage[16].var_x1_sq;  // 3.0-result
        end
        
        // ================================================
        // 阶段18：计算 inv_sigma = x1×(3-variance×x1²)÷2 (一个乘法+移位)
        // ================================================
        stage[18] <= stage[17];
        if (stage[17].valid) begin
            reg signed [31:0] temp;
            temp = stage[17].x1 * stage[17].three_minus_2;
            stage[18].inv_sigma <= temp[28:13];  // Q12*Q12=Q24, 右移13位(12位格式+1位除以2)
        end
        
        // ================================================
        // 阶段19：标准化 normalized = diff × inv_sigma (16个乘法)
        // ================================================
        stage[19] <= stage[18];
        if (stage[18].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                reg signed [31:0] temp;
                temp = stage[18].diff[i] * stage[18].inv_sigma;
                stage[19].normalized[i] <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
            end
        end
        
        // ================================================
        // 阶段20：缩放 scaled = normalized × γ (16个乘法)
        // ================================================
        stage[20] <= stage[19];
        if (stage[19].valid) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                reg signed [31:0] temp;
                temp = stage[19].normalized[i] * $signed({1'b0, gamma[i]});
                stage[20].scaled[i] <= temp[27:12];  // Q12*Q12=Q24, 取中间16位回Q12
            end
        end
        
        // ================================================
        // 阶段21：偏移 output = scaled + β (16个加法) - 组合逻辑输出
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