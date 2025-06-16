// ===========================================
// Complete SPI Wrapper with Fixed READ_RES
// ===========================================

`timescale 1ns/1ps

// Use the CDC-fixed SPI slave from before
module spi_slave_cdc (
    input  wire       sclk,
    input  wire       mosi,
    output reg        miso,
    input  wire       cs_n,
    input  wire       sys_clk,
    input  wire       rst_n,
    output reg [7:0]  rx_data,
    output wire       rx_valid,
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
    
    // MISO transmission - FIXED!
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

// Complete wrapper with fixed controller
module systolic_spi_wrapper_complete (
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
    
    // Dummy systolic array outputs (for testing SPI only)
    wire [31:0] dummy_results [0:15];
    assign dummy_results[0] = 32'h12345678;  // Test pattern
    assign dummy_results[1] = 32'hAABBCCDD;
    assign dummy_results[2] = 32'h11223344;
    assign dummy_results[3] = 32'hDEADBEEF;
    genvar i;
    generate
        for (i = 4; i < 16; i = i + 1) begin : gen_dummy
            assign dummy_results[i] = 32'h00000000;
        end
    endgenerate
    
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
    spi_command_controller_fixed spi_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .spi_rx_data(spi_rx_data),
        .spi_rx_valid(spi_rx_valid),
        .spi_tx_data(spi_tx_data),
        .spi_tx_ready(spi_tx_ready),
        .spi_tx_done(spi_tx_done),
        
        // Dummy matrix outputs (not used in this test)
        .matrix_a_00(), .matrix_a_01(), .matrix_a_02(), .matrix_a_03(),
        .matrix_a_04(), .matrix_a_05(), .matrix_a_06(), .matrix_a_07(),
        .matrix_a_08(), .matrix_a_09(), .matrix_a_10(), .matrix_a_11(),
        .matrix_a_12(), .matrix_a_13(), .matrix_a_14(), .matrix_a_15(),
        
        .matrix_b_00(), .matrix_b_01(), .matrix_b_02(), .matrix_b_03(),
        .matrix_b_04(), .matrix_b_05(), .matrix_b_06(), .matrix_b_07(),
        .matrix_b_08(), .matrix_b_09(), .matrix_b_10(), .matrix_b_11(),
        .matrix_b_12(), .matrix_b_13(), .matrix_b_14(), .matrix_b_15(),
        
        // Connect dummy results
        .results_00(dummy_results[0]), .results_01(dummy_results[1]), 
        .results_02(dummy_results[2]), .results_03(dummy_results[3]),
        .results_04(dummy_results[4]), .results_05(dummy_results[5]), 
        .results_06(dummy_results[6]), .results_07(dummy_results[7]),
        .results_08(dummy_results[8]), .results_09(dummy_results[9]), 
        .results_10(dummy_results[10]), .results_11(dummy_results[11]),
        .results_12(dummy_results[12]), .results_13(dummy_results[13]), 
        .results_14(dummy_results[14]), .results_15(dummy_results[15]),
        
        .start_compute(),
        .compute_done(1'b0),
        .irq(irq)
    );

endmodule
