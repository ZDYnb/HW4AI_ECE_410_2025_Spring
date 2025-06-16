// ==========================================
// Debug Block Boundaries Test
// Check if blocks have overlapping regions
// ==========================================

`timescale 1ns/1ps

module debug_block_boundaries;

    // Test specific positions to see which blocks affect them
    integer test_positions [0:7][0:1];  // [position][row/col]
    
    initial begin
        $display("=== Block Boundary Analysis ===");
        
        // Define test positions that show errors
        test_positions[0][0] = 0;   test_positions[0][1] = 16;   // result[0][16] = 0002
        test_positions[1][0] = 0;   test_positions[1][1] = 32;   // result[0][32] = 0002  
        test_positions[2][0] = 0;   test_positions[2][1] = 80;   // result[0][80] = 0004
        test_positions[3][0] = 0;   test_positions[3][1] = 127;  // result[0][127] = 0004
        test_positions[4][0] = 16;  test_positions[4][1] = 0;    // result[16][0] = 0002
        test_positions[5][0] = 127; test_positions[5][1] = 0;    // result[127][0] = 0005
        test_positions[6][0] = 127; test_positions[6][1] = 127;  // result[127][127] = 0007
        test_positions[7][0] = 0;   test_positions[7][1] = 0;    // result[0][0] = 0001 (correct)
        
        $display("\nAnalyzing which blocks contribute to each position:");
        
        analyze_block_contributions();
        
        $display("\n=== Block Size Analysis ===");
        $display("Block size: 64x64");
        $display("Matrix size: 128x128");  
        $display("Number of blocks: 2x2 = 4 total");
        $display("\nBlock boundaries:");
        $display("  Block [0,0]: rows 0-63,  cols 0-63");
        $display("  Block [0,1]: rows 0-63,  cols 64-127"); 
        $display("  Block [1,0]: rows 64-127, cols 0-63");
        $display("  Block [1,1]: rows 64-127, cols 64-127");
        
        $display("\n=== Error Pattern Analysis ===");
        $display("Positions with value 0002 (2x expected):");
        $display("  [0][16], [0][32] - These are in block [0,0] region but close to [0,1] boundary");
        $display("  [16][0] - This is in block [0,0] region but close to [1,0] boundary");
        
        $display("\nPositions with value 0004 (4x expected):");  
        $display("  [0][80], [0][96], [0][112] - These are in block [0,1] region");
        $display("  [0][127] - This is at block [0,1] boundary");
        
        $display("\nPositions with value 0005+ (5x+ expected):");
        $display("  [127][0] = 0005 - This is at block [1,0] boundary");
        $display("  [127][127] = 0007 - This is at block [1,1] boundary");
        
        $display("\n¿ HYPOTHESIS:");
        $display("The systolic array might be computing overlapping regions!");
        $display("Or the result accumulation is adding results from multiple blocks");
        $display("to positions that should only get contributions from one block.");
        
        $finish;
    end
    
    task analyze_block_contributions;
        integer pos_idx, row, col;
        integer block_row, block_col;
        integer contributing_blocks;
        begin
            for (pos_idx = 0; pos_idx < 8; pos_idx = pos_idx + 1) begin
                row = test_positions[pos_idx][0];
                col = test_positions[pos_idx][1];
                
                $display("\nPosition [%0d][%0d]:", row, col);
                
                contributing_blocks = 0;
                
                // Check which blocks this position belongs to
                for (block_row = 0; block_row < 2; block_row = block_row + 1) begin
                    for (block_col = 0; block_col < 2; block_col = block_col + 1) begin
                        // Check if position falls within this block's output region
                        if (row >= block_row * 64 && row < (block_row + 1) * 64 &&
                            col >= block_col * 64 && col < (block_col + 1) * 64) begin
                            $display("  - Belongs to Block [%0d,%0d] (rows %0d-%0d, cols %0d-%0d)", 
                                   block_row, block_col,
                                   block_row * 64, (block_row + 1) * 64 - 1,
                                   block_col * 64, (block_col + 1) * 64 - 1);
                            contributing_blocks = contributing_blocks + 1;
                        end
                    end
                end
                
                if (contributing_blocks != 1) begin
                    $display("  ¿  ERROR: Position should belong to exactly 1 block, but belongs to %0d blocks!", contributing_blocks);
                end else begin
                    $display("  ¿ Correctly belongs to 1 block");
                end
            end
        end
    endtask

endmodule
