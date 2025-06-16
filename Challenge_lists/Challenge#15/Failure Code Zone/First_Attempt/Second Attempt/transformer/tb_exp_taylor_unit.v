`timescale 1ns / 1ps
`default_nettype none

module tb_exp_taylor_unit;

    // Parameters
    parameter INPUT_WIDTH         = 33;
    parameter INPUT_FRAC_BITS     = 16;
    parameter OUTPUT_WIDTH        = 16;
    parameter OUTPUT_FRAC_BITS    = 15;
    parameter NUM_TERMS           = 4;
    parameter INTERNAL_FRAC_BITS  = 20;
    parameter LATENCY             = 5;
    parameter CLK_PERIOD          = 10; // ns

    // DUT ports
    reg  clk, rst_n, start_exp;
    reg  signed [INPUT_WIDTH-1:0] x_in;
    wire signed [OUTPUT_WIDTH-1:0] y_out;
    wire exp_done;

    // Instantiate DUT
    exp_taylor_unit #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_FRAC_BITS(INPUT_FRAC_BITS),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .OUTPUT_FRAC_BITS(OUTPUT_FRAC_BITS),
        .NUM_TERMS(NUM_TERMS),
        .INTERNAL_FRAC_BITS(INTERNAL_FRAC_BITS),
        .LATENCY(LATENCY)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_exp(start_exp),
        .x_in(x_in),
        .y_out(y_out),
        .exp_done(exp_done)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Taylor series exp(x) (for x ¿ 0)
    function real taylor_exp;
        input real x;
        input int terms;
        real sum, term;
        begin
            sum = 1.0; term = 1.0;
            for (int i = 1; i < terms; i++) begin
                term *= x / i;
                sum += term;
            end
            return sum;
        end
    endfunction

    // Test task
    task run_test(input real x_val, input int tol_bits);
        real expected;
        int  fixed_in, expected_fixed;
        begin
            // Apply input
            fixed_in = $rtoi(x_val * (1 << INPUT_FRAC_BITS));
            x_in = fixed_in;

            expected = taylor_exp(x_val, NUM_TERMS);
            expected_fixed = $rtoi(expected * (1 << OUTPUT_FRAC_BITS));

            $display("\n[TB] Test x = %f (fixed = %d)", x_val, fixed_in);
            $display("[TB] Expect exp(x) ¿ %f ¿ fixed = %d", expected, expected_fixed);

            start_exp = 1'b1; @(posedge clk); start_exp = 1'b0;

            wait (exp_done == 1); // Wait until done
            repeat (1) @(posedge clk); // settle

            $display("[TB] DUT Output y = %d", y_out);
            if (y_out >= expected_fixed - tol_bits && y_out <= expected_fixed + tol_bits)
                $display("[TB] ¿ PASS (within ±%0d tolerance bits)", tol_bits);
            else
                $error("[TB] ¿ FAIL. y_out = %d, expected = %d", y_out, expected_fixed);
        end
    endtask

    // Main test sequence
    initial begin
        real inputs[0:4] = '{0.0, -0.5, -1.0, -2.0, -4.0};

        clk = 0;
        rst_n = 0;
        start_exp = 0;
        x_in = 0;

        $display("\n=== Running exp_taylor_unit Testbench ===");
        #(3 * CLK_PERIOD);
        rst_n = 1;
        #(2 * CLK_PERIOD);

        foreach (inputs[i]) begin
            run_test(inputs[i], 2); // ±2 tolerance bits
            #(3 * CLK_PERIOD);
        end

        $display("=== All tests completed ===\n");
        $finish;
    end

endmodule

