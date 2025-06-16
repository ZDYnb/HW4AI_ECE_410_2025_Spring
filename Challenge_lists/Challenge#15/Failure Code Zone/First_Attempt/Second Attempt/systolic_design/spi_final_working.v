// ===========================================
// FINAL WORKING SPI CONTROLLER
// Fix: READ_RES state should ignore rx_valid
// ===========================================

`timescale 1ns/1ps

module spi_command_controller_working (
    input wire        clk,
    input wire        rst_n,
    input wire        cs_n,
    
    // SPI slave interface
    input wire [7:0]  spi_rx_data,
    input wire        spi_rx_valid,
    output reg [7:0]  spi_tx_data,
    output reg        spi_tx_ready,
    input wire        spi_tx_done,
    
    // Systolic array interface - flattened (same as before)
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
    reg       read_complete;
    
    // Internal matrix storage
    reg [15:0] matrix_a_storage [0:15];
    reg [7:0]  matrix_b_storage [0:15];
    reg [31:0] results_storage [0:15];
    
    // Map storage to outputs (same as before)
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
    
    // CORRECTED Next state logic - READ_RES doesn't respond to rx_valid
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
                if (data_count >= 6'd32)
                    next_state = IDLE;
                else
                    next_state = LOAD_A;
            end
            
            LOAD_B: begin
                if (data_count >= 6'd16)
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
            
            // FIXED: READ_RES only exits when CS goes high OR read complete
            READ_RES: begin
                if (cs_n || read_complete)  // Exit on CS high or completion
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
    
    // State machine operations
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
            read_complete <= 1'b0;
            
            // Initialize matrices (same as before)
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
                    data_count <= 6'd0;
                    element_index <= 5'd0;
                    byte_index <= 2'd0;
                    start_compute <= 1'b0;
                    spi_tx_ready <= 1'b0;
                    read_complete <= 1'b0;
                end
                
                CMD_DECODE: begin
                    current_cmd <= spi_rx_data;
                    data_count <= 6'd0;
                    element_index <= 5'd0;
                    byte_index <= 2'd0;
                    spi_tx_ready <= 1'b0;
                    read_complete <= 1'b0;
                    
                    if (spi_rx_data == CMD_START) begin
                        start_compute <= 1'b1;
                        irq_sent <= 1'b0;
                    end
                end
                
                LOAD_A: begin
                    if (spi_rx_valid) begin
                        if (byte_index == 2'd0) begin
                            matrix_a_storage[element_index][7:0] <= spi_rx_data;
                            byte_index <= 2'd1;
                        end else begin
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
                
                // FIXED READ_RES - ignores spi_rx_valid, only sends data
                READ_RES: begin
                    if (!spi_tx_ready) begin
                        // Always prepare next byte to send
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
                        
                        if (byte_index == 2'd3) begin
                            byte_index <= 2'd0;
                            if (element_index == 5'd15) begin
                                read_complete <= 1'b1;  // All 16 results sent
                            end else begin
                                element_index <= element_index + 1;
                            end
                        end else begin
                            byte_index <= byte_index + 1;
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
            if (state == READ_RES) begin
                irq <= 1'b0;
                irq_sent <= 1'b0;
            end
        end
    end

endmodule

// Test wrapper
module systolic_spi_wrapper_working (
    input  wire sclk,
    input  wire mosi,
    output wire miso,
    input  wire cs_n,
    output wire irq,
    input  wire clk,
    input  wire rst_n
);

    wire [7:0] spi_rx_data;
    wire       spi_rx_valid;
    wire [7:0] spi_tx_data;
    wire       spi_tx_ready;
    wire       spi_tx_done;
    
    // Test results
    wire [31:0] test_results [0:15];
    assign test_results[0] = 32'h12345678;
    assign test_results[1] = 32'hAABBCCDD;
    genvar i;
    generate
        for (i = 2; i < 16; i = i + 1) begin : gen_test
            assign test_results[i] = 32'h00000000;
        end
    endgenerate
    
    spi_slave_cdc spi_if (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n),
        .sys_clk(clk), .rst_n(rst_n),
        .rx_data(spi_rx_data), .rx_valid(spi_rx_valid),
        .tx_data(spi_tx_data), .tx_ready(spi_tx_ready), .tx_done(spi_tx_done)
    );
    
    spi_command_controller_working spi_ctrl (
        .clk(clk), .rst_n(rst_n), .cs_n(cs_n),
        .spi_rx_data(spi_rx_data), .spi_rx_valid(spi_rx_valid),
        .spi_tx_data(spi_tx_data), .spi_tx_ready(spi_tx_ready), .spi_tx_done(spi_tx_done),
        
        .matrix_a_00(), .matrix_a_01(), .matrix_a_02(), .matrix_a_03(),
        .matrix_a_04(), .matrix_a_05(), .matrix_a_06(), .matrix_a_07(),
        .matrix_a_08(), .matrix_a_09(), .matrix_a_10(), .matrix_a_11(),
        .matrix_a_12(), .matrix_a_13(), .matrix_a_14(), .matrix_a_15(),
        
        .matrix_b_00(), .matrix_b_01(), .matrix_b_02(), .matrix_b_03(),
        .matrix_b_04(), .matrix_b_05(), .matrix_b_06(), .matrix_b_07(),
        .matrix_b_08(), .matrix_b_09(), .matrix_b_10(), .matrix_b_11(),
        .matrix_b_12(), .matrix_b_13(), .matrix_b_14(), .matrix_b_15(),
        
        .results_00(test_results[0]), .results_01(test_results[1]), 
        .results_02(test_results[2]), .results_03(test_results[3]),
        .results_04(test_results[4]), .results_05(test_results[5]), 
        .results_06(test_results[6]), .results_07(test_results[7]),
        .results_08(test_results[8]), .results_09(test_results[9]), 
        .results_10(test_results[10]), .results_11(test_results[11]),
        .results_12(test_results[12]), .results_13(test_results[13]), 
        .results_14(test_results[14]), .results_15(test_results[15]),
        
        .start_compute(), .compute_done(1'b0), .irq(irq)
    );

endmodule

// Simple test
module test_working_spi;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper_working dut (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n), .irq(irq),
        .clk(clk), .rst_n(rst_n)
    );
    
    task spi_send_byte;
        input [7:0] data;
        output [7:0] received;
        integer bit_idx;
    begin
        received = 8'd0;
        cs_n = 0;
        #100;
        
        for (bit_idx = 7; bit_idx >= 0; bit_idx = bit_idx - 1) begin
            mosi = data[bit_idx];
            #100;
            sclk = 1;
            #50;
            received[bit_idx] = miso;
            #50;
            sclk = 0;
            #100;
        end
        
        #100;
        cs_n = 1;
        #200;
    end
    endtask
    
    always @(dut.spi_ctrl.state) begin
        if (dut.spi_ctrl.state == 5)
            $display("Time=%0t: In READ_RES state, element=%d, byte=%d", 
                    $time, dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
    end
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing WORKING SPI Read ===");
        
        // Send READ command - this should enter READ state and stay
        $display("Sending READ command...");
        spi_send_byte(8'h40, received_byte);
        #500;
        
        $display("State: %d (should be 5)", dut.spi_ctrl.state);
        
        // Now read data continuously without new commands
        $display("Reading first result...");
        spi_send_byte(8'h00, received_byte);
        $display("Byte 0: 0x%02x", received_byte);
        
        spi_send_byte(8'h00, received_byte);
        $display("Byte 1: 0x%02x", received_byte);
        
        spi_send_byte(8'h00, received_byte);
        $display("Byte 2: 0x%02x", received_byte);
        
        spi_send_byte(8'h00, received_byte);
        $display("Byte 3: 0x%02x", received_byte);
        
        $display("State after reads: %d", dut.spi_ctrl.state);
        $display("Element index: %d", dut.spi_ctrl.element_index);
        
        $finish;
    end
    
endmodule
