// ==========================================
// Test Single 64x64 Systolic Array
// Isolate systolic array to check if it has internal problems
// ==========================================

`timescale 1ns/1ps

module test_systolic_64x64;

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam WEIGHT_WIDTH = 8; 
    localparam ACCUMULATOR_WIDTH = 32;
    localparam ARRAY_SIZE = 64;
    
    // Test signals
    reg clk;
    reg rst_n;
    reg start;
    wire computation_done;
    wire result_valid;
    
    // Input matrices (flattened)
    reg [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
    reg [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;
    wire [ACCUMULATOR_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;
    
    // Test matrices (2D arrays)
    reg [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [ACCUMULATOR_WIDTH-1:0] result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [ACCUMULATOR_WIDTH-1:0] expected [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT - Direct systolic array test (using default parameters)
    systolic_array_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .result_flat(result_flat),
        .computation_done(computation_done),
        .result_valid(result_valid)
    );
    
    // Array conversion tasks
    task flatten_arrays;
        integer i, j, bit_index_a, bit_index_b;
        begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    bit_index_a = (i * ARRAY_SIZE + j) * DATA_WIDTH;
                    bit_index_b = (i * ARRAY_SIZE + j) * WEIGHT_WIDTH;
                    
                    matrix_a_flat[bit_index_a +: DATA_WIDTH] = matrix_a[i][j];
                    matrix_b_flat[bit_index_b +: WEIGHT_WIDTH] = matrix_b[i][j];
                end
            end
        end
    endtask
    
    task extract_results;
        integer i, j, bit_index;
        begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    bit_index = (i * ARRAY_SIZE + j) * ACCUMULATOR_WIDTH;
                    result[i][j] = result_flat[bit_index +: ACCUMULATOR_WIDTH];
                end
            end
        end
    endtask
    
    // Test 1: Simple Identity × Ones
    task create_identity_ones_test;
        integer i, j;
        begin
            $display("=== Test: 64x64 Identity × Ones ===");
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    // Matrix A: Identity
                    if (i == j) begin
                        matrix_a[i][j] = 16'h0001;
                        expected[i][j] = 32'h00000001;  // Should be 1 on diagonal
                    end else begin
                        matrix_a[i][j] = 16'h0000;
                        expected[i][j] = 32'h00000000;  // Should be 0 off diagonal
                    end
                    
                    // Matrix B: All ones
                    matrix_b[i][j] = 8'h01;
                end
            end
            $display("Matrix A: 64x64 Identity");
            $display("Matrix B: 64x64 All ones (value 1)");
            $display("Expected: Identity result (1 on diagonal, 0 elsewhere)");
        end
    endtask
    
    // Test 2: Simple 2×2 subset test
    task create_simple_test;
        integer i, j;
        begin
            $display("=== Test: 64x64 Simple Pattern ===");
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    // Matrix A: Only position [0][0] = 1, rest = 0
                    if (i == 0 && j == 0) begin
                        matrix_a[i][j] = 16'h0001;
                    end else begin
                        matrix_a[i][j] = 16'h0000;
                    end
                    
                    // Matrix B: All ones
                    matrix_b[i][j] = 8'h01;
                    
                    // Expected: Only result[0][j] should be 1
                    if (i == 0) begin
                        expected[i][j] = 32'h00000001;
                    end else begin
                        expected[i][j] = 32'h00000000;
                    end
                end
            end
            $display("Matrix A: Only A[0][0] = 1, rest = 0");
            $display("Matrix B: All ones");
            $display("Expected: Only first row = 1, rest = 0");
        end
    endtask
    
    // Verify results
    task verify_results;
        input [8*40:1] test_name;
        integer i, j, errors, total_checked;
        integer sample_positions [0:15][0:1];  // Check specific positions
        begin
            errors = 0;
            total_checked = 0;
            
            $display("\nVerifying %s results...", test_name);
            
            // Define sample positions to check
            sample_positions[0][0] = 0;   sample_positions[0][1] = 0;   // Corner
            sample_positions[1][0] = 0;   sample_positions[1][1] = 16;  // First row
            sample_positions[2][0] = 0;   sample_positions[2][1] = 32;  // First row
            sample_positions[3][0] = 0;   sample_positions[3][1] = 63;  // Last col first row
            sample_positions[4][0] = 16;  sample_positions[4][1] = 0;   // First col
            sample_positions[5][0] = 16;  sample_positions[5][1] = 16;  // Diagonal
            sample_positions[6][0] = 32;  sample_positions[6][1] = 32;  // Diagonal  
            sample_positions[7][0] = 63;  sample_positions[7][1] = 0;   // Last row first col
            sample_positions[8][0] = 63;  sample_positions[8][1] = 63;  // Last corner
            
            // Check sample positions
            for (i = 0; i < 9; i = i + 1) begin
                total_checked = total_checked + 1;
                if (result[sample_positions[i][0]][sample_positions[i][1]] !== 
                    expected[sample_positions[i][0]][sample_positions[i][1]]) begin
                    $display("  ERROR at [%0d][%0d]: got %08h, expected %08h", 
                           sample_positions[i][0], sample_positions[i][1],
                           result[sample_positions[i][0]][sample_positions[i][1]], 
                           expected[sample_positions[i][0]][sample_positions[i][1]]);
                    errors = errors + 1;
                end else begin
                    $display("  ¿ [%0d][%0d]: got %08h (correct)", 
                           sample_positions[i][0], sample_positions[i][1],
                           result[sample_positions[i][0]][sample_positions[i][1]]);
                end
            end
            
            if (errors == 0) begin
                $display("¿ %s PASSED - All %0d sample positions correct!", test_name, total_checked);
            end else begin
                $display("¿ %s FAILED - %0d errors in %0d positions", test_name, errors, total_checked);
            end
        end
    endtask
    
    // Run test
    task run_test;
        input [8*40:1] test_name;
        integer cycle_count;
        begin
            $display("Starting systolic array computation...");
            
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
            
            // Wait for completion
            cycle_count = 0;
            while (!computation_done && cycle_count < 10000) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                if (cycle_count % 1000 == 0) begin
                    $display("  Waiting... %0d cycles", cycle_count);
                end
            end
            
            if (computation_done) begin
                $display("¿ Systolic computation completed in %0d cycles", cycle_count);
                extract_results();
                verify_results(test_name);
            end else begin
                $display("¿ ERROR: Systolic computation timed out");
            end
        end
    endtask
    
    // Main test
    initial begin
        $display("=== Direct 64x64 Systolic Array Test ===");
        
        // Initialize
        rst_n = 1'b0;
        start = 1'b0;
        
        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        
        // Test 1: Simple pattern
        create_simple_test();
        flatten_arrays();
        #100;
        run_test("Simple Pattern");
        
        #1000;
        
        // Test 2: Identity test  
        create_identity_ones_test();
        flatten_arrays();
        #100;
        run_test("Identity×Ones");
        
        $display("\n=== Systolic Array Test Complete ===");
        $finish;
    end
    
    // Timeout
    initial begin
        #500000;
        $display("ERROR: Test timeout!");
        $finish;
    end

endmodule
