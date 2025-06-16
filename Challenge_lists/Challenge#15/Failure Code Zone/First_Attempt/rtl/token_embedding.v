`timescale 1ns/1ps

module token_embedding #(
    parameter VOCAB_SIZE = 16,
    parameter N_EMBD     = 8
)(
    input  wire clk,
    input  wire [$clog2(VOCAB_SIZE)-1:0] token_id,
    output reg  [7:0] embedding [0:N_EMBD-1]
);

	// define a toy embedding ROM
    reg [7:0] rom [0:VOCAB_SIZE-1][0:N_EMBD-1];

    integer i;
    initial begin
        for (int t = 0; t < VOCAB_SIZE; t++) begin
            for (int e = 0; e < N_EMBD; e++) begin
                rom[t][e] = t * N_EMBD + e; // Just simple pattern
            end
        end
    end

    always @(posedge clk) begin
        for (i = 0; i < N_EMBD; i++) begin
            embedding[i] <= rom[token_id][i];
        end
    end

endmodule
