module sqrt_lut #(
    parameter WIDTH = 16,
    parameter ADDR_WIDTH = 8,
    parameter DEFAULT = 16'hFFFF  // fallback value for out-of-range
)(
    input  logic [WIDTH-1:0] in_q88,
    output logic [WIDTH-1:0] out_q88
);

    // LUT for sqrt in Q8.8 format
    logic [WIDTH-1:0] lut [0:(1 << ADDR_WIDTH)-1];

    // Load hex file on simulation/synthesis
    initial begin
        $readmemh("sqrt_q88.hex", lut);
    end

    // Extract top 8 bits as index
    logic [ADDR_WIDTH-1:0] index;
    assign index = in_q88[15:8];

    // Protect against overflow or undefined LUT index
    always_comb begin
        if (index >= (1 << ADDR_WIDTH))
            out_q88 = DEFAULT;  // fallback value
        else
            out_q88 = lut[index];
    end

endmodule
