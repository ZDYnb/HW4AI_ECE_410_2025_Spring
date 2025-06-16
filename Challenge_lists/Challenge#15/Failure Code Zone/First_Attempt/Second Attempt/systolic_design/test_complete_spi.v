`timescale 1ns/1ps

module test_complete_spi;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper_complete dut (
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
    
    // Monitor state changes
    always @(dut.spi_ctrl.state) begin
        case (dut.spi_ctrl.state)
            0: $display("Time=%0t: State -> IDLE", $time);
            1: $display("Time=%0t: State -> CMD_DECODE", $time);
            5: $display("Time=%0t: State -> READ_RES", $time);
        endcase
    end
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing Complete SPI Fix ===");
        $display("Expected: results[0] = 0x12345678");
        
        // Send READ command
        $display("Sending READ command (0x40)...");
        spi_send_byte(8'h40, received_byte);
        #500;
        
        $display("Controller state: %d", dut.spi_ctrl.state);
        
        // Try to read data
        if (dut.spi_ctrl.state == 5) begin
            $display("SUCCESS: In READ_RES state!");
            
            $display("Reading bytes...");
            spi_send_byte(8'h00, received_byte);
            $display("Byte 0: 0x%02x (expected: 0x78)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 1: 0x%02x (expected: 0x56)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 2: 0x%02x (expected: 0x34)", received_byte);
            
            spi_send_byte(8'h00, received_byte);
            $display("Byte 3: 0x%02x (expected: 0x12)", received_byte);
            
        end else begin
            $display("PROBLEM: Not in READ_RES state");
        end
        
        $finish;
    end
    
endmodule
