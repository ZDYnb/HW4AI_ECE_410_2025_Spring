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
