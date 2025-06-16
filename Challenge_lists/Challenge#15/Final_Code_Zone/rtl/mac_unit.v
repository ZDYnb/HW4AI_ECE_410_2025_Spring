// MAC
module mac_unit (
    input clk,
    input rst_n,
    input enable,
    input clear,
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] result
);

// Parameters
localparam ACCUM_WIDTH = 32;

// Internal signals  
wire signed [15:0] a_signed;
wire signed [15:0] b_signed;
wire signed [31:0] mult_result;
wire signed [ACCUM_WIDTH-1:0] next_accum;
reg signed [ACCUM_WIDTH-1:0] accum_reg;

// Convert to signed for arithmetic
assign a_signed = $signed(a);
assign b_signed = $signed(b);
assign mult_result = a_signed * b_signed;

// Accumulator logic: clear or accumulate  
assign next_accum = clear ? (0) : (accum_reg + (mult_result >>> 10));

// Accumulator register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        accum_reg <= {ACCUM_WIDTH{1'b0}};
        result <= 16'b0;
    end else if (enable) begin
        accum_reg <= next_accum;
        result <= next_accum[15:0];  // 使用next_accum而不是accum_reg
    end
end

endmodule