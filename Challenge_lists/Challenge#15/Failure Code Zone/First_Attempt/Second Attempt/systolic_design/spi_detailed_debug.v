`timescale 1ns/1ps

module detailed_spi_debug;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper dut (
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n), .irq(irq),
        .clk(clk), .rst_n(rst_n)
    );
    
    // Monitor SPI reception
    always @(posedge dut.spi_if.rx_valid) begin
        $display("Time=%0t: SPI received byte: 0x%02x", $time, dut.spi_if.rx_data);
    end
    
    // Monitor controller state changes
    always @(dut.spi_ctrl.state) begin
        case (dut.spi_ctrl.state)
            0: $display("Time=%0t: Controller -> IDLE", $time);
            1: $display("Time=%0t: Controller -> CMD_DECODE", $time);  
            2: $display("Time=%0t: Controller -> LOAD_A", $time);
            3: $display("Time=%0t: Controller -> LOAD_B", $time);
            4: $display("Time=%0t: Controller -> COMPUTING", $time);
        endcase
    end
    
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
        
        $display("=== Detailed SPI Debug ===");
        
        // Send command
        $display("Sending Load Matrix A command (0x10)...");
        spi_write_byte(8'h10);
        
        #500;
        $display("After command: state=%d, data_count=%d", dut.spi_ctrl.state, dut.spi_ctrl.data_count);
        
        // Send two data bytes
        $display("Sending data byte 1 (0x01)...");
        spi_write_byte(8'h01);
        #100;
        $display("After byte 1: matrix_a[0]=%d, element_index=%d, byte_index=%d", 
                 dut.spi_ctrl.matrix_a_storage[0], dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
        
        $display("Sending data byte 2 (0x00)...");
        spi_write_byte(8'h00);
        #100;
        $display("After byte 2: matrix_a[0]=%d, element_index=%d, byte_index=%d", 
                 dut.spi_ctrl.matrix_a_storage[0], dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
        
        $finish;
    end
endmodule
