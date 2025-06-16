`timescale 1ns/1ps

module test_spi_data_loading;
    reg clk, rst_n;
    reg sclk, mosi, cs_n;
    wire miso, irq;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper dut (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n), .irq(irq),
        .clk(clk), .rst_n(rst_n)
    );
    
    // Simple SPI write task
    task spi_write_byte;
        input [7:0] data;
        integer i;
    begin
        cs_n = 0;
        for (i = 7; i >= 0; i = i - 1) begin
            mosi = data[i];
            #50; sclk = 1; #50; sclk = 0; #50;
        end
        cs_n = 1;
        #100;
    end
    endtask
    
    initial begin
        // Initialize
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing SPI Data Loading ===");
        
        // Send Load Matrix A command
        $display("Sending Load Matrix A command...");
        spi_write_byte(8'h10);
        
        // Send first few bytes of Matrix A
        $display("Sending Matrix A data...");
        spi_write_byte(8'h01); // Low byte of matrix_a[0] = 1
        spi_write_byte(8'h00); // High byte of matrix_a[0] = 0
        
        // Check if data was stored
        #1000;
        $display("Matrix A storage [0] = %d", dut.spi_ctrl.matrix_a_storage[0]);
        $display("SPI Controller state = %d", dut.spi_ctrl.state);
        $display("Data count = %d", dut.spi_ctrl.data_count);
        
        $finish;
    end
endmodule
