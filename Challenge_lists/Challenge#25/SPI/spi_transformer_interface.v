// ASIC优化的SPI变压器接口 - 完全修复版本
module spi_transformer_interface (
    // 系统时钟域
    input wire sys_clk,         // 系统时钟
    input wire sys_rst_n,       // 系统复位（异步复位，同步释放）
    
    // SPI时钟域  
    input wire spi_cs_n,        // SPI片选（低电平有效）
    input wire spi_sclk,        // SPI时钟
    input wire spi_mosi,        // SPI数据输入
    output reg spi_miso,        // SPI数据输出
    
    // 矩阵存储器接口（标准SRAM接口）
    output reg mem_we,          // 写使能
    output reg [11:0] mem_addr, // 地址总线 (4096 = 2^12)
    output reg [15:0] mem_wdata,// 写数据
    input wire [15:0] mem_rdata,// 读数据
    
    // 控制和状态接口
    output reg matrix_valid,    // 矩阵数据有效
    output reg [11:0] data_count, // 已接收数据个数
    input wire read_enable,     // 外部读取使能
    
    // 调试接口
    output wire [2:0] fsm_state,
    output wire [11:0] addr_debug,
    output wire spi_active
);

    // ==========================================
    // 参数定义 - 修复位宽问题
    // ==========================================
    localparam [11:0] MATRIX_SIZE = 12'd4095;  // 最大地址，避免溢出
    localparam [4:0] DATA_WIDTH = 5'd16;       // 16位数据宽度
    
    // FSM状态编码（格雷码，减少翻转）
    localparam [2:0] 
        S_IDLE     = 3'b000,
        S_RX_DATA  = 3'b001,  
        S_RX_DONE  = 3'b011,
        S_TX_PREP  = 3'b010,
        S_TX_DATA  = 3'b110,
        S_TX_DONE  = 3'b111;

    // ==========================================
    // SPI时钟域信号
    // ==========================================
    reg [2:0] spi_state, spi_next_state;
    reg [15:0] spi_shift_reg;       // SPI移位寄存器
    reg [3:0] spi_bit_cnt;          // 位计数器
    reg [11:0] spi_word_cnt;        // 字计数器
    reg spi_word_complete;          // 字接收完成标志
    reg spi_cs_n_d1, spi_cs_n_d2;  // CS边沿检测
    
    // 发送相关
    reg [15:0] spi_tx_data;         // 发送数据寄存器
    reg [3:0] spi_tx_bit_cnt;       // 发送位计数
    reg [11:0] spi_tx_word_cnt;     // 发送字计数

    // ==========================================
    // 系统时钟域信号  
    // ==========================================
    reg [2:0] sys_state;
    reg sys_matrix_valid;
    reg [11:0] sys_data_count;
    
    // CDC同步信号
    reg [2:0] spi_to_sys_sync;      // SPI状态同步到系统域
    reg [2:0] sys_to_spi_sync;      // 系统状态同步到SPI域

    // ==========================================
    // CS边沿检测（SPI域）
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_cs_n_d1 <= 1'b1;
            spi_cs_n_d2 <= 1'b1;
        end else begin
            spi_cs_n_d1 <= spi_cs_n;
            spi_cs_n_d2 <= spi_cs_n_d1;
        end
    end
    
    wire spi_cs_falling = spi_cs_n_d2 & ~spi_cs_n_d1;
    wire spi_cs_rising = ~spi_cs_n_d2 & spi_cs_n_d1;

    // ==========================================
    // SPI FSM状态机（SPI时钟域）
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_state <= S_IDLE;
        end else begin
            spi_state <= spi_next_state;
        end
    end

    // SPI FSM组合逻辑 - 添加完整的case覆盖
    always @(*) begin
        spi_next_state = spi_state;
        case (spi_state)
            S_IDLE: begin
                if (spi_cs_falling) begin
                    spi_next_state = S_RX_DATA;
                end
            end
            
            S_RX_DATA: begin
                if (spi_cs_rising) begin
                    if (spi_word_cnt >= 12'd4095) begin  // 修复：收到4096个数据
                        spi_next_state = S_RX_DONE;
                    end else begin
                        spi_next_state = S_IDLE;
                    end
                end
            end
            
            S_RX_DONE: begin
                if (spi_cs_falling && read_enable) begin
                    spi_next_state = S_TX_PREP;
                end
            end
            
            S_TX_PREP: begin
                spi_next_state = S_TX_DATA;
            end
            
            S_TX_DATA: begin
                if (spi_cs_rising) begin
                    if (spi_tx_word_cnt >= 12'd4095) begin
                        spi_next_state = S_TX_DONE;
                    end else begin
                        spi_next_state = S_TX_PREP;
                    end
                end
            end
            
            S_TX_DONE: begin
                spi_next_state = S_IDLE;
            end
            
            default: begin
                spi_next_state = S_IDLE;
            end
        endcase
    end

    // ==========================================
    // SPI数据接收逻辑（SPI时钟域）
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_shift_reg <= 16'b0;
            spi_bit_cnt <= 4'b0;
            spi_word_cnt <= 12'b0;
            spi_word_complete <= 1'b0;
        end else begin
            spi_word_complete <= 1'b0;  // 默认为0
            
            case (spi_state)
                S_IDLE: begin
                    if (spi_next_state == S_RX_DATA) begin
                        spi_bit_cnt <= 4'b0;
                        spi_word_cnt <= 12'b0;
                    end
                end
                
                S_RX_DATA: begin
                    if (!spi_cs_n) begin
                        // MSB first接收
                        spi_shift_reg <= {spi_shift_reg[14:0], spi_mosi};
                        
                        if (spi_bit_cnt == 4'd15) begin
                            spi_bit_cnt <= 4'b0;
                            spi_word_complete <= 1'b1;
                            spi_word_cnt <= spi_word_cnt + 1'b1;
                        end else begin
                            spi_bit_cnt <= spi_bit_cnt + 1'b1;
                        end
                    end
                end
                
                default: begin
                    // 保持状态
                end
            endcase
        end
    end

    // ==========================================
    // 存储器写控制（SPI时钟域）
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            mem_we <= 1'b0;
            mem_addr <= 12'b0;
            mem_wdata <= 16'b0;
        end else begin
            mem_we <= 1'b0;  // 默认不写
            
            if (spi_state == S_RX_DATA && spi_word_complete) begin
                mem_we <= 1'b1;
                mem_addr <= spi_word_cnt - 1'b1;  // 当前完成的字地址
                mem_wdata <= spi_shift_reg;
            end else if (spi_state == S_TX_PREP || spi_state == S_TX_DATA) begin
                // 读取模式，设置地址
                mem_addr <= spi_tx_word_cnt;
            end
        end
    end

    // ==========================================
    // SPI数据发送逻辑（SPI时钟域）
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_tx_word_cnt <= 12'b0;
        end else begin
            case (spi_state)
                S_TX_PREP: begin
                    spi_tx_word_cnt <= 12'b0;
                end
                
                S_TX_DATA: begin
                    if (spi_word_complete) begin  // 16位发送完成
                        spi_tx_word_cnt <= spi_tx_word_cnt + 1'b1;
                    end
                end
                
                default: begin
                    // 保持状态
                end
            endcase
        end
    end

    // 发送位计数和数据输出
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_tx_bit_cnt <= 4'b0;
            spi_tx_data <= 16'b0;
        end else begin
            case (spi_state)
                S_TX_PREP: begin
                    spi_tx_bit_cnt <= 4'b0;
                    spi_tx_data <= mem_rdata;  // 加载要发送的数据
                end
                
                S_TX_DATA: begin
                    if (!spi_cs_n) begin
                        if (spi_tx_bit_cnt == 4'd15) begin
                            spi_tx_bit_cnt <= 4'b0;
                            spi_tx_data <= mem_rdata;  // 加载下一个数据
                        end else begin
                            spi_tx_bit_cnt <= spi_tx_bit_cnt + 1'b1;
                        end
                    end
                end
                
                default: begin
                    // 保持状态
                end
            endcase
        end
    end

    // MISO输出（在时钟下降沿）
    always @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            spi_miso <= 1'b0;
        end else begin
            case (spi_state)
                S_TX_DATA: begin
                    spi_miso <= spi_tx_data[4'd15 - spi_tx_bit_cnt];  // MSB first
                end
                default: begin
                    spi_miso <= 1'b0;
                end
            endcase
        end
    end

    // ==========================================
    // CDC：SPI域到系统域
    // ==========================================
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_to_sys_sync <= 3'b0;
            sys_state <= S_IDLE;
            sys_matrix_valid <= 1'b0;
            sys_data_count <= 12'b0;
        end else begin
            // 同步SPI状态
            spi_to_sys_sync <= {spi_to_sys_sync[1:0], spi_state[0]};
            
            // 检测SPI状态变化
            if (spi_state == S_RX_DONE) begin
                sys_matrix_valid <= 1'b1;
                sys_data_count <= 12'd4096;  // 完整的4096个数据
            end else if (spi_state == S_IDLE) begin
                sys_matrix_valid <= 1'b0;
            end
        end
    end

    // ==========================================
    // 输出赋值
    // ==========================================
    assign fsm_state = spi_state;
    assign addr_debug = mem_addr;
    assign spi_active = ~spi_cs_n;
    
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            matrix_valid <= 1'b0;
            data_count <= 12'b0;
        end else begin
            matrix_valid <= sys_matrix_valid;
            data_count <= sys_data_count;
        end
    end

endmodule