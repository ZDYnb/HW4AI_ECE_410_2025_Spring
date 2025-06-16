// tb_vector_matrix_multiply_row_unit.v (Corrected ALL begin/end for if-else blocks)
`timescale 1ns / 1ps

module tb_vector_matrix_multiply_row_unit;

    // Testbench Parameters
    localparam DATA_WIDTH   = 8;
    localparam ACCUM_WIDTH  = 32;
    localparam K_DIM_TB     = 2; 
    localparam N_DIM_TB     = 2; 
    localparam CLK_PERIOD   = 10;

    // Testbench specific parameters
    localparam TEST_VEC_MAX_LEN = 16;

    // DUT Interface Signals
    reg                               clk;
    reg                               rst_n;
    reg                               op_start_tb;
    reg signed [DATA_WIDTH-1:0]       input_vector_A_tb [0:K_DIM_TB-1];
    reg signed [DATA_WIDTH-1:0]       weight_matrix_W_tb [0:K_DIM_TB-1][0:N_DIM_TB-1];

    wire signed [ACCUM_WIDTH-1:0]     output_vector_O_dut [0:N_DIM_TB-1];
    wire                              op_busy_dut;
    wire                              op_done_dut;

    // Instantiate the DUT
    vector_matrix_multiply_row_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .K_DIM(K_DIM_TB),
        .N_DIM(N_DIM_TB)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .op_start(op_start_tb),
        .input_vector_A(input_vector_A_tb),
        .weight_matrix_W(weight_matrix_W_tb),
        .output_vector_O(output_vector_O_dut),
        .op_busy(op_busy_dut),
        .op_done(op_done_dut)
    );

    // Clock generation
    always # (CLK_PERIOD/2) clk = ~clk;
    
    // Test sequence
    initial begin
        // ALL LOCAL VARIABLE DECLARATIONS MUST BE AT THE TOP OF THE BLOCK
        integer i, j; // For loops
        reg signed [ACCUM_WIDTH-1:0] expected_O [0:N_DIM_TB-1];
        integer timeout_counter;
        integer max_timeout_cycles;
        logic test_passed_current_tc; // General flag for current test case

        // Now, procedural statements and assignments
        clk = 1'b0;
        rst_n = 1'b0;
        op_start_tb = 1'b0;
        
        for (i = 0; i < K_DIM_TB; i = i + 1) begin
            input_vector_A_tb[i] = 0;
        end
        for (i = 0; i < K_DIM_TB; i = i + 1) begin
            for (j = 0; j < N_DIM_TB; j = j + 1) begin
                weight_matrix_W_tb[i][j] = 0;
            end
        end

        $display("[%0t TB] Starting Vector-Matrix Multiply Row Unit Testbench...", $time);

        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1: K_DIM=2, N_DIM=2 ---
        $display("[%0t TB] === Test Case 1: K=%0d, N=%0d ===", $time, K_DIM_TB, N_DIM_TB);

        input_vector_A_tb[0] = 1;
        input_vector_A_tb[1] = 2;

        weight_matrix_W_tb[0][0] = 3; weight_matrix_W_tb[0][1] = 4;
        weight_matrix_W_tb[1][0] = 5; weight_matrix_W_tb[1][1] = 6;

        expected_O[0] = 13; // 1*3 + 2*5
        expected_O[1] = 16; // 1*4 + 2*6

        op_start_tb = 1'b0; 
        @(posedge clk); 
        op_start_tb = 1'b1; 
        @(posedge clk);     
        op_start_tb = 1'b0; 
        $display("[%0t TB] op_start pulse sent for TC1.", $time);
        
        timeout_counter = 0;
        max_timeout_cycles = (K_DIM_TB * N_DIM_TB * 15) + 50; // Increased timeout slightly

        if(!op_busy_dut) @(posedge clk); // Wait a cycle if not immediately busy

        if (!op_busy_dut) begin
             $error("[%0t TB] TC1 Error: DUT did not become busy after start!", $time);
        end else begin
             $display("[%0t TB] DUT is busy for TC1, proceeding.", $time);
        end
        
        while (!op_done_dut && op_busy_dut && timeout_counter < max_timeout_cycles) begin
            @(posedge clk);
            timeout_counter = timeout_counter + 1;
        end

        if (timeout_counter >= max_timeout_cycles) begin
            $error("[%0t TB] Test Case 1 TIMEOUT: op_done was not asserted.", $time);
        end else if (!op_done_dut && !op_busy_dut) begin // CORRECTED: begin/end
            $error("[%0t TB] Test Case 1 ERROR: DUT became not busy but op_done was not asserted.", $time);
        end else if (op_done_dut) begin // CORRECTED: begin/end
            $display("[%0t TB] op_done received for TC1 at time %0t. op_busy is %b.", $time, $time, op_busy_dut);
            
            test_passed_current_tc = 1'b1;
            for (j = 0; j < N_DIM_TB; j = j + 1) begin 
                if (output_vector_O_dut[j] !== expected_O[j]) begin
                    $error("[%0t TB] Test Case 1 FAILED at O[%0d]. Expected: %d, Got: %d",
                           $time, j, expected_O[j], output_vector_O_dut[j]);
                    test_passed_current_tc = 1'b0;
                end
            end
            if (test_passed_current_tc) begin
                $display("[%0t TB] Test Case 1 PASSED.", $time);
            end
        end // End of 'else if (op_done_dut)'
        // No final 'else' here as these conditions should cover the valid end states or timeout


        #(CLK_PERIOD * 5); 

        // --- Add more test cases following the same pattern if desired ---
        // Make sure to reset/reinitialize input_vector_A_tb, weight_matrix_W_tb, expected_O,
        // timeout_counter for each new test case.

        $display("[%0t TB] Vector-Matrix Multiply Row Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
