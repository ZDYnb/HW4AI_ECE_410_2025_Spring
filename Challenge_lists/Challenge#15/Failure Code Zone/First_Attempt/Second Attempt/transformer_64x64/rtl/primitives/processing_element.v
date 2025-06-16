// ===========================================
// Processing Element for Systolic Array
// ===========================================
`timescale 1ns/1ps
module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input clk,
    input rst_n,
    
    // Data inputs (horizontal flow)
    input [DATA_WIDTH-1:0] data_in,
    input data_valid,
    
    // Weight inputs (vertical flow)
    input [WEIGHT_WIDTH-1:0] weight_in,
    input weight_valid,
    
    // Control
    input accumulate_en,
    
    // Data outputs (to next PE)
    output [DATA_WIDTH-1:0] data_out,
    output data_valid_out,
    
    // Weight outputs (to next PE)
    output [WEIGHT_WIDTH-1:0] weight_out,
    output weight_valid_out,
    
    // Result
    output [ACCUM_WIDTH-1:0] result
);

// ==========================================
// Internal Signals
// ==========================================
reg [DATA_WIDTH-1:0] data_reg;
reg data_valid_reg;
reg [WEIGHT_WIDTH-1:0] weight_reg;
reg weight_valid_reg;

wire mac_enable;
wire clear_accum;
wire [ACCUM_WIDTH-1:0] mac_result;
wire mac_valid;

// ==========================================
// Register Data and Weight Flow
// ==========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg <= {DATA_WIDTH{1'b0}};
        data_valid_reg <= 1'b0;
        weight_reg <= {WEIGHT_WIDTH{1'b0}};
        weight_valid_reg <= 1'b0;
    end else begin
        data_reg <= data_in;
        data_valid_reg <= data_valid;
        weight_reg <= weight_in;
        weight_valid_reg <= weight_valid;
    end
end

// ==========================================
// MAC Control Logic
// ==========================================
reg prev_accumulate_en;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_accumulate_en <= 1'b0;
    end else begin
        prev_accumulate_en <= accumulate_en;
    end
end

assign mac_enable = data_valid && weight_valid && accumulate_en;
assign clear_accum = accumulate_en && !prev_accumulate_en; // Clear at start of new computation

// ==========================================
// MAC Unit Instance
// ==========================================
mac_unit #(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) mac_inst (
    .clk(clk),
    .rst_n(rst_n),
    .enable(mac_enable),
    .clear_accum(clear_accum),
    .data_in(data_in),
    .weight_in(weight_in),
    .accum_out(mac_result),
    .valid_out(mac_valid)
);

// ==========================================
// Output Assignments
// ==========================================
assign data_out = data_reg;
assign data_valid_out = data_valid_reg;
assign weight_out = weight_reg;
assign weight_valid_out = weight_valid_reg;
assign result = mac_result;

endmodule

