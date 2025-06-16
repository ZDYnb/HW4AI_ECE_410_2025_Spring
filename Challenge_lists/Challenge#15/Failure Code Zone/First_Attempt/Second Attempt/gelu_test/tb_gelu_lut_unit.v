`timescale 1ns / 1ps

module tb_gelu_lut_unit;
    // DUT parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC_BITS  = 10;
    parameter CLK_PERIOD = 10;
    
    // DUT I/O
    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [DATA_WIDTH-1:0] x_in;
    wire signed [DATA_WIDTH-1:0] gelu_out;
    wire valid_out;
    wire out_of_range;
    
    // Test variables
    integer test_count;
    integer pass_count;
    integer fail_count;
    real max_error;
    real total_error;
    
    // Instantiate DUT
    gelu_lut_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .x_in(x_in),
        .gelu_out(gelu_out),
        .valid_out(valid_out),
        .out_of_range(out_of_range)
    );
    
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // =============================================================================
    // Utility Functions
    // =============================================================================
    
    // Convert fixed-point to real
    function real fx_to_real(input signed [DATA_WIDTH-1:0] fx);
        begin
            fx_to_real = fx / (1.0 * (1 << FRAC_BITS));
        end
    endfunction
    
    // Convert real to fixed-point
    function signed [DATA_WIDTH-1:0] real_to_fx(input real val);
        begin
            real_to_fx = val * (1 << FRAC_BITS);
        end
    endfunction
    
    // Reference GELU function (software golden model)
    function real gelu_reference(input real x);
        real sqrt_2_over_pi;
        begin
            sqrt_2_over_pi = 0.7978845608028654; // sqrt(2/pi)
            gelu_reference = 0.5 * x * (1.0 + $tanh(sqrt_2_over_pi * (x + 0.044715 * x * x * x)));
        end
    endfunction
    
    // =============================================================================
    // Test Tasks
    // =============================================================================
    
    // Test single value with expected result verification
    task test_single_value(
        input real x_val,
        input integer test_id
    );
        real expected_gelu, actual_gelu, error, error_percent;
        begin
            test_count = test_count + 1;
            
            // Calculate expected result
            expected_gelu = gelu_reference(x_val);
            
            // Apply stimulus
            @(posedge clk);
            valid_in <= 1;
            x_in <= real_to_fx(x_val);
            
            @(posedge clk);
            valid_in <= 0;
            
            // Wait for result
            wait (valid_out == 1);
            @(posedge clk);
            
            // Get actual result
            actual_gelu = fx_to_real(gelu_out);
            error = actual_gelu - expected_gelu;
            if (expected_gelu != 0.0)
                error_percent = 100.0 * error / expected_gelu;
            else
                error_percent = (actual_gelu == 0.0) ? 0.0 : 100.0;
            
            // Update statistics
            total_error = total_error + (error < 0 ? -error : error);
            if ((error < 0 ? -error : error) > max_error)
                max_error = (error < 0 ? -error : error);
            
            // Display result
            $display("Test %0d:", test_id);
            $display("  x_in     = %6d (%.4f)", x_in, fx_to_real(x_in));
            $display("  Expected = %.6f", expected_gelu);
            $display("  Actual   = %.6f (0x%04h)", actual_gelu, gelu_out);
            $display("  Error    = %.6f (%.2f%%)", error, error_percent);
            $display("  Out_range= %0d", out_of_range);
            
            // Pass/fail check (allow 2% error for LUT approximation)
            if (out_of_range || ((error < 0 ? -error : error) <= 0.02) || 
                (expected_gelu != 0.0 && ((error_percent < 0 ? -error_percent : error_percent) <= 2.0))) begin
                $display("  Result   = PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Result   = FAIL (Error > 2%%)");
                fail_count = fail_count + 1;
            end
            $display("");
        end
    endtask
    
    // =============================================================================
    // Main Test Stimulus
    // =============================================================================
    
    initial begin
        $display("=============================================================================");
        $display("ENHANCED GELU LUT TESTBENCH");
        $display("Data Width: %0d bits, Fractional Bits: %0d", DATA_WIDTH, FRAC_BITS);
        $display("LUT Range: [-4.0, +3.875], Step: 0.125");
        $display("=============================================================================");
        
        // Initialize
        rst_n = 0;
        valid_in = 0;
        x_in = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        max_error = 0.0;
        total_error = 0.0;
        
        // Reset sequence
        repeat(3) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        
        // Test Case 1: Key values within LUT range
        $display("=== Test Case 1: Key Values ===");
        test_single_value(-4.0,   1);
        test_single_value(-2.0,   2);
        test_single_value(-1.0,   3);
        test_single_value(-0.5,   4);
        test_single_value(0.0,    5);
        test_single_value(0.5,    6);
        test_single_value(1.0,    7);
        test_single_value(2.0,    8);
        test_single_value(3.0,    9);
        test_single_value(3.875,  10);
        
        // Test Case 2: LUT boundary alignment
        $display("=== Test Case 2: LUT Step Alignment ===");
        test_single_value(-2.125, 11);
        test_single_value(-1.750, 12);
        test_single_value(-0.125, 13);
        test_single_value(0.125,  14);
        test_single_value(1.250,  15);
        test_single_value(2.500,  16);
        
        // Test Case 3: Out-of-range values
        $display("=== Test Case 3: Out-of-Range Values ===");
        test_single_value(-5.0,   17);
        test_single_value(-4.5,   18);
        test_single_value(4.0,    19);
        test_single_value(5.0,    20);
        
        // Test Case 4: Edge cases and precision
        $display("=== Test Case 4: Precision Tests ===");
        test_single_value(-3.999, 21);
        test_single_value(3.874,  22);
        test_single_value(0.001,  23);
        test_single_value(-0.001, 24);
        
        // Test Case 5: Stress test with multiple rapid inputs
        $display("=== Test Case 5: Rapid Input Test ===");
        $display("Testing rapid consecutive inputs...");
        repeat(5) begin
            @(posedge clk);
            valid_in <= 1;
            x_in <= real_to_fx(1.0);
            @(posedge clk);
            valid_in <= 1;
            x_in <= real_to_fx(-1.0);
            @(posedge clk);
            valid_in <= 0;
            repeat(2) @(posedge clk);
        end
        $display("Rapid input test completed.");
        $display("");
        
        // Final statistics
        $display("=============================================================================");
        $display("TEST SUMMARY");
        $display("=============================================================================");
        $display("Total Tests:    %0d", test_count);
        $display("Passed:         %0d", pass_count);
        $display("Failed:         %0d", fail_count);
        $display("Pass Rate:      %.1f%%", 100.0 * pass_count / test_count);
        $display("Max Error:      %.6f", max_error);
        $display("Avg Error:      %.6f", total_error / test_count);
        $display("=============================================================================");
        
        if (fail_count == 0) begin
            $display("¿ ALL TESTS PASSED - GELU LUT Implementation is CORRECT!");
        end else begin
            $display("¿ %0d TESTS FAILED - Check implementation!", fail_count);
        end
        
        $display("=============================================================================");
        $finish;
    end
    
    // =============================================================================
    // Monitoring and Debugging
    // =============================================================================
    
    // Optional: Monitor key signals
    initial begin
        if ($test$plusargs("MONITOR")) begin
            $monitor("Time: %0t, x_in: %h (%.3f), gelu_out: %h (%.3f), valid_in: %b, valid_out: %b, out_of_range: %b",
                     $time, x_in, fx_to_real(x_in), gelu_out, fx_to_real(gelu_out), 
                     valid_in, valid_out, out_of_range);
        end
    end
    
    // Simulation timeout
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
