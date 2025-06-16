// tb_matrix_transpose_unit.v
`timescale 1ns / 1ps

module tb_matrix_transpose_unit;

    // Parameters matching DUT defaults
    localparam DATA_WIDTH_TB = 8;
    localparam M_ROWS_TB     = 2; // Rows in input matrix
    localparam N_COLS_TB     = 3; // Columns in input matrix
    localparam CLK_PERIOD    = 10; // 10ns => 100 MHz

    // DUT Interface Signals
    reg                               clk_tb;
    reg                               rst_n_tb;
    reg                               op_start_transpose_tb;
    reg signed [DATA_WIDTH_TB-1:0]    input_matrix_tb [0:M_ROWS_TB-1][0:N_COLS_TB-1];
    wire signed [DATA_WIDTH_TB-1:0]   output_matrix_transposed_dut [0:N_COLS_TB-1][0:M_ROWS_TB-1];
    wire                              op_busy_transpose_dut;
    wire                              op_done_transpose_dut;

    // Instantiate the DUT
    matrix_transpose_unit #(
        .DATA_WIDTH(DATA_WIDTH_TB),
        .M_ROWS(M_ROWS_TB),
        .N_COLS(N_COLS_TB)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .op_start_transpose(op_start_transpose_tb),
        .input_matrix(input_matrix_tb),
        .output_matrix_transposed(output_matrix_transposed_dut),
        .op_busy_transpose(op_busy_transpose_dut),
        .op_done_transpose(op_done_transpose_dut)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    // Test sequence
    initial begin
        // ALL LOCAL VARIABLE DECLARATIONS AT THE TOP OF THE BLOCK
        integer r, c; // Loop variables
        reg signed [DATA_WIDTH_TB-1:0] expected_transposed_matrix [0:N_COLS_TB-1][0:M_ROWS_TB-1];
        integer timeout_counter;
        integer max_timeout_cycles; // Declaration only
        logic test_passed;

        // Initialize signals
        clk_tb = 1'b0;
        rst_n_tb = 1'b0;
        op_start_transpose_tb = 1'b0;
        max_timeout_cycles = 10; // Initialization after declaration
        
        // Initialize input matrix to 0 (optional, good practice)
        for (r = 0; r < M_ROWS_TB; r = r + 1) begin
            for (c = 0; c < N_COLS_TB; c = c + 1) begin
                input_matrix_tb[r][c] = 0;
            end
        end

        $display("[%0t TB] Starting Matrix Transpose Unit Testbench...", $time);

        // Reset sequence
        #(CLK_PERIOD * 2);
        rst_n_tb = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1 ---
        $display("[%0t TB] === Test Case 1: M=%0d, N=%0d ===", $time, M_ROWS_TB, N_COLS_TB);

        // Define input matrix A (2x3)
        // A = [[1, 2, 3],
        //      [4, 5, 6]]
        input_matrix_tb[0][0] = 1; input_matrix_tb[0][1] = 2; input_matrix_tb[0][2] = 3;
        input_matrix_tb[1][0] = 4; input_matrix_tb[1][1] = 5; input_matrix_tb[1][2] = 6;

        $display("[%0t TB] Input Matrix:", $time);
        for (r = 0; r < M_ROWS_TB; r = r + 1) begin
            $display("[%0t TB] Row %0d: %d %d %d", $time, r, input_matrix_tb[r][0], input_matrix_tb[r][1], input_matrix_tb[r][2]);
        end

        // Calculate Expected Transposed Matrix A_T (3x2)
        // A_T = [[1, 4],
        //        [2, 5],
        //        [3, 6]]
        for (r = 0; r < M_ROWS_TB; r = r + 1) begin
            for (c = 0; c < N_COLS_TB; c = c + 1) begin
                expected_transposed_matrix[c][r] = input_matrix_tb[r][c];
            end
        end
        $display("[%0t TB] Expected Transposed Matrix:", $time);
        for (c = 0; c < N_COLS_TB; c = c + 1) begin // Iterate by columns of A_T (rows of A)
             $display("[%0t TB] Row %0d: %d %d", $time, c, expected_transposed_matrix[c][0], expected_transposed_matrix[c][1]);
        end


        // Start the operation
        op_start_transpose_tb = 1'b0; 
        @(posedge clk_tb);
        op_start_transpose_tb = 1'b1; 
        @(posedge clk_tb);     
        op_start_transpose_tb = 1'b0; 
        $display("[%0t TB] op_start_transpose pulse sent.", $time);
        
        timeout_counter = 0; // Initialize before use in loop

        if(!op_busy_transpose_dut) @(posedge clk_tb); 
        if(!op_busy_transpose_dut) begin // Added begin/end for clarity
            $error("[%0t TB] DUT did not become busy!", $time);
        end else begin
            $display("[%0t TB] DUT is busy, waiting for completion...", $time);
        end

        while (!op_done_transpose_dut && op_busy_transpose_dut && timeout_counter < max_timeout_cycles) begin
            @(posedge clk_tb);
            timeout_counter = timeout_counter + 1;
        end

        if (timeout_counter >= max_timeout_cycles) begin
            $error("[%0t TB] Test Case 1 TIMEOUT: op_done_transpose_dut was not asserted.", $time);
        end else if (!op_done_transpose_dut && !op_busy_transpose_dut) begin
            $error("[%0t TB] Test Case 1 ERROR: DUT became not busy but op_done_transpose_dut was not asserted.", $time);
        end else if (op_done_transpose_dut) begin 
            @(posedge clk_tb); 
            $display("[%0t TB] op_done_transpose_dut received. op_busy_transpose_dut is %b.", $time, op_busy_transpose_dut);
            
            test_passed = 1'b1; // Initialize before use
            for (c = 0; c < N_COLS_TB; c = c + 1) begin 
                for (r = 0; r < M_ROWS_TB; r = r + 1) begin 
                    if (output_matrix_transposed_dut[c][r] !== expected_transposed_matrix[c][r]) begin
                        $error("[%0t TB] Test Case 1 FAILED at Output_T[%0d][%0d]. Expected: %d, Got: %d",
                               $time, c, r, expected_transposed_matrix[c][r], output_matrix_transposed_dut[c][r]);
                        test_passed = 1'b0;
                    end
                end
            end
            if (test_passed) begin
                $display("[%0t TB] Test Case 1 PASSED.", $time);
            end else begin
                $display("[%0t TB] Test Case 1 FAILED overall.", $time);
            end
        end

        #(CLK_PERIOD * 5); 

        $display("[%0t TB] Matrix Transpose Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
