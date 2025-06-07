// SPI测试包装器 - 包含简单的存储器模拟
module spi_test_wrapper (
    // 系统时钟域
    input wire sys_clk,         
    input wire sys_rst_n,       
    
    // SPI时钟域  
    input wire spi_cs_n,        
    input wire spi_sclk,        
    input wire spi_mosi,        
    output wire spi_miso,        
    
    // 控制和状态接口
    output wire matrix_valid,    
    output wire [11:0] data_count, 
    input wire read_enable,     
    
    // 调试接口
    output wire [2:0] fsm_state,
    output wire [11:0] addr_debug,
    output wire spi_active
);

    // 存储器接口信号
    wire mem_we;
    wire [11:0] mem_addr;
    wire [15:0] mem_wdata;
    wire [15:0] mem_rdata;

    // SPI接口实例
    spi_transformer_interface spi_if (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .matrix_valid(matrix_valid),
        .data_count(data_count),
        .read_enable(read_enable),
        .fsm_state(fsm_state),
        .addr_debug(addr_debug),
        .spi_active(spi_active)
    );

    // 简单的存储器模拟
    simple_memory mem_inst (
        .clk(spi_sclk),
        .we(mem_we),
        .addr(mem_addr),
        .din(mem_wdata),
        .dout(mem_rdata)
    );

endmodule

// 简单的存储器模块
module simple_memory (
    input wire clk,
    input wire we,
    input wire [11:0] addr,
    input wire [15:0] din,
    output reg [15:0] dout
);

    // 存储器数组
    reg [15:0] memory [0:4095];
    
    // 初始化存储器
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] = 16'h0000;
        end
    end

    // 读写操作 - 修复位宽警告
    always @(posedge clk) begin
        if (we && (addr <= 12'd4095)) begin  // 修复位宽比较
            memory[addr] <= din;
        end
        if (addr <= 12'd4095) begin
            dout <= memory[addr];
        end else begin
            dout <= 16'h0000;  // 超出范围返回0
        end
    end

endmodule  