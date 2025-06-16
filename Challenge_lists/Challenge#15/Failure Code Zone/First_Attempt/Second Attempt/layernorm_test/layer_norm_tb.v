// tb_layer_norm_top.v - Test Complete LayerNorm with Normalization Unit
module tb_layer_norm_top;
    // Parameters
    parameter CLK_PERIOD = 10;
    parameter D_MODEL = 128;
    parameter X_WIDTH = 16;
    parameter X_FRAC = 10;
    parameter Y_WIDTH = 16;
    parameter Y_FRAC = 10;
    parameter PARAM_WIDTH = 8;
    parameter PARAM_FRAC = 6;
    
    // Test signals
    reg clk;
    reg rst_n;
    reg start_in;
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in;
    
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_flat_out;
    wire done_valid_out;
    
    // Debug signals
    wire busy_out_debug;
    wire mu_valid_debug;
    wire signed [23:0] mu_out_debug;
    wire sigma_sq_valid_debug;
    wire signed [23:0] sigma_sq_out_debug;
    wire var_plus_eps_valid_debug;
    wire signed [23:0] var_plus_eps_out_debug;
    wire std_dev_valid_debug;
    wire signed [23:0] std_dev_out_debug;
    wire recip_std_dev_valid_debug;
    wire signed [23:0] recip_std_dev_out_debug;
    
    // DUT
    layer_norm_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(start_in),
        .x_vector_flat_in(x_vector_flat_in),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_vector_flat_out(y_vector_flat_out),
        .done_valid_out(done_valid_out),
        .busy_out_debug(busy_out_debug),
        .mu_valid_debug(mu_valid_debug),
        .mu_out_debug(mu_out_debug),
        .sigma_sq_valid_debug(sigma_sq_valid_debug),
        .sigma_sq_out_debug(sigma_sq_out_debug),
        .var_plus_eps_valid_debug(var_plus_eps_valid_debug),
        .var_plus_eps_out_debug(var_plus_eps_out_debug),
        .std_dev_valid_debug(std_dev_valid_debug),
        .std_dev_out_debug(std_dev_out_debug),
        .recip_std_dev_valid_debug(recip_std_dev_valid_debug),
        .recip_std_dev_out_debug(recip_std_dev_out_debug)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Monitor key signals
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[%0t] busy=%b | mu_v=%b mu=%0d | var_v=%b | std_v=%b | recip_v=%b | norm_busy=%b norm_done=%b | final_done=%b", 
                     $time, busy_out_debug, mu_valid_debug, mu_out_debug, 
                     sigma_sq_valid_debug, std_dev_valid_debug, recip_std_dev_valid_debug,
                     dut.normalization_busy, dut.normalization_done, done_valid_out);
        end
    end
    
    // Test stimulus
    integer i;
    reg signed [Y_WIDTH-1:0] y_val;
    
    initial begin
        // Initialize
        rst_n = 0;
        start_in = 0;
        x_vector_flat_in = 0;
        gamma_vector_flat_in = 0;
        beta_vector_flat_in = 0;
        
        // Set gamma to 1.0 (64 in Q2.6) and beta to 0 for all elements
        for (i = 0; i < D_MODEL; i = i + 1) begin
            gamma_vector_flat_in[i * PARAM_WIDTH +: PARAM_WIDTH] = 8'h40; // 1.0 in Q2.6
            beta_vector_flat_in[i * PARAM_WIDTH +: PARAM_WIDTH] = 8'h00;   // 0.0
        end
        
        // Reset
        #(5 * CLK_PERIOD);
        rst_n = 1;
        #(2 * CLK_PERIOD);
        
        // ===== Test Case 1: All inputs 1.0 =====
        $display("\n=== Test Case 1: All inputs 1.0 ===");
        
        for (i = 0; i < D_MODEL; i = i + 1) begin
            x_vector_flat_in[i * X_WIDTH +: X_WIDTH] = 16'h0400; // 1.0 in Q5.10
        end
        
        // Start processing
        start_in = 1;
        #CLK_PERIOD;
        start_in = 0;
        
        // Wait for completion
        wait (done_valid_out);
        #(2 * CLK_PERIOD);
        
        // Check results
        $display("\n=== Test Case 1 Results ===");
        $display("Final output (first 8 elements):");
        for (i = 0; i < 8; i = i + 1) begin
            y_val = y_vector_flat_out[i * Y_WIDTH +: Y_WIDTH];
            $display("  y[%0d] = %h (%0d)", i, y_val, y_val);
        end
        
        // For identical inputs, output should be ~0 (after normalization)
        y_val = y_vector_flat_out[0 * Y_WIDTH +: Y_WIDTH];
        if (y_val >= -16 && y_val <= 16) begin // Allow small epsilon errors
            $display("¿ Test Case 1 PASSED - Output ~0 for identical inputs");
        end else begin
            $display("¿ Test Case 1 FAILED - Expected ~0, got %0d", y_val);
        end
        
        #(10 * CLK_PERIOD);
        
        // ===== Test Case 2: Alternating 2.0 and 0.5 =====
        $display("\n=== Test Case 2: Alternating 2.0 and 0.5 ===");
        
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i % 2 == 0) begin
                x_vector_flat_in[i * X_WIDTH +: X_WIDTH] = 16'h0800; // 2.0 in Q5.10
            end else begin
                x_vector_flat_in[i * X_WIDTH +: X_WIDTH] = 16'h0200; // 0.5 in Q5.10
            end
        end
        
        // Start processing
        start_in = 1;
        #CLK_PERIOD;
        start_in = 0;
        
        // Wait for completion
        wait (done_valid_out);
        #(2 * CLK_PERIOD);
        
        // Check results
        $display("\n=== Test Case 2 Results ===");
        $display("Statistics computed:");
        $display("  Mean: %h (%0d) - Expected: 1.25 = 1280", mu_out_debug, mu_out_debug);
        $display("  Variance (raw): %h (%0d)", sigma_sq_out_debug, sigma_sq_out_debug);
        $display("  Variance (scaled): %0d - Expected: ~576", sigma_sq_out_debug >> 10);
        $display("  Std Dev: %h (%0d) - Expected: 0.75 = 768", std_dev_out_debug, std_dev_out_debug);
        $display("  1/Std Dev: %h (%0d) - Expected: ~21844", recip_std_dev_out_debug, recip_std_dev_out_debug);
        
        $display("Final output (first 8 elements):");
        for (i = 0; i < 8; i = i + 1) begin
            y_val = y_vector_flat_out[i * Y_WIDTH +: Y_WIDTH];
            $display("  y[%0d] = %h (%0d)", i, y_val, y_val);
        end
        
        // Verify alternating pattern: +1.0, -1.0, +1.0, -1.0, ...
        y_val = y_vector_flat_out[0 * Y_WIDTH +: Y_WIDTH];
        reg signed [Y_WIDTH-1:0] y1 = y_vector_flat_out[1 * Y_WIDTH +: Y_WIDTH];
        reg signed [Y_WIDTH-1:0] y2 = y_vector_flat_out[2 * Y_WIDTH +: Y_WIDTH];
        reg signed [Y_WIDTH-1:0] y3 = y_vector_flat_out[3 * Y_WIDTH +: Y_WIDTH];
        
        if (y_val == 16'h0400 && y1 == 16'hFC00 && y2 == 16'h0400 && y3 == 16'hFC00) begin
            $display("¿ Test Case 2 PASSED - Correct alternating pattern");
            $display("  Input: [2.0, 0.5, 2.0, 0.5] ¿ Output: [+1.0, -1.0, +1.0, -1.0]");
            $display("  Math: (2.0-1.25)/0.75=1.0, (0.5-1.25)/0.75=-1.0 ¿");
        end else begin
            $display("¿ Test Case 2 FAILED - Unexpected pattern");
            $display("  Expected: [0400, FC00, 0400, FC00] (+1024, -1024, +1024, -1024)");
            $display("  Got:      [%h, %h, %h, %h] (%0d, %0d, %0d, %0d)", 
                     y_val, y1, y2, y3, y_val, y1, y2, y3);
        end
        
        $display("\n¿ Complete LayerNorm Integration Test Completed!");
        #(5 * CLK_PERIOD);
        $finish;
    end
    
    // Timeout protection
    initial begin
        #(2000 * CLK_PERIOD);
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
endmodule
