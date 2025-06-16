
// layer_norm_top.v - Complete LayerNorm with Integrated Normalization Unit
module layer_norm_top #(
    parameter D_MODEL = 128,
    parameter X_WIDTH = 16, parameter X_FRAC = 10,
    parameter Y_WIDTH = 16, parameter Y_FRAC = 10, 
    parameter PARAM_WIDTH = 8, parameter PARAM_FRAC = 6,

    parameter INTERNAL_X_WIDTH = 24, 
    parameter INTERNAL_X_FRAC  = 10,
    
    parameter ADDER_OUTPUT_WIDTH = INTERNAL_X_WIDTH + 7,
    
    parameter MEAN_CALC_OUT_WIDTH = INTERNAL_X_WIDTH,

    parameter VARIANCE_UNIT_DATA_WIDTH = INTERNAL_X_WIDTH,
    parameter VARIANCE_UNIT_OUT_WIDTH  = INTERNAL_X_WIDTH, 
    parameter VARIANCE_UNIT_NUM_PE     = 8,
    
    // Variance epsilon adder parameters
    parameter VAR_EPS_DATA_WIDTH = INTERNAL_X_WIDTH,
    parameter VAR_EPS_FRAC_BITS = 20,
    parameter VAR_EPS_EPSILON_INT_VAL = 11,
    
    // Square root unit parameters
    parameter SQRT_DATA_IN_WIDTH = INTERNAL_X_WIDTH,
    parameter SQRT_ROOT_OUT_WIDTH = 12,
    parameter SQRT_S_REG_WIDTH = 16,
    parameter SQRT_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH,
    parameter SQRT_FRAC_BITS_OUT = INTERNAL_X_FRAC,
    
    // Reciprocal unit parameters  
    parameter RECIP_INPUT_X_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_DIVISOR_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_QUOTIENT_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH,
    
    // Normalization unit parameters
    parameter NORM_NUM_PE = 8
) (
    input wire clk,
    input wire rst_n,
    input wire start_in,

    input wire signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_flat_in,
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in,
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in,

    // Debug outputs
    output wire signed [MEAN_CALC_OUT_WIDTH-1:0] mu_out_debug,
    output wire                                   mu_valid_debug,
    output wire signed [VARIANCE_UNIT_OUT_WIDTH-1:0] sigma_sq_out_debug,
    output wire                                      sigma_sq_valid_debug,
    output wire signed [VAR_EPS_DATA_WIDTH-1:0] var_plus_eps_out_debug,
    output wire                                  var_plus_eps_valid_debug,
    output wire signed [SQRT_FINAL_OUT_WIDTH-1:0] std_dev_out_debug,
    output wire                                    std_dev_valid_debug,
    output wire signed [RECIP_FINAL_OUT_WIDTH-1:0] recip_std_dev_out_debug,
    output wire                                     recip_std_dev_valid_debug,
    output reg                                       busy_out_debug,

    // Final outputs
    output wire signed [(D_MODEL * Y_WIDTH) - 1 : 0]     y_vector_flat_out,
    output wire                                          done_valid_out
);

    // --- Pipeline Stage s0: Input Latch & x_i Format Conversion ---
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0]            x_orig_flat_s0_reg;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0]        gamma_s0_reg;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0]        beta_s0_reg;
    reg                                                 valid_s0_reg;

    wire signed [(D_MODEL * INTERNAL_X_WIDTH) - 1 : 0]  x_casted_flat_s0_w;

    // --- Wires for Adder and Mean Calculation ---
    wire signed [ADDER_OUTPUT_WIDTH - 1 : 0] sum_x_from_adder_w;
    wire                                     sum_x_valid_from_adder_w;
    wire signed [MEAN_CALC_OUT_WIDTH-1:0]    mu_from_mean_calc_w;
    wire                                     mu_valid_from_mean_calc_w;
    
    // --- Pipeline Stage s1: mu calculated, x_casted and original x/gamma/beta pipelined ---
    reg signed [MEAN_CALC_OUT_WIDTH-1:0]          mu_s1_reg;
    reg signed [(D_MODEL * INTERNAL_X_WIDTH)-1:0] x_casted_s1_reg;
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0]      x_orig_s1_reg;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0]  gamma_s1_reg;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0]  beta_s1_reg;
    reg                                           valid_s1_reg;

    // --- Wires for Variance Calculation ---
    wire signed [VARIANCE_UNIT_OUT_WIDTH-1:0] variance_from_unit_w;
    wire                                      variance_valid_from_unit_w;
    wire                                      variance_unit_busy_w;
    
    // --- Wires for Variance Epsilon Adder ---
    wire signed [VAR_EPS_DATA_WIDTH-1:0] var_plus_eps_from_adder_w;
    wire                                  var_plus_eps_valid_from_adder_w;
    
    // --- Wires for Square Root Unit ---
    wire signed [SQRT_FINAL_OUT_WIDTH-1:0] std_dev_from_sqrt_w;
    wire                                    std_dev_valid_from_sqrt_w;
    
    // --- Wires for Reciprocal Unit ---
    wire signed [RECIP_FINAL_OUT_WIDTH-1:0] recip_std_dev_from_unit_w;
    wire                                     recip_std_dev_valid_from_unit_w;
    
    // --- Normalization Unit Signals ---
    wire normalization_start;
    wire normalization_busy;
    wire normalization_done;
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] normalized_output;

    // --- Combinational Logic: Cast x_i elements S5.10 -> S13.10 ---
    genvar i_cast_s0_top_v3;
    generate
        for (i_cast_s0_top_v3 = 0; i_cast_s0_top_v3 < D_MODEL; i_cast_s0_top_v3 = i_cast_s0_top_v3 + 1) begin : cast_x_elements_s0_top_v3_gen
            wire signed [X_WIDTH-1:0] x_i_original_val_w_local_cast; 
            wire signed [INTERNAL_X_WIDTH-1:0] x_i_casted_val_w_local_cast; 
            
            localparam CURRENT_X_INT_BITS_CAST = X_WIDTH - 1 - X_FRAC; 
            localparam TARGET_INTERNAL_INT_BITS_CAST = INTERNAL_X_WIDTH - 1 - INTERNAL_X_FRAC; 
            localparam NUM_INT_PAD_BITS_CALC_CAST = (TARGET_INTERNAL_INT_BITS_CAST >= CURRENT_X_INT_BITS_CAST) ? 
                                                    (TARGET_INTERNAL_INT_BITS_CAST - CURRENT_X_INT_BITS_CAST) : 0;

            assign x_i_original_val_w_local_cast = x_orig_flat_s0_reg[(i_cast_s0_top_v3 * X_WIDTH) + X_WIDTH - 1 : (i_cast_s0_top_v3 * X_WIDTH)];

            assign x_i_casted_val_w_local_cast[INTERNAL_X_FRAC-1:0] = x_i_original_val_w_local_cast[X_FRAC-1:0];
            assign x_i_casted_val_w_local_cast[INTERNAL_X_WIDTH-1 : INTERNAL_X_FRAC] = 
                {{NUM_INT_PAD_BITS_CALC_CAST{x_i_original_val_w_local_cast[X_WIDTH-1]}}, x_i_original_val_w_local_cast[X_WIDTH-1 : X_FRAC]};

            assign x_casted_flat_s0_w[(i_cast_s0_top_v3 * INTERNAL_X_WIDTH) + INTERNAL_X_WIDTH - 1 : (i_cast_s0_top_v3 * INTERNAL_X_WIDTH)] = x_i_casted_val_w_local_cast;
        end
    endgenerate

    // --- Sub-Module Instantiations: Statistics Computation Chain ---
    tree_level_pipelined_adder #( 
        .D_MODEL(D_MODEL), 
        .INPUT_WIDTH(INTERNAL_X_WIDTH), 
        .OUTPUT_WIDTH(ADDER_OUTPUT_WIDTH) 
    ) sum_adder_inst (
        .clk(clk), .rst_n(rst_n), 
        .data_in_flat(x_casted_flat_s0_w), 
        .valid_in(valid_s0_reg), 
        .sum_out(sum_x_from_adder_w), 
        .valid_out(sum_x_valid_from_adder_w)
    );

    mean_calculation_unit #( 
        .D_MODEL_VAL(D_MODEL), 
        .SUM_WIDTH(ADDER_OUTPUT_WIDTH), 
        .SUM_FRAC(INTERNAL_X_FRAC), 
        .MEAN_WIDTH(MEAN_CALC_OUT_WIDTH), 
        .MEAN_FRAC(INTERNAL_X_FRAC) 
    ) mean_calc_inst (
        .clk(clk), .rst_n(rst_n), 
        .sum_in(sum_x_from_adder_w), 
        .sum_valid_in(sum_x_valid_from_adder_w), 
        .mean_out(mu_from_mean_calc_w), 
        .mean_valid_out(mu_valid_from_mean_calc_w)
    );

    variance_unit #( 
        .D_MODEL(D_MODEL), 
        .DATA_WIDTH(VARIANCE_UNIT_DATA_WIDTH), 
        .NUM_PE(VARIANCE_UNIT_NUM_PE) 
    ) variance_calc_inst (
        .clk(clk), .rst_n(rst_n), 
        .data_in_flat(x_casted_s1_reg),     
        .mean_in(mu_s1_reg),                
        .start_variance(valid_s1_reg),      
        .variance_out(variance_from_unit_w),  
        .variance_valid(variance_valid_from_unit_w),
        .busy(variance_unit_busy_w)
    );

    variance_epsilon_adder_unit #(
        .DATA_WIDTH(VAR_EPS_DATA_WIDTH),
        .FRAC_BITS(VAR_EPS_FRAC_BITS),
        .EPSILON_INT_VAL(VAR_EPS_EPSILON_INT_VAL)
    ) var_eps_adder_inst (
        .clk(clk), .rst_n(rst_n),
        .variance_in(variance_from_unit_w),
        .variance_valid_in(variance_valid_from_unit_w),
        .var_plus_eps_out(var_plus_eps_from_adder_w),
        .var_plus_eps_valid_out(var_plus_eps_valid_from_adder_w)
    );

    sqrt_non_restoring #(
        .DATA_IN_WIDTH(SQRT_DATA_IN_WIDTH),
        .ROOT_OUT_WIDTH(SQRT_ROOT_OUT_WIDTH),
        .S_REG_WIDTH(SQRT_S_REG_WIDTH),
        .FINAL_OUT_WIDTH(SQRT_FINAL_OUT_WIDTH),
        .FRAC_BITS_OUT(SQRT_FRAC_BITS_OUT)
    ) sqrt_inst (
        .clk(clk), .rst_n(rst_n),
        .radicand_in(var_plus_eps_from_adder_w),
        .valid_in(var_plus_eps_valid_from_adder_w),
        .sqrt_out(std_dev_from_sqrt_w),
        .valid_out(std_dev_valid_from_sqrt_w)
    );

    reciprocal_unit #(
        .INPUT_X_WIDTH(RECIP_INPUT_X_WIDTH),
        .DIVISOR_WIDTH(RECIP_DIVISOR_WIDTH),
        .QUOTIENT_WIDTH(RECIP_QUOTIENT_WIDTH),
        .FINAL_OUT_WIDTH(RECIP_FINAL_OUT_WIDTH)
    ) recip_inst (
        .clk(clk), .rst_n(rst_n),
        .X_in(std_dev_from_sqrt_w),
        .valid_in(std_dev_valid_from_sqrt_w),
        .reciprocal_out(recip_std_dev_from_unit_w),
        .valid_out(recip_std_dev_valid_from_unit_w)
    );

    // --- Normalization Unit (Replaces PE Array) ---
    assign normalization_start = recip_std_dev_valid_from_unit_w && !normalization_busy && !normalization_done;
    
    normalization_unit #(
        .D_MODEL(D_MODEL),
        .NUM_PE(NORM_NUM_PE),
        .X_WIDTH(X_WIDTH), .X_FRAC(X_FRAC),
        .MU_WIDTH(MEAN_CALC_OUT_WIDTH), .MU_FRAC(INTERNAL_X_FRAC),
        .INV_STD_WIDTH(RECIP_FINAL_OUT_WIDTH), .INV_STD_FRAC(14), // Q14.14 format
        .GAMMA_WIDTH(PARAM_WIDTH), .GAMMA_FRAC(PARAM_FRAC),
        .BETA_WIDTH(PARAM_WIDTH), .BETA_FRAC(PARAM_FRAC),
        .Y_WIDTH(Y_WIDTH), .Y_FRAC(Y_FRAC)
    ) norm_unit_inst (
        .clk(clk), .rst_n(rst_n),
        .start_normalize(normalization_start),
        .x_vector_in(x_orig_s1_reg),  // Use original input data
        .gamma_vector_in(gamma_s1_reg),
        .beta_vector_in(beta_s1_reg),
        .mu_in(mu_s1_reg),
        .inv_std_in(recip_std_dev_from_unit_w),
        .y_vector_out(normalized_output),
        .normalize_done(normalization_done),
        .busy(normalization_busy)
    );

    // Connect debug outputs
    assign mu_out_debug = mu_from_mean_calc_w;
    assign mu_valid_debug = mu_valid_from_mean_calc_w;
    assign sigma_sq_out_debug = variance_from_unit_w;
    assign sigma_sq_valid_debug = variance_valid_from_unit_w;
    assign var_plus_eps_out_debug = var_plus_eps_from_adder_w;
    assign var_plus_eps_valid_debug = var_plus_eps_valid_from_adder_w;
    assign std_dev_out_debug = std_dev_from_sqrt_w;
    assign std_dev_valid_debug = std_dev_valid_from_sqrt_w;
    assign recip_std_dev_out_debug = recip_std_dev_from_unit_w;
    assign recip_std_dev_valid_debug = recip_std_dev_valid_from_unit_w;

    // Output assignments
    assign y_vector_flat_out = normalized_output;
    assign done_valid_out = normalization_done;

    // --- Pipeline Register Update & Control Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s0_reg <= 1'b0; 
            x_orig_flat_s0_reg <= 0; 
            gamma_s0_reg <= 0; 
            beta_s0_reg <= 0;
            valid_s1_reg <= 1'b0; 
            mu_s1_reg <= 0; 
            x_casted_s1_reg <= 0; 
            x_orig_s1_reg <=0; 
            gamma_s1_reg <= 0; 
            beta_s1_reg <= 0;
            busy_out_debug <= 1'b0;
        end else begin
            // Stage s0: Latch top-level inputs
            if (start_in && !busy_out_debug) begin
                valid_s0_reg        <= 1'b1;
                x_orig_flat_s0_reg  <= x_vector_flat_in;
                gamma_s0_reg        <= gamma_vector_flat_in;
                beta_s0_reg         <= beta_vector_flat_in;
                busy_out_debug      <= 1'b1; 
            end else begin
                valid_s0_reg <= 1'b0;
            end

            // Stage s1: mu is ready, pipeline data for variance calculation
            valid_s1_reg <= mu_valid_from_mean_calc_w; 
            if (mu_valid_from_mean_calc_w) begin 
                mu_s1_reg           <= mu_from_mean_calc_w;
                x_casted_s1_reg     <= x_casted_flat_s0_w;
                x_orig_s1_reg       <= x_orig_flat_s0_reg; 
                gamma_s1_reg        <= gamma_s0_reg;
                beta_s1_reg         <= beta_s0_reg;
            end

            // Clear busy when normalization is done
            if (normalization_done) begin
                busy_out_debug <= 1'b0;
            end
        end
    end
    
endmodule

