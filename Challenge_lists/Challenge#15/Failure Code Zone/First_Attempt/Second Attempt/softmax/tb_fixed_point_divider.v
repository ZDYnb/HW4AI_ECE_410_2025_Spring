`timescale 1ns/1ps

module tb_fixed_point_divider;

// =========================================== 
// Testbench signals
// ===========================================
reg clk;
reg rst_n;
reg start_div;
reg [15:0] numerator;    // S5.10
reg [23:0] denominator;  // S13.10
wire [15:0] quotient;    // S5.10
wire div_valid;

// Test control
integer test_num;
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
fixed_point_divider dut (
    .clk(clk),
    .rst_n(rst_n),
    .start_div(start_div),
    .numerator(numerator),
    .denominator(denominator),
    .quotient(quotient),
    .div_valid(div_valid)
);

// =========================================== 
// Fixed point conversion functions
// ===========================================
function real s5p10_to_real;
    input [15:0] fixed_val;
    begin
        if (fixed_val[15]) // negative
            s5p10_to_real = -((~fixed_val + 1) / 1024.0);
        else
            s5p10_to_real = fixed_val / 1024.0;
    end
endfunction

function real s13p10_to_real;
    input [23:0] fixed_val;
    begin
        if (fixed_val[23]) // negative  
            s13p10_to_real = -((~fixed_val + 1) / 1024.0);
        else
            s13p10_to_real = fixed_val / 1024.0;
    end
endfunction

function [15:0] real_to_s5p10;
    input real val;
    begin
        if (val < 0)
            real_to_s5p10 = ~(((-val) * 1024.0) - 1) + 1;
        else
            real_to_s5p10 = val * 1024.0;
    end
endfunction

function [23:0] real_to_s13p10;
    input real val;
    begin
        if (val < 0)
            real_to_s13p10 = ~(((-val) * 1024.0) - 1) + 1;
        else
            real_to_s13p10 = val * 1024.0;
    end
endfunction

// =========================================== 
// Test task
// ===========================================
task run_division_test;
    input real num_val;
    input real den_val;
    input real expected;
    input [200*8:1] test_name;
    begin
        $display("\n=== %s ===", test_name);
        
        // Set up inputs
        numerator = real_to_s5p10(num_val);
        denominator = real_to_s13p10(den_val);
        expected_result = expected;
        
        $display("Input: %f ÷ %f", num_val, den_val);
        $display("Expected: %f", expected_result);
        
        // Start division
        start_div = 1;
        @(posedge clk);
        start_div = 0;
        
        // Wait for completion
        wait(div_valid);
        @(posedge clk);
        
        // Check result
        actual_result = s5p10_to_real(quotient);
        error_percent = ((actual_result - expected_result) / expected_result) * 100.0;
        
        $display("Actual: %f", actual_result);
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
    $display("Fixed Point Divider Testbench");  
    $display("S5.10 ÷ S13.10 ¿ S5.10 Division Unit");
    $display("===========================================");
    
    // Initialize
    rst_n = 0;
    start_div = 0;
    numerator = 0;
    denominator = 0;
    
    // Reset sequence
    repeat(3) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    
    // Test 1: Basic division
    run_division_test(1.0, 2.0, 0.5, "Test 1: Basic Division 1.0÷2.0");
    
    // Test 2: Softmax typical case
    run_division_test(0.368, 2.718, 0.135, "Test 2: Softmax Case 0.368÷2.718");
    
    // Test 3: Small numerator
    run_division_test(0.001, 1.0, 0.001, "Test 3: Small Value 0.001÷1.0");
    
    // Test 4: Large denominator  
    run_division_test(1.0, 64.0, 0.015625, "Test 4: Large Denominator 1.0÷64.0");
    
    // Test 5: Equal values
    run_division_test(1.5, 1.5, 1.0, "Test 5: Equal Values 1.5÷1.5");
    
    // Test 6: Timing test
    $display("\n=== Test 6: Pipeline Timing ===");
    numerator = real_to_s5p10(1.0);
    denominator = real_to_s13p10(4.0);
    
    start_div = 1;
    $display("Cycle 0: start_div=1");
    @(posedge clk);
    start_div = 0;
    
    // Check timing
    test_num = 1;
    while (!div_valid && test_num <= 20) begin
        $display("Cycle %d: div_valid=0", test_num);
        @(posedge clk);
        test_num = test_num + 1;
    end
    
    if (div_valid) begin
        actual_result = s5p10_to_real(quotient);
        $display("Cycle %d: div_valid=1, result=%f", test_num, actual_result);
        $display("¿ PASS: Division completed in %d cycles", test_num);
    end else begin
        $display("¿ FAIL: Division did not complete within 20 cycles");
    end
    
    $display("\n===========================================");
    $display("Fixed Point Divider test completed!");
    $display("===========================================");
    
    $finish;
end

endmodule
