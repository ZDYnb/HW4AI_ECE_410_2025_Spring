// ===========================================
// Fixed Systolic Array with Proper Timing
// Addresses the systolic scheduling issue
// ===========================================

`timescale 1ns/1ps

// ===========================================
// Systolic Array with Input Scheduling
// ===========================================
module systolic_array_4x4_scheduled (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_computation,
    
    // Matrix A (4x4) - loaded all at once
    input  logic [15:0] matrix_a [4][4],
    
    // Matrix B (4x4) - loaded all at once  
    input  logic [7:0]  matrix_b [4][4],
    
    // Results output (4×4 matrix)
    output logic [31:0] result_matrix [4][4],
    output logic        computation_done
);

    // Internal systolic array connections
    logic        enable, clear_accum;
    logic [15:0] data_in_0, data_in_1, data_in_2, data_in_3;
    logic        data_valid_0, data_valid_1, data_valid_2, data_valid_3;
    logic [7:0]  weight_in_0, weight_in_1, weight_in_2, weight_in_3;
    logic        weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3;
    
    logic [31:0] result_00, result_01, result_02, result_03;
    logic [31:0] result_10, result_11, result_12, result_13;
    logic [31:0] result_20, result_21, result_22, result_23;
    logic [31:0] result_30, result_31, result_32, result_33;
    
    logic        valid_00, valid_01, valid_02, valid_03;
    logic        valid_10, valid_11, valid_12, valid_13;
    logic        valid_20, valid_21, valid_22, valid_23;
    logic        valid_30, valid_31, valid_32, valid_33;
    
    // Systolic Array Instance
    systolic_array_4x4 systolic_core (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in_0(data_in_0), .data_in_1(data_in_1), .data_in_2(data_in_2), .data_in_3(data_in_3),
        .data_valid_0(data_valid_0), .data_valid_1(data_valid_1), .data_valid_2(data_valid_2), .data_valid_3(data_valid_3),
        .weight_in_0(weight_in_0), .weight_in_1(weight_in_1), .weight_in_2(weight_in_2), .weight_in_3(weight_in_3),
        .weight_valid_0(weight_valid_0), .weight_valid_1(weight_valid_1), .weight_valid_2(weight_valid_2), .weight_valid_3(weight_valid_3),
        .result_00(result_00), .result_01(result_01), .result_02(result_02), .result_03(result_03),
        .result_10(result_10), .result_11(result_11), .result_12(result_12), .result_13(result_13),
        .result_20(result_20), .result_21(result_21), .result_22(result_22), .result_23(result_23),
        .result_30(result_30), .result_31(result_31), .result_32(result_32), .result_33(result_33),
        .valid_00(valid_00), .valid_01(valid_01), .valid_02(valid_02), .valid_03(valid_03),
        .valid_10(valid_10), .valid_11(valid_11), .valid_12(valid_12), .valid_13(valid_13),
        .valid_20(valid_20), .valid_21(valid_21), .valid_22(valid_22), .valid_23(valid_23),
        .valid_30(valid_30), .valid_31(valid_31), .valid_32(valid_32), .valid_33(valid_33)
    );
    
    // Control state machine
    typedef enum logic [3:0] {
        IDLE, CYCLE_0, CYCLE_1, CYCLE_2, CYCLE_3, 
        WAIT_PIPELINE, EXTRACT_RESULTS, DONE
    } state_t;
    state_t state;
    
    logic [3:0] cycle_count;
    logic [3:0] wait_count;
    
    // Systolic scheduling control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            enable <= 1'b0;
            clear_accum <= 1'b0;
            computation_done <= 1'b0;
            cycle_count <= 4'b0;
            wait_count <= 4'b0;
            
            // Initialize all inputs to 0
            data_in_0 <= 16'b0; data_in_1 <= 16'b0; data_in_2 <= 16'b0; data_in_3 <= 16'b0;
            data_valid_0 <= 1'b0; data_valid_1 <= 1'b0; data_valid_2 <= 1'b0; data_valid_3 <= 1'b0;
            weight_in_0 <= 8'b0; weight_in_1 <= 8'b0; weight_in_2 <= 8'b0; weight_in_3 <= 8'b0;
            weight_valid_0 <= 1'b0; weight_valid_1 <= 1'b0; weight_valid_2 <= 1'b0; weight_valid_3 <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_computation) begin
                        state <= CYCLE_0;
                        enable <= 1'b1;
                        clear_accum <= 1'b1;  // Clear on first cycle
                        cycle_count <= 4'b0;
                        computation_done <= 1'b0;
                    end
                end
                
                CYCLE_0: begin
                    // Feed column 0 of A and row 0 of B
                    data_in_0 <= matrix_a[0][0]; data_valid_0 <= 1'b1;  // A[0,0]
                    data_in_1 <= matrix_a[1][0]; data_valid_1 <= 1'b1;  // A[1,0]
                    data_in_2 <= matrix_a[2][0]; data_valid_2 <= 1'b1;  // A[2,0]
                    data_in_3 <= matrix_a[3][0]; data_valid_3 <= 1'b1;  // A[3,0]
                    
                    weight_in_0 <= matrix_b[0][0]; weight_valid_0 <= 1'b1;  // B[0,0]
                    weight_in_1 <= matrix_b[0][1]; weight_valid_1 <= 1'b1;  // B[0,1]
                    weight_in_2 <= matrix_b[0][2]; weight_valid_2 <= 1'b1;  // B[0,2]
                    weight_in_3 <= matrix_b[0][3]; weight_valid_3 <= 1'b1;  // B[0,3]
                    
                    clear_accum <= 1'b0;  // Start accumulating from next cycle
                    state <= CYCLE_1;
                end
                
                CYCLE_1: begin
                    // Feed column 1 of A and row 1 of B
                    data_in_0 <= matrix_a[0][1]; // A[0,1]
                    data_in_1 <= matrix_a[1][1]; // A[1,1] 
                    data_in_2 <= matrix_a[2][1]; // A[2,1]
                    data_in_3 <= matrix_a[3][1]; // A[3,1]
                    
                    weight_in_0 <= matrix_b[1][0]; // B[1,0]
                    weight_in_1 <= matrix_b[1][1]; // B[1,1]
                    weight_in_2 <= matrix_b[1][2]; // B[1,2]
                    weight_in_3 <= matrix_b[1][3]; // B[1,3]
                    
                    state <= CYCLE_2;
                end
                
                CYCLE_2: begin
                    // Feed column 2 of A and row 2 of B
                    data_in_0 <= matrix_a[0][2]; // A[0,2]
                    data_in_1 <= matrix_a[1][2]; // A[1,2]
                    data_in_2 <= matrix_a[2][2]; // A[2,2]
                    data_in_3 <= matrix_a[3][2]; // A[3,2]
                    
                    weight_in_0 <= matrix_b[2][0]; // B[2,0]
                    weight_in_1 <= matrix_b[2][1]; // B[2,1]
                    weight_in_2 <= matrix_b[2][2]; // B[2,2]
                    weight_in_3 <= matrix_b[2][3]; // B[2,3]
                    
                    state <= CYCLE_3;
                end
                
                CYCLE_3: begin
                    // Feed column 3 of A and row 3 of B
                    data_in_0 <= matrix_a[0][3]; // A[0,3]
                    data_in_1 <= matrix_a[1][3]; // A[1,3]
                    data_in_2 <= matrix_a[2][3]; // A[2,3]
                    data_in_3 <= matrix_a[3][3]; // A[3,3]
                    
                    weight_in_0 <= matrix_b[3][0]; // B[3,0]
                    weight_in_1 <= matrix_b[3][1]; // B[3,1]
                    weight_in_2 <= matrix_b[3][2]; // B[3,2]
                    weight_in_3 <= matrix_b[3][3]; // B[3,3]
                    
                    state <= WAIT_PIPELINE;
                    wait_count <= 4'b0;
                end
                
                WAIT_PIPELINE: begin
                    // Turn off inputs and wait for pipeline to finish
                    data_valid_0 <= 1'b0; data_valid_1 <= 1'b0; 
                    data_valid_2 <= 1'b0; data_valid_3 <= 1'b0;
                    weight_valid_0 <= 1'b0; weight_valid_1 <= 1'b0; 
                    weight_valid_2 <= 1'b0; weight_valid_3 <= 1'b0;
                    
                    if (wait_count >= 4'd5) begin  // Wait for pipeline
                        state <= EXTRACT_RESULTS;
                    end else begin
                        wait_count <= wait_count + 1;
                    end
                end
                
                EXTRACT_RESULTS: begin
                    // Copy results to output matrix
                    result_matrix[0][0] <= result_00; result_matrix[0][1] <= result_01; 
                    result_matrix[0][2] <= result_02; result_matrix[0][3] <= result_03;
                    result_matrix[1][0] <= result_10; result_matrix[1][1] <= result_11; 
                    result_matrix[1][2] <= result_12; result_matrix[1][3] <= result_13;
                    result_matrix[2][0] <= result_20; result_matrix[2][1] <= result_21; 
                    result_matrix[2][2] <= result_22; result_matrix[2][3] <= result_23;
                    result_matrix[3][0] <= result_30; result_matrix[3][1] <= result_31; 
                    result_matrix[3][2] <= result_32; result_matrix[3][3] <= result_33;
                    
                    state <= DONE;
                end
                
                DONE: begin
                    computation_done <= 1'b1;
                    enable <= 1'b0;
                    state <= IDLE;  // Ready for next computation
                end
            endcase
        end
    end

endmodule

// ===========================================
// Proper Test with Scheduled Systolic Array
// ===========================================
module tb_scheduled_systolic;

    parameter CLK_PERIOD = 10;
    
    logic        clk, rst_n;
    logic        start_computation;
    logic [15:0] matrix_a [4][4];
    logic [7:0]  matrix_b [4][4];
    logic [31:0] result_matrix [4][4];
    logic        computation_done;
    
    // DUT
    systolic_array_4x4_scheduled dut (.*);
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to display matrix
    task display_matrix(input string name, input logic [31:0] mat [4][4]);
        $display("%s:", name);
        for (int i = 0; i < 4; i++) begin
            $display("  [%3d, %3d, %3d, %3d]", mat[i][0], mat[i][1], mat[i][2], mat[i][3]);
        end
        $display("");
    endtask
    
    // Task to perform matrix multiplication
    task multiply_matrices(input string test_name);
        $display("=== %s ===", test_name);
        start_computation = 1'b1;
        #10;
        start_computation = 1'b0;
        
        // Wait for completion
        wait(computation_done);
        #10;
        
        display_matrix("Result", result_matrix);
    endtask
    
    initial begin
        $display("=== Scheduled Systolic Array Tests ===");
        
        // Initialize
        rst_n = 0;
        start_computation = 0;
        #20;
        rst_n = 1;
        #10;
        
        // =========================================
        // TEST 1: Identity Matrix (A × I = A)
        // =========================================
        $display("TEST 1: Identity Matrix Test");
        
        // Set up matrix A
        matrix_a[0][0] = 1;  matrix_a[0][1] = 2;  matrix_a[0][2] = 3;  matrix_a[0][3] = 4;
        matrix_a[1][0] = 5;  matrix_a[1][1] = 6;  matrix_a[1][2] = 7;  matrix_a[1][3] = 8;
        matrix_a[2][0] = 9;  matrix_a[2][1] = 10; matrix_a[2][2] = 11; matrix_a[2][3] = 12;
        matrix_a[3][0] = 13; matrix_a[3][1] = 14; matrix_a[3][2] = 15; matrix_a[3][3] = 16;
        
        // Set up identity matrix B  
        matrix_b[0][0] = 1; matrix_b[0][1] = 0; matrix_b[0][2] = 0; matrix_b[0][3] = 0;
        matrix_b[1][0] = 0; matrix_b[1][1] = 1; matrix_b[1][2] = 0; matrix_b[1][3] = 0;
        matrix_b[2][0] = 0; matrix_b[2][1] = 0; matrix_b[2][2] = 1; matrix_b[2][3] = 0;
        matrix_b[3][0] = 0; matrix_b[3][1] = 0; matrix_b[3][2] = 0; matrix_b[3][3] = 1;
        
        multiply_matrices("Identity Test");
        
        // Verify result should equal matrix A
        if (result_matrix[0][0] == 1 && result_matrix[0][1] == 2 && result_matrix[0][2] == 3 && result_matrix[0][3] == 4 &&
            result_matrix[1][0] == 5 && result_matrix[1][1] == 6 && result_matrix[1][2] == 7 && result_matrix[1][3] == 8) begin
            $display("¿ TEST 1 PASSED: Identity matrix works!");
        end else begin
            $display("¿ TEST 1 FAILED: Identity matrix wrong");
        end
        
        // =========================================
        // TEST 2: Simple 2×2 in corner
        // =========================================
        $display("TEST 2: Simple 2×2 Test");
        $display("A[0:1,0:1] = [1,2; 3,4] × B[0:1,0:1] = [2,1; 1,2] = [4,5; 10,11]");
        
        // Clear matrices
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                matrix_a[i][j] = 0;
                matrix_b[i][j] = 0;
            end
        end
        
        // Set up 2×2 matrices in top-left corner
        matrix_a[0][0] = 1; matrix_a[0][1] = 2;
        matrix_a[1][0] = 3; matrix_a[1][1] = 4;
        
        matrix_b[0][0] = 2; matrix_b[0][1] = 1;
        matrix_b[1][0] = 1; matrix_b[1][1] = 2;
        
        multiply_matrices("2×2 Corner Test");
        
        if (result_matrix[0][0] == 4 && result_matrix[0][1] == 5 && 
            result_matrix[1][0] == 10 && result_matrix[1][1] == 11) begin
            $display("¿ TEST 2 PASSED: 2×2 multiplication correct!");
        end else begin
            $display("¿ TEST 2 FAILED: Expected [4,5; 10,11], got [%0d,%0d; %0d,%0d]",
                     result_matrix[0][0], result_matrix[0][1], result_matrix[1][0], result_matrix[1][1]);
        end
        
        // =========================================
        // TEST 3: Single column multiplication  
        // =========================================
        $display("TEST 3: Single Column Test");
        
        // Clear matrices
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                matrix_a[i][j] = 0;
                matrix_b[i][j] = 0;
            end
        end
        
        // A has values only in first column
        matrix_a[0][0] = 2; matrix_a[1][0] = 3; matrix_a[2][0] = 4; matrix_a[3][0] = 5;
        
        // B has values only in first row, first column
        matrix_b[0][0] = 10;
        
        multiply_matrices("Single Column Test");
        
        if (result_matrix[0][0] == 20 && result_matrix[1][0] == 30 && 
            result_matrix[2][0] == 40 && result_matrix[3][0] == 50 &&
            result_matrix[0][1] == 0 && result_matrix[0][2] == 0) begin
            $display("¿ TEST 3 PASSED: Single column correct!");
        end else begin
            $display("¿ TEST 3 FAILED: Single column wrong");
        end
        
        $display("");
        $display("=== VERIFICATION COMPLETE ===");
        $display("Systolic array with proper scheduling tested!");
        
        $finish;
    end

endmodule

// ===========================================
// Include the original systolic array
// ===========================================
`include "systolic_4x4_core.sv"
