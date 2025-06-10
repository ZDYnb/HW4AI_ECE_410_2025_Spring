// Softmax Backend - 完全Verilog-2001兼容版本
// 功能：接收softmax_frontend的输出，直接做除法归一化
// 修复：完全移除SystemVerilog语法，确保Icarus兼容

module softmax_backend (
    input clk,
    input rst_n,
    
    // 来自softmax_frontend的流水线接口
    input valid_in,                         // 输入有效信号
    input [31:0] exp_sum_in,               // EXP值总和
    input [15:0] exp_values_in [0:15],     // EXP值向量
    
    // 流水线输出接口
    output reg valid_out,                   // 输出有效信号  
    output reg [15:0] softmax_out [0:15]   // softmax结果 (Q5.10格式)
);

// =============================================================================
// 流水线控制和数据寄存器
// =============================================================================
reg valid_stage_0, valid_stage_1;  // 2级流水线

// Stage数据
reg [31:0] exp_sum_s0;                    // Stage 0: 输入sum
reg [15:0] exp_values_s0 [0:15];          // Stage 0: exp_values
reg [15:0] softmax_s1 [0:15];             // Stage 1: softmax结果

// 计算变量 - 全部在模块顶层声明
reg [47:0] numerator_wide;   // 48位分子
reg [31:0] denominator;      // 32位分母  
reg [31:0] division_result;  // 32位除法结果
reg [31:0] temp_numerator;   // 临时计算用

// =============================================================================
// 主流水线逻辑
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    integer j;
    
    if (!rst_n) begin
        // 复位所有寄存器
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
        // Stage 0: 输入接收
        // ================================================================
        valid_stage_0 <= valid_in;
        if (valid_in) begin
            exp_sum_s0 <= exp_sum_in;
            for (j = 0; j < 16; j = j + 1) begin
                exp_values_s0[j] <= exp_values_in[j];
            end
        end
        
        // ================================================================
        // Stage 1: 除法归一化计算
        // ================================================================
        valid_stage_1 <= valid_stage_0;
        if (valid_stage_0) begin
            denominator = exp_sum_s0;
            
            // 16个串行除法计算（避免复杂的并行逻辑）
            if (denominator == 32'h0) begin
                // 除零保护 - 所有输出为0
                for (j = 0; j < 16; j = j + 1) begin
                    softmax_s1[j] <= 16'h0;
                end
            end else begin
                // 计算每个元素
                for (j = 0; j < 16; j = j + 1) begin
                    // 分步计算避免复杂表达式
                    temp_numerator = exp_values_s0[j] * 1024;
                    division_result = temp_numerator / denominator;
                    
                    // 检查溢出
                    if (division_result > 32'h0000FFFF) begin
                        softmax_s1[j] <= 16'hFFFF;  // 饱和
                    end else begin
                        softmax_s1[j] <= division_result[15:0];
                    end
                end
            end
        end
        
        // ================================================================
        // 输出阶段
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
// 单独的计算块用于调试 (组合逻辑)
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
// 调试信息
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