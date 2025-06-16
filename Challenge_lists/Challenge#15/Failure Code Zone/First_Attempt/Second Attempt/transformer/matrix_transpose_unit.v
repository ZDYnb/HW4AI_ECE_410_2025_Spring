// matrix_transpose_unit.v
module matrix_transpose_unit #(
    parameter DATA_WIDTH = 8,
    parameter M_ROWS     = 2, // Number of rows in input matrix A
    parameter N_COLS     = 3  // Number of columns in input matrix A
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          op_start_transpose,

    input wire signed [DATA_WIDTH-1:0]  input_matrix [0:M_ROWS-1][0:N_COLS-1],

    output reg signed [DATA_WIDTH-1:0]  output_matrix_transposed [0:N_COLS-1][0:M_ROWS-1],
    output reg                          op_busy_transpose,
    output reg                          op_done_transpose
);

    // Internal register to store latched input matrix
    reg signed [DATA_WIDTH-1:0]  internal_input_matrix_reg [0:M_ROWS-1][0:N_COLS-1];

    // FSM State Definitions
    localparam S_IDLE             = 2'b00;
    localparam S_LATCH_INPUT      = 2'b01;
    localparam S_TRANSPOSE_OUTPUT = 2'b10; // Perform transpose and make output available
    localparam S_DONE             = 2'b11;

    reg [1:0] current_state_reg, next_state_comb;

    // For op_start_transpose edge detection
    reg op_start_d1;
    wire op_start_posedge = op_start_transpose && !op_start_d1;

    // Loop variables for datapath (SystemVerilog allows 'int' in for loops with -sv)
    integer r, c; // Or declare as: int r, c;

    // FSM Sequential Part (State Register)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= S_IDLE;
            op_start_d1       <= 1'b0;
        end else begin
            current_state_reg <= next_state_comb;
            op_start_d1       <= op_start_transpose;
        end
    end

    // FSM Combinational Part (Next State and Output Logic)
    always_comb begin
        next_state_comb   = current_state_reg; // Default: stay in current state
        op_busy_transpose = 1'b1; // Default busy unless IDLE or DONE
        op_done_transpose = 1'b0;

        case(current_state_reg)
            S_IDLE: begin
                op_busy_transpose = 1'b0;
                if (op_start_posedge) begin
                    next_state_comb = S_LATCH_INPUT;
                end
            end
            S_LATCH_INPUT: begin
                // Input is latched in the clocked block based on this state
                next_state_comb = S_TRANSPOSE_OUTPUT;
            end
            S_TRANSPOSE_OUTPUT: begin
                // Transpose occurs in clocked block; output becomes available
                next_state_comb = S_DONE;
            end
            S_DONE: begin
                op_busy_transpose = 1'b0;
                op_done_transpose = 1'b1; // Pulse done signal
                next_state_comb = S_IDLE;
            end
            default: begin
                next_state_comb   = S_IDLE;
                op_busy_transpose = 1'b0;
            end
        endcase
    end

    // Datapath Sequential Logic (Registered assignments)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal matrix and output matrix
            for (r = 0; r < M_ROWS; r = r + 1) begin
                for (c = 0; c < N_COLS; c = c + 1) begin
                    internal_input_matrix_reg[r][c] <= 0;
                end
            end
            for (r = 0; r < N_COLS; r = r + 1) begin // Note: Transposed dimensions for output
                for (c = 0; c < M_ROWS; c = c + 1) begin
                    output_matrix_transposed[r][c] <= 0;
                end
            end
        end else begin
            // Default hold for output_matrix_transposed (unless assigned in S_TRANSPOSE_OUTPUT)
            // This explicit hold might be needed if not all elements are assigned every cycle in S_TRANSPOSE_OUTPUT
            // (though in this design, they are).
            for (r = 0; r < N_COLS; r = r + 1) begin
                for (c = 0; c < M_ROWS; c = c + 1) begin
                    output_matrix_transposed[r][c] <= output_matrix_transposed[r][c];
                end
            end

            if (current_state_reg == S_LATCH_INPUT) begin
                for (r = 0; r < M_ROWS; r = r + 1) begin
                    for (c = 0; c < N_COLS; c = c + 1) begin
                        internal_input_matrix_reg[r][c] <= input_matrix[r][c];
                    end
                end
            end

            if (current_state_reg == S_TRANSPOSE_OUTPUT) begin
                for (r = 0; r < M_ROWS; r = r + 1) begin
                    for (c = 0; c < N_COLS; c = c + 1) begin
                        output_matrix_transposed[c][r] <= internal_input_matrix_reg[r][c];
                    end
                end
            end
        end
    end

endmodule

