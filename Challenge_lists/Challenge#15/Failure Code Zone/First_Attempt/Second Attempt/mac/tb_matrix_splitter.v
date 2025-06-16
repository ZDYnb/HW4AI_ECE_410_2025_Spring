// =========================================== 
// Matrix Splitter Testbench
// Verifies 64x64 block extraction from 128x128 matrix
// ===========================================

`timescale 1ns/1ps

module tb_matrix_splitter;

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

// =========================================== 
// DUT Interface Signals
// ===========================================
reg valid_in;
wire valid_out;

reg [DATA_WIDTH-1:0] large_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
wire [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] large_matrix_flat;
reg [1:0] row_block_idx, col_block_idx;
wire [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] block_matrix_flat;
wire [DATA_WIDTH-1:0] block_matrix [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];

// =========================================== 
// Flatten/Unflatten for Testbench
// ===========================================
genvar fi, fj;
generate
    // Flatten input matrix
    for (fi = 0; fi < MATRIX_SIZE; fi = fi + 1) begin: TB_FLATTEN_ROW
        for (fj = 0; fj < MATRIX_SIZE; fj = fj + 1) begin: TB_FLATTEN_COL
            assign large_matrix_flat[(fi*MATRIX_SIZE + fj + 1)*DATA_WIDTH - 1 : (fi*MATRIX_SIZE + fj)*DATA_WIDTH] = large_matrix[fi][fj];
        end
    end
    
    // Unflatten output matrix
    for (fi = 0; fi < BLOCK_SIZE; fi = fi + 1) begin: TB_UNFLATTEN_ROW
        for (fj = 0; fj < BLOCK_SIZE; fj = fj + 1) begin: TB_UNFLATTEN_COL
            assign block_matrix[fi][fj] = block_matrix_flat[(fi*BLOCK_SIZE + fj + 1)*DATA_WIDTH - 1 : (fi*BLOCK_SIZE + fj)*DATA_WIDTH];
        end
    end
endgenerate

// =========================================== 
// DUT Instantiation
// ===========================================
matrix_splitter #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .valid_out(valid_out),
    .large_matrix_flat(large_matrix_flat),
    .row_block_idx(row_block_idx),
    .col_block_idx(col_block_idx),
    .block_matrix_flat(block_matrix_flat)
);

// =========================================== 
// Test Control Variables
// ===========================================
integer error_count;
integer test_block;

// =========================================== 
// Main Test Sequence
// ===========================================
initial begin
    // Initialize signals
    valid_in = 0;
    row_block_idx = 0;
    col_block_idx = 0;
    error_count = 0;
    
    // Wait for reset deassertion
    wait (rst_n);
    @(posedge clk);
    
    $display("=== Matrix Splitter Testbench Started ===");
    $display("Testing 64x64 block extraction from 128x128 matrix");
    
    // Initialize test matrix
    initialize_test_matrix();
    
    // Test all 4 blocks (2x2)
    for (test_block = 0; test_block < 4; test_block = test_block + 1) begin
        test_block_extraction(test_block);
    end
    
    // Final report
    @(posedge clk);
    $display("\n=== Test Summary ===");
    if (error_count == 0) begin
        $display("¿ All tests PASSED!");
        $display("Successfully extracted all 4 blocks from 128x128 matrix");
    end else begin
        $display("¿ %0d errors found", error_count);
    end
    
    $display("=== Matrix Splitter Testbench Complete ===");
    $finish;
end

// =========================================== 
// Initialize Test Matrix with Known Pattern
// ===========================================
task initialize_test_matrix;
    integer row, col;
    begin
        $display("\n--- Initializing Test Matrix ---");
        
        for (row = 0; row < MATRIX_SIZE; row = row + 1) begin
            for (col = 0; col < MATRIX_SIZE; col = col + 1) begin
                // Create a unique pattern: value = row*256 + col
                // This makes each element easily identifiable
                large_matrix[row][col] = row * 256 + col;
            end
        end
        
        $display("Initialized 128x128 matrix with pattern: matrix[r][c] = r*256 + c");
        
        // Display a few sample values for verification
        $display("Sample values:");
        $display("  matrix[0][0] = %0d (expected: 0)", large_matrix[0][0]);
        $display("  matrix[0][63] = %0d (expected: 63)", large_matrix[0][63]);
        $display("  matrix[63][0] = %0d (expected: 16128)", large_matrix[63][0]);
        $display("  matrix[127][127] = %0d (expected: 32639)", large_matrix[127][127]);
    end
endtask

// =========================================== 
// Test Block Extraction
// ===========================================
task test_block_extraction;
    input integer block_num;
    integer expected_errors;
    begin
        $display("\n--- Testing Block %0d Extraction ---", block_num);
        
        // Set block indices based on block number
        case (block_num)
            0: begin row_block_idx = 0; col_block_idx = 0; end  // Top-left
            1: begin row_block_idx = 0; col_block_idx = 1; end  // Top-right
            2: begin row_block_idx = 1; col_block_idx = 0; end  // Bottom-left
            3: begin row_block_idx = 1; col_block_idx = 1; end  // Bottom-right
        endcase
        
        $display("Extracting block [%0d,%0d] (%s)", 
                 row_block_idx, col_block_idx, get_block_name(block_num));
        
        // Apply valid signal
        @(posedge clk);
        valid_in = 1;
        
        @(posedge clk);
        valid_in = 0;
        
        // Wait for valid_out
        wait (valid_out);
        @(posedge clk);
        
        // Verify the extracted block
        expected_errors = error_count;
        verify_extracted_block(block_num);
        
        if (error_count == expected_errors) begin
            $display("¿ Block %0d extraction PASSED", block_num);
        end else begin
            $display("¿ Block %0d extraction FAILED with %0d errors", 
                     block_num, error_count - expected_errors);
        end
    end
endtask

// =========================================== 
// Verify Extracted Block Contents
// ===========================================
task verify_extracted_block;
    input integer block_num;
    integer i, j;
    integer expected_value, actual_value;
    integer base_row, base_col;
    integer sample_errors;
    begin
        $display("  Verifying block contents...");
        
        // Calculate base indices for this block
        base_row = row_block_idx * BLOCK_SIZE;
        base_col = col_block_idx * BLOCK_SIZE;
        
        sample_errors = 0;
        
        // Check all elements in the block
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                expected_value = (base_row + i) * 256 + (base_col + j);
                actual_value = block_matrix[i][j];
                
                if (actual_value !== expected_value) begin
                    if (sample_errors < 5) begin  // Limit error messages
                        $display("    ¿ ERROR at block[%0d][%0d]: got %0d, expected %0d",
                                 i, j, actual_value, expected_value);
                    end
                    sample_errors = sample_errors + 1;
                    error_count = error_count + 1;
                end
            end
        end
        
        if (sample_errors == 0) begin
            $display("    ¿ All %0d elements correct", BLOCK_SIZE * BLOCK_SIZE);
        end else begin
            $display("    ¿ %0d element errors found", sample_errors);
            if (sample_errors > 5) begin
                $display("    (showing first 5 errors only)");
            end
        end
        
        // Display corner values for verification
        $display("  Corner values verification:");
        $display("    block[0][0] = %0d (expected: %0d)", 
                 block_matrix[0][0], base_row * 256 + base_col);
        $display("    block[0][63] = %0d (expected: %0d)", 
                 block_matrix[0][63], base_row * 256 + base_col + 63);
        $display("    block[63][0] = %0d (expected: %0d)", 
                 block_matrix[63][0], (base_row + 63) * 256 + base_col);
        $display("    block[63][63] = %0d (expected: %0d)", 
                 block_matrix[63][63], (base_row + 63) * 256 + base_col + 63);
    end
endtask

// =========================================== 
// Helper Function: Get Block Name
// ===========================================
function string get_block_name;
    input integer block_num;
    begin
        case (block_num)
            0: get_block_name = "Top-left";
            1: get_block_name = "Top-right";
            2: get_block_name = "Bottom-left";
            3: get_block_name = "Bottom-right";
            default: get_block_name = "Unknown";
        endcase
    end
endfunction

// =========================================== 
// Continuous Monitoring
// ===========================================
always @(posedge clk) begin
    if (valid_out) begin
        // Monitor when valid output is produced
    end
end

// =========================================== 
// Timeout Protection
// ===========================================
initial begin
    #50000;  // 50¿s timeout
    $display("¿ ERROR: Testbench timeout!");
    $finish;
end

endmodule
