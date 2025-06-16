// tb_sqrt_non_restoring.v (Verilog-2001 style)
`timescale 1ns/1ps

module tb_sqrt_non_restoring;

    // Parameters for DUT instantiation
    parameter DATA_IN_WIDTH    = 24;
    parameter ROOT_OUT_WIDTH   = 12;
    parameter S_REG_WIDTH      = 16;
    parameter FINAL_OUT_WIDTH  = 24;
    parameter FRAC_BITS_OUT    = 10;

    // Test bench signals
    reg clk;
    reg rst_n;
    reg [DATA_IN_WIDTH-1:0]   radicand_in_tb;
    reg                       valid_in_tb;
    wire signed [FINAL_OUT_WIDTH-1:0] sqrt_out_tb;
    wire                       valid_out_tb;

    // Instantiate the Unit Under Test (DUT)
    sqrt_non_restoring #(
        .DATA_IN_WIDTH    (DATA_IN_WIDTH),
        .ROOT_OUT_WIDTH   (ROOT_OUT_WIDTH),
        .S_REG_WIDTH      (S_REG_WIDTH),
        .FINAL_OUT_WIDTH  (FINAL_OUT_WIDTH),
        .FRAC_BITS_OUT    (FRAC_BITS_OUT)
    ) DUT (
        .clk            (clk),
        .rst_n          (rst_n),
        .radicand_in    (radicand_in_tb),
        .valid_in       (valid_in_tb),
        .sqrt_out       (sqrt_out_tb),
        .valid_out      (valid_out_tb)
    );

    // Clock generation
    parameter CLK_PERIOD = 10; // ns
    initial clk = 1'b0; // Initialize clock
    always #((CLK_PERIOD)/2) clk = ~clk;

    // Stimulus and monitoring
    initial begin
        // Initialize signals
        rst_n = 1'b0; // Assert reset
        radicand_in_tb = 0;
        valid_in_tb = 0;

        #(CLK_PERIOD);
        rst_n = 1'b1; // De-assert reset
        #(CLK_PERIOD);

        // --- Test Case 1: sqrt(4.0) ---
        radicand_in_tb = 24'd4194304;
        valid_in_tb = 1;
        $display("[%0t ns] Applying radicand_in = %d (represents 4.0)", $time, radicand_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] sqrt_out = %d (Q_int=%d, Expected Q_int=2048), valid_out = %b",
                  $time, sqrt_out_tb, sqrt_out_tb[(ROOT_OUT_WIDTH-1):0], valid_out_tb);
        #(CLK_PERIOD * 2);

        // --- Test Case 2: sqrt(2.25) ---
        radicand_in_tb = 24'd2359296;
        valid_in_tb = 1;
        $display("[%0t ns] Applying radicand_in = %d (represents 2.25)", $time, radicand_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] sqrt_out = %d (Q_int=%d, Expected Q_int=1536), valid_out = %b",
                  $time, sqrt_out_tb, sqrt_out_tb[(ROOT_OUT_WIDTH-1):0], valid_out_tb);
        #(CLK_PERIOD * 2);

        // --- Test Case 3: sqrt(0.25) ---
        radicand_in_tb = 24'd262144;
        valid_in_tb = 1;
        $display("[%0t ns] Applying radicand_in = %d (represents 0.25)", $time, radicand_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] sqrt_out = %d (Q_int=%d, Expected Q_int=512), valid_out = %b",
                  $time, sqrt_out_tb, sqrt_out_tb[(ROOT_OUT_WIDTH-1):0], valid_out_tb);
        #(CLK_PERIOD * 2);
        
        // --- Test Case 4: Small value (D_int = 11) ---
        radicand_in_tb = 24'd11;
        valid_in_tb = 1;
        $display("[%0t ns] Applying radicand_in = %d (represents D_int=11)", $time, radicand_in_tb);
        #CLK_PERIOD;
        valid_in_tb = 0;

        wait (valid_out_tb == 1);
        $display("[%0t ns] sqrt_out = %d (Q_int=%d, Expected Q_int=3), valid_out = %b",
                  $time, sqrt_out_tb, sqrt_out_tb[(ROOT_OUT_WIDTH-1):0], valid_out_tb);
        #(CLK_PERIOD * 5);

        $display("[%0t ns] Test bench finished.", $time);
        $finish;
    end
endmodule
