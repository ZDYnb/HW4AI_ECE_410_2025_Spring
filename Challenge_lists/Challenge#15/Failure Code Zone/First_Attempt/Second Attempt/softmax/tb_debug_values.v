`timescale 1ns/1ps

module tb_debug_values;

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
// Debug monitor
// ===========================================
always @(posedge clk) begin
    if (valid_out) begin  // Simplified condition
        $display("=== DEBUG VALUES ===");
        $display("max_value = 0x%h (%f)", dut.max_value, dut.max_value/1024.0);
        $display("exp_input = 0x%h (%f)", dut.exp_input, $signed(dut.exp_input)/1024.0);
        $display("exp_lut.x_signed = 0x%h", dut.exp_lut.x_signed);
        $display("exp_lut.x_clamped = 0x%h", dut.exp_lut.x_clamped);
        $display("exp_lut.x_offset = 0x%h", dut.exp_lut.x_offset);
        $display("exp_lut.rom_addr = 0x%h", dut.exp_lut.rom_addr);
        $display("exp_values[0] = 0x%h (%f)", dut.exp_values[0], dut.exp_values[0]/1024.0);
        $display("sum_result = 0x%h (%f)", dut.sum_result, dut.sum_result/1024.0);
        $display("reciprocal_output = 0x%h (%f)", dut.reciprocal_output, $signed(dut.reciprocal_output)/16384.0);
        $display("Before shift: exp×recip = 0x%h", dut.exp_values[0] * dut.reciprocal_output);
        $display("After >>14: result = 0x%h (%f)", (dut.exp_values[0] * dut.reciprocal_output) >> 14, ((dut.exp_values[0] * dut.reciprocal_output) >> 14)/1024.0);
        $display("After >>10: result = 0x%h (%f)", (dut.exp_values[0] * dut.reciprocal_output) >> 10, ((dut.exp_values[0] * dut.reciprocal_output) >> 10)/1024.0);
        $display("softmax_results[0] = 0x%h (%f)", dut.softmax_results[0], dut.softmax_results[0]/1024.0);
        $finish;
    end
end

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
// Simple test
// ===========================================
initial begin
    $display("===========================================");
    $display("Debug Intermediate Values");
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
    
    $display("Starting computation...");
    start = 1;
    @(posedge clk);
    start = 0;
    
    // Wait for completion
    wait(valid_out);
    repeat(3) @(posedge clk);
end

endmodule
