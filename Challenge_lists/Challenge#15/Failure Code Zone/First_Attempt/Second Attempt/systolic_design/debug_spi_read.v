// ===========================================
// Debug SPI Result Reading
// ===========================================

`timescale 1ns/1ps

module debug_spi_read;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Use your SPI wrapper
    systolic_spi_wrapper_final dut (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n), .irq(irq),
        .clk(clk), .rst_n(rst_n)
    );
    
    // SPI send/receive task
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
            received[bit_idx] = miso; // Sample MISO
            #50;
            sclk = 0;
            #100;
        end
        
        #100;
        cs_n = 1;
        #200;
    end
    endtask
    
    // Monitor internal signals
    always @(posedge clk) begin
        if (dut.spi_ctrl.state == 5) begin // READ_RES state
            $display("Time=%0t: READ_RES state - element_idx=%d, byte_idx=%d, tx_data=0x%02x, tx_ready=%b", 
                    $time, dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index, 
                    dut.spi_ctrl.spi_tx_data, dut.spi_ctrl.spi_tx_ready);
        end
    end
    
    // Monitor systolic array results
    always @(posedge clk) begin
        if (dut.spi_ctrl.results_storage[0] != 0) begin
            $display("Time=%0t: results_storage[0] = %d", $time, dut.spi_ctrl.results_storage[0]);
        end
    end
    
    initial begin
        // Initialize
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Debug SPI Result Reading ===");
        
        // First, let's check if systolic array produces results
        $display("Checking systolic array connection...");
        #1000;
        $display("sys_results_00 = %d", dut.sys_results_00);
        $display("results_storage[0] = %d", dut.spi_ctrl.results_storage[0]);
        
        // Manually inject test values to verify SPI read works
        $display("Injecting test values...");
        force dut.spi_ctrl.results_storage[0] = 32'd100;
        force dut.spi_ctrl.results_storage[1] = 32'd200;
        #100;
        
        // Try to read first result via SPI
        $display("Sending READ command (0x40)...");
        spi_send_byte(8'h40, received_byte);
        #200;
        
        $display("Reading first result bytes...");
        spi_send_byte(8'h00, received_byte);
        $display("Byte 0: received=0x%02x (expected=0x64)", received_byte);
        
        spi_send_byte(8'h00, received_byte);
        $display("Byte 1: received=0x%02x (expected=0x00)", received_byte);
        
        spi_send_byte(8'h00, received_byte);
        $display("Byte 2: received=0x%02x (expected=0x00)", received_byte);
        
        spi_send_byte(8'h00, received_byte);  
        $display("Byte 3: received=0x%02x (expected=0x00)", received_byte);
        
        // Check what the SPI controller thinks it's doing
        $display("Controller state after read: %d", dut.spi_ctrl.state);
        $display("Element index: %d", dut.spi_ctrl.element_index);
        $display("Byte index: %d", dut.spi_ctrl.byte_index);
        
        release dut.spi_ctrl.results_storage[0];
        release dut.spi_ctrl.results_storage[1];
        
        $finish;
    end
    
endmodule
