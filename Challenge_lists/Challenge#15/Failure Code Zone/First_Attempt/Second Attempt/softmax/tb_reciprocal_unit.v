`timescale 1ns/1ps

module tb_reciprocal_unit;

// =========================================== 
// Testbench signals
// ===========================================
reg clk;
reg rst_n;
reg signed [23:0] X_in;
reg valid_in;
wire signed [23:0] reciprocal_out;
wire valid_out;

// Test control
integer test_num;
real input_val;
real expected_result;
real actual_result;
real error_percent;

// =========================================== 
// Clock generation
// ===========================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

// =========================================== 
// DUT instantiation
// ===========================================
reciprocal_unit #(
    .INPUT_X_WIDTH(24),
    .DIVISOR_WIDTH(24),
    .QUOTIENT_WIDTH(24),
    .FINAL_OUT_WIDTH(24)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .X_in(X_in),
    .valid_in(valid_in),
    .reciprocal_out(reciprocal_out),
    .valid_out(valid_out)
);

// =========================================== 
// Fixed point conversion functions
// S13.10 format for sum values
// ===========================================
function real s13p10_to_real;
    input [23:0] fixed_val;
    begin
        if (fixed_val[23]) // negative
            s13p10_to_real = -(((~fixed_val) + 1) / 1024.0);
        else
            s13p10_to_real = fixed_val / 1024.0;
    end
endfunction

function [23:0] real_to_s13p10;
    input real val;
    reg [23:0] temp_val;
    begin
        if (val < 0) begin
            temp_val = (-val) * 1024.0;
            real_to_s13p10 = (~temp_val) + 1;
        end else begin
            real_to_s13p10 = val * 1024.0;
        end
    end
endfunction

// Convert reciprocal output (2^14 / input) to real
function real reciprocal_to_real;
    input [23:0] recip_val;
    input real original_input;
    begin
        // reciprocal_out = 2^14 / original_input
        // So actual reciprocal = reciprocal_out / 2^14
        reciprocal_to_real = $signed(recip_val) / 16384.0; // 2^14 = 16384
    end
endfunction

// =========================================== 
// Test task
// ===========================================
task run_reciprocal_test;
    input real input_value;
    input [200*8:1] test_name;
    begin
        $display("\n=== %s ===", test_name);
        
        // Set up inputs
        input_val = input_value;
        X_in = real_to_s13p10(input_val);
        expected_result = 1.0 / input_val;
        
        $display("Input: %f (0x%h)", input_val, X_in);
        $display("Expected reciprocal: %f", expected_result);
        
        // Start reciprocal calculation
        valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        
        // Wait for completion
        wait(valid_out);
        @(posedge clk);
        
        // Check result
        actual_result = reciprocal_to_real(reciprocal_out, input_val);
        error_percent = ((actual_result - expected_result) / expected_result) * 100.0;
        
        $display("Hardware output: 0x%h", reciprocal_out);
        $display("Actual reciprocal: %f", actual_result);
        $display("Error: %f%%", error_percent);
        
        if (error_percent < 5.0 && error_percent > -5.0) begin
            $display("¿ PASS");
        end else begin
            $display("¿ FAIL: Error too large");
        end
    end
endtask

// =========================================== 
// Main test sequence
// ===========================================
initial begin
    $display("===========================================");
    $display("Reciprocal Unit Testbench");  
    $display("Testing 1/X calculation for Softmax sums");
    $display("Input: S13.10, Output: 2^14/X format");
    $display("===========================================");
    
    // Initialize
    rst_n = 0;
    valid_in = 0;
    X_in = 0;
    
    // Reset sequence
    repeat(3) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    
    // Test 1: Simple case
    run_reciprocal_test(1.0, "Test 1: Reciprocal of 1.0");
    
    // Test 2: Typical softmax sum
    run_reciprocal_test(2.718, "Test 2: Reciprocal of e (2.718)");
    
    // Test 3: Large sum (64 elements)
    run_reciprocal_test(32.0, "Test 3: Reciprocal of 32.0");
    
    // Test 4: Small sum  
    run_reciprocal_test(0.5, "Test 4: Reciprocal of 0.5");
    
    // Test 5: Realistic softmax sum
    run_reciprocal_test(16.384, "Test 5: Reciprocal of 16.384");
    
    // Test 6: Maximum reasonable sum
    run_reciprocal_test(64.0, "Test 6: Reciprocal of 64.0");
    
    // Test 7: Pipeline timing test
    $display("\n=== Test 7: Pipeline Timing ===");
    X_in = real_to_s13p10(4.0);
    
    valid_in = 1;
    $display("Cycle 0: valid_in=1, X_in=%f", s13p10_to_real(X_in));
    @(posedge clk);
    valid_in = 0;
    
    // Check timing
    test_num = 1;
    while (!valid_out && test_num <= 30) begin
        $display("Cycle %d: valid_out=0", test_num);
        @(posedge clk);
        test_num = test_num + 1;
    end
    
    if (valid_out) begin
        actual_result = reciprocal_to_real(reciprocal_out, 4.0);
        $display("Cycle %d: valid_out=1, result=%f", test_num, actual_result);
        $display("¿ PASS: Reciprocal completed in %d cycles", test_num);
    end else begin
        $display("¿ FAIL: Reciprocal did not complete within 30 cycles");
    end
    
    $display("\n===========================================");
    $display("Reciprocal Unit test completed!");
    $display("Ready for Softmax integration!");
    $display("===========================================");
    
    $finish;
end

endmodule
