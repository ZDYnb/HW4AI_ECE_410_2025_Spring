`timescale 1ns/1ps

module debug_element3;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg [5:0] addr;
    reg write_en, read_en, start;
    wire ready, done;
    reg clk, rst_n;
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
        $display("=== DEBUG ELEMENT 3 ADDRESSING ===");
        
        data_in = 0; addr = 0; write_en = 0; read_en = 0; start = 0; rst_n = 0;
        #100; rst_n = 1; #50;
        wait(ready == 1'b1);
        
        // Load simple case that should give result[0][3] = 16
        // A = [1 1 1 1; 0 0 0 0; 0 0 0 0; 0 0 0 0]  
        // B = [4; 4; 4; 4] (column 3)
        // Result[0][3] should be 1*4 + 1*4 + 1*4 + 1*4 = 16
        
        write_byte(0, 8'd1);   write_byte(1, 8'd0);   // A[0][0] = 1
        write_byte(2, 8'd1);   write_byte(3, 8'd0);   // A[0][1] = 1  
        write_byte(4, 8'd1);   write_byte(5, 8'd0);   // A[0][2] = 1
        write_byte(6, 8'd1);   write_byte(7, 8'd0);   // A[0][3] = 1
        
        write_byte(35, 8'd4);  // B[0][3] = 4 (element 3)
        write_byte(39, 8'd4);  // B[1][3] = 4 (element 7) 
        write_byte(43, 8'd4);  // B[2][3] = 4 (element 11)
        write_byte(47, 8'd4);  // B[3][3] = 4 (element 15)
        
        @(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
        wait(done == 1'b1);
        
        $display("After computation:");
        $display("Internal result_03 = %0d", dut.result_03);
        $display("Internal result_bytes[12:15] = 0x%02x 0x%02x 0x%02x 0x%02x", 
                 dut.result_bytes[12], dut.result_bytes[13], dut.result_bytes[14], dut.result_bytes[15]);
        
        $display("Reading element 3 via interface (addresses 60-63):");
        read_byte(60, b0);  // Should be result_bytes[60-48=12]
        read_byte(61, b1);  // Should be result_bytes[61-48=13]
        read_byte(62, b2);  // Should be result_bytes[62-48=14]  
        read_byte(63, b3);  // Should be result_bytes[63-48=15]
        
        $display("Read bytes: b0=0x%02x, b1=0x%02x, b2=0x%02x, b3=0x%02x", b0, b1, b2, b3);
        $display("Reconstructed = %0d", {b3, b2, b1, b0});
        
        $display("=== ADDRESS MAPPING CHECK ===");
        $display("Address 60 should map to result_bytes[12] (result_03 low byte)");
        $display("Address 61 should map to result_bytes[13] (result_03 byte 1)");
        $display("Address 62 should map to result_bytes[14] (result_03 byte 2)");
        $display("Address 63 should map to result_bytes[15] (result_03 high byte)");
        
        // Check the read logic directly
        $display("Testing read logic:");
        addr = 60; read_en = 1'b1; #1;
        $display("addr=60: data_out=%0d (addr-48=%0d)", data_out, addr-48);
        read_en = 1'b0;
        
        $finish;
    end
endmodule
