// ===========================================
// Simple Conversion Test Module
// ===========================================
`timescale 1ns/1ps

module test_simple_convert;

reg [31:0] test_input;
wire [15:0] test_output;

// Test the conversion logic directly
assign test_output = (test_input >>> 6) + test_input[5];

initial begin
    $display("=== Simple Conversion Test ===");
    
    // Test case 1: 0x00010000 (1.0 in S15.16)
    test_input = 32'h00010000;
    #1;
    $display("Input: 0x%08h, Output: 0x%04h", test_input, test_output);
    $display("Expected: 0x0400");
    
    // Test case 2: 0x00020000 (2.0 in S15.16)  
    test_input = 32'h00020000;
    #1;
    $display("Input: 0x%08h, Output: 0x%04h", test_input, test_output);
    $display("Expected: 0x0800");
    
    $finish;
end

endmodule
