// 修复读取功能的 spi_top.v

module spi_top (
    input wire clk,        // 系统时钟
    input wire rst_n,      // 复位
    
    // SPI接口
    input wire spi_cs,     // 片选
    input wire spi_clk,    // SPI时钟  
    input wire spi_mosi,   // 主机发来的数据
    output wire spi_miso   // 发给主机的数据
);

//================================================================
// 存储器
//================================================================
reg [15:0] input_matrix [0:255];    // 输入矩阵
reg [15:0] output_matrix [0:255];   // 输出矩阵

//================================================================
// 系统状态机
//================================================================
reg [2:0] system_state;
localparam WAITING     = 3'd0;
localparam LOADING     = 3'd1; 
localparam COMPUTING   = 3'd2;
localparam READY       = 3'd3;
localparam OUTPUTTING  = 3'd4;

//================================================================
// SPI信号同步到系统时钟域
//================================================================
reg [2:0] spi_cs_sync, spi_clk_sync, spi_mosi_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_cs_sync <= 3'b111;
        spi_clk_sync <= 3'b000;
        spi_mosi_sync <= 3'b000;
    end else begin
        spi_cs_sync <= {spi_cs_sync[1:0], spi_cs};
        spi_clk_sync <= {spi_clk_sync[1:0], spi_clk};
        spi_mosi_sync <= {spi_mosi_sync[1:0], spi_mosi};
    end
end

wire cs_sync = spi_cs_sync[2];
wire mosi_sync = spi_mosi_sync[2];
wire spi_clk_posedge = (spi_clk_sync[2:1] == 2'b01);

// 检测CS的下降沿
wire cs_negedge = (spi_cs_sync[2:1] == 2'b10);

//================================================================
// SPI数据收发逻辑 - 修复版
//================================================================
reg [15:0] spi_rx_shifter;   // 接收移位寄存器
reg [15:0] spi_tx_shifter;   // 发送移位寄存器
reg [3:0] bit_counter;       // 位计数器 (0-15)
reg [7:0] word_counter;      // 字计数器 (0-255)
reg word_complete;           // 一个16位字完成标志

// SPI接收逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_rx_shifter <= 16'h0;
        bit_counter <= 4'h0;
        word_counter <= 8'h0;
        word_complete <= 1'b0;
    end else begin
        word_complete <= 1'b0;  // 默认清除完成标志
        
        if (cs_sync) begin  // CS高电平，复位计数器
            bit_counter <= 4'h0;
        end else if (spi_clk_posedge && (system_state == LOADING || system_state == OUTPUTTING)) begin
            bit_counter <= bit_counter + 1;
            
            if (system_state == LOADING) begin
                // 接收数据
                spi_rx_shifter <= {spi_rx_shifter[14:0], mosi_sync};
            end
            
            if (bit_counter == 4'hF) begin  // 接收/发送完16位
                word_complete <= 1'b1;
                bit_counter <= 4'h0;
                word_counter <= word_counter + 1;
            end
        end
    end
end

// SPI发送逻辑 - 修复版
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_tx_shifter <= 16'h0;
    end else begin
        if (cs_sync) begin
            spi_tx_shifter <= 16'h0;
        end else begin
            // 修复：在OUTPUTTING状态开始时就准备第一个数据
            if (system_state == OUTPUTTING && bit_counter == 4'h0 && !spi_clk_posedge) begin
                // 当进入OUTPUTTING状态时，立即装载第一个数据
                spi_tx_shifter <= output_matrix[word_counter];
            end else if (spi_clk_posedge && system_state == OUTPUTTING) begin
                if (bit_counter == 4'h0) begin
                    // 新的字开始，装载数据
                    spi_tx_shifter <= output_matrix[word_counter];
                end else begin
                    // 移位发送
                    spi_tx_shifter <= {spi_tx_shifter[14:0], 1'b0};
                end
            end
        end
    end
end

// 修复：MISO输出逻辑，确保没有X状态
assign spi_miso = cs_sync ? 1'b0 : spi_tx_shifter[15];  // CS高时输出0而不是Z

//================================================================
// 主控制逻辑
//================================================================
reg compute_start;
wire compute_done;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        system_state <= WAITING;
        compute_start <= 1'b0;
    end else begin
        compute_start <= 1'b0;  // 默认清除启动信号
        
        case (system_state)
            WAITING: begin
                if (cs_negedge) begin  
                    system_state <= LOADING;
                    word_counter <= 8'h0;
                end
            end
            
            LOADING: begin
                if (word_complete) begin
                    input_matrix[word_counter-1] <= spi_rx_shifter;
                    
                    if (word_counter == 8'd0) begin  // word_counter溢出回到0
                        system_state <= COMPUTING;
                        compute_start <= 1'b1;
                    end
                end
                
                if (cs_sync) begin  
                    system_state <= WAITING;
                end
            end
            
            COMPUTING: begin
                if (compute_done) begin
                    system_state <= READY;
                end
            end
            
            READY: begin
                if (cs_negedge) begin  
                    system_state <= OUTPUTTING;
                    word_counter <= 8'h0;
                end
            end
            
            OUTPUTTING: begin
                if (word_complete && word_counter == 8'd0) begin
                    system_state <= WAITING;
                end
                
                if (cs_sync) begin
                    system_state <= WAITING;
                end
            end
        endcase
    end
end

//================================================================
// 计算单元实例化
//================================================================
your_compute_unit compute_core (
    .clk(clk),
    .rst_n(rst_n),
    .start(compute_start),
    .done(compute_done),
    .input_data(input_matrix),
    .output_data(output_matrix)
);

endmodule

//================================================================
// 超简单的计算单元
//================================================================
module your_compute_unit (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg done,
    input wire [15:0] input_data [0:255],    
    output wire [15:0] output_data [0:255]   
);

// 输入直接连到输出 (组合逻辑)
genvar i;
generate
    for (i = 0; i < 256; i = i + 1) begin : direct_wire
        assign output_data[i] = input_data[i];
    end
endgenerate

// done信号：start后延迟1个周期就完成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 1'b0;
    end else begin
        done <= start;
    end
end

endmodule