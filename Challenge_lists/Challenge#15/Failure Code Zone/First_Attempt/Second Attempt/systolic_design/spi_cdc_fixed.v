`timescale 1ns/1ps

module spi_cdc_test;
    reg clk, rst_n, sclk, mosi, cs_n;
    
    // Simple counters
    reg [5:0] data_count;
    reg [4:0] element_index;
    reg [1:0] byte_index;
    reg [2:0] state;
    reg [15:0] matrix_a [0:15];
    
    parameter IDLE = 0, CMD_DECODE = 1, LOAD_A = 2;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // SPI reception with CDC
    reg [7:0] rx_data_spi;
    reg rx_valid_spi;
    reg [2:0] bit_count;
    reg [7:0] rx_shift;
    
    // Clock domain crossing - synchronize SPI to system clock
    reg rx_valid_sync1, rx_valid_sync2, rx_valid_sync3;
    reg [7:0] rx_data_sync;
    wire rx_valid_pulse;
    
    // SPI reception (in SCLK domain)
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            bit_count <= 0;
            rx_valid_spi <= 0;
        end else begin
            rx_shift <= {rx_shift[6:0], mosi};
            bit_count <= bit_count + 1;
            if (bit_count == 7) begin
                rx_data_spi <= {rx_shift[6:0], mosi}; 
                rx_valid_spi <= 1;
                bit_count <= 0;
            end else begin
                rx_valid_spi <= 0;
            end
        end
    end
    
    // Synchronize to system clock domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_sync1 <= 0;
            rx_valid_sync2 <= 0;
            rx_valid_sync3 <= 0;
            rx_data_sync <= 0;
        end else begin
            rx_valid_sync1 <= rx_valid_spi;
            rx_valid_sync2 <= rx_valid_sync1;
            rx_valid_sync3 <= rx_valid_sync2;
            if (rx_valid_spi) rx_data_sync <= rx_data_spi;
        end
    end
    
    // Edge detection for single pulse
    assign rx_valid_pulse = rx_valid_sync2 && !rx_valid_sync3;
    
    // State machine (in system clock domain)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_count <= 0;
            element_index <= 0; 
            byte_index <= 0;
            matrix_a[0] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (rx_valid_pulse && !cs_n) begin
                        state <= CMD_DECODE;
                        data_count <= 0;
                        element_index <= 0;
                        byte_index <= 0;
                        $display("Time=%0t: IDLE->CMD_DECODE, rx_data=0x%02x", $time, rx_data_sync);
                    end
                end
                
                CMD_DECODE: begin
                    if (rx_data_sync == 8'h10) begin
                        state <= LOAD_A;
                        data_count <= 0;
                        element_index <= 0;
                        byte_index <= 0;
                        $display("Time=%0t: CMD_DECODE->LOAD_A", $time);
                    end
                end
                
                LOAD_A: begin
                    if (rx_valid_pulse) begin
                        $display("Time=%0t: LOAD_A rx=0x%02x, elem=%d, byte=%d", 
                                $time, rx_data_sync, element_index, byte_index);
                        if (byte_index == 0) begin
                            matrix_a[element_index][7:0] <= rx_data_sync;
                            byte_index <= 1;
                        end else begin
                            matrix_a[element_index][15:8] <= rx_data_sync;
                            byte_index <= 0;
                            element_index <= element_index + 1;
                        end
                        data_count <= data_count + 1;
                    end
                end
            endcase
        end
    end
    
    task spi_write_byte;
        input [7:0] data;
        integer i;
    begin
        cs_n = 0; #50;
        for (i = 7; i >= 0; i = i - 1) begin
            mosi = data[i]; #50; sclk = 1; #50; sclk = 0; #50;
        end
        cs_n = 1; #200; // Longer gap
    end
    endtask
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing CDC Fixed SPI ===");
        
        spi_write_byte(8'h10);
        #500;
        $display("After command: count=%d, element=%d, state=%d", 
                 data_count, element_index, state);
        
        spi_write_byte(8'h01);
        #500;
        $display("After byte 1: matrix[0]=%d, element=%d, byte_idx=%d", 
                 matrix_a[0], element_index, byte_index);
        
        spi_write_byte(8'h00);
        #500;
        $display("After byte 2: matrix[0]=%d, element=%d, byte_idx=%d", 
                 matrix_a[0], element_index, byte_index);
        
        if (matrix_a[0] == 16'd1) begin
            $display("✅ SUCCESS!");
        end else begin
            $display("❌ FAILED: got %d", matrix_a[0]);
        end
        
        $finish;
    end
endmodule
