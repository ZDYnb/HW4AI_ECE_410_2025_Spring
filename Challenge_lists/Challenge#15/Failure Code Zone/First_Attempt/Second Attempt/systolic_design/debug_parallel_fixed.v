`timescale 1ns/1ps

module debug_parallel_fixed;
    reg [7:0]  data_in;
    wire [7:0] data_out;
    reg [5:0]  addr;
    reg        write_en, read_en, start;
    wire       ready, done;
    reg        clk, rst_n;
    
    // Declare variables at module level
    reg [7:0] byte0, byte1, byte2, byte3;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    systolic_parallel_wrapper dut (
        .data_in(data_in), .data_out(data_out), .addr(addr),
        .write_en(write_en), .read_en(read_en), .start(start),
        .ready(ready), .done(done), .clk(clk), .rst_n(rst_n)
    );
    
    task write_byte;
        input [5:0] address;
        input [7:0] data;
    begin
        @(posedge clk);
        addr = address; data_in = data; write_en = 1'b1; read_en = 1'b0;
        @(posedge clk);
        write_en = 1'b0; #10;
    end
    endtask
    
    task read_byte;
        input [5:0] address;
        output [7:0] data;
    begin
        @(posedge clk);
        addr = address; write_en = 1'b0; read_en = 1'b1;
        @(posedge clk);
        data = data_out; read_en = 1'b0; #10;
    end
    endtask
    
    initial begin
        data_in = 0; addr = 0; write_en = 0; read_en = 0; start = 0; rst_n = 0;
        #100; rst_n = 1; #50;
        wait(ready == 1'b1);
        
        $display("=== DEBUG: Check Internal Results ===");
        
        // Load simple test: A[0][0]=1, others=0
        write_byte(0, 8'd1);   // A[0][0] low byte
        write_byte(1, 8'd0);   // A[0][0] high byte
        // All other A elements = 0 (already initialized)
        
        write_byte(32, 8'd1);  // B[0][0] = 1
        // All other B elements = 0
        
        // Start computation
        @(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
        wait(done == 1'b1);
        
        // Check what the systolic array produced
        $display("Internal result_00 = 0x%08x (%0d)", dut.result_00, dut.result_00);
        $display("Internal result_01 = 0x%08x (%0d)", dut.result_01, dut.result_01);
        
        // Check what got stored in result_bytes
        $display("result_bytes[0] = 0x%02x", dut.result_bytes[0]);
        $display("result_bytes[1] = 0x%02x", dut.result_bytes[1]);
        $display("result_bytes[2] = 0x%02x", dut.result_bytes[2]);
        $display("result_bytes[3] = 0x%02x", dut.result_bytes[3]);
        
        // Try to read back via interface
        read_byte(48, byte0);
        read_byte(49, byte1);
        read_byte(50, byte2);
        read_byte(51, byte3);
        
        $display("Read via interface:");
        $display("  byte0 = 0x%02x", byte0);
        $display("  byte1 = 0x%02x", byte1);
        $display("  byte2 = 0x%02x", byte2);
        $display("  byte3 = 0x%02x", byte3);
        
        $display("Reconstructed = 0x%08x (%0d)", {byte3, byte2, byte1, byte0}, {byte3, byte2, byte1, byte0});
        
        $finish;
    end
endmodule
