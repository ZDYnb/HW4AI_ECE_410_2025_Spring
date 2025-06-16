// ===========================================
// 4×4 Systolic Array Testbench
// Pure Verilog for Questa/ModelSim
// ===========================================

`timescale 1ns/1ps

module tb_systolic_array_4x4;

    // Clock and Reset
    reg clk;
    reg rst_n;
    reg enable;
    reg clear_accum;
    
    // Data inputs (4 rows)
    reg [15:0] data_in_0, data_in_1, data_in_2, data_in_3;
    reg data_valid_0, data_valid_1, data_valid_2, data_valid_3;
    
    // Weight inputs (4 columns)
    reg [7:0] weight_in_0, weight_in_1, weight_in_2, weight_in_3;
    reg weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3;
    
    // Results output (4×4 matrix)
    wire [31:0] result_00, result_01, result_02, result_03;
    wire [31:0] result_10, result_11, result_12, result_13;
    wire [31:0] result_20, result_21, result_22, result_23;
    wire [31:0] result_30, result_31, result_32, result_33;
    
    wire valid_00, valid_01, valid_02, valid_03;
    wire valid_10, valid_11, valid_12, valid_13;
    wire valid_20, valid_21, valid_22, valid_23;
    wire valid_30, valid_31, valid_32, valid_33;
    
    // Test control variables
    integer i, j, cycle_count;
    reg [15:0] test_matrix_a [0:3][0:3];  // 4x4 input matrix A
    reg [7:0]  test_matrix_b [0:3][0:3];  // 4x4 weight matrix B
    reg [31:0] expected_result [0:3][0:3]; // Expected results
    reg [31:0] actual_result [0:3][0:3];   // Actual results from DUT
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end
    
    // DUT instantiation
    systolic_array_4x4 dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_accum(clear_accum),
        
        .data_in_0(data_in_0), .data_in_1(data_in_1), 
        .data_in_2(data_in_2), .data_in_3(data_in_3),
        .data_valid_0(data_valid_0), .data_valid_1(data_valid_1),
        .data_valid_2(data_valid_2), .data_valid_3(data_valid_3),
        
        .weight_in_0(weight_in_0), .weight_in_1(weight_in_1),
        .weight_in_2(weight_in_2), .weight_in_3(weight_in_3),
        .weight_valid_0(weight_valid_0), .weight_valid_1(weight_valid_1),
        .weight_valid_2(weight_valid_2), .weight_valid_3(weight_valid_3),
        
        .result_00(result_00), .result_01(result_01), .result_02(result_02), .result_03(result_03),
        .result_10(result_10), .result_11(result_11), .result_12(result_12), .result_13(result_13),
        .result_20(result_20), .result_21(result_21), .result_22(result_22), .result_23(result_23),
        .result_30(result_30), .result_31(result_31), .result_32(result_32), .result_33(result_33),
        
        .valid_00(valid_00), .valid_01(valid_01), .valid_02(valid_02), .valid_03(valid_03),
        .valid_10(valid_10), .valid_11(valid_11), .valid_12(valid_12), .valid_13(valid_13),
        .valid_20(valid_20), .valid_21(valid_21), .valid_22(valid_22), .valid_23(valid_23),
        .valid_30(valid_30), .valid_31(valid_31), .valid_32(valid_32), .valid_33(valid_33)
    );
    
    // Initialize test matrices
    initial begin
        // Test Matrix A (Data) - 4x4
        test_matrix_a[0][0] = 16'd1;  test_matrix_a[0][1] = 16'd2;  test_matrix_a[0][2] = 16'd3;  test_matrix_a[0][3] = 16'd4;
        test_matrix_a[1][0] = 16'd5;  test_matrix_a[1][1] = 16'd6;  test_matrix_a[1][2] = 16'd7;  test_matrix_a[1][3] = 16'd8;
        test_matrix_a[2][0] = 16'd9;  test_matrix_a[2][1] = 16'd10; test_matrix_a[2][2] = 16'd11; test_matrix_a[2][3] = 16'd12;
        test_matrix_a[3][0] = 16'd13; test_matrix_a[3][1] = 16'd14; test_matrix_a[3][2] = 16'd15; test_matrix_a[3][3] = 16'd16;
        
        // Test Matrix B (Weights) - 4x4
        test_matrix_b[0][0] = 8'd1;  test_matrix_b[0][1] = 8'd0;  test_matrix_b[0][2] = 8'd0;  test_matrix_b[0][3] = 8'd0;
        test_matrix_b[1][0] = 8'd0;  test_matrix_b[1][1] = 8'd1;  test_matrix_b[1][2] = 8'd0;  test_matrix_b[1][3] = 8'd0;
        test_matrix_b[2][0] = 8'd0;  test_matrix_b[2][1] = 8'd0;  test_matrix_b[2][2] = 8'd1;  test_matrix_b[2][3] = 8'd0;
        test_matrix_b[3][0] = 8'd0;  test_matrix_b[3][1] = 8'd0;  test_matrix_b[3][2] = 8'd0;  test_matrix_b[3][3] = 8'd1;
        
        // Expected results for A * B (Identity matrix multiplication)
        expected_result[0][0] = 32'd1;  expected_result[0][1] = 32'd2;  expected_result[0][2] = 32'd3;  expected_result[0][3] = 32'd4;
        expected_result[1][0] = 32'd5;  expected_result[1][1] = 32'd6;  expected_result[1][2] = 32'd7;  expected_result[1][3] = 32'd8;
        expected_result[2][0] = 32'd9;  expected_result[2][1] = 32'd10; expected_result[2][2] = 32'd11; expected_result[2][3] = 32'd12;
        expected_result[3][0] = 32'd13; expected_result[3][1] = 32'd14; expected_result[3][2] = 32'd15; expected_result[3][3] = 32'd16;
    end
    
    // Task to reset the system
    task reset_system;
    begin
        rst_n = 0;
        enable = 0;
        clear_accum = 1;
        
        data_in_0 = 0; data_in_1 = 0; data_in_2 = 0; data_in_3 = 0;
        data_valid_0 = 0; data_valid_1 = 0; data_valid_2 = 0; data_valid_3 = 0;
        
        weight_in_0 = 0; weight_in_1 = 0; weight_in_2 = 0; weight_in_3 = 0;
        weight_valid_0 = 0; weight_valid_1 = 0; weight_valid_2 = 0; weight_valid_3 = 0;
        
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        clear_accum = 0;
        enable = 1;
        @(posedge clk);
    end
    endtask
    
    // Task to load matrices in systolic fashion
    task load_matrices;
    begin
        $display("=== Loading Matrices ===");
        cycle_count = 0;
        
        // Cycle 0: Load first elements
        data_in_0 = test_matrix_a[0][0];    data_valid_0 = 1;
        data_in_1 = 0;                      data_valid_1 = 0;
        data_in_2 = 0;                      data_valid_2 = 0;
        data_in_3 = 0;                      data_valid_3 = 0;
        
        weight_in_0 = test_matrix_b[0][0];  weight_valid_0 = 1;
        weight_in_1 = 0;                    weight_valid_1 = 0;
        weight_in_2 = 0;                    weight_valid_2 = 0;
        weight_in_3 = 0;                    weight_valid_3 = 0;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Cycle 1
        data_in_0 = test_matrix_a[0][1];    data_valid_0 = 1;
        data_in_1 = test_matrix_a[1][0];    data_valid_1 = 1;
        data_in_2 = 0;                      data_valid_2 = 0;
        data_in_3 = 0;                      data_valid_3 = 0;
        
        weight_in_0 = test_matrix_b[1][0];  weight_valid_0 = 1;
        weight_in_1 = test_matrix_b[0][1];  weight_valid_1 = 1;
        weight_in_2 = 0;                    weight_valid_2 = 0;
        weight_in_3 = 0;                    weight_valid_3 = 0;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Cycle 2
        data_in_0 = test_matrix_a[0][2];    data_valid_0 = 1;
        data_in_1 = test_matrix_a[1][1];    data_valid_1 = 1;
        data_in_2 = test_matrix_a[2][0];    data_valid_2 = 1;
        data_in_3 = 0;                      data_valid_3 = 0;
        
        weight_in_0 = test_matrix_b[2][0];  weight_valid_0 = 1;
        weight_in_1 = test_matrix_b[1][1];  weight_valid_1 = 1;
        weight_in_2 = test_matrix_b[0][2];  weight_valid_2 = 1;
        weight_in_3 = 0;                    weight_valid_3 = 0;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Cycle 3
        data_in_0 = test_matrix_a[0][3];    data_valid_0 = 1;
        data_in_1 = test_matrix_a[1][2];    data_valid_1 = 1;
        data_in_2 = test_matrix_a[2][1];    data_valid_2 = 1;
        data_in_3 = test_matrix_a[3][0];    data_valid_3 = 1;
        
        weight_in_0 = test_matrix_b[3][0];  weight_valid_0 = 1;
        weight_in_1 = test_matrix_b[2][1];  weight_valid_1 = 1;
        weight_in_2 = test_matrix_b[1][2];  weight_valid_2 = 1;
        weight_in_3 = test_matrix_b[0][3];  weight_valid_3 = 1;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Continue loading remaining elements
        // Cycle 4
        data_in_0 = 0;                      data_valid_0 = 0;
        data_in_1 = test_matrix_a[1][3];    data_valid_1 = 1;
        data_in_2 = test_matrix_a[2][2];    data_valid_2 = 1;
        data_in_3 = test_matrix_a[3][1];    data_valid_3 = 1;
        
        weight_in_0 = 0;                    weight_valid_0 = 0;
        weight_in_1 = test_matrix_b[3][1];  weight_valid_1 = 1;
        weight_in_2 = test_matrix_b[2][2];  weight_valid_2 = 1;
        weight_in_3 = test_matrix_b[1][3];  weight_valid_3 = 1;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Cycle 5
        data_in_0 = 0;                      data_valid_0 = 0;
        data_in_1 = 0;                      data_valid_1 = 0;
        data_in_2 = test_matrix_a[2][3];    data_valid_2 = 1;
        data_in_3 = test_matrix_a[3][2];    data_valid_3 = 1;
        
        weight_in_0 = 0;                    weight_valid_0 = 0;
        weight_in_1 = 0;                    weight_valid_1 = 0;
        weight_in_2 = test_matrix_b[3][2];  weight_valid_2 = 1;
        weight_in_3 = test_matrix_b[2][3];  weight_valid_3 = 1;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Cycle 6
        data_in_0 = 0;                      data_valid_0 = 0;
        data_in_1 = 0;                      data_valid_1 = 0;
        data_in_2 = 0;                      data_valid_2 = 0;
        data_in_3 = test_matrix_a[3][3];    data_valid_3 = 1;
        
        weight_in_0 = 0;                    weight_valid_0 = 0;
        weight_in_1 = 0;                    weight_valid_1 = 0;
        weight_in_2 = 0;                    weight_valid_2 = 0;
        weight_in_3 = test_matrix_b[3][3];  weight_valid_3 = 1;
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Stop inputs
        data_valid_0 = 0; data_valid_1 = 0; data_valid_2 = 0; data_valid_3 = 0;
        weight_valid_0 = 0; weight_valid_1 = 0; weight_valid_2 = 0; weight_valid_3 = 0;
        
        $display("Matrix loading completed after %0d cycles", cycle_count);
    end
    endtask
    
    // Task to wait for results and collect them
    task collect_results;
    begin
        $display("=== Waiting for Results ===");
        
        // Wait for all results to be valid (may take several more cycles)
        wait(valid_33 == 1);  // Wait for the last result
        
        @(posedge clk);  // Sample results
        
        // Collect all results
        actual_result[0][0] = result_00; actual_result[0][1] = result_01; 
        actual_result[0][2] = result_02; actual_result[0][3] = result_03;
        actual_result[1][0] = result_10; actual_result[1][1] = result_11; 
        actual_result[1][2] = result_12; actual_result[1][3] = result_13;
        actual_result[2][0] = result_20; actual_result[2][1] = result_21; 
        actual_result[2][2] = result_22; actual_result[2][3] = result_23;
        actual_result[3][0] = result_30; actual_result[3][1] = result_31; 
        actual_result[3][2] = result_32; actual_result[3][3] = result_33;
        
        $display("Results collected at cycle %0d", cycle_count);
    end
    endtask
    
    // Task to display matrices
    task display_matrices;
    begin
        $display("\n=== INPUT MATRIX A ===");
        for (i = 0; i < 4; i = i + 1) begin
            $display("%2d %2d %2d %2d", 
                test_matrix_a[i][0], test_matrix_a[i][1], 
                test_matrix_a[i][2], test_matrix_a[i][3]);
        end
        
        $display("\n=== WEIGHT MATRIX B ===");
        for (i = 0; i < 4; i = i + 1) begin
            $display("%2d %2d %2d %2d", 
                test_matrix_b[i][0], test_matrix_b[i][1], 
                test_matrix_b[i][2], test_matrix_b[i][3]);
        end
        
        $display("\n=== EXPECTED RESULT (A * B) ===");
        for (i = 0; i < 4; i = i + 1) begin
            $display("%3d %3d %3d %3d", 
                expected_result[i][0], expected_result[i][1], 
                expected_result[i][2], expected_result[i][3]);
        end
        
        $display("\n=== ACTUAL RESULT ===");
        for (i = 0; i < 4; i = i + 1) begin
            $display("%3d %3d %3d %3d", 
                actual_result[i][0], actual_result[i][1], 
                actual_result[i][2], actual_result[i][3]);
        end
    end
    endtask
    
    // Task to verify results
    task verify_results;
        reg test_passed;
    begin
        test_passed = 1;
        $display("\n=== VERIFICATION ===");
        
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                if (actual_result[i][j] !== expected_result[i][j]) begin
                    $display("MISMATCH at [%0d][%0d]: Expected=%0d, Got=%0d", 
                        i, j, expected_result[i][j], actual_result[i][j]);
                    test_passed = 0;
                end
            end
        end
        
        if (test_passed) begin
            $display("*** TEST PASSED! All results match expected values ***");
        end else begin
            $display("*** TEST FAILED! Some results don't match ***");
        end
    end
    endtask
    
    // Main test sequence
    initial begin
        $display("=== 4x4 Systolic Array Testbench ===");
        $display("Testing matrix multiplication A * B");
        
        // Initialize
        reset_system();
        
        // Display input matrices
        display_matrices();
        
        // Run the test
        load_matrices();
        collect_results();
        
        // Wait a few more cycles to ensure all results are stable
        repeat(10) @(posedge clk);
        
        // Display and verify results
        display_matrices();
        verify_results();
        
        // Additional test with different matrices
        $display("\n\n=== Running Second Test with Different Matrices ===");
        
        // Load new test matrices
        test_matrix_a[0][0] = 16'd2;  test_matrix_a[0][1] = 16'd0;  test_matrix_a[0][2] = 16'd0;  test_matrix_a[0][3] = 16'd0;
        test_matrix_a[1][0] = 16'd0;  test_matrix_a[1][1] = 16'd3;  test_matrix_a[1][2] = 16'd0;  test_matrix_a[1][3] = 16'd0;
        test_matrix_a[2][0] = 16'd0;  test_matrix_a[2][1] = 16'd0;  test_matrix_a[2][2] = 16'd4;  test_matrix_a[2][3] = 16'd0;
        test_matrix_a[3][0] = 16'd0;  test_matrix_a[3][1] = 16'd0;  test_matrix_a[3][2] = 16'd0;  test_matrix_a[3][3] = 16'd5;
        
        test_matrix_b[0][0] = 8'd1;  test_matrix_b[0][1] = 8'd2;  test_matrix_b[0][2] = 8'd3;  test_matrix_b[0][3] = 8'd4;
        test_matrix_b[1][0] = 8'd1;  test_matrix_b[1][1] = 8'd2;  test_matrix_b[1][2] = 8'd3;  test_matrix_b[1][3] = 8'd4;
        test_matrix_b[2][0] = 8'd1;  test_matrix_b[2][1] = 8'd2;  test_matrix_b[2][2] = 8'd3;  test_matrix_b[2][3] = 8'd4;
        test_matrix_b[3][0] = 8'd1;  test_matrix_b[3][1] = 8'd2;  test_matrix_b[3][2] = 8'd3;  test_matrix_b[3][3] = 8'd4;
        
        // Expected results for second test
        expected_result[0][0] = 32'd2;  expected_result[0][1] = 32'd4;  expected_result[0][2] = 32'd6;  expected_result[0][3] = 32'd8;
        expected_result[1][0] = 32'd3;  expected_result[1][1] = 32'd6;  expected_result[1][2] = 32'd9;  expected_result[1][3] = 32'd12;
        expected_result[2][0] = 32'd4;  expected_result[2][1] = 32'd8;  expected_result[2][2] = 32'd12; expected_result[2][3] = 32'd16;
        expected_result[3][0] = 32'd5;  expected_result[3][1] = 32'd10; expected_result[3][2] = 32'd15; expected_result[3][3] = 32'd20;
        
        reset_system();
        load_matrices();
        collect_results();
        repeat(10) @(posedge clk);
        display_matrices();
        verify_results();
        
        $display("\n=== Testbench Complete ===");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #50000;  // 50us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
