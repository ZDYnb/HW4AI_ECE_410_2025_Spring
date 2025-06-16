// ===========================================
// Matrix Splitter Debug Test
// Check if blocks are correctly extracted without overlap
// ===========================================

`timescale 1ns/1ps

module test_matrix_splitter_debug;

parameter MATRIX_SIZE = 128;
parameter BLOCK_SIZE = 64;
parameter DATA_WIDTH = 16;

reg clk, rst_n;
reg [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] test_matrix_flat;
reg [DATA_WIDTH-1:0] test_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

// Test all 4 blocks
wire [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] block_00_flat, block_01_flat, block_10_flat, block_11_flat;
wire [DATA_WIDTH-1:0] block_00 [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
wire [DATA_WIDTH-1:0] block_01 [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
wire [DATA_WIDTH-1:0] block_10 [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
wire [DATA_WIDTH-1:0] block_11 [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];

always #5 clk = ~clk;

// Flatten test matrix
task flatten_test_matrix;
    integer i, j, idx;
    begin
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                idx = i * MATRIX_SIZE + j;
                test_matrix_flat[idx*16 +: 16] = test_matrix[i][j];
            end
        end
    end
endtask

// Matrix Splitters for all 4 blocks
matrix_splitter #(.MATRIX_SIZE(MATRIX_SIZE), .BLOCK_SIZE(BLOCK_SIZE), .DATA_WIDTH(DATA_WIDTH))
splitter_00 (.clk(clk), .rst_n(rst_n), .valid_in(1'b1), .valid_out(),
             .large_matrix_flat(test_matrix_flat), .row_block_idx(2'b00), .col_block_idx(2'b00), .block_matrix_flat(block_00_flat));

matrix_splitter #(.MATRIX_SIZE(MATRIX_SIZE), .BLOCK_SIZE(BLOCK_SIZE), .DATA_WIDTH(DATA_WIDTH))
splitter_01 (.clk(clk), .rst_n(rst_n), .valid_in(1'b1), .valid_out(),
             .large_matrix_flat(test_matrix_flat), .row_block_idx(2'b00), .col_block_idx(2'b01), .block_matrix_flat(block_01_flat));

matrix_splitter #(.MATRIX_SIZE(MATRIX_SIZE), .BLOCK_SIZE(BLOCK_SIZE), .DATA_WIDTH(DATA_WIDTH))
splitter_10 (.clk(clk), .rst_n(rst_n), .valid_in(1'b1), .valid_out(),
             .large_matrix_flat(test_matrix_flat), .row_block_idx(2'b01), .col_block_idx(2'b00), .block_matrix_flat(block_10_flat));

matrix_splitter #(.MATRIX_SIZE(MATRIX_SIZE), .BLOCK_SIZE(BLOCK_SIZE), .DATA_WIDTH(DATA_WIDTH))
splitter_11 (.clk(clk), .rst_n(rst_n), .valid_in(1'b1), .valid_out(),
             .large_matrix_flat(test_matrix_flat), .row_block_idx(2'b01), .col_block_idx(2'b01), .block_matrix_flat(block_11_flat));

// Unflatten blocks
genvar gi, gj;
generate
    for (gi = 0; gi < BLOCK_SIZE; gi = gi + 1) begin: UNFLATTEN_ROW
        for (gj = 0; gj < BLOCK_SIZE; gj = gj + 1) begin: UNFLATTEN_COL
            assign block_00[gi][gj] = block_00_flat[(gi*BLOCK_SIZE+gj)*16 +: 16];
            assign block_01[gi][gj] = block_01_flat[(gi*BLOCK_SIZE+gj)*16 +: 16];
            assign block_10[gi][gj] = block_10_flat[(gi*BLOCK_SIZE+gj)*16 +: 16];
            assign block_11[gi][gj] = block_11_flat[(gi*BLOCK_SIZE+gj)*16 +: 16];
        end
    end
endgenerate

// Declare all variables at module level
integer i, j, errors;

initial begin
    $display("=== Matrix Splitter Debug Test ===");
    
    clk = 0;
    rst_n = 0;
    
    // Create a unique pattern matrix where each element = row*256 + col (¿?¿?16¿?¿?¿?)
    for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
        for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
            test_matrix[i][j] = i * 16'd256 + j;  // ¿?¿?256¿?¿?¿?1000¿?¿?¿?¿?
        end
    end
    
    flatten_test_matrix();
    
    #20 rst_n = 1;
    #50;
    
    $display("\n=== Original Matrix Sample ===");
    $display("test_matrix[0][0] = %0d", test_matrix[0][0]);
    $display("test_matrix[0][63] = %0d", test_matrix[0][63]);
    $display("test_matrix[0][64] = %0d", test_matrix[0][64]);
    $display("test_matrix[0][127] = %0d", test_matrix[0][127]);
    $display("test_matrix[63][0] = %0d", test_matrix[63][0]);
    $display("test_matrix[63][63] = %0d", test_matrix[63][63]);
    $display("test_matrix[64][0] = %0d", test_matrix[64][0]);
    $display("test_matrix[64][64] = %0d", test_matrix[64][64]);
    $display("test_matrix[127][127] = %0d", test_matrix[127][127]);
    
    $display("\n=== Block [0,0] (Top-Left) ===");
    $display("block_00[0][0] = %0d (should be 0)", block_00[0][0]);
    $display("block_00[0][63] = %0d (should be 63)", block_00[0][63]);
    $display("block_00[63][0] = %0d (should be %0d)", block_00[63][0], 63*256);
    $display("block_00[63][63] = %0d (should be %0d)", block_00[63][63], 63*256+63);
    
    $display("\n=== Block [0,1] (Top-Right) ===");
    $display("block_01[0][0] = %0d (should be 64)", block_01[0][0]);
    $display("block_01[0][63] = %0d (should be 127)", block_01[0][63]);
    $display("block_01[63][0] = %0d (should be %0d)", block_01[63][0], 63*256+64);
    $display("block_01[63][63] = %0d (should be %0d)", block_01[63][63], 63*256+127);
    
    $display("\n=== Block [1,0] (Bottom-Left) ===");
    $display("block_10[0][0] = %0d (should be %0d)", block_10[0][0], 64*256);
    $display("block_10[0][63] = %0d (should be %0d)", block_10[0][63], 64*256+63);
    $display("block_10[63][0] = %0d (should be %0d)", block_10[63][0], 127*256);
    $display("block_10[63][63] = %0d (should be %0d)", block_10[63][63], 127*256+63);
    
    $display("\n=== Block [1,1] (Bottom-Right) ===");
    $display("block_11[0][0] = %0d (should be %0d)", block_11[0][0], 64*256+64);
    $display("block_11[0][63] = %0d (should be %0d)", block_11[0][63], 64*256+127);
    $display("block_11[63][0] = %0d (should be %0d)", block_11[63][0], 127*256+64);
    $display("block_11[63][63] = %0d (should be %0d)", block_11[63][63], 127*256+127);
    
    // Check for overlaps
    $display("\n=== Checking for Overlaps ===");
    errors = 0;
    
    // Check boundary between blocks [0,0] and [0,1]
    if (block_00[0][63] == block_01[0][0]) begin
        $display("ERROR: Overlap between block [0,0] and [0,1]!");
        errors = errors + 1;
    end
    
    // Check boundary between blocks [0,0] and [1,0]
    if (block_00[63][0] == block_10[0][0]) begin
        $display("ERROR: Overlap between block [0,0] and [1,0]!");
        errors = errors + 1;
    end
    
    // Verify correct extraction
    if (block_00[0][0] != test_matrix[0][0]) begin
        $display("ERROR: block_00[0][0] incorrect extraction!");
        errors = errors + 1;
    end
    
    if (block_01[0][0] != test_matrix[0][64]) begin
        $display("ERROR: block_01[0][0] incorrect extraction!");
        errors = errors + 1;
    end
    
    if (block_10[0][0] != test_matrix[64][0]) begin
        $display("ERROR: block_10[0][0] incorrect extraction!");
        errors = errors + 1;
    end
    
    if (block_11[0][0] != test_matrix[64][64]) begin
        $display("ERROR: block_11[0][0] incorrect extraction!");
        errors = errors + 1;
    end
    
    if (errors == 0) begin
        $display("¿ Matrix Splitter Test PASSED - No overlaps detected");
    end else begin
        $display("¿ Matrix Splitter Test FAILED - %0d errors detected", errors);
    end
    
    $finish;
end

endmodule
