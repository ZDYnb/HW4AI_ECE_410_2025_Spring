// Softmax矩阵处理器 - Pipeline状态机版本 (Q5.10格式)
// 功能：对16×16矩阵的每一行进行Softmax处理
// 输入：256个元素的矩阵 (16行×16列，行主序存储)
// 输出：256个元素的概率分布矩阵 (每行和为1.0)
// 调度策略：Pipeline - 发送和接收并行，总时间 = 16 + pipeline_latency

module softmax_matrix_processor (
    input clk,
    input rst_n,
    
    // 控制接口
    input start,                    // 开始处理矩阵
    output reg done,                    // 处理完成标志
    
    // 矩阵输入接口 (Q5.10格式) - 16×16 = 256元素，行主序存储
    input [15:0] matrix_i [0:255],
    
    // 矩阵输出接口 (Q5.10格式) - 16×16 = 256元素，行主序存储
    output reg [15:0] matrix_o [0:255]
);

// =============================================================================
// Pipeline状态机定义
// =============================================================================
// 发送状态机
reg [1:0] send_state;
localparam SEND_IDLE = 2'b00;
localparam SENDING   = 2'b01;

// 接收状态机  
reg [1:0] recv_state;
localparam RECV_IDLE = 2'b00;
localparam RECEIVING = 2'b01;

// =============================================================================
// 控制计数器
// =============================================================================
reg [4:0] send_counter;        // 发送行计数器 (0-15)
reg [4:0] recv_counter;        // 接收行计数器 (0-15)
reg send_complete;             // 发送完成标志
reg recv_complete;             // 接收完成标志

// =============================================================================
// Softmax流水线接口信号
// =============================================================================
reg pipeline_valid_in;
reg [15:0] pipeline_input [0:15];      // 当前发送的行向量

wire pipeline_valid_out;
wire [15:0] pipeline_output [0:15];    // 当前接收的行向量

// =============================================================================
// Softmax处理器实例化
// =============================================================================
softmax_processor u_softmax_processor (
    .clk(clk),
    .rst_n(rst_n),
    
    // 输入
    .valid_in(pipeline_valid_in),
    .input_vector(pipeline_input),
    
    // 输出
    .valid_out(pipeline_valid_out),
    .softmax_out(pipeline_output)
);

// =============================================================================
// 完成信号 - 两个状态机都完成
// =============================================================================
//assign done;

// =============================================================================
// 发送状态机 - 独立控制数据发送
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        send_state <= SEND_IDLE;
        send_counter <= 5'b0;
        send_complete <= 1'b0;
        pipeline_valid_in <= 1'b0;
        
        // 清空流水线输入
        pipeline_input[0]  <= 16'h0000; pipeline_input[1]  <= 16'h0000;
        pipeline_input[2]  <= 16'h0000; pipeline_input[3]  <= 16'h0000;
        pipeline_input[4]  <= 16'h0000; pipeline_input[5]  <= 16'h0000;
        pipeline_input[6]  <= 16'h0000; pipeline_input[7]  <= 16'h0000;
        pipeline_input[8]  <= 16'h0000; pipeline_input[9]  <= 16'h0000;
        pipeline_input[10] <= 16'h0000; pipeline_input[11] <= 16'h0000;
        pipeline_input[12] <= 16'h0000; pipeline_input[13] <= 16'h0000;
        pipeline_input[14] <= 16'h0000; pipeline_input[15] <= 16'h0000;
        
    end else begin
        case (send_state)
            SEND_IDLE: begin
                pipeline_valid_in <= 1'b0;
                
                if (start) begin
                    send_state <= SENDING;
                    send_counter <= 5'b0;
                    send_complete <= 1'b0;  // 只在新的start时清零
                end
            end
            
SENDING: begin
                // 连续发送16行数据到流水线
                pipeline_valid_in <= 1'b1;
                
                if (send_counter < 16) begin
                    // 发送当前行数据
                    pipeline_input[0]  <= matrix_i[send_counter * 16 + 0];
                    pipeline_input[1]  <= matrix_i[send_counter * 16 + 1];
                    pipeline_input[2]  <= matrix_i[send_counter * 16 + 2];
                    pipeline_input[3]  <= matrix_i[send_counter * 16 + 3];
                    pipeline_input[4]  <= matrix_i[send_counter * 16 + 4];
                    pipeline_input[5]  <= matrix_i[send_counter * 16 + 5];
                    pipeline_input[6]  <= matrix_i[send_counter * 16 + 6];
                    pipeline_input[7]  <= matrix_i[send_counter * 16 + 7];
                    pipeline_input[8]  <= matrix_i[send_counter * 16 + 8];
                    pipeline_input[9]  <= matrix_i[send_counter * 16 + 9];
                    pipeline_input[10] <= matrix_i[send_counter * 16 + 10];
                    pipeline_input[11] <= matrix_i[send_counter * 16 + 11];
                    pipeline_input[12] <= matrix_i[send_counter * 16 + 12];
                    pipeline_input[13] <= matrix_i[send_counter * 16 + 13];
                    pipeline_input[14] <= matrix_i[send_counter * 16 + 14];
                    pipeline_input[15] <= matrix_i[send_counter * 16 + 15];
                    
                    // 递增发送计数器
                    send_counter <= send_counter + 1;
                end else begin
                    send_state <= SEND_IDLE;
                    send_complete <= 1'b1;
                    pipeline_valid_in <= 1'b0;
                end
            end
        endcase
    end
end

// =============================================================================
// 接收状态机 - 独立控制数据接收
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        recv_state <= RECV_IDLE;
        recv_counter <= 5'b0;
        recv_complete <= 1'b0;
        
    end else begin
        case (recv_state)
            RECV_IDLE: begin
                if (pipeline_valid_out) begin
                    recv_state <= RECEIVING;
                    recv_counter <= 5'b1;  // 设为1，因为我们刚接收了第0行
                    recv_complete <= 1'b0;  // 开始新的接收时清零
                    
                    // 接收第一行输出 (行0)
                    matrix_o[0]  <= pipeline_output[0];
                    matrix_o[1]  <= pipeline_output[1];
                    matrix_o[2]  <= pipeline_output[2];
                    matrix_o[3]  <= pipeline_output[3];
                    matrix_o[4]  <= pipeline_output[4];
                    matrix_o[5]  <= pipeline_output[5];
                    matrix_o[6]  <= pipeline_output[6];
                    matrix_o[7]  <= pipeline_output[7];
                    matrix_o[8]  <= pipeline_output[8];
                    matrix_o[9]  <= pipeline_output[9];
                    matrix_o[10] <= pipeline_output[10];
                    matrix_o[11] <= pipeline_output[11];
                    matrix_o[12] <= pipeline_output[12];
                    matrix_o[13] <= pipeline_output[13];
                    matrix_o[14] <= pipeline_output[14];
                    matrix_o[15] <= pipeline_output[15];
                end
            end
            
            RECEIVING: begin
                if (pipeline_valid_out) begin
                    // 接收当前行数据
                    matrix_o[recv_counter * 16 + 0]  <= pipeline_output[0];
                    matrix_o[recv_counter * 16 + 1]  <= pipeline_output[1];
                    matrix_o[recv_counter * 16 + 2]  <= pipeline_output[2];
                    matrix_o[recv_counter * 16 + 3]  <= pipeline_output[3];
                    matrix_o[recv_counter * 16 + 4]  <= pipeline_output[4];
                    matrix_o[recv_counter * 16 + 5]  <= pipeline_output[5];
                    matrix_o[recv_counter * 16 + 6]  <= pipeline_output[6];
                    matrix_o[recv_counter * 16 + 7]  <= pipeline_output[7];
                    matrix_o[recv_counter * 16 + 8]  <= pipeline_output[8];
                    matrix_o[recv_counter * 16 + 9]  <= pipeline_output[9];
                    matrix_o[recv_counter * 16 + 10] <= pipeline_output[10];
                    matrix_o[recv_counter * 16 + 11] <= pipeline_output[11];
                    matrix_o[recv_counter * 16 + 12] <= pipeline_output[12];
                    matrix_o[recv_counter * 16 + 13] <= pipeline_output[13];
                    matrix_o[recv_counter * 16 + 14] <= pipeline_output[14];
                    matrix_o[recv_counter * 16 + 15] <= pipeline_output[15];
                    // 递增接收计数器
                    recv_counter <= recv_counter + 1;
                end
                if (recv_counter == 15) begin
                    recv_state <= RECV_IDLE;
                    recv_complete <= 1'b1;
                    done <= 1'b1;
                end
            end
        endcase
    end
end

endmodule