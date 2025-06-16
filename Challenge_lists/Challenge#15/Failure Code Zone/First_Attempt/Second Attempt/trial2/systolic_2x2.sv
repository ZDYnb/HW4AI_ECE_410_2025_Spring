// ===========================================
// Corrected 2×2 Systolic Array - Proper Timing
// 4 Processing Elements with correct data flow
// ===========================================

`timescale 1ns/1ps

// ===========================================
// 2×2 Systolic Array
// ===========================================
module systolic_array_2x2 #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       enable,
    input  logic                       clear_accum,
    
    // Data inputs (left side - matrix A rows)
    input  logic [DATA_WIDTH-1:0]      data_in_row0,
    input  logic                       data_valid_row0,
    input  logic [DATA_WIDTH-1:0]      data_in_row1, 
    input  logic                       data_valid_row1,
    
    // Weight inputs (top side - matrix B columns)
    input  logic [WEIGHT_WIDTH-1:0]    weight_in_col0,
    input  logic                       weight_valid_col0,
    input  logic [WEIGHT_WIDTH-1:0]    weight_in_col1,
    input  logic                       weight_valid_col1,
    
    // Results output (matrix C)
    output logic [ACCUM_WIDTH-1:0]     result_00, result_01, result_10, result_11,
    output logic                       valid_00, valid_01, valid_10, valid_11
);

    // Internal data flow wires (horizontal)
    logic [DATA_WIDTH-1:0]      data_h[2][3];
    logic                       data_valid_h[2][3];
    
    // Internal weight flow wires (vertical)  
    logic [WEIGHT_WIDTH-1:0]    weight_v[3][2];
    logic                       weight_valid_v[3][2];
    
    // Input connections
    assign data_h[0][0] = data_in_row0;
    assign data_valid_h[0][0] = data_valid_row0;
    assign data_h[1][0] = data_in_row1;
    assign data_valid_h[1][0] = data_valid_row1;
    
    assign weight_v[0][0] = weight_in_col0;
    assign weight_valid_v[0][0] = weight_valid_col0;
    assign weight_v[0][1] = weight_in_col1;
    assign weight_valid_v[0][1] = weight_valid_col1;
    
    // PE[0][0] - Top Left
    processing_element pe_00 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h[0][0]), .data_valid_in(data_valid_h[0][0]),
        .data_out(data_h[0][1]), .data_valid_out(data_valid_h[0][1]),
        .weight_in(weight_v[0][0]), .weight_valid_in(weight_valid_v[0][0]),
        .weight_out(weight_v[1][0]), .weight_valid_out(weight_valid_v[1][0]),
        .accum_out(result_00), .result_valid(valid_00)
    );
    
    // PE[0][1] - Top Right
    processing_element pe_01 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h[0][1]), .data_valid_in(data_valid_h[0][1]),
        .data_out(data_h[0][2]), .data_valid_out(data_valid_h[0][2]),
        .weight_in(weight_v[0][1]), .weight_valid_in(weight_valid_v[0][1]),
        .weight_out(weight_v[1][1]), .weight_valid_out(weight_valid_v[1][1]),
        .accum_out(result_01), .result_valid(valid_01)
    );
    
    // PE[1][0] - Bottom Left
    processing_element pe_10 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h[1][0]), .data_valid_in(data_valid_h[1][0]),
        .data_out(data_h[1][1]), .data_valid_out(data_valid_h[1][1]),
        .weight_in(weight_v[1][0]), .weight_valid_in(weight_valid_v[1][0]),
        .weight_out(weight_v[2][0]), .weight_valid_out(weight_valid_v[2][0]),
        .accum_out(result_10), .result_valid(valid_10)
    );
    
    // PE[1][1] - Bottom Right
    processing_element pe_11 (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_accum(clear_accum),
        .data_in(data_h[1][1]), .data_valid_in(data_valid_h[1][1]),
        .data_out(data_h[1][2]), .data_valid_out(data_valid_h[1][2]),
        .weight_in(weight_v[1][1]), .weight_valid_in(weight_valid_v[1][1]),
        .weight_out(weight_v[2][1]), .weight_valid_out(weight_valid_v[2][1]),
        .accum_out(result_11), .result_valid(valid_11)
    );

endmodule

// ===========================================
// Corrected Testbench with Proper Systolic Timing
// ===========================================
module tb_systolic_array_2x2;

    parameter CLK_PERIOD = 10;
    
    logic        clk, rst_n, enable, clear_accum;
    logic [15:0] data_in_row0, data_in_row1;
    logic        data_valid_row0, data_valid_row1;
    logic [7:0]  weight_in_col0, weight_in_col1;
    logic        weight_valid_col0, weight_valid_col1;
    logic [31:0] result_00, result_01, result_10, result_11;
    logic        valid_00, valid_01, valid_10, valid_11;
    
    // DUT
    systolic_array_2x2 dut (.*);
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Matrix multiplication test with proper systolic timing
    // A = [1, 2] × B = [5, 6] = C = [19, 22]
    //     [3, 4]       [7, 8]       [43, 50]
    //
    // Systolic scheduling:
    // Cycle 0: Feed A[0,0]=1 and B[0,0]=5 to PE[0,0]
    // Cycle 1: Feed A[0,1]=2 to PE[0,0], A[1,0]=3 gets forwarded weight
    //          Feed B[0,1]=6 to PE[0,1], B[1,0]=7 gets forwarded data
    // And so on...
    
    initial begin
        $display("=== Corrected 2×2 Systolic Array Test ===");
        $display("Matrix multiplication: A × B = C");
        $display("A = [1, 2]   B = [5, 6]   Expected C = [19, 22]");
        $display("    [3, 4]       [7, 8]                 [43, 50]");
        $display("");
        
        // Initialize all signals
        rst_n = 0;
        enable = 0;
        clear_accum = 0;
        data_in_row0 = 0; data_valid_row0 = 0;
        data_in_row1 = 0; data_valid_row1 = 0;
        weight_in_col0 = 0; weight_valid_col0 = 0;
        weight_in_col1 = 0; weight_valid_col1 = 0;
        
        // Reset sequence
        #20;
        rst_n = 1;
        #10;
        enable = 1;
        
        // Cycle 0: Start computation, clear accumulators
        $display("Cycle 0: Initialize - clear accumulators");
        clear_accum = 1;
        data_in_row0 = 1; data_valid_row0 = 1;     // A[0,0] = 1
        data_in_row1 = 0; data_valid_row1 = 0;     // No data for row 1 yet
        weight_in_col0 = 5; weight_valid_col0 = 1; // B[0,0] = 5
        weight_in_col1 = 0; weight_valid_col1 = 0; // No weight for col 1 yet
        #10;
        $display("  After cycle 0: [%0d,%0d; %0d,%0d]", result_00, result_01, result_10, result_11);
        
        // Cycle 1: Continue computation, accumulate
        $display("Cycle 1: Second inputs");
        clear_accum = 0; // Now accumulate
        data_in_row0 = 2; data_valid_row0 = 1;     // A[0,1] = 2
        data_in_row1 = 3; data_valid_row1 = 1;     // A[1,0] = 3
        weight_in_col0 = 7; weight_valid_col0 = 1; // B[1,0] = 7
        weight_in_col1 = 6; weight_valid_col1 = 1; // B[0,1] = 6
        #10;
        $display("  After cycle 1: [%0d,%0d; %0d,%0d]", result_00, result_01, result_10, result_11);
        
        // Cycle 2: Final inputs
        $display("Cycle 2: Final inputs");
        data_in_row0 = 0; data_valid_row0 = 0;     // Done with row 0
        data_in_row1 = 4; data_valid_row1 = 1;     // A[1,1] = 4
        weight_in_col0 = 0; weight_valid_col0 = 0; // Done with col 0
        weight_in_col1 = 8; weight_valid_col1 = 1; // B[1,1] = 8
        #10;
        $display("  After cycle 2: [%0d,%0d; %0d,%0d]", result_00, result_01, result_10, result_11);
        
        // Cycle 3: Let pipeline finish
        $display("Cycle 3: Pipeline completion");
        data_in_row0 = 0; data_valid_row0 = 0;
        data_in_row1 = 0; data_valid_row1 = 0;
        weight_in_col0 = 0; weight_valid_col0 = 0;
        weight_in_col1 = 0; weight_valid_col1 = 0;
        #20; // Wait for pipeline to complete
        
        // Final results
        $display("");
        $display("Final Results:");
        $display("  C = [%0d, %0d]", result_00, result_01);
        $display("      [%0d, %0d]", result_10, result_11);
        $display("");
        
        // Verification
        $display("Verification:");
        if (result_00 == 19) $display("¿ C[0,0] = %0d (expected 19)", result_00);
        else $display("¿ C[0,0] = %0d (expected 19)", result_00);
        
        if (result_01 == 22) $display("¿ C[0,1] = %0d (expected 22)", result_01);
        else $display("¿ C[0,1] = %0d (expected 22)", result_01);
        
        if (result_10 == 43) $display("¿ C[1,0] = %0d (expected 43)", result_10);
        else $display("¿ C[1,0] = %0d (expected 43)", result_10);
        
        if (result_11 == 50) $display("¿ C[1,1] = %0d (expected 50)", result_11);
        else $display("¿ C[1,1] = %0d (expected 50)", result_11);
        
        // Summary
        if (result_00 == 19 && result_01 == 22 && result_10 == 43 && result_11 == 50) begin
            $display("");
            $display("¿ SUCCESS: Matrix multiplication works correctly!");
        end else begin
            $display("");
            $display("¿ Some results are incorrect - check timing");
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
