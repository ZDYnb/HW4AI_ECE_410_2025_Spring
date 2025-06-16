`timescale 1ns/1ps

module tb_softmax_complete;

// =========================================== 
// Testbench signals
// ===========================================
reg clk;
reg rst_n;
reg start;
reg [1023:0] qk_input;      // 64×16 Q×K^T values
wire [1023:0] softmax_out;  // 64×16 softmax results
wire valid_out;

// Test control
integer i;
real qk_values [63:0];
real softmax_results [63:0];
real sum_check;
real max_val, min_val;
real expected_sum;

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
// Fixed point conversion functions
// ===========================================
function real s5p10_to_real;
    input [15:0] fixed_val;
    begin
        if (fixed_val[15]) // negative
            s5p10_to_real = -(((~fixed_val) + 1) / 1024.0);
        else
            s5p10_to_real = fixed_val / 1024.0;
    end
endfunction

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
// Test task
// ===========================================
task run_softmax_test;
    input [200*8:1] test_name;
    begin
        $display("\n===========================================");
        $display("%s", test_name);
        $display("===========================================");
        
        // Pack input values
        for (i = 0; i < 64; i = i + 1) begin
            qk_input[i*16 +: 16] = real_to_s5p10(qk_values[i]);
        end
        
        // Display input range
        max_val = qk_values[0];
        min_val = qk_values[0];
        for (i = 1; i < 64; i = i + 1) begin
            if (qk_values[i] > max_val) max_val = qk_values[i];
            if (qk_values[i] < min_val) min_val = qk_values[i];
        end
        $display("Input range: %.3f to %.3f", min_val, max_val);
        
        // Start softmax computation
        start = 1;
        @(posedge clk);
        start = 0;
        
        $display("Softmax computation started...");
        
        // Wait for completion with timeout
        fork
            begin: wait_valid
                wait(valid_out);
                disable timeout;
            end
            begin: timeout
                #100000; // 100us timeout
                $display("¿ TIMEOUT: Softmax did not complete");
                disable wait_valid;
            end
        join
        
        if (valid_out) begin
            $display("¿ Softmax completed successfully!");
            
            // Unpack and analyze results
            sum_check = 0.0;
            for (i = 0; i < 64; i = i + 1) begin
                softmax_results[i] = s5p10_to_real(softmax_out[i*16 +: 16]);
                sum_check = sum_check + softmax_results[i];
            end
            
            $display("Output sum: %.6f (should be ~1.0)", sum_check);
            $display("First 8 values: %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f", 
                     softmax_results[0], softmax_results[1], softmax_results[2], softmax_results[3],
                     softmax_results[4], softmax_results[5], softmax_results[6], softmax_results[7]);
            
            // Check if sum is close to 1.0
            if (sum_check > 0.95 && sum_check < 1.05) begin
                $display("¿ PASS: Sum within acceptable range");
            end else begin
                $display("¿ FAIL: Sum not normalized properly");
            end
            
            // Check if all values are positive
            min_val = softmax_results[0];
            max_val = softmax_results[0];
            for (i = 1; i < 64; i = i + 1) begin
                if (softmax_results[i] < min_val) min_val = softmax_results[i];
                if (softmax_results[i] > max_val) max_val = softmax_results[i];
            end
            
            if (min_val >= 0.0) begin
                $display("¿ PASS: All values non-negative");
            end else begin
                $display("¿ FAIL: Negative values found");
            end
            
            $display("Result range: %.6f to %.6f", min_val, max_val);
        end
        
        // Wait for valid to go low
        @(posedge clk);
    end
endtask

// =========================================== 
// Main test sequence
// ===========================================
initial begin
    $display("===========================================");
    $display("Complete Softmax System Testbench");
    $display("Testing full QK^T ¿ Softmax pipeline");
    $display("===========================================");
    
    // Initialize
    rst_n = 0;
    start = 0;
    qk_input = 0;
    
    // Reset sequence
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(3) @(posedge clk);
    
    // Test 1: All equal values
    $display("\nSetting up Test 1: All equal values...");
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = 1.0;
    end
    run_softmax_test("Test 1: All Equal Values (1.0)");
    
    // Test 2: Incremental values
    $display("\nSetting up Test 2: Incremental values...");
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = i * 0.1;
    end
    run_softmax_test("Test 2: Incremental Values (0.0 to 6.3)");
    
    // Test 3: One hot scenario
    $display("\nSetting up Test 3: One hot scenario...");
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = (i == 32) ? 5.0 : 0.0;
    end
    run_softmax_test("Test 3: One Hot (peak at index 32)");
    
    // Test 4: Mixed positive/negative
    $display("\nSetting up Test 4: Mixed values...");
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = (i < 32) ? -1.0 : 1.0;
    end
    run_softmax_test("Test 4: Mixed Positive/Negative");
    
    // Test 5: Realistic attention scores
    $display("\nSetting up Test 5: Realistic attention...");
    for (i = 0; i < 64; i = i + 1) begin
        // Gaussian-like distribution
        qk_values[i] = 2.0 * $exp(-((i-32.0)*(i-32.0))/(2.0*10.0*10.0));
    end
    run_softmax_test("Test 5: Realistic Attention Pattern");
    
    $display("\n===========================================");
    $display("All Softmax tests completed!");
    $display("===========================================");
    
    $finish;
end

endmodule
