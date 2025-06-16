// ===========================================
// Matrix Splitter - Fixed Version
// Fixed index calculation overflow issue
// ===========================================

`timescale 1ns/1ps

module matrix_splitter #(
    parameter MATRIX_SIZE = 128,
    parameter BLOCK_SIZE = 64,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input valid_in,
    output reg valid_out,
    
    input [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] large_matrix_flat,
    input [1:0] row_block_idx,
    input [1:0] col_block_idx,
    output [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] block_matrix_flat
);

    reg [DATA_WIDTH-1:0] large_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    wire [DATA_WIDTH-1:0] block_matrix [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];

    // Unflatten large matrix
    genvar ui, uj;
    generate
        for (ui = 0; ui < MATRIX_SIZE; ui = ui + 1) begin: UNFLATTEN_ROW
            for (uj = 0; uj < MATRIX_SIZE; uj = uj + 1) begin: UNFLATTEN_COL
                always @(*) begin
                    large_matrix[ui][uj] = large_matrix_flat[(ui*MATRIX_SIZE+uj+1)*DATA_WIDTH-1:(ui*MATRIX_SIZE+uj)*DATA_WIDTH];
                end
            end
        end
    endgenerate

    // Extract block with proper index calculation
    genvar bi, bj;
    generate
        for (bi = 0; bi < BLOCK_SIZE; bi = bi + 1) begin: BLOCK_ROW
            for (bj = 0; bj < BLOCK_SIZE; bj = bj + 1) begin: BLOCK_COL
                // Use wider wires to prevent overflow
                wire [8:0] src_row_calc = {1'b0, row_block_idx} * BLOCK_SIZE + bi;  // 9-bit to prevent overflow
                wire [8:0] src_col_calc = {1'b0, col_block_idx} * BLOCK_SIZE + bj;  // 9-bit to prevent overflow
                wire [7:0] src_row = src_row_calc[7:0];  // Take lower 8 bits
                wire [7:0] src_col = src_col_calc[7:0];  // Take lower 8 bits
                
                assign block_matrix[bi][bj] = large_matrix[src_row][src_col];
                assign block_matrix_flat[(bi*BLOCK_SIZE+bj+1)*DATA_WIDTH-1:(bi*BLOCK_SIZE+bj)*DATA_WIDTH] = block_matrix[bi][bj];
                
                // Debug: Add overflow detection
                `ifdef SIMULATION
                    initial begin
                        if (src_row_calc > 127 || src_col_calc > 127) begin
                            $display("ERROR: Matrix Splitter index overflow at block[%0d][%0d]: src_row=%0d, src_col=%0d", 
                                     bi, bj, src_row_calc, src_col_calc);
                        end
                    end
                `endif
            end
        end
    endgenerate

    // Valid signal delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
        end
    end

    // Debug monitoring
    `ifdef SIMULATION
        always @(*) begin
            if (valid_in) begin
                $display("Matrix Splitter: Extracting block [%0d,%0d]", row_block_idx, col_block_idx);
                $display("  Base indices: row=%0d, col=%0d", 
                         row_block_idx * BLOCK_SIZE, col_block_idx * BLOCK_SIZE);
            end
        end
    `endif

endmodule
