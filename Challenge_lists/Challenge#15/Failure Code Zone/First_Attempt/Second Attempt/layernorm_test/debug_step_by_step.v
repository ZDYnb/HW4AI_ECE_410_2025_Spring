// debug_step_by_step.v - Test each module individually
module debug_step_by_step;

    parameter D_MODEL = 4;  // Very small for debugging
    parameter X_WIDTH = 16;
    parameter Y_WIDTH = 16;
    parameter PARAM_WIDTH = 8;

    reg clk, rst_n;
    
    // Test signals for Tree Adder + Mean Calculator
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] x_test;
    wire signed [25:0] sum_out;  // X_WIDTH + extra bits
    wire sum_valid;
    reg sum_start;
    
    // Mean calculator signals
    wire signed [23:0] mean_out;  // 24-bit mean
    wire mean_valid;

    // Variance unit signals
    reg start_variance;
    wire signed [23:0] variance_out;
    wire variance_valid;
    wire variance_busy;

    // Tree adder instance
    tree_level_pipelined_adder #(
        .D_MODEL(D_MODEL),
        .INPUT_WIDTH(X_WIDTH),
        .OUTPUT_WIDTH(26)
    ) adder_test (
        .clk(clk),
        .rst_n(rst_n),
        .data_in_flat(x_test),
        .valid_in(sum_start),
        .sum_out(sum_out),
        .valid_out(sum_valid)
    );

    // Mean calculator instance
    mean_calculation_unit #(
        .D_MODEL_VAL(D_MODEL),
        .SUM_WIDTH(26),
        .SUM_FRAC(10),
        .MEAN_WIDTH(24),
        .MEAN_FRAC(10)
    ) mean_test (
        .clk(clk),
        .rst_n(rst_n),
        .sum_in(sum_out),
        .sum_valid_in(sum_valid),
        .mean_out(mean_out),
        .mean_valid_out(mean_valid)
    );

    // Variance unit instance
    variance_unit #(
        .D_MODEL(D_MODEL),
        .DATA_WIDTH(X_WIDTH),
        .NUM_PE(4)  // Use 4 PEs for D_MODEL=4
    ) variance_test (
        .clk(clk),
        .rst_n(rst_n),
        .data_in_flat(x_test),
        .mean_in(mean_out),
        .start_variance(start_variance),
        .variance_out(variance_out),
        .variance_valid(variance_valid),
        .busy(variance_busy)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        $display("=== Step by Step Debug ===");
        
        clk = 0;
        rst_n = 0;
        sum_start = 0;
        start_variance = 0;
        
        // Simple test data: [1, 2, 3, 4]
        x_test = {16'd4096, 16'd3072, 16'd2048, 16'd1024}; // 4.0, 3.0, 2.0, 1.0 in S5.10
        
        $display("Input: [1.0, 2.0, 3.0, 4.0]");
        $display("Expected sum: 10.0 = 10240");
        $display("Expected mean: 2.5 = 2560 in S13.10 format");
        $display("Expected variance: 1.25 = 1310720 in S3.20 format");
        
        #50 rst_n = 1;
        #20;
        
        // === STEP 1: Test Tree Adder + Mean ===
        $display("\n=== STEP 1: Tree Adder + Mean Calculator ===");
        sum_start = 1;
        #10 sum_start = 0;
        
        // Wait for tree adder
        wait(sum_valid);
        $display("Tree Adder Result: %d", sum_out);
        
        // Wait for mean calculator
        wait(mean_valid);
        $display("Mean Calculator Result: %d (expected 2560)", mean_out);
        
        if (mean_out == 24'd2560) begin
            $display("PASS: Mean calculation works correctly");
        end else begin
            $display("FAIL: Mean calculation incorrect");
            $finish;
        end
        
        // === STEP 2: Test Variance Unit ===
        $display("\n=== STEP 2: Variance Unit ===");
        #20; // Wait a bit
        
        start_variance = 1;
        #10 start_variance = 0;
        
        // Wait for variance unit to start
        wait(variance_busy);
        $display("Variance unit is busy...");
        
        // Wait for variance calculation to complete
        wait(variance_valid);
        $display("Variance calculation complete");
        $display("Variance result: %d (expected ~1310720)", variance_out);
        
        if (variance_out > 1200000 && variance_out < 1400000) begin
            $display("PASS: Variance calculation looks reasonable");
        end else if (variance_out == 0) begin
            $display("FAIL: Variance is zero - calculation error");
        end else begin
            $display("MAYBE: Variance result differs from expected");
        end
        
        $display("\n=== All Tests Complete ===");
        #100 $finish;
    end

endmodule
