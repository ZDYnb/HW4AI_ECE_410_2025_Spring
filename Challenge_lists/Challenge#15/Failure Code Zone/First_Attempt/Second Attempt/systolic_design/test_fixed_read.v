`timescale 1ns/1ps

module test_fixed_read;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Use fixed controller
    spi_command_controller_fixed dut (
        .clk(clk), .rst_n(rst_n), .cs_n(cs_n),
        .spi_rx_data(8'h40), .spi_rx_valid(1'b1), // Simulate command
        .spi_tx_data(), .spi_tx_ready(), .spi_tx_done(1'b0),
        .matrix_a_00(), .matrix_a_01(), .matrix_a_02(), .matrix_a_03(),
        .matrix_a_04(), .matrix_a_05(), .matrix_a_06(), .matrix_a_07(),
        .matrix_a_08(), .matrix_a_09(), .matrix_a_10(), .matrix_a_11(),
        .matrix_a_12(), .matrix_a_13(), .matrix_a_14(), .matrix_a_15(),
        .matrix_b_00(), .matrix_b_01(), .matrix_b_02(), .matrix_b_03(),
        .matrix_b_04(), .matrix_b_05(), .matrix_b_06(), .matrix_b_07(),
        .matrix_b_08(), .matrix_b_09(), .matrix_b_10(), .matrix_b_11(),
        .matrix_b_12(), .matrix_b_13(), .matrix_b_14(), .matrix_b_15(),
        .results_00(32'd100), .results_01(32'd200), .results_02(32'd300), .results_03(32'd400),
        .results_04(32'd0), .results_05(32'd0), .results_06(32'd0), .results_07(32'd0),
        .results_08(32'd0), .results_09(32'd0), .results_10(32'd0), .results_11(32'd0),
        .results_12(32'd0), .results_13(32'd0), .results_14(32'd0), .results_15(32'd0),
        .start_compute(), .compute_done(1'b0), .irq()
    );
    
    always @(dut.state) begin
        case (dut.state)
            5: $display("Time=%0t: Entered READ_RES state!", $time);
        endcase
    end
    
    initial begin
        rst_n = 0; #100; rst_n = 1; #100;
        
        $display("Testing fixed READ_RES state...");
        #1000;
        $display("Final state: %d (should stay in READ_res=5)", dut.state);
        $display("Results storage[0]: %d", dut.results_storage[0]);
        
        $finish;
    end
endmodule
