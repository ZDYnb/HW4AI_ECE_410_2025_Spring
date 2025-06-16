`timescale 1ns / 1ps

module tb_variance_unit;

    // Parameters from DUT (ensure these match variance_unit.v)
    parameter D_MODEL = 128;
    parameter DATA_WIDTH = 24;
    parameter NUM_PE = 8;
    parameter INTERNAL_WIDTH = 48; // For squared values

    // Testbench signals
    reg                            clk;
    reg                            rst_n;
    reg [(D_MODEL*DATA_WIDTH)-1:0] tb_data_in_flat;
    reg [DATA_WIDTH-1:0]           tb_mean_in;
    reg                            tb_start_variance;

    wire [DATA_WIDTH-1:0]          tb_variance_out;
    wire                           tb_variance_valid;
    wire                           tb_busy;

    integer i; // Loop variable
    integer error_count = 0;

    // Instantiate the Device Under Test (DUT)
    variance_unit #(
        .D_MODEL(D_MODEL),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_PE(NUM_PE),
        .INTERNAL_WIDTH(INTERNAL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in_flat(tb_data_in_flat),
        .mean_in(tb_mean_in),
        .start_variance(tb_start_variance),
        .variance_out(tb_variance_out),
        .variance_valid(tb_variance_valid),
        .busy(tb_busy)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Creates a 10ns period clock (100MHz)
    end

    // Test sequence
    initial begin
        $display("------------------------------------------------------");
        $display("Starting Variance Unit Testbench at time %0t ns", $time);
        $display("------------------------------------------------------");

        // 1. Apply Reset
        rst_n = 1'b0; // Assert reset
        tb_start_variance = 1'b0;
        tb_data_in_flat = 0; // Initialize the whole flat array
        tb_mean_in = 0;
        $display("[%0t ns] TB: Asserting reset.", $time);
        #20; // Hold reset for 20ns
        rst_n = 1'b1; // De-assert reset
        $display("[%0t ns] TB: De-asserted reset.", $time);
        #10; // Wait a bit after reset

        // --- Test Case 1: All data points equal to the mean (expected variance = 0) ---
        $display("[%0t ns] TB: Starting Test Case 1: All data points equal to mean.", $time);
        tb_mean_in = 24'd100; // Let's pick 100 as the mean
        
        // Corrected loop for assigning to tb_data_in_flat
        for (i = 0; i < D_MODEL; i = i + 1) begin
            // Verilog-2001 and later allow indexed part-select assignments:
            // vector[base_expr +: width_expr]
            tb_data_in_flat[i*DATA_WIDTH +: DATA_WIDTH] = tb_mean_in; 
        end
        $display("[%0t ns] TB: Input data and mean (100) set.", $time);

        tb_start_variance = 1'b1; // Pulse start signal
        #10; // Keep start high for one clock cycle (10ns)
        tb_start_variance = 1'b0;
        $display("[%0t ns] TB: Pulsed start_variance. Waiting for busy signal...", $time);

        // Standard Verilog wait for busy to assert
        wait (tb_busy == 1'b1); 
        $display("[%0t ns] TB: Unit is busy. Waiting for variance_valid...", $time);

        wait (tb_variance_valid == 1'b1); // Wait for the output to be valid
        $display("[%0t ns] TB: variance_valid is HIGH.", $time);
        $display("[%0t ns] TB: DUT variance_out = %d", $time, tb_variance_out);

        // Check the result
        if (tb_variance_out === 24'd0) begin
            $display("[%0t ns] TB: PASS! Variance is 0 as expected.", $time);
        end else begin
            $display("[%0t ns] TB: FAIL! Variance is %d, expected 0.", $time, tb_variance_out);
            error_count = error_count + 1;
        end
        
        // It's good practice to wait for valid to go low if it's a pulse
        // or if you are going to start another transaction immediately.
        // This helps ensure a clean state for subsequent operations or checks.
        if (tb_variance_valid == 1'b1) begin // Check if it's still high
             @(posedge clk iff tb_variance_valid == 1'b0); // Using SystemVerilog 'iff' here for robustness if possible
        end
        wait (tb_variance_valid == 1'b0); // Wait for valid to de-assert if it hasn't already
        // #10; // Alternatively, just a small delay if valid is guaranteed to be a single cycle pulse

        // --- Add more test cases here ---
        // Example:
        // $display("[%0t ns] TB: Starting Test Case 2: ...", $time);
        // ... (setup new tb_data_in_flat, tb_mean_in, calculate expected_variance) ...
        // ... (pulse tb_start_variance) ...
        // ... (wait for tb_busy, then tb_variance_valid) ...
        // ... (check result) ...


        // End simulation
        #50; // Add some extra delay before finishing
        if (error_count == 0) begin
            $display("------------------------------------------------------");
            $display("All tests PASSED at time %0t ns!", $time);
            $display("------------------------------------------------------");
        end else begin
            $display("------------------------------------------------------");
            $error("There were %0d ERRORS at time %0t ns!", error_count, $time); // $error usually causes non-zero exit code
            $display("------------------------------------------------------");
        end
        $finish;
    end

endmodule
