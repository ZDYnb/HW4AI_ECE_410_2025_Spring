
module lif_neuron #(
    parameter WIDTH      = 16,          // Q1.15 width
    parameter LAMBDA     = 16'd32768,   // 0.5  (Q1.15)
    parameter THRESHOLD  = 16'd49152    // 1.5  (Q1.15)
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  in_bit,          // binary input
    output logic                  spike,           // cycle pulse
    output logic [WIDTH-1:0]      potential        // membrane potential
);

    logic [WIDTH-1:0]  input_fixed;                // 1.0 or 0.0
    logic [31:0]       mult_result;                // Q2.30 product
    logic [WIDTH:0]    mult_scaled;                // one bit wider (Q1.15)
    logic [WIDTH:0]    next_potential;             // one bit wider
    logic              spike_next;                 // comb comparator

    always_comb begin
        input_fixed   = {in_bit, 15'b0};
        mult_result   = potential * LAMBDA;
        mult_scaled   = mult_result[31:16];
        next_potential= mult_scaled + input_fixed;
        spike_next    = (next_potential >= THRESHOLD);
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            potential <= '0;
            spike     <= 1'b0;
        end else begin
            spike <= spike_next;
            if (spike_next)
                potential <= '0;
            else
                potential <= next_potential[WIDTH-1:0]; // keep lower 16 bits
        end
    end
endmodule
                               