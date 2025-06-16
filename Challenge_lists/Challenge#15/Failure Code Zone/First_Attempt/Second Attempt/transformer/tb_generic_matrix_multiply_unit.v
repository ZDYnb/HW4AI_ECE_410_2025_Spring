// tb_generic_matrix_multiply_unit.v
`timescale 1ns / 1ps

module tb_generic_matrix_multiply_unit;

    // Testbench Parameters
    localparam DATA_WIDTH   = 8;
    localparam ACCUM_WIDTH  = 32;
    localparam M_DIM_TB     = 2; // Rows in Matrix A / Output Matrix C
    localparam K_DIM_TB     = 3; // Cols in Matrix A / Rows in Matrix B
    localparam N_DIM_TB     = 2; // Cols in Matrix B / Output Matrix C
    localparam CLK_PERIOD   = 10;  // 10ns => 100 MHz

    // DUT Interface Signals
    reg                               clk_tb;
    reg                               rst_n_tb;
    reg                               op_start_mm_tb;

    reg signed [DATA_WIDTH-1:0]       matrix_a_tb [0:M_DIM_TB-1][0:K_DIM_TB-1];
    reg signed [DATA_WIDTH-1:0]       matrix_b_tb [0:K_DIM_TB-1][0:N_DIM_TB-1];

    wire signed [ACCUM_WIDTH-1:0]     output_matrix_c_dut [0:M_DIM_TB-1][0:N_DIM_TB-1];
    wire                              op_busy_mm_dut;
    wire                              op_done_mm_dut;

    // Instantiate the DUT
    generic_matrix_multiply_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .M_DIM(M_DIM_TB),
        .K_DIM(K_DIM_TB),
        .N_DIM(N_DIM_TB)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .op_start_mm(op_start_mm_tb),
        .matrix_a_in(matrix_a_tb),
        .matrix_b_in(matrix_b_tb),
        .output_matrix_c_out(output_matrix_c_dut),
        .op_busy_mm(op_busy_mm_dut),
        .op_done_mm(op_done_mm_dut)
    );

    // Clock generation
    always # (CLK_PERIOD/2) clk_tb = ~clk_tb;

    // Test sequence
    initial begin
        // Local variables for testbench calculations
        integer m, k, n; // Loop variables
        reg signed [ACCUM_WIDTH-1:0] expected_output_c [0:M_DIM_TB-1][0:N_DIM_TB-1];
        reg signed [ACCUM_WIDTH-1:0] temp_sum;
        integer timeout_counter;
        integer max_timeout_cycles;
        logic test_passed;

        // Initialize signals
        clk_tb = 1'b0;
        rst_n_tb = 1'b0;
        op_start_mm_tb = 1'b0;
        
        // Initialize input matrices to 0 (optional, good practice)
        for (m = 0; m < M_DIM_TB; m = m + 1) begin
            for (k = 0; k < K_DIM_TB; k = k + 1) begin
                matrix_a_tb[m][k] = 0;
            end
        end
        for (k = 0; k < K_DIM_TB; k = k + 1) begin
            for (n = 0; n < N_DIM_TB; n = n + 1) begin
                matrix_b_tb[k][n] = 0;
            end
        end

        $display("[%0t TB] Starting Generic Matrix Multiply Unit Testbench...", $time);

        // Reset sequence
        #(CLK_PERIOD * 2);
        rst_n_tb = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1: M=2, K=3, N=2 ---
        $display("[%0t TB] === Test Case 1: M=%0d, K=%0d, N=%0d ===", $time, M_DIM_TB, K_DIM_TB, N_DIM_TB);

        // Define input Matrix A (2x3)
        // A = [[1, 2, 3],
        //      [4, 5, 6]]
        matrix_a_tb[0][0] = 1; matrix_a_tb[0][1] = 2; matrix_a_tb[0][2] = 3;
        matrix_a_tb[1][0] = 4; matrix_a_tb[1][1] = 5; matrix_a_tb[1][2] = 6;

        // Define input Matrix B (3x2)
        // B = [[7, 8],
        //      [9, 1],
        //      [2, 3]]
        matrix_b_tb[0][0] = 7; matrix_b_tb[0][1] = 8;
        matrix_b_tb[1][0] = 9; matrix_b_tb[1][1] = 1;
        matrix_b_tb[2][0] = 2; matrix_b_tb[2][1] = 3;

        // Calculate Expected Output C = A * B (2x2)
        // C[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0] + A[0][2]*B[2][0]
        //         = 1*7 + 2*9 + 3*2 = 7 + 18 + 6 = 31
        // C[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1] + A[0][2]*B[2][1]
        //         = 1*8 + 2*1 + 3*3 = 8 + 2 + 9 = 19
        // C[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0] + A[1][2]*B[2][0]
        //         = 4*7 + 5*9 + 6*2 = 28 + 45 + 12 = 85
        // C[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1] + A[1][2]*B[2][1]
        //         = 4*8 + 5*1 + 6*3 = 32 + 5 + 18 = 55
        // Expected C = [[31, 19],
        //               [85, 55]]
        for (m = 0; m < M_DIM_TB; m = m + 1) begin
            for (n = 0; n < N_DIM_TB; n = n + 1) begin
                temp_sum = 0;
                for (k = 0; k < K_DIM_TB; k = k + 1) begin
                    temp_sum = temp_sum + matrix_a_tb[m][k] * matrix_b_tb[k][n];
                end
                expected_output_c[m][n] = temp_sum;
            end
        end
        $display("[%0t TB] Expected C[0]=[%0d, %0d], C[1]=[%0d, %0d]", $time,
                 expected_output_c[0][0], expected_output_c[0][1],
                 expected_output_c[1][0], expected_output_c[1][1]);

        // Start the operation
        op_start_mm_tb = 1'b0; 
        @(posedge clk_tb);
        op_start_mm_tb = 1'b1; 
        @(posedge clk_tb);     
        op_start_mm_tb = 1'b0; 
        $display("[%0t TB] op_start_mm pulse sent.", $time);
        
        timeout_counter = 0;
        // Rough estimate: M_DIM * (VMM_overhead + N_DIM * (DP_overhead + K_DIM * DP_element_cycles))
        max_timeout_cycles = M_DIM_TB * (20 + N_DIM_TB * (20 + K_DIM_TB * 7)) + 200; 

        if(!op_busy_mm_dut) @(posedge clk_tb); 
        if(!op_busy_mm_dut) $error("[%0t TB] DUT did not become busy!", $time);
        else $display("[%0t TB] DUT is busy, waiting for completion...", $time);

        while (!op_done_mm_dut && op_busy_mm_dut && timeout_counter < max_timeout_cycles) begin
            @(posedge clk_tb);
            timeout_counter = timeout_counter + 1;
        end

        if (timeout_counter >= max_timeout_cycles) begin
            $error("[%0t TB] Test Case 1 TIMEOUT: op_done_mm_dut was not asserted.", $time);
        end else if (!op_done_mm_dut && !op_busy_mm_dut) begin
            $error("[%0t TB] Test Case 1 ERROR: DUT became not busy but op_done_mm_dut was not asserted.", $time);
        end else if (op_done_mm_dut) begin 
            @(posedge clk_tb); // Wait one more cycle for registered output_matrix_c_dut to be stable
            $display("[%0t TB] op_done_mm_dut received. op_busy_mm_dut is %b.", $time, op_busy_mm_dut);
            
            test_passed = 1'b1; 
            for (m = 0; m < M_DIM_TB; m = m + 1) begin
                for (n = 0; n < N_DIM_TB; n = n + 1) begin
                    if (output_matrix_c_dut[m][n] !== expected_output_c[m][n]) begin
                        $error("[%0t TB] Test Case 1 FAILED at C[%0d][%0d]. Expected: %d, Got: %d",
                               $time, m, n, expected_output_c[m][n], output_matrix_c_dut[m][n]);
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

        $display("[%0t TB] Generic Matrix Multiply Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
