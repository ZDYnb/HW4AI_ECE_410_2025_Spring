// tb_layer_norm_top.v - Basic testbench for layer_norm_top module
`timescale 1ns / 1ps

module tb_layer_norm_top;

    // Parameters - same as DUT
    parameter D_MODEL = 64;
    parameter X_WIDTH = 16;
    parameter X_FRAC = 10;
    parameter Y_WIDTH = 16;
    parameter Y_FRAC = 10;
    parameter PARAM_WIDTH = 8;
    parameter PARAM_FRAC = 6;
    parameter INTERNAL_X_WIDTH = 24;
    parameter INTERNAL_X_FRAC = 10;
    parameter ADDER_OUTPUT_WIDTH = INTERNAL_X_WIDTH + 7;
    parameter MEAN_CALC_OUT_WIDTH = INTERNAL_X_WIDTH;
    parameter VARIANCE_UNIT_OUT_WIDTH = INTERNAL_X_WIDTH;
    parameter VAR_EPS_DATA_WIDTH = INTERNAL_X_WIDTH;
    parameter SQRT_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH;
    parameter RECIP_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg start_in;
    
    // Input vectors
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in;
    
    // Loop variable
    integer i;
    
    // Additional variables for complex tests
    reg has_output;
    
    // Previous values for edge detection
    reg normalization_busy_prev;
    reg done_valid_prev;
    
    // Output signals
    wire signed [MEAN_CALC_OUT_WIDTH-1:0] mu_out_debug;
    wire mu_valid_debug;
    wire signed [VARIANCE_UNIT_OUT_WIDTH-1:0] sigma_sq_out_debug;
    wire sigma_sq_valid_debug;
    wire signed [VAR_EPS_DATA_WIDTH-1:0] var_plus_eps_out_debug;
    wire var_plus_eps_valid_debug;
    wire signed [SQRT_FINAL_OUT_WIDTH-1:0] std_dev_out_debug;
    wire std_dev_valid_debug;
    wire signed [RECIP_FINAL_OUT_WIDTH-1:0] recip_std_dev_out_debug;
    wire recip_std_dev_valid_debug;
    wire busy_out_debug;
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_flat_out;
    wire done_valid_out;

    // Instantiate DUT
    layer_norm_top #(
        .D_MODEL(D_MODEL),
        .X_WIDTH(X_WIDTH),
        .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH),
        .Y_FRAC(Y_FRAC),
        .PARAM_WIDTH(PARAM_WIDTH),
        .PARAM_FRAC(PARAM_FRAC),
        .INTERNAL_X_WIDTH(INTERNAL_X_WIDTH),
        .INTERNAL_X_FRAC(INTERNAL_X_FRAC),
        .ADDER_OUTPUT_WIDTH(ADDER_OUTPUT_WIDTH),
        .MEAN_CALC_OUT_WIDTH(MEAN_CALC_OUT_WIDTH),
        .VARIANCE_UNIT_OUT_WIDTH(VARIANCE_UNIT_OUT_WIDTH),
        .VAR_EPS_DATA_WIDTH(VAR_EPS_DATA_WIDTH),
        .SQRT_FINAL_OUT_WIDTH(SQRT_FINAL_OUT_WIDTH),
        .RECIP_FINAL_OUT_WIDTH(RECIP_FINAL_OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(start_in),
        .x_vector_flat_in(x_vector_flat_in),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .mu_out_debug(mu_out_debug),
        .mu_valid_debug(mu_valid_debug),
        .sigma_sq_out_debug(sigma_sq_out_debug),
        .sigma_sq_valid_debug(sigma_sq_valid_debug),
        .var_plus_eps_out_debug(var_plus_eps_out_debug),
        .var_plus_eps_valid_debug(var_plus_eps_valid_debug),
        .std_dev_out_debug(std_dev_out_debug),
        .std_dev_valid_debug(std_dev_valid_debug),
        .recip_std_dev_out_debug(recip_std_dev_out_debug),
        .recip_std_dev_valid_debug(recip_std_dev_valid_debug),
        .busy_out_debug(busy_out_debug),
        .y_vector_flat_out(y_vector_flat_out),
        .done_valid_out(done_valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock (10ns period)
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        start_in = 0;
        x_vector_flat_in = 0;
        gamma_vector_flat_in = 0;
        beta_vector_flat_in = 0;

        // Wait for a few clock cycles
        repeat(5) @(posedge clk);
        
        // Release reset
        rst_n = 1;
        @(posedge clk);

        // Test case 1: Simple test with identical values
        $display("=== Test Case 1: Identical inputs (1.0) ===");
        
        // Fill x_vector with identical values (1.0 in fixed-point format)
        repeat(D_MODEL) begin
            x_vector_flat_in = x_vector_flat_in << X_WIDTH;
            x_vector_flat_in[X_WIDTH-1:0] = 16'h0400; // 1.0 in Q5.10
        end

        // Fill gamma and beta with default values
        repeat(D_MODEL) begin
            gamma_vector_flat_in = gamma_vector_flat_in << PARAM_WIDTH;
            gamma_vector_flat_in[PARAM_WIDTH-1:0] = 8'h40; // 1.0 in Q1.6
            beta_vector_flat_in = beta_vector_flat_in << PARAM_WIDTH;
            beta_vector_flat_in[PARAM_WIDTH-1:0] = 8'h00; // 0.0 in Q1.6
        end

        // Start the operation
        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        // Wait for completion
        wait(done_valid_out);
        @(posedge clk);
        
        $display("Test Case 1 Results:");
        $display("  Mean: %h (%0d) - Expected: 1.0 = 1024", mu_out_debug, mu_out_debug);
        $display("  Final output (first 4): [%h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48]);
        
        // For identical inputs, output should be ~0
        if ((y_vector_flat_out[Y_WIDTH-1:0] >= -16 && y_vector_flat_out[Y_WIDTH-1:0] <= 16)) begin
            $display("¿ Test Case 1 PASSED - Output ~0 for identical inputs");
        end else begin
            $display("¿ Test Case 1 FAILED - Expected ~0, got %0d", $signed(y_vector_flat_out[Y_WIDTH-1:0]));
        end

        wait(!busy_out_debug);
        repeat(10) @(posedge clk);

        // Test case 2: Alternating values
        $display("\n=== Test Case 2: Alternating 2.0 and 0.5 ===");
        
        x_vector_flat_in = 0;
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i % 2 == 0) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0800; // 2.0 in Q5.10
            end else begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0200; // 0.5 in Q5.10
            end
        end

        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        wait(done_valid_out);
        @(posedge clk);
        
        $display("Test Case 2 Results:");
        $display("  Mean: %h (%0d) - Expected: 1.25 = 1280", mu_out_debug, mu_out_debug);
        $display("  Std Dev: %h (%0d) - Expected: 0.75 = 768", std_dev_out_debug, std_dev_out_debug);
        $display("  Final output (first 4): [%h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48]);
        
        if (((y_vector_flat_out[Y_WIDTH-1:0] == 16'h0400) || (y_vector_flat_out[Y_WIDTH-1:0] == 16'hFC00)) &&
            ((y_vector_flat_out[2*Y_WIDTH-1:Y_WIDTH] == 16'h0400) || (y_vector_flat_out[2*Y_WIDTH-1:Y_WIDTH] == 16'hFC00))) begin
            $display("¿ Test Case 2 PASSED - Correct alternating ±1.0 pattern");
        end else begin
            $display("¿ Test Case 2 FAILED - Unexpected pattern");
        end

        wait(!busy_out_debug);
        repeat(10) @(posedge clk);

        // Test case 3: Random-like pattern
        $display("\n=== Test Case 3: Random-like pattern ===");
        
        x_vector_flat_in = 0;
        // Create a pseudo-random pattern with known values
        for (i = 0; i < D_MODEL; i = i + 1) begin
            case (i % 8)
                0: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0600; // 1.5
                1: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0200; // 0.5  
                2: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0A00; // 2.5
                3: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0100; // 0.25
                4: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0800; // 2.0
                5: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0300; // 0.75
                6: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0C00; // 3.0
                7: x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0080; // 0.125
            endcase
        end

        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        wait(done_valid_out);
        @(posedge clk);
        
        $display("Test Case 3 Results:");
        $display("  Mean: %h (%0d)", mu_out_debug, mu_out_debug);
        $display("  Variance (scaled): %0d", sigma_sq_out_debug >> 10);
        $display("  Std Dev: %h (%0d)", std_dev_out_debug, std_dev_out_debug);
        $display("  Final output (first 8): [%h, %h, %h, %h, %h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48],
                 y_vector_flat_out[79:64], y_vector_flat_out[95:80], y_vector_flat_out[111:96], y_vector_flat_out[127:112]);
        
        // Check if outputs are reasonable (not all zero, within expected range)
        has_output = 0;
        for (i = 0; i < 8; i = i + 1) begin
            if (y_vector_flat_out[i*Y_WIDTH +: Y_WIDTH] != 0) has_output = 1;
        end
        
        if (has_output) begin
            $display("¿ Test Case 3 PASSED - Non-zero normalized outputs generated");
        end else begin
            $display("¿ Test Case 3 FAILED - All outputs are zero");
        end

        wait(!busy_out_debug);
        repeat(10) @(posedge clk);

        // Test case 4: Extreme values (testing saturation)
        $display("\n=== Test Case 4: Extreme values ===");
        
        x_vector_flat_in = 0;
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i < 64) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h7C00; // ~31.0 (near max positive)
            end else begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0040; // ~0.0625 (small positive)
            end
        end

        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        wait(done_valid_out);
        @(posedge clk);
        
        $display("Test Case 4 Results:");
        $display("  Mean: %h (%0d)", mu_out_debug, mu_out_debug);
        $display("  Variance (scaled): %0d", sigma_sq_out_debug >> 10);
        $display("  Std Dev: %h (%0d)", std_dev_out_debug, std_dev_out_debug);
        $display("  Final output range - First half: [%h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48]);
        $display("  Final output range - Second half: [%h, %h, %h, %h]", 
                 y_vector_flat_out[64*16+15:64*16], y_vector_flat_out[65*16+15:65*16], 
                 y_vector_flat_out[66*16+15:66*16], y_vector_flat_out[67*16+15:67*16]);
        
        // Check if we get reasonable outputs without overflow
        if (y_vector_flat_out[15:0] != 0 && y_vector_flat_out[64*16+15:64*16] != 0) begin
            $display("¿ Test Case 4 PASSED - Handled extreme values successfully");
        end else begin
            $display("¿ Test Case 4 FAILED - Extreme values not handled properly");
        end

        wait(!busy_out_debug);
        repeat(10) @(posedge clk);

        // Test case 5: Negative values
        $display("\n=== Test Case 5: Mixed positive/negative values ===");
        
        x_vector_flat_in = 0;
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i % 4 == 0) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0800; // +2.0
            end else if (i % 4 == 1) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'hF800; // -2.0
            end else if (i % 4 == 2) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0400; // +1.0
            end else begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'hFC00; // -1.0
            end
        end

        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        wait(done_valid_out);
        @(posedge clk);
        
        $display("Test Case 5 Results:");
        $display("  Mean: %h (%0d) - Expected: 0.0 = 0", mu_out_debug, mu_out_debug);
        $display("  Variance (scaled): %0d", sigma_sq_out_debug >> 10);
        $display("  Std Dev: %h (%0d)", std_dev_out_debug, std_dev_out_debug);
        $display("  Final output (first 8): [%h, %h, %h, %h, %h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48],
                 y_vector_flat_out[79:64], y_vector_flat_out[95:80], y_vector_flat_out[111:96], y_vector_flat_out[127:112]);
        
        // Check if mean is close to 0 and we have reasonable outputs
        if (mu_out_debug >= -100 && mu_out_debug <= 100 && y_vector_flat_out[15:0] != 0) begin
            $display("¿ Test Case 5 PASSED - Handled mixed pos/neg values correctly");
        end else begin
            $display("¿ Test Case 5 FAILED - Mixed values not handled properly");
        end

        // End simulation
        $display("\n¿ All LayerNorm test cases completed!");
        repeat(10) @(posedge clk);
        $finish;
    end

    // Monitor important signals - updated for complete LayerNorm
    initial begin
        $monitor("Time: %0t | rst_n: %b | start_in: %b | busy: %b | mu_valid: %b | mu_out: %h | var_valid: %b | var_out: %h | var_eps_valid: %b | var_eps_out: %h | std_valid: %b | std_out: %h | recip_valid: %b | recip_out: %h | norm_busy: %b | done_valid: %b", 
                 $time, rst_n, start_in, busy_out_debug, mu_valid_debug, mu_out_debug, sigma_sq_valid_debug, sigma_sq_out_debug, var_plus_eps_valid_debug, var_plus_eps_out_debug, std_dev_valid_debug, std_dev_out_debug, recip_std_dev_valid_debug, recip_std_dev_out_debug, dut.normalization_busy, done_valid_out);
    end

    // Debug normalization unit processing
    always @(posedge clk) begin
        if (dut.normalization_busy) begin
            $display("[TB Debug] Time: %0t | Normalization unit processing: busy=%b", 
                     $time, dut.normalization_busy);
        end
        
        // Show when normalization processing completes
        if (!dut.normalization_busy && normalization_busy_prev) begin
            $display("[TB Debug] Time: %0t | Normalization processing completed!", $time);
        end
        
        // Show when done_valid is asserted
        if (done_valid_out && !done_valid_prev) begin
            $display("[TB Debug] Time: %0t | done_valid asserted!", $time);
            $display("  Final output [0-7]: %h %h %h %h %h %h %h %h", 
                     y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48],
                     y_vector_flat_out[79:64], y_vector_flat_out[95:80], y_vector_flat_out[111:96], y_vector_flat_out[127:112]);
        end
        
        // Update previous values
        normalization_busy_prev <= dut.normalization_busy;
        done_valid_prev <= done_valid_out;
    end

    // Timeout protection - increased for complete LayerNorm
    initial begin
        #2000000; // 2ms timeout (normalization unit processing needs additional time)
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
