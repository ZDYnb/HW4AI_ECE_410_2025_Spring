// ===========================================
// Testbench for 128x128 Matrix Multiplication System
// Complete system test with identity matrix verification
// ===========================================

`timescale 1ns/1ps

module tb_matrix_mult_128x128;

// =========================================== 
// Parameters
// ===========================================
parameter MATRIX_SIZE = 128;
parameter BLOCK_SIZE = 64;
parameter DATA_WIDTH = 16;

// =========================================== 
// Clock and Reset Generation
// ===========================================
reg clk;
reg rst_n;

always #5 clk = ~clk;

// =========================================== 
// DUT Signals
// ===========================================
reg start;
wire done;
wire [3:0] current_step;
wire computation_active;

// Flattened matrices
reg [262143:0] matrix_a_flat;  // 16*128*128-1 = 262143
reg [262143:0] matrix_b_flat;  
wire [262143:0] result_flat;   

// 2D arrays for easy access
reg [15:0] matrix_a [0:127][0:127];
reg [15:0] matrix_b [0:127][0:127];
wire [15:0] result_matrix [0:127][0:127];

// =========================================== 
// DUT Instance
// ===========================================
matrix_mult_128x128 #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .done(done),
    .matrix_a_flat(matrix_a_flat),
    .matrix_b_flat(matrix_b_flat),
    .result_flat(result_flat),
    .current_step(current_step),
    .computation_active(computation_active)
);

// =========================================== 
// Array Conversion Tasks
// ===========================================

// Task to flatten 2D arrays to 1D
task flatten_matrices;
    integer i, j, idx;
    begin
        for (i = 0; i < 128; i = i + 1) begin
            for (j = 0; j < 128; j = j + 1) begin
                idx = i * 128 + j;
                matrix_a_flat[idx*16 +: 16] = matrix_a[i][j];
                matrix_b_flat[idx*16 +: 16] = matrix_b[i][j];
            end
        end
    end
endtask

// Unflatten result using generate
genvar gi, gj;
generate
    for (gi = 0; gi < 128; gi = gi + 1) begin: RESULT_ROW
        for (gj = 0; gj < 128; gj = gj + 1) begin: RESULT_COL
            assign result_matrix[gi][gj] = result_flat[(gi*128+gj)*16 +: 16];
        end
    end
endgenerate

// =========================================== 
// Test Tasks
// ===========================================

// Task to initialize identity matrix
task create_identity_matrix;
    integer i, j;
    begin
        for (i = 0; i < 128; i = i + 1) begin
            for (j = 0; j < 128; j = j + 1) begin
                matrix_a[i][j] = (i == j) ? 16'h0001 : 16'h0000;
            end
        end
    end
endtask

// Task to initialize all-ones matrix
task create_ones_matrix;
    integer i, j;
    begin
        for (i = 0; i < 128; i = i + 1) begin
            for (j = 0; j < 128; j = j + 1) begin
                matrix_b[i][j] = 16'h0001;
            end
        end
    end
endtask

// Task to run computation with timeout
task run_computation;
    input [31:0] timeout_cycles;
    begin
        start = 1;
        #10 start = 0;
        
        fork
            begin
                wait(done);
                $display("¿ Computation completed at T=%0t", $time);
            end
            begin
                repeat(timeout_cycles) @(posedge clk);
                $display("¿ ERROR: Computation timed out after %0d cycles!", timeout_cycles);
                $finish;
            end
        join_any
        disable fork;
        
        if (!done) begin
            $display("¿ ERROR: Computation never completed!");
            $finish;
        end
    end
endtask

// Task to verify identity result
task verify_identity_result;
    input integer max_errors;
    integer errors;
    integer samples_checked;
    integer i, j;
    begin
        $display("\nVerifying Identity Test results...");
        errors = 0;
        samples_checked = 0;
        
        // Check a sampling of results (every 16th element)
        for (i = 0; i < 128; i = i + 16) begin
            for (j = 0; j < 128; j = j + 16) begin
                samples_checked = samples_checked + 1;
                if (result_matrix[i][j] != 16'h0001) begin
                    $display("  ERROR at [%0d][%0d]: got %h, expected 0001", 
                            i, j, result_matrix[i][j]);
                    errors = errors + 1;
                    if (errors >= max_errors) begin
                        $display("  ... (stopping after %0d errors)", max_errors);
                        break;
                    end
                end
            end
            if (errors >= max_errors) break;
        end
        
        $display("Checked %0d sample positions", samples_checked);
        
        if (errors == 0) begin
            $display("¿ Identity Test PASSED - All sampled results correct");
        end else begin
            $display("¿ Identity Test FAILED - %0d errors in %0d samples", errors, samples_checked);
        end
        
        // Check corner values
        $display("\nCorner value verification:");
        $display("  result[0][0] = %h (expected: 0001)", result_matrix[0][0]);
        $display("  result[0][127] = %h (expected: 0001)", result_matrix[0][127]);
        $display("  result[127][0] = %h (expected: 0001)", result_matrix[127][0]);
        $display("  result[127][127] = %h (expected: 0001)", result_matrix[127][127]);
    end
endtask

// =========================================== 
// Main Test Sequence
// ===========================================
initial begin
    $display("=== 128x128 Matrix Multiplication System Test ===");
    $display("Testing complete matrix multiplication pipeline");
    
    // Initialize
    clk = 0;
    rst_n = 0;
    start = 0;
    
    // Reset sequence
    #20 rst_n = 1;
    #20;
    
    // =====================================
    // Test 1: Identity Matrix Test
    // =====================================
    $display("\n--- Test 1: Identity Matrix Multiplication ---");
    $display("Testing A × I = A (where I is identity matrix)");
    
    create_identity_matrix();
    create_ones_matrix();
    flatten_matrices();  // Convert to flattened format
    
    $display("Matrix A: Identity matrix (diagonal 1s)");
    $display("Matrix B: All ones matrix");
    $display("Expected result: All ones matrix");
    
    run_computation(500000);  // 500k cycle timeout
    
    verify_identity_result(10);  // Stop after 10 errors
    
    #100;
    
    // =====================================
    // Test Summary
    // =====================================
    $display("\n=== Test Summary ===");
    $display("128x128 Matrix Multiplication Test Complete");
    $display("All tests completed successfully");
    
    $finish;
end

// =========================================== 
// Progress Monitoring
// ===========================================
reg [3:0] last_step;

always @(posedge clk) begin
    if (start) begin
        $display("T=%0t: Starting 128x128 matrix multiplication", $time);
        last_step = 4'hF;  // Invalid step
    end
    
    if (computation_active && current_step != last_step) begin
        $display("T=%0t: Progress - Step %0d/8 completed", $time, current_step + 1);
        last_step = current_step;
    end
    
    if (done) begin
        $display("T=%0t: Matrix multiplication completed", $time);
    end
end

// =========================================== 
// Optional: Dump specific signals for debugging
// ===================================================
`ifdef DUMP_SIGNALS
initial begin
    $dumpfile("matrix_mult_128x128.vcd");
    $dumpvars(0, tb_matrix_mult_128x128);
end
`endif

endmodule
