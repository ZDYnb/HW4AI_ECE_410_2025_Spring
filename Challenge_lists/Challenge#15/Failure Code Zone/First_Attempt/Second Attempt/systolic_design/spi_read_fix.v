// ===========================================
// Fix SPI Read Command Issue
// ===========================================

`timescale 1ns/1ps

module test_spi_read_fix;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    reg [7:0] received_byte;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_spi_wrapper_final dut (
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
            2: $display("Time=%0t: State -> LOAD_A", $time);
            3: $display("Time=%0t: State -> LOAD_B", $time);
            4: $display("Time=%0t: State -> COMPUTING", $time);
            5: $display("Time=%0t: State -> READ_RES", $time);
            6: $display("Time=%0t: State -> SEND_STATUS", $time);
        endcase
    end
    
    // Monitor SPI reception
    always @(posedge dut.spi_if.rx_valid) begin
        $display("Time=%0t: SPI received: 0x%02x", $time, dut.spi_if.rx_data);
    end
    
    // Monitor command processing
    always @(posedge clk) begin
        if (dut.spi_ctrl.state == 1) begin // CMD_DECODE
            $display("Time=%0t: CMD_DECODE - rx_data=0x%02x, current_cmd=0x%02x", 
                    $time, dut.spi_ctrl.spi_rx_data, dut.spi_ctrl.current_cmd);
        end
    end
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing SPI Command Decoding ===");
        
        // Inject test data
        force dut.spi_ctrl.results_storage[0] = 32'h12345678;
        #100;
        
        $display("Sending READ command (0x40)...");
        spi_send_byte(8'h40, received_byte);
        
        #1000; // Wait for state transitions
        
        $display("Current state: %d", dut.spi_ctrl.state); 
        $display("Current command: 0x%02x", dut.spi_ctrl.current_cmd);
        
        // If we're in READ_RES state, try reading
        if (dut.spi_ctrl.state == 5) begin
            $display("SUCCESS: Entered READ_RES state!");
            $display("Attempting to read data...");
            
            spi_send_byte(8'h00, received_byte);
            $display("Read byte 0: 0x%02x (expected: 0x78)", received_byte);
            
        end else begin
            $display("PROBLEM: Did not enter READ_RES state");
            $display("Checking command constants...");
            $display("CMD_READ_RES should be: 0x40");
        end
        
        release dut.spi_ctrl.results_storage[0];
        $finish;
    end
    
endmodule
