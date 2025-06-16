// =========================================== 
// Result Accumulator Testbench
// Verifies accumulation of 8 partial 64x64 results into 128x128 matrix
// ===========================================

`timescale 1ns/1ps

module tb_result_accumulator;

// =========================================== 
// Clock and Reset Generation
// ===========================================
reg clk;
reg rst_n;

initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

initial begin
    rst_n = 0;
    #20 rst_n = 1;
end

// =========================================== 
// Parameters
// ===========================================
localparam MATRIX_SIZE = 128;
localparam BLOCK_SIZE = 64;
localparam DATA_WIDTH = 16;
localparam ACCUM_WIDTH = 24;

// =========================================== 
// DUT Interface Signals
// ===========================================
reg start_new_computation;
reg accumulate_result;
reg [1:0] c_row_idx, c_col_idx;

reg [DATA_WIDTH-1:0] partial_result [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
wire [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] partial_result_flat;

wire [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] final_result_flat;
wire [DATA_WIDTH-1:0] final_result [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

wire accumulation_done;

// =========================================== 
// Flatten/Unflatten for Testbench
// ===========================================
genvar fi, fj;
generate
    // Flatten partial result for DUT input
    for (fi = 0; fi < BLOCK_SIZE; fi = fi + 1) begin: TB_FLATTEN_PARTIAL_ROW
        for (fj = 0; fj < BLOCK_SIZE; fj = fj + 1) begin: TB_FLATTEN_PARTIAL_COL
            assign partial_result_flat[(fi*BLOCK_SIZE + fj + 1)*DATA_WIDTH - 1 : (fi*BLOCK_SIZE + fj)*DATA_WIDTH] = partial_result[fi][fj];
        end
    end
    
    // Unflatten final result from DUT output
    for (fi = 0; fi < MATRIX_SIZE; fi = fi + 1) begin: TB_UNFLATTEN_RESULT_ROW
        for (fj = 0; fj < MATRIX_SIZE; fj = fj + 1) begin: TB_UNFLATTEN_RESULT_COL
            assign final_result[fi][fj] = final_result_flat[(fi*MATRIX_SIZE + fj + 1)*DATA_WIDTH - 1 : (fi*MATRIX_SIZE + fj)*DATA_WIDTH];
        end
    end
endgenerate

// =========================================== 
// DUT Instantiation
// ===========================================
result_accumulator #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start_new_computation(start_new_computation),
    .accumulate_result(accumulate_result),
    .c_row_idx(c_row_idx),
    .c_col_idx(c_col_idx),
    .partial_result_flat(partial_result_flat),
    .final_result_flat(final_result_flat),
    .accumulation_done(accumulation_done)
);

// =========================================== 
// Test Control Variables
// ===========================================
integer error_count;
integer computation_step;

// Test sequence arrays (matching block_manager sequence)
reg [1:0] test_c_row [0:7];
reg [1:0] test_c_col [0:7];

// Initialize test sequences
initial begin
    test_c_row[0] = 0; test_c_row[1] = 0; test_c_row[2] = 0; test_c_row[3] = 0;
    test_c_row[4] = 1; test_c_row[5] = 1; test_c_row[6] = 1; test_c_row[7] = 1;
    
    test_c_col[0] = 0; test_c_col[1] = 0; test_c_col[2] = 1; test_c_col[3] = 1;
    test_c_col[4] = 0; test_c_col[5] = 0; test_c_col[6] = 1; test_c_col[7] = 1;
end

// =========================================== 
// Main Test Sequence
// ===========================================
initial begin
    // Initialize signals
    start_new_computation = 0;
    accumulate_result = 0;
    c_row_idx = 0;
    c_col_idx = 0;
    error_count = 0;
    
    // Wait for reset deassertion
    wait (rst_n);
    @(posedge clk);
    
    $display("=== Result Accumulator Testbench Started ===");
    
    // Start new computation
    @(posedge clk);
    start_new_computation = 1;
    
    @(posedge clk);
    start_new_computation = 0;
    
    // Process all 8 accumulation steps
    for (computation_step = 0; computation_step < 8; computation_step = computation_step + 1) begin
        // Set indices
        c_row_idx = test_c_row[computation_step];
        c_col_idx = test_c_col[computation_step];
        
        // Generate test data
        for (integer i = 0; i < BLOCK_SIZE; i = i + 1) begin
            for (integer j = 0; j < BLOCK_SIZE; j = j + 1) begin
                partial_result[i][j] = i + j + computation_step * 100 + 1;
            end
        end
        
        $display("Step %0d: Accumulating to block [%0d,%0d], data base = %0d", 
                 computation_step, c_row_idx, c_col_idx, computation_step * 100 + 1);
        
        // Accumulate
        @(posedge clk);
        accumulate_result = 1;
        
        @(posedge clk);
        accumulate_result = 0;
        
        // Check sample value
        @(posedge clk);
        $display("  Sample: final[%0d][%0d] = %0d", 
                 c_row_idx * BLOCK_SIZE, c_col_idx * BLOCK_SIZE,
                 final_result[c_row_idx * BLOCK_SIZE][c_col_idx * BLOCK_SIZE]);
    end
    
    // Check final results
    $display("\nFinal verification:");
    $display("C[0,0]: final[0][0] = %0d (expected: 102)", final_result[0][0]);
    $display("C[0,1]: final[0][64] = %0d (expected: 502)", final_result[0][64]);  
    $display("C[1,0]: final[64][0] = %0d (expected: 902)", final_result[64][0]);
    $display("C[1,1]: final[64][64] = %0d (expected: 1302)", final_result[64][64]);
    
    $display("=== Testbench Complete ===");
    $finish;
end

endmodule
