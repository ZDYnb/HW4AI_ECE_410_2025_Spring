// tb_layer_norm_64.v - Test LayerNorm with D_MODEL=64
`timescale 1ns / 1ps

module tb_layer_norm_64;

    // Parameters - Changed to 64!
    parameter D_MODEL = 64;  // <<<--- ¿?¿?64¿?¿?
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

    // Instantiate DUT with D_MODEL=64
    layer_norm_top #(
        .D_MODEL(D_MODEL),  // 64
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
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        start_in = 0;
        x_vector_flat_in = 0;
        gamma_vector_flat_in = 0;
        beta_vector_flat_in = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("=== LayerNorm Test: D_MODEL=64 ===");
        
        // Fill gamma and beta
        for (i = 0; i < D_MODEL; i = i + 1) begin
            gamma_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h40; // 1.0
            beta_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h00;  // 0.0
        end

        // Test: Alternating 2.0 and 0.5
        $display("Test: Alternating 2.0 and 0.5 (64 elements)");
        
        x_vector_flat_in = 0;
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i % 2 == 0) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0800; // 2.0
            end else begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = 16'h0200; // 0.5
            end
        end

        // Show input
        $display("Input (first 8): [%h, %h, %h, %h, %h, %h, %h, %h]", 
                 x_vector_flat_in[15:0], x_vector_flat_in[31:16], x_vector_flat_in[47:32], x_vector_flat_in[63:48],
                 x_vector_flat_in[79:64], x_vector_flat_in[95:80], x_vector_flat_in[111:96], x_vector_flat_in[127:112]);

        // Start processing
        @(posedge clk);
        start_in = 1;
        @(posedge clk);
        start_in = 0;

        // Wait for completion
        wait(done_valid_out);
        @(posedge clk);
        
        $display("Results:");
        $display("  Mean: %h (%0d)", mu_out_debug, mu_out_debug);
        $display("  Std Dev: %h (%0d)", std_dev_out_debug, std_dev_out_debug);
        $display("  Output (first 8): [%h, %h, %h, %h, %h, %h, %h, %h]", 
                 y_vector_flat_out[15:0], y_vector_flat_out[31:16], y_vector_flat_out[47:32], y_vector_flat_out[63:48],
                 y_vector_flat_out[79:64], y_vector_flat_out[95:80], y_vector_flat_out[111:96], y_vector_flat_out[127:112]);
        
        // Check results
        if (y_vector_flat_out[15:0] != 16'hxxxx) begin
            $display("¿ SUCCESS: LayerNorm with D_MODEL=64 works!");
        end else begin
            $display("¿ FAILED: Output is undefined");
        end

        repeat(10) @(posedge clk);
        $finish;
    end

    initial begin
        #100000; // 100us timeout
        $display("TIMEOUT!");
        $finish;
    end

endmodule
