// simple_matrix_layernorm.v - Simple wrapper that processes matrix column by column
`timescale 1ns / 1ps

module simple_matrix_layernorm;

    // Parameters - same as your working LayerNorm
    parameter D_MODEL = 128;  // Column height (feature dimension)
    parameter MATRIX_COLS = 64;  // Number of columns (sequence length)
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

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Matrix storage - 128x64 matrix (128 features, 64 positions)
    reg signed [X_WIDTH-1:0] input_matrix [0:D_MODEL-1][0:MATRIX_COLS-1];
    reg signed [Y_WIDTH-1:0] output_matrix [0:D_MODEL-1][0:MATRIX_COLS-1];
    
    // LayerNorm interface
    reg start_in;
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in;
    
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_flat_out;
    wire done_valid_out;
    wire busy_out_debug;
    
    // Loop counters
    integer i, j, col_index;
    
    // LayerNorm instance - your existing working module
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
    ) layernorm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(start_in),
        .x_vector_flat_in(x_vector_flat_in),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_vector_flat_out(y_vector_flat_out),
        .done_valid_out(done_valid_out),
        .busy_out_debug(busy_out_debug),
        // Debug outputs - not connected for simplicity
        .mu_out_debug(),
        .mu_valid_debug(),
        .sigma_sq_out_debug(),
        .sigma_sq_valid_debug(),
        .var_plus_eps_out_debug(),
        .var_plus_eps_valid_debug(),
        .std_dev_out_debug(),
        .std_dev_valid_debug(),
        .recip_std_dev_out_debug(),
        .recip_std_dev_valid_debug()
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Main test procedure
    initial begin
        // Initialize
        rst_n = 0;
        start_in = 0;
        col_index = 0;
        
        // Initialize gamma and beta (same as your working testbench)
        for (i = 0; i < D_MODEL; i = i + 1) begin
            gamma_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h40; // 1.0 in Q1.6
            beta_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h00;  // 0.0 in Q1.6
        end
        
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        $display("=== Matrix LayerNorm Test (64x64) ===");
        $display("Creating alternating pattern matrix...");
        
        // Create test matrix: alternating 2.0 and 0.5 in each column
        for (i = 0; i < D_MODEL; i = i + 1) begin
            for (j = 0; j < MATRIX_COLS; j = j + 1) begin
                if (i % 2 == 0) begin
                    input_matrix[i][j] = 16'h0800; // 2.0 in Q5.10
                end else begin
                    input_matrix[i][j] = 16'h0200; // 0.5 in Q5.10
                end
            end
        end
        
        $display("Processing matrix column by column...");
        
        // Process each column
        for (col_index = 0; col_index < MATRIX_COLS; col_index = col_index + 1) begin
            $display("Processing column %0d/64", col_index);
            
            // Extract column col_index into x_vector_flat_in
            for (i = 0; i < D_MODEL; i = i + 1) begin
                x_vector_flat_in[(i * X_WIDTH) +: X_WIDTH] = input_matrix[i][col_index];
            end
            
            // Debug: show first few elements of input vector
            if (col_index < 4) begin
                $display("  Input vector: [%h, %h, %h, %h]", 
                         x_vector_flat_in[15:0], x_vector_flat_in[31:16], 
                         x_vector_flat_in[47:32], x_vector_flat_in[63:48]);
            end
            
            // Start LayerNorm processing
            @(posedge clk);
            start_in = 1;
            @(posedge clk);
            start_in = 0;
            
            // Wait for completion
            wait(done_valid_out);
            @(posedge clk);
            
            // Debug: show LayerNorm output
            if (col_index < 4) begin
                $display("  LayerNorm output: [%h, %h, %h, %h]", 
                         y_vector_flat_out[15:0], y_vector_flat_out[31:16], 
                         y_vector_flat_out[47:32], y_vector_flat_out[63:48]);
            end
            
            // Store results back to output matrix
            for (i = 0; i < D_MODEL; i = i + 1) begin
                output_matrix[i][col_index] = y_vector_flat_out[(i * Y_WIDTH) +: Y_WIDTH];
            end
            
            // Debug: verify stored values
            if (col_index < 4) begin
                $display("  Stored values: [%h, %h, %h, %h]", 
                         output_matrix[0][col_index], output_matrix[1][col_index], 
                         output_matrix[2][col_index], output_matrix[3][col_index]);
            end
            
            // Wait for module to be ready for next operation
            wait(!busy_out_debug);
            repeat(5) @(posedge clk);
        end
        
        $display("Matrix processing completed!");
        
        // Display results
        $display("\nSample results:");
        $display("Input matrix [0:3][0:3]:");
        for (i = 0; i < 4; i = i + 1) begin
            $display("  [%h, %h, %h, %h]", 
                     input_matrix[i][0], input_matrix[i][1], input_matrix[i][2], input_matrix[i][3]);
        end
        
        $display("\nOutput matrix [0:3][0:3]:");
        for (i = 0; i < 4; i = i + 1) begin
            $display("  [%h, %h, %h, %h]", 
                     output_matrix[i][0], output_matrix[i][1], output_matrix[i][2], output_matrix[i][3]);
        end
        
        // Verify results
        if (output_matrix[0][0] != 16'hxxxx && output_matrix[1][0] != 16'hxxxx) begin
            $display("\n¿ SUCCESS: Matrix LayerNorm completed successfully!");
            $display("  Sample outputs: %h, %h, %h, %h", 
                     output_matrix[0][0], output_matrix[1][0], output_matrix[0][1], output_matrix[1][1]);
        end else begin
            $display("\n¿ FAILED: Output contains undefined values");
        end
        
        repeat(20) @(posedge clk);
        $finish;
    end
    
    // Timeout protection
    initial begin
        #10000000; // 10ms timeout (should be enough for 64 columns)
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
