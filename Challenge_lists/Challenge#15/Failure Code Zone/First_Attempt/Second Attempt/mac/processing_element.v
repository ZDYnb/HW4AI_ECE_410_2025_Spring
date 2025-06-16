// ===========================================
// Processing Element - PE Unit
// Extracted from original systolic array, uses independent mac_unit
// ===========================================

`timescale 1ns/1ps

module processing_element #(
    parameter DATA_WIDTH = 16,      // Data width (S5.10)
    parameter WEIGHT_WIDTH = 8,     // Weight width (S1.6)
    parameter ACCUM_WIDTH = 32      // Accumulator width (keep original 32-bit)
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,
    
    // Data flow: horizontal pass-through
    input  [DATA_WIDTH-1:0]       data_in,
    input                         data_valid_in,
    output [DATA_WIDTH-1:0]       data_out,
    output                        data_valid_out,
    
    // Weight flow: vertical pass-through
    input  [WEIGHT_WIDTH-1:0]     weight_in,
    input                         weight_valid_in,
    output [WEIGHT_WIDTH-1:0]     weight_out,
    output                        weight_valid_out,
    
    // Result output
    output [ACCUM_WIDTH-1:0]      accum_out,
    output                        result_valid
);

    // ==========================================
    // Internal Signals
    // ==========================================
    wire [DATA_WIDTH-1:0]      mac_data;
    wire [WEIGHT_WIDTH-1:0]    mac_weight;
    wire [ACCUM_WIDTH-1:0]     mac_accum;
    wire                       mac_valid;
    
    // Systolic registers: for systolic dataflow pass-through
    reg [DATA_WIDTH-1:0]       data_reg;
    reg                        data_valid_reg;
    reg [WEIGHT_WIDTH-1:0]     weight_reg;
    reg                        weight_valid_reg;
    
    // ==========================================
    // MAC Unit Input Control
    // ==========================================
    
    // MAC unit computes only when both data and weight are valid
    assign mac_data = (data_valid_in && weight_valid_in) ? data_in : {DATA_WIDTH{1'b0}};
    assign mac_weight = (data_valid_in && weight_valid_in) ? weight_in : {WEIGHT_WIDTH{1'b0}};
    
    // ==========================================
    // Systolic Dataflow Registers
    // ==========================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
            weight_reg <= {WEIGHT_WIDTH{1'b0}};
            weight_valid_reg <= 1'b0;
        end else if (enable) begin
            // Data flows horizontally
            data_reg <= data_in;
            data_valid_reg <= data_valid_in;
            // Weight flows vertically
            weight_reg <= weight_in;
            weight_valid_reg <= weight_valid_in;
        end else begin
            data_valid_reg <= 1'b0;
            weight_valid_reg <= 1'b0;
        end
    end
    
    // ==========================================
    // Output Dataflow
    // ==========================================
    assign data_out = data_reg;
    assign data_valid_out = data_valid_reg;
    assign weight_out = weight_reg;
    assign weight_valid_out = weight_valid_reg;
    
    // ==========================================
    // MAC Unit Instantiation
    // ==========================================
    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && data_valid_in && weight_valid_in),
        .clear_accum(clear_accum),
        .data_in(mac_data),
        .weight_in(mac_weight),
        .accum_out(mac_accum),
        .valid_out(mac_valid)
    );
    
    // ==========================================
    // Result Output
    // ==========================================
    assign accum_out = mac_accum;
    assign result_valid = mac_valid;

endmodule
