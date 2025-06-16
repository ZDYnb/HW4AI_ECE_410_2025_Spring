// ===========================================
// MAC Unit - Multiply-Accumulate Core
// Clean, Parameterized, and Testable
// ===========================================

`timescale 1ns/1ps

module mac_unit #(
    parameter DATA_WIDTH = 16,      // Input data width (S5.10)
    parameter WEIGHT_WIDTH = 8,     // Weight width (S1.6)  
    parameter ACCUM_WIDTH = 24      // Accumulator width (S7.16)
)(
    input                           clk,
    input                           rst_n,
    input                           enable,
    input                           clear_accum,
    
    input  [DATA_WIDTH-1:0]         data_in,
    input  [WEIGHT_WIDTH-1:0]       weight_in,
    
    output [ACCUM_WIDTH-1:0]        accum_out,
    output                          valid_out
);

    // ==========================================
    // Internal Signals
    // ==========================================
    wire signed [DATA_WIDTH-1:0]                data_signed;
    wire signed [WEIGHT_WIDTH-1:0]              weight_signed;
    wire signed [DATA_WIDTH+WEIGHT_WIDTH-1:0]   mult_result;
    reg  signed [ACCUM_WIDTH-1:0]               accum_reg;
    wire signed [ACCUM_WIDTH-1:0]               next_accum;
    reg                                         valid_out_reg;
    
    // ==========================================
    // Arithmetic Logic
    // ==========================================
    
    // Convert inputs to signed for proper arithmetic
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);
    
    // Multiply operation
    assign mult_result = data_signed * weight_signed;
    
    // Accumulator logic: clear or accumulate
    assign next_accum = clear_accum ? 
                       {{(ACCUM_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){mult_result[DATA_WIDTH+WEIGHT_WIDTH-1]}}, mult_result} :
                       (accum_reg + {{(ACCUM_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){mult_result[DATA_WIDTH+WEIGHT_WIDTH-1]}}, mult_result});
    
    // ==========================================
    // Sequential Logic
    // ==========================================
    
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
    
    // ==========================================
    // Output Assignment
    // ==========================================
    assign accum_out = accum_reg;
    assign valid_out = valid_out_reg;

endmodule
