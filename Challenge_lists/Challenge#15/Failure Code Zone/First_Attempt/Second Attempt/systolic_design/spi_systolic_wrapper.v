// ===========================================
// Final Working SPI Wrapper with CDC Fix
// ===========================================

`timescale 1ns/1ps

// ===========================================
// CDC-Fixed SPI Slave Module
// ===========================================
module spi_slave_cdc (
    input  wire       sclk,
    input  wire       mosi,
    output reg        miso,
    input  wire       cs_n,
    input  wire       sys_clk,    // System clock for CDC
    input  wire       rst_n,
    output reg [7:0]  rx_data,
    output wire       rx_valid,   // Single pulse in sys_clk domain
    input  wire [7:0] tx_data,
    input  wire       tx_ready,
    output reg        tx_done
);

    // SPI reception (SCLK domain)
    reg [2:0] bit_count;
    reg [7:0] rx_shift_reg;
    reg [7:0] rx_data_spi;
    reg       rx_valid_spi;
    reg [7:0] tx_shift_reg;
    
    // Clock domain crossing (sys_clk domain)
    reg rx_valid_sync1, rx_valid_sync2, rx_valid_sync3;
    
    // SPI reception
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            bit_count <= 3'd0;
            rx_shift_reg <= 8'd0;
            rx_valid_spi <= 1'b0;
        end else begin
            rx_shift_reg <= {rx_shift_reg[6:0], mosi};
            bit_count <= bit_count + 1;
            
            if (bit_count == 3'd7) begin
                rx_data_spi <= {rx_shift_reg[6:0], mosi};
                rx_valid_spi <= 1'b1;
                bit_count <= 3'd0;
            end else begin
                rx_valid_spi <= 1'b0;
            end
        end
    end
    
    // Synchronize to system clock
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_sync1 <= 1'b0;
            rx_valid_sync2 <= 1'b0;
            rx_valid_sync3 <= 1'b0;
            rx_data <= 8'd0;
        end else begin
            rx_valid_sync1 <= rx_valid_spi;
            rx_valid_sync2 <= rx_valid_sync1;
            rx_valid_sync3 <= rx_valid_sync2;
            if (rx_valid_spi) rx_data <= rx_data_spi;
        end
    end
    
    // Edge detection for single pulse
    assign rx_valid = rx_valid_sync2 && !rx_valid_sync3;
    
    // MISO transmission
    always @(negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            miso <= 1'b0;
            tx_shift_reg <= 8'd0;
            tx_done <= 1'b0;
        end else begin
            if (bit_count == 3'd0 && tx_ready) begin
                tx_shift_reg <= tx_data;
                miso <= tx_data[7];
                tx_done <= 1'b0;
            end else begin
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                miso <= tx_shift_reg[7];
                if (bit_count == 3'd7) begin
                    tx_done <= 1'b1;
                end else begin
                    tx_done <= 1'b0;
                end
            end
        end
    end

endmodule

// ===========================================
// Fixed SPI Command Controller
// ===========================================
module spi_command_controller_final (
    input wire        clk,
    input wire        rst_n,
    input wire        cs_n,
    
    // SPI slave interface
    input wire [7:0]  spi_rx_data,
    input wire        spi_rx_valid,
    output reg [7:0]  spi_tx_data,
    output reg        spi_tx_ready,
    input wire        spi_tx_done,
    
    // Systolic array interface - flattened
    output wire [15:0] matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03,
    output wire [15:0] matrix_a_04, matrix_a_05, matrix_a_06, matrix_a_07,
    output wire [15:0] matrix_a_08, matrix_a_09, matrix_a_10, matrix_a_11,
    output wire [15:0] matrix_a_12, matrix_a_13, matrix_a_14, matrix_a_15,
    
    output wire [7:0]  matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03,
    output wire [7:0]  matrix_b_04, matrix_b_05, matrix_b_06, matrix_b_07,
    output wire [7:0]  matrix_b_08, matrix_b_09, matrix_b_10, matrix_b_11,
    output wire [7:0]  matrix_b_12, matrix_b_13, matrix_b_14, matrix_b_15,
    
    input wire [31:0] results_00, results_01, results_02, results_03,
    input wire [31:0] results_04, results_05, results_06, results_07,
    input wire [31:0] results_08, results_09, results_10, results_11,
    input wire [31:0] results_12, results_13, results_14, results_15,
    
    output reg        start_compute,
    input wire        compute_done,
    output reg        irq
);

    // Command codes
    parameter CMD_LOAD_A    = 8'h10;
    parameter CMD_LOAD_B    = 8'h20;
    parameter CMD_START     = 8'h30;
    parameter CMD_READ_RES  = 8'h40;
    parameter CMD_STATUS    = 8'h50;
    
    // State machine
    parameter IDLE       = 3'h0;
    parameter CMD_DECODE = 3'h1;
    parameter LOAD_A     = 3'h2;
    parameter LOAD_B     = 3'h3;
    parameter COMPUTING  = 3'h4;
    parameter READ_RES   = 3'h5;
    parameter SEND_STATUS = 3'h6;
    
    reg [2:0] state, next_state;
    reg [7:0] current_cmd;
    reg [5:0] data_count;      
    reg [4:0] element_index;   
    reg [1:0] byte_index;      
    reg       irq_sent;
    
    // Internal matrix storage
    reg [15:0] matrix_a_storage [0:15];
    reg [7:0]  matrix_b_storage [0:15];
    reg [31:0] results_storage [0:15];
    
    // Map storage to outputs
    assign matrix_a_00 = matrix_a_storage[0];   assign matrix_a_01 = matrix_a_storage[1];
    assign matrix_a_02 = matrix_a_storage[2];   assign matrix_a_03 = matrix_a_storage[3];
    assign matrix_a_04 = matrix_a_storage[4];   assign matrix_a_05 = matrix_a_storage[5];
    assign matrix_a_06 = matrix_a_storage[6];   assign matrix_a_07 = matrix_a_storage[7];
    assign matrix_a_08 = matrix_a_storage[8];   assign matrix_a_09 = matrix_a_storage[9];
    assign matrix_a_10 = matrix_a_storage[10];  assign matrix_a_11 = matrix_a_storage[11];
    assign matrix_a_12 = matrix_a_storage[12];  assign matrix_a_13 = matrix_a_storage[13];
    assign matrix_a_14 = matrix_a_storage[14];  assign matrix_a_15 = matrix_a_storage[15];
    
    assign matrix_b_00 = matrix_b_storage[0];   assign matrix_b_01 = matrix_b_storage[1];
    assign matrix_b_02 = matrix_b_storage[2];   assign matrix_b_03 = matrix_b_storage[3];
    assign matrix_b_04 = matrix_b_storage[4];   assign matrix_b_05 = matrix_b_storage[5];
    assign matrix_b_06 = matrix_b_storage[6];   assign matrix_b_07 = matrix_b_storage[7];
    assign matrix_b_08 = matrix_b_storage[8];   assign matrix_b_09 = matrix_b_storage[9];
    assign matrix_b_10 = matrix_b_storage[10];  assign matrix_b_11 = matrix_b_storage[11];
    assign matrix_b_12 = matrix_b_storage[12];  assign matrix_b_13 = matrix_b_storage[13];
    assign matrix_b_14 = matrix_b_storage[14];  assign matrix_b_15 = matrix_b_storage[15];
    
    // Map results to storage
    always @(*) begin
        results_storage[0] = results_00;   results_storage[1] = results_01;
        results_storage[2] = results_02;   results_storage[3] = results_03;
        results_storage[4] = results_04;   results_storage[5] = results_05;
        results_storage[6] = results_06;   results_storage[7] = results_07;
        results_storage[8] = results_08;   results_storage[9] = results_09;
        results_storage[10] = results_10;  results_storage[11] = results_11;
        results_storage[12] = results_12;  results_storage[13] = results_13;
        results_storage[14] = results_14;  results_storage[15] = results_15;
    end
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (spi_rx_valid && !cs_n)
                    next_state = CMD_DECODE;
                else
                    next_state = IDLE;
            end
            
            CMD_DECODE: begin
                case (spi_rx_data)
                    CMD_LOAD_A:   next_state = LOAD_A;
                    CMD_LOAD_B:   next_state = LOAD_B;
                    CMD_START:    next_state = COMPUTING;
                    CMD_READ_RES: next_state = READ_RES;
                    CMD_STATUS:   next_state = SEND_STATUS;
                    default:      next_state = IDLE;
                endcase
            end
            
            LOAD_A: begin
                if (data_count >= 6'd32)  // 32 bytes total
                    next_state = IDLE;
                else
                    next_state = LOAD_A;
            end
            
            LOAD_B: begin
                if (data_count >= 6'd16)  // 16 bytes total
                    next_state = IDLE;
                else
                    next_state = LOAD_B;
            end
            
            COMPUTING: begin
                if (compute_done)
                    next_state = IDLE;
                else
                    next_state = COMPUTING;
            end
            
            READ_RES: begin
                if (data_count >= 6'd64)  // 64 bytes total
                    next_state = IDLE;
                else
                    next_state = READ_RES;
            end
            
            SEND_STATUS: begin
                if (spi_tx_done)
                    next_state = IDLE;
                else
                    next_state = SEND_STATUS;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // State machine operations - with proper counter resets
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_count <= 6'd0;
            element_index <= 5'd0;
            byte_index <= 2'd0;
            current_cmd <= 8'd0;
            start_compute <= 1'b0;
            spi_tx_data <= 8'd0;
            spi_tx_ready <= 1'b0;
            irq <= 1'b0;
            irq_sent <= 1'b0;
            
            // Initialize matrices
            matrix_a_storage[0] <= 16'd0;   matrix_a_storage[1] <= 16'd0;   matrix_a_storage[2] <= 16'd0;   matrix_a_storage[3] <= 16'd0;
            matrix_a_storage[4] <= 16'd0;   matrix_a_storage[5] <= 16'd0;   matrix_a_storage[6] <= 16'd0;   matrix_a_storage[7] <= 16'd0;
            matrix_a_storage[8] <= 16'd0;   matrix_a_storage[9] <= 16'd0;   matrix_a_storage[10] <= 16'd0;  matrix_a_storage[11] <= 16'd0;
            matrix_a_storage[12] <= 16'd0;  matrix_a_storage[13] <= 16'd0;  matrix_a_storage[14] <= 16'd0;  matrix_a_storage[15] <= 16'd0;
            
            matrix_b_storage[0] <= 8'd0;    matrix_b_storage[1] <= 8'd0;    matrix_b_storage[2] <= 8'd0;    matrix_b_storage[3] <= 8'd0;
            matrix_b_storage[4] <= 8'd0;    matrix_b_storage[5] <= 8'd0;    matrix_b_storage[6] <= 8'd0;    matrix_b_storage[7] <= 8'd0;
            matrix_b_storage[8] <= 8'd0;    matrix_b_storage[9] <= 8'd0;    matrix_b_storage[10] <= 8'd0;   matrix_b_storage[11] <= 8'd0;
            matrix_b_storage[12] <= 8'd0;   matrix_b_storage[13] <= 8'd0;   matrix_b_storage[14] <= 8'd0;   matrix_b_storage[15] <= 8'd0;
            
        end else begin
            case (state)
                IDLE: begin
                    // CRITICAL: Reset ALL counters when entering IDLE
                    data_count <= 6'd0;
                    element_index <= 5'd0;
                    byte_index <= 2'd0;
                    start_compute <= 1'b0;
                    spi_tx_ready <= 1'b0;
                end
                
                CMD_DECODE: begin
                    current_cmd <= spi_rx_data;
                    // CRITICAL: Reset counters for new command
                    data_count <= 6'd0;
                    element_index <= 5'd0;
                    byte_index <= 2'd0;
                    
                    if (spi_rx_data == CMD_START) begin
                        start_compute <= 1'b1;
                        irq_sent <= 1'b0;
                    end
                end
                
                LOAD_A: begin
                    if (spi_rx_valid) begin
                        if (byte_index == 2'd0) begin
                            // Store low byte
                            matrix_a_storage[element_index][7:0] <= spi_rx_data;
                            byte_index <= 2'd1;
                        end else begin
                            // Store high byte and advance element
                            matrix_a_storage[element_index][15:8] <= spi_rx_data;
                            byte_index <= 2'd0;
                            element_index <= element_index + 1;
                        end
                        data_count <= data_count + 1;
                    end
                end
                
                LOAD_B: begin
                    if (spi_rx_valid) begin
                        matrix_b_storage[element_index] <= spi_rx_data;
                        element_index <= element_index + 1;
                        data_count <= data_count + 1;
                    end
                end
                
                COMPUTING: begin
                    start_compute <= 1'b0;
                    if (compute_done && !irq_sent) begin
                        irq <= 1'b1;
                        irq_sent <= 1'b1;
                    end
                end
                
                READ_RES: begin
                    if (!spi_tx_ready) begin
                        case (byte_index)
                            2'd0: spi_tx_data <= results_storage[element_index][7:0];
                            2'd1: spi_tx_data <= results_storage[element_index][15:8];
                            2'd2: spi_tx_data <= results_storage[element_index][23:16];
                            2'd3: spi_tx_data <= results_storage[element_index][31:24];
                        endcase
                        spi_tx_ready <= 1'b1;
                    end
                    
                    if (spi_tx_done) begin
                        spi_tx_ready <= 1'b0;
                        byte_index <= byte_index + 1;
                        data_count <= data_count + 1;
                        
                        if (byte_index == 2'd3) begin
                            byte_index <= 2'd0;
                            element_index <= element_index + 1;
                        end
                    end
                end
                
                SEND_STATUS: begin
                    if (!spi_tx_ready) begin
                        spi_tx_data <= 8'h08; // STAT_DONE
                        spi_tx_ready <= 1'b1;
                    end
                end
            endcase
            
            // Clear IRQ when reading results
            if (state == READ_RES && data_count > 6'd0) begin
                irq <= 1'b0;
                irq_sent <= 1'b0;
            end
        end
    end

endmodule

// ===========================================
// Final Working SPI Wrapper
// ===========================================
module systolic_spi_wrapper_final (
    input  wire sclk,
    input  wire mosi,
    output wire miso,
    input  wire cs_n,
    output wire irq,
    input  wire clk,
    input  wire rst_n
);

    // SPI interface signals
    wire [7:0] spi_rx_data;
    wire       spi_rx_valid;
    wire [7:0] spi_tx_data;
    wire       spi_tx_ready;
    wire       spi_tx_done;
    
    // Systolic array interface
    wire [15:0] sys_matrix_a_00, sys_matrix_a_01, sys_matrix_a_02, sys_matrix_a_03,
                sys_matrix_a_04, sys_matrix_a_05, sys_matrix_a_06, sys_matrix_a_07,
                sys_matrix_a_08, sys_matrix_a_09, sys_matrix_a_10, sys_matrix_a_11,
                sys_matrix_a_12, sys_matrix_a_13, sys_matrix_a_14, sys_matrix_a_15;
    
    wire [7:0]  sys_matrix_b_00, sys_matrix_b_01, sys_matrix_b_02, sys_matrix_b_03,
                sys_matrix_b_04, sys_matrix_b_05, sys_matrix_b_06, sys_matrix_b_07,
                sys_matrix_b_08, sys_matrix_b_09, sys_matrix_b_10, sys_matrix_b_11,
                sys_matrix_b_12, sys_matrix_b_13, sys_matrix_b_14, sys_matrix_b_15;
    
    wire [31:0] sys_results_00, sys_results_01, sys_results_02, sys_results_03,
                sys_results_04, sys_results_05, sys_results_06, sys_results_07,
                sys_results_08, sys_results_09, sys_results_10, sys_results_11,
                sys_results_12, sys_results_13, sys_results_14, sys_results_15;
    
    wire        sys_start;
    wire        sys_done;
    
    // CDC-Fixed SPI Slave
    spi_slave_cdc spi_if (
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n),
        .sys_clk(clk),
        .rst_n(rst_n),
        .rx_data(spi_rx_data),
        .rx_valid(spi_rx_valid),
        .tx_data(spi_tx_data),
        .tx_ready(spi_tx_ready),
        .tx_done(spi_tx_done)
    );
    
    // Fixed SPI Command Controller
    spi_command_controller_final spi_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .spi_rx_data(spi_rx_data),
        .spi_rx_valid(spi_rx_valid),
        .spi_tx_data(spi_tx_data),
        .spi_tx_ready(spi_tx_ready),
        .spi_tx_done(spi_tx_done),
        
        .matrix_a_00(sys_matrix_a_00), .matrix_a_01(sys_matrix_a_01), .matrix_a_02(sys_matrix_a_02), .matrix_a_03(sys_matrix_a_03),
        .matrix_a_04(sys_matrix_a_04), .matrix_a_05(sys_matrix_a_05), .matrix_a_06(sys_matrix_a_06), .matrix_a_07(sys_matrix_a_07),
        .matrix_a_08(sys_matrix_a_08), .matrix_a_09(sys_matrix_a_09), .matrix_a_10(sys_matrix_a_10), .matrix_a_11(sys_matrix_a_11),
        .matrix_a_12(sys_matrix_a_12), .matrix_a_13(sys_matrix_a_13), .matrix_a_14(sys_matrix_a_14), .matrix_a_15(sys_matrix_a_15),
        
        .matrix_b_00(sys_matrix_b_00), .matrix_b_01(sys_matrix_b_01), .matrix_b_02(sys_matrix_b_02), .matrix_b_03(sys_matrix_b_03),
        .matrix_b_04(sys_matrix_b_04), .matrix_b_05(sys_matrix_b_05), .matrix_b_06(sys_matrix_b_06), .matrix_b_07(sys_matrix_b_07),
        .matrix_b_08(sys_matrix_b_08), .matrix_b_09(sys_matrix_b_09), .matrix_b_10(sys_matrix_b_10), .matrix_b_11(sys_matrix_b_11),
        .matrix_b_12(sys_matrix_b_12), .matrix_b_13(sys_matrix_b_13), .matrix_b_14(sys_matrix_b_14), .matrix_b_15(sys_matrix_b_15),
        
        .results_00(sys_results_00), .results_01(sys_results_01), .results_02(sys_results_02), .results_03(sys_results_03),
        .results_04(sys_results_04), .results_05(sys_results_05), .results_06(sys_results_06), .results_07(sys_results_07),
        .results_08(sys_results_08), .results_09(sys_results_09), .results_10(sys_results_10), .results_11(sys_results_11),
        .results_12(sys_results_12), .results_13(sys_results_13), .results_14(sys_results_14), .results_15(sys_results_15),
        
        .start_compute(sys_start),
        .compute_done(sys_done),
        .irq(irq)
    );
    
    // Systolic Array
    systolic_array_4x4 systolic_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(sys_start),
        
        .matrix_a_00(sys_matrix_a_00), .matrix_a_01(sys_matrix_a_01), 
        .matrix_a_02(sys_matrix_a_02), .matrix_a_03(sys_matrix_a_03),
        .matrix_a_10(sys_matrix_a_04), .matrix_a_11(sys_matrix_a_05), 
        .matrix_a_12(sys_matrix_a_06), .matrix_a_13(sys_matrix_a_07),
        .matrix_a_20(sys_matrix_a_08), .matrix_a_21(sys_matrix_a_09), 
        .matrix_a_22(sys_matrix_a_10), .matrix_a_23(sys_matrix_a_11),
        .matrix_a_30(sys_matrix_a_12), .matrix_a_31(sys_matrix_a_13), 
        .matrix_a_32(sys_matrix_a_14), .matrix_a_33(sys_matrix_a_15),
        
        .matrix_b_00(sys_matrix_b_00), .matrix_b_01(sys_matrix_b_01), 
        .matrix_b_02(sys_matrix_b_02), .matrix_b_03(sys_matrix_b_03),
        .matrix_b_10(sys_matrix_b_04), .matrix_b_11(sys_matrix_b_05), 
        .matrix_b_12(sys_matrix_b_06), .matrix_b_13(sys_matrix_b_07),
        .matrix_b_20(sys_matrix_b_08), .matrix_b_21(sys_matrix_b_09), 
        .matrix_b_22(sys_matrix_b_10), .matrix_b_23(sys_matrix_b_11),
        .matrix_b_30(sys_matrix_b_12), .matrix_b_31(sys_matrix_b_13), 
        .matrix_b_32(sys_matrix_b_14), .matrix_b_33(sys_matrix_b_15),
        
        .result_00(sys_results_00), .result_01(sys_results_01), 
        .result_02(sys_results_02), .result_03(sys_results_03),
        .result_10(sys_results_04), .result_11(sys_results_05), 
        .result_12(sys_results_06), .result_13(sys_results_07),
        .result_20(sys_results_08), .result_21(sys_results_09), 
        .result_22(sys_results_10), .result_23(sys_results_11),
        .result_30(sys_results_12), .result_31(sys_results_13), 
        .result_32(sys_results_14), .result_33(sys_results_15),
        
        .computation_done(sys_done),
        .result_valid()
    );

endmodule
