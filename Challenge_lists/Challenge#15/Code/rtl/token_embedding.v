// token_embedding.v
`timescale 1ns/1ps
module token_embedding (
    input wire clk,
    input wire [3:0] token_id,
    output reg [7:0] embedding_vector0,
    output reg [7:0] embedding_vector1,
    output reg [7:0] embedding_vector2,
    output reg [7:0] embedding_vector3
);

    reg [7:0] rom [0:15][0:3];  // 16 tokens × 4-dim

    initial begin
        rom[0][0] = 8'd1;  rom[0][1] = 8'd2;  rom[0][2] = 8'd3;  rom[0][3] = 8'd4;
        rom[1][0] = 8'd5;  rom[1][1] = 8'd6;  rom[1][2] = 8'd7;  rom[1][3] = 8'd8;
        rom[2][0] = 8'd9;  rom[2][1] = 8'd10; rom[2][2] = 8'd11; rom[2][3] = 8'd12;
    end

    always @(posedge clk) begin
        embedding_vector0 <= rom[token_id][0];
        embedding_vector1 <= rom[token_id][1];
        embedding_vector2 <= rom[token_id][2];
        embedding_vector3 <= rom[token_id][3];
    end

endmodule
