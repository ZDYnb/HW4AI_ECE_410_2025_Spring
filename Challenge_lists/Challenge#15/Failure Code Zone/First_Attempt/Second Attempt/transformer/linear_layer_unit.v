
// linear_layer_unit.v
module linear_layer_unit #(
    parameter DATA_WIDTH   = 8,
    parameter ACCUM_WIDTH  = 32,
    parameter M_ROWS       = 1, // Number of rows in input activation matrix
    parameter K_COLS       = 2, // Number of cols in input activation / rows in weight matrix
    parameter N_COLS       = 2  // Number of cols in weight matrix / output matrix / bias length
) (
    input wire                          clk,
    input wire                          rst_n,

    input wire                          op_start_ll,

    input wire signed [DATA_WIDTH-1:0]  input_activation_matrix [0:M_ROWS-1][0:K_COLS-1],
    input wire signed [DATA_WIDTH-1:0]  weight_matrix [0:K_COLS-1][0:N_COLS-1],
    input wire signed [ACCUM_WIDTH-1:0] bias_vector [0:N_COLS-1],

    output reg signed [ACCUM_WIDTH-1:0] output_matrix [0:M_ROWS-1][0:N_COLS-1],
    output reg                          op_busy_ll,
    output reg                          op_done_ll
);

    // Internal registers to store latched inputs
    reg signed [DATA_WIDTH-1:0]  internal_activation_matrix_reg [0:M_ROWS-1][0:K_COLS-1];
    reg signed [DATA_WIDTH-1:0]  internal_weight_matrix_reg [0:K_COLS-1][0:N_COLS-1];
    reg signed [ACCUM_WIDTH-1:0] internal_bias_vector_reg [0:N_COLS-1];

    // Signals for VMM (Vector Matrix Multiply Row unit) instance
    reg                               vmm_op_start_reg;
    reg signed [DATA_WIDTH-1:0]       vmm_input_vector_A_reg [0:K_COLS-1]; 

    wire signed [ACCUM_WIDTH-1:0]     vmm_output_vector_O_wire [0:N_COLS-1];
    wire                              vmm_op_busy_wire;
    wire                              vmm_op_done_wire;

    // Instantiate vector_matrix_multiply_row_unit
    vector_matrix_multiply_row_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .K_DIM(K_COLS), 
        .N_DIM(N_COLS)
    ) vmm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .op_start(vmm_op_start_reg),
        .input_vector_A(vmm_input_vector_A_reg),
        .weight_matrix_W(internal_weight_matrix_reg), 
        .output_vector_O(vmm_output_vector_O_wire),
        .op_busy(vmm_op_busy_wire),
        .op_done(vmm_op_done_wire)
    );

    // FSM State Definitions
    localparam S_IDLE_LL                 = 4'd0;
    localparam S_LATCH_INPUTS_LL         = 4'd1;
    localparam S_SETUP_VMM_FOR_ROW_LL    = 4'd2;
    localparam S_START_VMM_PULSE_LL      = 4'd3;
    localparam S_WAIT_VMM_DONE_LL        = 4'd4;
    localparam S_PROCESS_VMM_OUTPUT_LL   = 4'd5;
    // S_CHECK_ALL_ROWS_DONE_LL is effectively merged into S_PROCESS_VMM_OUTPUT_LL's transition
    localparam S_FINAL_DONE_LL           = 4'd6; // Adjusted state values

    reg [2:0] current_state_ll_reg, next_state_ll_comb; // 3 bits for up to 8 states

    // Counter for input activation matrix rows
    reg [$clog2(M_ROWS+1)-1:0] current_row_m_idx_reg; // Counts 0 to M_ROWS

    // Loop variables for use in clocked always block
    integer i_loop, j_loop, m_loop;


    // FSM Sequential Logic (State Register)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_ll_reg <= S_IDLE_LL;
        end else begin
            current_state_ll_reg <= next_state_ll_comb;
        end
    end

    // FSM Combinational Logic (Next State and Output Control)
    always_comb begin
        next_state_ll_comb = current_state_ll_reg; // Default: stay in current state
        op_busy_ll = (current_state_ll_reg != S_IDLE_LL && current_state_ll_reg != S_FINAL_DONE_LL);
        op_done_ll = (current_state_ll_reg == S_FINAL_DONE_LL);
        vmm_op_start_reg = 1'b0; // Default VMM start to low

        case(current_state_ll_reg)
            S_IDLE_LL: begin
                if (op_start_ll) begin
                    next_state_ll_comb = S_LATCH_INPUTS_LL;
                end
            end
            S_LATCH_INPUTS_LL: begin
                // Datapath latches inputs and resets current_row_m_idx_reg
                next_state_ll_comb = S_SETUP_VMM_FOR_ROW_LL;
            end
            S_SETUP_VMM_FOR_ROW_LL: begin
                // Datapath sets up vmm_input_vector_A_reg in this state
                if (current_row_m_idx_reg < M_ROWS) begin
                    next_state_ll_comb = S_START_VMM_PULSE_LL;
                end else begin // All rows processed
                    next_state_ll_comb = S_FINAL_DONE_LL;
                end
            end
            S_START_VMM_PULSE_LL: begin
                vmm_op_start_reg = 1'b1; // Pulse VMM start
                next_state_ll_comb = S_WAIT_VMM_DONE_LL;
            end
            S_WAIT_VMM_DONE_LL: begin
                vmm_op_start_reg = 1'b0; // De-assert VMM start
                if (vmm_op_done_wire) begin // VMM finished processing one row
                    next_state_ll_comb = S_PROCESS_VMM_OUTPUT_LL;
                end else begin
                    next_state_ll_comb = S_WAIT_VMM_DONE_LL; // Keep waiting
                end
            end
            S_PROCESS_VMM_OUTPUT_LL: begin
                // Datapath performs bias addition, stores output, and increments current_row_m_idx_reg
                next_state_ll_comb = S_SETUP_VMM_FOR_ROW_LL; // Check for next row
            end
            S_FINAL_DONE_LL: begin
                // op_done_ll is asserted by default based on this state
                next_state_ll_comb = S_IDLE_LL;
            end
            default: begin
                next_state_ll_comb = S_IDLE_LL;
            end
        endcase
    end

    // Datapath Sequential Logic (Registered assignments)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_row_m_idx_reg <= {($clog2(M_ROWS+1)){1'b0}};
            // Initialize internal registers and output matrix
            for (m_loop = 0; m_loop < M_ROWS; m_loop = m_loop + 1) begin
                for (i_loop = 0; i_loop < K_COLS; i_loop = i_loop + 1) begin
                    internal_activation_matrix_reg[m_loop][i_loop] <= 0;
                end
                for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                    output_matrix[m_loop][j_loop] <= 0;
                end
            end
            for (i_loop = 0; i_loop < K_COLS; i_loop = i_loop + 1) begin
                vmm_input_vector_A_reg[i_loop] <= 0; // Initialize VMM input buffer
                for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                    internal_weight_matrix_reg[i_loop][j_loop] <= 0;
                end
            end
            for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                internal_bias_vector_reg[j_loop] <= 0;
            end
        end else begin
            // Default holds for most registers unless explicitly changed by FSM state
            current_row_m_idx_reg <= current_row_m_idx_reg; 
            // vmm_input_vector_A_reg holds by default

            if (current_state_ll_reg == S_LATCH_INPUTS_LL) begin
                for (m_loop = 0; m_loop < M_ROWS; m_loop = m_loop + 1) begin
                    for (i_loop = 0; i_loop < K_COLS; i_loop = i_loop + 1) begin
                        internal_activation_matrix_reg[m_loop][i_loop] <= input_activation_matrix[m_loop][i_loop];
                    end
                end
                for (i_loop = 0; i_loop < K_COLS; i_loop = i_loop + 1) begin
                    for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                        internal_weight_matrix_reg[i_loop][j_loop] <= weight_matrix[i_loop][j_loop];
                    end
                end
                for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                    internal_bias_vector_reg[j_loop] <= bias_vector[j_loop];
                end
                current_row_m_idx_reg <= {($clog2(M_ROWS+1)){1'b0}}; // Reset row counter
            end

            if (current_state_ll_reg == S_SETUP_VMM_FOR_ROW_LL) begin
                if (current_row_m_idx_reg < M_ROWS) begin // Ensure index is valid
                    for (i_loop = 0; i_loop < K_COLS; i_loop = i_loop + 1) begin
                        vmm_input_vector_A_reg[i_loop] <= internal_activation_matrix_reg[current_row_m_idx_reg][i_loop];
                    end
                end
            end

            if (current_state_ll_reg == S_PROCESS_VMM_OUTPUT_LL) begin
                // Perform bias addition and store the result for the current row
                if (current_row_m_idx_reg < M_ROWS) begin // Ensure index is valid
                    for (j_loop = 0; j_loop < N_COLS; j_loop = j_loop + 1) begin
                        output_matrix[current_row_m_idx_reg][j_loop] <= vmm_output_vector_O_wire[j_loop] + internal_bias_vector_reg[j_loop];
                    end
                end
                current_row_m_idx_reg <= current_row_m_idx_reg + 1; // Increment for next row
            end
        end
    end

endmodule
