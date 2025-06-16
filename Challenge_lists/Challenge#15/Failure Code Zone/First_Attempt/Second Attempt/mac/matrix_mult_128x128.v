// ===========================================
// Matrix Multiplication 128x128 - Debug Version
// Added extensive debug monitoring
// ===========================================

`timescale 1ns/1ps

module matrix_mult_128x128 #(
    parameter MATRIX_SIZE = 128,
    parameter BLOCK_SIZE = 64,
    parameter DATA_WIDTH = 16,
    parameter ACCUM_WIDTH = 24
)(
    input clk,
    input rst_n,
    
    // Control interface
    input start,
    output reg done,
    
    // Matrix inputs (128x128) - flattened
    input [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] matrix_a_flat,
    input [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] matrix_b_flat,
    
    // Result output (128x128) - flattened  
    output [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] result_flat,
    
    // Progress monitoring
    output [3:0] current_step,
    output computation_active
);

// =========================================== 
// Internal Signals
// ===========================================

// Block Manager signals
wire block_mgr_done;
wire block_mgr_computation_valid;
wire [1:0] a_row_idx, a_col_idx;
wire [1:0] b_row_idx, b_col_idx; 
wire [1:0] c_row_idx, c_col_idx;
wire start_systolic;
wire systolic_done;
wire accumulate_result;
wire [3:0] computation_count;

// Matrix Splitter A signals
wire [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] block_a_flat;

// Matrix B 16-bit to 8-bit conversion
wire [8*MATRIX_SIZE*MATRIX_SIZE-1:0] matrix_b_8bit;

// Matrix Splitter B signals (8-bit weights)
wire [8*BLOCK_SIZE*BLOCK_SIZE-1:0] block_b_flat;

// Systolic Array signals (32-bit accumulator)
wire [32*BLOCK_SIZE*BLOCK_SIZE-1:0] systolic_result_flat;
wire systolic_computation_done;

// Result Accumulator signals (convert 32-bit to 16-bit)
wire [DATA_WIDTH*BLOCK_SIZE*BLOCK_SIZE-1:0] systolic_result_16bit;

// Result Accumulator signals
wire [DATA_WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] accumulated_result_flat;

// Debug signals
reg [31:0] accumulate_count [0:3][0:3];  // Count accumulations per block
wire [15:0] debug_systolic_sample;
wire [15:0] debug_accumulated_sample;

// =========================================== 
// 16-bit to 8-bit Conversion for Matrix B
// ===========================================
genvar conv_i, conv_j;
generate
    for (conv_i = 0; conv_i < MATRIX_SIZE; conv_i = conv_i + 1) begin: CONV_ROW
        for (conv_j = 0; conv_j < MATRIX_SIZE; conv_j = conv_j + 1) begin: CONV_COL
            // Extract lower 8 bits from each 16-bit element
            assign matrix_b_8bit[(conv_i*MATRIX_SIZE+conv_j)*8 +: 8] = 
                   matrix_b_flat[(conv_i*MATRIX_SIZE+conv_j)*16 +: 8];
        end
    end
endgenerate

// =========================================== 
// Block Manager Instance
// ===========================================
block_manager #(
    .BLOCK_SIZE(BLOCK_SIZE)
) block_mgr_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .done(block_mgr_done),
    .computation_valid(block_mgr_computation_valid),
    .a_row_idx(a_row_idx),
    .a_col_idx(a_col_idx),
    .b_row_idx(b_row_idx),
    .b_col_idx(b_col_idx),
    .c_row_idx(c_row_idx),
    .c_col_idx(c_col_idx),
    .start_systolic(start_systolic),
    .systolic_done(systolic_done),
    .accumulate_result(accumulate_result),
    .computation_count(computation_count)
);

// =========================================== 
// Matrix Splitter A Instance
// ===========================================
matrix_splitter #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH)
) splitter_a_inst (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(block_mgr_computation_valid),
    .valid_out(),  // Not used in this integration
    .large_matrix_flat(matrix_a_flat),
    .row_block_idx(a_row_idx),
    .col_block_idx(a_col_idx),
    .block_matrix_flat(block_a_flat)
);

// =========================================== 
// Matrix Splitter B Instance (8-bit weights)
// ===========================================
matrix_splitter #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(8)  // Note: weights are 8-bit
) splitter_b_inst (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(block_mgr_computation_valid),
    .valid_out(),  // Not used in this integration
    .large_matrix_flat(matrix_b_8bit),  // Use properly converted 8-bit matrix
    .row_block_idx(b_row_idx),
    .col_block_idx(b_col_idx),
    .block_matrix_flat(block_b_flat)
);

// =========================================== 
// Systolic Array Instance (fixed interface)
// ===========================================
systolic_array_top #(
    .ARRAY_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(8),
    .ACCUM_WIDTH(32)
) systolic_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_systolic),
    .matrix_a_flat(block_a_flat),
    .matrix_b_flat(block_b_flat),
    .result_flat(systolic_result_flat),
    .computation_done(systolic_computation_done),
    .result_valid()  // Not used
);

// Connect systolic done signal
assign systolic_done = systolic_computation_done;

// =========================================== 
// Bit width conversion: 32-bit ¿ 16-bit
// ===========================================
genvar bi, bj;
generate
    for (bi = 0; bi < BLOCK_SIZE; bi = bi + 1) begin: BIT_CONV_ROW
        for (bj = 0; bj < BLOCK_SIZE; bj = bj + 1) begin: BIT_CONV_COL
            // Extract 16-bit result from 32-bit accumulator (take lower 16 bits)
            assign systolic_result_16bit[(bi*BLOCK_SIZE + bj + 1)*DATA_WIDTH - 1 : (bi*BLOCK_SIZE + bj)*DATA_WIDTH] 
                 = systolic_result_flat[(bi*BLOCK_SIZE + bj + 1)*32 - 1 : (bi*BLOCK_SIZE + bj)*32];
        end
    end
endgenerate

// =========================================== 
// Result Accumulator Instance
// ===========================================
result_accumulator #(
    .MATRIX_SIZE(MATRIX_SIZE),
    .BLOCK_SIZE(BLOCK_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) accumulator_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start_new_computation(start),
    .accumulate_result(accumulate_result),
    .c_row_idx(c_row_idx),
    .c_col_idx(c_col_idx),
    .partial_result_flat(systolic_result_16bit),  // Use converted 16-bit results
    .final_result_flat(accumulated_result_flat),
    .accumulation_done()  // Not used
);

// =========================================== 
// Debug Sample Signals
// ===========================================
assign debug_systolic_sample = systolic_result_16bit[15:0];  // Sample element [0][0]
assign debug_accumulated_sample = accumulated_result_flat[15:0];  // Sample element [0][0]

// =========================================== 
// Top Level Control Logic
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 1'b0;
    end else begin
        done <= block_mgr_done;
    end
end

// =========================================== 
// Output Assignments
// ===========================================
assign result_flat = accumulated_result_flat;
assign current_step = computation_count;
assign computation_active = block_mgr_computation_valid;

// =========================================== 
// Debug Accumulation Counter
// ===========================================
integer debug_i, debug_j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (debug_i = 0; debug_i < 4; debug_i = debug_i + 1) begin
            for (debug_j = 0; debug_j < 4; debug_j = debug_j + 1) begin
                accumulate_count[debug_i][debug_j] <= 0;
            end
        end
    end else if (start) begin
        for (debug_i = 0; debug_i < 4; debug_i = debug_i + 1) begin
            for (debug_j = 0; debug_j < 4; debug_j = debug_j + 1) begin
                accumulate_count[debug_i][debug_j] <= 0;
            end
        end
    end else if (accumulate_result) begin
        accumulate_count[c_row_idx][c_col_idx] <= accumulate_count[c_row_idx][c_col_idx] + 1;
    end
end

// =========================================== 
// Enhanced Debug and Monitoring
// ===========================================
always @(posedge clk) begin
    if (start) begin
        $display("Matrix Mult 128x128: Starting computation");
    end
    
    if (start_systolic) begin
        $display("Matrix Mult 128x128: Starting systolic computation %0d", computation_count);
        $display("  Processing: A[%0d,%0d] × B[%0d,%0d] ¿ C[%0d,%0d]",
                 a_row_idx, a_col_idx, b_row_idx, b_col_idx, c_row_idx, c_col_idx);
        // Sample input data
        $display("  Sample A[0][0] = %h, B[0][0] = %h", block_a_flat[15:0], block_b_flat[7:0]);
    end
    
    if (systolic_done) begin
        $display("Matrix Mult 128x128: Systolic computation %0d completed", computation_count);
        $display("  Sample systolic result[0][0] = %h", debug_systolic_sample);
    end
    
    if (accumulate_result) begin
        $display("Matrix Mult 128x128: Accumulating result %0d to block [%0d,%0d]", 
                 computation_count, c_row_idx, c_col_idx);
        $display("  Accumulation count for this block: %0d", accumulate_count[c_row_idx][c_col_idx] + 1);
        $display("  Sample accumulator input = %h", debug_systolic_sample);
        $display("  Sample accumulator output = %h", debug_accumulated_sample);
    end
    
    if (done) begin
        $display("Matrix Mult 128x128: Computation completed after %0d steps", computation_count + 1);
        $display("  Final accumulation counts:");
        $display("    Block [0,0]: %0d, Block [0,1]: %0d", 
                 accumulate_count[0][0], accumulate_count[0][1]);
        $display("    Block [1,0]: %0d, Block [1,1]: %0d", 
                 accumulate_count[1][0], accumulate_count[1][1]);
    end
end

// Performance monitoring
reg [31:0] cycle_counter;
always @(posedge clk) begin
    if (start) begin
        cycle_counter <= 0;
    end else if (computation_active) begin
        cycle_counter <= cycle_counter + 1;
    end
    
    if (done) begin
        $display("Matrix Mult 128x128: Total cycles: %0d", cycle_counter);
    end
end

// Debug Block Manager state
always @(posedge clk) begin
    if (block_mgr_inst.state != block_mgr_inst.next_state) begin
        $display("Block Manager: State transition %0d ¿ %0d", 
                 block_mgr_inst.state, block_mgr_inst.next_state);
    end
end

// Debug accumulate_result signal duration
reg accumulate_prev;
reg [31:0] accumulate_duration;

always @(posedge clk) begin
    accumulate_prev <= accumulate_result;
    
    if (accumulate_result && !accumulate_prev) begin
        accumulate_duration <= 0;
        $display("DEBUG: accumulate_result asserted at T=%0t", $time);
    end else if (accumulate_result) begin
        accumulate_duration <= accumulate_duration + 1;
    end else if (!accumulate_result && accumulate_prev) begin
        $display("DEBUG: accumulate_result deasserted after %0d cycles", accumulate_duration + 1);
    end
end

endmodule
