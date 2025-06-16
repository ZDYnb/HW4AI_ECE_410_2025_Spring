`timescale 1ns/1ps

module spi_working_test;
    reg clk, rst_n, sclk, mosi, cs_n;
    wire miso, irq;
    
    // Simple counters that ACTUALLY reset
    reg [5:0] my_data_count;
    reg [4:0] my_element_index;
    reg [1:0] my_byte_index;
    reg [2:0] my_state;
    reg [15:0] my_matrix_a [0:15];
    
    // States
    parameter IDLE = 0, CMD_DECODE = 1, LOAD_A = 2;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // SPI reception
    reg [7:0] rx_data;
    reg rx_valid;
    reg [2:0] bit_count;
    reg [7:0] rx_shift;
    
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            bit_count <= 0;
            rx_valid <= 0;
        end else begin
            rx_shift <= {rx_shift[6:0], mosi};
            bit_count <= bit_count + 1;
            if (bit_count == 7) begin
                rx_data <= {rx_shift[6:0], mosi}; 
                rx_valid <= 1;
                bit_count <= 0;
            end else begin
                rx_valid <= 0;
            end
        end
    end
    
    // Simple working state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            my_state <= IDLE;
            my_data_count <= 0;
            my_element_index <= 0; 
            my_byte_index <= 0;
            my_matrix_a[0] <= 0;
        end else begin
            case (my_state)
                IDLE: begin
                    if (rx_valid && !cs_n) begin
                        my_state <= CMD_DECODE;
                        // RESET COUNTERS
                        my_data_count <= 0;
                        my_element_index <= 0;
                        my_byte_index <= 0;
                    end
                end
                
                CMD_DECODE: begin
                    if (rx_data == 8'h10) begin
                        my_state <= LOAD_A;
                        // RESET AGAIN
                        my_data_count <= 0;
                        my_element_index <= 0;
                        my_byte_index <= 0;
                    end
                end
                
                LOAD_A: begin
                    if (rx_valid) begin
                        if (my_byte_index == 0) begin
                            my_matrix_a[my_element_index][7:0] <= rx_data;
                            my_byte_index <= 1;
                        end else begin
                            my_matrix_a[my_element_index][15:8] <= rx_data;
                            my_byte_index <= 0;
                            my_element_index <= my_element_index + 1;
                        end
                        my_data_count <= my_data_count + 1;
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
        cs_n = 1; #100;
    end
    endtask
    
    initial begin
        sclk = 0; mosi = 0; cs_n = 1; rst_n = 0;
        #100; rst_n = 1; #100;
        
        $display("=== Testing SIMPLE Working SPI ===");
        
        // Send command
        spi_write_byte(8'h10);
        #100;
        $display("After command: count=%d, element=%d, state=%d", 
                 my_data_count, my_element_index, my_state);
        
        // Send data
        spi_write_byte(8'h01);
        #100;
        $display("After byte 1: matrix[0]=%d, element=%d, byte_idx=%d", 
                 my_matrix_a[0], my_element_index, my_byte_index);
        
        spi_write_byte(8'h00);
        #100;
        $display("After byte 2: matrix[0]=%d, element=%d, byte_idx=%d", 
                 my_matrix_a[0], my_element_index, my_byte_index);
        
        if (my_matrix_a[0] == 16'd1) begin
            $display("¿ SUCCESS!");
        end else begin
            $display("¿ FAILED: got %d", my_matrix_a[0]);
        end
        
        $finish;
    end
endmodule
