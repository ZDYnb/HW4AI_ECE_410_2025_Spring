
// tb_mac_unit.v
`timescale 1ns / 1ps

module tb_mac_unit;

    localparam DATA_A_WIDTH = 8;
    localparam DATA_B_WIDTH = 8;
    localparam ACCUM_WIDTH  = 32;
    localparam CLK_PERIOD   = 10; // 10ns clock period (100 MHz)

    reg                          clk;
    reg                          rst_n;
    reg                          en;
    reg signed [DATA_A_WIDTH-1:0] data_a;
    reg signed [DATA_B_WIDTH-1:0] data_b;
    reg signed [ACCUM_WIDTH-1:0]  accum_in;
    wire signed [ACCUM_WIDTH-1:0] accum_out;

    // Instantiate the DUT (Device Under Test)
    mac_unit #(
        .DATA_A_WIDTH(DATA_A_WIDTH),
        .DATA_B_WIDTH(DATA_B_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_a(data_a),
        .data_b(data_b),
        .accum_in(accum_in),
        .accum_out(accum_out)
    );

    // Clock generation
    always begin
        clk = 1'b0; #(CLK_PERIOD/2);
        clk = 1'b1; #(CLK_PERIOD/2);
    end

    // Test sequence
    initial begin
        // Declare local variables for the initial block at the top
        logic signed [ACCUM_WIDTH-1:0] expected_val_tc4;

        // Start of procedural statements
        $display("[%0t] Starting MAC Unit Testbench...", $time);
        rst_n = 1'b0; // Assert reset
        en = 1'b0;
        data_a = 0;
        data_b = 0;
        accum_in = 0;
        #(CLK_PERIOD * 2); // Hold reset for 2 cycles

        rst_n = 1'b1; // De-assert reset
        $display("[%0t] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // Test Case 1: 5 * 3 + 10 = 25
        $display("[%0t] Test Case 1: 5 * 3 + 10", $time);
        data_a = 5;
        data_b = 3;
        accum_in = 10;
        en = 1'b1;      // Enable the operation for one cycle
        #(CLK_PERIOD);
        
        en = 1'b0;      // Disable further new operations.
        #(CLK_PERIOD);
                        
        #(CLK_PERIOD);
        $display("[%0t] TC1: DUT.data_a_reg=%d, DUT.data_b_reg=%d, DUT.accum_in_reg=%d, accum_out=%d (Expected: 25)",
                 $time, DUT.data_a_reg, DUT.data_b_reg, DUT.accum_in_reg, accum_out);
        if (accum_out !== 25) $error("[%0t] Test Case 1 FAILED: Expected 25, got %d", $time, accum_out);
        else $display("[%0t] Test Case 1 PASSED", $time);


        // Test Case 2: -4 * 6 + 25 (previous accum_out) = 1
        $display("[%0t] Test Case 2: -4 * 6 + 25", $time);
        data_a = -4;
        data_b = 6;
        // accum_in = accum_out; // Ideal, but for a strict test case, use the known expected previous value
        accum_in = 25; 
        en = 1'b1;
        #(CLK_PERIOD);
        
        en = 1'b0;
        #(CLK_PERIOD);
                        
        #(CLK_PERIOD);
        $display("[%0t] TC2: DUT.data_a_reg=%d, DUT.data_b_reg=%d, DUT.accum_in_reg=%d, accum_out=%d (Expected: 1)",
                 $time, DUT.data_a_reg, DUT.data_b_reg, DUT.accum_in_reg, accum_out);
        if (accum_out !== 1) $error("[%0t] Test Case 2 FAILED: Expected 1, got %d", $time, accum_out);
        else $display("[%0t] Test Case 2 PASSED", $time);


        // Test Case 3: 0 * 10 + 50 = 50
        $display("[%0t] Test Case 3: 0 * 10 + 50", $time);
        data_a = 0;
        data_b = 10;
        accum_in = 50;
        en = 1'b1;
        #(CLK_PERIOD);
        
        en = 1'b0;
        #(CLK_PERIOD);
                        
        #(CLK_PERIOD);
        $display("[%0t] TC3: DUT.data_a_reg=%d, DUT.data_b_reg=%d, DUT.accum_in_reg=%d, accum_out=%d (Expected: 50)",
                 $time, DUT.data_a_reg, DUT.data_b_reg, DUT.accum_in_reg, accum_out);
        if (accum_out !== 50) $error("[%0t] Test Case 3 FAILED: Expected 50, got %d", $time, accum_out);
        else $display("[%0t] Test Case 3 PASSED", $time);

        // Test Case 4: 127 * 127 + 0 (Max positive INT8 * Max positive INT8)
        // 127 * 127 = 16129
        $display("[%0t] Test Case 4: 127 * 127 + 0", $time);
        data_a = 127; 
        data_b = 127; 
        accum_in = 0;
        en = 1'b1;
        #(CLK_PERIOD);
        
        en = 1'b0;
        #(CLK_PERIOD);
                        
        #(CLK_PERIOD);
        
        // Assign value to the declared variable before use
        expected_val_tc4 = ((1<<(DATA_A_WIDTH-1)) - 1) * ((1<<(DATA_B_WIDTH-1)) - 1); 
        
        $display("[%0t] TC4: DUT.data_a_reg=%d, DUT.data_b_reg=%d, DUT.accum_in_reg=%d, accum_out=%d (Expected: %d)",
                 $time, DUT.data_a_reg, DUT.data_b_reg, DUT.accum_in_reg, accum_out, expected_val_tc4);
        if (accum_out !== expected_val_tc4) $error("[%0t] Test Case 4 FAILED: Expected %d, got %d", $time, expected_val_tc4, accum_out);
        else $display("[%0t] Test Case 4 PASSED", $time);

        $display("[%0t] MAC Unit Testbench Finished.", $time);
        $finish;
    end // End of initial block

endmodule
