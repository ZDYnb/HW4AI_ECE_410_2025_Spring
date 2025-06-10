// Complete Softmax Processor - Top Module (Q5.10格式)
// 功能：连接softmax_frontend和softmax_backend
// 总延迟：8周期(frontend) + 2周期(backend) = 10周期

module softmax_processor (
    input clk,
    input rst_n,
    
    // 流水线控制接口
    input valid_in,                     // 输入有效信号
    input [15:0] input_vector [0:15],   // 输入向量 (Q5.10格式)
    
    // 流水线输出接口  
    output valid_out,                   // 输出有效信号
    output [15:0] softmax_out [0:15]    // softmax结果 (Q5.10格式)
);

// =============================================================================
// 连接frontend和backend的信号
// =============================================================================
wire frontend_valid;
wire [31:0] frontend_exp_sum;
wire [15:0] frontend_exp_values [0:15];

// =============================================================================
// Softmax Frontend实例 - EXP LUT + Tree Adder
// =============================================================================
softmax_frontend u_frontend (
    .clk(clk),
    .rst_n(rst_n),
    
    // 输入
    .valid_in(valid_in),
    .input_vector(input_vector),
    
    // 输出 (连接到backend)
    .valid_out(frontend_valid),
    .exp_sum(frontend_exp_sum),
    .exp_values(frontend_exp_values)
);

// =============================================================================
// Softmax Backend实例 - Division Normalization  
// =============================================================================
softmax_backend u_backend (
    .clk(clk),
    .rst_n(rst_n),
    
    // 输入 (来自frontend)
    .valid_in(frontend_valid),
    .exp_sum_in(frontend_exp_sum),
    .exp_values_in(frontend_exp_values),
    
    // 输出
    .valid_out(valid_out),
    .softmax_out(softmax_out)
);

endmodule