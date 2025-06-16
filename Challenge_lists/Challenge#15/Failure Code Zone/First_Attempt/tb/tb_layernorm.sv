
`timescale 1ns/1ps

module tb_layernorm;

    parameter N = 4;
    parameter DATA_WIDTH = 8;

    logic clk;
    logic [DATA_WIDTH-1:0] input_vector [0:N-1];
    logic [DATA_WIDTH-1:0] normalized_vector [0:N-1];

    // Instantiate DUT
    layernorm #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .input_vector(input_vector),
        .normalized_vector(normalized_vector)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;

        // Provide input vector
        input_vector[0] = 8'd10;
        input_vector[1] = 8'd20;
        input_vector[2] = 8'd30;
        input_vector[3] = 8'd40;

        // Wait for one clock cycle
        #10;

        $display("Input:      %0d %0d %0d %0d",
            input_vector[0], input_vector[1], input_vector[2], input_vector[3]);
        $display("Normalized: %0d %0d %0d %0d",
            normalized_vector[0], normalized_vector[1], normalized_vector[2], normalized_vector[3]);

        $finish;
    end

endmodule

