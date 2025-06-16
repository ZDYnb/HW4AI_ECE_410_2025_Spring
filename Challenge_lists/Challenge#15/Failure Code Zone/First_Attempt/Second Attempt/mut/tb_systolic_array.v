// ===========================================
// Systolic Array Testbench
// ===========================================
`timescale 1ns/1ps

module tb_systolic_array;

// ===========================================
// Parameters
// ===========================================
parameter ARRAY_SIZE = 4;              // Small array for testing
parameter DATA_WIDTH = 16;
parameter WEIGHT_WIDTH = 8;
parameter ACCUM_WIDTH = 32;
parameter CLK_PERIOD = 10;              // 100MHz clock

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
wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

// Helper arrays for easier matrix manipulation
reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [ACCUM_WIDTH-1:0] expected_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [ACCUM_WIDTH-1:0] actual_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

// Test control
integer i, j, k;
integer error_count;
integer test_case;

// ===========================================
// DUT Instantiation
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
// Helper Tasks
// ===========================================

// Task to flatten matrix_a into flat format
task flatten_matrix_a;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = matrix_a[i][j];
            end
        end
    end
endtask

// Task to flatten matrix_b into flat format
task flatten_matrix_b;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = matrix_b[i][j];
            end
        end
    end
endtask

// Task to unflatten result
task unflatten_result;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                actual_result[i][j] = result_flat[(i*ARRAY_SIZE+j)*ACCUM_WIDTH +: ACCUM_WIDTH];
            end
        end
    end
endtask

// Task to calculate expected result (software matrix multiplication)
task calculate_expected;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                expected_result[i][j] = 0;
                for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
                    expected_result[i][j] = expected_result[i][j] + (matrix_a[i][k] * matrix_b[k][j]);
                end
            end
        end
    end
endtask

// Task to print matrix
task print_matrix;
    input integer matrix_type; // 0=A, 1=B, 2=expected, 3=actual
    begin
        case (matrix_type)
            0: begin
                $display("Matrix A:");
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%6d ", $signed(matrix_a[i][j]));
                    end
                    $display("");
                end
            end
            1: begin
                $display("Matrix B:");
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%6d ", $signed(matrix_b[i][j]));
                    end
                    $display("");
                end
            end
            2: begin
                $display("Expected Result:");
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%8d ", $signed(expected_result[i][j]));
                    end
                    $display("");
                end
            end
            3: begin
                $display("Actual Result:");
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%8d ", $signed(actual_result[i][j]));
                    end
                    $display("");
                end
            end
        endcase
        $display("");
    end
endtask

// Task to verify results
task verify_results;
    begin
        error_count = 0;
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (expected_result[i][j] !== actual_result[i][j]) begin
                    $display("ERROR: Mismatch at [%0d][%0d] - Expected: %0d, Actual: %0d", 
                            i, j, expected_result[i][j], actual_result[i][j]);
                    error_count = error_count + 1;
                end
            end
        end
        
        if (error_count == 0) begin
            $display("¿ Test Case %0d PASSED - All results match!", test_case);
        end else begin
            $display("¿ Test Case %0d FAILED - %0d errors found!", test_case, error_count);
        end
        $display("----------------------------------------");
    end
endtask

// Task to run single test
task run_test;
    begin
        $display("Starting Test Case %0d", test_case);
        
        // Prepare matrices
        flatten_matrix_a();
        flatten_matrix_b();
        calculate_expected();
        
        // Print input matrices
        print_matrix(0); // Matrix A
        print_matrix(1); // Matrix B
        print_matrix(2); // Expected result
        
        // Reset
        rst_n = 0;
        start = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        // Start computation
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait for completion
        wait(done);
        #(CLK_PERIOD * 2); // Allow some settling time
        
        // Extract and verify results
        unflatten_result();
        print_matrix(3); // Actual result
        verify_results();
        
        #(CLK_PERIOD * 5); // Gap between tests
    end
endtask

// ===========================================
// Test Cases
// ===========================================
initial begin
    $display("===========================================");
    $display("Systolic Array Testbench Started");
    $display("Array Size: %0d x %0d", ARRAY_SIZE, ARRAY_SIZE);
    $display("===========================================");
    
    // Initialize signals
    clk = 0;
    rst_n = 0;
    start = 0;
    matrix_a_flat = 0;
    matrix_b_flat = 0;
    test_case = 0;
    
    // Wait for initial reset
    #(CLK_PERIOD * 3);
    
    // Test Case 1: Identity matrices
    test_case = 1;
    $display("\n=== Test Case 1: Identity Matrix ===");
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a[i][j] = (i == j) ? 16'd1 : 16'd0;
            matrix_b[i][j] = (i == j) ? 8'd1 : 8'd0;
        end
    end
    run_test();
    
    // Test Case 2: Simple values
    test_case = 2;
    $display("\n=== Test Case 2: Simple Values ===");
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a[i][j] = i + j + 1;
            matrix_b[i][j] = i + j + 1;
        end
    end
    run_test();
    
    // Test Case 3: Sequential values
    test_case = 3;
    $display("\n=== Test Case 3: Sequential Values ===");
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a[i][j] = i * ARRAY_SIZE + j + 1;
            matrix_b[i][j] = j * ARRAY_SIZE + i + 1;
        end
    end
    run_test();
    
    // Test Case 4: Negative values
    test_case = 4;
    $display("\n=== Test Case 4: Mixed Positive/Negative ===");
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a[i][j] = (i + j) % 2 ? (i + j + 1) : -(i + j + 1);
            matrix_b[i][j] = (i * j) % 2 ? (i + j + 1) : -(i + j + 1);
        end
    end
    run_test();
    
    // Test Case 5: Maximum values
    test_case = 5;
    $display("\n=== Test Case 5: Large Values ===");
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a[i][j] = 16'h7FFF; // Maximum positive 16-bit
            matrix_b[i][j] = 8'h7F;    // Maximum positive 8-bit
        end
    end
    run_test();
    
    // Final summary
    $display("\n===========================================");
    $display("All test cases completed!");
    $display("===========================================");
    
    #(CLK_PERIOD * 10);
    $finish;
end

// ===========================================
// Monitoring and Timeout
// ===========================================
initial begin
    #(CLK_PERIOD * 10000); // Timeout after 10000 cycles
    $display("ERROR: Testbench timeout!");
    $finish;
end

// Optional: Monitor key signals during simulation
initial begin
    $monitor("Time: %0t | Start: %b | Done: %b | Valid: %b | Computing cycles: %0d", 
             $time, start, done, result_valid, dut.compute_counter);
end

endmodule
