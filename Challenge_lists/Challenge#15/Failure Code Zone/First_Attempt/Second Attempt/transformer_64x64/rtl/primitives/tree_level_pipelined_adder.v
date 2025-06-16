// ===========================================
// Tree Sum Accumulator - Based on Proven Design
// 64-input parallel tree adder with pipeline
// S5.10 Fixed Point Format  
// Clean production-ready implementation
// ===========================================

`timescale 1ns/1ps

module tree_sum_accumulator (
    input clk,
    input rst_n,
    input start,                           // Start tree addition
    input [1023:0] exp_values_in,         // 64×16 exp values (S5.10)
    output reg [23:0] sum_out,            // S13.10 sum result
    output reg sum_valid                  // Result valid
);

// ============================================================================
// Parameter Calculations - Exact match to successful version
// ============================================================================
localparam D_MODEL = 64;                  // 64 inputs
localparam INPUT_WIDTH = 16;              // S5.10 format  
localparam OUTPUT_WIDTH = 24;             // S13.10 format
localparam PADDED_SIZE = 1 << $clog2(D_MODEL);  // 64 -> 64 (already power of 2)
localparam TREE_LEVELS = $clog2(PADDED_SIZE);   // log2(64) = 6

// ============================================================================
// Signal Declarations
// ============================================================================
integer i_input, i_level;

// Internal data arrays (unpacked from flat input)
wire [INPUT_WIDTH-1:0] data_in [D_MODEL-1:0];

// Unpack flattened input into array
genvar unpack_i;
generate
    for (unpack_i = 0; unpack_i < D_MODEL; unpack_i = unpack_i + 1) begin : input_unpack
        assign data_in[unpack_i] = exp_values_in[(unpack_i+1)*INPUT_WIDTH-1 : unpack_i*INPUT_WIDTH];
    end
endgenerate

// Pipeline storage arrays
reg [OUTPUT_WIDTH-1:0] tree_data [TREE_LEVELS:0] [PADDED_SIZE-1:0];
reg [TREE_LEVELS:0] level_valid;

// ============================================================================
// Input Stage (Level 0)
// ============================================================================
always @(posedge clk or negedge rst_n) begin : input_stage
    if (!rst_n) begin
        level_valid[0] <= 1'b0;
        for (i_input = 0; i_input < PADDED_SIZE; i_input = i_input + 1) begin
            tree_data[0][i_input] <= {OUTPUT_WIDTH{1'b0}};
        end
    end else begin
        level_valid[0] <= start;
        
        if (start) begin
            for (i_input = 0; i_input < PADDED_SIZE; i_input = i_input + 1) begin
                // Sign-extend S5.10 to S13.10 format
                tree_data[0][i_input] <= {{(OUTPUT_WIDTH-INPUT_WIDTH){data_in[i_input][INPUT_WIDTH-1]}}, 
                                         data_in[i_input]};
            end
        end
    end
end

// ============================================================================
// Tree Pipeline Levels (Level 1 to TREE_LEVELS)
// ============================================================================
genvar level;
generate
    for (level = 1; level <= TREE_LEVELS; level = level + 1) begin : tree_levels
        
        localparam NODES_THIS_LEVEL = PADDED_SIZE >> level;
        
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                level_valid[level] <= 1'b0;
                for (i_level = 0; i_level < PADDED_SIZE; i_level = i_level + 1) begin
                    tree_data[level][i_level] <= {OUTPUT_WIDTH{1'b0}};
                end
            end else begin
                level_valid[level] <= level_valid[level-1];
                
                if (level_valid[level-1]) begin
                    for (i_level = 0; i_level < NODES_THIS_LEVEL; i_level = i_level + 1) begin
                        tree_data[level][i_level] <= tree_data[level-1][2*i_level] + tree_data[level-1][2*i_level + 1];
                    end
                    
                    // Clear unused nodes
                    for (i_level = NODES_THIS_LEVEL; i_level < PADDED_SIZE; i_level = i_level + 1) begin
                        tree_data[level][i_level] <= {OUTPUT_WIDTH{1'b0}};
                    end
                end
            end
        end
    end
endgenerate

// ============================================================================
// Output Stage
// ============================================================================
always @(posedge clk or negedge rst_n) begin : output_stage
    if (!rst_n) begin
        sum_out <= {OUTPUT_WIDTH{1'b0}};
        sum_valid <= 1'b0;
    end else begin
        sum_out <= tree_data[TREE_LEVELS][0];
        sum_valid <= level_valid[TREE_LEVELS];
    end
end

endmodule

