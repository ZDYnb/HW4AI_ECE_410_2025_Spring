`timescale 1ns/1ps

module tree_sum_accumulator (
    input clk,
    input rst_n,
    input start,
    input [1023:0] exp_values_in,
    output reg [23:0] sum_out,
    output reg sum_valid
);

// Parameters
localparam INPUT_WIDTH = 16;
localparam OUTPUT_WIDTH = 24;
localparam NUM_ADDER_STAGES = 6;

// Pipeline Storage - 6 register arrays
reg [OUTPUT_WIDTH-1:0] level0_reg [63:0];
reg [OUTPUT_WIDTH-1:0] level1_reg [31:0];
reg [OUTPUT_WIDTH-1:0] level2_reg [15:0];
reg [OUTPUT_WIDTH-1:0] level3_reg [7:0];
reg [OUTPUT_WIDTH-1:0] level4_reg [3:0];
reg [OUTPUT_WIDTH-1:0] level5_reg [1:0];

// Valid Signal Pipeline
reg [NUM_ADDER_STAGES:0] valid_pipe;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_pipe <= 0;
    end else begin
        valid_pipe <= {valid_pipe[NUM_ADDER_STAGES-1:0], start};
    end
end

// Input Unpacking
wire [INPUT_WIDTH-1:0] data_in [63:0];
genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin : input_unpack
        assign data_in[i] = exp_values_in[i*INPUT_WIDTH +: INPUT_WIDTH];
    end
endgenerate

integer j;

// --- Stage 0: Input Latching ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 64; j = j + 1) level0_reg[j] <= 0;
    end else if (start) begin
        for (j = 0; j < 64; j = j + 1) begin
            level0_reg[j] <= {{(OUTPUT_WIDTH-INPUT_WIDTH){data_in[j][INPUT_WIDTH-1]}}, data_in[j]};
        end
    end
end

// --- Stage 1: Additions (64 -> 32) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 32; j = j + 1) level1_reg[j] <= 0;
    end else if (valid_pipe[0]) begin
        for (j = 0; j < 32; j = j + 1) begin
            level1_reg[j] <= level0_reg[2*j] + level0_reg[2*j + 1];
        end
    end
end

// --- Stage 2: Additions (32 -> 16) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 16; j = j + 1) level2_reg[j] <= 0;
    end else if (valid_pipe[1]) begin
        for (j = 0; j < 16; j = j + 1) begin
            level2_reg[j] <= level1_reg[2*j] + level1_reg[2*j + 1];
        end
    end
end

// --- Stage 3: Additions (16 -> 8) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 8; j = j + 1) level3_reg[j] <= 0;
    end else if (valid_pipe[2]) begin
        for (j = 0; j < 8; j = j + 1) begin
            level3_reg[j] <= level2_reg[2*j] + level2_reg[2*j + 1];
        end
    end
end

// --- Stage 4: Additions (8 -> 4) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 4; j = j + 1) level4_reg[j] <= 0;
    end else if (valid_pipe[3]) begin
        for (j = 0; j < 4; j = j + 1) begin
            level4_reg[j] <= level3_reg[2*j] + level3_reg[2*j + 1];
        end
    end
end

// --- Stage 5: Additions (4 -> 2) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 2; j = j + 1) level5_reg[j] <= 0;
    end else if (valid_pipe[4]) begin
        for (j = 0; j < 2; j = j + 1) begin
            level5_reg[j] <= level4_reg[2*j] + level4_reg[2*j + 1];
        end
    end
end

// --- Output: Final Sum (2 -> 1) and Output Assignment ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_out <= 0;
        sum_valid <= 0;
    end else begin
        if (valid_pipe[5]) begin
            sum_out <= level5_reg[0] + level5_reg[1];  // Direct final addition
            sum_valid <= 1'b1;
        end else begin
            sum_valid <= 1'b0;
            // Keep sum_out unchanged when not valid
        end
    end
end

endmodule

