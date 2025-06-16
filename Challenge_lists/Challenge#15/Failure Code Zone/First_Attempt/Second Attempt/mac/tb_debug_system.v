// =========================================== 
// Debug Testbench - Simplified System Test
// Check data flow step by step
// ===========================================

`timescale 1ns/1ps

module tb_debug_system;

// =========================================== 
// Parameters
// ===========================================
parameter MATRIX_SIZE = 128;
parameter BLOCK_SIZE = 64;
parameter DATA_WIDTH = 16;

// =========================================== 
// Clock and Reset
// ===========================================
reg clk;
reg rst_n;

always #5 clk = ~clk;

// =========================================== 
// DUT Signals
// ===========================================
reg start;
wire done;

// Flattened matrices
reg [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] matrix_a_flat;
reg [8*MATRIX_SIZE*MATRIX_SIZE-1:0] matrix_b_flat;  // 8-bit weights
wire [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] result_flat;

// 2D arrays for easy access
reg [DATA_WIDTH-1:0] matrix_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
reg [7:0] matrix_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
wire [DATA_WIDTH-1:0] result_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

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
    .result_flat(result_flat)
);

// =========================================== 
// Array Conversion Tasks
// ===========================================
task flatten_matrices;
    integer i, j;
    begin
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                matrix_a_flat[(i*MATRIX_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = matrix_a[i][j];
                matrix_b_flat[(i*MATRIX_SIZE+j)*8 +: 8] = matrix_b[i][j];
            end
        end
    end
endtask

genvar gi, gj;
generate
    for (gi = 0; gi < MATRIX_SIZE; gi = gi + 1) begin: UNFLATTEN_ROW
        for (gj = 0; gj < MATRIX_SIZE; gj = gj + 1) begin: UNFLATTEN_COL
            assign result_matrix[gi][gj] = result_flat[(gi*MATRIX_SIZE+gj)*DATA_WIDTH +: DATA_WIDTH];
        end
    end
endgenerate

// =========================================== 
// Debug Monitoring
// ===========================================

// Monitor internal signals
always @(posedge clk) begin
    if (dut.block_mgr_start_systolic) begin
        $display("T=%0t: Starting systolic computation step", $time);
        $display("  A indices: [%0d,%0d], B indices: [%0d,%0d] -> C indices: [%0d,%0d]", 
                 dut.a_row_idx, dut.a_col_idx, dut.b_row_idx, dut.b_col_idx, 
                 dut.c_row_idx, dut.c_col_idx);
    end
    
    if (dut.systolic_done) begin
        $display("T=%0t: Systolic computation completed", $time);
        // Check some sample values from systolic output
        $display("  Sample systolic results: result[0] = %0d, result[63] = %0d", 
                 dut.systolic_result_flat[15:0], dut.systolic_result_flat[63*DATA_WIDTH +: DATA_WIDTH]);
    end
    
    if (dut.block_mgr_accumulate_result) begin
        $display("T=%0t: Accumulating result to block [%0d,%0d]", $time, dut.c_row_idx, dut.c_col_idx);
    end
end

// =========================================== 
// Test Sequence
// ===========================================
initial begin
    $display("=== Debug System Test ===");
    
    // Initialize
    clk = 0;
    rst_n = 0;
    start = 0;
    
    // Create simple test matrices
    integer i, j;
    for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
        for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
            matrix_a[i][j] = (i == j) ? 16'h0001 : 16'h0000;  // Identity matrix
            matrix_b[i][j] = 8'h01;  // All ones
        end
    end
    
    flatten_matrices();
    
    // Reset
    #10 rst_n = 1;
    #10;
    
    $display("Starting computation: A (identity) x B (all 1s)");
    $display("Expected result: B matrix (all 1s)");
    
    // Start computation
    start = 1;
    #10 start = 0;
    
    // Wait for completion
    wait(done);
    $display("Computation completed at T=%0t", $time);
    
    // Check results
    $display("\nChecking results:");
    integer errors = 0;
    for (i = 0; i < 8; i = i + 1) begin  // Check first 8 rows only
        for (j = 0; j < 8; j = j + 1) begin  // Check first 8 columns only
            if (result_matrix[i][j] != 16'h0001) begin
                $display("  ERROR at [%0d][%0d]: got %h, expected 0001", i, j, result_matrix[i][j]);
                errors = errors + 1;
            end
        end
    end
    
    if (errors == 0) begin
        $display("¿ Basic test PASSED");
    end else begin
        $display("¿ Basic test FAILED: %0d errors", errors);
    end
    
    $finish;
end

endmodule
