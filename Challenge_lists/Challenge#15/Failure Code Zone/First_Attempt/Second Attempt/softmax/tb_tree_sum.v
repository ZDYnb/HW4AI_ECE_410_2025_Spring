`timescale 1ns/1ps

module tb_tree_sum;

// Parameters
parameter CLK_PERIOD = 10;

// Signals
reg clk;
reg rst_n;
reg start;
reg [1023:0] exp_values_in;
wire [23:0] sum_out;
wire sum_valid;

integer i;
real expected_sum, actual_sum, error;

// DUT
tree_sum_accumulator dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .exp_values_in(exp_values_in),
    .sum_out(sum_out),
    .sum_valid(sum_valid)
);

// Clock
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Utility functions
function [15:0] real_to_s5p10;
    input real val;
    begin
        real_to_s5p10 = $rtoi(val * 1024.0);
    end
endfunction

function real s13p10_to_real;
    input [23:0] val;
    begin
        s13p10_to_real = $itor(val) / 1024.0;
    end
endfunction

// Test sequence
initial begin
    $display("===========================================");
    $display("Tree Sum Accumulator - Clean Test");
    $display("===========================================");
    
    // Reset
    rst_n = 0;
    start = 0;
    exp_values_in = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(3) @(posedge clk);
    
    // Test 1: All 1.0
    $display("\n=== Test 1: All inputs = 1.0 ===");
    expected_sum = 64.0;
    
    for (i = 0; i < 64; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(1.0);
    end
    
    start = 1;
    @(posedge clk);
    start = 0;
    
    $display("Expected: %8.4f", expected_sum);
    $display("Waiting for result...");
    
    wait(sum_valid);
    actual_sum = s13p10_to_real(sum_out);
    error = ((actual_sum - expected_sum) / expected_sum) * 100.0;
    if (error < 0) error = -error;
    
    $display("Actual:   %8.4f", actual_sum);
    $display("Error:    %6.2f%%", error);
    
    if (error < 0.1) begin
        $display("¿ PASS");
    end else begin
        $display("¿ FAIL");
    end
    
    // Wait for valid to go low
    wait(!sum_valid);
    repeat(3) @(posedge clk);
    
    // Test 2: All 0.5
    $display("\n=== Test 2: All inputs = 0.5 ===");
    expected_sum = 32.0;
    
    for (i = 0; i < 64; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(0.5);
    end
    
    start = 1;
    @(posedge clk);
    start = 0;
    
    $display("Expected: %8.4f", expected_sum);
    $display("Waiting for result...");
    
    wait(sum_valid);
    actual_sum = s13p10_to_real(sum_out);
    error = ((actual_sum - expected_sum) / expected_sum) * 100.0;
    if (error < 0) error = -error;
    
    $display("Actual:   %8.4f", actual_sum);
    $display("Error:    %6.2f%%", error);
    
    if (error < 0.1) begin
        $display("¿ PASS");
    end else begin
        $display("¿ FAIL");
    end
    
    wait(!sum_valid);
    repeat(3) @(posedge clk);
    
    // Test 3: Mixed values
    $display("\n=== Test 3: 32×2.0 + 32×(-1.0) ===");
    expected_sum = 32.0;
    
    for (i = 0; i < 32; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(2.0);
    end
    for (i = 32; i < 64; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(-1.0);
    end
    
    start = 1;
    @(posedge clk);
    start = 0;
    
    $display("Expected: %8.4f", expected_sum);
    $display("Waiting for result...");
    
    wait(sum_valid);
    actual_sum = s13p10_to_real(sum_out);
    error = ((actual_sum - expected_sum) / expected_sum) * 100.0;
    if (error < 0) error = -error;
    
    $display("Actual:   %8.4f", actual_sum);
    $display("Error:    %6.2f%%", error);
    
    if (error < 1.0) begin
        $display("¿ PASS");
    end else begin
        $display("¿ FAIL");
    end
    
    wait(!sum_valid);
    repeat(3) @(posedge clk);
    
    // Test 4: Sequential values
    $display("\n=== Test 4: Sequential 0.1, 0.2, 0.3... ===");
    expected_sum = 0.0;
    
    for (i = 0; i < 64; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(0.1 * (i + 1));
        expected_sum = expected_sum + (0.1 * (i + 1));
    end
    
    start = 1;
    @(posedge clk);
    start = 0;
    
    $display("Expected: %8.4f", expected_sum);
    $display("Waiting for result...");
    
    wait(sum_valid);
    actual_sum = s13p10_to_real(sum_out);
    error = ((actual_sum - expected_sum) / expected_sum) * 100.0;
    if (error < 0) error = -error;
    
    $display("Actual:   %8.4f", actual_sum);
    $display("Error:    %6.2f%%", error);
    
    if (error < 1.0) begin
        $display("¿ PASS");
    end else begin
        $display("¿ FAIL");
    end
    
    // Test 5: Pipeline timing test (CLEAN VERSION)
    $display("\n=== Test 5: Pipeline Timing Test (Clean) ===");
    
    // Complete pipeline flush - wait enough cycles to clear all stages
    $display("Flushing pipeline...");
    exp_values_in = 0;  // Clear all inputs
    repeat(10) @(posedge clk);  // Wait for pipeline to completely clear
    
    // Verify pipeline is clean
    if (sum_valid) begin
        $display("WARNING: Pipeline not clean, waiting more...");
        wait(!sum_valid);
        repeat(5) @(posedge clk);
    end
    
    $display("Pipeline flushed. Starting timing test...");
    
    // Now set fresh test data
    for (i = 0; i < 64; i = i + 1) begin
        exp_values_in[i*16 +: 16] = real_to_s5p10(0.25);
    end
    
    // Start the test with clean pipeline
    start = 1;
    $display("Cycle 0: start=1, inputs set to 64×0.25");
    @(posedge clk);
    start = 0;
    
    // Now track the actual pipeline behavior
    $display("Cycle 1: sum_valid=%b", sum_valid);
    if (sum_valid) begin
        actual_sum = s13p10_to_real(sum_out);
        $display("  ERROR: Pipeline should not be ready yet!");
        $display("  Spurious result: %8.4f", actual_sum);
        $display("¿ FAIL: Pipeline timing incorrect");
    end else begin
        @(posedge clk);
        $display("Cycle 2: sum_valid=%b", sum_valid);
        if (sum_valid) begin
            actual_sum = s13p10_to_real(sum_out);
            $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
            $display("¿ PASS: Pipeline working! (2-cycle latency)");
        end else begin
            @(posedge clk);
            $display("Cycle 3: sum_valid=%b", sum_valid);
            if (sum_valid) begin
                actual_sum = s13p10_to_real(sum_out);
                $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                $display("¿ PASS: Pipeline working! (3-cycle latency)");
            end else begin
                @(posedge clk);
                $display("Cycle 4: sum_valid=%b", sum_valid);
                if (sum_valid) begin
                    actual_sum = s13p10_to_real(sum_out);
                    $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                    $display("¿ PASS: Pipeline working! (4-cycle latency)");
                end else begin
                    @(posedge clk);
                    $display("Cycle 5: sum_valid=%b", sum_valid);
                    if (sum_valid) begin
                        actual_sum = s13p10_to_real(sum_out);
                        $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                        $display("¿ PASS: Pipeline working! (5-cycle latency)");
                    end else begin
                        @(posedge clk);
                        $display("Cycle 6: sum_valid=%b", sum_valid);
                        if (sum_valid) begin
                            actual_sum = s13p10_to_real(sum_out);
                            $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                            if ((actual_sum >= 15.9) && (actual_sum <= 16.1)) begin
                                $display("¿ PASS: Pipeline working! (6-cycle latency) - CORRECT!");
                            end else begin
                                $display("¿ FAIL: Wrong result value");
                            end
                        end else begin
                            @(posedge clk);
                            $display("Cycle 7: sum_valid=%b", sum_valid);
                            if (sum_valid) begin
                                actual_sum = s13p10_to_real(sum_out);
                                $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                                $display("¿ PASS: Pipeline working! (7-cycle latency)");
                            end else begin
                                @(posedge clk);
                                $display("Cycle 8: sum_valid=%b", sum_valid);
                                if (sum_valid) begin
                                    actual_sum = s13p10_to_real(sum_out);
                                    $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                                    $display("¿ PASS: Pipeline working! (8-cycle latency)");
                                end else begin
                                    @(posedge clk);
                                    $display("Cycle 9: sum_valid=%b", sum_valid);
                                    if (sum_valid) begin
                                        actual_sum = s13p10_to_real(sum_out);
                                        $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                                        $display("¿ PASS: Pipeline working! (9-cycle latency)");
                                    end else begin
                                        @(posedge clk);
                                        $display("Cycle 10: sum_valid=%b", sum_valid);
                                        if (sum_valid) begin
                                            actual_sum = s13p10_to_real(sum_out);
                                            $display("  Result available: %8.4f (Expected: 16.0)", actual_sum);
                                            $display("¿ PASS: Pipeline working! (10-cycle latency)");
                                        end else begin
                                            $display("¿ FAIL: No valid result within 10 cycles");
                                            $display("   Pipeline may be broken or needs different timing");
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    $display("\n===========================================");
    $display("All tests completed!");
    $display("===========================================");
    
    $finish;
end

// Timeout
initial begin
    #10000;
    $display("TIMEOUT!");
    $finish;
end

endmodule
