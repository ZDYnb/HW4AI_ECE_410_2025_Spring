// ===========================================
// Final Complete SPI Test - End to End
// ===========================================

`timescale 1ns/1ps

// Complete wrapper with final fixed controller
module systolic_spi_wrapper_final_complete (
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
    
    // Test results - hardcoded known values
    wire [31:0] test_results [0:15];
    assign test_results[0] = 32'h12345678;
    assign test_results[1] = 32'hAABBCCDD;
    assign test_results[2] = 32'h11223344;
    assign test_results[3] = 32'hDEADBEEF;
    genvar i;
    generate
        for (i = 4; i < 16; i = i + 1) begin : gen_test
            assign test_results[i] = 32'h00000000;
        end
    endgenerate
    
    // CDC SPI Slave
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
    
    // Fixed SPI Controller
    spi_command_controller_final_fix spi_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .spi_rx_data(spi_rx_data),
        .spi_rx_valid(spi_rx_valid),
        .spi_tx_data(spi_tx_data),
        .spi_tx_ready(spi_tx_ready),
        .spi_tx_done(spi_tx_done),
        
        // Dummy matrix outputs
        .matrix_a_00(), .matrix_a_01(), .matrix_a_02(), .matrix_a_03(),
        .matrix_a_04(), .matrix_a_05(), .matrix_a_06(), .matrix_a_07(),
        .matrix_a_08(), .matrix_a_09(), .matrix_a_10(), .matrix_a_11(),
        .matrix_a_12(), .matrix_a_13(), .matrix_a_14(), .matrix_a_15(),
        
        .matrix_b_00(), .matrix_b_01(), .matrix_b_02(), .matrix_b_03(),
        .matrix_b_04(), .matrix_b_05(), .matrix_b_06(), .matrix_b_07(),
        .matrix_b_08(), .matrix_b_09(), .matrix_b_10(), .matrix_b_11(),
        .matrix_b_12(), .matrix_b_13(), .matrix_b_14(), .matrix_b_15(),
        
        // Connect test results
        .results_00(test_results[0]), .results_01(test_results[1]), 
        .results_02(test_results[2]), .results_03(test_results[3]),
        .results_04(test_results[4]), .results_05(test_results[5]), 
        .results_06(test_results[6]), .results_07(test_results[7]),
        .results_08(test_results[8]), .results_09(test_results[9]), 
        .results_10(test_results[10]), .results_11(test_results[11]),
        .results_12(test_results[12]), .results_13(test_results[13]), 
        .results_14(test_results[14]), .results_15(test_results[15]),
        
        .start_compute(),
        .compute_done(1'b0),
        .irq(irq)
    );

endmodule

// Complete end-to-end test
module tb_final_complete_test;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    integer test_results [0:15];
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper_final_complete dut (
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
    
    // Monitor state for debugging
    always @(dut.spi_ctrl.state) begin
        case (dut.spi_ctrl.state)
            0: $display("Time=%0t: State -> IDLE", $time);
            1: $display("Time=%0t: State -> CMD_DECODE", $time);
            5: $display("Time=%0t: State -> READ_RES (element=%d, read_complete=%b)", 
                       $time, dut.spi_ctrl.element_index, dut.spi_ctrl.read_complete);
        endcase
    end
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== FINAL COMPLETE SPI TEST ===");
        $display("Expected results[0] = 0x12345678");
        $display("Expected results[1] = 0xAABBCCDD");
        
        // Send READ command
        $display("\nSending READ command (0x40)...");
        spi_send_byte(8'h40, received_byte);
        #500;
        
        $display("Controller state after command: %d", dut.spi_ctrl.state);
        $display("Read complete flag: %b", dut.spi_ctrl.read_complete);
        
        if (dut.spi_ctrl.state == 5) begin
            $display("\n✅ SUCCESS: Entered READ_RES state!");
            
            // Read first result (4 bytes)
            $display("Reading result[0]...");
            spi_send_byte(8'h00, received_byte);
            $display("Byte 0: 0x%02x (expected: 0x78)", received_byte);
            test_results[0] = received_byte;
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 1: 0x%02x (expected: 0x56)", received_byte);
            test_results[1] = received_byte;
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 2: 0x%02x (expected: 0x34)", received_byte);
            test_results[2] = received_byte;
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 3: 0x%02x (expected: 0x12)", received_byte);
            test_results[3] = received_byte;
            
            // Check if still in READ state
            $display("State after first result: %d", dut.spi_ctrl.state);
            $display("Element index: %d", dut.spi_ctrl.element_index);
            
            // Read second result (4 bytes)
            $display("\nReading result[1]...");
            spi_send_byte(8'h00, received_byte);
            $display("Byte 0: 0x%02x (expected: 0xDD)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 1: 0x%02x (expected: 0xCC)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 2: 0x%02x (expected: 0xBB)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 3: 0x%02x (expected: 0xAA)", received_byte);
            
            $display("State after second result: %d", dut.spi_ctrl.state);
            $display("Element index: %d", dut.spi_ctrl.element_index);
            
            // Reconstruct and verify
            $display("\nVerification:");
            $display("Result[0] = 0x%02x%02x%02x%02x", test_results[3], test_results[2], test_results[1], test_results[0]);
            
            if (test_results[0] == 8'h78 && test_results[1] == 8'h56 && 
                test_results[2] == 8'h34 && test_results[3] == 8'h12) begin
                $display("✅ SUCCESS: First result correct!");
            end else begin
                $display("❌ FAILED: First result incorrect");
            end
            
        end else begin
            $display("❌ PROBLEM: Not in READ_RES state");
            $display("Current state: %d", dut.spi_ctrl.state);
        end
        
        $finish;
    end
    
endmodule
