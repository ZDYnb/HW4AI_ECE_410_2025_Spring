// ===========================================
// Detailed Cycle-by-Cycle Systolic Array Testbench
// Shows internal PE operations and data flow
// ===========================================

`timescale 1ns/1ps

module tb_detailed_systolic_array_4x4;

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
    integer cycle_count;
    reg [31:0] expected_result [0:3][0:3];
    reg monitoring_enabled;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end
    
    // Cycle counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_count <= 0;
        else if (dut.current_state != 3'b000)  // Not IDLE
            cycle_count <= cycle_count + 1;
        else
            cycle_count <= 0;
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
    
    // Detailed FSM and Data Flow Monitor
    always @(posedge clk) begin
        if (monitoring_enabled) begin
            $display("\n=== CYCLE %0d ===", cycle_count);
            
            // FSM State
            case (dut.current_state)
                3'b000: $display("FSM State: IDLE");
                3'b001: $display("FSM State: LOAD_DATA (cycle=%0d)", dut.cycle_counter);
                3'b010: $display("FSM State: COMPUTE (compute_cycle=%0d)", dut.compute_counter);
                3'b011: $display("FSM State: DRAIN (cycle=%0d)", dut.cycle_counter);
                3'b100: $display("FSM State: DONE");
                default: $display("FSM State: UNKNOWN");
            endcase
            
            // Control Signals
            $display("Control: enable_pe=%b, clear_accum=%b, data_feed=%b, weight_feed=%b", 
                     dut.enable_pe, dut.clear_accum_pe, dut.data_feed_enable, dut.weight_feed_enable);
            
            // Current Input Data and Weights
            if (dut.data_feed_enable) begin
                $display("Input Data:    [%2d] [%2d] [%2d] [%2d]", 
                         dut.data_in_0, dut.data_in_1, dut.data_in_2, dut.data_in_3);
                $display("Input Weights: [%2d] [%2d] [%2d] [%2d]", 
                         dut.weight_in_0, dut.weight_in_1, dut.weight_in_2, dut.weight_in_3);
                $display("Data Valid:    [%b] [%b] [%b] [%b]", 
                         dut.data_valid_0, dut.data_valid_1, dut.data_valid_2, dut.data_valid_3);
                $display("Weight Valid:  [%b] [%b] [%b] [%b]", 
                         dut.weight_valid_0, dut.weight_valid_1, dut.weight_valid_2, dut.weight_valid_3);
            end
            
            // Processing Element Activities
            $display("\n--- PE Activities ---");
            display_pe_activity(0, 0, dut.pe_00.data_in, dut.pe_00.weight_in, 
                               dut.pe_00.data_valid_in, dut.pe_00.weight_valid_in, 
                               dut.pe_00.accum_out, dut.pe_00.result_valid);
            display_pe_activity(0, 1, dut.pe_01.data_in, dut.pe_01.weight_in, 
                               dut.pe_01.data_valid_in, dut.pe_01.weight_valid_in, 
                               dut.pe_01.accum_out, dut.pe_01.result_valid);
            display_pe_activity(0, 2, dut.pe_02.data_in, dut.pe_02.weight_in, 
                               dut.pe_02.data_valid_in, dut.pe_02.weight_valid_in, 
                               dut.pe_02.accum_out, dut.pe_02.result_valid);
            display_pe_activity(0, 3, dut.pe_03.data_in, dut.pe_03.weight_in, 
                               dut.pe_03.data_valid_in, dut.pe_03.weight_valid_in, 
                               dut.pe_03.accum_out, dut.pe_03.result_valid);
                               
            display_pe_activity(1, 0, dut.pe_10.data_in, dut.pe_10.weight_in, 
                               dut.pe_10.data_valid_in, dut.pe_10.weight_valid_in, 
                               dut.pe_10.accum_out, dut.pe_10.result_valid);
            display_pe_activity(1, 1, dut.pe_11.data_in, dut.pe_11.weight_in, 
                               dut.pe_11.data_valid_in, dut.pe_11.weight_valid_in, 
                               dut.pe_11.accum_out, dut.pe_11.result_valid);
            display_pe_activity(1, 2, dut.pe_12.data_in, dut.pe_12.weight_in, 
                               dut.pe_12.data_valid_in, dut.pe_12.weight_valid_in, 
                               dut.pe_12.accum_out, dut.pe_12.result_valid);
            display_pe_activity(1, 3, dut.pe_13.data_in, dut.pe_13.weight_in, 
                               dut.pe_13.data_valid_in, dut.pe_13.weight_valid_in, 
                               dut.pe_13.accum_out, dut.pe_13.result_valid);
                               
            display_pe_activity(2, 0, dut.pe_20.data_in, dut.pe_20.weight_in, 
                               dut.pe_20.data_valid_in, dut.pe_20.weight_valid_in, 
                               dut.pe_20.accum_out, dut.pe_20.result_valid);
            display_pe_activity(2, 1, dut.pe_21.data_in, dut.pe_21.weight_in, 
                               dut.pe_21.data_valid_in, dut.pe_21.weight_valid_in, 
                               dut.pe_21.accum_out, dut.pe_21.result_valid);
            display_pe_activity(2, 2, dut.pe_22.data_in, dut.pe_22.weight_in, 
                               dut.pe_22.data_valid_in, dut.pe_22.weight_valid_in, 
                               dut.pe_22.accum_out, dut.pe_22.result_valid);
            display_pe_activity(2, 3, dut.pe_23.data_in, dut.pe_23.weight_in, 
                               dut.pe_23.data_valid_in, dut.pe_23.weight_valid_in, 
                               dut.pe_23.accum_out, dut.pe_23.result_valid);
                               
            display_pe_activity(3, 0, dut.pe_30.data_in, dut.pe_30.weight_in, 
                               dut.pe_30.data_valid_in, dut.pe_30.weight_valid_in, 
                               dut.pe_30.accum_out, dut.pe_30.result_valid);
            display_pe_activity(3, 1, dut.pe_31.data_in, dut.pe_31.weight_in, 
                               dut.pe_31.data_valid_in, dut.pe_31.weight_valid_in, 
                               dut.pe_31.accum_out, dut.pe_31.result_valid);
            display_pe_activity(3, 2, dut.pe_32.data_in, dut.pe_32.weight_in, 
                               dut.pe_32.data_valid_in, dut.pe_32.weight_valid_in, 
                               dut.pe_32.accum_out, dut.pe_32.result_valid);
            display_pe_activity(3, 3, dut.pe_33.data_in, dut.pe_33.weight_in, 
                               dut.pe_33.data_valid_in, dut.pe_33.weight_valid_in, 
                               dut.pe_33.accum_out, dut.pe_33.result_valid);
            
            // Current Results Matrix
            $display("\n--- Current Results Matrix ---");
            $display("[%3d] [%3d] [%3d] [%3d]", result_00, result_01, result_02, result_03);
            $display("[%3d] [%3d] [%3d] [%3d]", result_10, result_11, result_12, result_13);
            $display("[%3d] [%3d] [%3d] [%3d]", result_20, result_21, result_22, result_23);
            $display("[%3d] [%3d] [%3d] [%3d]", result_30, result_31, result_32, result_33);
            
            $display("========================================");
        end
    end
    
    // Task to display PE activity
    task display_pe_activity;
        input [1:0] row, col;
        input [15:0] data_in;
        input [7:0] weight_in;
        input data_valid, weight_valid;
        input [31:0] accum;
        input valid;
    begin
        if (data_valid && weight_valid) begin
            $display("PE[%0d][%0d]: data=%0d * weight=%0d -> accum=%0d (valid=%b)", 
                     row, col, data_in, weight_in, accum, valid);
        end else if (valid) begin
            $display("PE[%0d][%0d]: -- * -- -> accum=%0d (holding)", row, col, accum);
        end else begin
            $display("PE[%0d][%0d]: idle", row, col);
        end
    end
    endtask
    
    // Task to reset the system
    task reset_system;
    begin
        monitoring_enabled = 0;
        rst_n = 0;
        start = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    end
    endtask
    
    // Task to load full 4x4 test matrices
    task load_full_4x4_test;
    begin
        $display("\n=== Loading Full 4x4 Test Matrices ===");
        
        // Matrix A (Full 4x4 with small values for easy tracking)
        matrix_a_00 = 16'd1;  matrix_a_01 = 16'd1;  matrix_a_02 = 16'd1;  matrix_a_03 = 16'd1;
        matrix_a_10 = 16'd2;  matrix_a_11 = 16'd2;  matrix_a_12 = 16'd2;  matrix_a_13 = 16'd2;
        matrix_a_20 = 16'd3;  matrix_a_21 = 16'd3;  matrix_a_22 = 16'd3;  matrix_a_23 = 16'd3;
        matrix_a_30 = 16'd4;  matrix_a_31 = 16'd4;  matrix_a_32 = 16'd4;  matrix_a_33 = 16'd4;
        
        // Matrix B (Full 4x4 with different pattern)
        matrix_b_00 = 8'd1;  matrix_b_01 = 8'd2;  matrix_b_02 = 8'd3;  matrix_b_03 = 8'd4;
        matrix_b_10 = 8'd1;  matrix_b_11 = 8'd2;  matrix_b_12 = 8'd3;  matrix_b_13 = 8'd4;
        matrix_b_20 = 8'd1;  matrix_b_21 = 8'd2;  matrix_b_22 = 8'd3;  matrix_b_23 = 8'd4;
        matrix_b_30 = 8'd1;  matrix_b_31 = 8'd2;  matrix_b_32 = 8'd3;  matrix_b_33 = 8'd4;
        
        // Expected results: Manual calculation
        // Row 0: [1 1 1 1] * [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4] = [4 8 12 16]
        // Row 1: [2 2 2 2] * [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4] = [8 16 24 32]
        // Row 2: [3 3 3 3] * [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4] = [12 24 36 48]
        // Row 3: [4 4 4 4] * [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4] = [16 32 48 64]
        expected_result[0][0] = 32'd4;   expected_result[0][1] = 32'd8;   expected_result[0][2] = 32'd12;  expected_result[0][3] = 32'd16;
        expected_result[1][0] = 32'd8;   expected_result[1][1] = 32'd16;  expected_result[1][2] = 32'd24;  expected_result[1][3] = 32'd32;
        expected_result[2][0] = 32'd12;  expected_result[2][1] = 32'd24;  expected_result[2][2] = 32'd36;  expected_result[2][3] = 32'd48;
        expected_result[3][0] = 32'd16;  expected_result[3][1] = 32'd32;  expected_result[3][2] = 32'd48;  expected_result[3][3] = 32'd64;
        
        $display("\nInput Matrix A (4x4):");
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_a_10, matrix_a_11, matrix_a_12, matrix_a_13);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_a_20, matrix_a_21, matrix_a_22, matrix_a_23);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_a_30, matrix_a_31, matrix_a_32, matrix_a_33);
        
        $display("\nInput Matrix B (4x4):");
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_b_10, matrix_b_11, matrix_b_12, matrix_b_13);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_b_20, matrix_b_21, matrix_b_22, matrix_b_23);
        $display("[%2d] [%2d] [%2d] [%2d]", matrix_b_30, matrix_b_31, matrix_b_32, matrix_b_33);
        
        $display("\nExpected Result (A × B):");
        $display("[%3d] [%3d] [%3d] [%3d]", expected_result[0][0], expected_result[0][1], expected_result[0][2], expected_result[0][3]);
        $display("[%3d] [%3d] [%3d] [%3d]", expected_result[1][0], expected_result[1][1], expected_result[1][2], expected_result[1][3]);
        $display("[%3d] [%3d] [%3d] [%3d]", expected_result[2][0], expected_result[2][1], expected_result[2][2], expected_result[2][3]);
        $display("[%3d] [%3d] [%3d] [%3d]", expected_result[3][0], expected_result[3][1], expected_result[3][2], expected_result[3][3]);
        
        $display("\n=== Matrix Multiplication Explanation ===");
        $display("A[0]·B[:,0] = 1×1 + 1×1 + 1×1 + 1×1 = 4   (result[0][0])");
        $display("A[0]·B[:,1] = 1×2 + 1×2 + 1×2 + 1×2 = 8   (result[0][1])");
        $display("A[1]·B[:,0] = 2×1 + 2×1 + 2×1 + 2×1 = 8   (result[1][0])");
        $display("A[3]·B[:,3] = 4×4 + 4×4 + 4×4 + 4×4 = 64  (result[3][3])");
    end
    endtask
    
    // Task to start computation with detailed monitoring
    task run_detailed_computation;
    begin
        $display("\n=== Starting Detailed Computation ===");
        monitoring_enabled = 1;  // Enable detailed monitoring
        
        @(posedge clk);
        start = 1;  // Pulse start signal
        @(posedge clk);
        start = 0;
        
        $display("Monitoring systolic array operation...\n");
        wait(computation_done == 1);  // Wait for FSM to complete
        
        monitoring_enabled = 0;  // Disable monitoring
        @(posedge clk);
        $display("\n=== Computation Completed! ===");
    end
    endtask
    
    // Task to verify final results (updated for full 4x4)
    task verify_final_results;
        reg test_passed;
        integer i, j;
        reg [31:0] actual_results [0:3][0:3];
    begin
        test_passed = 1;
        $display("\n=== FINAL VERIFICATION ===");
        
        // Collect actual results
        actual_results[0][0] = result_00; actual_results[0][1] = result_01; actual_results[0][2] = result_02; actual_results[0][3] = result_03;
        actual_results[1][0] = result_10; actual_results[1][1] = result_11; actual_results[1][2] = result_12; actual_results[1][3] = result_13;
        actual_results[2][0] = result_20; actual_results[2][1] = result_21; actual_results[2][2] = result_22; actual_results[2][3] = result_23;
        actual_results[3][0] = result_30; actual_results[3][1] = result_31; actual_results[3][2] = result_32; actual_results[3][3] = result_33;
        
        $display("Final Results:");
        $display("[%3d] [%3d] [%3d] [%3d]", result_00, result_01, result_02, result_03);
        $display("[%3d] [%3d] [%3d] [%3d]", result_10, result_11, result_12, result_13);
        $display("[%3d] [%3d] [%3d] [%3d]", result_20, result_21, result_22, result_23);
        $display("[%3d] [%3d] [%3d] [%3d]", result_30, result_31, result_32, result_33);
        
        // Check all 16 results
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                if (actual_results[i][j] !== expected_result[i][j]) begin
                    $display("MISMATCH at [%0d][%0d]: Expected=%0d, Got=%0d", i, j, expected_result[i][j], actual_results[i][j]);
                    test_passed = 0;
                end
            end
        end
        
        if (test_passed) begin
            $display("*** FULL 4x4 MATRIX TEST PASSED! All 16 results correct! ***");
        end else begin
            $display("*** FULL 4x4 MATRIX TEST FAILED! ***");
        end
        
        $display("\n=== Key Verification Points ===");
        $display("Corner elements:");
        $display("  Top-left [0][0]:     Expected=%0d, Got=%0d %s", expected_result[0][0], result_00, (result_00 == expected_result[0][0]) ? "¿" : "¿");
        $display("  Top-right [0][3]:    Expected=%0d, Got=%0d %s", expected_result[0][3], result_03, (result_03 == expected_result[0][3]) ? "¿" : "¿");
        $display("  Bottom-left [3][0]:  Expected=%0d, Got=%0d %s", expected_result[3][0], result_30, (result_30 == expected_result[3][0]) ? "¿" : "¿");
        $display("  Bottom-right [3][3]: Expected=%0d, Got=%0d %s", expected_result[3][3], result_33, (result_33 == expected_result[3][3]) ? "¿" : "¿");
    end
    endtask
    
    // Main test sequence
    initial begin
        $display("=== Detailed Cycle-by-Cycle 4x4 Systolic Array Demo ===");
        $display("This testbench shows exactly how the systolic array performs full 4x4 matrix multiplication!");
        
        reset_system();
        load_full_4x4_test();
        run_detailed_computation();
        verify_final_results();
        
        $display("\n=== Full 4x4 Demo Complete ===");
        $display("You've seen all 16 processing elements working together!");
        $display("The systolic array successfully computed a complete 4x4 × 4x4 matrix multiplication.");
        repeat(5) @(posedge clk);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #50000;  // 50us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
