// ASIC-optimized SPI transformer interface
module spi_transformer_interface (
    // System clock domain
    input wire sys_clk,         // System clock
    input wire sys_rst_n,       // System reset (asynchronous reset, synchronous release)
    
    // SPI clock domain  
    input wire spi_cs_n,        // SPI chip select (active low)
    input wire spi_sclk,        // SPI clock
    input wire spi_mosi,        // SPI data input
    output reg spi_miso,        // SPI data output
    
    // Matrix memory interface (standard SRAM interface)
    output reg mem_we,          // Write enable
    output reg [11:0] mem_addr, // Address bus (4096 = 2^12)
    output reg [15:0] mem_wdata,// Write data
    input wire [15:0] mem_rdata,// Read data
    
    // Control and status interface
    output reg matrix_valid,    // Matrix data valid
    output reg [11:0] data_count, // Number of received data
    input wire read_enable,     // External read enable
    
    // Debug interface
    output wire [2:0] fsm_state,
    output wire [11:0] addr_debug,
    output wire spi_active
);

    // ==========================================
    // Parameter definitions
    // ==========================================
    localparam [11:0] MATRIX_SIZE = 12'd4095;  // 64x64-1 = 4095 (max address)
    localparam [4:0] DATA_WIDTH = 5'd16;       // 16-bit data width
    
    // FSM state encoding (Gray code, reduces toggling)
    localparam [2:0] 
        S_IDLE     = 3'b000,
        S_RX_DATA  = 3'b001,  
        S_RX_DONE  = 3'b011,
        S_TX_PREP  = 3'b010,
        S_TX_DATA  = 3'b110,
        S_TX_DONE  = 3'b111;

    // ==========================================
    // SPI clock domain signals
    // ==========================================
    reg [2:0] spi_state, spi_next_state;
    reg [15:0] spi_shift_reg;       // SPI shift register
    reg [3:0] spi_bit_cnt;          // Bit counter
    reg [11:0] spi_word_cnt;        // Word counter
    reg spi_word_complete;          // Word receive complete flag
    reg spi_cs_n_d1, spi_cs_n_d2;   // CS edge detection
    
    // Transmission related
    reg [15:0] spi_tx_data;         // Transmission data register
    reg [3:0] spi_tx_bit_cnt;       // Transmission bit counter
    reg [11:0] spi_tx_word_cnt;     // Transmission word counter

    // ==========================================
    // System clock domain signals  
    // ==========================================
    reg [2:0] sys_state;
    reg sys_matrix_valid;
    reg [11:0] sys_data_count;
    
    // CDC sync signals
    reg [2:0] spi_to_sys_sync;      // SPI state sync to system domain
    reg [2:0] sys_to_spi_sync;      // System state sync to SPI domain

    // ==========================================
    // CS edge detection (SPI domain)
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
    // SPI FSM (SPI clock domain)
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_state <= S_IDLE;
        end else begin
            spi_state <= spi_next_state;
        end
    end

    // SPI FSM combinational logic
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
                    if (spi_word_cnt == MATRIX_SIZE - 1) begin
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
                    if (spi_tx_word_cnt == MATRIX_SIZE) begin
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
    // SPI data receive logic (SPI clock domain)
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_shift_reg <= 16'b0;
            spi_bit_cnt <= 4'b0;
            spi_word_cnt <= 12'b0;
            spi_word_complete <= 1'b0;
        end else begin
            spi_word_complete <= 1'b0;  // Default 0
            
            case (spi_state)
                S_IDLE: begin
                    if (spi_next_state == S_RX_DATA) begin
                        spi_bit_cnt <= 4'b0;
                        spi_word_cnt <= 12'b0;
                    end
                end
                
                S_RX_DATA: begin
                    if (!spi_cs_n) begin
                        // MSB first receive
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
                    // Hold state
                end
            endcase
        end
    end

    // ==========================================
    // Memory write control (SPI clock domain)
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            mem_we <= 1'b0;
            mem_addr <= 12'b0;
            mem_wdata <= 16'b0;
        end else begin
            mem_we <= 1'b0;  // Default no write
            
            if (spi_state == S_RX_DATA && spi_word_complete) begin
                mem_we <= 1'b1;
                mem_addr <= spi_word_cnt - 1'b1;  // Address of current completed word
                mem_wdata <= spi_shift_reg;
            end
        end
    end

    // ==========================================
    // SPI data transmit logic (SPI clock domain)
    // ==========================================
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_tx_word_cnt <= 12'b0;
        end else begin
            case (spi_state)
                S_TX_PREP: begin
                    spi_tx_word_cnt <= 12'b0;
                    // Prepare to read first data address
                    mem_addr <= 12'b0;
                end
                
                S_TX_DATA: begin
                    if (spi_word_complete) begin  // 16 bits sent
                        spi_tx_word_cnt <= spi_tx_word_cnt + 1'b1;
                        mem_addr <= spi_tx_word_cnt + 1'b1;  // Next address
                    end
                end
                
                default: begin
                    // Hold state
                end
            endcase
        end
    end

    // Transmit bit counter and data output
    always @(posedge spi_sclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_tx_bit_cnt <= 4'b0;
            spi_tx_data <= 16'b0;
        end else begin
            case (spi_state)
                S_TX_PREP: begin
                    spi_tx_bit_cnt <= 4'b0;
                    spi_tx_data <= mem_rdata;  // Load data to send
                end
                
                S_TX_DATA: begin
                    if (!spi_cs_n) begin
                        if (spi_tx_bit_cnt == 4'd15) begin
                            spi_tx_bit_cnt <= 4'b0;
                            spi_tx_data <= mem_rdata;  // Load next data
                        end else begin
                            spi_tx_bit_cnt <= spi_tx_bit_cnt + 1'b1;
                        end
                    end
                end
                
                default: begin
                    // Hold state
                end
            endcase
        end
    end

    // MISO output (on clock falling edge)
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
    // CDC: SPI domain to system domain
    // ==========================================
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_to_sys_sync <= 3'b0;
            sys_state <= S_IDLE;
            sys_matrix_valid <= 1'b0;
            sys_data_count <= 12'b0;
        end else begin
            // Sync SPI state
            spi_to_sys_sync <= {spi_to_sys_sync[1:0], spi_state[0]};
            
            // Detect SPI state change
            if (spi_state == S_RX_DONE) begin
                sys_matrix_valid <= 1'b1;
                sys_data_count <= 12'd4096;  // All 4096 data received
            end else if (spi_state == S_IDLE) begin
                sys_matrix_valid <= 1'b0;
            end
        end
    end

    // ==========================================
    // Output assignments
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