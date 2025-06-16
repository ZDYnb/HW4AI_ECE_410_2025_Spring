
// tb_linear_layer_unit.v (Enhanced for M_ROWS_TB > 1)
`timescale 1ns / 1ps

module tb_linear_layer_unit;

    // Parameters for this test
    localparam DATA_WIDTH   = 8;
    localparam ACCUM_WIDTH  = 32;
    localparam M_ROWS_TB    = 2; // CHANGED: Number of input rows
    localparam K_COLS_TB    = 2; 
    localparam N_COLS_TB    = 2; 
    localparam CLK_PERIOD   = 10;  // 10ns => 100 MHz

    // DUT Interface Signals
    reg                               clk;
    reg                               rst_n;
    reg                               op_start_ll_tb;

    reg signed [DATA_WIDTH-1:0]       input_activation_matrix_tb [0:M_ROWS_TB-1][0:K_COLS_TB-1];
    reg signed [DATA_WIDTH-1:0]       weight_matrix_tb           [0:K_COLS_TB-1][0:N_COLS_TB-1];
    reg signed [ACCUM_WIDTH-1:0]      bias_vector_tb             [0:N_COLS_TB-1];

    // DUT output wire size will be determined by parameters passed to DUT instance
    wire signed [ACCUM_WIDTH-1:0]     output_matrix_dut          [0:M_ROWS_TB-1][0:N_COLS_TB-1];
    wire                              op_busy_ll_dut;
    wire                              op_done_ll_dut;

    // Instantiate the DUT
    linear_layer_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .M_ROWS(M_ROWS_TB), // Pass TB parameter to DUT
        .K_COLS(K_COLS_TB),
        .N_COLS(N_COLS_TB)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .op_start_ll(op_start_ll_tb),
        .input_activation_matrix(input_activation_matrix_tb),
        .weight_matrix(weight_matrix_tb),
        .bias_vector(bias_vector_tb),
        .output_matrix(output_matrix_dut),
        .op_busy_ll(op_busy_ll_dut),
        .op_done_ll(op_done_ll_dut)
    );

    // Clock generation
    always # (CLK_PERIOD/2) clk = ~clk;

    // Test sequence
    initial begin
        // Local variables for testbench calculations
        integer m, k, n; // Loop variables
        reg signed [ACCUM_WIDTH-1:0] expected_output_matrix [0:M_ROWS_TB-1][0:N_COLS_TB-1];
        reg signed [ACCUM_WIDTH-1:0] temp_row_sum;
        integer timeout_counter;
        integer max_timeout_cycles;
        logic test_passed;

        // Initialize signals
        clk = 1'b0;
        rst_n = 1'b0;
        op_start_ll_tb = 1'b0;
        
        // Initialize input arrays to 0
        for (m = 0; m < M_ROWS_TB; m = m + 1) begin
            for (k = 0; k < K_COLS_TB; k = k + 1) begin
                input_activation_matrix_tb[m][k] = 0;
            end
        end
        for (k = 0; k < K_COLS_TB; k = k + 1) begin
            for (n = 0; n < N_COLS_TB; n = n + 1) begin
                weight_matrix_tb[k][n] = 0;
            end
        end
        for (n = 0; n < N_COLS_TB; n = n + 1) begin
            bias_vector_tb[n] = 0;
        end

        $display("[%0t TB] Starting Linear Layer Unit Testbench (M=%0d)...", $time, M_ROWS_TB);

        // Reset sequence
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1: M=2, K=2, N=2 ---
        $display("[%0t TB] === Test Case 1: M=%0d, K=%0d, N=%0d ===", $time, M_ROWS_TB, K_COLS_TB, N_COLS_TB);

        // Define input data
        // Activation A = [[1, 2],   (2x2 matrix)
        //                 [3, 1]]
        input_activation_matrix_tb[0][0] = 1; input_activation_matrix_tb[0][1] = 2;
        input_activation_matrix_tb[1][0] = 3; input_activation_matrix_tb[1][1] = 1;


        // Weights W = [[3, 4],   (2x2 matrix)
        //              [5, 6]]
        weight_matrix_tb[0][0] = 3; weight_matrix_tb[0][1] = 4;
        weight_matrix_tb[1][0] = 5; weight_matrix_tb[1][1] = 6;

        // Bias B = [10, 20] (vector of length 2)
        bias_vector_tb[0] = 10;
        bias_vector_tb[1] = 20;

        // Calculate Expected Output O = A * W + B
        // Row 0: [1, 2] * W + B = [13, 16] + [10, 20] = [23, 36]
        // Row 1: [3, 1] * W + B = [3*3+1*5, 3*4+1*6] + B = [9+5, 12+6] + B = [14, 18] + [10, 20] = [24, 38]
        // Expected O = [[23, 36],
        //               [24, 38]]
        for (m = 0; m < M_ROWS_TB; m = m + 1) begin
            for (n = 0; n < N_COLS_TB; n = n + 1) begin
                temp_row_sum = 0;
                for (k = 0; k < K_COLS_TB; k = k + 1) begin
                    temp_row_sum = temp_row_sum + input_activation_matrix_tb[m][k] * weight_matrix_tb[k][n];
                end
                expected_output_matrix[m][n] = temp_row_sum + bias_vector_tb[n];
            end
        end
        for (m = 0; m < M_ROWS_TB; m = m + 1) begin
            $display("[%0t TB] Expected Output[%0d][0]=%d, Expected Output[%0d][1]=%d", 
                     $time, m, expected_output_matrix[m][0], m, expected_output_matrix[m][1]);
        end


        // Start the operation
        op_start_ll_tb = 1'b0; 
        @(posedge clk);
        op_start_ll_tb = 1'b1; 
        @(posedge clk);     
        op_start_ll_tb = 1'b0; 
        $display("[%0t TB] op_start_ll pulse sent.", $time);
        
        timeout_counter = 0;
        max_timeout_cycles = (M_ROWS_TB * N_COLS_TB * K_COLS_TB * 15) + 100; // Adjusted timeout for M_ROWS

        if(!op_busy_ll_dut) @(posedge clk); 
        if(!op_busy_ll_dut) $error("[%0t TB] DUT did not become busy!", $time);
        else $display("[%0t TB] DUT is busy, waiting for completion...", $time);

        while (!op_done_ll_dut && op_busy_ll_dut && timeout_counter < max_timeout_cycles) begin
            @(posedge clk);
            timeout_counter = timeout_counter + 1;
        end

        if (timeout_counter >= max_timeout_cycles) begin
            $error("[%0t TB] Test Case 1 TIMEOUT: op_done_ll was not asserted.", $time);
        end else if (!op_done_ll_dut && !op_busy_ll_dut) begin
            $error("[%0t TB] Test Case 1 ERROR: DUT became not busy but op_done_ll was not asserted.", $time);
        end else if (op_done_ll_dut) begin 
            @(posedge clk); // Wait one more cycle for registered output_matrix_dut to be stable
            $display("[%0t TB] op_done_ll received. op_busy_ll is %b.", $time, op_busy_ll_dut);
            
            test_passed = 1'b1;
            for (m = 0; m < M_ROWS_TB; m = m + 1) begin
                for (n = 0; n < N_COLS_TB; n = n + 1) begin
                    if (output_matrix_dut[m][n] !== expected_output_matrix[m][n]) begin
                        $error("[%0t TB] Test Case 1 FAILED at Output[%0d][%0d]. Expected: %d, Got: %d",
                               $time, m, n, expected_output_matrix[m][n], output_matrix_dut[m][n]);
                        test_passed = 1'b0;
                    end
                end
            end
            if (test_passed) begin
                $display("[%0t TB] Test Case 1 PASSED.", $time);
            end
        end

        #(CLK_PERIOD * 5); 

        $display("[%0t TB] Linear Layer Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
