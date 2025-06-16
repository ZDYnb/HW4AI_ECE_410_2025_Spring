// layer_norm_64x64_pipelined_tb.v - Testbench for 64x64 Matrix LayerNorm
`timescale 1ns / 1ps

module layer_norm_64x64_pipelined_tb;

    // Parameters
    parameter MATRIX_SIZE = 64;
    parameter X_WIDTH = 16;
    parameter X_FRAC = 10;
    parameter Y_WIDTH = 16;
    parameter Y_FRAC = 10;
    parameter PARAM_WIDTH = 8;
    parameter PARAM_FRAC = 6;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // DUT inputs
    reg start_matrix;
    reg signed [(MATRIX_SIZE * MATRIX_SIZE * X_WIDTH) - 1 : 0] x_matrix_flat_in;
    reg signed [(MATRIX_SIZE * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in;
    reg signed [(MATRIX_SIZE * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in;
    
    // DUT outputs
    wire signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] y_matrix_flat_out;
    wire matrix_done;
    wire busy;
    wire [5:0] current_row_debug;
    wire row_processing_debug;
    wire [7:0] total_cycles_debug;
    
    // Test variables
    integer i, row, col;
    integer cycle_count;
    integer matrix_idx;
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // S5.10 conversion functions
    function signed [X_WIDTH-1:0] real_to_s5p10;
        input real value;
        begin
            if (value > 31.999) value = 31.999;
            if (value < -32.0) value = -32.0;
            real_to_s5p10 = $rtoi(value * 1024.0);
        end
    endfunction
    
    function real s5p10_to_real;
        input signed [Y_WIDTH-1:0] fixed_val;
        begin
            s5p10_to_real = $signed(fixed_val) / 1024.0;
        end
    endfunction
    
    // S1.6 conversion functions
    function signed [PARAM_WIDTH-1:0] real_to_s1p6;
        input real value;
        begin
            if (value > 1.984) value = 1.984;
            if (value < -2.0) value = -2.0;
            real_to_s1p6 = $rtoi(value * 64.0);
        end
    endfunction
    
    // DUT instantiation
    layer_norm_64x64_pipelined dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_matrix(start_matrix),
        .x_matrix_flat_in(x_matrix_flat_in),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_matrix_flat_out(y_matrix_flat_out),
        .matrix_done(matrix_done),
        .busy(busy),
        .current_row_debug(current_row_debug),
        .row_processing_debug(row_processing_debug),
        .total_cycles_debug(total_cycles_debug)
    );
    
    // Main test
    initial begin
        $display("=== 64x64 Matrix LayerNorm Testbench ===");
        $display("Data format: S5.10 input, S1.6 params");
        
        // Initialize
        rst_n = 0;
        start_matrix = 0;
        x_matrix_flat_in = 0;
        gamma_vector_flat_in = 0;
        beta_vector_flat_in = 0;
        cycle_count = 0;
        
        // Reset sequence
        #100;
        rst_n = 1;
        #50;
        
        // Generate test data
        $display("Generating test matrix...");
        
        // Fill input matrix with test pattern
        for (row = 0; row < MATRIX_SIZE; row = row + 1) begin
            for (col = 0; col < MATRIX_SIZE; col = col + 1) begin
                matrix_idx = row * MATRIX_SIZE + col;
                x_matrix_flat_in[matrix_idx * X_WIDTH +: X_WIDTH] = 
                    real_to_s5p10((col - 32.0) * 0.2 + row * 0.05);
            end
        end
        
        // Set LayerNorm parameters
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            gamma_vector_flat_in[i * PARAM_WIDTH +: PARAM_WIDTH] = real_to_s1p6(1.0);
            beta_vector_flat_in[i * PARAM_WIDTH +: PARAM_WIDTH] = real_to_s1p6(0.0);
        end
        
        $display("Test data generated");
        $display("Starting matrix processing...");
        
        // Start processing
        start_matrix = 1;
        #10;
        start_matrix = 0;
        
        // Wait for completion
        while (!matrix_done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            if (cycle_count % 1000 == 0) begin
                $display("Cycle %d: Row %d/%d", cycle_count, current_row_debug + 1, MATRIX_SIZE);
            end
            
            if (cycle_count > 20000) begin
                $display("ERROR: Timeout!");
                $finish;
            end
        end
        
        $display("Processing completed in %d cycles", cycle_count);
        $display("Average cycles per row: %d", cycle_count / MATRIX_SIZE);
        
        // Display results
        $display("First row results:");
        for (i = 0; i < 8; i = i + 1) begin
            $display("  y[0][%d] = %f", i, 
                    s5p10_to_real(y_matrix_flat_out[i * Y_WIDTH +: Y_WIDTH]));
        end
        
        $display("Test completed successfully!");
        $finish;
    end
    
    // Progress monitor
    always @(posedge clk) begin
        if (busy && (cycle_count % 500 == 0) && (cycle_count > 0)) begin
            $display("Processing row %d/%d (cycle %d)", 
                    current_row_debug + 1, MATRIX_SIZE, cycle_count);
        end
    end

endmodule
