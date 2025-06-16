

// tb_qkv_projection_unit.v
`timescale 1ns / 1ps

module tb_qkv_projection_unit;

    // Testbench Parameters
    localparam DATA_WIDTH   = 8;
    localparam ACCUM_WIDTH  = 16; // For bias and Q, K, V outputs
    localparam D_MODEL_TB   = 3;
    localparam D_K_TB       = 2;
    localparam D_V_TB       = 2; 
    localparam CLK_PERIOD   = 10;

    // DUT Interface Signals
    reg                               clk_tb;
    reg                               rst_n_tb;
    reg                               op_start_qkv_tb;

    reg signed [DATA_WIDTH-1:0]       input_x_vector_tb [0:D_MODEL_TB-1];
    reg signed [DATA_WIDTH-1:0]       Wq_matrix_tb [0:D_MODEL_TB-1][0:D_K_TB-1];
    reg signed [DATA_WIDTH-1:0]       Wk_matrix_tb [0:D_MODEL_TB-1][0:D_K_TB-1];
    reg signed [DATA_WIDTH-1:0]       Wv_matrix_tb [0:D_MODEL_TB-1][0:D_V_TB-1];
    reg signed [ACCUM_WIDTH-1:0]      bq_vector_tb [0:D_K_TB-1];
    reg signed [ACCUM_WIDTH-1:0]      bk_vector_tb [0:D_K_TB-1];
    reg signed [ACCUM_WIDTH-1:0]      bv_vector_tb [0:D_V_TB-1];

    wire signed [ACCUM_WIDTH-1:0]     q_vector_out_dut [0:D_K_TB-1];
    wire signed [ACCUM_WIDTH-1:0]     k_vector_out_dut [0:D_K_TB-1];
    wire signed [ACCUM_WIDTH-1:0]     v_vector_out_dut [0:D_V_TB-1];
    wire                              op_busy_qkv_dut;
    wire                              op_done_qkv_dut;

    // Instantiate the DUT
    qkv_projection_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .D_MODEL(D_MODEL_TB),
        .D_K(D_K_TB),
        .D_V(D_V_TB)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .op_start_qkv(op_start_qkv_tb),
        .input_x_vector(input_x_vector_tb),
        .Wq_matrix(Wq_matrix_tb),
        .Wk_matrix(Wk_matrix_tb),
        .Wv_matrix(Wv_matrix_tb),
        .bq_vector(bq_vector_tb),
        .bk_vector(bk_vector_tb),
        .bv_vector(bv_vector_tb),
        .q_vector_out(q_vector_out_dut),
        .k_vector_out(k_vector_out_dut),
        .v_vector_out(v_vector_out_dut),
        .op_busy_qkv(op_busy_qkv_dut),
        .op_done_qkv(op_done_qkv_dut)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    // Test sequence
    initial begin
        integer i, k_idx, n_idx; // Loop variables (k_idx for D_MODEL, n_idx for D_K/D_V)
        reg signed [ACCUM_WIDTH-1:0] expected_q_vector [0:D_K_TB-1];
        reg signed [ACCUM_WIDTH-1:0] expected_k_vector [0:D_K_TB-1];
        reg signed [ACCUM_WIDTH-1:0] expected_v_vector [0:D_V_TB-1];
        reg signed [ACCUM_WIDTH-1:0] temp_sum;
        integer timeout_counter;
        integer max_timeout_cycles;
        logic test_passed;

        // Initialize signals
        clk_tb = 1'b0;
        rst_n_tb = 1'b0;
        op_start_qkv_tb = 1'b0;
        
        // Initialize inputs to 0 (optional)
        for (i = 0; i < D_MODEL_TB; i = i + 1) input_x_vector_tb[i] = 0;
        // ... (initialize Wq, Wk, Wv, bq, bk, bv to 0 if desired) ...

        $display("[%0t TB] Starting QKV Projection Unit Testbench...", $time);

        #(CLK_PERIOD * 2);
        rst_n_tb = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1 ---
        $display("[%0t TB] === Test Case 1: D_MODEL=%0d, D_K=%0d, D_V=%0d ===", $time, D_MODEL_TB, D_K_TB, D_V_TB);

        // Define input data
        input_x_vector_tb[0] = 1; input_x_vector_tb[1] = 2; input_x_vector_tb[2] = 3;

        Wq_matrix_tb[0][0] = 1; Wq_matrix_tb[0][1] = 2;
        Wq_matrix_tb[1][0] = 3; Wq_matrix_tb[1][1] = 1;
        Wq_matrix_tb[2][0] = 2; Wq_matrix_tb[2][1] = 3;
        bq_vector_tb[0] = 1; bq_vector_tb[1] = 1;

        Wk_matrix_tb[0][0] = 2; Wk_matrix_tb[0][1] = 1;
        Wk_matrix_tb[1][0] = 1; Wk_matrix_tb[1][1] = 3;
        Wk_matrix_tb[2][0] = 3; Wk_matrix_tb[2][1] = 2;
        bk_vector_tb[0] = 2; bk_vector_tb[1] = 2;

        Wv_matrix_tb[0][0] = 1; Wv_matrix_tb[0][1] = 3;
        Wv_matrix_tb[1][0] = 2; Wv_matrix_tb[1][1] = 2;
        Wv_matrix_tb[2][0] = 3; Wv_matrix_tb[2][1] = 1;
        bv_vector_tb[0] = 3; bv_vector_tb[1] = 3;

        // Calculate Expected Q
        for (n_idx = 0; n_idx < D_K_TB; n_idx = n_idx + 1) begin
            temp_sum = 0;
            for (k_idx = 0; k_idx < D_MODEL_TB; k_idx = k_idx + 1) begin
                temp_sum = temp_sum + input_x_vector_tb[k_idx] * Wq_matrix_tb[k_idx][n_idx];
            end
            expected_q_vector[n_idx] = temp_sum + bq_vector_tb[n_idx];
        end
        $display("[%0t TB] Expected Q: [%0d, %0d]", $time, expected_q_vector[0], expected_q_vector[1]);

        // Calculate Expected K
        for (n_idx = 0; n_idx < D_K_TB; n_idx = n_idx + 1) begin
            temp_sum = 0;
            for (k_idx = 0; k_idx < D_MODEL_TB; k_idx = k_idx + 1) begin
                temp_sum = temp_sum + input_x_vector_tb[k_idx] * Wk_matrix_tb[k_idx][n_idx];
            end
            expected_k_vector[n_idx] = temp_sum + bk_vector_tb[n_idx];
        end
        $display("[%0t TB] Expected K: [%0d, %0d]", $time, expected_k_vector[0], expected_k_vector[1]);

        // Calculate Expected V
        for (n_idx = 0; n_idx < D_V_TB; n_idx = n_idx + 1) begin
            temp_sum = 0;
            for (k_idx = 0; k_idx < D_MODEL_TB; k_idx = k_idx + 1) begin
                temp_sum = temp_sum + input_x_vector_tb[k_idx] * Wv_matrix_tb[k_idx][n_idx];
            end
            expected_v_vector[n_idx] = temp_sum + bv_vector_tb[n_idx];
        end
        $display("[%0t TB] Expected V: [%0d, %0d]", $time, expected_v_vector[0], expected_v_vector[1]);
        
        // Start the operation
        op_start_qkv_tb = 1'b0; 
        @(posedge clk_tb);
        op_start_qkv_tb = 1'b1; 
        @(posedge clk_tb);     
        op_start_qkv_tb = 1'b0; 
        $display("[%0t TB] op_start_qkv pulse sent.", $time);
        
        timeout_counter = 0;
        // Linear layer runs M_ROWS times (here M_ROWS=1)
        // VMM inside linear layer runs N_COLS times
        // DP inside VMM runs K_COLS times
        // Each DP element takes ~5 cycles (REQ, MAC, S1, S2, CAPTURE)
        // Total rough estimate: 3 * (LL_overhead + 1 * (VMM_overhead + N_COLS * (DP_overhead + K_COLS * 5)))
        max_timeout_cycles = 3 * (10 + D_K_TB * (10 + D_MODEL_TB * 7)) + 200; 

        if(!op_busy_qkv_dut) @(posedge clk_tb); 
        if(!op_busy_qkv_dut) $error("[%0t TB] DUT did not become busy!", $time);
        else $display("[%0t TB] DUT is busy, waiting for completion...", $time);

        while (!op_done_qkv_dut && op_busy_qkv_dut && timeout_counter < max_timeout_cycles) begin
            @(posedge clk_tb);
            timeout_counter = timeout_counter + 1;
        end

        if (timeout_counter >= max_timeout_cycles) begin
            $error("[%0t TB] Test Case 1 TIMEOUT: op_done_qkv_dut was not asserted.", $time);
        end else if (!op_done_qkv_dut && !op_busy_qkv_dut) begin
            $error("[%0t TB] Test Case 1 ERROR: DUT became not busy but op_done_qkv_dut was not asserted.", $time);
        end else if (op_done_qkv_dut) begin 
            @(posedge clk_tb); // Wait one more cycle for registered outputs to be stable
            $display("[%0t TB] op_done_qkv_dut received. op_busy_qkv_dut is %b.", $time, op_busy_qkv_dut);
            
            test_passed = 1'b1; 
            // Verify Q
            for (i = 0; i < D_K_TB; i = i + 1) begin
                if (q_vector_out_dut[i] !== expected_q_vector[i]) begin
                    $error("[%0t TB] Test Case 1 FAILED at Q[%0d]. Expected: %d, Got: %d",
                           $time, i, expected_q_vector[i], q_vector_out_dut[i]);
                    test_passed = 1'b0;
                end
            end
            // Verify K
            for (i = 0; i < D_K_TB; i = i + 1) begin
                if (k_vector_out_dut[i] !== expected_k_vector[i]) begin
                    $error("[%0t TB] Test Case 1 FAILED at K[%0d]. Expected: %d, Got: %d",
                           $time, i, expected_k_vector[i], k_vector_out_dut[i]);
                    test_passed = 1'b0;
                end
            end
            // Verify V
            for (i = 0; i < D_V_TB; i = i + 1) begin
                if (v_vector_out_dut[i] !== expected_v_vector[i]) begin
                    $error("[%0t TB] Test Case 1 FAILED at V[%0d]. Expected: %d, Got: %d",
                           $time, i, expected_v_vector[i], v_vector_out_dut[i]);
                    test_passed = 1'b0;
                end
            end

            if (test_passed) begin
                $display("[%0t TB] Test Case 1 PASSED.", $time);
            end else begin
                $display("[%0t TB] Test Case 1 FAILED overall.", $time);
            end
        end

        #(CLK_PERIOD * 5); 

        $display("[%0t TB] QKV Projection Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
