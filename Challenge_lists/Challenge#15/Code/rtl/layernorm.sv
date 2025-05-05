
module layernorm #(
    parameter N = 4,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic [DATA_WIDTH-1:0] input_vector [0:N-1],
    output logic [DATA_WIDTH-1:0] normalized_vector [0:N-1]
);

    logic [DATA_WIDTH+3:0] mean;
    logic [DATA_WIDTH+3:0] var;
    logic [DATA_WIDTH+3:0] temp_sub [0:N-1];
    logic [DATA_WIDTH+3:0] temp_sq  [0:N-1];

    integer i;

    always_ff @(posedge clk) begin
        // Mean
        mean = 0;
        for (i = 0; i < N; i++)
            mean += input_vector[i];
        mean = mean / N;

        // Variance
        for (i = 0; i < N; i++) begin
            temp_sub[i] = input_vector[i] - mean;
            temp_sq[i]  = temp_sub[i] * temp_sub[i];
        end

        var = 0;
        for (i = 0; i < N; i++)
            var += temp_sq[i];
        var = var / N;

        // Normalization
        for (i = 0; i < N; i++)
            normalized_vector[i] = temp_sub[i] / (var[DATA_WIDTH-1:0] + 1); // approximate
    end

endmodule

