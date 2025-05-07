/* verilator lint_off UNUSEDSIGNAL */
module layernorm #(
    parameter N = 4,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst,
    input  logic [N*DATA_WIDTH-1:0] in_vector_flat,
    output logic [N*DATA_WIDTH-1:0] out_vector_flat
);

    logic [DATA_WIDTH-1:0] in_vector     [0:N-1];
    logic [DATA_WIDTH-1:0] out_vector    [0:N-1];
    logic [DATA_WIDTH+3:0] sum;
    logic [DATA_WIDTH+3:0] mean;

    integer i_unpack, i_mean, i_pack_ff, i_pack_comb;

    // Unpack flat input into array
    always_comb begin
        for (i_unpack = 0; i_unpack < N; i_unpack++) begin
            in_vector[i_unpack] = in_vector_flat[i_unpack*DATA_WIDTH +: DATA_WIDTH];
        end
    end

    // Compute mean and output (stage 1)
    always_ff @(posedge clk) begin
        if (rst) begin
            sum  <= 0;
            mean <= 0;
        end else begin
            sum <= 0;
            for (i_mean = 0; i_mean < N; i_mean++) begin
                sum <= sum + {{4'b0}, in_vector[i_mean]};  // zero-extend to avoid WIDTHEXPAND
            end
            mean <= sum / N;

            // Store original input into output for now (until full normalization is written)
            for (i_pack_ff = 0; i_pack_ff < N; i_pack_ff++) begin
                out_vector[i_pack_ff] <= in_vector[i_pack_ff];  // replace later with normalization
            end
        end
    end

    // Pack output array into flat
    always_comb begin
        for (i_pack_comb = 0; i_pack_comb < N; i_pack_comb++) begin
            out_vector_flat[i_pack_comb*DATA_WIDTH +: DATA_WIDTH] = out_vector[i_pack_comb];
        end
    end

endmodule
