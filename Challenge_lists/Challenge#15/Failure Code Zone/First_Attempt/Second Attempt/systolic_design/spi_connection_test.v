`timescale 1ns/1ps

module test_spi_connections;
    reg clk, rst_n;
    wire [15:0] test_a_00;
    wire [7:0] test_b_00; 
    wire [31:0] test_result_00;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test SPI wrapper instantiation
    systolic_spi_wrapper dut (
        .sclk(1'b0), .mosi(1'b0), .miso(), .cs_n(1'b1), .irq(),
        .clk(clk), .rst_n(1'b1)
    );
    
    // Check internal connections
    initial begin
        #100;
        $display("Checking SPI wrapper internal connections...");
        $display("Matrix A storage [0] = %d", dut.spi_ctrl.matrix_a_storage[0]);
        $display("Matrix A output 00 = %d", dut.sys_matrix_a_00);
        $display("Connection working: %s", (dut.sys_matrix_a_00 === dut.spi_ctrl.matrix_a_storage[0]) ? "YES" : "NO");
        $finish;
    end
endmodule
