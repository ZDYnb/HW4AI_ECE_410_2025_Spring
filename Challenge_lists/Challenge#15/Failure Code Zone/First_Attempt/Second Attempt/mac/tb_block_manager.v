// =========================================== 
// Block Manager Testbench
// Verifies the 8-step computation sequence for 128x128 matrix multiplication
// ===========================================

`timescale 1ns/1ps

module tb_block_manager;

// =========================================== 
// Clock and Reset Generation
// ===========================================
reg clk;
reg rst_n;

initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

initial begin
    rst_n = 0;
    #20 rst_n = 1;
end

// =========================================== 
// DUT Interface Signals
// ===========================================
reg start;
wire done;
wire computation_valid;

wire [1:0] a_row_idx, a_col_idx;
wire [1:0] b_row_idx, b_col_idx; 
wire [1:0] c_row_idx, c_col_idx;

wire start_systolic;
reg systolic_done;
wire accumulate_result;
wire [3:0] computation_count;

// =========================================== 
// DUT Instantiation
// ===========================================
block_manager #(
    .BLOCK_SIZE(64)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .done(done),
    .computation_valid(computation_valid),
    .a_row_idx(a_row_idx),
    .a_col_idx(a_col_idx),
    .b_row_idx(b_row_idx),
    .b_col_idx(b_col_idx),
    .c_row_idx(c_row_idx),
    .c_col_idx(c_col_idx),
    .start_systolic(start_systolic),
    .systolic_done(systolic_done),
    .accumulate_result(accumulate_result),
    .computation_count(computation_count)
);

// =========================================== 
// Expected Computation Sequence
// ===========================================
reg [1:0] expected_a_row [0:7];
reg [1:0] expected_a_col [0:7];
reg [1:0] expected_b_row [0:7];
reg [1:0] expected_b_col [0:7];
reg [1:0] expected_c_row [0:7];
reg [1:0] expected_c_col [0:7];

// Initialize expected sequences
initial begin
    expected_a_row[0] = 0; expected_a_row[1] = 0; expected_a_row[2] = 0; expected_a_row[3] = 0;
    expected_a_row[4] = 1; expected_a_row[5] = 1; expected_a_row[6] = 1; expected_a_row[7] = 1;
    
    expected_a_col[0] = 0; expected_a_col[1] = 1; expected_a_col[2] = 0; expected_a_col[3] = 1;
    expected_a_col[4] = 0; expected_a_col[5] = 1; expected_a_col[6] = 0; expected_a_col[7] = 1;
    
    expected_b_row[0] = 0; expected_b_row[1] = 1; expected_b_row[2] = 0; expected_b_row[3] = 1;
    expected_b_row[4] = 0; expected_b_row[5] = 1; expected_b_row[6] = 0; expected_b_row[7] = 1;
    
    expected_b_col[0] = 0; expected_b_col[1] = 0; expected_b_col[2] = 1; expected_b_col[3] = 1;
    expected_b_col[4] = 0; expected_b_col[5] = 0; expected_b_col[6] = 1; expected_b_col[7] = 1;
    
    expected_c_row[0] = 0; expected_c_row[1] = 0; expected_c_row[2] = 0; expected_c_row[3] = 0;
    expected_c_row[4] = 1; expected_c_row[5] = 1; expected_c_row[6] = 1; expected_c_row[7] = 1;
    
    expected_c_col[0] = 0; expected_c_col[1] = 0; expected_c_col[2] = 1; expected_c_col[3] = 1;
    expected_c_col[4] = 0; expected_c_col[5] = 0; expected_c_col[6] = 1; expected_c_col[7] = 1;
end

// =========================================== 
// Simulation Control
// ===========================================
reg [3:0] test_step;
reg [31:0] cycle_count;
integer error_count;

initial begin
    // Initialize signals
    start = 0;
    systolic_done = 0;
    test_step = 0;
    cycle_count = 0;
    error_count = 0;
    
    // Wait for reset deassertion
    wait (rst_n);
    @(posedge clk);
    
    $display("=== Block Manager Testbench Started ===");
    $display("Testing 8-step computation sequence for 128x128 matrix multiplication");
    
    // Test the computation sequence
    test_computation_sequence();
    
    // Final report
    @(posedge clk);
    $display("\n=== Test Summary ===");
    if (error_count == 0) begin
        $display("¿ All tests PASSED!");
    end else begin
        $display("¿ %0d errors found", error_count);
    end
    
    $display("=== Block Manager Testbench Complete ===");
    $finish;
end

// =========================================== 
// Main Test Task
// ===========================================
task test_computation_sequence;
    begin
        $display("\n--- Testing Computation Sequence ---");
        
        // Start the computation
        @(posedge clk);
        start = 1;
        $display("T=%0t: Starting block manager", $time);
        
        @(posedge clk);
        start = 0;
        
        // Process all 8 computations
        for (test_step = 0; test_step < 8; test_step = test_step + 1) begin
            process_computation_step(test_step);
        end
        
        // Wait for done signal
        wait_for_done();
        
        $display("--- Computation Sequence Test Complete ---");
    end
endtask

// =========================================== 
// Process Single Computation Step
// ===========================================
task process_computation_step;
    input [3:0] step;
    begin
        $display("\n¿ Processing Computation Step %0d", step);
        
        // Wait for start_systolic to be asserted
        wait (start_systolic);
        $display("T=%0t: start_systolic asserted for step %0d", $time, step);
        
        // Check indices immediately when computation starts
        @(posedge clk);
        check_indices(step);
        
        // Simulate systolic array computation time (random 10-20 cycles)
        repeat ($random % 11 + 10) @(posedge clk);
        
        // Assert systolic_done
        systolic_done = 1;
        $display("T=%0t: Asserting systolic_done for step %0d", $time, step);
        
        @(posedge clk);
        
        // Debug: Print current state and signals
        $display("  Debug: state=%0d, systolic_done=%0b, accumulate_result=%0b", 
                 dut.state, systolic_done, accumulate_result);
        
        // Check accumulate_result signal (should be high now)
        if (accumulate_result) begin
            $display("T=%0t: accumulate_result asserted for step %0d", $time, step);
        end else begin
            $display("¿ ERROR: accumulate_result not asserted for step %0d", step);
            error_count = error_count + 1;
        end
        
        systolic_done = 0;
        @(posedge clk);
    end
endtask

// =========================================== 
// Check Block Indices
// ===========================================
task check_indices;
    input [3:0] step;
    begin
        $display("  Checking indices for step %0d:", step);
        $display("    A[%0d,%0d] × B[%0d,%0d] ¿ C[%0d,%0d]", 
                 a_row_idx, a_col_idx, b_row_idx, b_col_idx, c_row_idx, c_col_idx);
        
        // Check A indices
        if (a_row_idx !== expected_a_row[step]) begin
            $display("    ¿ ERROR: a_row_idx = %0d, expected %0d", a_row_idx, expected_a_row[step]);
            error_count = error_count + 1;
        end
        
        if (a_col_idx !== expected_a_col[step]) begin
            $display("    ¿ ERROR: a_col_idx = %0d, expected %0d", a_col_idx, expected_a_col[step]);
            error_count = error_count + 1;
        end
        
        // Check B indices  
        if (b_row_idx !== expected_b_row[step]) begin
            $display("    ¿ ERROR: b_row_idx = %0d, expected %0d", b_row_idx, expected_b_row[step]);
            error_count = error_count + 1;
        end
        
        if (b_col_idx !== expected_b_col[step]) begin
            $display("    ¿ ERROR: b_col_idx = %0d, expected %0d", b_col_idx, expected_b_col[step]);
            error_count = error_count + 1;
        end
        
        // Check C indices
        if (c_row_idx !== expected_c_row[step]) begin
            $display("    ¿ ERROR: c_row_idx = %0d, expected %0d", c_row_idx, expected_c_row[step]);
            error_count = error_count + 1;
        end
        
        if (c_col_idx !== expected_c_col[step]) begin
            $display("    ¿ ERROR: c_col_idx = %0d, expected %0d", c_col_idx, expected_c_col[step]);
            error_count = error_count + 1;
        end
        
        // Check computation count
        if (computation_count !== step) begin
            $display("    ¿ ERROR: computation_count = %0d, expected %0d", computation_count, step);
            error_count = error_count + 1;
        end
        
        if (error_count == 0) begin
            $display("    ¿ All indices correct for step %0d", step);
        end
    end
endtask

// =========================================== 
// Wait for Done Signal
// ===========================================
task wait_for_done;
    begin
        $display("\n¿ Waiting for done signal...");
        
        wait (done);
        $display("T=%0t: ¿ Done signal received", $time);
        
        // Verify final state
        @(posedge clk);
        if (computation_count === 7) begin
            $display("¿ Final computation_count = 7 (correct)");
        end else begin
            $display("¿ ERROR: Final computation_count = %0d, expected 7", computation_count);
            error_count = error_count + 1;
        end
        
        @(posedge clk);
    end
endtask

// =========================================== 
// Continuous Monitoring
// ===========================================
always @(posedge clk) begin
    cycle_count <= cycle_count + 1;
    
    if (computation_valid) begin
        // Monitor state during computation
    end
end

// =========================================== 
// Display Expected vs Actual Sequence
// ===========================================
initial begin
    #1;  // Wait for initial block to complete
    $display("\n¿ Expected Computation Sequence:");
    $display("Step | A[r,c] × B[r,c] ¿ C[r,c] | Description");
    $display("-----|------------------------|------------------");
    $display("  0  | A[0,0] × B[0,0] ¿ C[0,0] | First term");
    $display("  1  | A[0,1] × B[1,0] ¿ C[0,0] | Accumulate");
    $display("  2  | A[0,0] × B[0,1] ¿ C[0,1] | First term");
    $display("  3  | A[0,1] × B[1,1] ¿ C[0,1] | Accumulate");
    $display("  4  | A[1,0] × B[0,0] ¿ C[1,0] | First term");
    $display("  5  | A[1,1] × B[1,0] ¿ C[1,0] | Accumulate");
    $display("  6  | A[1,0] × B[0,1] ¿ C[1,1] | First term");
    $display("  7  | A[1,1] × B[1,1] ¿ C[1,1] | Accumulate");
    $display("");
end

// =========================================== 
// Timeout Protection
// ===========================================
initial begin
    #50000;  // 50¿s timeout
    $display("¿ ERROR: Testbench timeout!");
    $finish;
end

endmodule
