// ===========================================
// Detailed Computation Display Testbench
// Shows exact input/output matrices
// ===========================================
`timescale 1ns/1ps

module tb_detailed_computation;

// ===========================================
// Parameters
// ===========================================
parameter ARRAY_SIZE = 4;              // Use 4x4 for clear display
parameter DATA_WIDTH = 16;
parameter WEIGHT_WIDTH = 8;
parameter ACCUM_WIDTH = 32;
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
wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

// Helper arrays for easier matrix manipulation
reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [ACCUM_WIDTH-1:0] expected_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [ACCUM_WIDTH-1:0] actual_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

integer i, j, k;

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

// Task to flatten matrices
task flatten_matrices;
    begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = matrix_a[i][j];
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

// Task to calculate expected result
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

// Task to print matrix with format
task print_matrix;
    input integer matrix_type; // 0=A, 1=B, 2=expected, 3=actual
    input [255:0] matrix_name;
    begin
        case (matrix_type)
            0: begin
                $display("%s:", matrix_name);
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%4d ", $signed(matrix_a[i][j]));
                    end
                    $display("");
                end
            end
            1: begin
                $display("%s:", matrix_name);
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%4d ", $signed(matrix_b[i][j]));
                    end
                    $display("");
                end
            end
            2: begin
                $display("%s:", matrix_name);
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%6d ", $signed(expected_result[i][j]));
                    end
                    $display("");
                end
            end
            3: begin
                $display("%s:", matrix_name);
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $write("  ");
                    for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                        $write("%6d ", $signed(actual_result[i][j]));
                    end
                    $display("");
                end
            end
        endcase
        $display("");
    end
endtask

// Task to show detailed computation for one element
task show_element_computation;
    input integer row;
    input integer col;
    begin
        $display("=== Detailed computation for Result[%0d][%0d] ===", row, col);
        $write("Result[%0d][%0d] = ", row, col);
        for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
            if (k > 0) $write(" + ");
            $write("A[%0d][%0d]×B[%0d][%0d]", row, k, k, col);
        end
        $display("");
        
        $write("             = ");
        for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
            if (k > 0) $write(" + ");
            $write("(%0d)×(%0d)", $signed(matrix_a[row][k]), $signed(matrix_b[k][col]));
        end
        $display("");
        
        $write("             = ");
        for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
            if (k > 0) $write(" + ");
            $write("%0d", $signed(matrix_a[row][k]) * $signed(matrix_b[k][col]));
        end
        $display("");
        
        $display("             = %0d", expected_result[row][col]);
        $display("Hardware got: %0d", actual_result[row][col]);
        
        if (expected_result[row][col] === actual_result[row][col]) begin
            $display("¿ MATCH!");
        end else begin
            $display("¿ MISMATCH!");
        end
        $display("");
    end
endtask

// Task to run test with detailed output
task run_detailed_test;
    input [255:0] test_name;
    begin
        $display("\n" + "="*60);
        $display("¿ %s - DETAILED COMPUTATION", test_name);
        $display("="*60);
        
        // Calculate expected result
        calculate_expected();
        
        // Print input matrices
        print_matrix(0, "Input Matrix A");
        print_matrix(1, "Input Matrix B");
        print_matrix(2, "Expected Result (A × B)");
        
        // Reset and start computation
        rst_n = 0;
        start = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        $display("¿ Starting hardware computation...");
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait for completion
        wait(done);
        #(CLK_PERIOD * 2);
        
        // Extract and display results
        unflatten_result();
        print_matrix(3, "Actual Hardware Result");
        
        // Show detailed computation for a few key elements
        $display("¿ DETAILED ELEMENT COMPUTATIONS:");
        show_element_computation(0, 0);  // Top-left
        show_element_computation(1, 1);  // Diagonal
        show_element_computation(0, ARRAY_SIZE-1);  // Top-right
        show_element_computation(ARRAY_SIZE-1, ARRAY_SIZE-1);  // Bottom-right
        
        #(CLK_PERIOD * 5);
    end
endtask

// ===========================================
// Test Cases
// ===========================================
initial begin
    $display("¿ DETAILED SYSTOLIC ARRAY COMPUTATION ANALYSIS");
    $display("Array Size: %0dx%0d", ARRAY_SIZE, ARRAY_SIZE);
    
    // Initialize
    clk = 0;
    rst_n = 0;
    start = 0;
    #(CLK_PERIOD * 3);
    
    // Test 1: Identity Matrix
    matrix_a[0][0] = 1; matrix_a[0][1] = 0; matrix_a[0][2] = 0; matrix_a[0][3] = 0;
    matrix_a[1][0] = 0; matrix_a[1][1] = 1; matrix_a[1][2] = 0; matrix_a[1][3] = 0;
    matrix_a[2][0] = 0; matrix_a[2][1] = 0; matrix_a[2][2] = 1; matrix_a[2][3] = 0;
    matrix_a[3][0] = 0; matrix_a[3][1] = 0; matrix_a[3][2] = 0; matrix_a[3][3] = 1;
    
    matrix_b[0][0] = 1; matrix_b[0][1] = 0; matrix_b[0][2] = 0; matrix_b[0][3] = 0;
    matrix_b[1][0] = 0; matrix_b[1][1] = 1; matrix_b[1][2] = 0; matrix_b[1][3] = 0;
    matrix_b[2][0] = 0; matrix_b[2][1] = 0; matrix_b[2][2] = 1; matrix_b[2][3] = 0;
    matrix_b[3][0] = 0; matrix_b[3][1] = 0; matrix_b[3][2] = 0; matrix_b[3][3] = 1;
    
    flatten_matrices();
    run_detailed_test("IDENTITY MATRIX");
    
    // Test 2: Simple Matrix
    matrix_a[0][0] = 1; matrix_a[0][1] = 2; matrix_a[0][2] = 0; matrix_a[0][3] = 0;
    matrix_a[1][0] = 3; matrix_a[1][1] = 4; matrix_a[1][2] = 0; matrix_a[1][3] = 0;
    matrix_a[2][0] = 0; matrix_a[2][1] = 0; matrix_a[2][2] = 1; matrix_a[2][3] = 0;
    matrix_a[3][0] = 0; matrix_a[3][1] = 0; matrix_a[3][2] = 0; matrix_a[3][3] = 1;
    
    matrix_b[0][0] = 5; matrix_b[0][1] = 6; matrix_b[0][2] = 0; matrix_b[0][3] = 0;
    matrix_b[1][0] = 7; matrix_b[1][1] = 8; matrix_b[1][2] = 0; matrix_b[1][3] = 0;
    matrix_b[2][0] = 0; matrix_b[2][1] = 0; matrix_b[2][2] = 2; matrix_b[2][3] = 0;
    matrix_b[3][0] = 0; matrix_b[3][1] = 0; matrix_b[3][2] = 0; matrix_b[3][3] = 3;
    
    flatten_matrices();
    run_detailed_test("SIMPLE MATRIX");
    
    $display("\n¿ DETAILED ANALYSIS COMPLETE!");
    $finish;
end

endmodule
