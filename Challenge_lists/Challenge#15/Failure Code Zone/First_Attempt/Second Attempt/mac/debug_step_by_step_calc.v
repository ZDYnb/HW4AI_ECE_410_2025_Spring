// ==========================================
// Debug Step-by-Step Calculation
// Show what each block computes and where it goes
// ==========================================

`timescale 1ns/1ps

module debug_step_by_step_calc;

    reg clk;
    reg rst_n;
    reg start;
    wire done;
    
    // Test matrices
    reg [15:0] matrix_a [0:127][0:127];
    reg [15:0] matrix_b [0:127][0:127];
    wire [262143:0] matrix_a_flat;
    wire [262143:0] matrix_b_flat;
    wire [262143:0] result_flat;
    
    // Monitor result accumulator state
    reg [15:0] result_monitor [0:127][0:127];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT
    matrix_mult_128x128 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .result_flat(result_flat),
        .done(done)
    );
    
    // Array conversion
    generate
        genvar gi, gj;
        for (gi = 0; gi < 128; gi = gi + 1) begin: GEN_ROW
            for (gj = 0; gj < 128; gj = gj + 1) begin: GEN_COL
                assign matrix_a_flat[(gi*128+gj)*16 +: 16] = matrix_a[gi][gj];
                assign matrix_b_flat[(gi*128+gj)*16 +: 16] = matrix_b[gi][gj];
                
                // Monitor result changes
                always @(*) begin
                    result_monitor[gi][gj] = result_flat[(gi*128+gj)*16 +: 16];
                end
            end
        end
    endgenerate
    
    // Create test matrices
    task create_test_matrices;
        integer i, j;
        begin
            $display("=== Creating Test Matrices ===");
            for (i = 0; i < 128; i = i + 1) begin
                for (j = 0; j < 128; j = j + 1) begin
                    if (i == j) begin
                        matrix_a[i][j] = 16'h0001;  // Identity
                    end else begin
                        matrix_a[i][j] = 16'h0000;
                    end
                    matrix_b[i][j] = 16'h0001;      // All ones
                end
            end
            
            $display("Matrix A: 128x128 Identity");
            $display("Matrix B: 128x128 All ones");
            $display("Expected result: All positions should be 0001");
        end
    endtask
    
    // Show what each step should compute
    task show_expected_calculations;
        begin
            $display("\n=== Expected Block Calculations ===");
            $display("2x2 blocks of 64x64 each:");
            $display("");
            
            $display("Step 1: A[0,0] × B[0,0] ¿ C[0,0]");
            $display("  A[0,0] = Identity_top_left (64x64)");  
            $display("  B[0,0] = Ones_top_left (64x64)");
            $display("  Result: Identity × Ones = Ones (all 0001)");
            $display("  Writes to: result[0:63][0:63]");
            
            $display("\nStep 2: A[0,1] × B[1,0] ¿ C[0,0]");
            $display("  A[0,1] = Zeros_top_right (64x64)");
            $display("  B[1,0] = Ones_bottom_left (64x64)");  
            $display("  Result: Zeros × Ones = Zeros (all 0000)");
            $display("  Accumulates to: result[0:63][0:63] (no change)");
            
            $display("\nStep 3: A[0,0] × B[0,1] ¿ C[0,1]");
            $display("  A[0,0] = Identity_top_left (64x64)");
            $display("  B[0,1] = Ones_top_right (64x64)");
            $display("  Result: Identity × Ones = Ones (all 0001)");
            $display("  Writes to: result[0:63][64:127]");
            
            $display("\nStep 4: A[0,1] × B[1,1] ¿ C[0,1]");
            $display("  A[0,1] = Zeros_top_right (64x64)");
            $display("  B[1,1] = Ones_bottom_right (64x64)");
            $display("  Result: Zeros × Ones = Zeros (all 0000)");
            $display("  Accumulates to: result[0:63][64:127] (no change)");
            
            $display("\n... (similar for remaining 4 steps)");
            $display("");
            $display("¿ KEY INSIGHT:");
            $display("After all 8 steps, EVERY position should be exactly 0001");
            $display("If any position ¿ 0001, there's a bug!");
        end
    endtask
    
    // Monitor each step's progress
    task monitor_step_progress;
        input integer step_num;
        begin
            $display("\n=== After Step %0d ===", step_num);
            $display("Key positions:");
            $display("  result[0][0]   = %04h", result_monitor[0][0]);
            $display("  result[0][16]  = %04h", result_monitor[0][16]);
            $display("  result[0][63]  = %04h", result_monitor[0][63]);   // Block boundary
            $display("  result[0][64]  = %04h", result_monitor[0][64]);   // Block boundary  
            $display("  result[0][127] = %04h", result_monitor[0][127]);
            $display("  result[63][0]  = %04h", result_monitor[63][0]);   // Block boundary
            $display("  result[64][0]  = %04h", result_monitor[64][0]);   // Block boundary
            $display("  result[127][0] = %04h", result_monitor[127][0]);
            $display("  result[127][127] = %04h", result_monitor[127][127]);
            
            // Check for unexpected changes
            if (result_monitor[0][16] > 16'h0001) begin
                $display("  ¿  position [0][16] = %04h (> 1!)", result_monitor[0][16]);
            end
            if (result_monitor[0][127] > 16'h0001) begin
                $display("  ¿  position [0][127] = %04h (> 1!)", result_monitor[0][127]);
            end
            if (result_monitor[127][127] > 16'h0001) begin
                $display("  ¿  position [127][127] = %04h (> 1!)", result_monitor[127][127]);
            end
        end
    endtask
    
    // Monitor result changes without accessing internal signals
    reg [15:0] prev_result [0:7][0:7];  // Sample positions
    
    // Sample key positions
    always @(posedge clk) begin
        if (rst_n) begin
            prev_result[0][0] <= result_monitor[0][0];
            prev_result[0][1] <= result_monitor[0][16];
            prev_result[0][2] <= result_monitor[0][32];
            prev_result[0][3] <= result_monitor[0][63];
            prev_result[0][4] <= result_monitor[0][64];
            prev_result[0][5] <= result_monitor[0][127];
            prev_result[1][0] <= result_monitor[16][0];
            prev_result[7][7] <= result_monitor[127][127];
            
            // Detect changes
            if (result_monitor[0][0] != prev_result[0][0] && result_monitor[0][0] != 16'h0000) begin
                $display("CHANGE DETECTED: result[0][0] changed to %04h at time %0dns", result_monitor[0][0], $time);
            end
            if (result_monitor[0][16] != prev_result[0][1] && result_monitor[0][16] != 16'h0000) begin
                $display("CHANGE DETECTED: result[0][16] changed to %04h at time %0dns", result_monitor[0][16], $time);
            end
            if (result_monitor[0][127] != prev_result[0][5] && result_monitor[0][127] != 16'h0000) begin
                $display("CHANGE DETECTED: result[0][127] changed to %04h at time %0dns", result_monitor[0][127], $time);
            end
            if (result_monitor[127][127] != prev_result[7][7] && result_monitor[127][127] != 16'h0000) begin
                $display("CHANGE DETECTED: result[127][127] changed to %04h at time %0dns", result_monitor[127][127], $time);
            end
        end
    end
    
    // Main test
    initial begin
        $display("=== Step-by-Step Calculation Debug ===");
        
        // Initialize
        rst_n = 1'b0;
        start = 1'b0;
        
        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        
        // Create test data and show expectations
        create_test_matrices();
        show_expected_calculations();
        
        $display("\n=== Starting Computation ===");
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        // Monitor computation progress  
        fork
            begin
                wait(done);
                $display("\n¿ Computation completed!");
            end
            
            begin
                while (!done) begin
                    #10000000;  // Check every 10ms
                    if (!done) begin
                        $display("\nProgress check at time %0dns:", $time);
                        monitor_step_progress(0);  // Show current state
                    end
                end
            end
        join
        
        // Final summary
        $display("\n=== Final Analysis ===");
        monitor_step_progress(8);  // Final state
        
        $display("\n¿ Debug Summary:");
        $display("Watch for:");
        $display("  1. When do values first become > 0001?");
        $display("  2. Which accumulation step causes the problem?");
        $display("  3. Are values increasing with each step?");
        
        $finish;
    end
    
    // Timeout
    initial begin
        #300000000;
        $display("Test timeout!");
        $finish;
    end

endmodule
