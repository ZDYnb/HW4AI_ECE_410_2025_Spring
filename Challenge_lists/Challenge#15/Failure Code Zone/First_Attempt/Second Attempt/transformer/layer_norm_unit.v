// layer_norm_unit.v
module layer_norm_unit #(
    parameter FEATURE_DIM         = 768, 
    parameter DATA_WIDTH          = 16,
    parameter PARAM_WIDTH         = 16,
    parameter FRAC_BITS           = 8,

    parameter SUM_WIDTH           = 32,  
    parameter SUM_SQ_WIDTH        = 48,  

    parameter MEAN_WIDTH          = DATA_WIDTH, 
    parameter VAR_INTERNAL_WIDTH  = SUM_SQ_WIDTH, 
    parameter NORM_FACTOR_INT_BITS= 1, 
    parameter NORM_FACTOR_FRAC_BITS= 16,
    parameter NORM_FACTOR_WIDTH   = 1 + NORM_FACTOR_INT_BITS + NORM_FACTOR_FRAC_BITS, 

    parameter RECIP_N_VALUE_Q16   = ((1 << 16) / FEATURE_DIM), 
    parameter EPSILON_FIXED_POINT = 1, 
    parameter INV_SQRT_LATENCY    = 10  
) (
    input wire clk,
    input wire rst_n,
    input wire op_start, 

    input wire signed [DATA_WIDTH-1:0]  input_vector [0:FEATURE_DIM-1],
    input wire signed [PARAM_WIDTH-1:0] gamma_vector [0:FEATURE_DIM-1],
    input wire signed [PARAM_WIDTH-1:0] beta_vector  [0:FEATURE_DIM-1],

    output reg signed [DATA_WIDTH-1:0] output_vector [0:FEATURE_DIM-1],
    output reg op_busy,
    output reg op_done
);

    localparam IDX_COUNTER_WIDTH = $clog2(FEATURE_DIM + 1); 
    localparam P1_SUM_PIPE_DEPTH = 2; 
    localparam P2_NORM_PIPE_DEPTH = 4; 

    localparam S_IDLE                      = 5'd0;
    localparam S_CALC_SUMS_INIT            = 5'd2; 
    localparam S_CALC_SUMS_LOOP            = 5'd3; 
    localparam S_CALC_SUMS_DRAIN           = 5'd4; 
    localparam S_CALC_MEAN_VAR_START       = 5'd5; 
    localparam S_CALC_MEAN_VAR_WAIT        = 5'd6; 
    localparam S_CALC_INV_SQRT_START       = 5'd7; 
    localparam S_CALC_INV_SQRT_WAIT        = 5'd8; 
    localparam S_NORM_INIT                 = 5'd9; 
    localparam S_NORM_LOOP                 = 5'd10; 
    localparam S_NORM_DRAIN                = 5'd11; 
    localparam S_DONE                      = 5'd12; 

    reg [4:0] current_state_reg, next_state_comb; 

    reg op_start_d1; 
    wire op_start_posedge = op_start && !op_start_d1;

    reg [IDX_COUNTER_WIDTH-1:0]        idx_counter_reg; 
    reg [$clog2(P1_SUM_PIPE_DEPTH+1)-1:0]  p1_drain_counter_reg;
    reg [$clog2(P2_NORM_PIPE_DEPTH+1)-1:0]  p2_drain_counter_reg;
    reg [IDX_COUNTER_WIDTH-1:0]        output_write_idx_reg; 

    reg signed [SUM_WIDTH-1:0]         sum_x_acc_reg;
    reg signed [SUM_SQ_WIDTH-1:0]      sum_x_sq_acc_reg;
    
    reg signed [DATA_WIDTH-1:0]        p1_x_s0_reg;      
    reg signed [DATA_WIDTH-1:0]        p1_x_s1_reg;      
    reg signed [(2*DATA_WIDTH)-1:0]    p1_x_sq_s1_reg;   

    reg signed [MEAN_WIDTH-1:0]        mean_reg;         
    reg signed [VAR_INTERNAL_WIDTH-1:0] variance_plus_epsilon_reg; 
    reg signed [NORM_FACTOR_WIDTH-1:0] norm_factor_reg;
    reg [$clog2(INV_SQRT_LATENCY+1)-1:0] inv_sqrt_wait_counter_reg; 

    reg signed [DATA_WIDTH-1:0]        p2_x_s0_reg;
    reg signed [PARAM_WIDTH-1:0]       p2_gamma_s0_reg;
    reg signed [PARAM_WIDTH-1:0]       p2_beta_s0_reg;
    reg signed [DATA_WIDTH:0]          p2_centered_x_s1_reg; 
    reg signed [PARAM_WIDTH-1:0]       p2_gamma_s1_reg;
    reg signed [PARAM_WIDTH-1:0]       p2_beta_s1_reg;
    
    localparam PROD1_FRAC_BITS = FRAC_BITS + NORM_FACTOR_FRAC_BITS;
    localparam PROD1_WIDTH = DATA_WIDTH + 1 + NORM_FACTOR_WIDTH; 
    reg signed [PROD1_WIDTH-1:0]       p2_normalized_x_s2_reg; 
    
    reg signed [PARAM_WIDTH-1:0]       p2_gamma_s2_reg;
    reg signed [PARAM_WIDTH-1:0]       p2_beta_s2_reg;

    localparam PROD2_FRAC_BITS = PROD1_FRAC_BITS + FRAC_BITS; 
    localparam PROD2_WIDTH = PROD1_WIDTH + PARAM_WIDTH; 
    reg signed [PROD2_WIDTH-1:0]       p2_scaled_x_s3_reg; 

    reg signed [PARAM_WIDTH-1:0]       p2_beta_s3_reg;
    reg signed [DATA_WIDTH-1:0]        p2_final_out_s4_reg;

    reg signed [PROD2_WIDTH-1:0]  dbg_beta_extended_then_shifted;
    reg signed [PROD2_WIDTH-1:0]  dbg_temp_sum_for_final_scaling;

    // Module-level integer loop variables for use in always blocks
    integer i_loop_datapath; // Renamed to avoid conflict if 'i' is used elsewhere


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= S_IDLE;
            op_start_d1 <= 1'b0;
        end else begin
            current_state_reg <= next_state_comb;
            op_start_d1 <= op_start;
        end
    end

    always_comb begin
        next_state_comb = current_state_reg; 
        op_busy         = (current_state_reg != S_IDLE && current_state_reg != S_DONE);
        op_done         = (current_state_reg == S_DONE);
        
        case (current_state_reg)
            S_IDLE: if (op_start_posedge) next_state_comb = S_CALC_SUMS_INIT;
            S_CALC_SUMS_INIT: next_state_comb = S_CALC_SUMS_LOOP;
            S_CALC_SUMS_LOOP: if (idx_counter_reg == FEATURE_DIM) next_state_comb = S_CALC_SUMS_DRAIN; else next_state_comb = S_CALC_SUMS_LOOP;
            S_CALC_SUMS_DRAIN: if (p1_drain_counter_reg == 0) next_state_comb = S_CALC_MEAN_VAR_START; else next_state_comb = S_CALC_SUMS_DRAIN;
            S_CALC_MEAN_VAR_START: next_state_comb = S_CALC_MEAN_VAR_WAIT; 
            S_CALC_MEAN_VAR_WAIT: next_state_comb = S_CALC_INV_SQRT_START;
            S_CALC_INV_SQRT_START: next_state_comb = S_CALC_INV_SQRT_WAIT;
            S_CALC_INV_SQRT_WAIT: if (inv_sqrt_wait_counter_reg == 0) next_state_comb = S_NORM_INIT; else next_state_comb = S_CALC_INV_SQRT_WAIT;
            S_NORM_INIT: next_state_comb = S_NORM_LOOP;
            S_NORM_LOOP: if (idx_counter_reg == FEATURE_DIM) next_state_comb = S_NORM_DRAIN; else next_state_comb = S_NORM_LOOP;
            S_NORM_DRAIN: if (p2_drain_counter_reg == 0) next_state_comb = S_DONE; else next_state_comb = S_NORM_DRAIN;
            S_DONE: next_state_comb = S_IDLE;
            default: next_state_comb = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        logic signed [SUM_SQ_WIDTH-1:0] local_term1_var; 
        logic signed [SUM_SQ_WIDTH-1:0] local_term2_var; 
        logic signed [PROD2_WIDTH-1:0]  local_beta_sign_extended;
        logic signed [PROD2_WIDTH-1:0]  local_beta_shifted; 
        logic signed [PROD2_WIDTH-1:0]  local_temp_sum;
        logic signed [DATA_WIDTH-1:0]   final_scaled_result; 

        if (!rst_n) begin
            idx_counter_reg <= {IDX_COUNTER_WIDTH{1'b0}}; 
            p1_drain_counter_reg <= 0;
            p2_drain_counter_reg <= 0;
            sum_x_acc_reg <= 0;
            sum_x_sq_acc_reg <= 0;
            mean_reg <= 0;
            variance_plus_epsilon_reg <= 0;
            norm_factor_reg <= 0;
            inv_sqrt_wait_counter_reg <= 0;
            output_write_idx_reg <= {IDX_COUNTER_WIDTH{1'b0}}; 

            p1_x_s0_reg <= 0; p1_x_s1_reg <= 0; p1_x_sq_s1_reg <= 0;
            p2_x_s0_reg <= 0; p2_gamma_s0_reg <= 0; p2_beta_s0_reg <= 0;
            p2_centered_x_s1_reg <= 0; p2_gamma_s1_reg <= 0; p2_beta_s1_reg <= 0;
            p2_normalized_x_s2_reg <= 0; p2_gamma_s2_reg <= 0; p2_beta_s2_reg <= 0;
            p2_scaled_x_s3_reg <= 0; p2_beta_s3_reg <= 0;
            p2_final_out_s4_reg <= 0;
            dbg_beta_extended_then_shifted <= 0;
            dbg_temp_sum_for_final_scaling <= 0;
            
            i_loop_datapath = 0; // Use module-level integer for loop
            while(i_loop_datapath < FEATURE_DIM) begin
                output_vector[i_loop_datapath] <= 0;
                i_loop_datapath = i_loop_datapath + 1;
            end

        end else begin
            // Default holds (explicitly listed for clarity, can be omitted for brevity if desired)
            idx_counter_reg <= idx_counter_reg;
            p1_drain_counter_reg <= p1_drain_counter_reg;
            p2_drain_counter_reg <= p2_drain_counter_reg;
            sum_x_acc_reg <= sum_x_acc_reg;
            sum_x_sq_acc_reg <= sum_x_sq_acc_reg;
            mean_reg <= mean_reg;
            variance_plus_epsilon_reg <= variance_plus_epsilon_reg;
            norm_factor_reg <= norm_factor_reg;
            inv_sqrt_wait_counter_reg <= inv_sqrt_wait_counter_reg;
            output_write_idx_reg <= output_write_idx_reg;
            p1_x_s0_reg <= p1_x_s0_reg; p1_x_s1_reg <= p1_x_s1_reg; p1_x_sq_s1_reg <= p1_x_sq_s1_reg;
            p2_x_s0_reg <= p2_x_s0_reg; p2_gamma_s0_reg <= p2_gamma_s0_reg; p2_beta_s0_reg <= p2_beta_s0_reg;
            p2_centered_x_s1_reg <= p2_centered_x_s1_reg; p2_gamma_s1_reg <= p2_gamma_s1_reg; p2_beta_s1_reg <= p2_beta_s1_reg;
            p2_normalized_x_s2_reg <= p2_normalized_x_s2_reg; p2_gamma_s2_reg <= p2_gamma_s2_reg; p2_beta_s2_reg <= p2_beta_s2_reg;
            p2_scaled_x_s3_reg <= p2_scaled_x_s3_reg; p2_beta_s3_reg <= p2_beta_s3_reg;
            p2_final_out_s4_reg <= p2_final_out_s4_reg;
            dbg_beta_extended_then_shifted <= dbg_beta_extended_then_shifted;
            dbg_temp_sum_for_final_scaling <= dbg_temp_sum_for_final_scaling;
            
            // Explicitly hold output_vector elements unless written
            i_loop_datapath = 0;
            while(i_loop_datapath < FEATURE_DIM) begin
                output_vector[i_loop_datapath] <= output_vector[i_loop_datapath];
                i_loop_datapath = i_loop_datapath + 1;
            end

            if (current_state_reg == S_CALC_SUMS_INIT) begin
                sum_x_acc_reg <= 0; sum_x_sq_acc_reg <= 0;
                idx_counter_reg <= {IDX_COUNTER_WIDTH{1'b0}}; 
                p1_drain_counter_reg <= P1_SUM_PIPE_DEPTH; 
                mean_reg <= 0; 
                variance_plus_epsilon_reg <= 0;
                norm_factor_reg <= 0;
            end

            if (current_state_reg == S_CALC_SUMS_LOOP) begin
                if (idx_counter_reg < FEATURE_DIM) begin
                    p1_x_s0_reg <= input_vector[idx_counter_reg]; 
                    idx_counter_reg <= idx_counter_reg + 1;
                end else begin p1_x_s0_reg <= 0; end 
            end else if (current_state_reg == S_CALC_SUMS_DRAIN) begin
                 p1_x_s0_reg <= 0; 
            end
            
            p1_x_s1_reg <= p1_x_s0_reg; 
            p1_x_sq_s1_reg <= $signed(p1_x_s0_reg) * $signed(p1_x_s0_reg); 
            
            if (current_state_reg == S_CALC_SUMS_LOOP || current_state_reg == S_CALC_SUMS_DRAIN) begin
                if ( (current_state_reg == S_CALC_SUMS_LOOP && idx_counter_reg > 0 ) || // Avoid accumulating uninitialized p1_x_s1 on first loop cycle if pipe not full
                     (current_state_reg == S_CALC_SUMS_DRAIN && p1_drain_counter_reg <= P1_SUM_PIPE_DEPTH && p1_drain_counter_reg > 0) ) { 
                    sum_x_acc_reg <= sum_x_acc_reg + $signed({{(SUM_WIDTH - DATA_WIDTH){p1_x_s1_reg[DATA_WIDTH-1]}}, p1_x_s1_reg}); 
                    sum_x_sq_acc_reg <= sum_x_sq_acc_reg + $signed({{(SUM_SQ_WIDTH - (2*DATA_WIDTH)){p1_x_sq_s1_reg[(2*DATA_WIDTH)-1]}}, p1_x_sq_s1_reg}); 
                }
            end

            if (current_state_reg == S_CALC_SUMS_DRAIN && p1_drain_counter_reg > 0) begin
                p1_drain_counter_reg <= p1_drain_counter_reg - 1;
            end

            if (current_state_reg == S_CALC_MEAN_VAR_START) begin
                mean_reg <= (sum_x_acc_reg * RECIP_N_VALUE_Q16) >>> 16; 
            end
            
            if (current_state_reg == S_CALC_MEAN_VAR_WAIT) begin
                local_term1_var = (sum_x_sq_acc_reg * RECIP_N_VALUE_Q16) >>> 16; 
                local_term2_var = $signed(mean_reg) * $signed(mean_reg);         
                variance_plus_epsilon_reg <= local_term1_var - local_term2_var + EPSILON_FIXED_POINT; 
            end

            if (current_state_reg == S_CALC_INV_SQRT_START) begin
                inv_sqrt_wait_counter_reg <= INV_SQRT_LATENCY; 
            end
            if (current_state_reg == S_CALC_INV_SQRT_WAIT) begin
                if (inv_sqrt_wait_counter_reg > 0) begin
                    inv_sqrt_wait_counter_reg <= inv_sqrt_wait_counter_reg - 1;
                end
                if (inv_sqrt_wait_counter_reg == 1) begin 
                    norm_factor_reg <= 18'd35030; 
                end
            end
            
            if (current_state_reg == S_NORM_INIT) begin 
                idx_counter_reg <= {IDX_COUNTER_WIDTH{1'b0}}; 
                output_write_idx_reg <= {IDX_COUNTER_WIDTH{1'b0}};
                p2_drain_counter_reg <= P2_NORM_PIPE_DEPTH;
            end

            if (current_state_reg == S_NORM_LOOP) begin
                if (idx_counter_reg < FEATURE_DIM) begin
                    p2_x_s0_reg     <= input_vector[idx_counter_reg];
                    p2_gamma_s0_reg <= gamma_vector[idx_counter_reg];
                    p2_beta_s0_reg  <= beta_vector[idx_counter_reg];
                    idx_counter_reg <= idx_counter_reg + 1;
                end else begin 
                    p2_x_s0_reg     <= 0; p2_gamma_s0_reg <= 0; p2_beta_s0_reg  <= 0;
                end
            end else if (current_state_reg == S_NORM_DRAIN || current_state_reg == S_NORM_INIT) begin 
                 p2_x_s0_reg     <= 0; 
                 p2_gamma_s0_reg <= 0; 
                 p2_beta_s0_reg  <= 0;
            end
            
            p2_centered_x_s1_reg <= p2_x_s0_reg - mean_reg; 
            p2_gamma_s1_reg      <= p2_gamma_s0_reg;
            p2_beta_s1_reg       <= p2_beta_s0_reg;
            
            p2_normalized_x_s2_reg <= $signed(p2_centered_x_s1_reg) * $signed(norm_factor_reg); 
            p2_gamma_s2_reg        <= p2_gamma_s1_reg;
            p2_beta_s2_reg         <= p2_beta_s1_reg;
            
            p2_scaled_x_s3_reg     <= $signed(p2_normalized_x_s2_reg) * $signed(p2_gamma_s2_reg); 
            p2_beta_s3_reg         <= p2_beta_s2_reg;
            
            local_beta_sign_extended = $signed({{(PROD2_WIDTH - PARAM_WIDTH){p2_beta_s3_reg[PARAM_WIDTH-1]}}, p2_beta_s3_reg });
            local_beta_shifted       = local_beta_sign_extended <<< (NORM_FACTOR_FRAC_BITS + FRAC_BITS);
            local_temp_sum           = $signed(p2_scaled_x_s3_reg) + local_beta_shifted;
            
            final_scaled_result     = local_temp_sum >>> (NORM_FACTOR_FRAC_BITS + FRAC_BITS); 
            p2_final_out_s4_reg    <= final_scaled_result; 
            
            dbg_beta_extended_then_shifted <= local_beta_shifted;
            dbg_temp_sum_for_final_scaling <= local_temp_sum;

            if ((current_state_reg == S_NORM_LOOP && idx_counter_reg > P2_NORM_PIPE_DEPTH) ||  
                (current_state_reg == S_NORM_DRAIN && p2_drain_counter_reg > 0) ) begin 
                if (output_write_idx_reg < FEATURE_DIM) begin
                    if (rst_n) begin 
                        $display("[%0t LN_DUT_WRITE] Writing to output_vector[%0d]. Value from p2_final_out_s4_reg: %d. Output_write_idx: %d",
                                 $time, output_write_idx_reg, p2_final_out_s4_reg, output_write_idx_reg);
                    end
                    output_vector[output_write_idx_reg] <= p2_final_out_s4_reg; 
                    output_write_idx_reg <= output_write_idx_reg + 1;
                end
            end
            
            if (current_state_reg == S_NORM_DRAIN && p2_drain_counter_reg > 0) begin
                p2_drain_counter_reg <= p2_drain_counter_reg - 1;
            end
        end
    end

    // LN_DUT DEBUG DISPLAY BLOCK
    always @(posedge clk) begin
        if(rst_n && (op_busy || op_start || op_done || current_state_reg != S_IDLE )) begin 
            $display("[%0t LN_DUT] State: %s, idx: %d, wr_idx: %d, sum_x: %d, sum_sq: %d, mean: %d, var_eps: %d, norm_f: %d | p2_s0_x: %d, p2_s0_g: %d, p2_s0_b: %d | p2_s1_cx: %d | p2_s2_nx: %d | p2_s3_scx: %d, p2_s3_b: %d | dbg_b_shft: %d, dbg_tmp_sum: %d, p2_s4_final: %d | OV[0]:%d,OV[1]:%d,OV[2]:%d,OV[3]:%d | op_done: %b",
                $time,
                (current_state_reg == S_IDLE) ? "IDLE" :
                (current_state_reg == S_CALC_SUMS_INIT) ? "SUM_INIT" :
                (current_state_reg == S_CALC_SUMS_LOOP) ? "SUM_LOOP" :
                (current_state_reg == S_CALC_SUMS_DRAIN) ? "SUM_DRAIN" :
                (current_state_reg == S_CALC_MEAN_VAR_START) ? "MV_START" :
                (current_state_reg == S_CALC_MEAN_VAR_WAIT) ? "MV_WAIT" :
                (current_state_reg == S_CALC_INV_SQRT_START) ? "INV_S_START" :
                (current_state_reg == S_CALC_INV_SQRT_WAIT) ? "INV_S_WAIT" :
                (current_state_reg == S_NORM_INIT) ? "NORM_INIT" :
                (current_state_reg == S_NORM_LOOP) ? "NORM_LOOP" :
                (current_state_reg == S_NORM_DRAIN) ? "NORM_DRAIN" :
                (current_state_reg == S_DONE) ? "DONE" :
                "UNKNOWN_STATE", 
                idx_counter_reg, output_write_idx_reg,
                sum_x_acc_reg, sum_x_sq_acc_reg,
                mean_reg, variance_plus_epsilon_reg, norm_factor_reg,
                p2_x_s0_reg, p2_gamma_s0_reg, p2_beta_s0_reg, 
                p2_centered_x_s1_reg,                     
                p2_normalized_x_s2_reg,                     
                p2_scaled_x_s3_reg, p2_beta_s3_reg,         
                dbg_beta_extended_then_shifted, dbg_temp_sum_for_final_scaling, 
                p2_final_out_s4_reg,                        
                (FEATURE_DIM > 0) ? output_vector[0] : 0, // Conditional display for safety
                (FEATURE_DIM > 1) ? output_vector[1] : 0,
                (FEATURE_DIM > 2) ? output_vector[2] : 0, 
                (FEATURE_DIM > 3) ? output_vector[3] : 0, 
                op_done
            );
        end
    end

endmodule
