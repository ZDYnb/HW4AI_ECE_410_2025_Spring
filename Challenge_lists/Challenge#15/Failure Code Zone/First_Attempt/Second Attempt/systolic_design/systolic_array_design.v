// ===========================================
// Clean 4×4 Systolic Array Design Only
// No testbench - pure design modules
// Converted to standard Verilog
// ===========================================

`timescale 1ns/1ps

// ===========================================
// 4×4 Systolic Array Top Module
// ===========================================
module systolic_array_4x4 (
    input         clk,
    input         rst_n,
    input         enable,
    input         clear_accum,
    
    // Data inputs (4 rows)
    input  [15:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input         data_valid_0, data_valid_1, data_valid_2, data_valid_3,
    
    // Weight inputs (4 columns)
    input  [7:0]  weight_in_0, weight_in_1, weight_in_2, weight_in_3,
    input         weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3,
    
    // Results output (4×4 matrix)
    output [31:0] result_00, result_01, result_02, result_03,
    output [31:0] result_10, result_11, result_12, result_13,
    output [31:0] result_20, result_21, result_22, result_23,
    output [31:0] result_30, result_31, result_32, result_33,
    
    output        valid_00, valid_01, valid_02, valid_03,
    output        valid_10, valid_11, valid_12, valid_13,
    output        valid_20, valid_21, valid_22, valid_23,
    output        valid_30, valid_31, valid_32, valid_33
);

    // Internal horizontal data flow
    wire [15:0] data_h_0_1, data_h_0_2, data_h_0_3, data_h_0_4;
    wire [15:0] data_h_1_1, data_h_1_2, data_h_1_3, data_h_1_4;
    wire [15:0] data_h_2_1, data_h_2_2, data_h_2_3, data_h_2_4;
    wire [15:0] data_h_3_1, data_h_3_2, data_h_3_3, data_h_3_4;
    
    wire data_valid_h_0_1, data_valid_h_0_2, data_valid_h_0_3, data_valid_h_0_4;
    wire data_valid_h_1_1, data_valid_h_1_2, data_valid_h_1_3, data_valid_h_1_4;
    wire data_valid_h_2_1, data_valid_h_2_2, data_valid_h_2_3, data_valid_h_2_4;
    wire data_valid_h_3_1, data_valid_h_3_2, data_valid_h_3_3, data_valid_h_3_4;
    
    // Internal vertical weight flow
    wire [7:0] weight_v_1_0, weight_v_2_0, weight_v_3_0, weight_v_4_0;
    wire [7:0] weight_v_1_1, weight_v_2_1, weight_v_3_1, weight_v_4_1;
    wire [7:0] weight_v_1_2, weight_v_2_2, weight_v_3_2, weight_v_4_2;
    wire [7:0] weight_v_1_3, weight_v_2_3, weight_v_3_3, weight_v_4_3;
    
    wire weight_valid_v_1_0, weight_valid_v_2_0, weight_valid_v_3_0, weight_valid_v_4_0;
    wire weight_valid_v_1_1, weight_valid_v_2_1, weight_valid_v_3_1, weight_valid_v_4_1;
    wire weight_valid_v_1_2, weight_valid_v_2_2, weight_valid_v_3_2, weight_valid_v_4_2;
    wire weight_valid_v_1_3, weight_valid_v_2_3, weight_valid_v_3_3, weight_valid_v_4_3;
    
    // 4×4 Processing Element Array
    // Row 0
    processing_element pe_00 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_0), .data_valid_in(data_valid_0),
        .data_out(data_h_0_1), .data_valid_out(data_valid_h_0_1),
        .weight_in(weight_in_0), .weight_valid_in(weight_valid_0),
        .weight_out(weight_v_1_0), .weight_valid_out(weight_valid_v_1_0),
        .accum_out(result_00), .result_valid(valid_00)
    );
    
    processing_element pe_01 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_1), .data_valid_in(data_valid_h_0_1),
        .data_out(data_h_0_2), .data_valid_out(data_valid_h_0_2),
        .weight_in(weight_in_1), .weight_valid_in(weight_valid_1),
        .weight_out(weight_v_1_1), .weight_valid_out(weight_valid_v_1_1),
        .accum_out(result_01), .result_valid(valid_01)
    );
    
    processing_element pe_02 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_2), .data_valid_in(data_valid_h_0_2),
        .data_out(data_h_0_3), .data_valid_out(data_valid_h_0_3),
        .weight_in(weight_in_2), .weight_valid_in(weight_valid_2),
        .weight_out(weight_v_1_2), .weight_valid_out(weight_valid_v_1_2),
        .accum_out(result_02), .result_valid(valid_02)
    );
    
    processing_element pe_03 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_3), .data_valid_in(data_valid_h_0_3),
        .data_out(data_h_0_4), .data_valid_out(data_valid_h_0_4),
        .weight_in(weight_in_3), .weight_valid_in(weight_valid_3),
        .weight_out(weight_v_1_3), .weight_valid_out(weight_valid_v_1_3),
        .accum_out(result_03), .result_valid(valid_03)
    );
    
    // Row 1
    processing_element pe_10 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_1), .data_valid_in(data_valid_1),
        .data_out(data_h_1_1), .data_valid_out(data_valid_h_1_1),
        .weight_in(weight_v_1_0), .weight_valid_in(weight_valid_v_1_0),
        .weight_out(weight_v_2_0), .weight_valid_out(weight_valid_v_2_0),
        .accum_out(result_10), .result_valid(valid_10)
    );
    
    processing_element pe_11 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_1), .data_valid_in(data_valid_h_1_1),
        .data_out(data_h_1_2), .data_valid_out(data_valid_h_1_2),
        .weight_in(weight_v_1_1), .weight_valid_in(weight_valid_v_1_1),
        .weight_out(weight_v_2_1), .weight_valid_out(weight_valid_v_2_1),
        .accum_out(result_11), .result_valid(valid_11)
    );
    
    processing_element pe_12 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_2), .data_valid_in(data_valid_h_1_2),
        .data_out(data_h_1_3), .data_valid_out(data_valid_h_1_3),
        .weight_in(weight_v_1_2), .weight_valid_in(weight_valid_v_1_2),
        .weight_out(weight_v_2_2), .weight_valid_out(weight_valid_v_2_2),
        .accum_out(result_12), .result_valid(valid_12)
    );
    
    processing_element pe_13 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_3), .data_valid_in(data_valid_h_1_3),
        .data_out(data_h_1_4), .data_valid_out(data_valid_h_1_4),
        .weight_in(weight_v_1_3), .weight_valid_in(weight_valid_v_1_3),
        .weight_out(weight_v_2_3), .weight_valid_out(weight_valid_v_2_3),
        .accum_out(result_13), .result_valid(valid_13)
    );
    
    // Row 2
    processing_element pe_20 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_2), .data_valid_in(data_valid_2),
        .data_out(data_h_2_1), .data_valid_out(data_valid_h_2_1),
        .weight_in(weight_v_2_0), .weight_valid_in(weight_valid_v_2_0),
        .weight_out(weight_v_3_0), .weight_valid_out(weight_valid_v_3_0),
        .accum_out(result_20), .result_valid(valid_20)
    );
    
    processing_element pe_21 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_1), .data_valid_in(data_valid_h_2_1),
        .data_out(data_h_2_2), .data_valid_out(data_valid_h_2_2),
        .weight_in(weight_v_2_1), .weight_valid_in(weight_valid_v_2_1),
        .weight_out(weight_v_3_1), .weight_valid_out(weight_valid_v_3_1),
        .accum_out(result_21), .result_valid(valid_21)
    );
    
    processing_element pe_22 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_2), .data_valid_in(data_valid_h_2_2),
        .data_out(data_h_2_3), .data_valid_out(data_valid_h_2_3),
        .weight_in(weight_v_2_2), .weight_valid_in(weight_valid_v_2_2),
        .weight_out(weight_v_3_2), .weight_valid_out(weight_valid_v_3_2),
        .accum_out(result_22), .result_valid(valid_22)
    );
    
    processing_element pe_23 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_3), .data_valid_in(data_valid_h_2_3),
        .data_out(data_h_2_4), .data_valid_out(data_valid_h_2_4),
        .weight_in(weight_v_2_3), .weight_valid_in(weight_valid_v_2_3),
        .weight_out(weight_v_3_3), .weight_valid_out(weight_valid_v_3_3),
        .accum_out(result_23), .result_valid(valid_23)
    );
    
    // Row 3
    processing_element pe_30 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_3), .data_valid_in(data_valid_3),
        .data_out(data_h_3_1), .data_valid_out(data_valid_h_3_1),
        .weight_in(weight_v_3_0), .weight_valid_in(weight_valid_v_3_0),
        .weight_out(weight_v_4_0), .weight_valid_out(weight_valid_v_4_0),
        .accum_out(result_30), .result_valid(valid_30)
    );
    
    processing_element pe_31 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_1), .data_valid_in(data_valid_h_3_1),
        .data_out(data_h_3_2), .data_valid_out(data_valid_h_3_2),
        .weight_in(weight_v_3_1), .weight_valid_in(weight_valid_v_3_1),
        .weight_out(weight_v_4_1), .weight_valid_out(weight_valid_v_4_1),
        .accum_out(result_31), .result_valid(valid_31)
    );
    
    processing_element pe_32 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_2), .data_valid_in(data_valid_h_3_2),
        .data_out(data_h_3_3), .data_valid_out(data_valid_h_3_3),
        .weight_in(weight_v_3_2), .weight_valid_in(weight_valid_v_3_2),
        .weight_out(weight_v_4_2), .weight_valid_out(weight_valid_v_4_2),
        .accum_out(result_32), .result_valid(valid_32)
    );
    
    processing_element pe_33 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_3), .data_valid_in(data_valid_h_3_3),
        .data_out(data_h_3_4), .data_valid_out(data_valid_h_3_4),
        .weight_in(weight_v_3_3), .weight_valid_in(weight_valid_v_3_3),
        .weight_out(weight_v_4_3), .weight_valid_out(weight_valid_v_4_3),
        .accum_out(result_33), .result_valid(valid_33)
    );

endmodule

// ===========================================
// Processing Element
// ===========================================
module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,
    
    input  [DATA_WIDTH-1:0]       data_in,
    input                         data_valid_in,
    output [DATA_WIDTH-1:0]       data_out,
    output                        data_valid_out,
    
    input  [WEIGHT_WIDTH-1:0]     weight_in,
    input                         weight_valid_in,
    output [WEIGHT_WIDTH-1:0]     weight_out,
    output                        weight_valid_out,
    
    output [ACCUM_WIDTH-1:0]      accum_out,
    output                        result_valid
);

    wire [DATA_WIDTH-1:0]      mac_data;
    wire [WEIGHT_WIDTH-1:0]    mac_weight;
    wire [ACCUM_WIDTH-1:0]     mac_accum;
    wire                       mac_valid;
    
    reg [DATA_WIDTH-1:0]       data_reg;
    reg                        data_valid_reg;
    reg [WEIGHT_WIDTH-1:0]     weight_reg;
    reg                        weight_valid_reg;
    
    // MAC unit gets valid data/weight only when both are valid
    assign mac_data = (data_valid_in && weight_valid_in) ? data_in : {DATA_WIDTH{1'b0}};
    assign mac_weight = (data_valid_in && weight_valid_in) ? weight_in : {WEIGHT_WIDTH{1'b0}};
    
    // Register data and weights for systolic flow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
            weight_reg <= {WEIGHT_WIDTH{1'b0}};
            weight_valid_reg <= 1'b0;
        end else if (enable) begin
            data_reg <= data_in;
            data_valid_reg <= data_valid_in;
            weight_reg <= weight_in;
            weight_valid_reg <= weight_valid_in;
        end else begin
            data_valid_reg <= 1'b0;
            weight_valid_reg <= 1'b0;
        end
    end
    
    // Output registered values for systolic flow
    assign data_out = data_reg;
    assign data_valid_out = data_valid_reg;
    assign weight_out = weight_reg;
    assign weight_valid_out = weight_valid_reg;
    
    // MAC unit instantiation
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && data_valid_in && weight_valid_in),
        .clear_accum(clear_accum),
        .data_in(mac_data),
        .weight_in(mac_weight),
        .accum_out(mac_accum),
        .valid_out(mac_valid)
    );
    
    assign accum_out = mac_accum;
    assign result_valid = mac_valid;

endmodule

// ===========================================
// MAC Unit (Multiply-Accumulate)
// ===========================================
module mac_unit_basic #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,
    
    input  [DATA_WIDTH-1:0]       data_in,
    input  [WEIGHT_WIDTH-1:0]     weight_in,
    
    output [ACCUM_WIDTH-1:0]      accum_out,
    output                        valid_out
);

    wire signed [DATA_WIDTH-1:0]      data_signed;
    wire signed [WEIGHT_WIDTH-1:0]    weight_signed;
    wire signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] mult_result;
    reg signed [ACCUM_WIDTH-1:0]      accum_reg;
    wire signed [ACCUM_WIDTH-1:0]     next_accum;
    reg                               valid_out_reg;
    
    // Convert to signed for arithmetic
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);
    assign mult_result = data_signed * weight_signed;
    
    // Accumulator logic: clear or accumulate
    assign next_accum = clear_accum ? mult_result : (accum_reg + mult_result);
    
    // Accumulator register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= {ACCUM_WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end else if (enable) begin
            accum_reg <= next_accum;
            valid_out_reg <= 1'b1;
        end else begin
            valid_out_reg <= 1'b0;
        end
    end
    
    assign accum_out = accum_reg;
    assign valid_out = valid_out_reg;

endmodule
