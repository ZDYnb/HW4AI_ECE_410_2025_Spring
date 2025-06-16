`timescale 1ns/1ps

module tb_mac_unit_basic;

    // Parameters for DUT
    localparam DATA_WIDTH   = 16;
    localparam WEIGHT_WIDTH = 8;
    localparam ACCUM_WIDTH  = 24;
    localparam CLK_PERIOD   = 10; // Clock period in ns

    // Testbench signals
    reg                          clk;
    reg                          rst_n;
    reg                          enable;
    reg                          clear_accum;
    reg  [DATA_WIDTH-1:0]        data_in;
    reg  [WEIGHT_WIDTH-1:0]      weight_in;
    wire [ACCUM_WIDTH-1:0]       accum_out;
    wire                         valid_out;

    // Instantiate the Unit Under Test (DUT)
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_accum(clear_accum),
        .data_in(data_in),
        .weight_in(weight_in),
        .accum_out(accum_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Stimulus and test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        enable = 0;
        clear_accum = 0;
        data_in = 0;
        weight_in = 0;

        // Apply reset
        #(CLK_PERIOD * 2) rst_n = 1;
        $display("Time: %0tns --- Reset Released", $time);

        // Test Case 1: Simple multiplication (2 * 3 = 6)
        #(CLK_PERIOD) enable = 1;
        clear_accum = 1;
        data_in = 16'd2;    // 2 (as integer for simplicity)
        weight_in = 8'd3;   // 3 (as integer)
        $display("Time: %0tns --- TC1: data_in=2, weight_in=3, clear_accum=1. Expected product=6", $time);
        
        // Test Case 2: Accumulate (-4 * 5 = -20), previous was 6. Expected accum = 6 + (-20) = -14
        #(CLK_PERIOD) clear_accum = 0; // Now accumulate
        data_in = -4; // -4
        weight_in = $signed(8'd5);  // 5
        $display("Time: %0tns --- TC2: data_in=-4, weight_in=5, clear_accum=0. Expected product=-20, accum=-14", $time);

        // Test Case 3: Accumulate (10 * 1 = 10), previous was -14. Expected accum = -14 + 10 = -4
        #(CLK_PERIOD) data_in = $signed(16'd10); // 10
        weight_in = $signed(8'd1);   // 1
        $display("Time: %0tns --- TC3: data_in=10, weight_in=1, clear_accum=0. Expected product=10, accum=-4", $time);

        // Test Case 4: clear_accum again (5 * 2 = 10)
        #(CLK_PERIOD) clear_accum = 1;
        data_in = $signed(16'd5);   // 5
        weight_in = $signed(8'd2);  // 2
        $display("Time: %0tns --- TC4: data_in=5, weight_in=2, clear_accum=1. Expected product=10, accum=10", $time);

        // Test Case 5: Disable enable
        #(CLK_PERIOD) enable = 0;
        $display("Time: %0tns --- TC5: enable=0. Accumulator should hold value, valid_out should be 0.", $time);
        
        // Test Case 6: Enable again with new values, still accumulating from previous enabled state (10)
        // but accum_out is only updated on posedge when enable is high.
        // Since enable was low, accum_reg held '10'. Now clear_accum=0, product = 1*1=1. Expected 10+1=11
        #(CLK_PERIOD) enable = 1;
        clear_accum = 0;
        data_in = $signed(16'd1);   // 1
        weight_in = $signed(8'd1);  // 1
        $display("Time: %0tns --- TC6: data_in=1, weight_in=1, clear_accum=0, enable=1. Expected product=1, accum=11", $time);
        
        #(CLK_PERIOD * 2); // Wait for last transaction to complete

        // End simulation
        $display("Time: %0tns --- Testbench Finished", $time);
        $finish;
    end

    // Monitor to display signals when they change
    initial begin
        $monitor("Time: %0tns | rst_n: %b, enable: %b, clear: %b | data: %d (0x%h), weight: %d (0x%h) || accum: %d (0x%h), valid: %b",
                 $time, rst_n, enable, clear_accum, data_in, data_in, weight_in, weight_in, accum_out, accum_out, valid_out);
    end

endmodule
