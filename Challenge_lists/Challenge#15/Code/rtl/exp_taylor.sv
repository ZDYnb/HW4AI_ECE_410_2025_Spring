module exp_taylor #(
    parameter WIDTH = 16  // Q8.8 format
)(
    input  logic signed [WIDTH-1:0] x_q88,
    output logic signed [WIDTH-1:0] y_q88
);

    // Intermediate widened signals
    logic signed [2*WIDTH-1:0] x1, x2, x3, x4;
    logic signed [2*WIDTH-1:0] term1, term2, term3, term4;
    logic signed [2*WIDTH-1:0] sum;

    // Clamping bounds
    localparam signed [WIDTH-1:0] X_MIN = 16'shFF00;  // -1.0
    localparam signed [WIDTH-1:0] X_MAX = 16'sh0180;  // +1.5
    localparam signed [WIDTH-1:0] Y_MIN = 16'sh0001;  // ~0
    localparam signed [WIDTH-1:0] Y_MAX = 16'shFFFF;  // max Q8.8

    always_comb begin
        // Default assignments to avoid latch inference
        x1 = 0;
        x2 = 0;
        x3 = 0;
        x4 = 0;
        term1 = 0;
        term2 = 0;
        term3 = 0;
        term4 = 0;
        sum = 0;
        y_q88 = 0;

        if (x_q88 < X_MIN) begin
            y_q88 = Y_MIN;
        end else if (x_q88 > X_MAX) begin
            y_q88 = Y_MAX;
        end else begin
            // Compute terms of exp(x)
            x1 = x_q88;
            x2 = (x1 * x1) >>> 8;
            x3 = (x2 * x1) >>> 8;
            x4 = (x3 * x1) >>> 8;

            term1 = x1;
            term2 = x2 / 2;
            term3 = x3 / 6;
            term4 = x4 / 24;

            sum = 256 + term1 + term2 + term3 + term4;

            y_q88 = sum[WIDTH-1:0];
        end
    end

endmodule

