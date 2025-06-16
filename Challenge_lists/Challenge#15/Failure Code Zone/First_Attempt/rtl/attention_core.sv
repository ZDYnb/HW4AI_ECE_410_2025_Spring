module attention_core #(
    parameter N = 4,
    parameter DW = 16  // Q8.8
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [DW-1:0] q[N],
    input  logic signed [DW-1:0] k[N],
    input  logic signed [DW-1:0] v[N],

    output logic done,
    output logic signed [DW-1:0] y  // final attention output
);

    // Wires
    logic signed [DW-1:0] qk_dot;
    logic signed [DW-1:0] softmax_out[N];
    logic started;

    // FSM
    typedef enum logic [1:0] {
        IDLE, COMPUTE, DONE
    } state_t;
    state_t state;

    // Dot product
    dot_product #(.N(N), .WIDTH(DW)) dot_inst (
        .a(q),
        .b(k),
        .result(qk_dot)
    );


    // Softmax
    logic signed [DW-1:0] qk_vector[N];  // broadcast dot product to N inputs
    always_comb begin
        for (int i = 0; i < N; i++) begin
            qk_vector[i] = qk_dot;
        end
    end

    softmax #(.N(N), .DW(DW)) softmax_inst (
        .x(qk_vector),
        .y(softmax_out)
    );

    // Weighted sum
    attention_apply #(.N(N), .DW(DW)) apply_inst (
        .weights(softmax_out),
        .v(v),
        .out(y)
    );

    // Control
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start)
                        state <= COMPUTE;
                end
                COMPUTE: begin
                    state <= DONE;
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
