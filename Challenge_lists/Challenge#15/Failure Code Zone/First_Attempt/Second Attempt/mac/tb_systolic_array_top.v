`timescale 1ns/1ps // Define time unit and precision

module tb_systolic_array_top;

    // ===========================================
    // 1. Parameter Definitions (Must match systolic_array_top module)
    // ===========================================
    parameter ARRAY_SIZE   = 4;   // Use 4x4 array for initial testing, easier to debug
    parameter DATA_WIDTH   = 16;  // Data width (S5.10 format: 1 sign bit, 5 integer, 10 fractional)
    parameter WEIGHT_WIDTH = 8;   // Weight width (S1.6 format: 1 sign bit, 1 integer, 6 fractional)
    parameter ACCUM_WIDTH  = 32;  // Accumulator width (S_ACCUM_INT.16 format: 1 sign bit, ACCUM_INT, 16 fractional)
                                  // Max expected integer bits for 64x64 array sum is 5+1+log2(64) = 12. So 32-bit (S15.16) is safe.
    parameter COUNTER_BITS = 8;   // Counter bit width, must be large enough

    localparam CLOCK_PERIOD_NS = 10; // ¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?

    // ===========================================
    // 2. Testbench Signal Declarations (reg for driving inputs, wire for receiving DUT outputs)
    // ===========================================
    reg  clk;
    reg  rst_n;
    reg  start;

    // Flattened inputs for Matrix A and B
    reg  [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0]  matrix_a_flat;
    reg  [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;

    // DUT output signals
    wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0]  result_flat;
    wire computation_done;
    wire result_valid;

    // ===========================================
    // Testbench internal status flags for verification
    // ===========================================
    reg tb_comp_done_flag;   // Flag to capture computation_done pulse
    reg tb_result_valid_flag; // Flag to capture result_valid pulse

    // ===========================================
    // 3. Instantiate Your Design Under Test (DUT)
    // ===========================================
    systolic_array_top #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .COUNTER_BITS(COUNTER_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .result_flat(result_flat),
        .computation_done(computation_done),
        .result_valid(result_valid)
    );

    // ===========================================
    // 4. Clock Generation Logic
    // ===========================================
    initial begin
        clk = 0; // Initialize clock to low
        forever #(CLOCK_PERIOD_NS / 2) clk = ~clk; // Toggle every CLOCK_PERIOD_NS/2, period is CLOCK_PERIOD_NS
    end

    // ===========================================
    // 5. Software Reference Model for Verification (for small ARRAY_SIZE)
    // ===========================================
    // Function to convert signed integer to S_X.Y fixed-point representation
    // Assuming 2's complement. total_bits = 1 (sign) + int_bits + frac_bits
    function automatic [total_bits-1:0] float_to_fixed;
        input real float_val;
        input integer total_bits;
        input integer frac_bits;
        begin
            float_to_fixed = $rtoi(float_val * (1 << frac_bits));
            // Handle overflow/underflow if necessary, for simplicity, assuming values fit.
            // For negative numbers, ensure proper 2's complement truncation/representation.
        end
    endfunction

    // Function to convert S_X.Y fixed-point representation to real
    function automatic real fixed_to_float;
        input [total_bits-1:0] fixed_val;
        input integer total_bits;
        input integer frac_bits;
        begin
            // Handle signed conversion
            if (fixed_val[total_bits-1] == 1) begin // Negative number
                fixed_to_float = ($signed(fixed_val) / (1 << frac_bits));
            end else begin // Positive number
                fixed_to_float = (fixed_val / (1 << frac_bits));
            end
        end
    endfunction

    // Function to compute expected result C = A * B
    // Outputs a flattened array of ACCUM_WIDTH elements.
    function automatic [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] compute_expected_result;
        input [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] a_flat;
        input [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] b_flat;
        
        real a_real[ARRAY_SIZE][ARRAY_SIZE];
        real b_real[ARRAY_SIZE][ARRAY_SIZE];
        real c_real[ARRAY_SIZE][ARRAY_SIZE];
        
        integer r_a, c_a, r_b, c_b, k_dot;
        reg [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] c_flat_out;
        
        // Unflatten A_flat and B_flat into real matrices
        for (r_a = 0; r_a < ARRAY_SIZE; r_a = r_a + 1) begin
            for (c_a = 0; c_a < ARRAY_SIZE; c_a = c_a + 1) begin
                // Extract DATA_WIDTH bits for matrix A
                a_real[r_a][c_a] = fixed_to_float(a_flat[(r_a*ARRAY_SIZE + c_a + 1)*DATA_WIDTH - 1 : (r_a*ARRAY_SIZE + c_a)*DATA_WIDTH], DATA_WIDTH, 10); // S5.10 (10 frac bits)
            end
        end
        
        for (r_b = 0; r_b < ARRAY_SIZE; r_b = r_b + 1) begin
            for (c_b = 0; c_b < ARRAY_SIZE; c_b = c_b + 1) begin
                // Extract WEIGHT_WIDTH bits for matrix B
                b_real[r_b][c_b] = fixed_to_float(b_flat[(r_b*ARRAY_SIZE + c_b + 1)*WEIGHT_WIDTH - 1 : (r_b*ARRAY_SIZE + c_b)*WEIGHT_WIDTH], WEIGHT_WIDTH, 6); // S1.6 (6 frac bits)
            end
        end
        
        // Perform matrix multiplication C = A * B (in real numbers)
        for (r_a = 0; r_a < ARRAY_SIZE; r_a = r_a + 1) begin // row of C
            for (c_b = 0; c_b < ARRAY_SIZE; c_b = c_b + 1) begin // col of C
                c_real[r_a][c_b] = 0.0;
                for (k_dot = 0; k_dot < ARRAY_SIZE; k_dot = k_dot + 1) begin // dot product index
                    c_real[r_a][c_b] = c_real[r_a][c_b] + (a_real[r_a][k_dot] * b_real[k_dot][c_b]);
                end
            end
        end

        // Flatten C_real back to fixed-point for comparison
        c_flat_out = {ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE{1'b0}}; // Initialize
        for (r_a = 0; r_a < ARRAY_SIZE; r_a = r_a + 1) begin
            for (c_b = 0; c_b < ARRAY_SIZE; c_b = c_b + 1) begin
                // Truncate/quantize to ACCUM_WIDTH fixed-point format (S_X.16)
                // For simplicity, assuming the fractional part is always 16 bits in the accumulator
                c_flat_out[(r_a*ARRAY_SIZE + c_b + 1)*ACCUM_WIDTH - 1 : (r_a*ARRAY_SIZE + c_b)*ACCUM_WIDTH] =
                    float_to_fixed(c_real[r_a][c_b], ACCUM_WIDTH, 16); // ACCUM_WIDTH, 16 frac bits
            end
        end
        compute_expected_result = c_flat_out;
    endfunction

    // ===========================================
    // 6. Test Sequence (Stimulus and Output Checking)
    // ===========================================
    initial begin
        // --- Calculate timeout values ---
        // Total computation cycles = (3 * ARRAY_SIZE - 2) clock cycles
        localparam EXPECTED_COMPUTATION_CYCLES = 3 * ARRAY_SIZE - 2;
        localparam TIMEOUT_FOR_COMPLETION_NS = (EXPECTED_COMPUTATION_CYCLES + 50) * CLOCK_PERIOD_NS;

        $display("------------------------------------------------------------------");
        $display(" %0t: Testbench Simulation Started. ARRAY_SIZE = %0d", $time, ARRAY_SIZE);
        $display("     Expected computation cycles: %0d", EXPECTED_COMPUTATION_CYCLES);
        $display("     Timeout for completion: %0d ns", TIMEOUT_FOR_COMPLETION_NS);
        $display("------------------------------------------------------------------");


        // Initialize all input signals
        rst_n = 0; // Assert reset (active low)
        start = 0; // Deassert start signal
        matrix_a_flat = {DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE{1'b0}};
        matrix_b_flat = {WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE{1'b0}};

        #10; // Initial delay to see reset signal
        $display(" %0t: Asserting Reset (rst_n = %b)", $time, rst_n);
        
        #(CLOCK_PERIOD_NS * 5); // Hold reset for 5 clock cycles
        rst_n = 1; // Deassert reset
        $display(" %0t: Deasserting Reset (rst_n = %b)", $time, rst_n);
        
        #(CLOCK_PERIOD_NS * 2); // Wait a couple of cycles for DUT to enter IDLE

        // ----------------------------------------------------
        // Define Test Matrices A and B (4x4 example)
        // Values represented as decimal integers. The `float_to_fixed` function
        // will convert them to their respective S5.10 and S1.6 fixed-point binary.
        // Example: 1.0 (real) -> S5.10 (16-bit) -> 16'h00400 (decimal 1024)
        // 0.5 (real) -> S5.10 (16-bit) -> 16'h00200 (decimal 512)
        // You can change these real values to verify different scenarios.
        // ----------------------------------------------------
        // Define A_real and B_real using real numbers for clarity
        real a_vals_real[ARRAY_SIZE][ARRAY_SIZE];
        real b_vals_real[ARRAY_SIZE][ARRAY_SIZE];

        // Example: Simple Identity-like matrix for A (using 1.0)
        // [[1.0, 0.0, 0.0, 0.0],
        //  [0.0, 1.0, 0.0, 0.0],
        //  [0.0, 0.0, 1.0, 0.0],
        //  [0.0, 0.0, 0.0, 1.0]]
        a_vals_real[0][0]=1.0; a_vals_real[0][1]=0.0; a_vals_real[0][2]=0.0; a_vals_real[0][3]=0.0;
        a_vals_real[1][0]=0.0; a_vals_real[1][1]=1.0; a_vals_real[1][2]=0.0; a_vals_real[1][3]=0.0;
        a_vals_real[2][0]=0.0; a_vals_real[2][1]=0.0; a_vals_real[2][2]=1.0; a_vals_real[2][3]=0.0;
        a_vals_real[3][0]=0.0; a_vals_real[3][1]=0.0; a_vals_real[3][2]=0.0; a_vals_real[3][3]=1.0;

        // Example: Simple matrix for B (using 2.0)
        // [[2.0, 2.0, 2.0, 2.0],
        //  [2.0, 2.0, 2.0, 2.0],
        //  [2.0, 2.0, 2.0, 2.0],
        //  [2.0, 2.0, 2.0, 2.0]]
        b_vals_real[0][0]=2.0; b_vals_real[0][1]=2.0; b_vals_real[0][2]=2.0; b_vals_real[0][3]=2.0;
        b_vals_real[1][0]=2.0; b_vals_real[1][1]=2.0; b_vals_real[1][2]=2.0; b_vals_real[1][3]=2.0;
        b_vals_real[2][0]=2.0; b_vals_real[2][1]=2.0; b_vals_real[2][2]=2.0; b_vals_real[2][3]=2.0;
        b_vals_real[3][0]=2.0; b_vals_real[3][1]=2.0; b_vals_real[3][2]=2.0; b_vals_real[3][3]=2.0;

        // Flatten A_real and B_real into fixed-point binary
        for (integer r = 0; r < ARRAY_SIZE; r = r + 1) begin
            for (integer c = 0; c < ARRAY_SIZE; c = c + 1) begin
                matrix_a_flat[(r*ARRAY_SIZE + c + 1)*DATA_WIDTH - 1 : (r*ARRAY_SIZE + c)*DATA_WIDTH] =
                    float_to_fixed(a_vals_real[r][c], DATA_WIDTH, 10);
                matrix_b_flat[(r*ARRAY_SIZE + c + 1)*WEIGHT_WIDTH - 1 : (r*ARRAY_SIZE + c)*WEIGHT_WIDTH] =
                    float_to_fixed(b_vals_real[r][c], WEIGHT_WIDTH, 6);
            end
        end

        #(CLOCK_PERIOD_NS); // Ensure input data is stable

        $display("------------------------------------");
        $display(" %0t: Asserting START signal. Matrix A and B loaded.", $time);
        $display("     Matrix A (real values):");
        for (integer r = 0; r < ARRAY_SIZE; r = r + 1) begin
            $write("       [ ");
            for (integer c = 0; c < ARRAY_SIZE; c = c + 1) begin
                $write("%f ", a_vals_real[r][c]);
            end
            $display("]");
        end
        $display("     Matrix B (real values):");
        for (integer r = 0; r < ARRAY_SIZE; r = r + 1) begin
            $write("       [ ");
            for (integer c = 0; c < ARRAY_SIZE; c = c + 1) begin
                $write("%f ", b_vals_real[r][c]);
            end
            $display("]");
        end
        $display("------------------------------------");
        start = 1; // Assert start signal
        
        // ----------------------------------------------------
        // Wait for computation to complete OR timeout
        // ----------------------------------------------------
        fork : completion_fork
            begin : wait_done_block
                @(posedge clk iff dut.computation_done); // Wait for DUT's done signal
                $display(" %0t: DUT's computation_done went HIGH! (Capturing pulse)", $time);
                tb_comp_done_flag = 1; // Set flag to 1
                tb_result_valid_flag = dut.result_valid; // Capture result_valid too
            end
            begin : wait_timeout_block
                #(TIMEOUT_FOR_COMPLETION_NS); // Timeout
                $display(" %0t: Testbench TIMEOUT reached! (DUT might be stuck)", $time);
                tb_comp_done_flag = 0; // Ensure flags are 0 if timeout occurred
                tb_result_valid_flag = 0;
            end
        join_any

        // Now deassert START *AFTER* the fork-join_any completes and you've captured the pulse
        start = 0; 
        
        // Check if simulation ended due to timeout or actual completion
        if (!tb_comp_done_flag) begin // Check the captured flag, not the live signal
            $display("--------------------------------------------------");
            $display(" %0t: WARNING: DUT did NOT complete within expected time! ", $time);
            $display("              FSM might be stuck or computation cycles are miscalculated.", $time);
            $display("--------------------------------------------------");
        end else begin
            $display("------------------------------------");
            $display(" %0t: DUT computation completed successfully!", $time);
            $display("------------------------------------");
        end
        
        #(CLOCK_PERIOD_NS * 2); // Wait a couple of cycles for outputs to settle. DUT will likely be in IDLE now.

        // ----------------------------------------------------
        // Final Result Output and Automatic Verification
        // ----------------------------------------------------
        $display("--------------------------------------------------");
        $display(" %0t: Final Results Check:", $time);
        $display("     Computation done signal (CAPTURED): %b", tb_comp_done_flag); 
        $display("     Result valid signal (CAPTURED): %b", tb_result_valid_flag); 
        $display("     (Live DUT signals at check time: Done = %b, Valid = %b)", dut.computation_done, dut.result_valid);
        $display(" ");

        // Calculate expected result using the software reference model
        reg [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] expected_result_flat;
        expected_result_flat = compute_expected_result(matrix_a_flat, matrix_b_flat);

        $display("     DUT Result (flat): %H", result_flat);
        $display("     Expected Result (flat): %H", expected_result_flat);

        // Display results in 2D matrix format for better readability
        $display("     DUT Result Matrix (fixed-point as real):");
        for (integer r = 0; r < ARRAY_SIZE; r = r + 1) begin
            $write("       [ ");
            for (integer c = 0; c < ARRAY_SIZE; c = c + 1) begin
                real val_real = fixed_to_float(result_flat[(r*ARRAY_SIZE + c + 1)*ACCUM_WIDTH - 1 : (r*ARRAY_SIZE + c)*ACCUM_WIDTH], ACCUM_WIDTH, 16);
                $write("%f ", val_real);
            end
            $display("]");
        end

        $display("     Expected Result Matrix (real):");
        real expected_c_real[ARRAY_SIZE][ARRAY_SIZE];
        for (integer r_a = 0; r_a < ARRAY_SIZE; r_a = r_a + 1) begin // row of C
            for (integer c_b = 0; c_b < ARRAY_SIZE; c_b = c_b + 1) begin // col of C
                expected_c_real[r_a][c_b] = 0.0;
                for (integer k_dot = 0; k_dot < ARRAY_SIZE; k_dot = k_dot + 1) begin // dot product index
                    real a_val = fixed_to_float(matrix_a_flat[(r_a*ARRAY_SIZE + k_dot + 1)*DATA_WIDTH - 1 : (r_a*ARRAY_SIZE + k_dot)*DATA_WIDTH], DATA_WIDTH, 10);
                    real b_val = fixed_to_float(matrix_b_flat[(k_dot*ARRAY_SIZE + c_b + 1)*WEIGHT_WIDTH - 1 : (k_dot*ARRAY_SIZE + c_b)*WEIGHT_WIDTH], WEIGHT_WIDTH, 6);
                    expected_c_real[r_a][c_b] = expected_c_real[r_a][c_b] + (a_val * b_val);
                end
            end
        end

        for (integer r = 0; r < ARRAY_SIZE; r = r + 1) begin
            $write("       [ ");
            for (integer c = 0; c < ARRAY_SIZE; c = c + 1) begin
                $write("%f ", expected_c_real[r][c]);
            end
            $display("]");
        end


        // Automatic Result Comparison
        if (tb_comp_done_flag && tb_result_valid_flag && (result_flat === expected_result_flat)) begin
            $display(" ");
            $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            $display(" >>>              TEST PASSED!                <<< ");
            $display(" <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            $display(" ");
        end else begin
            $display(" ");
            $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            $display(" >>>              TEST FAILED!                <<< ");
            $display(" <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            $display("     Reason: ");
            if (!tb_comp_done_flag || !tb_result_valid_flag) $display("       - DUT did not complete computation.");
            if (!(result_flat === expected_result_flat)) $display("       - Calculated result does not match expected result.");
            $display(" ");
        end
        $display("--------------------------------------------------");


        #(CLOCK_PERIOD_NS * 10); // Extra wait time before ending simulation
        $finish; // End simulation
    end

    // ===========================================
    // 7. Enhanced Debugging - FSM State and Counter Tracing
    // ===========================================
    always @(posedge clk) begin
        static reg [1:0] prev_state = 2'bxx; // Store previous state
        static reg [COUNTER_BITS-1:0] prev_counter = {COUNTER_BITS{1'bx}}; // Store previous counter

        if (dut.current_state !== prev_state || dut.cycle_counter !== prev_counter) begin
            $display(" %0t: DEBUG FSM: State = %s, Cycle Counter = %0d",
                     $time,
                     (dut.current_state == dut.IDLE) ? "IDLE" :
                     (dut.current_state == dut.FEED_COMPUTE) ? "FEED_COMPUTE" :
                     (dut.current_state == dut.DRAIN_RESULTS) ? "DRAIN_RESULTS" :
                     (dut.current_state == dut.DONE_STATE) ? "DONE_STATE" : "UNKNOWN",
                     dut.cycle_counter);
            prev_state = dut.current_state;
            prev_counter = dut.cycle_counter;
        end
        
        // Optionally, print data being fed in FEED_COMPUTE state (less frequently to avoid flood)
        if (dut.current_state == dut.FEED_COMPUTE && dut.cycle_counter % 2 == 0 && dut.cycle_counter <= (2*ARRAY_SIZE - 2)) begin
            $display(" %0t: DEBUG FEED: Cycle %0d, A[0][col=%0d]=%H (%f), B[row=%0d][0]=%H (%f), Valid A[0]=%b, Valid B[0]=%b",
                     $time, dut.cycle_counter,
                     dut.cycle_counter, dut.data_in[0], fixed_to_float(dut.data_in[0], DATA_WIDTH, 10),
                     dut.cycle_counter, dut.weight_in[0], fixed_to_float(dut.weight_in[0], WEIGHT_WIDTH, 6),
                     dut.data_valid[0], dut.weight_valid[0]);
        end
    end

    // ===========================================
    // 8. Waveform File Generation (Highly Recommended for Debugging)
    // ===========================================
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_systolic_array_top); 
        $display(" %0t: Waveform dumping enabled to waveform.vcd", $time);
    end

endmodule
