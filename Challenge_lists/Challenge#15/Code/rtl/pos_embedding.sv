module pos_embedding #(
    parameter N_POS = 16,
    parameter N_EMBD = 8
)(
    input wire clk,
    input wire [$clog2(N_POS)-1:0] pos,
    output reg [7:0] embedding [0:N_EMBD-1]
);

    reg [7:0] rom [0:N_POS-1][0:N_EMBD-1];

    integer i;
    initial begin
        for (int p = 0; p < N_POS; p++) begin
            for (int e = 0; e < N_EMBD; e++) begin
                rom[p][e] = p * N_EMBD + e; // Simple pattern
            end
        end
    end

    always @(posedge clk) begin
        for (i = 0; i < N_EMBD; i++) begin
            embedding[i] <= rom[pos][i];
        end
    end
endmodule


