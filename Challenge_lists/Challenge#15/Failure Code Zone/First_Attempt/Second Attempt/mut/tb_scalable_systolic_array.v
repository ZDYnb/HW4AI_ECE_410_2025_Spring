// ===========================================
// Scalable Systolic Array Testbench
// Modified for S5.10 Fixed Point Format
// ===========================================
`timescale 1ns/1ps

module tb_scalable_systolic_array;

// ===========================================
// Parameters - Easy to modify for different sizes
// ===========================================
parameter ARRAY_SIZE = 8;              // Start with 8x8 for testing
parameter DATA_WIDTH = 16;
parameter DATA_FRAC = 10;               // S5.10 format
parameter WEIGHT_WIDTH = 8;
parameter WEIGHT_FRAC = 6;              // S1.6 format
parameter ACCUM_WIDTH = 32;
parameter ACCUM_FRAC = 16;              // S15.16 format
parameter CLK_PERIOD = 10;

// ===========================================
// Testbench Signals
// ===========================================
reg clk;
reg rst_n;
reg start;
reg [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
reg [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;
wire done;
wire result_valid;
wire [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

// Test control
integer test_case;
integer error_count;
integer total_errors;
real start_time, end_time, compute_time;

// ===========================================
// DUT Instantiation (Use Default Parameters)
// ===========================================
systolic_array_top #(
    .ARRAY_SIZE(ARRAY_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .matrix_a_flat(matrix_a_flat),
    .matrix_b_flat(matrix_b_flat),
    .done(done),
    .result_valid(result_valid),
    .result_flat(result_flat)
);

// ===========================================
// Clock Generation
// ===========================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// ===========================================
// Fixed Point Helper Functions
// ===========================================

// Function to convert real to S5.10 format
function [DATA_WIDTH-1:0] real_to_s5_10;
    input real val;
    begin
        real_to_s5_10 = $rtoi(val * (1 << DATA_FRAC));
    end
endfunction

// Function to convert real to S1.6 format  
function [WEIGHT_WIDTH-1:0] real_to_s1_6;
    input real val;
    begin
        real_to_s1_6 = $rtoi(val * (1 << WEIGHT_FRAC));
    end
endfunction

// Function to convert S5.10 to real
function real s5_10_to_real;
    input [DATA_WIDTH-1:0] val;
    begin
        s5_10_to_real = $itor($signed(val)) / (1 << DATA_FRAC);
    end
endfunction

// Function to convert S1.6 to real
function real s1_6_to_real;
    input [WEIGHT_WIDTH-1:0] val;
    begin
        s1_6_to_real = $itor($signed(val)) / (1 << WEIGHT_FRAC);
    end
endfunction

// ===========================================
// Test Tasks for Fixed Point
// ===========================================

// Task to create identity matrices in fixed point
task create_identity_matrices;
    integer i, j;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (i == j) begin
                    // Diagonal elements = 1.0
                    matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = real_to_s5_10(1.0);
                    matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = real_to_s1_6(1.0);
                end else begin
                    // Off-diagonal elements = 0.0
                    matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = real_to_s5_10(0.0);
                    matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = real_to_s1_6(0.0);
                end
            end
        end
        $display("Created %dx%d identity matrices (S5.10 and S1.6)", ARRAY_SIZE, ARRAY_SIZE);
        
        // Display some sample values for verification
        $display("Sample values:");
        $display("  A[0][0] = %f (0x%04h)", s5_10_to_real(matrix_a_flat[DATA_WIDTH-1:0]), matrix_a_flat[DATA_WIDTH-1:0]);
        $display("  B[0][0] = %f (0x%02h)", s1_6_to_real(matrix_b_flat[WEIGHT_WIDTH-1:0]), matrix_b_flat[WEIGHT_WIDTH-1:0]);
    end
endtask

// Task to create simple test matrices
task create_simple_matrices;
    integer i, j;
    real a_val, b_val;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                // Create simple patterns with small values
                a_val = 0.5 + 0.1 * (i + j);  // 0.5, 0.6, 0.7, etc.
                b_val = 0.25 + 0.05 * (i + j); // 0.25, 0.3, 0.35, etc.
                
                matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = real_to_s5_10(a_val);
                matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = real_to_s1_6(b_val);
            end
        end
        $display("Created %dx%d simple test matrices (fixed point)", ARRAY_SIZE, ARRAY_SIZE);
        
        // Display some sample values
        $display("Sample values:");
        $display("  A[0][0] = %f, A[1][1] = %f", 
                s5_10_to_real(matrix_a_flat[DATA_WIDTH-1:0]),
                s5_10_to_real(matrix_a_flat[(1*ARRAY_SIZE+1)*DATA_WIDTH +: DATA_WIDTH]));
        $display("  B[0][0] = %f, B[1][1] = %f",
                s1_6_to_real(matrix_b_flat[WEIGHT_WIDTH-1:0]),
                s1_6_to_real(matrix_b_flat[(1*ARRAY_SIZE+1)*WEIGHT_WIDTH +: WEIGHT_WIDTH]));
    end
endtask

// Task to verify identity matrix result
task verify_identity_result;
    integer i, j;
    real result_val, expected_val;
    begin
        error_count = 0;
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                result_val = s5_10_to_real(result_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH]);
                
                if (i == j) begin
                    // Diagonal should be 1.0
                    expected_val = 1.0;
                    if (result_val < 0.98 || result_val > 1.02) begin  // Allow 2% tolerance
                        error_count = error_count + 1;
                        if (error_count <= 10)
                            $display("ERROR at [%d][%d]: Expected ~1.0, Got %f", i, j, result_val);
                    end
                end else begin
                    // Off-diagonal should be 0.0
                    expected_val = 0.0;
                    if (result_val < -0.02 || result_val > 0.02) begin  // Allow small tolerance
                        error_count = error_count + 1;
                        if (error_count <= 10)
                            $display("ERROR at [%d][%d]: Expected ~0.0, Got %f", i, j, result_val);
                    end
                end
            end
        end
        
        if (error_count == 0) begin
            $display("¿ Identity test PASSED - All %d elements correct within tolerance!", ARRAY_SIZE*ARRAY_SIZE);
        end else begin
            $display("¿ Identity test FAILED - %d errors found!", error_count);
            if (error_count > 10)
                $display("  (Only first 10 errors shown)");
        end
        total_errors = total_errors + error_count;
        
        // Display some sample results
        $display("Sample results:");
        $display("  Result[0][0] = %f", s5_10_to_real(result_flat[DATA_WIDTH-1:0]));
        $display("  Result[1][1] = %f", s5_10_to_real(result_flat[(1*ARRAY_SIZE+1)*DATA_WIDTH +: DATA_WIDTH]));
    end
endtask

// Task to run single test
task run_test;
    input [255:0] test_name;
    begin
        $display("\n=== %s ===", test_name);
        $display("Array Size: %dx%d (%d total elements)", ARRAY_SIZE, ARRAY_SIZE, ARRAY_SIZE*ARRAY_SIZE);
        $display("Format: Data=S5.10, Weight=S1.6, Accumulator=S15.16");
        
        // Reset
        rst_n = 0;
        start = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        // Start computation and measure time
        start_time = $realtime;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait for completion
        $display("Starting computation...");
        wait(done);
        end_time = $realtime;
        compute_time = end_time - start_time;
        
        #(CLK_PERIOD * 2); // Allow settling time
        
        $display("Computation completed in %.1f ns (%d cycles)", 
                compute_time, $rtoi(compute_time/CLK_PERIOD));
        $display("Throughput: %.2f GOPS", 
                (2.0 * ARRAY_SIZE * ARRAY_SIZE * ARRAY_SIZE) / (compute_time * 1e-9) / 1e9);
        
        #(CLK_PERIOD * 5);
    end
endtask

// ===========================================
// Resource Estimation
// ===========================================
initial begin
    $display("===========================================");
    $display("Fixed Point Systolic Array Analysis");
    $display("===========================================");
    $display("Array Configuration:");
    $display("  Size: %dx%d", ARRAY_SIZE, ARRAY_SIZE);
    $display("  Total PEs: %d", ARRAY_SIZE*ARRAY_SIZE);
    $display("  Data Format: S%d.%d", DATA_WIDTH-1-DATA_FRAC, DATA_FRAC);
    $display("  Weight Format: S%d.%d", WEIGHT_WIDTH-1-WEIGHT_FRAC, WEIGHT_FRAC);
    $display("  Accumulator Format: S%d.%d", ACCUM_WIDTH-1-ACCUM_FRAC, ACCUM_FRAC);
    $display("");
    $display("Estimated Resources:");
    $display("  Multipliers: %d", ARRAY_SIZE*ARRAY_SIZE);
    $display("  Expected Cycles: %d", 3*ARRAY_SIZE);
    $display("===========================================");
end

// ===========================================
// Main Test Sequence
// ===========================================
initial begin
    // Initialize
    clk = 0;
    rst_n = 0;
    start = 0;
    test_case = 0;
    total_errors = 0;
    
    #(CLK_PERIOD * 3);
    
    // Test 1: Identity Matrix
    test_case = 1;
    create_identity_matrices();
    run_test("Fixed Point Identity Matrix Test");
    verify_identity_result();
    
    // Test 2: Simple Matrix
    test_case = 2;
    create_simple_matrices();
    run_test("Fixed Point Simple Matrix Test");
    $display("¿ Simple test completed (results need manual verification for fixed point)");
    
    // Final summary
    $display("\n===========================================");
    $display("Test Summary for %dx%d Fixed Point Array:", ARRAY_SIZE, ARRAY_SIZE);
    $display("Total errors: %d", total_errors);
    if (total_errors == 0) begin
        $display("¿ All tests PASSED!");
    end else begin
        $display("¿ Some tests FAILED!");
    end
    $display("===========================================");
    
    #(CLK_PERIOD * 10);
    $finish;
end

// ===========================================
// Performance Monitoring
// ===========================================
initial begin
    #(CLK_PERIOD * 100000); // Timeout
    $display("WARNING: Testbench timeout!");
    $finish;
end

endmodule
