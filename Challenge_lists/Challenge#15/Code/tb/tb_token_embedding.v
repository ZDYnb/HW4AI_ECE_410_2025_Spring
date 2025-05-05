`timescale 1ns/1ps

module tb_token_embedding;
    reg clk = 0;
    reg [3:0] token_id;  // log2(16) = 4
    wire [7:0] embedding [0:7]; // N_EMBD = 8

    token_embedding #(
        .VOCAB_SIZE(16),
        .N_EMBD(8)
    ) dut (
        .clk(clk),
        .token_id(token_id),
        .embedding(embedding)
    );

    always #5 clk = ~clk;

    initial begin
        token_id = 4'd0; #10;
        $display("Token 0: %p", embedding);
        token_id = 4'd1; #10;
        $display("Token 1: %p", embedding);
        token_id = 4'd2; #10;
        $display("Token 2: %p", embedding);
        $finish;
    end
endmodule

