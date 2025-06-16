// ===========================================
// Result Accumulator
// Accumulates partial 64x64 results into final 128x128 result matrix
// ===========================================

`timescale 1ns/1ps

module result_accumulator #(
    parameter MATRIX_SIZE = 128,
    parameter BLOCK_SIZE = 64,
    parameter DATA_WIDTH = 16,
    parameter ACCUM_WIDTH = 24
)(
    input clk,
    input rst_n,
    input start_new_computation,
    input accumulate_result,
    input [1:0] c_row_idx,
    input [1:0] c_col_idx,
    input [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] partial_result_flat,
    output [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] final_result_flat,
    output reg accumulation_done
);

    localparam NUM_BLOCKS = MATRIX_SIZE / BLOCK_SIZE;

    reg signed [ACCUM_WIDTH-1:0] accumulator [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    wire signed [DATA_WIDTH-1:0] partial_result [0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
    wire signed [DATA_WIDTH-1:0] final_result [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Add edge detection for accumulate_result
    reg accumulate_result_prev;
    wire accumulate_pulse;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulate_result_prev <= 1'b0;
        end else begin
            accumulate_result_prev <= accumulate_result;
        end
    end
    
    // Generate pulse only on rising edge
    assign accumulate_pulse = accumulate_result && !accumulate_result_prev;

    // Unflatten partial result
    genvar pi, pj;
    generate
        for (pi = 0; pi < BLOCK_SIZE; pi = pi + 1) begin: PARTIAL_ROW
            for (pj = 0; pj < BLOCK_SIZE; pj = pj + 1) begin: PARTIAL_COL
                assign partial_result[pi][pj] = partial_result_flat[(pi*BLOCK_SIZE+pj+1)*DATA_WIDTH-1:(pi*BLOCK_SIZE+pj)*DATA_WIDTH];
            end
        end
    endgenerate

    // Flatten final result
    genvar fi, fj;
    generate
        for (fi = 0; fi < MATRIX_SIZE; fi = fi + 1) begin: FINAL_ROW
            for (fj = 0; fj < MATRIX_SIZE; fj = fj + 1) begin: FINAL_COL
                assign final_result[fi][fj] = accumulator[fi][fj][DATA_WIDTH-1:0];
                assign final_result_flat[(fi*MATRIX_SIZE+fj+1)*DATA_WIDTH-1:(fi*MATRIX_SIZE+fj)*DATA_WIDTH] = final_result[fi][fj];
            end
        end
    endgenerate

    // Accumulator management with edge detection
    integer row, col, i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (row = 0; row < MATRIX_SIZE; row = row + 1) begin
                for (col = 0; col < MATRIX_SIZE; col = col + 1) begin
                    accumulator[row][col] <= {ACCUM_WIDTH{1'b0}};
                end
            end
            accumulation_done <= 1'b0;
        end else if (start_new_computation) begin
            for (row = 0; row < MATRIX_SIZE; row = row + 1) begin
                for (col = 0; col < MATRIX_SIZE; col = col + 1) begin
                    accumulator[row][col] <= {ACCUM_WIDTH{1'b0}};
                end
            end
            accumulation_done <= 1'b0;
        end else if (accumulate_pulse) begin  // Use pulse instead of level
            for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                    accumulator[c_row_idx*BLOCK_SIZE + i][c_col_idx*BLOCK_SIZE + j] <= 
                        accumulator[c_row_idx*BLOCK_SIZE + i][c_col_idx*BLOCK_SIZE + j] + 
                        {{(ACCUM_WIDTH-DATA_WIDTH){partial_result[i][j][DATA_WIDTH-1]}}, partial_result[i][j]};
                end
            end
            accumulation_done <= 1'b1;
            
            // Debug output
            `ifdef SIMULATION
            $display("Result Accumulator: Accumulated to block [%0d,%0d] at T=%0t", 
                     c_row_idx, c_col_idx, $time);
            $display("  Sample values: [0][0]=%0d, [1][1]=%0d", 
                     partial_result[0][0], partial_result[1][1]);
            `endif
        end else begin
            accumulation_done <= 1'b0;
        end
    end

    // Debug monitoring
    `ifdef SIMULATION
        always @(posedge accumulate_pulse) begin
            $display("Result Accumulator: Pulse detected for block [%0d,%0d]", c_row_idx, c_col_idx);
        end
        
        always @(posedge accumulate_result) begin
            if (!accumulate_pulse) begin
                $display("Result Accumulator: Level signal but no pulse (ignored)");
            end
        end
    `endif

endmodule
