`timescale 1ns/1ps

module debug_data_count;
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
    
    // Monitor critical values
    always @(posedge clk) begin
        if (dut.spi_ctrl.state == 1) begin // CMD_DECODE
            $display("Time=%0t: CMD_DECODE - data_count=%d", $time, dut.spi_ctrl.data_count);
        end
        if (dut.spi_ctrl.state == 5) begin // READ_RES  
            $display("Time=%0t: READ_RES - data_count=%d, element_idx=%d, byte_idx=%d", 
                    $time, dut.spi_ctrl.data_count, dut.spi_ctrl.element_index, dut.spi_ctrl.byte_index);
        end
    end
    
    // Monitor state transitions with data_count
    always @(dut.spi_ctrl.state) begin
        $display("Time=%0t: State change to %d, data_count=%d", 
                $time, dut.spi_ctrl.state, dut.spi_ctrl.data_count);
    end
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Debug Data Count Issue ===");
        
        // Send READ command
        spi_send_byte(8'h40, received_byte);
        #1000;
        
        $display("Final analysis:");
        $display("State: %d", dut.spi_ctrl.state);
        $display("Data count: %d", dut.spi_ctrl.data_count);
        $display("Element index: %d", dut.spi_ctrl.element_index);
        
        $finish;
    end
    
endmodule
