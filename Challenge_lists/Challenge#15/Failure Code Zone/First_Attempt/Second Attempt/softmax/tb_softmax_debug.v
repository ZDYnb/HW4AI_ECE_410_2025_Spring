`timescale 1ns/1ps

module tb_softmax_debug;

// =========================================== 
// Testbench signals
// ===========================================
reg clk;
reg rst_n;
reg start;
reg [1023:0] qk_input;
wire [1023:0] softmax_out;
wire valid_out;

// Test variables
integer i;

// =========================================== 
// Clock generation
// ===========================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

// =========================================== 
// DUT instantiation
// ===========================================
softmax_controller_reciprocal dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .qk_input(qk_input),
    .softmax_out(softmax_out),
    .valid_out(valid_out)
);

// =========================================== 
// Fixed point conversion
// ===========================================
function [15:0] real_to_s5p10;
    input real val;
    reg [15:0] temp_val;
    begin
        if (val < 0) begin
            temp_val = (-val) * 1024.0;
            real_to_s5p10 = (~temp_val) + 1;
        end else begin
            real_to_s5p10 = val * 1024.0;
        end
    end
endfunction

// =========================================== 
// Debug monitor
// ===========================================
always @(posedge clk) begin
    $display("[%0t] State=%h, exp_counter=%d, mult_counter=%d, valid_out=%b",
             $time, dut.state, dut.exp_counter, dut.mult_counter, valid_out);
    $display("         max_value=%h, exp_input=%h, exp_valid=%b",
             dut.max_value, dut.exp_input, dut.exp_valid);
    $display("         sum_valid=%b, reciprocal_valid=%b",
             dut.sum_valid, dut.reciprocal_valid);
end

// =========================================== 
// Simple test
// ===========================================
initial begin
    $display("===========================================");
    $display("Debug Softmax FSM Behavior");
    $display("===========================================");
    
    // Initialize
    rst_n = 0;
    start = 0;
    
    // Set up simple test data (all 1.0)
    for (i = 0; i < 64; i = i + 1) begin
        qk_input[i*16 +: 16] = real_to_s5p10(1.0);
    end
    
    // Reset sequence
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(3) @(posedge clk);
    
    $display("Starting softmax computation...");
    start = 1;
    @(posedge clk);
    start = 0;
    
    // Monitor for 300 cycles (was 200)
    repeat(300) begin
        @(posedge clk);
        if (valid_out) begin
            $display("¿ SUCCESS: valid_out asserted at time %0t", $time);
            $finish;
        end
    end
    
    $display("¿ TIMEOUT: FSM stuck after 300 cycles");
    $finish;
end

endmodule
