// layer_norm_pe.v (Pipelined Processing Element - Pure Pipeline & Centralized Debug)
module layer_norm_pe #(
    // Input/Output Data Format Parameters
    parameter X_WIDTH         = 16, parameter X_FRAC        = 10, // x_i: S5.10
    parameter MU_WIDTH        = 24, parameter MU_FRAC       = 10, // mu: S13.10
    parameter INV_STD_WIDTH   = 24, parameter INV_STD_FRAC  = 14, // inv_std_eff: S9.14
    parameter GAMMA_WIDTH     = 8,  parameter GAMMA_FRAC    = 6,  // gamma_i: S1.6
    parameter BETA_WIDTH      = 8,  parameter BETA_FRAC     = 6,  // beta_i: S1.6
    parameter Y_WIDTH         = 16, parameter Y_FRAC        = 10, // y_i: S5.10

    // Intermediate Stage Format Parameters
    parameter STAGE1_OUT_WIDTH = 24, parameter STAGE1_OUT_FRAC = 10, // centered_x: S13.10
    parameter STAGE2_OUT_WIDTH = 24, parameter STAGE2_OUT_FRAC = 21, // normalized_x: S2.21
    parameter STAGE3_OUT_WIDTH = 24, parameter STAGE3_OUT_FRAC = 18, // scaled_x: S5.18
    parameter STAGE4_OUT_WIDTH = 24, parameter STAGE4_OUT_FRAC = 18  // y_i_sum: S5.18
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in_pe,

    input wire signed [X_WIDTH-1:0]         x_i_in,
    input wire signed [MU_WIDTH-1:0]        mu_common_in,
    input wire signed [INV_STD_WIDTH-1:0]   inv_std_eff_common_in,
    input wire signed [GAMMA_WIDTH-1:0]     gamma_i_in,
    input wire signed [BETA_WIDTH-1:0]      beta_i_in,

    output reg signed [Y_WIDTH-1:0]         y_i_out,
    output reg                              valid_out_pe
);

    // Min/Max constants for saturation
    parameter signed [STAGE2_OUT_WIDTH-1:0] S2_21_MAX_VAL = {1'b0,  2'b11, {(STAGE2_OUT_FRAC){1'b1}}};
    parameter signed [STAGE2_OUT_WIDTH-1:0] S2_21_MIN_VAL = {1'b1,  2'b00, {(STAGE2_OUT_FRAC){1'b0}}};
    parameter signed [STAGE3_OUT_WIDTH-1:0] S5_18_MAX_VAL = {1'b0,  5'b11111, {(STAGE3_OUT_FRAC){1'b1}}};
    parameter signed [STAGE3_OUT_WIDTH-1:0] S5_18_MIN_VAL = {1'b1,  5'b00000, {(STAGE3_OUT_FRAC){1'b0}}};
    parameter signed [Y_WIDTH-1:0]          S5_10_MAX_VAL = {1'b0,  5'b11111, {(Y_FRAC){1'b1}}};
    parameter signed [Y_WIDTH-1:0]          S5_10_MIN_VAL = {1'b1,  5'b00000, {(Y_FRAC){1'b0}}};

    // Pipeline Registers
    reg signed [X_WIDTH-1:0]          x_i_s0_reg;
    reg signed [MU_WIDTH-1:0]         mu_s0_reg;
    reg signed [INV_STD_WIDTH-1:0]    inv_std_eff_s0_reg; 
    reg signed [GAMMA_WIDTH-1:0]      gamma_s0_reg;       
    reg signed [BETA_WIDTH-1:0]       beta_s0_reg;   
    reg                               valid_s0_reg;

    reg signed [STAGE1_OUT_WIDTH-1:0] centered_x_s1_reg;
    reg signed [INV_STD_WIDTH-1:0]    inv_std_eff_s1_reg; 
    reg signed [GAMMA_WIDTH-1:0]      gamma_s1_reg;       
    reg signed [BETA_WIDTH-1:0]       beta_s1_reg;        
    reg                               valid_s1_reg;

    reg signed [STAGE2_OUT_WIDTH-1:0] normalized_x_s2_reg;
    reg signed [GAMMA_WIDTH-1:0]      gamma_s2_reg;
    reg signed [BETA_WIDTH-1:0]       beta_s2_reg;
    reg                               valid_s2_reg;

    reg signed [STAGE3_OUT_WIDTH-1:0] scaled_x_s3_reg;
    reg signed [BETA_WIDTH-1:0]       beta_s3_reg;
    reg                               valid_s3_reg;

    reg signed [STAGE4_OUT_WIDTH-1:0] y_i_sum_s4_reg;
    reg                               valid_s4_reg;
    
    // Combinational Logic Wires
    wire signed [STAGE1_OUT_WIDTH-1:0] x_extended_s1_w;
    wire signed [STAGE1_OUT_WIDTH-1:0] centered_x_s1_comb_w;

    parameter PRODUCT1_WIDTH      = STAGE1_OUT_WIDTH + INV_STD_WIDTH;
    parameter PRODUCT1_FRAC_BITS  = STAGE1_OUT_FRAC + INV_STD_FRAC;  
    parameter S2_SHIFT_AMOUNT     = PRODUCT1_FRAC_BITS - STAGE2_OUT_FRAC; 
    parameter S2_ROUND_CONST_VAL  = (S2_SHIFT_AMOUNT > 0) ? (1 << (S2_SHIFT_AMOUNT - 1)) : 0;
    wire signed [PRODUCT1_WIDTH-1:0]   product1_full_s2_w;
    wire signed [PRODUCT1_WIDTH-1:0]   product1_rounded_s2_w;
    wire signed [PRODUCT1_WIDTH-1:0]   product1_shifted_s2_w;
    wire signed [STAGE2_OUT_WIDTH-1:0] normalized_x_presat_s2_w;
    wire signed [STAGE2_OUT_WIDTH-1:0] normalized_x_s2_comb_w;

    parameter PRODUCT2_WIDTH      = STAGE2_OUT_WIDTH + GAMMA_WIDTH; 
    parameter PRODUCT2_FRAC_BITS  = STAGE2_OUT_FRAC + GAMMA_FRAC;   
    parameter S3_SHIFT_AMOUNT     = PRODUCT2_FRAC_BITS - STAGE3_OUT_FRAC; 
    parameter S3_ROUND_CONST_VAL  = (S3_SHIFT_AMOUNT > 0) ? (1 << (S3_SHIFT_AMOUNT - 1)) : 0;
    wire signed [PRODUCT2_WIDTH-1:0]   product2_full_s3_w;
    wire signed [PRODUCT2_WIDTH-1:0]   product2_rounded_s3_w;
    wire signed [PRODUCT2_WIDTH-1:0]   product2_shifted_s3_w;
    wire signed [STAGE3_OUT_WIDTH-1:0] scaled_x_presat_s3_w;
    wire signed [STAGE3_OUT_WIDTH-1:0] scaled_x_s3_comb_w;
    
    wire signed [STAGE4_OUT_WIDTH-1:0] beta_i_aligned_s4_comb_w;
    wire signed [STAGE4_OUT_WIDTH:0]   y_i_sum_s4_raw_w; 
    wire signed [STAGE4_OUT_WIDTH-1:0] y_i_sum_s4_comb_w;
    
    parameter S5_SHIFT_AMOUNT    = STAGE4_OUT_FRAC - Y_FRAC; 
    parameter S5_ROUND_CONST_VAL = (S5_SHIFT_AMOUNT > 0) ? (1 << (S5_SHIFT_AMOUNT - 1)) : 0;
    wire signed [STAGE4_OUT_WIDTH-1:0] sum_plus_round_S5_w;
    wire signed [STAGE4_OUT_WIDTH-1:0] sum_shifted_S5_w;
    wire signed [Y_WIDTH-1:0]          y_i_presat_s5_w;
    wire signed [Y_WIDTH-1:0]          y_i_final_s5_comb_w;

    // --- Stage 1 Calculations (using s0_reg values) ---
    assign x_extended_s1_w = {{ (STAGE1_OUT_WIDTH - X_WIDTH) {x_i_s0_reg[X_WIDTH-1]} }, x_i_s0_reg};
    assign centered_x_s1_comb_w = x_extended_s1_w - mu_s0_reg;

    // --- Stage 2 Calculations (using s1_reg values) ---
    assign product1_full_s2_w = centered_x_s1_reg * inv_std_eff_s1_reg;
    assign product1_rounded_s2_w = product1_full_s2_w + S2_ROUND_CONST_VAL;
    assign product1_shifted_s2_w = product1_rounded_s2_w >>> S2_SHIFT_AMOUNT;
    assign normalized_x_presat_s2_w = product1_shifted_s2_w[STAGE2_OUT_WIDTH-1:0];
    assign normalized_x_s2_comb_w = (normalized_x_presat_s2_w > S2_21_MAX_VAL) ? S2_21_MAX_VAL :
                                   ((normalized_x_presat_s2_w < S2_21_MIN_VAL) ? S2_21_MIN_VAL :
                                    normalized_x_presat_s2_w);

    // --- Stage 3 Calculations (using s2_reg values) ---
    assign product2_full_s3_w = normalized_x_s2_reg * gamma_s2_reg;
    assign product2_rounded_s3_w = product2_full_s3_w + S3_ROUND_CONST_VAL;
    assign product2_shifted_s3_w = product2_rounded_s3_w >>> S3_SHIFT_AMOUNT;
    assign scaled_x_presat_s3_w = product2_shifted_s3_w[STAGE3_OUT_WIDTH-1:0];
    assign scaled_x_s3_comb_w = (scaled_x_presat_s3_w > S5_18_MAX_VAL) ? S5_18_MAX_VAL :
                               ((scaled_x_presat_s3_w < S5_18_MIN_VAL) ? S5_18_MIN_VAL :
                                scaled_x_presat_s3_w);
    
    // --- Stage 4 Calculations (using s3_reg values) ---
    wire beta_s3_sign_w = beta_s3_reg[BETA_WIDTH-1];
    wire beta_s3_int_bit_w = beta_s3_reg[BETA_WIDTH-2]; // Assuming S1.6 format for beta (1 integer bit)
    wire [BETA_FRAC-1:0] beta_s3_frac_val_w = beta_s3_reg[BETA_FRAC-1:0];
    // Calculate padding widths for beta alignment to S5.18 (1s, 5i, 18f)
    localparam BETA_S4_TARGET_INT_BITS = STAGE4_OUT_WIDTH - 1 - STAGE4_OUT_FRAC; // Should be 5
    localparam BETA_S3_ACTUAL_INT_BITS = BETA_WIDTH - 1 - BETA_FRAC;       // Should be 1
    localparam BETA_S4_INT_PAD_WIDTH = BETA_S4_TARGET_INT_BITS - BETA_S3_ACTUAL_INT_BITS;
    localparam BETA_S4_FRAC_PAD_WIDTH = STAGE4_OUT_FRAC - BETA_FRAC; // Should be 18-6=12

    assign beta_i_aligned_s4_comb_w = {beta_s3_sign_w, 
                                     {{BETA_S4_INT_PAD_WIDTH{beta_s3_sign_w}}, beta_s3_int_bit_w}, 
                                     {beta_s3_frac_val_w, {BETA_S4_FRAC_PAD_WIDTH{1'b0}}} };
                                        
    assign y_i_sum_s4_raw_w = scaled_x_s3_reg + beta_i_aligned_s4_comb_w;
    assign y_i_sum_s4_comb_w = (y_i_sum_s4_raw_w > S5_18_MAX_VAL) ? S5_18_MAX_VAL :
                              ((y_i_sum_s4_raw_w < S5_18_MIN_VAL) ? S5_18_MIN_VAL :
                               y_i_sum_s4_raw_w[STAGE4_OUT_WIDTH-1:0]); // Truncate if in range (raw is wider)
    
    // --- Stage 5 Calculations (using s4_reg values) ---
    assign sum_plus_round_S5_w = y_i_sum_s4_reg + S5_ROUND_CONST_VAL;
    assign sum_shifted_S5_w = sum_plus_round_S5_w >>> S5_SHIFT_AMOUNT;
    assign y_i_presat_s5_w = sum_shifted_S5_w[Y_WIDTH-1:0];
    assign y_i_final_s5_comb_w = (y_i_presat_s5_w > S5_10_MAX_VAL) ? S5_10_MAX_VAL :
                                ((y_i_presat_s5_w < S5_10_MIN_VAL) ? S5_10_MIN_VAL :
                                 y_i_presat_s5_w);

    // --- Pipeline Register Updates ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s0_reg <= 1'b0; x_i_s0_reg <= 0; mu_s0_reg <= 0; inv_std_eff_s0_reg <= 0; gamma_s0_reg <= 0; beta_s0_reg <= 0;
            valid_s1_reg <= 1'b0; centered_x_s1_reg <= 0; inv_std_eff_s1_reg <= 0; gamma_s1_reg <= 0; beta_s1_reg <= 0;
            valid_s2_reg <= 1'b0; normalized_x_s2_reg <= 0; gamma_s2_reg <= 0; beta_s2_reg <= 0;
            valid_s3_reg <= 1'b0; scaled_x_s3_reg <= 0; beta_s3_reg <= 0;
            valid_s4_reg <= 1'b0; y_i_sum_s4_reg <= 0;
            valid_out_pe <= 1'b0; y_i_out <= 0;
        end else begin
            // Stage 0: Latch inputs
            valid_s0_reg <= valid_in_pe;
            if (valid_in_pe) begin
                x_i_s0_reg           <= x_i_in;
                mu_s0_reg            <= mu_common_in;
                inv_std_eff_s0_reg   <= inv_std_eff_common_in;
                gamma_s0_reg         <= gamma_i_in;
                beta_s0_reg          <= beta_i_in;
            end

            // Stage 1 registers update based on valid_s0_reg
            valid_s1_reg <= valid_s0_reg;
            if (valid_s0_reg) begin
                centered_x_s1_reg  <= centered_x_s1_comb_w;
                inv_std_eff_s1_reg <= inv_std_eff_s0_reg; 
                gamma_s1_reg       <= gamma_s0_reg;         
                beta_s1_reg        <= beta_s0_reg;   
            end

            // Stage 2 registers update based on valid_s1_reg
            valid_s2_reg <= valid_s1_reg;
            if (valid_s1_reg) begin
                normalized_x_s2_reg <= normalized_x_s2_comb_w;
                gamma_s2_reg        <= gamma_s1_reg; 
                beta_s2_reg         <= beta_s1_reg;  
            end

            // Stage 3 registers update based on valid_s2_reg
            valid_s3_reg <= valid_s2_reg;
            if (valid_s2_reg) begin
                scaled_x_s3_reg <= scaled_x_s3_comb_w;
                beta_s3_reg     <= beta_s2_reg; 
            end

            // Stage 4 registers update based on valid_s3_reg
            valid_s4_reg <= valid_s3_reg;
            if (valid_s3_reg) begin
                y_i_sum_s4_reg <= y_i_sum_s4_comb_w;
            end

            // Stage 5 registers (output registers) update based on valid_s4_reg
            valid_out_pe <= valid_s4_reg; 
            if (valid_s4_reg) begin
                y_i_out <= y_i_final_s5_comb_w;
            end
        end
    end
    
  

endmodule

