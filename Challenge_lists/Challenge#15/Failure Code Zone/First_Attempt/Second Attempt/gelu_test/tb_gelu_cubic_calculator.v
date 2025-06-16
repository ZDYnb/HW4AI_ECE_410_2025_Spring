// =============================================================================
// Testbench for GELU Cubic Calculator
// =============================================================================
// Tests the cubic calculator with various fixed-point inputs
// Verifies x^3 calculation accuracy and overflow detection
// =============================================================================

`timescale 1ns/1ps

module tb_gelu_cubic_calculator();

// =============================================================================
// Parameters
// =============================================================================
parameter DATA_WIDTH = 24;
parameter FRAC_BITS = 16;
parameter CLK_PERIOD = 10; // 10ns = 100MHz

// =============================================================================
// Testbench Signals
// =============================================================================
reg clk;
reg rst_n;
reg [DATA_WIDTH-1:0] x_in;
reg valid_in;
wire [DATA_WIDTH-1:0] x_cubed_out;
wire valid_out;
wire overflow;

// Test control
reg [31:0] test_count;
reg [DATA_WIDTH-1:0] expected_result;
real x_real, x_cubed_real, result_real;

// =============================================================================
// DUT Instantiation
// =============================================================================
gelu_cubic_calculator #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRAC_BITS(FRAC_BITS)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .x_in(x_in),
    .valid_in(valid_in),
    .x_cubed_out(x_cubed_out),
    .valid_out(valid_out),
    .overflow(overflow)
);

// =============================================================================
// Clock Generation
// =============================================================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// =============================================================================
// Fixed-Point Conversion Functions
// =============================================================================

// Convert real number to fixed-point
function [DATA_WIDTH-1:0] real_to_fixed;
    input real val;
    begin
        real_to_fixed = val * (1 << FRAC_BITS);
    end
endfunction

// Convert fixed-point to real
function real fixed_to_real;
    input [DATA_WIDTH-1:0] val;
    begin
        fixed_to_real = $signed(val) / (1.0 * (1 << FRAC_BITS));
    end
endfunction

// =============================================================================
// Test Stimulus
// =============================================================================
initial begin
    // Initialize
    rst_n = 0;
    x_in = 0;
    valid_in = 0;
    test_count = 0;
    
    $display("=============================================================================");
    $display("GELU Cubic Calculator Testbench Started");
    $display("Data Width: %0d bits, Fractional Bits: %0d", DATA_WIDTH, FRAC_BITS);
    $display("=============================================================================");
    
    // Reset sequence
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    
    // Test Case 1: Small positive values
    $display("\n--- Test Case 1: Small Positive Values ---");
    test_cubic_calculation(0.5);
    test_cubic_calculation(0.25);
    test_cubic_calculation(0.125);
    test_cubic_calculation(1.0);
    
    // Test Case 2: Small negative values  
    $display("\n--- Test Case 2: Small Negative Values ---");
    test_cubic_calculation(-0.5);
    test_cubic_calculation(-0.25);
    test_cubic_calculation(-1.0);
    
    // Test Case 3: Zero
    $display("\n--- Test Case 3: Zero Input ---");
    test_cubic_calculation(0.0);
    
    // Test Case 4: Larger values (may cause overflow)
    $display("\n--- Test Case 4: Larger Values ---");
    test_cubic_calculation(2.0);
    test_cubic_calculation(4.0);
    test_cubic_calculation(-2.0);
    
    // Test Case 5: Edge cases
    $display("\n--- Test Case 5: Edge Cases ---");
    test_cubic_calculation(0.1);
    test_cubic_calculation(-0.1);
    
    // Wait for final results
    repeat(10) @(posedge clk);
    
    $display("\n=============================================================================");
    $display("Testbench Completed - Total Tests: %0d", test_count);
    $display("=============================================================================");
    $finish;
end

// =============================================================================
// Test Task
// =============================================================================
task test_cubic_calculation;
    input real x_val;
    begin
        test_count = test_count + 1;
        
        // Convert input to fixed-point
        x_in = real_to_fixed(x_val);
        x_real = x_val;
        x_cubed_real = x_val * x_val * x_val;
        
        $display("Test %0d: x = %f (0x%h)", test_count, x_val, x_in);
        
        // Apply stimulus
        valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        
        // Wait for result (2 cycles latency)
        wait(valid_out);
        @(posedge clk);
        
        // Check result
        result_real = fixed_to_real(x_cubed_out);
        
        $display("  Expected: %f", x_cubed_real);
        $display("  Got:      %f (0x%h)", result_real, x_cubed_out);
        $display("  Error:    %f (%f%%)", result_real - x_cubed_real, 
                 100.0 * (result_real - x_cubed_real) / (x_cubed_real + 1e-10));
        $display("  Overflow: %b", overflow);
        
        // Check for reasonable accuracy (within 1% for normal range)
        if (x_cubed_real != 0.0 && 
            (result_real - x_cubed_real) / x_cubed_real > 0.01) begin
            $display("  WARNING: Error > 1%%");
        end
        
        $display("");
    end
endtask

// =============================================================================
// Monitoring
// =============================================================================
initial begin
    $monitor("Time: %0t, x_in: %h, x_cubed_out: %h, valid_in: %b, valid_out: %b, overflow: %b",
             $time, x_in, x_cubed_out, valid_in, valid_out, overflow);
end

endmodule
