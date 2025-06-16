// Simple test to debug IRQ issue
`timescale 1ns/1ps

module simple_irq_test;
    reg clk, rst_n;
    wire irq;
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT
    systolic_spi_wrapper dut (
        .sclk(1'b0),    // Tie off SPI signals for now
        .mosi(1'b0),
        .miso(),
        .cs_n(1'b1),
        .irq(irq),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Simple test
    initial begin
        $display("=== Simple IRQ Test ===");
        
        // Reset
        rst_n = 0;
        #100;
        rst_n = 1;
        #100;
        
        // Monitor IRQ
        $display("Monitoring IRQ signal...");
        $monitor("Time=%0t: IRQ=%b, Controller_IRQ=%b", $time, irq, dut.spi_ctrl.irq);
        
        // Let it run
        #1000;
        
        $display("Test complete");
        $finish;
    end
    
endmodule
