// ===========================================
// Direct Systolic Array Test (No SPI)
// ===========================================

`timescale 1ns/1ps

module tb_direct_systolic;

    // System signals
    reg clk;
    reg rst_n;
    reg start;
    
    // Matrix inputs
    reg [15:0] matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03;
    reg [15:0] matrix_a_10, matrix_a_11, matrix_a_12, matrix_a_13;
    reg [15:0] matrix_a_20, matrix_a_21, matrix_a_22, matrix_a_23;
    reg [15:0] matrix_a_30, matrix_a_31, matrix_a_32, matrix_a_33;
    
    reg [7:0] matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03;
    reg [7:0] matrix_b_10, matrix_b_11, matrix_b_12, matrix_b_13;
    reg [7:0] matrix_b_20, matrix_b_21, matrix_b_22, matrix_b_23;
    reg [7:0] matrix_b_30, matrix_b_31, matrix_b_32, matrix_b_33;
    
    // Results
    wire [31:0] result_00, result_01, result_02, result_03;
    wire [31:0] result_10, result_11, result_12, result_13;
    wire [31:0] result_20, result_21, result_22, result_23;
    wire [31:0] result_30, result_31, result_32, result_33;
    
    wire computation_done, result_valid;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz
    end
    
    // Direct systolic array instance (no SPI wrapper)
    systolic_array_4x4 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        
        // Matrix A
        .matrix_a_00(matrix_a_00), .matrix_a_01(matrix_a_01), .matrix_a_02(matrix_a_02), .matrix_a_03(matrix_a_03),
        .matrix_a_10(matrix_a_10), .matrix_a_11(matrix_a_11), .matrix_a_12(matrix_a_12), .matrix_a_13(matrix_a_13),
        .matrix_a_20(matrix_a_20), .matrix_a_21(matrix_a_21), .matrix_a_22(matrix_a_22), .matrix_a_23(matrix_a_23),
        .matrix_a_30(matrix_a_30), .matrix_a_31(matrix_a_31), .matrix_a_32(matrix_a_32), .matrix_a_33(matrix_a_33),
        
        // Matrix B  
        .matrix_b_00(matrix_b_00), .matrix_b_01(matrix_b_01), .matrix_b_02(matrix_b_02), .matrix_b_03(matrix_b_03),
        .matrix_b_10(matrix_b_10), .matrix_b_11(matrix_b_11), .matrix_b_12(matrix_b_12), .matrix_b_13(matrix_b_13),
        .matrix_b_20(matrix_b_20), .matrix_b_21(matrix_b_21), .matrix_b_22(matrix_b_22), .matrix_b_23(matrix_b_23),
        .matrix_b_30(matrix_b_30), .matrix_b_31(matrix_b_31), .matrix_b_32(matrix_b_32), .matrix_b_33(matrix_b_33),
        
        // Results
        .result_00(result_00), .result_01(result_01), .result_02(result_02), .result_03(result_03),
        .result_10(result_10), .result_11(result_11), .result_12(result_12), .result_13(result_13),
        .result_20(result_20), .result_21(result_21), .result_22(result_22), .result_23(result_23),
        .result_30(result_30), .result_31(result_31), .result_32(result_32), .result_33(result_33),
        
        .computation_done(computation_done),
        .result_valid(result_valid)
    );
    
    // Test sequence
    initial begin
        $display("=== Direct Systolic Array Test ===");
        $display("Bypassing SPI interface for clean test");
        
        // Reset
        rst_n = 0;
        start = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        // Load test matrices
        $display("\nLoading test matrices...");
        
        // Matrix A: [1 1 1 1; 2 2 2 2; 3 3 3 3; 4 4 4 4]
        matrix_a_00 = 16'd1; matrix_a_01 = 16'd1; matrix_a_02 = 16'd1; matrix_a_03 = 16'd1;
        matrix_a_10 = 16'd2; matrix_a_11 = 16'd2; matrix_a_12 = 16'd2; matrix_a_13 = 16'd2;
        matrix_a_20 = 16'd3; matrix_a_21 = 16'd3; matrix_a_22 = 16'd3; matrix_a_23 = 16'd3;
        matrix_a_30 = 16'd4; matrix_a_31 = 16'd4; matrix_a_32 = 16'd4; matrix_a_33 = 16'd4;
        
        // Matrix B: [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4]
        matrix_b_00 = 8'd1; matrix_b_01 = 8'd2; matrix_b_02 = 8'd3; matrix_b_03 = 8'd4;
        matrix_b_10 = 8'd1; matrix_b_11 = 8'd2; matrix_b_12 = 8'd3; matrix_b_13 = 8'd4;
        matrix_b_20 = 8'd1; matrix_b_21 = 8'd2; matrix_b_22 = 8'd3; matrix_b_23 = 8'd4;
        matrix_b_30 = 8'd1; matrix_b_31 = 8'd2; matrix_b_32 = 8'd3; matrix_b_33 = 8'd4;
        
        $display("Matrix A: [1 1 1 1; 2 2 2 2; 3 3 3 3; 4 4 4 4]");
        $display("Matrix B: [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4]");
        $display("Expected: [4 8 12 16; 8 16 24 32; 12 24 36 48; 16 32 48 64]");
        
        // Start computation
        $display("\nStarting computation...");
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for completion
        $display("Waiting for completion...");
        wait(computation_done == 1);
        
        repeat(5) @(posedge clk);  // Let results settle
        
        // Display results
        $display("\n=== RESULTS ===");
        $display("Actual Results:");
        $display("[%3d] [%3d] [%3d] [%3d]", result_00, result_01, result_02, result_03);
        $display("[%3d] [%3d] [%3d] [%3d]", result_10, result_11, result_12, result_13);
        $display("[%3d] [%3d] [%3d] [%3d]", result_20, result_21, result_22, result_23);
        $display("[%3d] [%3d] [%3d] [%3d]", result_30, result_31, result_32, result_33);
        
        // Verify results
        if (result_00 == 32'd4   && result_01 == 32'd8   && result_02 == 32'd12  && result_03 == 32'd16 &&
            result_10 == 32'd8   && result_11 == 32'd16  && result_12 == 32'd24  && result_13 == 32'd32 &&
            result_20 == 32'd12  && result_21 == 32'd24  && result_22 == 32'd36  && result_23 == 32'd48 &&
            result_30 == 32'd16  && result_31 == 32'd32  && result_32 == 32'd48  && result_33 == 32'd64) begin
            
            $display("\n¿ *** SYSTOLIC ARRAY CORE TEST PASSED! *** ¿");
            $display("¿ Your systolic array is working perfectly!");
            $display("¿ All 16 results are correct!");
            $display("¿ Core computation verified!");
            
        end else begin
            $display("\n¿ Test failed - results don't match expected values");
        end
        
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Timeout
    initial begin
        #10000;  // 10¿s timeout
        $display("ERROR: Test timeout!");
        $finish;
    end

endmodule
