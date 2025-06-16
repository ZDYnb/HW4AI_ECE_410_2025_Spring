// ===========================================
// FSM-Controlled 4×4 Systolic Array Testbench
// Pure Verilog for Questa/ModelSim
// ===========================================

`timescale 1ns/1ps

module tb_fsm_systolic_array_4x4;

    // Clock and Reset
    reg clk;
    reg rst_n;
    reg start;
    
    // Matrix A inputs (4x4)
    reg [15:0] matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03;
    reg [15:0] matrix_a_10, matrix_a_11, matrix_a_12, matrix_a_13;
    reg [15:0] matrix_a_20, matrix_a_21, matrix_a_22, matrix_a_23;
    reg [15:0] matrix_a_30, matrix_a_31, matrix_a_32, matrix_a_33;
    
    // Matrix B inputs (4x4)
    reg [7:0] matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03;
    reg [7:0] matrix_b_10, matrix_b_11, matrix_b_12, matrix_b_13;
    reg [7:0] matrix_b_20, matrix_b_21, matrix_b_22, matrix_b_23;
    reg [7:0] matrix_b_30, matrix_b_31, matrix_b_32, matrix_b_33;
    
    // Results output (4×4 matrix)
    wire [31:0] result_00, result_01, result_02, result_03;
    wire [31:0] result_10, result_11, result_12, result_13;
    wire [31:0] result_20, result_21, result_22, result_23;
    wire [31:0] result_30, result_31, result_32, result_33;
    
    wire computation_done;
    wire result_valid;
    
    // Test variables
    integer i, j;
    reg [31:0] expected_result [0:3][0:3];
    reg [31:0] actual_result [0:3][0:3];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end
    
    // DUT instantiation
    systolic_array_4x4 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        
        // Matrix A
        .matrix_a_00(matrix_a_00), .matrix_a_01(matrix_a_01), .matrix_a_02(matrix_a_02), .matrix_a_03(matrix_a_03),
        .matrix_a_10(matrix_a_10), .matrix_a_11(matrix_a_11), .matrix_a_12(matrix_a_12), .matrix_a_13(matrix_a_13),
        .matrix_a_20(matrix_a_20), .matrix_a_21(matrix_a_21), .matrix_a_22(matrix_a_22), .matrix_a_23(matrix_a_23),
        .matrix_a_30(matrix_a_30), .matrix_a_31(matrix_a_31), .matrix_a_32(matrix_a_32), .matrix_a_33(matrix_a_33),
        
        // Matrix B
        .matrix_b_00(matrix_b_00), .matrix_b_01(matrix_b_01), .matrix_b_02(matrix_b_02), .matrix_b_03(matrix_b_03),
        .matrix_b_10(matrix_b_10), .matrix_b_11(matrix_b_11), .matrix_b_12(matrix_b_12), .matrix_b_13(matrix_b_13),
        .matrix_b_20(matrix_b_20), .matrix_b_21(matrix_b_21), .matrix_b_22(matrix_b_22), .matrix_b_23(matrix_b_23),
        .matrix_b_30(matrix_b_30), .matrix_b_31(matrix_b_31), .matrix_b_32(matrix_b_32), .matrix_b_33(matrix_b_33),
        
        // Results
        .result_00(result_00), .result_01(result_01), .result_02(result_02), .result_03(result_03),
        .result_10(result_10), .result_11(result_11), .result_12(result_12), .result_13(result_13),
        .result_20(result_20), .result_21(result_21), .result_22(result_22), .result_23(result_23),
        .result_30(result_30), .result_31(result_31), .result_32(result_32), .result_33(result_33),
        
        .computation_done(computation_done),
        .result_valid(result_valid)
    );
    
    // Task to reset the system
    task reset_system;
    begin
        rst_n = 0;
        start = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    end
    endtask
    
    // Task to load test matrices
    task load_test_matrices_1;
    begin
        $display("=== Loading Test Matrices 1 (Identity Test) ===");
        
        // Matrix A (4x4)
        matrix_a_00 = 16'd1;  matrix_a_01 = 16'd2;  matrix_a_02 = 16'd3;  matrix_a_03 = 16'd4;
        matrix_a_10 = 16'd5;  matrix_a_11 = 16'd6;  matrix_a_12 = 16'd7;  matrix_a_13 = 16'd8;
        matrix_a_20 = 16'd9;  matrix_a_21 = 16'd10; matrix_a_22 = 16'd11; matrix_a_23 = 16'd12;
        matrix_a_30 = 16'd13; matrix_a_31 = 16'd14; matrix_a_32 = 16'd15; matrix_a_33 = 16'd16;
        
        // Matrix B (Identity)
        matrix_b_00 = 8'd1;  matrix_b_01 = 8'd0;  matrix_b_02 = 8'd0;  matrix_b_03 = 8'd0;
        matrix_b_10 = 8'd0;  matrix_b_11 = 8'd1;  matrix_b_12 = 8'd0;  matrix_b_13 = 8'd0;
        matrix_b_20 = 8'd0;  matrix_b_21 = 8'd0;  matrix_b_22 = 8'd1;  matrix_b_23 = 8'd0;
        matrix_b_30 = 8'd0;  matrix_b_31 = 8'd0;  matrix_b_32 = 8'd0;  matrix_b_33 = 8'd1;
        
        // Expected results (A * I = A)
        expected_result[0][0] = 32'd1;  expected_result[0][1] = 32'd2;  expected_result[0][2] = 32'd3;  expected_result[0][3] = 32'd4;
        expected_result[1][0] = 32'd5;  expected_result[1][1] = 32'd6;  expected_result[1][2] = 32'd7;  expected_result[1][3] = 32'd8;
        expected_result[2][0] = 32'd9;  expected_result[2][1] = 32'd10; expected_result[2][2] = 32'd11; expected_result[2][3] = 32'd12;
        expected_result[3][0] = 32'd13; expected_result[3][1] = 32'd14; expected_result[3][2] = 32'd15; expected_result[3][3] = 32'd16;
    end
    endtask
    
    // Task to load second test matrices
    task load_test_matrices_2;
    begin
        $display("=== Loading Test Matrices 2 (Diagonal Test) ===");
        
        // Matrix A (Diagonal)
        matrix_a_00 = 16'd2;  matrix_a_01 = 16'd0;  matrix_a_02 = 16'd0;  matrix_a_03 = 16'd0;
        matrix_a_10 = 16'd0;  matrix_a_11 = 16'd3;  matrix_a_12 = 16'd0;  matrix_a_13 = 16'd0;
        matrix_a_20 = 16'd0;  matrix_a_21 = 16'd0;  matrix_a_22 = 16'd4;  matrix_a_23 = 16'd0;
        matrix_a_30 = 16'd0;  matrix_a_31 = 16'd0;  matrix_a_32 = 16'd0;  matrix_a_33 = 16'd5;
        
        // Matrix B (Same values in all rows)
        matrix_b_00 = 8'd1;  matrix_b_01 = 8'd2;  matrix_b_02 = 8'd3;  matrix_b_03 = 8'd4;
        matrix_b_10 = 8'd1;  matrix_b_11 = 8'd2;  matrix_b_12 = 8'd3;  matrix_b_13 = 8'd4;
        matrix_b_20 = 8'd1;  matrix_b_21 = 8'd2;  matrix_b_22 = 8'd3;  matrix_b_23 = 8'd4;
        matrix_b_30 = 8'd1;  matrix_b_31 = 8'd2;  matrix_b_32 = 8'd3;  matrix_b_33 = 8'd4;
        
        // Expected results
        expected_result[0][0] = 32'd2;  expected_result[0][1] = 32'd4;  expected_result[0][2] = 32'd6;  expected_result[0][3] = 32'd8;
        expected_result[1][0] = 32'd3;  expected_result[1][1] = 32'd6;  expected_result[1][2] = 32'd9;  expected_result[1][3] = 32'd12;
        expected_result[2][0] = 32'd4;  expected_result[2][1] = 32'd8;  expected_result[2][2] = 32'd12; expected_result[2][3] = 32'd16;
        expected_result[3][0] = 32'd5;  expected_result[3][1] = 32'd10; expected_result[3][2] = 32'd15; expected_result[3][3] = 32'd20;
    end
    endtask
    
    // Task to start computation and wait for completion
    task run_computation;
    begin
        $display("=== Starting Computation ===");
        @(posedge clk);
        start = 1;  // Pulse start signal
        @(posedge clk);
        start = 0;
        
        $display("Waiting for computation to complete...");
        wait(computation_done == 1);  // Wait for FSM to complete
        
        @(posedge clk);  // Sample results after completion
        $display("Computation completed!");
    end
    endtask
    
    // Task to collect results
    task collect_results;
    begin
        // Collect all results
        actual_result[0][0] = result_00; actual_result[0][1] = result_01; 
        actual_result[0][2] = result_02; actual_result[0][3] = result_03;
        actual_result[1][0] = result_10; actual_result[1][1] = result_11; 
        actual_result[1][2] = result_12; actual_result[1][3] = result_13;
        actual_result[2][0] = result_20; actual_result[2][1] = result_21; 
        actual_result[2][2] = result_22; actual_result[2][3] = result_23;
        actual_result[3][0] = result_30; actual_result[3][1] = result_31; 
        actual_result[3][2] = result_32; actual_result[3][3] = result_33;
    end
    endtask
    
    // Task to display matrices
    task display_matrices;
    begin
        $display("\n=== INPUT MATRIX A ===");
        $display("%2d %2d %2d %2d", matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03);
        $display("%2d %2d %2d %2d", matrix_a_10, matrix_a_11, matrix_a_12, matrix_a_13);
        $display("%2d %2d %2d %2d", matrix_a_20, matrix_a_21, matrix_a_22, matrix_a_23);
        $display("%2d %2d %2d %2d", matrix_a_30, matrix_a_31, matrix_a_32, matrix_a_33);
        
        $display("\n=== WEIGHT MATRIX B ===");
        $display("%2d %2d %2d %2d", matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03);
        $display("%2d %2d %2d %2d", matrix_b_10, matrix_b_11, matrix_b_12, matrix_b_13);
        $display("%2d %2d %2d %2d", matrix_b_20, matrix_b_21, matrix_b_22, matrix_b_23);
        $display("%2d %2d %2d %2d", matrix_b_30, matrix_b_31, matrix_b_32, matrix_b_33);
        
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
    
    // Task to monitor FSM states
    initial begin
        $display("=== FSM State Monitor ===");
        forever begin
            @(posedge clk);
            case (dut.current_state)
                3'b000: $display("Time=%0t: FSM State = IDLE", $time);
                3'b001: $display("Time=%0t: FSM State = LOAD_DATA (cycle=%0d)", $time, dut.cycle_counter);
                3'b010: $display("Time=%0t: FSM State = COMPUTE (compute_cycle=%0d)", $time, dut.compute_counter);
                3'b011: $display("Time=%0t: FSM State = DRAIN (cycle=%0d)", $time, dut.cycle_counter);
                3'b100: $display("Time=%0t: FSM State = DONE", $time);
                default: $display("Time=%0t: FSM State = UNKNOWN", $time);
            endcase
        end
    end
    
    // Main test sequence
    initial begin
        $display("=== FSM-Controlled 4x4 Systolic Array Testbench ===");
        
        // Test 1: Identity Matrix
        $display("\n=== TEST 1: Identity Matrix Multiplication ===");
        reset_system();
        load_test_matrices_1();
        display_matrices();
        run_computation();
        collect_results();
        display_matrices();
        verify_results();
        
        // Wait some cycles between tests
        repeat(10) @(posedge clk);
        
        // Test 2: Diagonal Matrix
        $display("\n\n=== TEST 2: Diagonal Matrix Multiplication ===");
        reset_system();
        load_test_matrices_2();
        display_matrices();
        run_computation();
        collect_results();
        display_matrices();
        verify_results();
        
        $display("\n=== All Tests Complete ===");
        repeat(10) @(posedge clk);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
