// ==========================================
// Debug Result Accumulator Position Calculation
// Check if position mapping is correct
// ==========================================

`timescale 1ns/1ps

module debug_result_accumulator_position;

    // Test the position calculation logic from Result Accumulator
    
    // Parameters (same as your system)
    localparam BLOCK_SIZE = 64;
    localparam MATRIX_SIZE = 128;
    
    // Test inputs
    reg [1:0] row_block_idx, col_block_idx;
    reg [5:0] local_row, local_col;
    
    // Position calculation (from your result_accumulator.v)
    wire [6:0] result_row = row_block_idx * BLOCK_SIZE + local_row;
    wire [6:0] result_col = col_block_idx * BLOCK_SIZE + local_col;
    
    // Bit index calculation  
    wire [16:0] bit_index = (result_row * MATRIX_SIZE + result_col) * 16;
    
    initial begin
        $display("=== Result Accumulator Position Debug ===");
        $display("BLOCK_SIZE = %0d", BLOCK_SIZE);
        $display("MATRIX_SIZE = %0d", MATRIX_SIZE);
        
        $display("\n=== Testing Block Position Mapping ===");
        
        // Test Block [0,0] positions
        $display("\n--- Block [0,0] positions ---");
        row_block_idx = 0; col_block_idx = 0;
        
        local_row = 0; local_col = 0;
        #1;
        $display("Block[0,0] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        local_row = 0; local_col = 16;
        #1;
        $display("Block[0,0] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        local_row = 0; local_col = 63;
        #1;
        $display("Block[0,0] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        // Test Block [0,1] positions  
        $display("\n--- Block [0,1] positions ---");
        row_block_idx = 0; col_block_idx = 1;
        
        local_row = 0; local_col = 0;
        #1;
        $display("Block[0,1] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        local_row = 0; local_col = 63;
        #1;
        $display("Block[0,1] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        // Test Block [1,0] positions
        $display("\n--- Block [1,0] positions ---");
        row_block_idx = 1; col_block_idx = 0;
        
        local_row = 0; local_col = 0;
        #1;
        $display("Block[1,0] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        local_row = 63; local_col = 0;
        #1;
        $display("Block[1,0] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        // Test Block [1,1] positions
        $display("\n--- Block [1,1] positions ---");
        row_block_idx = 1; col_block_idx = 1;
        
        local_row = 0; local_col = 0;
        #1;
        $display("Block[1,1] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        local_row = 63; local_col = 63;
        #1;
        $display("Block[1,1] local[%0d,%0d] ¿ global[%0d,%0d] bit_index=%0d", 
                local_row, local_col, result_row, result_col, bit_index);
        
        // Check for overlaps - test specific problem positions
        $display("\n=== Checking Problem Positions ===");
        
        // Position [0][16] - shows value 0002
        $display("\nPosition [0][16] should only be written by Block[0,0]:");
        check_position_coverage(0, 16);
        
        // Position [0][127] - shows value 0004  
        $display("\nPosition [0][127] should only be written by Block[0,1]:");
        check_position_coverage(0, 127);
        
        // Position [127][127] - shows value 0007
        $display("\nPosition [127][127] should only be written by Block[1,1]:");
        check_position_coverage(127, 127);
        
        $display("\n=== Analysis ===");
        $display("If any position is covered by multiple blocks, that's the bug!");
        $display("Each position should belong to exactly ONE block.");
        
        $finish;
    end
    
    // Check which block(s) can write to a specific position
    task check_position_coverage;
        input [6:0] target_row, target_col;
        integer block_count;
        integer br, bc;
        begin
            block_count = 0;
            $display("  Target position: [%0d][%0d]", target_row, target_col);
            
            for (br = 0; br < 2; br = br + 1) begin
                for (bc = 0; bc < 2; bc = bc + 1) begin
                    // Check if this block covers the target position
                    if (target_row >= br * BLOCK_SIZE && target_row < (br + 1) * BLOCK_SIZE &&
                        target_col >= bc * BLOCK_SIZE && target_col < (bc + 1) * BLOCK_SIZE) begin
                        
                        block_count = block_count + 1;
                        $display("    ¿ Covered by Block[%0d,%0d] (rows %0d-%0d, cols %0d-%0d)", 
                               br, bc, 
                               br * BLOCK_SIZE, (br + 1) * BLOCK_SIZE - 1,
                               bc * BLOCK_SIZE, (bc + 1) * BLOCK_SIZE - 1);
                               
                        // Show local coordinates within this block
                        $display("      Local coordinates: [%0d,%0d]", 
                               target_row - br * BLOCK_SIZE, 
                               target_col - bc * BLOCK_SIZE);
                    end
                end
            end
            
            if (block_count == 1) begin
                $display("    ¿ CORRECT: Position belongs to exactly 1 block");
            end else begin
                $display("    ¿ ERROR: Position belongs to %0d blocks!", block_count);
            end
        end
    endtask

endmodule
