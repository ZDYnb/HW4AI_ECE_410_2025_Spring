// ===========================================
// Clean 4×4 Systolic Array - All Syntax Fixed
// ===========================================

`timescale 1ns/1ps

// ===========================================
// 4×4 Systolic Array
// ===========================================
module systolic_array_4x4 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic        clear_accum,
    
    // Data inputs (4 rows)
    input  logic [15:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input  logic        data_valid_0, data_valid_1, data_valid_2, data_valid_3,
    
    // Weight inputs (4 columns)
    input  logic [7:0]  weight_in_0, weight_in_1, weight_in_2, weight_in_3,
    input  logic        weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3,
    
    // Results output (4×4 matrix)
    output logic [31:0] result_00, result_01, result_02, result_03,
    output logic [31:0] result_10, result_11, result_12, result_13,
    output logic [31:0] result_20, result_21, result_22, result_23,
    output logic [31:0] result_30, result_31, result_32, result_33,
    
    output logic        valid_00, valid_01, valid_02, valid_03,
    output logic        valid_10, valid_11, valid_12, valid_13,
    output logic        valid_20, valid_21, valid_22, valid_23,
    output logic        valid_30, valid_31, valid_32, valid_33
);

    // Internal horizontal data flow
    logic [15:0] data_h_0_1, data_h_0_2, data_h_0_3, data_h_0_4;
    logic [15:0] data_h_1_1, data_h_1_2, data_h_1_3, data_h_1_4;
    logic [15:0] data_h_2_1, data_h_2_2, data_h_2_3, data_h_2_4;
    logic [15:0] data_h_3_1, data_h_3_2, data_h_3_3, data_h_3_4;
    
    logic data_valid_h_0_1, data_valid_h_0_2, data_valid_h_0_3, data_valid_h_0_4;
    logic data_valid_h_1_1, data_valid_h_1_2, data_valid_h_1_3, data_valid_h_1_4;
    logic data_valid_h_2_1, data_valid_h_2_2, data_valid_h_2_3, data_valid_h_2_4;
    logic data_valid_h_3_1, data_valid_h_3_2, data_valid_h_3_3, data_valid_h_3_4;
    
    // Internal vertical weight flow
    logic [7:0] weight_v_1_0, weight_v_2_0, weight_v_3_0, weight_v_4_0;
    logic [7:0] weight_v_1_1, weight_v_2_1, weight_v_3_1, weight_v_4_1;
    logic [7:0] weight_v_1_2, weight_v_2_2, weight_v_3_2, weight_v_4_2;
    logic [7:0] weight_v_1_3, weight_v_2_3, weight_v_3_3, weight_v_4_3;
    
    logic weight_valid_v_1_0, weight_valid_v_2_0, weight_valid_v_3_0, weight_valid_v_4_0;
    logic weight_valid_v_1_1, weight_valid_v_2_1, weight_valid_v_3_1, weight_valid_v_4_1;
    logic weight_valid_v_1_2, weight_valid_v_2_2, weight_valid_v_3_2, weight_valid_v_4_2;
    logic weight_valid_v_1_3, weight_valid_v_2_3, weight_valid_v_3_3, weight_valid_v_4_3;
    
    // PE[0][0]
    processing_element pe_00 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_0), .data_valid_in(data_valid_0),
        .data_out(data_h_0_1), .data_valid_out(data_valid_h_0_1),
        .weight_in(weight_in_0), .weight_valid_in(weight_valid_0),
        .weight_out(weight_v_1_0), .weight_valid_out(weight_valid_v_1_0),
        .accum_out(result_00), .result_valid(valid_00)
    );
    
    // PE[0][1]
    processing_element pe_01 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_1), .data_valid_in(data_valid_h_0_1),
        .data_out(data_h_0_2), .data_valid_out(data_valid_h_0_2),
        .weight_in(weight_in_1), .weight_valid_in(weight_valid_1),
        .weight_out(weight_v_1_1), .weight_valid_out(weight_valid_v_1_1),
        .accum_out(result_01), .result_valid(valid_01)
    );
    
    // PE[0][2]
    processing_element pe_02 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_2), .data_valid_in(data_valid_h_0_2),
        .data_out(data_h_0_3), .data_valid_out(data_valid_h_0_3),
        .weight_in(weight_in_2), .weight_valid_in(weight_valid_2),
        .weight_out(weight_v_1_2), .weight_valid_out(weight_valid_v_1_2),
        .accum_out(result_02), .result_valid(valid_02)
    );
    
    // PE[0][3]
    processing_element pe_03 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_0_3), .data_valid_in(data_valid_h_0_3),
        .data_out(data_h_0_4), .data_valid_out(data_valid_h_0_4),
        .weight_in(weight_in_3), .weight_valid_in(weight_valid_3),
        .weight_out(weight_v_1_3), .weight_valid_out(weight_valid_v_1_3),
        .accum_out(result_03), .result_valid(valid_03)
    );
    
    // PE[1][0]
    processing_element pe_10 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_1), .data_valid_in(data_valid_1),
        .data_out(data_h_1_1), .data_valid_out(data_valid_h_1_1),
        .weight_in(weight_v_1_0), .weight_valid_in(weight_valid_v_1_0),
        .weight_out(weight_v_2_0), .weight_valid_out(weight_valid_v_2_0),
        .accum_out(result_10), .result_valid(valid_10)
    );
    
    // PE[1][1]
    processing_element pe_11 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_1), .data_valid_in(data_valid_h_1_1),
        .data_out(data_h_1_2), .data_valid_out(data_valid_h_1_2),
        .weight_in(weight_v_1_1), .weight_valid_in(weight_valid_v_1_1),
        .weight_out(weight_v_2_1), .weight_valid_out(weight_valid_v_2_1),
        .accum_out(result_11), .result_valid(valid_11)
    );
    
    // PE[1][2]
    processing_element pe_12 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_2), .data_valid_in(data_valid_h_1_2),
        .data_out(data_h_1_3), .data_valid_out(data_valid_h_1_3),
        .weight_in(weight_v_1_2), .weight_valid_in(weight_valid_v_1_2),
        .weight_out(weight_v_2_2), .weight_valid_out(weight_valid_v_2_2),
        .accum_out(result_12), .result_valid(valid_12)
    );
    
    // PE[1][3]
    processing_element pe_13 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_1_3), .data_valid_in(data_valid_h_1_3),
        .data_out(data_h_1_4), .data_valid_out(data_valid_h_1_4),
        .weight_in(weight_v_1_3), .weight_valid_in(weight_valid_v_1_3),
        .weight_out(weight_v_2_3), .weight_valid_out(weight_valid_v_2_3),
        .accum_out(result_13), .result_valid(valid_13)
    );
    
    // PE[2][0]
    processing_element pe_20 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_2), .data_valid_in(data_valid_2),
        .data_out(data_h_2_1), .data_valid_out(data_valid_h_2_1),
        .weight_in(weight_v_2_0), .weight_valid_in(weight_valid_v_2_0),
        .weight_out(weight_v_3_0), .weight_valid_out(weight_valid_v_3_0),
        .accum_out(result_20), .result_valid(valid_20)
    );
    
    // PE[2][1]
    processing_element pe_21 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_1), .data_valid_in(data_valid_h_2_1),
        .data_out(data_h_2_2), .data_valid_out(data_valid_h_2_2),
        .weight_in(weight_v_2_1), .weight_valid_in(weight_valid_v_2_1),
        .weight_out(weight_v_3_1), .weight_valid_out(weight_valid_v_3_1),
        .accum_out(result_21), .result_valid(valid_21)
    );
    
    // PE[2][2]
    processing_element pe_22 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_2), .data_valid_in(data_valid_h_2_2),
        .data_out(data_h_2_3), .data_valid_out(data_valid_h_2_3),
        .weight_in(weight_v_2_2), .weight_valid_in(weight_valid_v_2_2),
        .weight_out(weight_v_3_2), .weight_valid_out(weight_valid_v_3_2),
        .accum_out(result_22), .result_valid(valid_22)
    );
    
    // PE[2][3]
    processing_element pe_23 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_2_3), .data_valid_in(data_valid_h_2_3),
        .data_out(data_h_2_4), .data_valid_out(data_valid_h_2_4),
        .weight_in(weight_v_2_3), .weight_valid_in(weight_valid_v_2_3),
        .weight_out(weight_v_3_3), .weight_valid_out(weight_valid_v_3_3),
        .accum_out(result_23), .result_valid(valid_23)
    );
    
    // PE[3][0]
    processing_element pe_30 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_in_3), .data_valid_in(data_valid_3),
        .data_out(data_h_3_1), .data_valid_out(data_valid_h_3_1),
        .weight_in(weight_v_3_0), .weight_valid_in(weight_valid_v_3_0),
        .weight_out(weight_v_4_0), .weight_valid_out(weight_valid_v_4_0),
        .accum_out(result_30), .result_valid(valid_30)
    );
    
    // PE[3][1]
    processing_element pe_31 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_1), .data_valid_in(data_valid_h_3_1),
        .data_out(data_h_3_2), .data_valid_out(data_valid_h_3_2),
        .weight_in(weight_v_3_1), .weight_valid_in(weight_valid_v_3_1),
        .weight_out(weight_v_4_1), .weight_valid_out(weight_valid_v_4_1),
        .accum_out(result_31), .result_valid(valid_31)
    );
    
    // PE[3][2]
    processing_element pe_32 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_2), .data_valid_in(data_valid_h_3_2),
        .data_out(data_h_3_3), .data_valid_out(data_valid_h_3_3),
        .weight_in(weight_v_3_2), .weight_valid_in(weight_valid_v_3_2),
        .weight_out(weight_v_4_2), .weight_valid_out(weight_valid_v_4_2),
        .accum_out(result_32), .result_valid(valid_32)
    );
    
    // PE[3][3]
    processing_element pe_33 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h_3_3), .data_valid_in(data_valid_h_3_3),
        .data_out(data_h_3_4), .data_valid_out(data_valid_h_3_4),
        .weight_in(weight_v_3_3), .weight_valid_in(weight_valid_v_3_3),
        .weight_out(weight_v_4_3), .weight_valid_out(weight_valid_v_4_3),
        .accum_out(result_33), .result_valid(valid_33)
    );

endmodule

// ===========================================
// Simple Testbench
// ===========================================
module tb_systolic_4x4;

    parameter CLK_PERIOD = 10;
    
    logic        clk, rst_n, enable, clear_accum;
    logic [15:0] data_in_0, data_in_1, data_in_2, data_in_3;
    logic        data_valid_0, data_valid_1, data_valid_2, data_valid_3;
    logic [7:0]  weight_in_0, weight_in_1, weight_in_2, weight_in_3;
    logic        weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3;
    
    logic [31:0] result_00, result_01, result_02, result_03;
    logic [31:0] result_10, result_11, result_12, result_13;
    logic [31:0] result_20, result_21, result_22, result_23;
    logic [31:0] result_30, result_31, result_32, result_33;
    
    logic        valid_00, valid_01, valid_02, valid_03;
    logic        valid_10, valid_11, valid_12, valid_13;
    logic        valid_20, valid_21, valid_22, valid_23;
    logic        valid_30, valid_31, valid_32, valid_33;
    
    // DUT
    systolic_array_4x4 dut (.*);
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test: A × I = A (Identity matrix test)
    initial begin
        $display("=== 4×4 Systolic Array Test ===");
        $display("Testing A × I = A (Identity matrix)");
        
        // Initialize
        rst_n = 0; enable = 0; clear_accum = 0;
        data_in_0 = 0; data_in_1 = 0; data_in_2 = 0; data_in_3 = 0;
        data_valid_0 = 0; data_valid_1 = 0; data_valid_2 = 0; data_valid_3 = 0;
        weight_in_0 = 0; weight_in_1 = 0; weight_in_2 = 0; weight_in_3 = 0;
        weight_valid_0 = 0; weight_valid_1 = 0; weight_valid_2 = 0; weight_valid_3 = 0;
        
        #20 rst_n = 1; #10 enable = 1;
        
        // Cycle 0: First inputs (clear accumulators)
        clear_accum = 1;
        data_in_0 = 1; data_valid_0 = 1;    // A[0,0] = 1
        data_in_1 = 5; data_valid_1 = 1;    // A[1,0] = 5
        data_in_2 = 9; data_valid_2 = 1;    // A[2,0] = 9
        data_in_3 = 13; data_valid_3 = 1;   // A[3,0] = 13
        weight_in_0 = 1; weight_valid_0 = 1; // I[0,0] = 1
        weight_in_1 = 0; weight_valid_1 = 1; // I[0,1] = 0
        weight_in_2 = 0; weight_valid_2 = 1; // I[0,2] = 0
        weight_in_3 = 0; weight_valid_3 = 1; // I[0,3] = 0
        #10;
        
        // Cycle 1: Second inputs (accumulate)
        clear_accum = 0;
        data_in_0 = 2; data_in_1 = 6; data_in_2 = 10; data_in_3 = 14;
        weight_in_0 = 0; weight_in_1 = 1; weight_in_2 = 0; weight_in_3 = 0;
        #10;
        
        // Cycle 2: Third inputs
        data_in_0 = 3; data_in_1 = 7; data_in_2 = 11; data_in_3 = 15;
        weight_in_0 = 0; weight_in_1 = 0; weight_in_2 = 1; weight_in_3 = 0;
        #10;
        
        // Cycle 3: Fourth inputs
        data_in_0 = 4; data_in_1 = 8; data_in_2 = 12; data_in_3 = 16;
        weight_in_0 = 0; weight_in_1 = 0; weight_in_2 = 0; weight_in_3 = 1;
        #10;
        
        // Turn off inputs and wait
        data_valid_0 = 0; data_valid_1 = 0; data_valid_2 = 0; data_valid_3 = 0;
        weight_valid_0 = 0; weight_valid_1 = 0; weight_valid_2 = 0; weight_valid_3 = 0;
        #30;
        
        // Display results
        $display("Results:");
        $display("  [%2d, %2d, %2d, %2d]", result_00, result_01, result_02, result_03);
        $display("  [%2d, %2d, %2d, %2d]", result_10, result_11, result_12, result_13);
        $display("  [%2d, %2d, %2d, %2d]", result_20, result_21, result_22, result_23);
        $display("  [%2d, %2d, %2d, %2d]", result_30, result_31, result_32, result_33);
        
        // Simple verification
        if (result_00 == 1 && result_11 == 6 && result_22 == 11 && result_33 == 16) begin
            $display("¿ SUCCESS: 4×4 systolic array working!");
        end else begin
            $display("¿ Some errors found");
        end
        
        $display("=== Test Complete ===");
        $finish;
    end

endmodule

// ===========================================
// Processing Element (same as before)
// ===========================================
module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       enable,
    input  logic                       clear_accum,
    
    input  logic [DATA_WIDTH-1:0]      data_in,
    input  logic                       data_valid_in,
    output logic [DATA_WIDTH-1:0]      data_out,
    output logic                       data_valid_out,
    
    input  logic [WEIGHT_WIDTH-1:0]    weight_in,
    input  logic                       weight_valid_in,
    output logic [WEIGHT_WIDTH-1:0]    weight_out,
    output logic                       weight_valid_out,
    
    output logic [ACCUM_WIDTH-1:0]     accum_out,
    output logic                       result_valid
);

    logic [DATA_WIDTH-1:0]      mac_data;
    logic [WEIGHT_WIDTH-1:0]    mac_weight;
    logic [ACCUM_WIDTH-1:0]     mac_accum;
    logic                       mac_valid;
    
    logic [DATA_WIDTH-1:0]      data_reg;
    logic                       data_valid_reg;
    logic [WEIGHT_WIDTH-1:0]    weight_reg;
    logic                       weight_valid_reg;
    
    assign mac_data = (data_valid_in && weight_valid_in) ? data_in : '0;
    assign mac_weight = (data_valid_in && weight_valid_in) ? weight_in : '0;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= '0;
            data_valid_reg <= '0;
            weight_reg <= '0;
            weight_valid_reg <= '0;
        end else if (enable) begin
            data_reg <= data_in;
            data_valid_reg <= data_valid_in;
            weight_reg <= weight_in;
            weight_valid_reg <= weight_valid_in;
        end else begin
            data_valid_reg <= '0;
            weight_valid_reg <= '0;
        end
    end
    
    assign data_out = data_reg;
    assign data_valid_out = data_valid_reg;
    assign weight_out = weight_reg;
    assign weight_valid_out = weight_valid_reg;
    
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && data_valid_in && weight_valid_in),
        .clear_accum(clear_accum),
        .data_in(mac_data),
        .weight_in(mac_weight),
        .accum_out(mac_accum),
        .valid_out(mac_valid)
    );
    
    assign accum_out = mac_accum;
    assign result_valid = mac_valid;

endmodule

// ===========================================
// MAC Unit (same as before)
// ===========================================
module mac_unit_basic #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       enable,
    input  logic                       clear_accum,
    
    input  logic [DATA_WIDTH-1:0]      data_in,
    input  logic [WEIGHT_WIDTH-1:0]    weight_in,
    
    output logic [ACCUM_WIDTH-1:0]     accum_out,
    output logic                       valid_out
);

    logic signed [DATA_WIDTH-1:0]      data_signed;
    logic signed [WEIGHT_WIDTH-1:0]    weight_signed;
    logic signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] mult_result;
    logic signed [ACCUM_WIDTH-1:0]     accum_reg;
    logic signed [ACCUM_WIDTH-1:0]     next_accum;
    
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);
    assign mult_result = data_signed * weight_signed;
    assign next_accum = clear_accum ? mult_result : (accum_reg + mult_result);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= '0;
            valid_out <= '0;
        end else if (enable) begin
            accum_reg <= next_accum;
            valid_out <= '1;
        end else begin
            valid_out <= '0;
        end
    end
    
    assign accum_out = accum_reg;

endmodule

