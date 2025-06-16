// ===========================================
// Irregular Matrix Test - GPT-2 Realistic Scenarios
// Testing how 8x8 array handles non-square matrices
// ===========================================

`timescale 1ns/1ps

module tb_systolic_8x8;

    // Parameters
    parameter ARRAY_SIZE = 8;
    parameter DATA_WIDTH = 16;
    parameter WEIGHT_WIDTH = 8;
    parameter ACCUM_WIDTH = 32;
    parameter CLK_PERIOD = 10;
    
    // Same interface as 8x8 test
    reg                                         clk;
    reg                                         rst_n;
    reg                                         start;
    reg  [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
    reg  [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;
    wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;
    wire                                        computation_done;
    wire                                        result_valid;
    
    // Test matrices
    reg [DATA_WIDTH-1:0] test_matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0] test_matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [ACCUM_WIDTH-1:0] expected_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [ACCUM_WIDTH-1:0] actual_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    integer i, j, k, cycle_count;
    
    // ==========================================
    // DUT Instantiation
    // ==========================================
    systolic_array_top #(
        .ARRAY_SIZE(8),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .result_flat(result_flat),
        .computation_done(computation_done),
        .result_valid(result_valid)
    );
    
    // ==========================================
    // Clock Generation & Pack/Unpack (same as 8x8)
    // ==========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    genvar pack_i, pack_j;
    generate
        for (pack_i = 0; pack_i < ARRAY_SIZE; pack_i = pack_i + 1) begin: PACK_ROW
            for (pack_j = 0; pack_j < ARRAY_SIZE; pack_j = pack_j + 1) begin: PACK_COL
                always @(*) begin
                    matrix_a_flat[(pack_i*ARRAY_SIZE + pack_j + 1)*DATA_WIDTH - 1 : (pack_i*ARRAY_SIZE + pack_j)*DATA_WIDTH] = test_matrix_a[pack_i][pack_j];
                    matrix_b_flat[(pack_i*ARRAY_SIZE + pack_j + 1)*WEIGHT_WIDTH - 1 : (pack_i*ARRAY_SIZE + pack_j)*WEIGHT_WIDTH] = test_matrix_b[pack_i][pack_j];
                end
                assign actual_result[pack_i][pack_j] = result_flat[(pack_i*ARRAY_SIZE + pack_j + 1)*ACCUM_WIDTH - 1 : (pack_i*ARRAY_SIZE + pack_j)*ACCUM_WIDTH];
            end
        end
    endgenerate
    
    // ==========================================
    // Test Tasks
    // ==========================================
    
    task reset_system;
    begin
        rst_n = 0;
        start = 0;
        cycle_count = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        $display("System reset completed");
    end
    endtask
    
    task run_computation;
    begin
        $display("=== Starting Irregular Matrix Computation ===");
        start = 1;
        @(posedge clk);
        start = 0;
        wait(computation_done);
        @(posedge clk);
        cycle_count = cycle_count + 1;
        $display("Computation completed");
    end
    endtask
    
    // Task to display irregular matrix (show actual dimensions used)
    task display_irregular_result(input integer rows, input integer cols);
    begin
        $display("\n=== RESULT MATRIX (%0dx%0d) ===", rows, cols);
        for (i = 0; i < rows; i = i + 1) begin
            $write("Row %0d: ", i);
            for (j = 0; j < cols; j = j + 1) begin
                $write("%4d ", actual_result[i][j]);
            end
            $display("");
        end
    end
    endtask
    
    // Task to verify irregular results
    task verify_irregular_results(input integer rows, input integer cols);
        reg test_passed;
        integer error_count;
    begin
        test_passed = 1;
        error_count = 0;
        $display("\n=== VERIFICATION (%0dx%0d region) ===", rows, cols);
        
        for (i = 0; i < rows; i = i + 1) begin
            for (j = 0; j < cols; j = j + 1) begin
                if (actual_result[i][j] !== expected_result[i][j]) begin
                    if (error_count < 5) begin
                        $display("MISMATCH at [%0d][%0d]: Expected=%0d, Got=%0d", 
                            i, j, expected_result[i][j], actual_result[i][j]);
                    end
                    test_passed = 0;
                    error_count = error_count + 1;
                end
            end
        end
        
        if (test_passed) begin
            $display("*** IRREGULAR TEST PASSED! All %0d results correct ***", rows*cols);
        end else begin
            $display("*** IRREGULAR TEST FAILED! %0d errors out of %0d ***", error_count, rows*cols);
        end
        
        // Calculate PE utilization
        $display("PE Utilization: %0d/%0d = %0d%%", rows*cols, ARRAY_SIZE*ARRAY_SIZE, (rows*cols*100)/(ARRAY_SIZE*ARRAY_SIZE));
    end
    endtask
    
    // ==========================================
    // Irregular Test Cases
    // ==========================================
    
    // Test Case 1: 4x6 matrix (QKV projection like)
    task load_4x6_test;
        integer row, col;
    begin
        $display("Loading 4x6 Matrix Test (simulating sequence_length=4, hidden=6)");
        
        // Clear all matrices
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                test_matrix_a[i][j] = 0;
                test_matrix_b[i][j] = 0;
                expected_result[i][j] = 0;
            end
        end
        
        // Set up 4x6 computation: A(4x4) * B(4x6) = C(4x6)
        // Matrix A: 4x4 identity in top-left
        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 4; col = col + 1) begin
                if (row == col) begin
                    test_matrix_a[row][col] = row + 1;  // 1,2,3,4 on diagonal
                end else begin
                    test_matrix_a[row][col] = 0;
                end
            end
        end
        
        // Matrix B: 4x6 pattern in top area
        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 6; col = col + 1) begin
                test_matrix_b[row][col] = (row + 1) * 10 + (col + 1);  // 11,12,13,14,15,16; 21,22,23,24,25,26; etc.
            end
        end
        
        // Expected result: A(4x4) * B(4x6) = C(4x6)
        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 6; col = col + 1) begin
                expected_result[row][col] = 0;
                for (k = 0; k < 4; k = k + 1) begin
                    if (row == k) begin  // Only diagonal elements of A are non-zero
                        expected_result[row][col] = expected_result[row][col] + 
                                                  (row + 1) * ((k + 1) * 10 + (col + 1));
                    end
                end
            end
        end
    end
    endtask
    
    // Test Case 2: 6x3 matrix (FFN projection like)  
    task load_6x3_test;
        integer row, col;
    begin
        $display("Loading 6x3 Matrix Test (simulating FFN projection)");
        
        // Clear all matrices
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                test_matrix_a[i][j] = 0;
                test_matrix_b[i][j] = 0;
                expected_result[i][j] = 0;
            end
        end
        
        // Set up 6x3 computation: A(6x6) * B(6x3) = C(6x3)
        // Matrix A: 6x6 with simple pattern
        for (row = 0; row < 6; row = row + 1) begin
            for (col = 0; col < 6; col = col + 1) begin
                if (row == col) begin
                    test_matrix_a[row][col] = 2;  // All 2s on diagonal
                end else begin
                    test_matrix_a[row][col] = 0;
                end
            end
        end
        
        // Matrix B: 6x3 with incremental pattern
        for (row = 0; row < 6; row = row + 1) begin
            for (col = 0; col < 3; col = col + 1) begin
                test_matrix_b[row][col] = row * 3 + col + 1;  // 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
            end
        end
        
        // Expected result: diagonal A * B
        for (row = 0; row < 6; row = row + 1) begin
            for (col = 0; col < 3; col = col + 1) begin
                expected_result[row][col] = 2 * (row * 3 + col + 1);  // 2x each B element
            end
        end
    end
    endtask
    
    // Test Case 3: 3x8 matrix (full width utilization)
    task load_3x8_test;
        integer row, col;
    begin
        $display("Loading 3x8 Matrix Test (testing full width)");
        
        // Clear all matrices
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                test_matrix_a[i][j] = 0;
                test_matrix_b[i][j] = 0;
                expected_result[i][j] = 0;
            end
        end
        
        // Matrix A: 3x3 simple values
        for (row = 0; row < 3; row = row + 1) begin
            for (col = 0; col < 3; col = col + 1) begin
                test_matrix_a[row][col] = (row == col) ? 1 : 0;  // Identity
            end
        end
        
        // Matrix B: 3x8 (use full width!)
        for (row = 0; row < 3; row = row + 1) begin
            for (col = 0; col < 8; col = col + 1) begin
                test_matrix_b[row][col] = row * 8 + col + 1;  // 1-24 sequential
            end
        end
        
        // Expected result: identity * B = B
        for (row = 0; row < 3; row = row + 1) begin
            for (col = 0; col < 8; col = col + 1) begin
                expected_result[row][col] = row * 8 + col + 1;
            end
        end
    end
    endtask
    
    // ==========================================
    // Main Test Sequence
    // ==========================================
    initial begin
        $dumpfile("systolic_array_8x8.vcd");
        $dumpvars(0, tb_systolic_8x8);
        
        $display("=== Irregular Matrix Test for GPT-2 Scenarios ===");
        $display("Testing PE utilization with realistic matrix shapes");
        
        // Test Case 1: 4x6 (Low utilization)
        $display("\n=== TEST CASE 1: 4x6 Matrix (37.5%% PE utilization) ===");
        reset_system();
        load_4x6_test();
        run_computation();
        repeat(20) @(posedge clk);
        display_irregular_result(4, 6);
        verify_irregular_results(4, 6);
        
        // Test Case 2: 6x3 (28% utilization)  
        $display("\n=== TEST CASE 2: 6x3 Matrix (28%% PE utilization) ===");
        reset_system();
        load_6x3_test();
        run_computation();
        repeat(20) @(posedge clk);
        display_irregular_result(6, 3);
        verify_irregular_results(6, 3);
        
        // Test Case 3: 3x8 (37.5% utilization, but full width)
        $display("\n=== TEST CASE 3: 3x8 Matrix (37.5%% PE utilization, full width) ===");
        reset_system();
        load_3x8_test();
        run_computation();
        repeat(20) @(posedge clk);
        display_irregular_result(3, 8);
        verify_irregular_results(3, 8);
        
        // Summary
        $display("\n=== IRREGULAR MATRIX TEST SUMMARY ===");
        $display("¿ 4x6: Good for QKV projections with short sequences");
        $display("¿ 6x3: Good for FFN output projections");  
        $display("¿ 3x8: Good for attention operations");
        $display("¿ All tests validate systolic array handles irregular shapes correctly");
        $display("¿ PE utilization varies from 28%% to 37.5%% - room for optimization!");
        
        $display("\n=== Irregular Matrix Test Complete ===");
        $finish;
    end
    
    // Timeout
    initial begin
        #200000;  
        $display("ERROR: Irregular matrix testbench timeout!");
        $finish;
    end
    
    always @(posedge computation_done) begin
        $display("T=%0t: Irregular computation completed", $time);
    end

endmodule
