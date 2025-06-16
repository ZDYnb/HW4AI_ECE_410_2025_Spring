// spi_transformer_interface.v - Fixed Version
module spi_transformer_interface (
    // 系统信号
    input wire clk,          // 系统时钟 100MHz
    input wire rst_n,        // 复位信号（低电平有效）
    
    // SPI信号
    input wire spi_cs_n,     // SPI片选（低电平有效）
    input wire spi_sclk,     // SPI时钟
    input wire spi_mosi,     // SPI数据输入
    output reg spi_miso,     // SPI数据输出
    
    // 调试输出
    output reg [7:0] received_data,  // 最后接收到的8位数据
    output reg [2:0] bit_count,      // 当前接收的bit数量（0-7）
    output reg data_ready,           // 数据接收完成标志
    
    // 16位扩展输出
    output reg [15:0] received_data_16, // 16位数据
    output reg [1:0] byte_count_16,     // 16位模式下的字节计数
    output reg data_ready_16            // 16位数据准备标志
);

    // ==========================================
    // Step 1-3: 基础8位SPI接收逻辑
    // ==========================================
    reg [7:0] shift_register;  // 8位移位寄存器
    
    always @(posedge spi_sclk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零所有信号
            shift_register <= 8'b0;
            bit_count <= 3'b0;
            data_ready <= 1'b0;
        end else if (!spi_cs_n) begin
            // CS有效时接收数据
            
            // 核心操作：左移并接收新bit (MSB first)
            shift_register <= {shift_register[6:0], spi_mosi};
            
            // 计数接收的bit数
            if (bit_count == 3'b111) begin  // 7 -> 下一个就是8个bit完成
                data_ready <= 1'b1;
                bit_count <= 3'b0;  // 重置计数器
            end else begin
                bit_count <= bit_count + 1;
                data_ready <= 1'b0;
            end
        end else begin
            // CS无效时保持空闲
            data_ready <= 1'b0;
        end
    end

    // ==========================================
    // Step 1-3: 数据存储 - 在系统时钟域存储接收完成的数据
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            received_data <= 8'b0;
        end else if (data_ready) begin
            // 当SPI接收完成时，存储完整的8位数据
            received_data <= shift_register;
        end
    end

    // ==========================================
    // Step 4: SPI输出逻辑（发送之前接收的数据）
    // ==========================================
    reg [7:0] tx_data;
    reg [2:0] tx_bit_count;
    
    // 数据准备 - 当接收完成时立即准备下次发送的数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'b0;
        end else if (data_ready) begin
            // 使用接收完成的数据作为下次发送的数据
            tx_data <= shift_register;
        end
    end
    
    // 发送计数器 - 在CS下降沿重置，SPI时钟上升沿递增
    always @(posedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            tx_bit_count <= 3'b0;  // CS释放时重置
        end else begin
            tx_bit_count <= tx_bit_count + 1;  // 每个SPI时钟递增
        end
    end
    
    // 数据发送 - 在SPI时钟下降沿输出 (LSB first for loopback compatibility)
    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            spi_miso <= 1'b0;
        end else begin
            // LSB first发送（与测试期望匹配）
            spi_miso <= tx_data[tx_bit_count];
        end
    end

    // ==========================================
    // Step 5: 16位数据扩展
    // ==========================================
    reg [15:0] data_16_buffer;  // 16位数据缓冲
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            received_data_16 <= 16'b0;
            byte_count_16 <= 2'b0;
            data_ready_16 <= 1'b0;
            data_16_buffer <= 16'b0;
        end else if (data_ready) begin
            // 每当接收到一个字节时
            if (byte_count_16 == 2'b0) begin
                // 第一个字节（高字节）
                data_16_buffer[15:8] <= shift_register;
                byte_count_16 <= 2'b1;
                data_ready_16 <= 1'b0;
            end else if (byte_count_16 == 2'b1) begin
                // 第二个字节（低字节）
                data_16_buffer[7:0] <= shift_register;
                received_data_16 <= {data_16_buffer[15:8], shift_register};
                byte_count_16 <= 2'b0;  // 重置为下一个16位传输
                data_ready_16 <= 1'b1;
            end
        end else begin
            data_ready_16 <= 1'b0;
        end
    end

endmodule
