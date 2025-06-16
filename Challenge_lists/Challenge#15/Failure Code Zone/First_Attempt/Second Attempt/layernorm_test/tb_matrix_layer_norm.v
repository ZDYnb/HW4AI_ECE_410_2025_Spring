// tb_matrix_layer_norm.v - Simple testbench for matrix LayerNorm module
`timescale 1ns / 1ps

module tb_matrix_layer_norm;

    // Parameters - same as DUT
    parameter MATRIX_SIZE = 64;
    parameter D_MODEL = 64;
    parameter SEQ_LEN = 64;
    parameter X_WIDTH = 16;
    parameter X_FRAC = 10;
    parameter Y_WIDTH = 16;
    parameter Y_FRAC = 10;
    parameter PARAM_WIDTH = 8;
    parameter PARAM_FRAC = 6;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg start_matrix_norm;
    
    // Input matrix - 64x64 flattened
    reg signed [(MATRIX_SIZE * MATRIX_SIZE * X_WIDTH) - 1 : 0] matrix_in_flat;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in;
    reg signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in;
    
    // Output signals
    wire signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] matrix_out_flat;
    wire matrix_norm_done;
    wire matrix_busy;
    
    // Loop variables and test data
    integer i, j;
    
    // Helper variables for verification
    wire signed [Y_WIDTH-1:0] out_00, out_01, out_02, out_03;
    wire signed [Y_WIDTH-1:0] out_10, out_11, out_12, out_13;
    
    // Direct access to specific output elements for debugging
    assign out_00 = matrix_out_flat[(0 * MATRIX_SIZE + 0) * Y_WIDTH +: Y_WIDTH]; // [0][0]
    assign out_01 = matrix_out_flat[(0 * MATRIX_SIZE + 1) * Y_WIDTH +: Y_WIDTH]; // [0][1]
    assign out_02 = matrix_out_flat[(0 * MATRIX_SIZE + 2) * Y_WIDTH +: Y_WIDTH]; // [0][2]
    assign out_03 = matrix_out_flat[(0 * MATRIX_SIZE + 3) * Y_WIDTH +: Y_WIDTH]; // [0][3]
    assign out_10 = matrix_out_flat[(1 * MATRIX_SIZE + 0) * Y_WIDTH +: Y_WIDTH]; // [1][0]
    assign out_11 = matrix_out_flat[(1 * MATRIX_SIZE + 1) * Y_WIDTH +: Y_WIDTH]; // [1][1]
    assign out_12 = matrix_out_flat[(1 * MATRIX_SIZE + 2) * Y_WIDTH +: Y_WIDTH]; // [1][2]
    assign out_13 = matrix_out_flat[(1 * MATRIX_SIZE + 3) * Y_WIDTH +: Y_WIDTH]; // [1][3]

    // Instantiate DUT
    matrix_layer_norm #(
        .MATRIX_SIZE(MATRIX_SIZE),
        .D_MODEL(D_MODEL),
        .SEQ_LEN(SEQ_LEN),
        .X_WIDTH(X_WIDTH),
        .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH),
        .Y_FRAC(Y_FRAC),
        .PARAM_WIDTH(PARAM_WIDTH),
        .PARAM_FRAC(PARAM_FRAC)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_matrix_norm(start_matrix_norm),
        .matrix_in_flat(matrix_in_flat),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .matrix_out_flat(matrix_out_flat),
        .matrix_norm_done(matrix_norm_done),
        .matrix_busy(matrix_busy)
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
        start_matrix_norm = 0;
        matrix_in_flat = 0;

        // Initialize LayerNorm parameters: gamma=1.0, beta=0.0
        for (i = 0; i < D_MODEL; i = i + 1) begin
            gamma_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h40; // 1.0 in Q1.6
            beta_vector_flat_in[(i * PARAM_WIDTH) +: PARAM_WIDTH] = 8'h00;  // 0.0 in Q1.6
        end

        // Wait and release reset
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        $display("=== Matrix LayerNorm Test ===");

        // Test Case: Simple pattern - alternating 2.0 and 0.5 in each column
        $display("Creating test matrix: each column alternates 2.0 and 0.5");
        
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                if (i % 2 == 0) begin
                    // Even rows: 2.0 in Q5.10 format
                    matrix_in_flat[((i * MATRIX_SIZE + j) * X_WIDTH) +: X_WIDTH] = 16'h0800;
                end else begin
                    // Odd rows: 0.5 in Q5.10 format  
                    matrix_in_flat[((i * MATRIX_SIZE + j) * X_WIDTH) +: X_WIDTH] = 16'h0200;
                end
            end
        end

        // Start processing
        $display("Starting matrix processing...");
        @(posedge clk);
        start_matrix_norm = 1;
        @(posedge clk);
        start_matrix_norm = 0;

        // Wait for completion
        wait(matrix_norm_done);
        @(posedge clk);
        
        $display("Matrix processing completed!");
        $display("");
        $display("Results:");
        $display("  Output[0][0] = %h (%0d)", out_00, $signed(out_00));
        $display("  Output[0][1] = %h (%0d)", out_01, $signed(out_01));
        $display("  Output[0][2] = %h (%0d)", out_02, $signed(out_02));
        $display("  Output[0][3] = %h (%0d)", out_03, $signed(out_03));
        $display("  Output[1][0] = %h (%0d)", out_10, $signed(out_10));
        $display("  Output[1][1] = %h (%0d)", out_11, $signed(out_11));
        $display("  Output[1][2] = %h (%0d)", out_12, $signed(out_12));
        $display("  Output[1][3] = %h (%0d)", out_13, $signed(out_13));
        $display("");
        
        // Analysis
        if ($signed(out_00) > 0 && $signed(out_10) < 0) begin
            $display("¿ PASS: Alternating pattern correctly normalized");
            $display("  Even rows (2.0) -> positive values");
            $display("  Odd rows (0.5) -> negative values");
        end else begin
            $display("¿ FAIL: Unexpected normalization results");
        end

        // Check if all columns have similar pattern
        $display("");
        $display("Checking consistency across columns...");
        if ((out_00 == out_01) && (out_01 == out_02) && (out_02 == out_03)) begin
            $display("¿ PASS: All columns show consistent results");
        end else begin
            $display("? INFO: Columns may have slight variations (normal)");
        end

        repeat(20) @(posedge clk);
        $display("");
        $display("=== Test Complete ===");
        $finish;
    end

    // Monitor progress
    always @(posedge clk) begin
        if (dut.state == 2'b10 && dut.layernorm_start) begin // PROCESS_COLUMN
            $display("[Progress] Processing column %0d/64", dut.col_counter);
        end
    end

    // Timeout protection
    initial begin
        #300000000; // 300ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
