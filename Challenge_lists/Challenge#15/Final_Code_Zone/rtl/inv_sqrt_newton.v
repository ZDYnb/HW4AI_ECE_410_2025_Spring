// Square Root Inverse Module - 8-stage Pipelined Newton's Method (Q5.10 format) - Fixed Temporary Variable Version
// Function: Calculate 1/√variance 
// Input: Variance σ² (Q5.10 format)
// Output: 1/σ (Q5.10 format)

module inv_sqrt_newton (
    input clk,
    input rst_n,
    
    // Input interface
    input valid_in,
    input signed [15:0] variance_in,     // Variance σ² (Q5.10)
    input signed [15:0] mean_in,         // Mean μ (pass-through)
    // Difference vector
    input signed [15:0] diff_vector_in_0,  input signed [15:0] diff_vector_in_1,
    input signed [15:0] diff_vector_in_2,  input signed [15:0] diff_vector_in_3,
    input signed [15:0] diff_vector_in_4,  input signed [15:0] diff_vector_in_5,
    input signed [15:0] diff_vector_in_6,  input signed [15:0] diff_vector_in_7,
    input signed [15:0] diff_vector_in_8,  input signed [15:0] diff_vector_in_9,
    input signed [15:0] diff_vector_in_10, input signed [15:0] diff_vector_in_11,
    input signed [15:0] diff_vector_in_12, input signed [15:0] diff_vector_in_13,
    input signed [15:0] diff_vector_in_14, input signed [15:0] diff_vector_in_15,
    
    // Output interface
    output reg valid_out,
    output reg signed [15:0] inv_sigma_out,  // 1/σ (Q5.10)
    output reg signed [15:0] mean_out,       // Mean μ (pass-through)
    // Difference vector output
    output reg signed [15:0] diff_vector_out_0,  output reg signed [15:0] diff_vector_out_1,
    output reg signed [15:0] diff_vector_out_2,  output reg signed [15:0] diff_vector_out_3,
    output reg signed [15:0] diff_vector_out_4,  output reg signed [15:0] diff_vector_out_5,
    output reg signed [15:0] diff_vector_out_6,  output reg signed [15:0] diff_vector_out_7,
    output reg signed [15:0] diff_vector_out_8,  output reg signed [15:0] diff_vector_out_9,
    output reg signed [15:0] diff_vector_out_10, output reg signed [15:0] diff_vector_out_11,
    output reg signed [15:0] diff_vector_out_12, output reg signed [15:0] diff_vector_out_13,
    output reg signed [15:0] diff_vector_out_14, output reg signed [15:0] diff_vector_out_15
);

// =============================================================================
// Q5.10 Format Constant Definitions
// =============================================================================
localparam Q5_10_ONE = 16'h0400;      // 1.0 in Q5.10
localparam Q5_10_THREE = 16'h0C00;    // 3.0 in Q5.10
localparam Q5_10_HALF = 16'h0200;     // 0.5 in Q5.10

// =============================================================================
// Unified Pipeline Data Structure - Each Stage Has a Complete Data Copy
// =============================================================================

// Valid signal for each stage
reg valid_stage [0:7];  // Stage 0-7

// Each stage has a complete copy of the data structure
reg signed [15:0] variance_stage [0:7];         // Variance at each stage
reg signed [15:0] mean_stage [0:7];             // Mean at each stage

// Difference vector at each stage (each stage has a complete 16-element vector)
reg signed [15:0] diff_vector_stage [0:7][0:15]; // [stage][vector_index]

// Newton's method intermediate variables - each stage has a complete copy
reg signed [15:0] x0_stage [0:7];               // Initial guess x0
reg signed [15:0] x0_sq_stage [0:7];            // x0²
reg signed [15:0] var_x0_sq_stage [0:7];        // variance * x0²
reg signed [15:0] three_minus_1_stage [0:7];    // 3 - variance*x0²
reg signed [15:0] x1_stage [0:7];               // 1st iteration result x1
reg signed [15:0] x1_sq_stage [0:7];            // x1²
reg signed [15:0] var_x1_sq_stage [0:7];        // variance * x1²
reg signed [15:0] three_minus_2_stage [0:7];    // 3 - variance*x1²

// Independent temporary calculation variables for each stage
reg signed [31:0] temp_mult_s1;    // Stage 1: x0² calculation
reg signed [31:0] temp_mult_s2;    // Stage 2: variance × x0² calculation
reg signed [31:0] temp_mult_s4;    // Stage 4: x1 calculation
reg signed [31:0] temp_mult_s5;    // Stage 5: x1² calculation
reg signed [31:0] temp_mult_s6;    // Stage 6: variance × x1² calculation
reg signed [31:0] temp_mult_out;   // Output: final result calculation
reg signed [15:0] temp_three_minus_2_s7;
reg signed [15:0] temp_three_minus_1_s3;

// =============================================================================
// Initial Guess Lookup Table
// =============================================================================
function [15:0] get_initial_guess;
    input [15:0] variance;
    begin
        casez (variance[15:8])
            8'h00: get_initial_guess = 16'h0C00;  // var≈0.010-0.100 -> guess≈3.000
            8'h01: get_initial_guess = 16'h0800;  // var≈0.250-0.400 -> guess≈2.000
            8'h02: get_initial_guess = 16'h0599;  // var≈0.500-0.700 -> guess≈1.400
            8'h03: get_initial_guess = 16'h0466;  // var≈0.800-0.900 -> guess≈1.100
            8'h04: get_initial_guess = 16'h0400;  // var≈1.000-1.200 -> guess≈1.000
            8'h05: get_initial_guess = 16'h0399;  // var≈1.300-1.400 -> guess≈0.900
            8'h06: get_initial_guess = 16'h0333;  // var≈1.500-1.700 -> guess≈0.800
            8'h07: get_initial_guess = 16'h02CC;  // var≈1.800-1.900 -> guess≈0.700
            8'h08: get_initial_guess = 16'h02CC;  // var≈2.000-2.200 -> guess≈0.700
            8'h09: get_initial_guess = 16'h0266;  // var≈2.300-2.400 -> guess≈0.600
            8'h0A: get_initial_guess = 16'h0266;  // var≈2.500-2.700 -> guess≈0.600
            8'h0B: get_initial_guess = 16'h0266;  // var≈2.800-2.900 -> guess≈0.600
            8'h0C: get_initial_guess = 16'h0266;  // var≈3.000-3.200 -> guess≈0.600
            8'h0D: get_initial_guess = 16'h0200;  // var≈3.300-3.500 -> guess≈0.500
            8'h0E: get_initial_guess = 16'h0200;  // var≈3.600-3.700 -> guess≈0.500
            8'h0F: get_initial_guess = 16'h0200;  // var≈3.800-3.900 -> guess≈0.500
            8'h10: get_initial_guess = 16'h0200;  // var≈4.000 -> guess≈0.500
            8'h28: get_initial_guess = 16'h0133;  // var≈10.000-10.200 -> guess≈0.300
            8'h40: get_initial_guess = 16'h00CC;  // var≈16.000 -> guess≈0.200
            default: get_initial_guess = 16'h0100;  // 0.25 safe default
        endcase
    end
endfunction

// =============================================================================
// Main Pipeline Logic - Fixed Temporary Variable Version
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all valid signals and data
        integer i, j;
        for (i = 0; i <= 7; i = i + 1) begin
            valid_stage[i] <= 1'b0;
            variance_stage[i] <= 16'h0000;
            mean_stage[i] <= 16'h0000;
            x0_stage[i] <= 16'h0000;
            x0_sq_stage[i] <= 16'h0000;
            var_x0_sq_stage[i] <= 16'h0000;
            three_minus_1_stage[i] <= 16'h0000;
            x1_stage[i] <= 16'h0000;
            x1_sq_stage[i] <= 16'h0000;
            var_x1_sq_stage[i] <= 16'h0000;
            three_minus_2_stage[i] <= 16'h0000;
            for (j = 0; j <= 15; j = j + 1) begin
                diff_vector_stage[i][j] <= 16'h0000;
            end
        end
        
        // Reset temporary variables
        temp_mult_s1 <= 32'h00000000;
        temp_mult_s2 <= 32'h00000000;
        temp_mult_s4 <= 32'h00000000;
        temp_mult_s5 <= 32'h00000000;
        temp_mult_s6 <= 32'h00000000;
        temp_mult_out <= 32'h00000000;
        
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================================
        // Stage 0: Receive New Input Data + Initial Guess Lookup
        // ================================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // Save new input data to Stage 0
            variance_stage[0] <= variance_in;
            mean_stage[0] <= mean_in;
            diff_vector_stage[0][0]  <= diff_vector_in_0;  diff_vector_stage[0][1]  <= diff_vector_in_1;
            diff_vector_stage[0][2]  <= diff_vector_in_2;  diff_vector_stage[0][3]  <= diff_vector_in_3;
            diff_vector_stage[0][4]  <= diff_vector_in_4;  diff_vector_stage[0][5]  <= diff_vector_in_5;
            diff_vector_stage[0][6]  <= diff_vector_in_6;  diff_vector_stage[0][7]  <= diff_vector_in_7;
            diff_vector_stage[0][8]  <= diff_vector_in_8;  diff_vector_stage[0][9]  <= diff_vector_in_9;
            diff_vector_stage[0][10] <= diff_vector_in_10; diff_vector_stage[0][11] <= diff_vector_in_11;
            diff_vector_stage[0][12] <= diff_vector_in_12; diff_vector_stage[0][13] <= diff_vector_in_13;
            diff_vector_stage[0][14] <= diff_vector_in_14; diff_vector_stage[0][15] <= diff_vector_in_15;
            
            // Stage 0 calculation: initial guess lookup
            x0_stage[0] <= get_initial_guess(variance_in);
            
            // Other variables initialized to 0 (will be calculated in subsequent stages)
            x0_sq_stage[0] <= 16'h0000;
            var_x0_sq_stage[0] <= 16'h0000;
            three_minus_1_stage[0] <= 16'h0000;
            x1_stage[0] <= 16'h0000;
            x1_sq_stage[0] <= 16'h0000;
            var_x1_sq_stage[0] <= 16'h0000;
            three_minus_2_stage[0] <= 16'h0000;
            
            // $display("Stage0: NEW INPUT variance=0x%04x, x0=0x%04x", variance_in, get_initial_guess(variance_in));
        end
        
        // ================================================================
        // Stage 1: Inherit Stage 0 Data + Calculate x0² (using independent temporary variable)
        // ================================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // Inherit all data from Stage 0
            variance_stage[1] <= variance_stage[0];
            mean_stage[1] <= mean_stage[0];
            // Copy diff_vector array elements one by one
            diff_vector_stage[1][0]  <= diff_vector_stage[0][0];  diff_vector_stage[1][1]  <= diff_vector_stage[0][1];
            diff_vector_stage[1][2]  <= diff_vector_stage[0][2];  diff_vector_stage[1][3]  <= diff_vector_stage[0][3];
            diff_vector_stage[1][4]  <= diff_vector_stage[0][4];  diff_vector_stage[1][5]  <= diff_vector_stage[0][5];
            diff_vector_stage[1][6]  <= diff_vector_stage[0][6];  diff_vector_stage[1][7]  <= diff_vector_stage[0][7];
            diff_vector_stage[1][8]  <= diff_vector_stage[0][8];  diff_vector_stage[1][9]  <= diff_vector_stage[0][9];
            diff_vector_stage[1][10] <= diff_vector_stage[0][10]; diff_vector_stage[1][11] <= diff_vector_stage[0][11];
            diff_vector_stage[1][12] <= diff_vector_stage[0][12]; diff_vector_stage[1][13] <= diff_vector_stage[0][13];
            diff_vector_stage[1][14] <= diff_vector_stage[0][14]; diff_vector_stage[1][15] <= diff_vector_stage[0][15];
            x0_stage[1] <= x0_stage[0];
            var_x0_sq_stage[1] <= var_x0_sq_stage[0];
            three_minus_1_stage[1] <= three_minus_1_stage[0];
            x1_stage[1] <= x1_stage[0];
            x1_sq_stage[1] <= x1_sq_stage[0];
            var_x1_sq_stage[1] <= var_x1_sq_stage[0];
            three_minus_2_stage[1] <= three_minus_2_stage[0];
            
            // Stage 1 calculation: x0² (using dedicated temporary variable)
            temp_mult_s1 = ($signed(x0_stage[0]) * $signed(x0_stage[0]));
            x0_sq_stage[1] <= temp_mult_s1 >>> 10;
            
            // $display("Stage1: x0=0x%04x, x0_sq=0x%04x", x0_stage[0], temp_mult_s1 >>> 10);
        end
        
        // ================================================================
        // Stage 2: Inherit Stage 1 Data + Calculate variance×x0² (using independent temporary variable)
        // ================================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // Inherit all data from Stage 1
            variance_stage[2] <= variance_stage[1];
            mean_stage[2] <= mean_stage[1];
            // Copy diff_vector array elements one by one
            diff_vector_stage[2][0]  <= diff_vector_stage[1][0];  diff_vector_stage[2][1]  <= diff_vector_stage[1][1];
            diff_vector_stage[2][2]  <= diff_vector_stage[1][2];  diff_vector_stage[2][3]  <= diff_vector_stage[1][3];
            diff_vector_stage[2][4]  <= diff_vector_stage[1][4];  diff_vector_stage[2][5]  <= diff_vector_stage[1][5];
            diff_vector_stage[2][6]  <= diff_vector_stage[1][6];  diff_vector_stage[2][7]  <= diff_vector_stage[1][7];
            diff_vector_stage[2][8]  <= diff_vector_stage[1][8];  diff_vector_stage[2][9]  <= diff_vector_stage[1][9];
            diff_vector_stage[2][10] <= diff_vector_stage[1][10]; diff_vector_stage[2][11] <= diff_vector_stage[1][11];
            diff_vector_stage[2][12] <= diff_vector_stage[1][12]; diff_vector_stage[2][13] <= diff_vector_stage[1][13];
            diff_vector_stage[2][14] <= diff_vector_stage[1][14]; diff_vector_stage[2][15] <= diff_vector_stage[1][15];
            x0_stage[2] <= x0_stage[1];
            x0_sq_stage[2] <= x0_sq_stage[1];
            three_minus_1_stage[2] <= three_minus_1_stage[1];
            x1_stage[2] <= x1_stage[1];
            x1_sq_stage[2] <= x1_sq_stage[1];
            var_x1_sq_stage[2] <= var_x1_sq_stage[1];
            three_minus_2_stage[2] <= three_minus_2_stage[1];
            
            // Stage 2 calculation: variance × x0² (using dedicated temporary variable)
            temp_mult_s2 = $signed(variance_stage[1]) * $signed(x0_sq_stage[1]);
            var_x0_sq_stage[2] <= temp_mult_s2 >>> 10;
            
            // $display("Stage2: variance=0x%04x, x0_sq=0x%04x, var_x0_sq=0x%04x", 
                    //  variance_stage[1], x0_sq_stage[1], temp_mult_s2 >>> 10);
        end
        
        // ================================================================
        // Stage 3: Inherit Stage 2 Data + Calculate 3-variance×x0²
        // ================================================================
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            // Inherit all data from Stage 2
            variance_stage[3] <= variance_stage[2];
            mean_stage[3] <= mean_stage[2];
            // Copy diff_vector array elements one by one
            diff_vector_stage[3][0]  <= diff_vector_stage[2][0];  diff_vector_stage[3][1]  <= diff_vector_stage[2][1];
            diff_vector_stage[3][2]  <= diff_vector_stage[2][2];  diff_vector_stage[3][3]  <= diff_vector_stage[2][3];
            diff_vector_stage[3][4]  <= diff_vector_stage[2][4];  diff_vector_stage[3][5]  <= diff_vector_stage[2][5];
            diff_vector_stage[3][6]  <= diff_vector_stage[2][6];  diff_vector_stage[3][7]  <= diff_vector_stage[2][7];
            diff_vector_stage[3][8]  <= diff_vector_stage[2][8];  diff_vector_stage[3][9]  <= diff_vector_stage[2][9];
            diff_vector_stage[3][10] <= diff_vector_stage[2][10]; diff_vector_stage[3][11] <= diff_vector_stage[2][11];
            diff_vector_stage[3][12] <= diff_vector_stage[2][12]; diff_vector_stage[3][13] <= diff_vector_stage[2][13];
            diff_vector_stage[3][14] <= diff_vector_stage[2][14]; diff_vector_stage[3][15] <= diff_vector_stage[2][15];
            x0_stage[3] <= x0_stage[2];
            x0_sq_stage[3] <= x0_sq_stage[2];
            var_x0_sq_stage[3] <= var_x0_sq_stage[2];
            x1_stage[3] <= x1_stage[2];
            x1_sq_stage[3] <= x1_sq_stage[2];
            var_x1_sq_stage[3] <= var_x1_sq_stage[2];
            three_minus_2_stage[3] <= three_minus_2_stage[2];
            
            // Stage 3 calculation: 3 - variance×x0²
            temp_three_minus_1_s3 = Q5_10_THREE - var_x0_sq_stage[2];
            three_minus_1_stage[3] <= temp_three_minus_1_s3; 
            
            // $display("Stage3: 3.0=0x%04x, var_x0_sq=0x%04x, three_minus_1=0x%04x", 
                    //  Q5_10_THREE, var_x0_sq_stage[2], Q5_10_THREE - var_x0_sq_stage[2]);
        end
        
        // ================================================================
        // Stage 4: Inherit Stage 3 Data + Calculate x1=x0×(3-variance×x0²)÷2 (using independent temporary variable)
        // ================================================================
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            // Inherit all data from Stage 3
            variance_stage[4] <= variance_stage[3];
            mean_stage[4] <= mean_stage[3];
            // Copy diff_vector array elements one by one
            diff_vector_stage[4][0]  <= diff_vector_stage[3][0];  diff_vector_stage[4][1]  <= diff_vector_stage[3][1];
            diff_vector_stage[4][2]  <= diff_vector_stage[3][2];  diff_vector_stage[4][3]  <= diff_vector_stage[3][3];
            diff_vector_stage[4][4]  <= diff_vector_stage[3][4];  diff_vector_stage[4][5]  <= diff_vector_stage[3][5];
            diff_vector_stage[4][6]  <= diff_vector_stage[3][6];  diff_vector_stage[4][7]  <= diff_vector_stage[3][7];
            diff_vector_stage[4][8]  <= diff_vector_stage[3][8];  diff_vector_stage[4][9]  <= diff_vector_stage[3][9];
            diff_vector_stage[4][10] <= diff_vector_stage[3][10]; diff_vector_stage[4][11] <= diff_vector_stage[3][11];
            diff_vector_stage[4][12] <= diff_vector_stage[3][12]; diff_vector_stage[4][13] <= diff_vector_stage[3][13];
            diff_vector_stage[4][14] <= diff_vector_stage[3][14]; diff_vector_stage[4][15] <= diff_vector_stage[3][15];
            x0_stage[4] <= x0_stage[3];
            x0_sq_stage[4] <= x0_sq_stage[3];
            var_x0_sq_stage[4] <= var_x0_sq_stage[3];
            three_minus_1_stage[4] <= three_minus_1_stage[3];
            x1_sq_stage[4] <= x1_sq_stage[3];
            var_x1_sq_stage[4] <= var_x1_sq_stage[3];
            three_minus_2_stage[4] <= three_minus_2_stage[3];
            
            // Stage 4 calculation: x1 = x0×(3-variance×x0²)÷2 (using dedicated temporary variable)
            temp_mult_s4 = $signed(x0_stage[3]) * $signed(three_minus_1_stage[3]);
            x1_stage[4] <= temp_mult_s4 >>> 11;  // Right shift 11 bits (10 bits Q format + 1 bit divide by 2)
            
            // $display("Stage4: x0=0x%04x, three_minus_1=0x%04x, x1=0x%04x", 
                    //  x0_stage[3], three_minus_1_stage[3], temp_mult_s4 >>> 11);
        end
        
        // ================================================================
        // Stage 5: Inherit Stage 4 Data + Calculate x1² (using independent temporary variable)
        // ================================================================
        valid_stage[5] <= valid_stage[4];
        if (valid_stage[4]) begin
            // Inherit all data from Stage 4
            variance_stage[5] <= variance_stage[4];
            mean_stage[5] <= mean_stage[4];
            // Copy diff_vector array elements one by one
            diff_vector_stage[5][0]  <= diff_vector_stage[4][0];  diff_vector_stage[5][1]  <= diff_vector_stage[4][1];
            diff_vector_stage[5][2]  <= diff_vector_stage[4][2];  diff_vector_stage[5][3]  <= diff_vector_stage[4][3];
            diff_vector_stage[5][4]  <= diff_vector_stage[4][4];  diff_vector_stage[5][5]  <= diff_vector_stage[4][5];
            diff_vector_stage[5][6]  <= diff_vector_stage[4][6];  diff_vector_stage[5][7]  <= diff_vector_stage[4][7];
            diff_vector_stage[5][8]  <= diff_vector_stage[4][8];  diff_vector_stage[5][9]  <= diff_vector_stage[4][9];
            diff_vector_stage[5][10] <= diff_vector_stage[4][10]; diff_vector_stage[5][11] <= diff_vector_stage[4][11];
            diff_vector_stage[5][12] <= diff_vector_stage[4][12]; diff_vector_stage[5][13] <= diff_vector_stage[4][13];
            diff_vector_stage[5][14] <= diff_vector_stage[4][14]; diff_vector_stage[5][15] <= diff_vector_stage[4][15];
            x0_stage[5] <= x0_stage[4];
            x0_sq_stage[5] <= x0_sq_stage[4];
            var_x0_sq_stage[5] <= var_x0_sq_stage[4];
            three_minus_1_stage[5] <= three_minus_1_stage[4];
            x1_stage[5] <= x1_stage[4];
            var_x1_sq_stage[5] <= var_x1_sq_stage[4];
            three_minus_2_stage[5] <= three_minus_2_stage[4];
            
            // Stage 5 calculation: x1² (using dedicated temporary variable)
            temp_mult_s5 = $signed(x1_stage[4]) * $signed(x1_stage[4]);
            x1_sq_stage[5] <= temp_mult_s5 >>> 10;
            
            // $display("Stage5: x1=0x%04x, x1_sq=0x%04x", x1_stage[4], temp_mult_s5 >>> 10);
        end
        
        // ================================================================
        // Stage 6: Inherit Stage 5 Data + Calculate variance×x1² (using independent temporary variable)
        // ================================================================
        valid_stage[6] <= valid_stage[5];
        if (valid_stage[5]) begin
            // Inherit all data from Stage 5
            variance_stage[6] <= variance_stage[5];
            mean_stage[6] <= mean_stage[5];
            // Copy diff_vector array elements one by one
            diff_vector_stage[6][0]  <= diff_vector_stage[5][0];  diff_vector_stage[6][1]  <= diff_vector_stage[5][1];
            diff_vector_stage[6][2]  <= diff_vector_stage[5][2];  diff_vector_stage[6][3]  <= diff_vector_stage[5][3];
            diff_vector_stage[6][4]  <= diff_vector_stage[5][4];  diff_vector_stage[6][5]  <= diff_vector_stage[5][5];
            diff_vector_stage[6][6]  <= diff_vector_stage[5][6];  diff_vector_stage[6][7]  <= diff_vector_stage[5][7];
            diff_vector_stage[6][8]  <= diff_vector_stage[5][8];  diff_vector_stage[6][9]  <= diff_vector_stage[5][9];
            diff_vector_stage[6][10] <= diff_vector_stage[5][10]; diff_vector_stage[6][11] <= diff_vector_stage[5][11];
            diff_vector_stage[6][12] <= diff_vector_stage[5][12]; diff_vector_stage[6][13] <= diff_vector_stage[5][13];
            diff_vector_stage[6][14] <= diff_vector_stage[5][14]; diff_vector_stage[6][15] <= diff_vector_stage[5][15];
            x0_stage[6] <= x0_stage[5];
            x0_sq_stage[6] <= x0_sq_stage[5];
            var_x0_sq_stage[6] <= var_x0_sq_stage[5];
            three_minus_1_stage[6] <= three_minus_1_stage[5];
            x1_stage[6] <= x1_stage[5];
            x1_sq_stage[6] <= x1_sq_stage[5];
            three_minus_2_stage[6] <= three_minus_2_stage[5];
            
            // Stage 6 calculation: variance × x1² (using dedicated temporary variable)
            temp_mult_s6 = $signed(variance_stage[5]) * $signed(x1_sq_stage[5]);
            var_x1_sq_stage[6] <= temp_mult_s6 >>> 10;
            
            // $display("Stage6: variance=0x%04x, x1_sq=0x%04x, var_x1_sq=0x%04x", 
                    //  variance_stage[5], x1_sq_stage[5], temp_mult_s6 >>> 10);
        end
        
        // ================================================================
        // Stage 7: Inherit Stage 6 Data + Calculate 3-variance×x1²
        // ================================================================
        valid_stage[7] <= valid_stage[6];
        if (valid_stage[6]) begin
            // Inherit all data from Stage 6
            variance_stage[7] <= variance_stage[6];
            mean_stage[7] <= mean_stage[6];
            // Copy diff_vector array elements one by one
            diff_vector_stage[7][0]  <= diff_vector_stage[6][0];  diff_vector_stage[7][1]  <= diff_vector_stage[6][1];
            diff_vector_stage[7][2]  <= diff_vector_stage[6][2];  diff_vector_stage[7][3]  <= diff_vector_stage[6][3];
            diff_vector_stage[7][4]  <= diff_vector_stage[6][4];  diff_vector_stage[7][5]  <= diff_vector_stage[6][5];
            diff_vector_stage[7][6]  <= diff_vector_stage[6][6];  diff_vector_stage[7][7]  <= diff_vector_stage[6][7];
            diff_vector_stage[7][8]  <= diff_vector_stage[6][8];  diff_vector_stage[7][9]  <= diff_vector_stage[6][9];
            diff_vector_stage[7][10] <= diff_vector_stage[6][10]; diff_vector_stage[7][11] <= diff_vector_stage[6][11];
            diff_vector_stage[7][12] <= diff_vector_stage[6][12]; diff_vector_stage[7][13] <= diff_vector_stage[6][13];
            diff_vector_stage[7][14] <= diff_vector_stage[6][14]; diff_vector_stage[7][15] <= diff_vector_stage[6][15];
            x0_stage[7] <= x0_stage[6];
            x0_sq_stage[7] <= x0_sq_stage[6];
            var_x0_sq_stage[7] <= var_x0_sq_stage[6];
            three_minus_1_stage[7] <= three_minus_1_stage[6];
            x1_stage[7] <= x1_stage[6];
            x1_sq_stage[7] <= x1_sq_stage[6];
            var_x1_sq_stage[7] <= var_x1_sq_stage[6];
            
            // Stage 7 calculation: 3 - variance×x1²
            temp_three_minus_2_s7 = Q5_10_THREE - var_x1_sq_stage[6];
            three_minus_2_stage[7] <= temp_three_minus_2_s7;   
            
            // $display("Stage7: 3.0=0x%04x, var_x1_sq=0x%04x, three_minus_2=0x%04x", 
                    //  Q5_10_THREE, var_x1_sq_stage[6], Q5_10_THREE - var_x1_sq_stage[6]);
        end
        
        // ================================================================
        // Output: Use Stage 7 Data to Calculate Final Result (using independent temporary variable)
        // ================================================================
        valid_out <= valid_stage[7];
        if (valid_stage[7]) begin
            // Calculate final 1/σ = x1×(3-variance×x1²)÷2 (using dedicated temporary variable)
            temp_mult_out = $signed(x1_stage[7]) * $signed(three_minus_2_stage[7]);
            inv_sigma_out <= temp_mult_out >>> 11;  // Right shift 11 bits (10 bits Q format + 1 bit divide by 2)
            
            // $display("Output: x1=0x%04x, three_minus_2=0x%04x, inv_sigma_out=0x%04x", 
                    //  x1_stage[7], three_minus_2_stage[7], temp_mult_out >>> 11);
            
            // Pass through other data to post-processing module
            mean_out <= mean_stage[7];
            diff_vector_out_0  <= diff_vector_stage[7][0];  diff_vector_out_1  <= diff_vector_stage[7][1];
            diff_vector_out_2  <= diff_vector_stage[7][2];  diff_vector_out_3  <= diff_vector_stage[7][3];
            diff_vector_out_4  <= diff_vector_stage[7][4];  diff_vector_out_5  <= diff_vector_stage[7][5];
            diff_vector_out_6  <= diff_vector_stage[7][6];  diff_vector_out_7  <= diff_vector_stage[7][7];
            diff_vector_out_8  <= diff_vector_stage[7][8];  diff_vector_out_9  <= diff_vector_stage[7][9];
            diff_vector_out_10 <= diff_vector_stage[7][10]; diff_vector_out_11 <= diff_vector_stage[7][11];
            diff_vector_out_12 <= diff_vector_stage[7][12]; diff_vector_out_13 <= diff_vector_stage[7][13];
            diff_vector_out_14 <= diff_vector_stage[7][14]; diff_vector_out_15 <= diff_vector_stage[7][15];
        end
        
    end
end

endmodule