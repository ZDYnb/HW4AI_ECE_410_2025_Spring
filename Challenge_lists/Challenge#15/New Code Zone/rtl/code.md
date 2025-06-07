
// mac_unit.v
module mac_unit #(
    parameter DATA_A_WIDTH = 8,
    parameter DATA_B_WIDTH = 8,
    parameter ACCUM_WIDTH  = 32
) (
    input wire                      clk,
    input wire                      rst_n,
    input wire                      en,

    input wire signed [DATA_A_WIDTH-1:0] data_a,
    input wire signed [DATA_B_WIDTH-1:0] data_b,
    input wire signed [ACCUM_WIDTH-1:0]  accum_in, // For iterative accumulation

    output reg signed [ACCUM_WIDTH-1:0]  accum_out
);

    // Intermediate register for the product
    // Product of two N-bit numbers can be 2N bits.
    localparam PRODUCT_WIDTH = DATA_A_WIDTH + DATA_B_WIDTH;
    reg signed [PRODUCT_WIDTH-1:0] product_reg;
    
    // Registers for inputs to align with pipeline stages if accum_in changes
    reg signed [DATA_A_WIDTH-1:0] data_a_reg;
    reg signed [DATA_B_WIDTH-1:0] data_b_reg;
    reg signed [ACCUM_WIDTH-1:0]  accum_in_reg;
    reg                           en_reg_stage1; // Enable for multiplication stage
    reg                           en_reg_stage2; // Enable for accumulation stage

    // Stage 1: Multiplication and input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg    <= {DATA_A_WIDTH{1'b0}};
            data_b_reg    <= {DATA_B_WIDTH{1'b0}};
            product_reg   <= {PRODUCT_WIDTH{1'b0}};
            accum_in_reg  <= {ACCUM_WIDTH{1'b0}};
            en_reg_stage1 <= 1'b0;
            en_reg_stage2 <= 1'b0;
        end else begin
            if (en) begin // Capture inputs when top-level enable is high
                data_a_reg   <= data_a;
                data_b_reg   <= data_b;
                accum_in_reg <= accum_in; // Capture accum_in for the next stage
            end
            // The multiplication happens combinationally based on registered inputs,
            // or directly if we want a more direct path.
            // For a clear pipeline stage, register inputs then multiply.
            // So, product_reg is updated based on *previous* cycle's data_a & data_b if en was high.
            if (en_reg_stage1) begin // If previous cycle's enable was high
                 product_reg <= data_a_reg * data_b_reg;
            end else begin
                // Optional: clear product_reg if not enabled to avoid propagating old values,
                // or let it hold. For MAC, typically new product replaces old.
                // If en_reg_stage1 is low, it implies data_a_reg and data_b_reg were not validly loaded
                // for this specific operation, so the product might not be meaningful.
                // However, the structure `accum_out = accum_in + product` means `accum_in` can pass through if product is 0.
            end
            
            // Manage enables for pipeline flow
            en_reg_stage1 <= en;         // en for current cycle becomes en_reg_stage1 for next
            en_reg_stage2 <= en_reg_stage1; // en_reg_stage1 for current cycle becomes en_reg_stage2 for next
        end
    end

    // Stage 2: Addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_out <= {ACCUM_WIDTH{1'b0}};
        end else begin
            if (en_reg_stage2) begin // Use the enable from the previous stage
                // The product_reg was calculated in the previous cycle from data_a_reg * data_b_reg
                // The accum_in_reg was also captured from the input `accum_in` in the previous cycle
                accum_out <= accum_in_reg + product_reg;
            end else begin
                // Optional: if not enabled, perhaps pass accum_in_reg through or hold accum_out.
                // For a MAC that might be part of a larger dot product where `en` controls valid operations,
                // not enabling means the accum_out should not update with a new MAC result.
                // If it should just sum with 0: accum_out <= accum_in_reg; (if product_reg is forced to 0 when not enabled)
                // Or simply: accum_out <= accum_out; (hold previous value) - this is typical for registered outputs.
            end
        end
    end

endmodule




// dot_product_unit.v
module dot_product_unit #(
    parameter DATA_WIDTH              = 8,
    parameter ACCUM_WIDTH             = 32,
    parameter MAC_LATENCY             = 2,     // Physical latency of mac_unit output reg
    parameter MAX_VECTOR_LENGTH_PARAM = 1024
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          start,
    input wire [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] vector_length,
    input wire signed [DATA_WIDTH-1:0]  vec_a_element_in,
    input wire signed [DATA_WIDTH-1:0]  vec_b_element_in,
    output reg signed [ACCUM_WIDTH-1:0] result_out,
    output reg                          result_valid,
    output reg                          busy,
    output reg                          request_next_elements
);

    // Internal signals for datapath
    reg signed [ACCUM_WIDTH-1:0] current_sum_reg;
    reg [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] element_counter_reg;

    // FSM state register and parameters
    localparam FSM_IDLE           = 4'd0;
    localparam FSM_INIT           = 4'd1;
    localparam FSM_REQUEST_DATA   = 4'd2;
    localparam FSM_START_MAC      = 4'd3;
    localparam FSM_WAIT_MAC_S1    = 4'd4; // MAC Stage 1
    localparam FSM_WAIT_MAC_S2    = 4'd5; // MAC Stage 2 (mac_unit output reg updates at end of this cycle)
    localparam FSM_CAPTURE_SUM    = 4'd6; // Capture mac_unit output in this cycle
    localparam FSM_OUTPUT_RESULT  = 4'd7;
    
    reg [3:0] current_state_reg, next_state_comb; // FSM state registers

    // Signals to feed the mac_unit instance
    reg                           mac_en_reg;
    wire signed [DATA_WIDTH-1:0]  mac_data_a_wire;
    wire signed [DATA_WIDTH-1:0]  mac_data_b_wire;
    wire signed [ACCUM_WIDTH-1:0] mac_accum_in_wire;
    wire signed [ACCUM_WIDTH-1:0] mac_accum_out_wire; // Output from mac_unit

    mac_unit #(
        .DATA_A_WIDTH(DATA_WIDTH),
        .DATA_B_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(mac_en_reg),
        .data_a(mac_data_a_wire),
        .data_b(mac_data_b_wire),
        .accum_in(mac_accum_in_wire),
        .accum_out(mac_accum_out_wire)
    );

    // Combinational logic to drive wires feeding the MAC unit
    assign mac_data_a_wire   = vec_a_element_in;
    assign mac_data_b_wire   = vec_b_element_in;
    assign mac_accum_in_wire = current_sum_reg;

    //--------------------------------------------------------------------------
    // FSM Sequential Logic (State Register)
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= FSM_IDLE;
        end else begin
            current_state_reg <= next_state_comb;
        end
    end

    //--------------------------------------------------------------------------
    // FSM Combinational Logic (Next State and Output Logic)
    //--------------------------------------------------------------------------
    always_comb begin
        // Default assignments for FSM outputs and mac_unit control
        next_state_comb       = current_state_reg; // Stay in current state by default
        busy                  = (current_state_reg != FSM_IDLE && current_state_reg != FSM_OUTPUT_RESULT);
        result_valid          = (current_state_reg == FSM_OUTPUT_RESULT);
        mac_en_reg            = 1'b0; 
        request_next_elements = 1'b0; // Default to not requesting

        case (current_state_reg)
            FSM_IDLE: begin
                if (start) begin
                    next_state_comb = FSM_INIT;
                end
            end

            FSM_INIT: begin
                next_state_comb = FSM_REQUEST_DATA;
            end

            FSM_REQUEST_DATA: begin
                if (element_counter_reg < vector_length) begin
                    request_next_elements = 1'b1; 
                    next_state_comb = FSM_START_MAC;
                end else begin 
                    next_state_comb = FSM_OUTPUT_RESULT;
                end
            end

            FSM_START_MAC: begin 
                mac_en_reg = 1'b1; 
                // Explicit begin-end for if-else branches
                if (MAC_LATENCY >= 1) begin
                    next_state_comb = FSM_WAIT_MAC_S1;
                end else begin // For 0-cycle MAC latency (combinational MAC)
                    next_state_comb = FSM_CAPTURE_SUM; 
                end
            end

            FSM_WAIT_MAC_S1: begin 
                if (MAC_LATENCY == 1) begin // Output ready to be captured in next cycle
                    next_state_comb = FSM_CAPTURE_SUM; 
                end else if (MAC_LATENCY >= 2) begin // Need at least one more wait cycle
                    next_state_comb = FSM_WAIT_MAC_S2;
                end
                // Note: Assumes MAC_LATENCY is at least 1 if FSM_WAIT_MAC_S1 is reached from FSM_START_MAC
            end

            FSM_WAIT_MAC_S2: begin 
                // After this state, mac_accum_out_wire holds the result of the MAC operation.
                // (Assuming MAC_LATENCY is 2, its output register is updated at the end of this cycle)
                next_state_comb = FSM_CAPTURE_SUM;
            end

            FSM_CAPTURE_SUM: begin 
                // Datapath updates current_sum_reg and element_counter_reg in this state's clock cycle,
                // using the mac_accum_out_wire value that became stable during FSM_WAIT_MAC_S2.
                next_state_comb = FSM_REQUEST_DATA;
            end

            FSM_OUTPUT_RESULT: begin
                next_state_comb = FSM_IDLE;
            end

            default: begin
                next_state_comb = FSM_IDLE;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Datapath Sequential Logic (Registers for sum, counter, outputs)
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_sum_reg     <= {ACCUM_WIDTH{1'b0}};
            element_counter_reg <= {($clog2(MAX_VECTOR_LENGTH_PARAM)){1'b0}};
            result_out          <= {ACCUM_WIDTH{1'b0}};
        end else begin
            // Default behavior: Hold current values unless explicitly changed
            current_sum_reg     <= current_sum_reg;
            element_counter_reg <= element_counter_reg;
            result_out          <= result_out;

            if (next_state_comb == FSM_INIT) begin // Reset on *entry* to INIT (from IDLE + start)
                current_sum_reg     <= {ACCUM_WIDTH{1'b0}};
                element_counter_reg <= {($clog2(MAX_VECTOR_LENGTH_PARAM)){1'b0}};
            end

            if (current_state_reg == FSM_CAPTURE_SUM) begin // Capture in this new state
                current_sum_reg     <= mac_accum_out_wire;
                element_counter_reg <= element_counter_reg + 1;
            end
            
            if (current_state_reg == FSM_OUTPUT_RESULT) begin
                result_out <= current_sum_reg;
            end
        end
    end

    //--------------------------------------------------------------------------
    // DEBUGGING DISPLAY BLOCK
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n && (busy || start || (current_state_reg != FSM_IDLE) )) begin // Display when active or just started/finished
            $display("[%0t DUT] State: %s, elem_cnt: %d (len:%d), sum_reg: %d | mac_en: %b, mac_A: %d, mac_B: %d, mac_accum_in: %d => mac_OUT: %d | req_next: %b, res_valid: %b, res_out_port: %d",
                $time,
                (current_state_reg == FSM_IDLE) ? "IDLE" :
                (current_state_reg == FSM_INIT) ? "INIT" :
                (current_state_reg == FSM_REQUEST_DATA) ? "REQ_DATA" :
                (current_state_reg == FSM_START_MAC) ? "START_MAC" :
                (current_state_reg == FSM_WAIT_MAC_S1) ? "WAIT_S1" :
                (current_state_reg == FSM_WAIT_MAC_S2) ? "WAIT_S2" :
                (current_state_reg == FSM_CAPTURE_SUM) ? "CAPTURE_SUM" :
                (current_state_reg == FSM_OUTPUT_RESULT) ? "OUT_RES" : "UNKNOWN_FSM",
                element_counter_reg, vector_length, current_sum_reg,
                mac_en_reg, mac_data_a_wire, mac_data_b_wire, mac_accum_in_wire, mac_accum_out_wire,
                request_next_elements, result_valid, result_out );
        end
    end

endmodule




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





// qkv_projection_unit.v
module qkv_projection_unit #(
    parameter DATA_WIDTH   = 8,
    parameter ACCUM_WIDTH  = 32,
    parameter D_MODEL      = 768, // Dimension of input x
    parameter D_K          = 64,  // Dimension of Q and K vectors
    parameter D_V          = 64   // Dimension of V vector
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          op_start_qkv, // Main start signal

    input wire signed [DATA_WIDTH-1:0]  input_x_vector [0:D_MODEL-1],
    input wire signed [DATA_WIDTH-1:0]  Wq_matrix [0:D_MODEL-1][0:D_K-1],
    input wire signed [DATA_WIDTH-1:0]  Wk_matrix [0:D_MODEL-1][0:D_K-1],
    input wire signed [DATA_WIDTH-1:0]  Wv_matrix [0:D_MODEL-1][0:D_V-1],
    input wire signed [ACCUM_WIDTH-1:0] bq_vector [0:D_K-1],
    input wire signed [ACCUM_WIDTH-1:0] bk_vector [0:D_K-1],
    input wire signed [ACCUM_WIDTH-1:0] bv_vector [0:D_V-1],

    output reg signed [ACCUM_WIDTH-1:0] q_vector_out [0:D_K-1],
    output reg signed [ACCUM_WIDTH-1:0] k_vector_out [0:D_K-1],
    output reg signed [ACCUM_WIDTH-1:0] v_vector_out [0:D_V-1],

    output reg                          op_busy_qkv, // Driven by FSM combinational logic
    output reg                          op_done_qkv  // Driven by FSM combinational logic
);

    // Determine the maximum N_COLS needed for the linear_layer_unit instance
    localparam MAX_N_FOR_LL = (D_K > D_V) ? D_K : D_V;

    // Internal registers for latched inputs
    reg signed [DATA_WIDTH-1:0]  internal_x_vector_reg [0:D_MODEL-1];
    reg signed [DATA_WIDTH-1:0]  internal_Wq_matrix_reg [0:D_MODEL-1][0:D_K-1];
    reg signed [DATA_WIDTH-1:0]  internal_Wk_matrix_reg [0:D_MODEL-1][0:D_K-1];
    reg signed [DATA_WIDTH-1:0]  internal_Wv_matrix_reg [0:D_MODEL-1][0:D_V-1];
    reg signed [ACCUM_WIDTH-1:0] internal_bq_vector_reg [0:D_K-1];
    reg signed [ACCUM_WIDTH-1:0] internal_bk_vector_reg [0:D_K-1];
    reg signed [ACCUM_WIDTH-1:0] internal_bv_vector_reg [0:D_V-1];

    // Signals for the linear_layer_unit instance (ll_inst)
    reg                               ll_op_start_reg;
    reg signed [DATA_WIDTH-1:0]       ll_input_activation_matrix_reg [0:0][0:D_MODEL-1]; 
    reg signed [DATA_WIDTH-1:0]       ll_weight_matrix_reg [0:D_MODEL-1][0:MAX_N_FOR_LL-1];
    reg signed [ACCUM_WIDTH-1:0]      ll_bias_vector_reg [0:MAX_N_FOR_LL-1];

    wire signed [ACCUM_WIDTH-1:0]     ll_output_matrix_wire [0:0][0:MAX_N_FOR_LL-1];
    wire                              ll_op_busy_wire;
    wire                              ll_op_done_wire;

    linear_layer_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .M_ROWS(1),          
        .K_COLS(D_MODEL),    
        .N_COLS(MAX_N_FOR_LL) 
    ) ll_inst (
        .clk(clk),
        .rst_n(rst_n),
        .op_start_ll(ll_op_start_reg),
        .input_activation_matrix(ll_input_activation_matrix_reg),
        .weight_matrix(ll_weight_matrix_reg),
        .bias_vector(ll_bias_vector_reg),
        .output_matrix(ll_output_matrix_wire),
        .op_busy_ll(ll_op_busy_wire),
        .op_done_ll(ll_op_done_wire)
    );

    // FSM State Definitions
    localparam S_IDLE_QKV                = 4'd0;
    localparam S_LATCH_INPUTS_QKV        = 4'd1;
    localparam S_CALC_Q_SETUP_LL         = 4'd2;
    localparam S_CALC_Q_START_LL         = 4'd3;
    localparam S_CALC_Q_WAIT_LL          = 4'd4;
    localparam S_CALC_Q_STORE            = 4'd5;
    localparam S_CALC_K_SETUP_LL         = 4'd6;
    localparam S_CALC_K_START_LL         = 4'd7;
    localparam S_CALC_K_WAIT_LL          = 4'd8;
    localparam S_CALC_K_STORE            = 4'd9;
    localparam S_CALC_V_SETUP_LL         = 4'd10;
    localparam S_CALC_V_START_LL         = 4'd11;
    localparam S_CALC_V_WAIT_LL          = 4'd12;
    localparam S_CALC_V_STORE            = 4'd13;
    localparam S_DONE_QKV                = 4'd14;

    reg [3:0] current_qkv_state_reg, next_qkv_state_comb;

    reg op_start_qkv_d1;
    wire op_start_qkv_posedge = op_start_qkv && !op_start_qkv_d1;

    integer i, j; 


    // FSM Sequential Part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_qkv_state_reg <= S_IDLE_QKV;
            op_start_qkv_d1       <= 1'b0;
        end else begin
            current_qkv_state_reg <= next_qkv_state_comb;
            op_start_qkv_d1       <= op_start_qkv;
        end
    end

    // FSM Combinational Part
    always_comb begin
        next_qkv_state_comb = current_qkv_state_reg; 
        op_busy_qkv         = 1'b1; 
        op_done_qkv         = 1'b0;
        ll_op_start_reg     = 1'b0; 

        case(current_qkv_state_reg)
            S_IDLE_QKV: begin
                op_busy_qkv = 1'b0;
                if (op_start_qkv_posedge) begin
                    next_qkv_state_comb = S_LATCH_INPUTS_QKV;
                end
            end
            S_LATCH_INPUTS_QKV: begin
                next_qkv_state_comb = S_CALC_Q_SETUP_LL;
            end
            S_CALC_Q_SETUP_LL: begin
                next_qkv_state_comb = S_CALC_Q_START_LL;
            end
            S_CALC_Q_START_LL: begin
                ll_op_start_reg = 1'b1; 
                next_qkv_state_comb = S_CALC_Q_WAIT_LL;
            end
            S_CALC_Q_WAIT_LL: begin
                ll_op_start_reg = 1'b0; 
                if (ll_op_done_wire) begin
                    next_qkv_state_comb = S_CALC_Q_STORE;
                end
            end
            S_CALC_Q_STORE: begin
                next_qkv_state_comb = S_CALC_K_SETUP_LL;
            end
            S_CALC_K_SETUP_LL: begin
                next_qkv_state_comb = S_CALC_K_START_LL;
            end
            S_CALC_K_START_LL: begin
                ll_op_start_reg = 1'b1;
                next_qkv_state_comb = S_CALC_K_WAIT_LL;
            end
            S_CALC_K_WAIT_LL: begin
                ll_op_start_reg = 1'b0;
                if (ll_op_done_wire) begin
                    next_qkv_state_comb = S_CALC_K_STORE;
                end
            end
            S_CALC_K_STORE: begin
                next_qkv_state_comb = S_CALC_V_SETUP_LL; 
            end
            S_CALC_V_SETUP_LL: begin
                next_qkv_state_comb = S_CALC_V_START_LL;
            end
            S_CALC_V_START_LL: begin
                ll_op_start_reg = 1'b1;
                next_qkv_state_comb = S_CALC_V_WAIT_LL;
            end
            S_CALC_V_WAIT_LL: begin
                ll_op_start_reg = 1'b0;
                if (ll_op_done_wire) begin
                    next_qkv_state_comb = S_CALC_V_STORE;
                end
            end
            S_CALC_V_STORE: begin
                next_qkv_state_comb = S_DONE_QKV;
            end
            S_DONE_QKV: begin
                op_busy_qkv = 1'b0;
                op_done_qkv = 1'b1; 
                next_qkv_state_comb = S_IDLE_QKV;
            end
            default: begin
                next_qkv_state_comb = S_IDLE_QKV;
                op_busy_qkv = 1'b0;
            end
        endcase
    end

    // Datapath Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // op_busy_qkv <= 1'b0; // REMOVED - Driven by FSM combinational logic
            // op_done_qkv <= 1'b0; // REMOVED - Driven by FSM combinational logic
            
            for (i = 0; i < D_MODEL; i = i + 1) internal_x_vector_reg[i] <= 0;
            for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_K; j = j + 1) internal_Wq_matrix_reg[i][j] <= 0;
            for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_K; j = j + 1) internal_Wk_matrix_reg[i][j] <= 0;
            for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_V; j = j + 1) internal_Wv_matrix_reg[i][j] <= 0;
            for (i = 0; i < D_K; i = i + 1) internal_bq_vector_reg[i] <= 0;
            for (i = 0; i < D_K; i = i + 1) internal_bk_vector_reg[i] <= 0;
            for (i = 0; i < D_V; i = i + 1) internal_bv_vector_reg[i] <= 0;

            for (i = 0; i < D_MODEL; i = i + 1) ll_input_activation_matrix_reg[0][i] <= 0;
            for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < MAX_N_FOR_LL; j = j + 1) ll_weight_matrix_reg[i][j] <= 0;
            for (i = 0; i < MAX_N_FOR_LL; i = i + 1) ll_bias_vector_reg[i] <= 0;
            
            for (i = 0; i < D_K; i = i + 1) q_vector_out[i] <= 0;
            for (i = 0; i < D_K; i = i + 1) k_vector_out[i] <= 0;
            for (i = 0; i < D_V; i = i + 1) v_vector_out[i] <= 0;

        end else begin
            if (current_qkv_state_reg == S_LATCH_INPUTS_QKV) begin
                for (i = 0; i < D_MODEL; i = i + 1) internal_x_vector_reg[i] <= input_x_vector[i];
                for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_K; j = j + 1) internal_Wq_matrix_reg[i][j] <= Wq_matrix[i][j];
                for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_K; j = j + 1) internal_Wk_matrix_reg[i][j] <= Wk_matrix[i][j];
                for (i = 0; i < D_MODEL; i = i + 1) for (j = 0; j < D_V; j = j + 1) internal_Wv_matrix_reg[i][j] <= Wv_matrix[i][j];
                for (i = 0; i < D_K; i = i + 1) internal_bq_vector_reg[i] <= bq_vector[i];
                for (i = 0; i < D_K; i = i + 1) internal_bk_vector_reg[i] <= bk_vector[i];
                for (i = 0; i < D_V; i = i + 1) internal_bv_vector_reg[i] <= bv_vector[i];
            end

            if (current_qkv_state_reg == S_CALC_Q_SETUP_LL) begin
                for (i = 0; i < D_MODEL; i = i + 1) ll_input_activation_matrix_reg[0][i] <= internal_x_vector_reg[i];
                for (i = 0; i < D_MODEL; i = i + 1) begin
                    for (j = 0; j < D_K; j = j + 1) ll_weight_matrix_reg[i][j] <= internal_Wq_matrix_reg[i][j];
                    for (j = D_K; j < MAX_N_FOR_LL; j = j + 1) ll_weight_matrix_reg[i][j] <= 0; 
                end
                for (i = 0; i < D_K; i = i + 1) ll_bias_vector_reg[i] <= internal_bq_vector_reg[i];
                for (i = D_K; i < MAX_N_FOR_LL; i = i + 1) ll_bias_vector_reg[i] <= 0; 
            end

            if (current_qkv_state_reg == S_CALC_Q_STORE) begin
                for (i = 0; i < D_K; i = i + 1) q_vector_out[i] <= ll_output_matrix_wire[0][i];
            end

            if (current_qkv_state_reg == S_CALC_K_SETUP_LL) begin
                for (i = 0; i < D_MODEL; i = i + 1) ll_input_activation_matrix_reg[0][i] <= internal_x_vector_reg[i]; 
                for (i = 0; i < D_MODEL; i = i + 1) begin
                    for (j = 0; j < D_K; j = j + 1) ll_weight_matrix_reg[i][j] <= internal_Wk_matrix_reg[i][j];
                    for (j = D_K; j < MAX_N_FOR_LL; j = j + 1) ll_weight_matrix_reg[i][j] <= 0;
                end
                for (i = 0; i < D_K; i = i + 1) ll_bias_vector_reg[i] <= internal_bk_vector_reg[i];
                for (i = D_K; i < MAX_N_FOR_LL; i = i + 1) ll_bias_vector_reg[i] <= 0;
            end

            if (current_qkv_state_reg == S_CALC_K_STORE) begin
                for (i = 0; i < D_K; i = i + 1) k_vector_out[i] <= ll_output_matrix_wire[0][i];
            end
            
            if (current_qkv_state_reg == S_CALC_V_SETUP_LL) begin
                for (i = 0; i < D_MODEL; i = i + 1) ll_input_activation_matrix_reg[0][i] <= internal_x_vector_reg[i]; 
                for (i = 0; i < D_MODEL; i = i + 1) begin
                    for (j = 0; j < D_V; j = j + 1) ll_weight_matrix_reg[i][j] <= internal_Wv_matrix_reg[i][j];
                    for (j = D_V; j < MAX_N_FOR_LL; j = j + 1) ll_weight_matrix_reg[i][j] <= 0;
                end
                for (i = 0; i < D_V; i = i + 1) ll_bias_vector_reg[i] <= internal_bv_vector_reg[i];
                for (i = D_V; i < MAX_N_FOR_LL; i = i + 1) ll_bias_vector_reg[i] <= 0;
            end

            if (current_qkv_state_reg == S_CALC_V_STORE) begin
                for (i = 0; i < D_V; i = i + 1) v_vector_out[i] <= ll_output_matrix_wire[0][i];
            end
            
            // op_done_qkv is pulsed by the FSM combinational logic when in S_DONE_QKV
            // No need for specific handling here unless it wasn't a direct output reg
        end
    end

endmodule







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



// softmax_unit.v
module softmax_unit #(
    parameter N                   = 4,    // Vector length (e.g., sequence length)
    parameter INPUT_DATA_WIDTH    = 32,   // Width of input x (scaled scores), e.g., Q16.16
    parameter INPUT_FRAC_BITS     = 16,
    parameter OUTPUT_DATA_WIDTH   = 16,   // Width of output y (attention weights), e.g., Q1.15
    parameter OUTPUT_FRAC_BITS    = 15,

    // Internal precision parameters
    parameter MAX_VAL_WIDTH       = INPUT_DATA_WIDTH, 
    parameter SHIFTED_X_WIDTH     = INPUT_DATA_WIDTH + 1, 
    parameter SHIFTED_X_FRAC_BITS = INPUT_FRAC_BITS,

    parameter EXP_VAL_WIDTH       = 16, 
    parameter EXP_VAL_FRAC_BITS   = 12, 
    
    parameter SUM_EXP_INT_BITS    = (EXP_VAL_WIDTH - 1 - EXP_VAL_FRAC_BITS) + $clog2(N),
    parameter SUM_EXP_WIDTH       = 1 + SUM_EXP_INT_BITS + EXP_VAL_FRAC_BITS, 

    parameter RECIP_SUM_FRAC_BITS = 16, 
    parameter RECIP_SUM_WIDTH     = 1 + 2 + RECIP_SUM_FRAC_BITS, 

    // Latencies for conceptual sub-units
    parameter EXP_LATENCY         = 1, 
    parameter RECIP_LATENCY       = 5  
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          op_start,

    input wire signed [INPUT_DATA_WIDTH-1:0]  input_vector_x [0:N-1],
    output reg signed [OUTPUT_DATA_WIDTH-1:0] output_vector_y [0:N-1],

    output reg                          op_busy,
    output reg                          op_done
);

    // --- FSM State Definitions ---
    localparam S_IDLE                   = 4'd0;
    localparam S_LATCH_INPUTS           = 4'd1;
    localparam S_FIND_MAX_INIT          = 4'd2;
    localparam S_FIND_MAX_LOOP          = 4'd3;
    localparam S_EXP_SUM_INIT           = 4'd4;
    localparam S_EXP_SUM_FETCH_X        = 4'd5; 
    localparam S_EXP_SUM_START_EXP      = 4'd6; 
    localparam S_EXP_SUM_WAIT_EXP       = 4'd7; 
    localparam S_EXP_SUM_ACCUM          = 4'd8; 
    localparam S_CALC_RECIP_START       = 4'd9;
    localparam S_CALC_RECIP_WAIT        = 4'd10;
    localparam S_NORMALIZE_INIT         = 4'd11;
    localparam S_NORMALIZE_LOOP         = 4'd12; 
    localparam S_DONE                   = 4'd13;

    reg [3:0] current_state_reg, next_state_comb;

    // --- Datapath Registers & Wires ---
    reg signed [INPUT_DATA_WIDTH-1:0]   x_internal_reg [0:N-1];
    reg signed [MAX_VAL_WIDTH-1:0]      max_val_reg;
    
    reg signed [EXP_VAL_WIDTH-1:0]      exp_values_buf [0:N-1]; 
    reg signed [SUM_EXP_WIDTH-1:0]      sum_exp_values_acc_reg;
    reg signed [RECIP_SUM_WIDTH-1:0]    recip_sum_exp_reg; 

    reg [$clog2(N+1)-1:0]               idx_counter_reg; 
    reg [$clog2(N+1)-1:0]               idx_for_exp_result_reg; 

    // Signals for exp_lut_unit instance
    reg                                 exp_unit_start;
    wire signed [EXP_VAL_WIDTH-1:0]     exp_unit_y_out;
    wire                                exp_unit_done;
    
    logic signed [SHIFTED_X_WIDTH-1:0]  current_shifted_x_comb; 
    
    // No longer an assign for current_recip_out_comb at module level
    reg [$clog2(RECIP_LATENCY+1)-1:0]   recip_wait_counter_reg;

    reg op_start_d1;
    wire op_start_posedge = op_start && !op_start_d1;
    integer i; 

    localparam FINAL_SHIFT = (EXP_VAL_FRAC_BITS + RECIP_SUM_FRAC_BITS) - OUTPUT_FRAC_BITS;

    exp_lut_unit #(
        .INPUT_WIDTH(SHIFTED_X_WIDTH),
        .INPUT_FRAC_BITS(SHIFTED_X_FRAC_BITS),
        .OUTPUT_WIDTH(EXP_VAL_WIDTH),
        .OUTPUT_FRAC_BITS(EXP_VAL_FRAC_BITS),
        .EXP_LUT_LATENCY(EXP_LATENCY)
    ) exp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_exp(exp_unit_start),
        .x_in(current_shifted_x_comb), 
        .y_out(exp_unit_y_out),
        .exp_done(exp_unit_done)
    );

    assign current_shifted_x_comb = (idx_counter_reg < N) ? 
                                    (x_internal_reg[idx_counter_reg] - max_val_reg) : 
                                    0; 

    // Removed: assign current_recip_out_comb = ...;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= S_IDLE;
            op_start_d1       <= 1'b0;
        end else begin
            current_state_reg <= next_state_comb;
            op_start_d1       <= op_start;
        end
    end

    always_comb begin
        next_state_comb = current_state_reg; 
        op_busy         = (current_state_reg != S_IDLE && current_state_reg != S_DONE);
        op_done         = (current_state_reg == S_DONE);
        exp_unit_start  = 1'b0; 

        case (current_state_reg)
            S_IDLE: if (op_start_posedge) next_state_comb = S_LATCH_INPUTS;
            S_LATCH_INPUTS: next_state_comb = S_FIND_MAX_INIT;
            S_FIND_MAX_INIT: next_state_comb = S_FIND_MAX_LOOP;
            S_FIND_MAX_LOOP: if (idx_counter_reg == N) next_state_comb = S_EXP_SUM_INIT;
            S_EXP_SUM_INIT: next_state_comb = S_EXP_SUM_FETCH_X;
            S_EXP_SUM_FETCH_X: begin
                if (idx_counter_reg < N) next_state_comb = S_EXP_SUM_START_EXP;
                else next_state_comb = S_CALC_RECIP_START; 
            end
            S_EXP_SUM_START_EXP: begin
                exp_unit_start = 1'b1; 
                next_state_comb = S_EXP_SUM_WAIT_EXP;
            end
            S_EXP_SUM_WAIT_EXP: begin
                if (exp_unit_done) next_state_comb = S_EXP_SUM_ACCUM;
            end
            S_EXP_SUM_ACCUM: next_state_comb = S_EXP_SUM_FETCH_X; 
            S_CALC_RECIP_START: begin
                next_state_comb = S_CALC_RECIP_WAIT;
            end
            S_CALC_RECIP_WAIT: begin
                if (recip_wait_counter_reg == 0) next_state_comb = S_NORMALIZE_INIT;
            end
            S_NORMALIZE_INIT: next_state_comb = S_NORMALIZE_LOOP;
            S_NORMALIZE_LOOP: if (idx_counter_reg == N) next_state_comb = S_DONE;
            S_DONE: next_state_comb = S_IDLE;
            default: next_state_comb = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        logic signed [EXP_VAL_WIDTH + RECIP_SUM_WIDTH - 1:0] temp_prod_norm;
        logic signed [OUTPUT_DATA_WIDTH-1:0] scaled_final_val;
        logic signed [RECIP_SUM_WIDTH-1:0]   calculated_reciprocal_comb; // For calculation before latching

        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                x_internal_reg[i] <= 0;
                exp_values_buf[i] <= 0;
                output_vector_y[i] <= 0;
            end
            max_val_reg <= {1'b1, {(MAX_VAL_WIDTH-1){1'b0}}}; 
            sum_exp_values_acc_reg <= 0;
            recip_sum_exp_reg <= 0;
            idx_counter_reg <= 0;
            idx_for_exp_result_reg <= 0;
            recip_wait_counter_reg <= 0;
        end else begin
            // Default holds 
            // ...

            if (current_state_reg == S_LATCH_INPUTS) begin
                for (i = 0; i < N; i = i + 1) begin
                    x_internal_reg[i] <= input_vector_x[i];
                end
            end

            if (current_state_reg == S_FIND_MAX_INIT) begin
                if (N > 0) max_val_reg <= x_internal_reg[0]; else max_val_reg <= 0;
                idx_counter_reg <= 1; 
            end

            if (current_state_reg == S_FIND_MAX_LOOP) begin
                if (idx_counter_reg < N) begin
                    if (x_internal_reg[idx_counter_reg] > max_val_reg) begin
                        max_val_reg <= x_internal_reg[idx_counter_reg];
                    end
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end

            if (current_state_reg == S_EXP_SUM_INIT) begin
                idx_counter_reg <= 0;
                sum_exp_values_acc_reg <= 0;
            end
            
            if (current_state_reg == S_EXP_SUM_START_EXP) begin
                 idx_for_exp_result_reg <= idx_counter_reg;
            end
            
            if (current_state_reg == S_EXP_SUM_ACCUM) begin 
                if (idx_for_exp_result_reg < N) begin 
                    exp_values_buf[idx_for_exp_result_reg] <= exp_unit_y_out; 
                    sum_exp_values_acc_reg <= sum_exp_values_acc_reg + $signed({{(SUM_EXP_WIDTH-EXP_VAL_WIDTH){exp_unit_y_out[EXP_VAL_WIDTH-1]}},exp_unit_y_out}); 
                end
                idx_counter_reg <= idx_counter_reg + 1; 
            end
            
            if (current_state_reg == S_CALC_RECIP_START) begin
                recip_wait_counter_reg <= RECIP_LATENCY;
            end

            if (current_state_reg == S_CALC_RECIP_WAIT) begin
                if (recip_wait_counter_reg > 0) begin
                    recip_wait_counter_reg <= recip_wait_counter_reg - 1;
                end
                if (recip_wait_counter_reg == 1) begin // Value is calculated combinationally in this cycle
                    if (sum_exp_values_acc_reg != 0) begin
                        calculated_reciprocal_comb = (1 << (RECIP_SUM_FRAC_BITS + EXP_VAL_FRAC_BITS)) / sum_exp_values_acc_reg;
                    end else begin
                        calculated_reciprocal_comb = 0;
                    end
                    recip_sum_exp_reg <= calculated_reciprocal_comb; 
                end
            end

            if (current_state_reg == S_NORMALIZE_INIT) begin
                idx_counter_reg <= 0;
            end

            if (current_state_reg == S_NORMALIZE_LOOP) begin
                if (idx_counter_reg < N) begin
                    temp_prod_norm = $signed(exp_values_buf[idx_counter_reg]) * $signed(recip_sum_exp_reg);
                    
                    if (FINAL_SHIFT >= 0) begin
                        scaled_final_val = temp_prod_norm >>> FINAL_SHIFT;
                    end else begin 
                        scaled_final_val = temp_prod_norm <<< (-FINAL_SHIFT);
                    end
                    output_vector_y[idx_counter_reg] <= scaled_final_val;
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end
        end
    end

    // Optional: Debug display
    // ...

endmodule



// softmax_unit.v
// Designed to use the user's verified exp_lut_unit.v
module softmax_unit #(
    parameter N                   = 4,    // Vector length (e.g., sequence length)

    // Input x to Softmax (scaled scores)
    parameter INPUT_DATA_WIDTH    = 16,   
    parameter INPUT_FRAC_BITS     = 8,

    // Output y from Softmax (attention weights)
    parameter OUTPUT_DATA_WIDTH   = 16,   
    parameter OUTPUT_FRAC_BITS    = 15,

    // Parameters for the exp_lut_unit instance (matching user's exp_lut_unit)
    parameter EXP_UNIT_INPUT_WIDTH    = 12, 
    parameter EXP_UNIT_INPUT_FRAC   = 8,  
    parameter EXP_UNIT_OUTPUT_WIDTH   = 16, 
    parameter EXP_UNIT_OUTPUT_FRAC  = 15, // This is the fractional bits of exp_lut_unit's output
    parameter EXP_UNIT_LATENCY      = 1,
    
    // Parameters for sum_exp accumulator
    // Integer bits for exp_val (Q1.15 has 0 explicit integer bits for magnitude). Sum needs $clog2(N) for magnitude.
    parameter SUM_EXP_INT_BITS    = $clog2(N), 
    parameter SUM_EXP_WIDTH       = 1 + SUM_EXP_INT_BITS + EXP_UNIT_OUTPUT_FRAC, // Sign + Int + Frac

    // Parameters for reciprocal (1/sum_exp)
    parameter RECIP_SUM_FRAC_BITS = 15, 
    parameter RECIP_SUM_WIDTH     = 16, // e.g., Q1.15

    parameter RECIP_LATENCY       = 5  // Placeholder for reciprocal unit
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          op_start,

    input wire signed [INPUT_DATA_WIDTH-1:0]  input_vector_x [0:N-1],
    output reg signed [OUTPUT_DATA_WIDTH-1:0] output_vector_y [0:N-1],

    output reg                          op_busy,
    output reg                          op_done
);

    // --- Local Parameters ---
    // Shift for scaling (x_i - max_val) to exp_unit's input format
    localparam SHIFT_FOR_EXP_PREP = INPUT_FRAC_BITS - EXP_UNIT_INPUT_FRAC;
    // Shift for final normalization: (FracBitsOf(exp_out) + FracBitsOf(recip_sum)) - FracBitsOf(output_y)
    localparam FINAL_NORM_SHIFT = (EXP_UNIT_OUTPUT_FRAC + RECIP_SUM_FRAC_BITS) - OUTPUT_FRAC_BITS;


    // --- FSM State Definitions ---
    localparam S_IDLE                   = 4'd0;
    localparam S_LATCH_INPUTS           = 4'd1;
    localparam S_FIND_MAX_INIT          = 4'd2;
    localparam S_FIND_MAX_LOOP          = 4'd3;
    localparam S_EXP_SUM_INIT           = 4'd4;
    localparam S_EXP_SUM_FETCH_X        = 4'd5; 
    localparam S_EXP_SUM_START_EXP      = 4'd6; 
    localparam S_EXP_SUM_WAIT_EXP       = 4'd7; 
    localparam S_EXP_SUM_ACCUM          = 4'd8; 
    localparam S_CALC_RECIP_START       = 4'd9;
    localparam S_CALC_RECIP_WAIT        = 4'd10;
    localparam S_NORMALIZE_INIT         = 4'd11;
    localparam S_NORMALIZE_LOOP         = 4'd12; 
    localparam S_DONE                   = 4'd13;

    reg [3:0] current_state_reg, next_state_comb;

    // --- Datapath Registers & Wires ---
    reg signed [INPUT_DATA_WIDTH-1:0]   x_internal_reg [0:N-1];
    reg signed [INPUT_DATA_WIDTH-1:0]   max_val_reg;    
    
    reg signed [EXP_UNIT_OUTPUT_WIDTH-1:0] exp_values_buf [0:N-1]; 
    reg signed [SUM_EXP_WIDTH-1:0]         sum_exp_values_acc_reg;
    reg signed [RECIP_SUM_WIDTH-1:0]       recip_sum_exp_reg; 

    reg [$clog2(N+1)-1:0]               idx_counter_reg; 
    reg [$clog2(N+1)-1:0]               idx_for_exp_result_reg; 

    reg                                 exp_unit_start_reg_to_dut;
    wire signed [EXP_UNIT_OUTPUT_WIDTH-1:0] exp_unit_y_out_from_dut;
    wire                                exp_unit_done_from_dut;  
    
    wire signed [EXP_UNIT_INPUT_WIDTH-1:0]  shifted_x_for_exp_unit; 
    
    reg [$clog2(RECIP_LATENCY+1)-1:0]   recip_wait_counter_reg;

    reg op_start_d1;
    wire op_start_posedge = op_start && !op_start_d1;
    integer i; 

    // Wires for intermediate steps of current_shifted_x_for_exp calculation
    wire signed [INPUT_DATA_WIDTH:0]   w_temp_diff_shifted_x; 
    wire signed [INPUT_DATA_WIDTH:0]   w_temp_scaled_shifted_x;    


    exp_lut_unit #(
        .INPUT_WIDTH(EXP_UNIT_INPUT_WIDTH),     
        .INPUT_FRAC_BITS(EXP_UNIT_INPUT_FRAC),  
        .OUTPUT_WIDTH(EXP_UNIT_OUTPUT_WIDTH),             
        .OUTPUT_FRAC_BITS(EXP_UNIT_OUTPUT_FRAC),     
        .EXP_LUT_LATENCY(EXP_UNIT_LATENCY)      
    ) exp_inst (
        .clk(clk), .rst_n(rst_n),
        .start_exp(exp_unit_start_reg_to_dut), 
        .x_in(shifted_x_for_exp_unit), 
        .y_out(exp_unit_y_out_from_dut),
        .exp_done(exp_unit_done_from_dut)
    );

    assign w_temp_diff_shifted_x = (current_state_reg == S_EXP_SUM_FETCH_X && idx_counter_reg < N) ?
                                 ($signed(x_internal_reg[idx_counter_reg]) - $signed(max_val_reg)) : 0;

    assign w_temp_scaled_shifted_x = (SHIFT_FOR_EXP_PREP >= 0) ?
                                   (w_temp_diff_shifted_x >>> SHIFT_FOR_EXP_PREP) :
                                   (w_temp_diff_shifted_x <<< (-SHIFT_FOR_EXP_PREP));

    assign shifted_x_for_exp_unit = 
     ( (INPUT_DATA_WIDTH+1) == EXP_UNIT_INPUT_WIDTH ) ? 
        w_temp_scaled_shifted_x[EXP_UNIT_INPUT_WIDTH-1:0] : 
     ( (INPUT_DATA_WIDTH+1) < EXP_UNIT_INPUT_WIDTH ) ? 
        $signed({{(EXP_UNIT_INPUT_WIDTH - (INPUT_DATA_WIDTH+1)){w_temp_scaled_shifted_x[INPUT_DATA_WIDTH]}}, 
                 w_temp_scaled_shifted_x}) :
        $signed(w_temp_scaled_shifted_x[EXP_UNIT_INPUT_WIDTH-1:0]);
    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state_reg <= S_IDLE; else current_state_reg <= next_state_comb;
        op_start_d1 <= rst_n ? op_start : 1'b0;
    end

    always_comb begin
        next_state_comb = current_state_reg; 
        op_busy         = (current_state_reg != S_IDLE && current_state_reg != S_DONE);
        op_done         = (current_state_reg == S_DONE);
        exp_unit_start_reg_to_dut  = 1'b0; 

        case (current_state_reg)
            S_IDLE: if (op_start_posedge) next_state_comb = S_LATCH_INPUTS;
            S_LATCH_INPUTS: next_state_comb = S_FIND_MAX_INIT;
            S_FIND_MAX_INIT: next_state_comb = S_FIND_MAX_LOOP;
            S_FIND_MAX_LOOP: if (idx_counter_reg == N) next_state_comb = S_EXP_SUM_INIT;
            S_EXP_SUM_INIT: next_state_comb = S_EXP_SUM_FETCH_X;
            S_EXP_SUM_FETCH_X: if (idx_counter_reg < N) next_state_comb = S_EXP_SUM_START_EXP; else next_state_comb = S_CALC_RECIP_START; 
            S_EXP_SUM_START_EXP: begin exp_unit_start_reg_to_dut = 1'b1; next_state_comb = S_EXP_SUM_WAIT_EXP; end
            S_EXP_SUM_WAIT_EXP: if (exp_unit_done_from_dut) next_state_comb = S_EXP_SUM_ACCUM;
            S_EXP_SUM_ACCUM: next_state_comb = S_EXP_SUM_FETCH_X; 
            S_CALC_RECIP_START: next_state_comb = S_CALC_RECIP_WAIT;
            S_CALC_RECIP_WAIT: if (recip_wait_counter_reg == 0) next_state_comb = S_NORMALIZE_INIT;
            S_NORMALIZE_INIT: next_state_comb = S_NORMALIZE_LOOP;
            S_NORMALIZE_LOOP: if (idx_counter_reg == N) next_state_comb = S_DONE;
            S_DONE: next_state_comb = S_IDLE;
            default: next_state_comb = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        // Local variables for this clocked block
        logic signed [EXP_UNIT_OUTPUT_WIDTH + RECIP_SUM_WIDTH - 1:0] temp_prod_norm_comb; // Corrected: Use EXP_UNIT_OUTPUT_WIDTH
        logic signed [OUTPUT_DATA_WIDTH-1:0] scaled_final_val_comb;
        logic signed [RECIP_SUM_WIDTH-1:0]   calculated_reciprocal_val_comb;
        logic signed [(RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC + 1) -1:0] numerator_for_recip_comb; // Corrected


        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                x_internal_reg[i] <= 0;
                exp_values_buf[i] <= 0;
                output_vector_y[i] <= 0;
            end
            max_val_reg <= {1'b1, {(INPUT_DATA_WIDTH-1){1'b0}}}; 
            sum_exp_values_acc_reg <= 0;
            recip_sum_exp_reg <= 0;
            idx_counter_reg <= 0;
            idx_for_exp_result_reg <= 0;
            recip_wait_counter_reg <= 0;
        end else begin
            if (current_state_reg == S_LATCH_INPUTS) begin
                for (i = 0; i < N; i = i + 1) x_internal_reg[i] <= input_vector_x[i];
            end
            if (current_state_reg == S_FIND_MAX_INIT) begin
                if (N > 0) max_val_reg <= x_internal_reg[0]; else max_val_reg <= 0;
                idx_counter_reg <= 1; 
            end
            if (current_state_reg == S_FIND_MAX_LOOP) begin
                if (idx_counter_reg < N) begin
                    if (x_internal_reg[idx_counter_reg] > max_val_reg) max_val_reg <= x_internal_reg[idx_counter_reg];
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end
            if (current_state_reg == S_EXP_SUM_INIT) begin
                idx_counter_reg <= 0; sum_exp_values_acc_reg <= 0;
            end
            if (current_state_reg == S_EXP_SUM_START_EXP) idx_for_exp_result_reg <= idx_counter_reg;
            
            if (current_state_reg == S_EXP_SUM_ACCUM) begin 
                if (idx_for_exp_result_reg < N) begin 
                    exp_values_buf[idx_for_exp_result_reg] <= exp_unit_y_out_from_dut; 
                    sum_exp_values_acc_reg <= sum_exp_values_acc_reg + $signed({{(SUM_EXP_WIDTH-EXP_UNIT_OUTPUT_WIDTH){exp_unit_y_out_from_dut[EXP_UNIT_OUTPUT_WIDTH-1]}},exp_unit_y_out_from_dut}); 
                end
                idx_counter_reg <= idx_counter_reg + 1; 
            end
            
            if (current_state_reg == S_CALC_RECIP_START) begin
                recip_wait_counter_reg <= RECIP_LATENCY;
                // Calculate combinational value for reciprocal here
                if (sum_exp_values_acc_reg != 0) begin
                    // Numerator for 1.0, scaled to have (RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC) fractional bits
                    numerator_for_recip_comb = 1 << (RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC); // Use correct param
                    calculated_reciprocal_val_comb = numerator_for_recip_comb / sum_exp_values_acc_reg; 
                end else begin
                    calculated_reciprocal_val_comb = 0;
                end
            end

            if (current_state_reg == S_CALC_RECIP_WAIT) begin
                if (recip_wait_counter_reg > 0) recip_wait_counter_reg <= recip_wait_counter_reg - 1;
                if (recip_wait_counter_reg == 1) begin 
                    recip_sum_exp_reg <= calculated_reciprocal_val_comb; 
                end
            end
            if (current_state_reg == S_NORMALIZE_INIT) idx_counter_reg <= 0;
            
            if (current_state_reg == S_NORMALIZE_LOOP) begin
                if (idx_counter_reg < N) begin
                    temp_prod_norm_comb = $signed(exp_values_buf[idx_counter_reg]) * $signed(recip_sum_exp_reg);
                    if (FINAL_NORM_SHIFT >= 0) scaled_final_val_comb = temp_prod_norm_comb >>> FINAL_NORM_SHIFT;
                    else scaled_final_val_comb = temp_prod_norm_comb <<< (-FINAL_NORM_SHIFT);
                    output_vector_y[idx_counter_reg] <= scaled_final_val_comb;
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end
        end
    end
endmodule


// exp_lut_unit.v (Corrected LUT Addressing and Logic for User's Parameters)
module exp_lut_unit #(
    parameter INPUT_WIDTH         = 12, // Q4.8 (S III FFFFFFFF)
    parameter INPUT_FRAC_BITS     = 8,
    parameter OUTPUT_WIDTH        = 16, // Q1.15 (S .FFFFFFFFFFFFFFF) per TB expectation
    parameter OUTPUT_FRAC_BITS    = 15,
    parameter LUT_ADDR_WIDTH      = 8,   // 256 entries, matches Python script's N
    parameter EXP_LUT_LATENCY     = 1
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          start_exp,
    input  wire signed [INPUT_WIDTH-1:0] x_in,

    output reg [OUTPUT_WIDTH-1:0]        y_out,    // Matched to user's TB (unsigned)
    output reg                           exp_done
);

    reg signed [INPUT_WIDTH-1:0] x_in_r;
    reg [EXP_LUT_LATENCY:0]      latency_counter_reg;
    reg                          exp_done_pulse_reg;

    wire [INPUT_WIDTH-1:0]     abs_x_comb = (x_in_r[INPUT_WIDTH-1] && x_in_r != 0) ? -x_in_r : x_in_r;
    
    // Integer part of abs_x (e.g., bits [11:8] for Q4.8)
    wire [INPUT_WIDTH-1-INPUT_FRAC_BITS:0] abs_x_integer_part = abs_x_comb[INPUT_WIDTH-1 : INPUT_FRAC_BITS];
    
    // Fractional part of abs_x (e.g., bits [7:0] for Q4.8) used for LUT address
    wire [LUT_ADDR_WIDTH-1:0] lut_addr_calc;
    // Python script uses i from 0 to N-1 (255) as address, where x_for_exp = i / (2^FRAC_BITS)
    // So, if abs_x_comb < 1.0, its fractional part scaled by 2^FRAC_BITS is the address.
    // Since LUT_ADDR_WIDTH == INPUT_FRAC_BITS here, we use all fractional bits.
    assign lut_addr_calc = abs_x_comb[INPUT_FRAC_BITS-1 : 0];


    reg [OUTPUT_WIDTH-1:0] lut [0:(1<<LUT_ADDR_WIDTH)-1];
    initial begin
        $display("[%0t EXP_LUT_DUT] Reading exp_lut.mem (LUT_SIZE=%d)...", $time, (1<<LUT_ADDR_WIDTH));
        $readmemh("exp_lut.mem", lut); // Generated by Python script
    end

    wire [OUTPUT_WIDTH-1:0] lut_out_comb;

    // LUT lookup logic
    assign lut_out_comb = (x_in_r == 0) ? OUTPUT_WIDTH'(1 << OUTPUT_FRAC_BITS) : // exp(0) = 1.0
                        (x_in_r > 0) ? OUTPUT_WIDTH'(1) : // Error/Smallest: Input should be <=0
                        (|abs_x_integer_part) ? OUTPUT_WIDTH'(1) : // If abs(x_in_r) >= 1.0, exp(-abs(x)) is small
                                                                   // Python LUT only covers abs(x) in [0, 1)
                        lut[lut_addr_calc]; // Use fractional part as address if abs(x_in_r) < 1.0

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_in_r <= 0;
            y_out <= 0;
            exp_done <= 1'b0;
            latency_counter_reg <= 0;
            exp_done_pulse_reg <= 1'b0;
        end else begin
            exp_done_pulse_reg <= 1'b0;

            if (start_exp) begin
                x_in_r <= x_in;
                if (EXP_LUT_LATENCY == 0) begin
                    y_out <= lut_out_comb;
                    exp_done_pulse_reg <= 1'b1;
                end else begin
                    latency_counter_reg <= EXP_LUT_LATENCY;
                    exp_done <= 1'b0;
                end
            end else if (latency_counter_reg > 0) begin
                latency_counter_reg <= latency_counter_reg - 1;
                if (latency_counter_reg == 1) begin
                    y_out <= lut_out_comb; // lut_out_comb uses x_in_r from start_exp cycle
                    exp_done_pulse_reg <= 1'b1;
                end
            end
            exp_done <= exp_done_pulse_reg;
        end
    end
endmodule


// softmax_unit.v
// Designed to use the user's verified exp_lut_unit.v
module softmax_unit #(
    parameter N                   = 4,    // Vector length (e.g., sequence length)

    // Input x to Softmax (scaled scores)
    parameter INPUT_DATA_WIDTH    = 16,   
    parameter INPUT_FRAC_BITS     = 8,

    // Output y from Softmax (attention weights)
    parameter OUTPUT_DATA_WIDTH   = 16,   
    parameter OUTPUT_FRAC_BITS    = 15,

    // Parameters for the exp_lut_unit instance (matching user's exp_lut_unit)
    parameter EXP_UNIT_INPUT_WIDTH    = 12, 
    parameter EXP_UNIT_INPUT_FRAC   = 8,  
    parameter EXP_UNIT_OUTPUT_WIDTH   = 16, 
    parameter EXP_UNIT_OUTPUT_FRAC  = 15, // This is the fractional bits of exp_lut_unit's output
    parameter EXP_UNIT_LATENCY      = 1,
    
    // Parameters for sum_exp accumulator
    // Integer bits for exp_val (Q1.15 has 0 explicit integer bits for magnitude). Sum needs $clog2(N) for magnitude.
    parameter SUM_EXP_INT_BITS    = $clog2(N), 
    parameter SUM_EXP_WIDTH       = 1 + SUM_EXP_INT_BITS + EXP_UNIT_OUTPUT_FRAC, // Sign + Int + Frac

    // Parameters for reciprocal (1/sum_exp)
    parameter RECIP_SUM_FRAC_BITS = 15, 
    parameter RECIP_SUM_WIDTH     = 16, // e.g., Q1.15

    parameter RECIP_LATENCY       = 5  // Placeholder for reciprocal unit
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          op_start,

    input wire signed [INPUT_DATA_WIDTH-1:0]  input_vector_x [0:N-1],
    output reg signed [OUTPUT_DATA_WIDTH-1:0] output_vector_y [0:N-1],

    output reg                          op_busy,
    output reg                          op_done
);

    // --- Local Parameters ---
    // Shift for scaling (x_i - max_val) to exp_unit's input format
    localparam SHIFT_FOR_EXP_PREP = INPUT_FRAC_BITS - EXP_UNIT_INPUT_FRAC;
    // Shift for final normalization: (FracBitsOf(exp_out) + FracBitsOf(recip_sum)) - FracBitsOf(output_y)
    localparam FINAL_NORM_SHIFT = (EXP_UNIT_OUTPUT_FRAC + RECIP_SUM_FRAC_BITS) - OUTPUT_FRAC_BITS;


    // --- FSM State Definitions ---
    localparam S_IDLE                   = 4'd0;
    localparam S_LATCH_INPUTS           = 4'd1;
    localparam S_FIND_MAX_INIT          = 4'd2;
    localparam S_FIND_MAX_LOOP          = 4'd3;
    localparam S_EXP_SUM_INIT           = 4'd4;
    localparam S_EXP_SUM_FETCH_X        = 4'd5; 
    localparam S_EXP_SUM_START_EXP      = 4'd6; 
    localparam S_EXP_SUM_WAIT_EXP       = 4'd7; 
    localparam S_EXP_SUM_ACCUM          = 4'd8; 
    localparam S_CALC_RECIP_START       = 4'd9;
    localparam S_CALC_RECIP_WAIT        = 4'd10;
    localparam S_NORMALIZE_INIT         = 4'd11;
    localparam S_NORMALIZE_LOOP         = 4'd12; 
    localparam S_DONE                   = 4'd13;

    reg [3:0] current_state_reg, next_state_comb;

    // --- Datapath Registers & Wires ---
    reg signed [INPUT_DATA_WIDTH-1:0]   x_internal_reg [0:N-1];
    reg signed [INPUT_DATA_WIDTH-1:0]   max_val_reg;    
    
    reg signed [EXP_UNIT_OUTPUT_WIDTH-1:0] exp_values_buf [0:N-1]; 
    reg signed [SUM_EXP_WIDTH-1:0]         sum_exp_values_acc_reg;
    reg signed [RECIP_SUM_WIDTH-1:0]       recip_sum_exp_reg; 

    reg [$clog2(N+1)-1:0]               idx_counter_reg; 
    reg [$clog2(N+1)-1:0]               idx_for_exp_result_reg; 

    reg                                 exp_unit_start_reg_to_dut;
    wire signed [EXP_UNIT_OUTPUT_WIDTH-1:0] exp_unit_y_out_from_dut;
    wire                                exp_unit_done_from_dut;  
    
    wire signed [EXP_UNIT_INPUT_WIDTH-1:0]  shifted_x_for_exp_unit; 
    
    reg [$clog2(RECIP_LATENCY+1)-1:0]   recip_wait_counter_reg;

    reg op_start_d1;
    wire op_start_posedge = op_start && !op_start_d1;
    integer i; 

    // Wires for intermediate steps of current_shifted_x_for_exp calculation
    wire signed [INPUT_DATA_WIDTH:0]   w_temp_diff_shifted_x; 
    wire signed [INPUT_DATA_WIDTH:0]   w_temp_scaled_shifted_x;    


    exp_lut_unit #(
        .INPUT_WIDTH(EXP_UNIT_INPUT_WIDTH),     
        .INPUT_FRAC_BITS(EXP_UNIT_INPUT_FRAC),  
        .OUTPUT_WIDTH(EXP_UNIT_OUTPUT_WIDTH),             
        .OUTPUT_FRAC_BITS(EXP_UNIT_OUTPUT_FRAC),     
        .EXP_LUT_LATENCY(EXP_UNIT_LATENCY)      
    ) exp_inst (
        .clk(clk), .rst_n(rst_n),
        .start_exp(exp_unit_start_reg_to_dut), 
        .x_in(shifted_x_for_exp_unit), 
        .y_out(exp_unit_y_out_from_dut),
        .exp_done(exp_unit_done_from_dut)
    );

    assign w_temp_diff_shifted_x = (current_state_reg == S_EXP_SUM_FETCH_X && idx_counter_reg < N) ?
                                 ($signed(x_internal_reg[idx_counter_reg]) - $signed(max_val_reg)) : 0;

    assign w_temp_scaled_shifted_x = (SHIFT_FOR_EXP_PREP >= 0) ?
                                   (w_temp_diff_shifted_x >>> SHIFT_FOR_EXP_PREP) :
                                   (w_temp_diff_shifted_x <<< (-SHIFT_FOR_EXP_PREP));

    assign shifted_x_for_exp_unit = 
     ( (INPUT_DATA_WIDTH+1) == EXP_UNIT_INPUT_WIDTH ) ? 
        w_temp_scaled_shifted_x[EXP_UNIT_INPUT_WIDTH-1:0] : 
     ( (INPUT_DATA_WIDTH+1) < EXP_UNIT_INPUT_WIDTH ) ? 
        $signed({{(EXP_UNIT_INPUT_WIDTH - (INPUT_DATA_WIDTH+1)){w_temp_scaled_shifted_x[INPUT_DATA_WIDTH]}}, 
                 w_temp_scaled_shifted_x}) :
        $signed(w_temp_scaled_shifted_x[EXP_UNIT_INPUT_WIDTH-1:0]);
    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state_reg <= S_IDLE; else current_state_reg <= next_state_comb;
        op_start_d1 <= rst_n ? op_start : 1'b0;
    end

    always_comb begin
        next_state_comb = current_state_reg; 
        op_busy         = (current_state_reg != S_IDLE && current_state_reg != S_DONE);
        op_done         = (current_state_reg == S_DONE);
        exp_unit_start_reg_to_dut  = 1'b0; 

        case (current_state_reg)
            S_IDLE: if (op_start_posedge) next_state_comb = S_LATCH_INPUTS;
            S_LATCH_INPUTS: next_state_comb = S_FIND_MAX_INIT;
            S_FIND_MAX_INIT: next_state_comb = S_FIND_MAX_LOOP;
            S_FIND_MAX_LOOP: if (idx_counter_reg == N) next_state_comb = S_EXP_SUM_INIT;
            S_EXP_SUM_INIT: next_state_comb = S_EXP_SUM_FETCH_X;
            S_EXP_SUM_FETCH_X: if (idx_counter_reg < N) next_state_comb = S_EXP_SUM_START_EXP; else next_state_comb = S_CALC_RECIP_START; 
            S_EXP_SUM_START_EXP: begin exp_unit_start_reg_to_dut = 1'b1; next_state_comb = S_EXP_SUM_WAIT_EXP; end
            S_EXP_SUM_WAIT_EXP: if (exp_unit_done_from_dut) next_state_comb = S_EXP_SUM_ACCUM;
            S_EXP_SUM_ACCUM: next_state_comb = S_EXP_SUM_FETCH_X; 
            S_CALC_RECIP_START: next_state_comb = S_CALC_RECIP_WAIT;
            S_CALC_RECIP_WAIT: if (recip_wait_counter_reg == 0) next_state_comb = S_NORMALIZE_INIT;
            S_NORMALIZE_INIT: next_state_comb = S_NORMALIZE_LOOP;
            S_NORMALIZE_LOOP: if (idx_counter_reg == N) next_state_comb = S_DONE;
            S_DONE: next_state_comb = S_IDLE;
            default: next_state_comb = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        // Local variables for this clocked block
        logic signed [EXP_UNIT_OUTPUT_WIDTH + RECIP_SUM_WIDTH - 1:0] temp_prod_norm_comb; // Corrected: Use EXP_UNIT_OUTPUT_WIDTH
        logic signed [OUTPUT_DATA_WIDTH-1:0] scaled_final_val_comb;
        logic signed [RECIP_SUM_WIDTH-1:0]   calculated_reciprocal_val_comb;
        logic signed [(RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC + 1) -1:0] numerator_for_recip_comb; // Corrected


        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                x_internal_reg[i] <= 0;
                exp_values_buf[i] <= 0;
                output_vector_y[i] <= 0;
            end
            max_val_reg <= {1'b1, {(INPUT_DATA_WIDTH-1){1'b0}}}; 
            sum_exp_values_acc_reg <= 0;
            recip_sum_exp_reg <= 0;
            idx_counter_reg <= 0;
            idx_for_exp_result_reg <= 0;
            recip_wait_counter_reg <= 0;
        end else begin
            if (current_state_reg == S_LATCH_INPUTS) begin
                for (i = 0; i < N; i = i + 1) x_internal_reg[i] <= input_vector_x[i];
            end
            if (current_state_reg == S_FIND_MAX_INIT) begin
                if (N > 0) max_val_reg <= x_internal_reg[0]; else max_val_reg <= 0;
                idx_counter_reg <= 1; 
            end
            if (current_state_reg == S_FIND_MAX_LOOP) begin
                if (idx_counter_reg < N) begin
                    if (x_internal_reg[idx_counter_reg] > max_val_reg) max_val_reg <= x_internal_reg[idx_counter_reg];
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end
            if (current_state_reg == S_EXP_SUM_INIT) begin
                idx_counter_reg <= 0; sum_exp_values_acc_reg <= 0;
            end
            if (current_state_reg == S_EXP_SUM_START_EXP) idx_for_exp_result_reg <= idx_counter_reg;
            
            if (current_state_reg == S_EXP_SUM_ACCUM) begin 
                if (idx_for_exp_result_reg < N) begin 
                    exp_values_buf[idx_for_exp_result_reg] <= exp_unit_y_out_from_dut; 
                    sum_exp_values_acc_reg <= sum_exp_values_acc_reg + $signed({{(SUM_EXP_WIDTH-EXP_UNIT_OUTPUT_WIDTH){exp_unit_y_out_from_dut[EXP_UNIT_OUTPUT_WIDTH-1]}},exp_unit_y_out_from_dut}); 
                end
                idx_counter_reg <= idx_counter_reg + 1; 
            end
            
            if (current_state_reg == S_CALC_RECIP_START) begin
                recip_wait_counter_reg <= RECIP_LATENCY;
                // Calculate combinational value for reciprocal here
                if (sum_exp_values_acc_reg != 0) begin
                    // Numerator for 1.0, scaled to have (RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC) fractional bits
                    numerator_for_recip_comb = 1 << (RECIP_SUM_FRAC_BITS + EXP_UNIT_OUTPUT_FRAC); // Use correct param
                    calculated_reciprocal_val_comb = numerator_for_recip_comb / sum_exp_values_acc_reg; 
                end else begin
                    calculated_reciprocal_val_comb = 0;
                end
            end

            if (current_state_reg == S_CALC_RECIP_WAIT) begin
                if (recip_wait_counter_reg > 0) recip_wait_counter_reg <= recip_wait_counter_reg - 1;
                if (recip_wait_counter_reg == 1) begin 
                    recip_sum_exp_reg <= calculated_reciprocal_val_comb; 
                end
            end
            if (current_state_reg == S_NORMALIZE_INIT) idx_counter_reg <= 0;
            
            if (current_state_reg == S_NORMALIZE_LOOP) begin
                if (idx_counter_reg < N) begin
                    temp_prod_norm_comb = $signed(exp_values_buf[idx_counter_reg]) * $signed(recip_sum_exp_reg);
                    if (FINAL_NORM_SHIFT >= 0) scaled_final_val_comb = temp_prod_norm_comb >>> FINAL_NORM_SHIFT;
                    else scaled_final_val_comb = temp_prod_norm_comb <<< (-FINAL_NORM_SHIFT);
                    output_vector_y[idx_counter_reg] <= scaled_final_val_comb;
                    idx_counter_reg <= idx_counter_reg + 1;
                end
            end
        end
    end
endmodule