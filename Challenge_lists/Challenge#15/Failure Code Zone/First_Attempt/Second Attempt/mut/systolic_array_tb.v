`timescale 1ns/1ps

module systolic_array_tb;

    // ==========================================
    // Parameters - MUST MATCH DUT PARAMETERS
    // ==========================================
    parameter ARRAY_SIZE = 4; // Use a smaller size for initial testing, e.g., 4 or 8
    parameter DATA_WIDTH = 16;
    parameter WEIGHT_WIDTH = 8;
    parameter ACCUM_WIDTH = 32;

    // Fixed-point scaling parameters (from mac_unit)
    parameter DATA_FRAC = 10;
    parameter WEIGHT_FRAC = 6;
    parameter ACCUM_FRAC = 16;

    // ==========================================
    // Testbench Signals
    // ==========================================
    reg clk;
    reg rst_n;
    reg start;

    reg [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
    reg [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;

    wire done;
    wire result_valid;
    wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

    // Internal 2D arrays for testbench (for clearer handling of inputs/outputs)
    reg signed [DATA_WIDTH-1:0] A_tb [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [WEIGHT_WIDTH-1:0] B_tb [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire signed [ACCUM_WIDTH-1:0] C_dut_tb [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1]; // Result from DUT, unflattened
    reg signed [ACCUM_WIDTH-1:0] C_expected_tb [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1]; // Expected result

    // ==========================================
    // Instantiate the DUT
    // ==========================================
    systolic_array_top #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .done(done),
        .result_valid(result_valid),
        .result_flat(result_flat)
    );

    // ==========================================
    // Clock Generation
    // ==========================================
    always #5 clk = ~clk; // 10ns period, 100MHz clock

    // ==========================================
    // Unflatten result_flat from DUT for easier verification
    // ==========================================
    genvar i_unflat, j_unflat;
    generate
        for (i_unflat = 0; i_unflat < ARRAY_SIZE; i_unflat = i_unflat + 1) begin: UNFLAT_ROW
            for (j_unflat = 0; j_unflat < ARRAY_SIZE; j_unflat = j_unflat + 1) begin: UNFLAT_COL
                assign C_dut_tb[i_unflat][j_unflat] = result_flat[(i_unflat*ARRAY_SIZE+j_unflat)*ACCUM_WIDTH +: ACCUM_WIDTH];
            end
        end
    endgenerate

    // ==========================================
    // Helper task for float to fixed-point conversion
    // Tasks can have output arguments and are more flexible than functions in Verilog-2001
    // ==========================================
    task float_to_fixed;
        input real value;
        input integer frac_bits;
        input integer result_width; // The width of the output fixed-point number
        output reg signed [31:0] fixed_out; // Max 32-bit output for now. Will be assigned to specific width.
                                            // This is a common workaround for dynamic width output in Verilog-2001 tasks.
                                            // Ensure your actual widths are <= 32.

        real scaled_value;
        reg signed [31:0] temp_fixed; // Temporary storage for fixed point result

        begin
            scaled_value = value * (2.0**frac_bits);

            // Round to nearest integer (standard rounding)
            if (scaled_value >= 0) begin
                temp_fixed = $signed(scaled_value + 0.5);
            end else begin
                temp_fixed = $signed(scaled_value - 0.5);
            end

            // Handle saturation if value exceeds fixed-point range
            if (temp_fixed > ((1 << (result_width - 1)) - 1)) begin
                fixed_out = ((1 << (result_width - 1)) - 1); // Max positive value
            end else if (temp_fixed < (-(1 << (result_width - 1)))) begin
                fixed_out = (-(1 << (result_width - 1))); // Min negative value
            end else begin
                // Assign only the relevant bits for the given width
                fixed_out = temp_fixed[result_width-1:0];
            end
        end
    endtask


    // ==========================================
    // Test Sequence
    // ==========================================
        // --- ALL DECLARATIONS MUST BE HERE AT THE TOP OF THE INITIAL BLOCK ---
        integer i, j, k; // Loop variables declared as integer
        real sum_float;
        real a_val, b_val;
        integer errors;
        reg [ARRAY_SIZE-1:0] pass_flags [ARRAY_SIZE-1:0]; // 'reg' for a simple bit array
        reg signed [31:0] temp_fixed_val; // Temporary reg to hold task output
    initial begin


        clk = 1'b0;
        rst_n = 1'b0; // Assert reset
        start = 1'b0;
        matrix_a_flat = '0;
        matrix_b_flat = '0;

        // Initialize matrices A_tb and B_tb with some example fixed-point values
        // A (S5.10): Max range ~ +/- 15.99
        // B (S1.6): Max range ~ +/- 0.98

        // Example 1: Simple 4x4 matrices
        // A_tb: Mostly positive values
        float_to_fixed(1.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[0][0] = temp_fixed_val;
        float_to_fixed(2.5, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[0][1] = temp_fixed_val;
        float_to_fixed(3.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[0][2] = temp_fixed_val;
        float_to_fixed(0.5, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[0][3] = temp_fixed_val;

        float_to_fixed(4.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[1][0] = temp_fixed_val;
        float_to_fixed(5.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[1][1] = temp_fixed_val;
        float_to_fixed(1.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[1][2] = temp_fixed_val;
        float_to_fixed(2.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[1][3] = temp_fixed_val;

        float_to_fixed(0.1, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[2][0] = temp_fixed_val;
        float_to_fixed(1.2, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[2][1] = temp_fixed_val;
        float_to_fixed(3.4, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[2][2] = temp_fixed_val;
        float_to_fixed(5.6, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[2][3] = temp_fixed_val;

        float_to_fixed(7.8, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[3][0] = temp_fixed_val;
        float_to_fixed(9.0, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[3][1] = temp_fixed_val;
        float_to_fixed(1.1, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[3][2] = temp_fixed_val;
        float_to_fixed(2.2, DATA_FRAC, DATA_WIDTH, temp_fixed_val); A_tb[3][3] = temp_fixed_val;

        // B_tb: Mix of positive and negative, smaller magnitude
        float_to_fixed(0.1, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[0][0] = temp_fixed_val;
        float_to_fixed(0.2, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[0][1] = temp_fixed_val;
        float_to_fixed(-0.3, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[0][2] = temp_fixed_val;
        float_to_fixed(0.4, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[0][3] = temp_fixed_val;

        float_to_fixed(0.5, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[1][0] = temp_fixed_val;
        float_to_fixed(-0.1, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[1][1] = temp_fixed_val;
        float_to_fixed(0.6, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[1][2] = temp_fixed_val;
        float_to_fixed(0.7, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[1][3] = temp_fixed_val;

        float_to_fixed(0.8, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[2][0] = temp_fixed_val;
        float_to_fixed(0.9, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[2][1] = temp_fixed_val;
        float_to_fixed(-0.2, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[2][2] = temp_fixed_val;
        float_to_fixed(0.3, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[2][3] = temp_fixed_val;

        float_to_fixed(-0.4, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[3][0] = temp_fixed_val;
        float_to_fixed(0.5, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[3][1] = temp_fixed_val;
        float_to_fixed(0.1, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[3][2] = temp_fixed_val;
        float_to_fixed(-0.6, WEIGHT_FRAC, WEIGHT_WIDTH, temp_fixed_val); B_tb[3][3] = temp_fixed_val;


        // Flatten A_tb and B_tb into matrix_a_flat and matrix_b_flat
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = A_tb[i][j];
                matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = B_tb[i][j];
            end
        end

        // Calculate expected result C_expected_tb (floating point, then convert to fixed)
        // This is a standard matrix multiplication: C[i][j] = sum(A[i][k] * B[k][j])
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                sum_float = 0.0; // Initialize for each C[i][j]
                for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
                    a_val = $itor(A_tb[i][k]) / (2.0**DATA_FRAC);
                    b_val = $itor(B_tb[k][j]) / (2.0**WEIGHT_FRAC);
                    sum_float = sum_float + (a_val * b_val);
                end
                // Call the task to get the fixed-point result
                float_to_fixed(sum_float, ACCUM_FRAC, ACCUM_WIDTH, temp_fixed_val);
                C_expected_tb[i][j] = temp_fixed_val;
            end
        end

        // --- Simulation Sequence ---
        #10; // Wait for initial reset
        rst_n = 1'b1; // Deassert reset
        #10;
        start = 1'b1; // Pulse start signal
        #10;
        start = 1'b0; // Deassert start

        // Wait until computation is done
        wait (done);
        #10; // Give some time for signals to settle after done

        // Verification
        $display("\n--- Verification Results ---");
        $display("Expected Cycles for Done: %0d", (3 * ARRAY_SIZE - 1));
        $display("Actual Cycles when Done asserted: %0d", $time/10 - 2); // Adjust for initial reset + start pulse
        $display("result_valid: %b", result_valid);

        if (!result_valid) begin
            $display("ERROR: result_valid is not high when done!");
            $finish;
        end

        $display("\n--- DUT Results (Fixed-Point Raw / Decimal) ---");
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            $write("Row %0d: ", i);
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                $write("%h (%.4f) ", C_dut_tb[i][j], $itor(C_dut_tb[i][j]) / (2.0**ACCUM_FRAC));
            end
            $display("");
        end

        $display("\n--- Expected Results (Fixed-Point Raw / Decimal) ---");
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            $write("Row %0d: ", i);
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                $write("%h (%.4f) ", C_expected_tb[i][j], $itor(C_expected_tb[i][j]) / (2.0**ACCUM_FRAC));
            end
            $display("");
        end

        errors = 0; // Initialize errors
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (C_dut_tb[i][j] == C_expected_tb[i][j]) begin
                    pass_flags[i][j] = 1'b1;
                end else begin
                    pass_flags[i][j] = 1'b0;
                    errors = errors + 1; // Correct Verilog-2001 increment
                    $display("MISMATCH at C[%0d][%0d]: DUT= %h (%.4f), Expected= %h (%.4f)",
                             i, j, C_dut_tb[i][j], $itor(C_dut_tb[i][j]) / (2.0**ACCUM_FRAC),
                             C_expected_tb[i][j], $itor(C_expected_tb[i][j]) / (2.0**ACCUM_FRAC));
                end
            end
        end

        if (errors == 0) begin
            $display("\nTEST PASSED! All results match expected values.");
        end else begin
            $display("\nTEST FAILED! Found %0d mismatches.", errors);
        end

        $finish;
    end // End of initial block

endmodule // End of module
