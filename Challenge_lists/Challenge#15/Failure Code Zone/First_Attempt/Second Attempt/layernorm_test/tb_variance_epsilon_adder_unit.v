// tb_variance_epsilon_adder_unit.v
`timescale 1ns/1ps

module tb_variance_epsilon_adder_unit;

    // Parameters for DUT (should match DUT parameters)
    localparam DATA_WIDTH      = 24;
    localparam FRAC_BITS       = 20; // For S3.20 format
    localparam EPSILON_INT_VAL = 11; // Represents epsilon = 11 * 2^(-20)

    // Testbench signals
    reg clk;
    reg rst_n;
    reg signed [DATA_WIDTH-1:0] variance_in_tb;
    reg                         variance_valid_in_tb;

    wire signed [DATA_WIDTH-1:0] var_plus_eps_out_tb;
    wire                         var_plus_eps_valid_out_tb;

    // Instantiate the Unit Under Test (DUT)
    variance_epsilon_adder_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .EPSILON_INT_VAL(EPSILON_INT_VAL)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .variance_in(variance_in_tb),
        .variance_valid_in(variance_valid_in_tb),
        .var_plus_eps_out(var_plus_eps_out_tb),
        .var_plus_eps_valid_out(var_plus_eps_valid_out_tb)
    );

    // Clock generation
    localparam CLK_PERIOD = 10; // ns
    initial clk = 1'b0;
    always #((CLK_PERIOD)/2) clk = ~clk;

    // Stimulus and checking
    initial begin
        // Initialize signals
        rst_n = 1'b0; // Assert reset
        variance_in_tb = 0;
        variance_valid_in_tb = 1'b0;

        #(CLK_PERIOD * 2);
        rst_n = 1'b1; // De-assert reset
        #(CLK_PERIOD);

        // Test Case 1: variance_in = 0.0
        // Expected output = 0.0 + epsilon = 11 (as integer representation for S3.20)
        variance_in_tb = 24'sd0;
        variance_valid_in_tb = 1'b1;
        $display("[%0t ns] TC1: Applying variance_in = %d (0.0), valid_in = 1", $time, variance_in_tb);
        @(posedge clk);
        variance_valid_in_tb = 1'b0;

        @(posedge clk); // Wait for output to be valid (1 cycle latency)
        if (var_plus_eps_valid_out_tb && var_plus_eps_out_tb == 24'sd11) begin
            $display("[%0t ns] TC1 PASS: var_plus_eps_out = %d", $time, var_plus_eps_out_tb);
        end else begin
            $error("[%0t ns] TC1 FAIL: var_plus_eps_out = %d (Expected 11), valid = %b", $time, var_plus_eps_out_tb, var_plus_eps_valid_out_tb);
        end
        #(CLK_PERIOD);

        // Test Case 2: variance_in = some small value, e.g., 100 * 2^(-20)
        // Expected output = 100 + 11 = 111 (as integer representation)
        variance_in_tb = 24'sd100;
        variance_valid_in_tb = 1'b1;
        $display("[%0t ns] TC2: Applying variance_in = %d (100*2^-20), valid_in = 1", $time, variance_in_tb);
        @(posedge clk);
        variance_valid_in_tb = 1'b0;

        @(posedge clk); // Wait for output
        if (var_plus_eps_valid_out_tb && var_plus_eps_out_tb == 24'sd111) begin
            $display("[%0t ns] TC2 PASS: var_plus_eps_out = %d", $time, var_plus_eps_out_tb);
        end else begin
            $error("[%0t ns] TC2 FAIL: var_plus_eps_out = %d (Expected 111), valid = %b", $time, var_plus_eps_out_tb, var_plus_eps_valid_out_tb);
        end
        #(CLK_PERIOD);
        
        // Test Case 3: variance_in = 1.0 (S3.20 integer rep: 1 * 2^20 = 1048576)
        // Expected output = 1048576 + 11 = 1048587
        variance_in_tb = 24'sd1048576; 
        variance_valid_in_tb = 1'b1;
        $display("[%0t ns] TC3: Applying variance_in = %d (1.0), valid_in = 1", $time, variance_in_tb);
        @(posedge clk);
        variance_valid_in_tb = 1'b0;

        @(posedge clk); // Wait for output
        if (var_plus_eps_valid_out_tb && var_plus_eps_out_tb == 24'sd1048587) begin
            $display("[%0t ns] TC3 PASS: var_plus_eps_out = %d", $time, var_plus_eps_out_tb);
        end else begin
            $error("[%0t ns] TC3 FAIL: var_plus_eps_out = %d (Expected 1048587), valid = %b", $time, var_plus_eps_out_tb, var_plus_eps_valid_out_tb);
        end
        #(CLK_PERIOD * 5);


        $display("[%0t ns] Test bench finished.", $time);
        $finish;
    end

endmodule
