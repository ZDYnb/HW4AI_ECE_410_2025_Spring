module systolic_pe (
    input clk,
    input rst_n,
    input enable,
    input [15:0] a_in,
    input [15:0] b_in,
    output reg [15:0] a_out,
    output reg [15:0] b_out,
    output [15:0] c_out
);

mac_unit mac_core (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .clear(1'b0),
    .a(a_in),
    .b(b_in),
    .result(c_out)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_out <= 16'h0;
        b_out <= 16'h0;
    end else begin
        a_out <= a_in;
        b_out <= b_in;
    end
end

endmodule