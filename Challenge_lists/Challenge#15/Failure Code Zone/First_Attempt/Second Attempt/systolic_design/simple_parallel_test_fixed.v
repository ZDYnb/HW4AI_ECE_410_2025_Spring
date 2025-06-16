`timescale 1ns/1ps

module simple_parallel_test_fixed;
    reg [7:0]  data_in;
    wire [7:0] data_out;
    reg [5:0]  addr;
    reg        write_en, read_en, start;
    wire       ready, done;
    reg        clk, rst_n;
    
    // Declare variables at module level
    reg [7:0] b0, b1, b2, b3;
    
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
        $display("=== SIMPLE PARALLEL TEST ===");
        
        data_in = 0; addr = 0; write_en = 0; read_en = 0; start = 0; rst_n = 0;
        #100; rst_n = 1; #50;
        wait(ready == 1'b1);
        
        $display("Loading simple test: A[0][0]=1, A[0][1]=1, B[0][0]=2, B[1][0]=3");
        
        // Load Matrix A: Only first row [1, 1, 0, 0]
        write_byte(0, 8'd1);   write_byte(1, 8'd0);   // A[0][0] = 1
        write_byte(2, 8'd1);   write_byte(3, 8'd0);   // A[0][1] = 1
        // All other A elements = 0
        
        // Load Matrix B: Only first column [2; 3; 0; 0]
        write_byte(32, 8'd2);  // B[0][0] = 2
        write_byte(36, 8'd3);  // B[1][0] = 3 (B[1][0] is at index 4, address 32+4=36)
        // All other B elements = 0
        
        // Expected result: A[0][0] = 1*2 + 1*3 = 5
        
        // Start computation
        @(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
        wait(done == 1'b1);
        
        $display("Computation completed. Reading result...");
        
        // Read result[0][0] manually byte by byte
        read_byte(48, b0);  // result_bytes[0]
        read_byte(49, b1);  // result_bytes[1]  
        read_byte(50, b2);  // result_bytes[2]
        read_byte(51, b3);  // result_bytes[3]
        
        $display("Raw bytes: b0=0x%02x, b1=0x%02x, b2=0x%02x, b3=0x%02x", b0, b1, b2, b3);
        $display("Reconstructed result[0][0] = %0d (expected: 5)", {b3, b2, b1, b0});
        
        // Check internal values
        $display("Internal result_00 = %0d", dut.result_00);
        $display("Internal result_bytes[0:3] = 0x%02x 0x%02x 0x%02x 0x%02x", 
                 dut.result_bytes[0], dut.result_bytes[1], dut.result_bytes[2], dut.result_bytes[3]);
        
        // Test a few more results
        read_byte(52, b0);  read_byte(53, b1);  read_byte(54, b2);  read_byte(55, b3);
        $display("Result[0][1] = %0d (expected: 0)", {b3, b2, b1, b0});
        
        read_byte(56, b0);  read_byte(57, b1);  read_byte(58, b2);  read_byte(59, b3);
        $display("Result[0][2] = %0d (expected: 0)", {b3, b2, b1, b0});
        
        // Check if there's an addressing issue
        $display("=== ADDRESS DEBUG ===");
        $display("Address 48 (result_bytes[0]) should map to result_bytes[48-48=0]");
        $display("Address 52 (result_bytes[4]) should map to result_bytes[52-48=4]");
        $display("Address 56 (result_bytes[8]) should map to result_bytes[56-48=8]");
        
        if ({b3, b2, b1, b0} == 32'd5) begin
            $display("SUCCESS: Simple test passed!");
        end else begin
            $display("FAILED: Expected 5, got %0d", {b3, b2, b1, b0});
        end
        
        $finish;
    end
endmodule
