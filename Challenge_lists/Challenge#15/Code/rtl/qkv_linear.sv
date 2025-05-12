module qkv_linear #(
    parameter N = 4,                  // Vector length
    parameter WIDTH = 16              // Bit width for fixed-point
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [WIDTH-1:0] x [N],   // Input vector

    output logic done,
    output logic signed [WIDTH-1:0] q [N],   // Output vector Q
    output logic signed [WIDTH-1:0] k [N],   // Output vector K
    output logic signed [WIDTH-1:0] v [N]    // Output vector V
);

    // Accumulators
    logic signed [WIDTH-1:0] q_acc [N];
    logic signed [WIDTH-1:0] k_acc [N];
    logic signed [WIDTH-1:0] v_acc [N];

    // Example hardcoded weights
    logic signed [WIDTH-1:0] WQ [N][N];
    logic signed [WIDTH-1:0] WK [N][N];
    logic signed [WIDTH-1:0] WV [N][N];

    initial begin
        WQ = '{
            '{16'sd1, 16'sd2, 16'sd3, 16'sd4},
            '{16'sd4, 16'sd3, 16'sd2, 16'sd1},
            '{16'sd1, -16'sd1, 16'sd1, -16'sd1},
            '{16'sd2, 16'sd2, 16'sd2, 16'sd2}
        };
        WK = '{
            '{16'sd1, 0, 0, 0},
            '{0, 16'sd1, 0, 0},
            '{0, 0, 16'sd1, 0},
            '{0, 0, 0, 16'sd1}
        };
        WV = '{
            '{16'sd2, 16'sd2, 16'sd2, 16'sd2},
            '{-16'sd2, -16'sd2, -16'sd2, -16'sd2},
            '{16'sd1, 0, -16'sd1, 0},
            '{0, 16'sd1, 0, -16'sd1}
        };
    end

    typedef enum logic [1:0] {IDLE, COMPUTE, WRITE_OUT} state_t;
    state_t state;

    integer i, j;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        for (i = 0; i < N; i++) begin
                            q_acc[i] = 0;
                            k_acc[i] = 0;
                            v_acc[i] = 0;
                            for (j = 0; j < N; j++) begin
                                q_acc[i] += x[j] * WQ[i][j];
                                k_acc[i] += x[j] * WK[i][j];
                                v_acc[i] += x[j] * WV[i][j];
                            end
                        end
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    for (i = 0; i < N; i++) begin
                        q[i] <= q_acc[i];
                        k[i] <= k_acc[i];
                        v[i] <= v_acc[i];
                    end
                    done <= 1;
                    state <= WRITE_OUT;
                end

                WRITE_OUT: begin
                    done <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
