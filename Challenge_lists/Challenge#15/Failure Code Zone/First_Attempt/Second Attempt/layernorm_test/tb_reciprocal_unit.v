
// tb_reciprocal_unit.v
`timescale 1ns/1ps

module tb_reciprocal_unit;

    // Parameters for DUT (should match reciprocal_unit parameters)
    localparam INPUT_X_WIDTH   = 24;
    localparam DIVISOR_WIDTH   = 24;
    localparam QUOTIENT_WIDTH  = 24;
    localparam FINAL_OUT_WIDTH = 24; // For S9.14 output

    // Test bench signals
    reg clk;
    reg rst_n;
    reg signed [INPUT_X_WIDTH-1:0] X_in_tb; // Input to DUT (S13.10)
    reg                            valid_in_tb;
    wire signed [FINAL_OUT_WIDTH-1:0] reciprocal_out_tb; // Output from DUT (S9.14)
    wire                           valid_out_tb;

    // Instantiate the Unit Under Test (DUT)
    reciprocal_unit #(
        .INPUT_X_WIDTH   (INPUT_X_WIDTH),
        .DIVISOR_WIDTH   (DIVISOR_WIDTH),
        .QUOTIENT_WIDTH  (QUOTIENT_WIDTH),
        .FINAL_OUT_WIDTH (FINAL_OUT_WIDTH)
        // REMAINDER_WIDTH and DIVIDEND_REG_WIDTH use defaults from DUT
    ) DUT (
        .clk            (clk),
        .rst_n          (rst_n),
        .X_in           (X_in_tb),
        .valid_in       (valid_in_tb),
        .reciprocal_out (reciprocal_out_tb),
        .valid_out      (valid_out_tb)
    );

    // Clock generation
    localparam CLK_PERIOD = 10; // ns
    initial clk = 1'b0;
    always #((CLK_PERIOD)/2) clk = ~clk;

    // Stimulus and monitoring
    initial begin
        rst_n = 1'b0;
        X_in_tb = 0;
        valid_in_tb = 0;

        #(CLK_PERIOD);
        rst_n = 1'b1;
        #(CLK_PERIOD);

        // --- Test Case 1: X_val = 2.0 ---
        // X_in (S13.10): 2.0 * 2^10 = 2048.
        // Expected Reciprocal_val = 0.5.
        // Expected Q_hw (output magnitude for S9.14): 0.5 * 2^14 = 8192.
        X_in_tb = 24'sd2048; // Represents 2.0 in S13.10 (assuming enough integer bits for 2.0)
                             // If S13.10 implies 1s.13i.10f, then 2.0 is 2048.
                             // Since X_in port on DUT is signed, we provide a signed value.
        valid_in_tb = 1;
        $display("[%0t ns] Applying X_in = %d (S13.10 rep of 2.0)", $time, X_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] reciprocal_out = %d (S9.14 value, Q_hw=%d, Expected Q_hw=8192), valid_out = %b",
                  $time, reciprocal_out_tb, reciprocal_out_tb, valid_out_tb); // Display full signed output
        #(CLK_PERIOD * 2);

        // --- Test Case 2: X_val = 0.5 ---
        // X_in (S13.10): 0.5 * 2^10 = 512.
        // Expected Reciprocal_val = 2.0.
        // Expected Q_hw: 2.0 * 2^14 = 32768.
        X_in_tb = 24'sd512; // Represents 0.5
        valid_in_tb = 1;
        $display("[%0t ns] Applying X_in = %d (S13.10 rep of 0.5)", $time, X_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] reciprocal_out = %d (S9.14 value, Q_hw=%d, Expected Q_hw=32768), valid_out = %b",
                  $time, reciprocal_out_tb, reciprocal_out_tb, valid_out_tb);
        #(CLK_PERIOD * 2);

        // --- Test Case 3: X_val = 1.0 ---
        // X_in (S13.10): 1.0 * 2^10 = 1024.
        // Expected Reciprocal_val = 1.0.
        // Expected Q_hw: 1.0 * 2^14 = 16384.
        X_in_tb = 24'sd1024; // Represents 1.0
        valid_in_tb = 1;
        $display("[%0t ns] Applying X_in = %d (S13.10 rep of 1.0)", $time, X_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] reciprocal_out = %d (S9.14 value, Q_hw=%d, Expected Q_hw=16384), valid_out = %b",
                  $time, reciprocal_out_tb, reciprocal_out_tb, valid_out_tb);
        #(CLK_PERIOD * 5);

        $display("[%0t ns] Test bench finished.", $time);
        $finish;
    end
endmodule
