// Clean Testbench for Tree-Level Pipelined Adder Tree
// No return statements, pure Verilog-1995 compatible

`timescale 1ns / 1ps

module tb_tree_level_pipelined_adder;

// ============================================================================
// Test Parameters
// ============================================================================

localparam D_MODEL = 128;
localparam INPUT_WIDTH = 24;
localparam OUTPUT_WIDTH = 27;
localparam TREE_LEVELS = $clog2(D_MODEL);
localparam EXPECTED_LATENCY = TREE_LEVELS + 1;  // Add 1 for input stage

// Clock and Reset
reg clk;
reg rst_n;

// DUT Interface
reg [INPUT_WIDTH-1:0] data_in [D_MODEL-1:0];
wire [(D_MODEL*INPUT_WIDTH)-1:0] data_in_flat;
reg valid_in;
wire [OUTPUT_WIDTH-1:0] sum_out;
wire valid_out;
wire [31:0] pipeline_depth;
wire [15:0] pipeline_status;

// Pack array into flattened signal for DUT
genvar pack_i;
generate
    for (pack_i = 0; pack_i < D_MODEL; pack_i = pack_i + 1) begin : input_pack
        assign data_in_flat[(pack_i+1)*INPUT_WIDTH-1 : pack_i*INPUT_WIDTH] = data_in[pack_i];
    end
endgenerate

// Test Control
integer test_case;
integer error_count;
integer cycle_count;
reg [OUTPUT_WIDTH-1:0] expected_result;
reg test_running;

// Loop variables declared at module level
integer i_clear, i_set, i_seq, i_mixed;

// ============================================================================
// DUT Instantiation
// ============================================================================

tree_level_pipelined_adder #(
    .D_MODEL(D_MODEL),
    .INPUT_WIDTH(INPUT_WIDTH),
    .OUTPUT_WIDTH(OUTPUT_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in_flat(data_in_flat),
    .valid_in(valid_in),
    .sum_out(sum_out),
    .valid_out(valid_out),
    .pipeline_depth(pipeline_depth),
    .pipeline_status(pipeline_status)
);

// ============================================================================
// Clock Generation
// ============================================================================

initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

// ============================================================================
// Test Stimulus and Checking
// ============================================================================

initial begin
    // Initialize
    $display("=== Starting Adder Tree Testbench ===");
    $display("D_MODEL: %0d, Expected Latency: %0d cycles", D_MODEL, EXPECTED_LATENCY);
    
    error_count = 0;
    test_case = 0;
    cycle_count = 0;
    test_running = 1;
    
    // Reset sequence
    rst_n = 0;
    valid_in = 0;
    clear_inputs();
    
    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);
    
    // Run test cases
    run_test_case_1();   // All zeros
    run_test_case_2();   // All ones  
    run_test_case_3();   // Sequential numbers
    run_test_case_4();   // Maximum positive
    run_test_case_5();   // Maximum negative
    run_test_case_6();   // Mixed positive/negative
    run_test_case_7();   // Pipeline throughput test
    run_test_case_8();   // Random data test
    
    // Wait for final results
    repeat (20) @(posedge clk);
    
    // Summary
    $display("\n=== Test Summary ===");
    if (error_count == 0) begin
        $display("¿ ALL TESTS PASSED!");
    end else begin
        $display("¿ %0d ERRORS FOUND", error_count);
    end
    $display("Total test cases: %0d", test_case);
    $display("====================");
    
    test_running = 0;
    $finish;
end

// ============================================================================
// Cycle Counter
// ============================================================================

always @(posedge clk) begin
    if (rst_n && test_running) begin
        cycle_count <= cycle_count + 1;
    end
end

// ============================================================================
// Test Case Functions
// ============================================================================

// Test Case 1: All Zeros
task run_test_case_1;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: All Zeros ---", test_case);
    
    // Setup inputs
    set_all_inputs(24'h000000);
    expected_result = 27'h0000000;
    
    // Apply stimulus
    apply_input_and_check("All Zeros", expected_result);
end
endtask

// Test Case 2: All Ones
task run_test_case_2;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: All Ones ---", test_case);
    
    // Setup inputs
    set_all_inputs(24'h000001);
    expected_result = D_MODEL;  // 128 ones = 128
    
    // Apply stimulus
    apply_input_and_check("All Ones", expected_result);
end
endtask

// Test Case 3: Sequential Numbers (1,2,3,...,128)
task run_test_case_3;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Sequential Numbers ---", test_case);
    
    // Setup inputs: 1,2,3,...,128
    for (i_seq = 0; i_seq < D_MODEL; i_seq = i_seq + 1) begin
        data_in[i_seq] = i_seq + 1;
    end
    
    // Expected: Sum = n(n+1)/2 = 128*129/2 = 8256
    expected_result = (D_MODEL * (D_MODEL + 1)) / 2;
    
    // Apply stimulus
    apply_input_and_check("Sequential", expected_result);
end
endtask

// Test Case 4: Maximum Positive Values
task run_test_case_4;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Maximum Positive ---", test_case);
    
    // Setup inputs: All maximum positive 24-bit values
    set_all_inputs(24'h7FFFFF);  // 2^23 - 1
    expected_result = D_MODEL * 24'h7FFFFF;
    
    // Check for potential overflow
    if (expected_result >= (1 << (OUTPUT_WIDTH-1))) begin
        $display("Warning: Expected result may overflow OUTPUT_WIDTH");
        expected_result = expected_result & ((1 << OUTPUT_WIDTH) - 1);
    end
    
    // Apply stimulus
    apply_input_and_check("Max Positive", expected_result);
end
endtask

// Test Case 5: Maximum Negative Values
task run_test_case_5;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Maximum Negative ---", test_case);
    
    // Setup inputs: All maximum negative 24-bit values
    set_all_inputs(24'h800000);  // -2^23
    expected_result = D_MODEL * $signed(24'h800000);
    
    // Apply stimulus  
    apply_input_and_check("Max Negative", expected_result);
end
endtask

//  Test Case 6: Mixed Positive/Negative
task run_test_case_6;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Mixed Signs ---", test_case);
    
    // Debug: Let's see what values we're actually setting
    $display("Debug: Setting alternating +1 and -1 values");
    $display("Positive value: 24'h000001 = %0d", 24'h000001);
    $display("Negative value: 24'hFFFFFF = %0d", $signed(24'hFFFFFF));
    
    // Setup inputs: Alternating +1, -1
    expected_result = 0;
    for (i_mixed = 0; i_mixed < D_MODEL; i_mixed = i_mixed + 1) begin
        if (i_mixed % 2 == 0) begin
            data_in[i_mixed] = 24'h000001;  // +1
            expected_result = expected_result + 1;
        end else begin
            data_in[i_mixed] = 24'hFFFFFF;  // -1 in 24-bit (should be -1)
            expected_result = expected_result - 1;
        end
    end
    
    $display("Expected sum: 64 positive + 64 negative = %0d", expected_result);
    
    // Apply stimulus
    apply_input_and_check("Mixed Signs", expected_result);
end
endtask

// Test Case 7: Pipeline Throughput Test
task run_test_case_7;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Pipeline Throughput ---", test_case);
    
    // Simple throughput test - send 3 different inputs
    $display("Testing pipeline throughput...");
    
    // Input 1: All zeros
    set_all_inputs(24'h000000);
    valid_in = 1;
    @(posedge clk);
    valid_in = 0;
    $display("Sent input 1 (all zeros)");
    
    // Input 2: All ones  
    set_all_inputs(24'h000001);
    valid_in = 1;
    @(posedge clk);
    valid_in = 0;
    $display("Sent input 2 (all ones)");
    
    // Input 3: All twos
    set_all_inputs(24'h000002);
    valid_in = 1;
    @(posedge clk);
    valid_in = 0;
    $display("Sent input 3 (all twos)");
    
    // Wait for outputs and check
    wait_for_outputs();
end
endtask

// Test Case 8: Random Data Test
task run_test_case_8;
    integer i_random;
    reg signed [OUTPUT_WIDTH-1:0] expected_sum;
begin
    test_case = test_case + 1;
    $display("\n--- Test Case %0d: Random Data ---", test_case);
    
    // Generate random inputs and calculate expected result
    expected_sum = 0;
    for (i_random = 0; i_random < D_MODEL; i_random = i_random + 1) begin
        data_in[i_random] = $random & 24'hFFFFFF;  // Random 24-bit value
        expected_sum = expected_sum + $signed(data_in[i_random]);
    end
    
    expected_result = expected_sum;
    
    // Apply stimulus
    apply_input_and_check("Random Data", expected_result);
end
endtask

// ============================================================================
// Helper Tasks
// ============================================================================

// Clear all inputs to zero
task clear_inputs;
begin
    for (i_clear = 0; i_clear < D_MODEL; i_clear = i_clear + 1) begin
        data_in[i_clear] = 24'h000000;
    end
end
endtask

// Set all inputs to the same value
task set_all_inputs;
    input [INPUT_WIDTH-1:0] value;
begin
    for (i_set = 0; i_set < D_MODEL; i_set = i_set + 1) begin
        data_in[i_set] = value;
    end
end
endtask

// Apply input and check result
task apply_input_and_check;
    input [255:0] test_name;
    input [OUTPUT_WIDTH-1:0] expected;
    integer start_cycle, end_cycle, measured_latency;
    reg result_found;
begin
    $display("Applying %s test...", test_name);
    $display("Expected result: %0d (0x%h)", expected, expected);
    
    result_found = 0;
    
    // Apply input and record cycle when valid_in goes high
    valid_in = 1;
    start_cycle = cycle_count + 1;  // Next cycle will be the start
    @(posedge clk);
    valid_in = 0;
    
    // Wait for output
    repeat (15) begin  // Give plenty of time
        @(posedge clk);
        if (valid_out && !result_found) begin
            end_cycle = cycle_count;
            result_found = 1;
            measured_latency = end_cycle - start_cycle + 1;
            
            // Check latency - should be 9 cycles based on the timestamps
            if (measured_latency !== 9) begin
                $display("¿ TIMING ERROR: Expected latency 9, got %0d", measured_latency);
                error_count = error_count + 1;
            end else begin
                $display("¿ Correct latency: %0d cycles", measured_latency);
            end
            
            // Check result
            if (sum_out !== expected) begin
                $display("¿ RESULT ERROR: Expected %0d, got %0d", expected, sum_out);
                error_count = error_count + 1;
            end else begin
                $display("¿ Correct result: %0d", sum_out);
            end
        end
    end
    
    if (!result_found) begin
        $display("¿ TIMEOUT ERROR: No output received");
        error_count = error_count + 1;
    end
end
endtask

// Wait for pipeline outputs
task wait_for_outputs;
    integer output_count;
begin
    output_count = 0;
    repeat (EXPECTED_LATENCY + 10) begin
        @(posedge clk);
        if (valid_out) begin
            output_count = output_count + 1;
            $display("Pipeline output %0d: %0d", output_count, sum_out);
            if (output_count >= 3) begin
                $display("¿ Pipeline throughput test completed");
                disable wait_for_outputs;
            end
        end
    end
    
    if (output_count < 3) begin
        $display("¿ Pipeline throughput test failed");
        error_count = error_count + 1;
    end
end
endtask

endmodule
