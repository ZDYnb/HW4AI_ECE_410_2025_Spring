// LayerNorm Full Pipeline Module - 20-stage Pipeline (Q5.10 format)
// Function: Complete LayerNorm computation - Preprocessing + Square Root + Postprocessing
// Total Latency: 9 stages (preprocessing) + 8 stages (sqrt) + 3 stages (postprocessing) = 20 clock cycles
// Throughput: Can accept a new input vector every clock cycle

module layernorm_pipeline (
    input clk,
    input rst_n,
    
    // Input interface (Q5.10 format)
    input valid_in,
    input [15:0] input_vector_0,  input [15:0] input_vector_1,
    input [15:0] input_vector_2,  input [15:0] input_vector_3,
    input [15:0] input_vector_4,  input [15:0] input_vector_5,
    input [15:0] input_vector_6,  input [15:0] input_vector_7,
    input [15:0] input_vector_8,  input [15:0] input_vector_9,
    input [15:0] input_vector_10, input [15:0] input_vector_11,
    input [15:0] input_vector_12, input [15:0] input_vector_13,
    input [15:0] input_vector_14, input [15:0] input_vector_15,
    
    // Output interface (Q5.10 format)
    output valid_out,
    output signed [15:0] output_vector_0,  output signed [15:0] output_vector_1,
    output signed [15:0] output_vector_2,  output signed [15:0] output_vector_3,
    output signed [15:0] output_vector_4,  output signed [15:0] output_vector_5,
    output signed [15:0] output_vector_6,  output signed [15:0] output_vector_7,
    output signed [15:0] output_vector_8,  output signed [15:0] output_vector_9,
    output signed [15:0] output_vector_10, output signed [15:0] output_vector_11,
    output signed [15:0] output_vector_12, output signed [15:0] output_vector_13,
    output signed [15:0] output_vector_14, output signed [15:0] output_vector_15
);

// =============================================================================
// LayerNorm Parameter Definition (Fixed at Compile Time)
// =============================================================================
// Gamma parameter (scaling factor) - Default is 1.0 (Q5.10 = 0x0400)
parameter [15:0] GAMMA_0  = 16'h0400, GAMMA_1  = 16'h0400, GAMMA_2  = 16'h0400, GAMMA_3  = 16'h0400;
parameter [15:0] GAMMA_4  = 16'h0400, GAMMA_5  = 16'h0400, GAMMA_6  = 16'h0400, GAMMA_7  = 16'h0400;
parameter [15:0] GAMMA_8  = 16'h0400, GAMMA_9  = 16'h0400, GAMMA_10 = 16'h0400, GAMMA_11 = 16'h0400;
parameter [15:0] GAMMA_12 = 16'h0400, GAMMA_13 = 16'h0400, GAMMA_14 = 16'h0400, GAMMA_15 = 16'h0400;

// Beta parameter (offset) - Default is 0.0 (Q5.10 = 0x0000)
parameter [15:0] BETA_0  = 16'h0000, BETA_1  = 16'h0000, BETA_2  = 16'h0000, BETA_3  = 16'h0000;
parameter [15:0] BETA_4  = 16'h0000, BETA_5  = 16'h0000, BETA_6  = 16'h0000, BETA_7  = 16'h0000;
parameter [15:0] BETA_8  = 16'h0000, BETA_9  = 16'h0000, BETA_10 = 16'h0000, BETA_11 = 16'h0000;
parameter [15:0] BETA_12 = 16'h0000, BETA_13 = 16'h0000, BETA_14 = 16'h0000, BETA_15 = 16'h0000;

// =============================================================================
// Inter-module Connection Signals
// =============================================================================

// Preprocessing module → Square root module
wire preprocess_valid_out;
wire signed [15:0] mean_preprocess_to_invsqrt;
wire signed [15:0] variance_preprocess_to_invsqrt;
wire signed [15:0] diff_preprocess_to_invsqrt_0,  diff_preprocess_to_invsqrt_1;
wire signed [15:0] diff_preprocess_to_invsqrt_2,  diff_preprocess_to_invsqrt_3;
wire signed [15:0] diff_preprocess_to_invsqrt_4,  diff_preprocess_to_invsqrt_5;
wire signed [15:0] diff_preprocess_to_invsqrt_6,  diff_preprocess_to_invsqrt_7;
wire signed [15:0] diff_preprocess_to_invsqrt_8,  diff_preprocess_to_invsqrt_9;
wire signed [15:0] diff_preprocess_to_invsqrt_10, diff_preprocess_to_invsqrt_11;
wire signed [15:0] diff_preprocess_to_invsqrt_12, diff_preprocess_to_invsqrt_13;
wire signed [15:0] diff_preprocess_to_invsqrt_14, diff_preprocess_to_invsqrt_15;

// Square root module → Postprocessing module
wire invsqrt_valid_out;
wire signed [15:0] inv_sigma_invsqrt_to_postprocess;
wire signed [15:0] mean_invsqrt_to_postprocess;
wire signed [15:0] diff_invsqrt_to_postprocess_0,  diff_invsqrt_to_postprocess_1;
wire signed [15:0] diff_invsqrt_to_postprocess_2,  diff_invsqrt_to_postprocess_3;
wire signed [15:0] diff_invsqrt_to_postprocess_4,  diff_invsqrt_to_postprocess_5;
wire signed [15:0] diff_invsqrt_to_postprocess_6,  diff_invsqrt_to_postprocess_7;
wire signed [15:0] diff_invsqrt_to_postprocess_8,  diff_invsqrt_to_postprocess_9;
wire signed [15:0] diff_invsqrt_to_postprocess_10, diff_invsqrt_to_postprocess_11;
wire signed [15:0] diff_invsqrt_to_postprocess_12, diff_invsqrt_to_postprocess_13;
wire signed [15:0] diff_invsqrt_to_postprocess_14, diff_invsqrt_to_postprocess_15;

// =============================================================================
// Module Instantiation
// =============================================================================

// Stage 1: Preprocessing module (9-stage pipeline)
// Computes mean, variance, and difference vector
layernorm_preprocess u_preprocess (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(valid_in),
    .input_vector_0(input_vector_0),   .input_vector_1(input_vector_1),
    .input_vector_2(input_vector_2),   .input_vector_3(input_vector_3),
    .input_vector_4(input_vector_4),   .input_vector_5(input_vector_5),
    .input_vector_6(input_vector_6),   .input_vector_7(input_vector_7),
    .input_vector_8(input_vector_8),   .input_vector_9(input_vector_9),
    .input_vector_10(input_vector_10), .input_vector_11(input_vector_11),
    .input_vector_12(input_vector_12), .input_vector_13(input_vector_13),
    .input_vector_14(input_vector_14), .input_vector_15(input_vector_15),
    
    // Output
    .valid_out(preprocess_valid_out),
    .mean_out(mean_preprocess_to_invsqrt),
    .variance_out(variance_preprocess_to_invsqrt),
    .diff_vector_0(diff_preprocess_to_invsqrt_0),   .diff_vector_1(diff_preprocess_to_invsqrt_1),
    .diff_vector_2(diff_preprocess_to_invsqrt_2),   .diff_vector_3(diff_preprocess_to_invsqrt_3),
    .diff_vector_4(diff_preprocess_to_invsqrt_4),   .diff_vector_5(diff_preprocess_to_invsqrt_5),
    .diff_vector_6(diff_preprocess_to_invsqrt_6),   .diff_vector_7(diff_preprocess_to_invsqrt_7),
    .diff_vector_8(diff_preprocess_to_invsqrt_8),   .diff_vector_9(diff_preprocess_to_invsqrt_9),
    .diff_vector_10(diff_preprocess_to_invsqrt_10), .diff_vector_11(diff_preprocess_to_invsqrt_11),
    .diff_vector_12(diff_preprocess_to_invsqrt_12), .diff_vector_13(diff_preprocess_to_invsqrt_13),
    .diff_vector_14(diff_preprocess_to_invsqrt_14), .diff_vector_15(diff_preprocess_to_invsqrt_15)
);

// Stage 2: Square root module (8-stage pipeline)
// Computes 1/√variance
inv_sqrt_newton u_invsqrt (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(preprocess_valid_out),
    .variance_in(variance_preprocess_to_invsqrt),
    .mean_in(mean_preprocess_to_invsqrt),
    .diff_vector_in_0(diff_preprocess_to_invsqrt_0),   .diff_vector_in_1(diff_preprocess_to_invsqrt_1),
    .diff_vector_in_2(diff_preprocess_to_invsqrt_2),   .diff_vector_in_3(diff_preprocess_to_invsqrt_3),
    .diff_vector_in_4(diff_preprocess_to_invsqrt_4),   .diff_vector_in_5(diff_preprocess_to_invsqrt_5),
    .diff_vector_in_6(diff_preprocess_to_invsqrt_6),   .diff_vector_in_7(diff_preprocess_to_invsqrt_7),
    .diff_vector_in_8(diff_preprocess_to_invsqrt_8),   .diff_vector_in_9(diff_preprocess_to_invsqrt_9),
    .diff_vector_in_10(diff_preprocess_to_invsqrt_10), .diff_vector_in_11(diff_preprocess_to_invsqrt_11),
    .diff_vector_in_12(diff_preprocess_to_invsqrt_12), .diff_vector_in_13(diff_preprocess_to_invsqrt_13),
    .diff_vector_in_14(diff_preprocess_to_invsqrt_14), .diff_vector_in_15(diff_preprocess_to_invsqrt_15),
    
    // Output
    .valid_out(invsqrt_valid_out),
    .inv_sigma_out(inv_sigma_invsqrt_to_postprocess),
    .mean_out(mean_invsqrt_to_postprocess),
    .diff_vector_out_0(diff_invsqrt_to_postprocess_0),   .diff_vector_out_1(diff_invsqrt_to_postprocess_1),
    .diff_vector_out_2(diff_invsqrt_to_postprocess_2),   .diff_vector_out_3(diff_invsqrt_to_postprocess_3),
    .diff_vector_out_4(diff_invsqrt_to_postprocess_4),   .diff_vector_out_5(diff_invsqrt_to_postprocess_5),
    .diff_vector_out_6(diff_invsqrt_to_postprocess_6),   .diff_vector_out_7(diff_invsqrt_to_postprocess_7),
    .diff_vector_out_8(diff_invsqrt_to_postprocess_8),   .diff_vector_out_9(diff_invsqrt_to_postprocess_9),
    .diff_vector_out_10(diff_invsqrt_to_postprocess_10), .diff_vector_out_11(diff_invsqrt_to_postprocess_11),
    .diff_vector_out_12(diff_invsqrt_to_postprocess_12), .diff_vector_out_13(diff_invsqrt_to_postprocess_13),
    .diff_vector_out_14(diff_invsqrt_to_postprocess_14), .diff_vector_out_15(diff_invsqrt_to_postprocess_15)
);

// Stage 3: Postprocessing module (3-stage pipeline)
// Normalization, scaling, and offset
layernorm_postprocess u_postprocess (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(invsqrt_valid_out),
    .inv_sigma_in(inv_sigma_invsqrt_to_postprocess),
    .mean_in(mean_invsqrt_to_postprocess),
    .diff_vector_in_0(diff_invsqrt_to_postprocess_0),   .diff_vector_in_1(diff_invsqrt_to_postprocess_1),
    .diff_vector_in_2(diff_invsqrt_to_postprocess_2),   .diff_vector_in_3(diff_invsqrt_to_postprocess_3),
    .diff_vector_in_4(diff_invsqrt_to_postprocess_4),   .diff_vector_in_5(diff_invsqrt_to_postprocess_5),
    .diff_vector_in_6(diff_invsqrt_to_postprocess_6),   .diff_vector_in_7(diff_invsqrt_to_postprocess_7),
    .diff_vector_in_8(diff_invsqrt_to_postprocess_8),   .diff_vector_in_9(diff_invsqrt_to_postprocess_9),
    .diff_vector_in_10(diff_invsqrt_to_postprocess_10), .diff_vector_in_11(diff_invsqrt_to_postprocess_11),
    .diff_vector_in_12(diff_invsqrt_to_postprocess_12), .diff_vector_in_13(diff_invsqrt_to_postprocess_13),
    .diff_vector_in_14(diff_invsqrt_to_postprocess_14), .diff_vector_in_15(diff_invsqrt_to_postprocess_15),
    
    // LayerNorm parameters (compile-time constants)
    .gamma_0(GAMMA_0),   .gamma_1(GAMMA_1),   .gamma_2(GAMMA_2),   .gamma_3(GAMMA_3),
    .gamma_4(GAMMA_4),   .gamma_5(GAMMA_5),   .gamma_6(GAMMA_6),   .gamma_7(GAMMA_7),
    .gamma_8(GAMMA_8),   .gamma_9(GAMMA_9),   .gamma_10(GAMMA_10), .gamma_11(GAMMA_11),
    .gamma_12(GAMMA_12), .gamma_13(GAMMA_13), .gamma_14(GAMMA_14), .gamma_15(GAMMA_15),
    
    .beta_0(BETA_0),   .beta_1(BETA_1),   .beta_2(BETA_2),   .beta_3(BETA_3),
    .beta_4(BETA_4),   .beta_5(BETA_5),   .beta_6(BETA_6),   .beta_7(BETA_7),
    .beta_8(BETA_8),   .beta_9(BETA_9),   .beta_10(BETA_10), .beta_11(BETA_11),
    .beta_12(BETA_12), .beta_13(BETA_13), .beta_14(BETA_14), .beta_15(BETA_15),
    
    // Output
    .valid_out(valid_out),
    .output_vector_0(output_vector_0),   .output_vector_1(output_vector_1),
    .output_vector_2(output_vector_2),   .output_vector_3(output_vector_3),
    .output_vector_4(output_vector_4),   .output_vector_5(output_vector_5),
    .output_vector_6(output_vector_6),   .output_vector_7(output_vector_7),
    .output_vector_8(output_vector_8),   .output_vector_9(output_vector_9),
    .output_vector_10(output_vector_10), .output_vector_11(output_vector_11),
    .output_vector_12(output_vector_12), .output_vector_13(output_vector_13),
    .output_vector_14(output_vector_14), .output_vector_15(output_vector_15)
);

endmodule