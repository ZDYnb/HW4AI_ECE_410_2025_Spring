// ==========================================
// Result Accumulator with Debug Information
// Add detailed logging to find the exact bug
// ==========================================

`timescale 1ns/1ps

module result_accumulator #(
    parameter DATA_WIDTH = 16,
    parameter BLOCK_SIZE = 64,
    parameter MATRIX_SIZE = 128,
    parameter RESULT_WIDTH = 32
)(
    input                               clk,
    input                               rst_n,
    input                               accumulate_result,
    input  [1:0]                        row_block_idx,
    input  [1:0]                        col_block_idx,
    input  [RESULT_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] block_result_flat,
    output [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] final_result_flat
);

    // Internal result storage
    reg [DATA_WIDTH-1:0] result_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    
    // Debug variables
    integer debug_accumulation_count;
    integer i, j;
    
    // Edge detection for accumulate_result
    reg accumulate_result_prev;
    wire accumulate_pulse = accumulate_result && !accumulate_result_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulate_result_prev <= 1'b0;
        end else begin
            accumulate_result_prev <= accumulate_result;
        end
    end
    
    // Accumulation process with detailed debug
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize result matrix
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    result_matrix[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
            debug_accumulation_count <= 0;
        end else if (accumulate_pulse) begin
            debug_accumulation_count <= debug_accumulation_count + 1;
            
            $display("RESULT ACCUMULATOR DEBUG - Accumulation #%0d", debug_accumulation_count);
            $display("Time: %0dns", $time);
            $display("Block indices: row_block_idx=%0d, col_block_idx=%0d", row_block_idx, col_block_idx);
            $display("Target block: C[%0d,%0d]", row_block_idx, col_block_idx);
            
            // Calculate base position for this block
            $display("Base position: [%0d,%0d]", row_block_idx * BLOCK_SIZE, col_block_idx * BLOCK_SIZE);
            
            // Process block result (sample first few positions for debug)
            for (i = 0; i < 4; i = i + 1) begin  // Only first 4 rows for debug
                for (j = 0; j < 8; j = j + 1) begin  // Only first 8 cols for debug
                    // Calculate global position
                    if (row_block_idx * BLOCK_SIZE + i < MATRIX_SIZE && 
                        col_block_idx * BLOCK_SIZE + j < MATRIX_SIZE) begin
                        
                        // Extract result for this position
                        result_matrix[row_block_idx * BLOCK_SIZE + i][col_block_idx * BLOCK_SIZE + j] <= 
                            result_matrix[row_block_idx * BLOCK_SIZE + i][col_block_idx * BLOCK_SIZE + j] + 
                            block_result_flat[(i * BLOCK_SIZE + j) * RESULT_WIDTH +: DATA_WIDTH];
                            
                        // Debug output
                        if (block_result_flat[(i * BLOCK_SIZE + j) * RESULT_WIDTH +: DATA_WIDTH] != 16'h0000) begin
                            $display("  Writing [%0d][%0d]: value=%04h", 
                                    row_block_idx * BLOCK_SIZE + i, 
                                    col_block_idx * BLOCK_SIZE + j,
                                    block_result_flat[(i * BLOCK_SIZE + j) * RESULT_WIDTH +: DATA_WIDTH]);
                        end
                    end
                end
            end
            
            // Process all other positions (without debug output)
            for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                    if ((i >= 4 || j >= 8) &&  // Skip positions already processed above
                        row_block_idx * BLOCK_SIZE + i < MATRIX_SIZE && 
                        col_block_idx * BLOCK_SIZE + j < MATRIX_SIZE) begin
                        
                        result_matrix[row_block_idx * BLOCK_SIZE + i][col_block_idx * BLOCK_SIZE + j] <= 
                            result_matrix[row_block_idx * BLOCK_SIZE + i][col_block_idx * BLOCK_SIZE + j] + 
                            block_result_flat[(i * BLOCK_SIZE + j) * RESULT_WIDTH +: DATA_WIDTH];
                    end
                end
            end
            
            // Show sample of results after accumulation
            $display("Sample results after accumulation:");
            $display("  result[0][0]   = %04h", result_matrix[0][0]);
            $display("  result[0][16]  = %04h", result_matrix[0][16]);
            $display("  result[0][127] = %04h", result_matrix[0][127]);
            $display("  result[127][127] = %04h", result_matrix[127][127]);
        end
    end
    
    // Flatten output result
    generate
        genvar out_i, out_j;
        for (out_i = 0; out_i < MATRIX_SIZE; out_i = out_i + 1) begin: OUTPUT_ROW
            for (out_j = 0; out_j < MATRIX_SIZE; out_j = out_j + 1) begin: OUTPUT_COL
                assign final_result_flat[(out_i*MATRIX_SIZE + out_j)*DATA_WIDTH +: DATA_WIDTH] = result_matrix[out_i][out_j];
            end
        end
    endgenerate
    
    // Debug: Monitor specific positions for changes  
    reg [DATA_WIDTH-1:0] prev_0_16;
    reg [DATA_WIDTH-1:0] prev_0_127;
    reg [DATA_WIDTH-1:0] prev_127_127;
    
    always @(posedge clk) begin
        if (rst_n) begin
            if (result_matrix[0][16] != prev_0_16) begin
                $display("CHANGE: result[0][16] changed from %04h to %04h at time %0dns",
                        prev_0_16, result_matrix[0][16], $time);
                prev_0_16 <= result_matrix[0][16];
            end
            
            if (result_matrix[0][127] != prev_0_127) begin
                $display("CHANGE: result[0][127] changed from %04h to %04h at time %0dns",
                        prev_0_127, result_matrix[0][127], $time);
                prev_0_127 <= result_matrix[0][127];
            end
            
            if (result_matrix[127][127] != prev_127_127) begin
                $display("CHANGE: result[127][127] changed from %04h to %04h at time %0dns",
                        prev_127_127, result_matrix[127][127], $time);
                prev_127_127 <= result_matrix[127][127];
            end
        end else begin
            prev_0_16 <= 16'h0000;
            prev_0_127 <= 16'h0000;
            prev_127_127 <= 16'h0000;
        end
    end

endmodule
