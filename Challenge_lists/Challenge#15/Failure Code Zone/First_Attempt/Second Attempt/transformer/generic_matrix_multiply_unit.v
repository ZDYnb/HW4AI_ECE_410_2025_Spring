// generic_matrix_multiply_unit.v
module generic_matrix_multiply_unit #(
    parameter DATA_WIDTH   = 8,    // Bit-width for elements of input matrices A and B
    parameter ACCUM_WIDTH  = 32,   // Bit-width for elements of output matrix C (matching VMM output)
    parameter M_DIM        = 4,    // Number of rows in Matrix A / Output Matrix C
    parameter K_DIM        = 3,    // Number of columns in Matrix A / Rows in Matrix B
    parameter N_DIM        = 2     // Number of columns in Matrix B / Output Matrix C
) (
    input wire                          clk,
    input wire                          rst_n,

    input wire                          op_start_mm, // Start the matrix multiplication

    input wire signed [DATA_WIDTH-1:0]  matrix_a_in [0:M_DIM-1][0:K_DIM-1],
    input wire signed [DATA_WIDTH-1:0]  matrix_b_in [0:K_DIM-1][0:N_DIM-1],

    output reg signed [ACCUM_WIDTH-1:0] output_matrix_c_out [0:M_DIM-1][0:N_DIM-1],
    output reg                          op_busy_mm,
    output reg                          op_done_mm
);

    // Internal registers to store latched inputs
    reg signed [DATA_WIDTH-1:0]  internal_matrix_a_reg [0:M_DIM-1][0:K_DIM-1];
    reg signed [DATA_WIDTH-1:0]  internal_matrix_b_reg [0:K_DIM-1][0:N_DIM-1];
    // output_matrix_c_out serves as internal storage for the final result

    // Signals for the vector_matrix_multiply_row_unit (vmm_inst) instance
    reg                               vmm_op_start_reg;
    // vmm_input_vector_A will be one row from internal_matrix_a_reg
    reg signed [DATA_WIDTH-1:0]       vmm_input_vector_A_reg [0:K_DIM-1]; 

    wire signed [ACCUM_WIDTH-1:0]     vmm_output_vector_O_wire [0:N_DIM-1];
    wire                              vmm_op_busy_wire;
    wire                              vmm_op_done_wire;

    // Instantiate vector_matrix_multiply_row_unit
    // Its K_DIM will be our K_DIM (cols of A / rows of B)
    // Its N_DIM will be our N_DIM (cols of B / cols of C)
    vector_matrix_multiply_row_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .K_DIM(K_DIM), 
        .N_DIM(N_DIM)
    ) vmm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .op_start(vmm_op_start_reg),
        .input_vector_A(vmm_input_vector_A_reg),
        .weight_matrix_W(internal_matrix_b_reg), // Pass the entire latched matrix B
        .output_vector_O(vmm_output_vector_O_wire),
        .op_busy(vmm_op_busy_wire),
        .op_done(vmm_op_done_wire)
    );

    // FSM State Definitions
    localparam S_IDLE_MM                 = 3'd0;
    localparam S_LATCH_INPUTS_MM         = 3'd1;
    localparam S_SETUP_VMM_FOR_ROW_MM    = 3'd2; // Setup vmm_input_vector_A_reg with current row of A
    localparam S_START_VMM_PULSE_MM      = 3'd3;
    localparam S_WAIT_VMM_DONE_MM        = 3'd4;
    localparam S_STORE_OUTPUT_ROW_MM     = 3'd5; // Store vmm_output_vector_O_wire to output_matrix_c_out
    localparam S_FINAL_DONE_MM           = 3'd6;

    reg [2:0] current_mm_state_reg, next_mm_state_comb; // 3 bits for up to 8 states

    // Counter for rows of Matrix A
    // Needs to count from 0 to M_DIM (to detect completion when it equals M_DIM)
    reg [$clog2(M_DIM+1)-1:0] current_row_m_idx_reg; 

    // For op_start_mm edge detection
    reg op_start_mm_d1;
    wire op_start_mm_posedge = op_start_mm && !op_start_mm_d1;

    // Loop variables for datapath
    integer i, j, k; // For use in for-loops in clocked always block


    // FSM Sequential Part (State Register)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mm_state_reg <= S_IDLE_MM;
            op_start_mm_d1       <= 1'b0;
        end else begin
            current_mm_state_reg <= next_mm_state_comb;
            op_start_mm_d1       <= op_start_mm;
        end
    end

    // FSM Combinational Part (Next State and Output Control)
    always_comb begin
        next_mm_state_comb = current_mm_state_reg; 
        op_busy_mm         = 1'b1; // Default busy unless IDLE or DONE
        op_done_mm         = 1'b0;
        vmm_op_start_reg   = 1'b0; 
        
        case(current_mm_state_reg)
            S_IDLE_MM: begin
                op_busy_mm = 1'b0;
                if (op_start_mm_posedge) begin
                    next_mm_state_comb = S_LATCH_INPUTS_MM;
                end
            end
            S_LATCH_INPUTS_MM: begin
                // Inputs are latched in clocked block; row counter also reset
                next_mm_state_comb = S_SETUP_VMM_FOR_ROW_MM;
            end
            S_SETUP_VMM_FOR_ROW_MM: begin
                // vmm_input_vector_A_reg is set up in clocked block
                if (current_row_m_idx_reg < M_DIM) begin
                    next_mm_state_comb = S_START_VMM_PULSE_MM;
                end else begin // All rows processed
                    next_mm_state_comb = S_FINAL_DONE_MM;
                end
            end
            S_START_VMM_PULSE_MM: begin
                vmm_op_start_reg = 1'b1; // Pulse VMM start
                next_mm_state_comb = S_WAIT_VMM_DONE_MM;
            end
            S_WAIT_VMM_DONE_MM: begin
                vmm_op_start_reg = 1'b0; // De-assert VMM start
                if (vmm_op_done_wire) begin
                    next_mm_state_comb = S_STORE_OUTPUT_ROW_MM;
                end
                // else stay waiting (implicit from default next_mm_state_comb)
            end
            S_STORE_OUTPUT_ROW_MM: begin
                // Output row stored in clocked block; current_row_m_idx_reg incremented
                next_mm_state_comb = S_SETUP_VMM_FOR_ROW_MM; // Go to setup for next row or finish
            end
            S_FINAL_DONE_MM: begin
                op_busy_mm = 1'b0;
                op_done_mm = 1'b1; // Pulse overall done signal
                next_mm_state_comb = S_IDLE_MM;
            end
            default: begin
                next_mm_state_comb = S_IDLE_MM;
                op_busy_mm = 1'b0;
            end
        endcase
    end

    // Datapath Sequential Logic (Registered assignments)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_row_m_idx_reg <= {($clog2(M_DIM+1)){1'b0}};
            // Initialize internal registers and output matrix
            for (i = 0; i < M_DIM; i = i + 1) begin
                for (k = 0; k < K_DIM; k = k + 1) begin
                    internal_matrix_a_reg[i][k] <= 0;
                end
            end
            for (i = 0; i < K_DIM; i = i + 1) begin
                for (j = 0; j < N_DIM; j = j + 1) begin
                    internal_matrix_b_reg[i][j] <= 0;
                end
            end
            for (i = 0; i < M_DIM; i = i + 1) begin
                for (j = 0; j < N_DIM; j = j + 1) begin
                    output_matrix_c_out[i][j] <= 0;
                end
            end
            for (k = 0; k < K_DIM; k = k + 1) begin
                vmm_input_vector_A_reg[k] <= 0;
            end
        end else begin
            // Default holds for registers not explicitly assigned in current state's logic
            current_row_m_idx_reg <= current_row_m_idx_reg;
            // vmm_input_vector_A_reg, internal matrices, output_matrix_c_out hold by default

            if (current_mm_state_reg == S_LATCH_INPUTS_MM) begin
                for (i = 0; i < M_DIM; i = i + 1) begin
                    for (k = 0; k < K_DIM; k = k + 1) begin
                        internal_matrix_a_reg[i][k] <= matrix_a_in[i][k];
                    end
                end
                for (i = 0; i < K_DIM; i = i + 1) begin
                    for (j = 0; j < N_DIM; j = j + 1) begin
                        internal_matrix_b_reg[i][j] <= matrix_b_in[i][j];
                    end
                end
                current_row_m_idx_reg <= {($clog2(M_DIM+1)){1'b0}}; // Reset row counter
            end

            if (current_mm_state_reg == S_SETUP_VMM_FOR_ROW_MM) begin
                if (current_row_m_idx_reg < M_DIM) begin // Ensure index is valid
                    for (k = 0; k < K_DIM; k = k + 1) begin
                        vmm_input_vector_A_reg[k] <= internal_matrix_a_reg[current_row_m_idx_reg][k];
                    end
                end
            end

            if (current_mm_state_reg == S_STORE_OUTPUT_ROW_MM) begin
                if (current_row_m_idx_reg < M_DIM) begin // Ensure index is valid before writing
                    for (j = 0; j < N_DIM; j = j + 1) begin
                        output_matrix_c_out[current_row_m_idx_reg][j] <= vmm_output_vector_O_wire[j];
                    end
                end
                current_row_m_idx_reg <= current_row_m_idx_reg + 1; // Increment for next row
            end
        end
    end

endmodule
