// Reciprocal Divider - 简化版真流水线 (Q5.10格式)  
// 功能：计算 1/exp_sum，使用简化的移位除法
// 输入：exp_sum (来自softmax_frontend)
// 输出：reciprocal + exp_values传递
// 流水线：3级简单流水线

module reciprocal_divider (
    input clk,
    input rst_n,
    
    // 来自softmax_frontend的流水线接口
    input valid_in,                         // 输入有效信号
    input [31:0] exp_sum_in,               // 除数 (分母)
    input [15:0] exp_values_in [0:15],     // exp_values传递
    
    // 到softmax_backend的流水线接口
    output reg valid_out,                   // 输出有效信号
    output reg [15:0] reciprocal_out,      // 倒数结果 (Q5.10)
    output reg [15:0] exp_values_out [0:15] // exp_values传递
);

// =============================================================================
// 简化方案：用近似算法
// 对于softmax，我们知道exp_sum的大致范围，可以用查表+调整的方法
// =============================================================================

// 流水线控制
reg valid_stage [0:2];  // 3级流水线

// Stage数据
reg [19:0] exp_sum_s0;                    // Stage 0: 输入sum (取低20位)
reg [15:0] exp_values_s0 [0:15];          // Stage 0: exp_values

reg [15:0] reciprocal_approx_s1;          // Stage 1: 近似倒数
reg [15:0] exp_values_s1 [0:15];          // Stage 1: exp_values

reg [15:0] reciprocal_final_s2;           // Stage 2: 最终倒数
reg [15:0] exp_values_s2 [0:15];          // Stage 2: exp_values

// =============================================================================
// 主流水线逻辑
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    integer j;
    
    if (!rst_n) begin
        // 复位
        valid_stage[0] <= 1'b0;
        valid_stage[1] <= 1'b0; 
        valid_stage[2] <= 1'b0;
        valid_out <= 1'b0;
        reciprocal_out <= 16'h0;
        
    end else begin
        
        // ================================================================
        // Stage 0: 输入接收
        // ================================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // 保存输入数据
            exp_sum_s0 <= exp_sum_in[19:0];  // 取低20位
            
            // 传递exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s0[j] <= exp_values_in[j];
            end
        end
        
        // ================================================================
        // Stage 1: 简单倒数计算
        // ================================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // 正确的倒数计算：
            // 我们要计算 1/exp_sum，结果在Q5.10格式
            // Q5.10格式中，1.0 = 1024
            // 所以 1/exp_sum = 1024*1024 / exp_sum = 1048576 / exp_sum
            
            reg [31:0] dividend;
            reg [19:0] divisor;
            reg [15:0] result;
            
            dividend = 32'h00100000;  // 1048576 = 1024*1024 
            divisor = exp_sum_s0;
            
            // 简单除法：检查除数不为0
            if (divisor == 0) begin
                result = 16'hFFFF;  // 除零保护
            end else if (divisor > dividend) begin
                result = 16'h0001;  // 结果小于1，给最小值
            end else begin
                // 执行除法
                result = dividend / divisor;
                // 限制在16位范围内
                if (result > 16'hFFFF) begin
                    result = 16'hFFFF;
                end
            end
            
            reciprocal_approx_s1 <= result;
            
            // 传递exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s1[j] <= exp_values_s0[j];
            end
        end
        
        // ================================================================
        // Stage 2: 输出准备 (可以加调整)
        // ================================================================  
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // 直接输出近似结果 (可以在这里加细调)
            reciprocal_final_s2 <= reciprocal_approx_s1;
            
            // 传递exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s2[j] <= exp_values_s1[j];
            end
        end
        
        // ================================================================
        // 输出阶段
        // ================================================================
        valid_out <= valid_stage[2];
        if (valid_stage[2]) begin
            reciprocal_out <= reciprocal_final_s2;
            
            // 输出exp_values
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_out[j] <= exp_values_s2[j];
            end
        end
        
    end
end

// =============================================================================
// 调试信息
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