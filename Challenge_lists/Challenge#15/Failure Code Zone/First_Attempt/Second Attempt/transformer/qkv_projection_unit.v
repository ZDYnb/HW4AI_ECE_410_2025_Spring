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

