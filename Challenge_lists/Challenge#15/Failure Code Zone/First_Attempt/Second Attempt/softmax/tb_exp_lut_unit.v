// ===========================================
// EXP LUT Unit Testbench
// Pure Verilog-2001 Compatible
// Clean version without syntax errors
// ===========================================

`timescale 1ns/1ps

module tb_exp_lut_unit;

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
parameter WIDTH = 16;
parameter FRAC_BITS = 10;
parameter CLK_PERIOD = 10;

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
reg clk;
reg rst_n;
reg [WIDTH-1:0] x_in;
wire [WIDTH-1:0] exp_out;
wire valid_out;

// ¿?¿?¿?¿?¿?
real x_real, exp_real, exp_expected, error_percent;
integer i, test_count, pass_count, fail_count;

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// ===========================================
// DUT¿?¿?¿?
// ===========================================
exp_lut_unit dut (
    .clk(clk),
    .rst_n(rst_n),
    .x_in(x_in),
    .exp_out(exp_out),
    .valid_out(valid_out)
);

// ===========================================
// S5.10¿?¿?¿?¿?¿?¿?
// ===========================================
function real s5p10_to_real;
    input [WIDTH-1:0] fixed_val;
    reg signed [WIDTH-1:0] signed_val;
    begin
        signed_val = fixed_val;
        s5p10_to_real = $itor(signed_val) / 1024.0;
    end
endfunction

function [WIDTH-1:0] real_to_s5p10;
    input real real_val;
    begin
        real_to_s5p10 = $rtoi(real_val * 1024.0);
    end
endfunction

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
task test_single_value;
    input real test_x;
    input real expected_exp;
    input [7:0] test_id;
    begin
        // ¿?¿?¿?¿?
        x_real = test_x;
        x_in = real_to_s5p10(x_real);
        exp_expected = expected_exp;
        
        // ¿?¿?¿?¿?¿?¿?¿?¿?
        @(posedge clk);
        
        // ¿?¿?valid¿?¿?
        wait(valid_out);
        @(posedge clk);
        
        // ¿?¿?¿?¿?
        exp_real = s5p10_to_real(exp_out);
        
        // ¿?¿?¿?¿?
        if (exp_expected > 0.0) begin
            error_percent = ((exp_real - exp_expected) / exp_expected) * 100.0;
        end else begin
            error_percent = 0.0;
        end
        
        // ¿?¿?¿?¿?abs
        if (error_percent < 0.0) begin
            error_percent = -error_percent;
        end
        
        // ¿?¿?¿?¿?/¿?¿?
        if (error_percent <= 15.0) begin
            $display("¿ Test[%2d]: x=%6.3f, hw=%6.3f, exp=%6.3f, err=%5.1f%%", 
                     test_id, x_real, exp_real, exp_expected, error_percent);
            pass_count = pass_count + 1;
        end else begin
            $display("¿ Test[%2d]: x=%6.3f, hw=%6.3f, exp=%6.3f, err=%5.1f%%", 
                     test_id, x_real, exp_real, exp_expected, error_percent);
            $display("   HW=0x%04x", exp_out);
            fail_count = fail_count + 1;
        end
        
        test_count = test_count + 1;
    end
endtask

// ===========================================
// ¿?¿?¿?¿?¿?
// ===========================================
initial begin
    $display("===========================================");
    $display("EXP LUT Unit Testbench Started");
    $display("S5.10 Format: exp(-8.0) to exp(0.0)");
    $display("===========================================");
    
    // ¿?¿?¿?
    test_count = 0;
    pass_count = 0;
    fail_count = 0;
    
    // ¿?¿?
    rst_n = 0;
    x_in = 16'h0000;
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    
    // ¿?¿?¿?¿?
    $display("\n=== Reset Test ===");
    rst_n = 0;
    @(posedge clk);
    if (exp_out == 16'h0000 && valid_out == 1'b0) begin
        $display("¿ Reset test passed");
    end else begin
        $display("¿ Reset test failed");
    end
    rst_n = 1;
    @(posedge clk);
    
    // ¿?¿?¿?¿?¿?
    $display("\n=== Key Point Tests ===");
    
    test_single_value(-8.0, 0.000335, 0);
    test_single_value(-7.0, 0.000912, 1);
    test_single_value(-6.0, 0.002479, 2);
    test_single_value(-5.0, 0.006738, 3);
    test_single_value(-4.0, 0.018316, 4);
    test_single_value(-3.0, 0.049787, 5);
    test_single_value(-2.0, 0.135335, 6);
    test_single_value(-1.0, 0.367879, 7);
    test_single_value(-0.5, 0.606531, 8);
    test_single_value(0.0, 1.000000, 9);
    
    // ¿?¿?¿?¿?
    $display("\n=== Boundary Tests ===");
    test_single_value(-8.1, 0.000335, 10);  // ¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?
    test_single_value(0.1, 1.000000, 11);   // ¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?
    
    // ¿?¿?¿?¿?¿?
    $display("\n=== Intermediate Tests ===");
    test_single_value(-1.5, 0.223130, 12);
    test_single_value(-2.5, 0.082085, 13);
    test_single_value(-3.5, 0.030197, 14);
    test_single_value(-4.5, 0.011109, 15);
    
    // ¿?¿?¿?¿?
    $display("\n===========================================");
    $display("Test Results Summary:");
    $display("Total Tests: %d", test_count);
    $display("Passed:      %d", pass_count);
    $display("Failed:      %d", fail_count);
    
    if (test_count > 0) begin
        $display("Pass Rate:   %.1f%%", (pass_count * 100.0) / test_count);
    end
    
    $display("===========================================");
    
    if (fail_count == 0) begin
        $display("¿ ALL TESTS PASSED! EXP LUT working correctly!");
    end else if (pass_count > fail_count) begin
        $display("¿ Most tests passed. EXP LUT functioning well.");
    end else begin
        $display("¿  Many tests failed. Check EXP LUT implementation.");
    end
    
    $finish;
end

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
initial begin
    #50000;
    $display("¿ TIMEOUT: Test took too long!");
    $finish;
end

endmodule
