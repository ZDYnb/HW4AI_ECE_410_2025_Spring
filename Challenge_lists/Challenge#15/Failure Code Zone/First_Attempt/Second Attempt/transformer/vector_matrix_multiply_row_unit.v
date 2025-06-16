// vector_matrix_multiply_row_unit.v
module vector_matrix_multiply_row_unit #(
    parameter DATA_WIDTH   = 8,    // Width of individual elements
    parameter ACCUM_WIDTH  = 32,   // Width of dot product results (and output vector elements)
    parameter K_DIM        = 4,    // Length of input vector A, and rows in Matrix W
    parameter N_DIM        = 3     // Number of columns in Matrix W, and length of output vector O
) (
    input wire                          clk,
    input wire                          rst_n,

    input wire                          op_start, // Start the vector-matrix multiplication

    input wire signed [DATA_WIDTH-1:0]  input_vector_A [0:K_DIM-1],
    input wire signed [DATA_WIDTH-1:0]  weight_matrix_W [0:K_DIM-1][0:N_DIM-1], // [row][col]

    output reg signed [ACCUM_WIDTH-1:0] output_vector_O [0:N_DIM-1], // Parallel output
    output reg                          op_busy, 
    output reg                          op_done      
);

    // Internal registers to store latched inputs
    reg signed [DATA_WIDTH-1:0]  internal_A_reg [0:K_DIM-1];
    reg signed [DATA_WIDTH-1:0]  internal_W_reg [0:K_DIM-1][0:N_DIM-1];

    // Signals for controlling and interfacing with the dot_product_unit
    reg                               dp_start_pulse_reg; 
    reg signed [DATA_WIDTH-1:0]       dp_vec_a_element_latched_reg; 
    reg signed [DATA_WIDTH-1:0]       dp_vec_b_element_latched_reg; 

    wire signed [ACCUM_WIDTH-1:0]     dp_result_out_wire;
    wire                              dp_result_valid_wire;
    wire                              dp_busy_wire;
    wire                              dp_request_next_elements_wire;

    integer k_loop, r_loop, c_loop, n_loop; 

    // Instantiate the dot_product_unit
    dot_product_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(dp_start_pulse_reg),
        .vector_length(K_DIM), 
        .vec_a_element_in(dp_vec_a_element_latched_reg), 
        .vec_b_element_in(dp_vec_b_element_latched_reg), 
        .result_out(dp_result_out_wire),
        .result_valid(dp_result_valid_wire),
        .busy(dp_busy_wire),
        .request_next_elements(dp_request_next_elements_wire)
    );

    // FSM State Definitions
    localparam S_IDLE             = 4'd0;
    localparam S_LATCH_INPUTS     = 4'd1;
    localparam S_INIT_DP_COL      = 4'd2; 
    localparam S_START_DP         = 4'd3; 
    localparam S_FEED_DP_ELEMENTS = 4'd4; 
    localparam S_STORE_DP_RESULT  = 4'd5; 
    localparam S_ALL_COLS_DONE    = 4'd6; 

    reg [3:0] current_state_reg, next_state_comb;

    // Counters for loops - CORRECTED WIDTHS
    reg [$clog2(N_DIM+1)-1:0]    col_idx_j_reg;   // Needs to hold value N_DIM for termination check
    reg [$clog2(K_DIM+1)-1:0]    row_idx_i_reg;   // Needs to hold value K_DIM for termination check


    // FSM Sequential Part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= S_IDLE;
        end else begin
            current_state_reg <= next_state_comb;
        end
    end

    // FSM Combinational Part (and output logic)
    always_comb begin
        next_state_comb = current_state_reg; 
        op_busy = (current_state_reg != S_IDLE && current_state_reg != S_ALL_COLS_DONE);
        op_done = (current_state_reg == S_ALL_COLS_DONE);
        dp_start_pulse_reg = 1'b0; 
        
        case (current_state_reg)
            S_IDLE: begin
                if (op_start) begin
                    next_state_comb = S_LATCH_INPUTS;
                end
            end

            S_LATCH_INPUTS: begin
                next_state_comb = S_INIT_DP_COL;
            end

            S_INIT_DP_COL: begin 
                if (col_idx_j_reg < N_DIM) begin // Compares value up to N_DIM-1 with N_DIM
                    next_state_comb = S_START_DP;
                end else begin // col_idx_j_reg == N_DIM
                    next_state_comb = S_ALL_COLS_DONE;
                end
            end
            
            S_START_DP: begin 
                dp_start_pulse_reg = 1'b1; 
                next_state_comb = S_FEED_DP_ELEMENTS;
            end

            S_FEED_DP_ELEMENTS: begin
                dp_start_pulse_reg = 1'b0; 
                if (dp_result_valid_wire) begin 
                    next_state_comb = S_STORE_DP_RESULT;
                end else if (dp_busy_wire || dp_request_next_elements_wire) begin 
                    next_state_comb = S_FEED_DP_ELEMENTS;
                end else if (!dp_busy_wire && !dp_result_valid_wire && !dp_request_next_elements_wire) begin
                    next_state_comb = S_FEED_DP_ELEMENTS; 
                end
            end

            S_STORE_DP_RESULT: begin 
                next_state_comb = S_INIT_DP_COL; 
            end

            S_ALL_COLS_DONE: begin
                next_state_comb = S_IDLE;
            end
            default: next_state_comb = S_IDLE;
        endcase
    end

    // Datapath Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_idx_j_reg <= {($clog2(N_DIM+1)){1'b0}}; // Corrected width for reset
            row_idx_i_reg <= {($clog2(K_DIM+1)){1'b0}}; // Corrected width for reset
            dp_vec_a_element_latched_reg <= 0; 
            dp_vec_b_element_latched_reg <= 0; 
            
            k_loop = 0;
            while (k_loop < K_DIM) begin
                internal_A_reg[k_loop] <= 0;
                k_loop = k_loop + 1;
            end

            r_loop = 0;
            while (r_loop < K_DIM) begin
                c_loop = 0;
                while (c_loop < N_DIM) begin
                    internal_W_reg[r_loop][c_loop] <= 0;
                    c_loop = c_loop + 1;
                end
                r_loop = r_loop + 1;
            end

            n_loop = 0;
            while (n_loop < N_DIM) begin
                output_vector_O[n_loop] <= 0;
                n_loop = n_loop + 1;
            end
        end else begin
            // Default assignments to hold values unless explicitly changed
            col_idx_j_reg <= col_idx_j_reg;
            row_idx_i_reg <= row_idx_i_reg;
            dp_vec_a_element_latched_reg <= dp_vec_a_element_latched_reg; 
            dp_vec_b_element_latched_reg <= dp_vec_b_element_latched_reg; 


            if (current_state_reg == S_IDLE && next_state_comb == S_LATCH_INPUTS) begin
                k_loop = 0;
                while (k_loop < K_DIM) begin
                    internal_A_reg[k_loop] <= input_vector_A[k_loop];
                    k_loop = k_loop + 1;
                end

                r_loop = 0;
                while (r_loop < K_DIM) begin
                    c_loop = 0;
                    while (c_loop < N_DIM) begin
                        internal_W_reg[r_loop][c_loop] <= weight_matrix_W[r_loop][c_loop];
                        c_loop = c_loop + 1;
                    end
                    r_loop = r_loop + 1;
                end
                col_idx_j_reg <= {($clog2(N_DIM+1)){1'b0}}; // Corrected width for reset
                row_idx_i_reg <= {($clog2(K_DIM+1)){1'b0}}; // Corrected width for reset
            end

            // Reset row_idx_i_reg when starting a new dot product (new column)
            if (next_state_comb == S_INIT_DP_COL && 
                (current_state_reg == S_LATCH_INPUTS || current_state_reg == S_STORE_DP_RESULT)) begin
                 row_idx_i_reg <= {($clog2(K_DIM+1)){1'b0}}; // Corrected width for reset
            end
            
            // Latch elements for dp_inst when it requests, THEN increment row_idx_i_reg for the NEXT element
            if (current_state_reg == S_FEED_DP_ELEMENTS && dp_request_next_elements_wire && row_idx_i_reg < K_DIM) begin
                dp_vec_a_element_latched_reg <= internal_A_reg[row_idx_i_reg];
                dp_vec_b_element_latched_reg <= internal_W_reg[row_idx_i_reg][col_idx_j_reg];
                row_idx_i_reg <= row_idx_i_reg + 1;
            end

            // Store result and advance column index
            if (current_state_reg == S_STORE_DP_RESULT) begin 
                output_vector_O[col_idx_j_reg] <= dp_result_out_wire;
                col_idx_j_reg <= col_idx_j_reg + 1;
            end
        end
    end

    // VMM's own DEBUG DISPLAY BLOCK
    always @(posedge clk) begin
        if(rst_n && (op_busy || op_start || op_done || current_state_reg != S_IDLE)) begin
            $display("[%0t VMM_DUT] State: %s, col_j: %d (N_DIM:%d), row_i: %d (K_DIM:%d) | dp_start: %b, dp_req: %b, dp_busy: %b, dp_valid: %b, dp_res_out: %d | VMM_op_done: %b, VMM_op_busy: %b",
                $time,
                (current_state_reg == S_IDLE)            ? "IDLE" :
                (current_state_reg == S_LATCH_INPUTS)    ? "LATCH_INPUTS" :
                (current_state_reg == S_INIT_DP_COL)     ? "INIT_DP_COL" :
                (current_state_reg == S_START_DP)        ? "START_DP" :
                (current_state_reg == S_FEED_DP_ELEMENTS)? "FEED_DP_ELEMENTS" :
                (current_state_reg == S_STORE_DP_RESULT) ? "STORE_DP_RESULT" :
                (current_state_reg == S_ALL_COLS_DONE)   ? "ALL_COLS_DONE" : "UNKNOWN_VMM_STATE",
                col_idx_j_reg, N_DIM, row_idx_i_reg, K_DIM,
                dp_start_pulse_reg, dp_request_next_elements_wire, dp_busy_wire, dp_result_valid_wire, dp_result_out_wire,
                op_done, op_busy
            );
        end
    end

endmodule

