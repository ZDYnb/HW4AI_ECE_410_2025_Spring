`timescale 1ns/1ps

module test_fixed_spi;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Use the FIXED wrapper
    systolic_spi_wrapper_fixed dut (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n), .irq(irq),
        .clk(clk), .rst_n(rst_n)
    );
    
    task spi_write_byte;
        input [7:0] data;
        integer i;
    begin
        cs_n = 0; #50;
        for (i = 7; i >= 0; i = i - 1) begin
            mosi = data[i]; #50; sclk = 1; #50; sclk = 0; #50;
        end
        cs_n = 1; #100;
    end
    endtask
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing FIXED SPI Wrapper ===");
        
        // Send command
        spi_write_byte(8'h10);
        #100;
        $display("After command: data_count=%d, element_index=%d", 
                 dut.spi_ctrl.data_count, dut.spi_ctrl.element_index);
        
        // Send data bytes
        spi_write_byte(8'h01);
        #100;
        $display("After byte 1: matrix_a[0]=%d, element_index=%d, byte_index=%d", 
                 dut.spi_ctrl.matrix_a_storage[0], dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
        
        spi_write_byte(8'h00);
        #100;
        $display("After byte 2: matrix_a[0]=%d, element_index=%d, byte_index=%d", 
                 dut.spi_ctrl.matrix_a_storage[0], dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
        
        if (dut.spi_ctrl.matrix_a_storage[0] == 16'd1) begin
            $display("✅ SUCCESS: Data stored correctly!");
        end else begin
            $display("❌ FAILED: Expected 1, got %d", dut.spi_ctrl.matrix_a_storage[0]);
        end
        
        $finish;
    end
endmodule
