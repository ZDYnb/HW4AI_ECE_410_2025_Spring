// ==========================================
// Simple Debug: Just Add More Monitoring
// Add detailed prints to your existing system
// ==========================================

`timescale 1ns/1ps

module debug_simple;

    // Test signals (same as your working test)
    reg clk;
    reg rst_n;
    reg start;
    wire done;
    
    // Same matrices as before
    localparam MATRIX_SIZE = 128;
    localparam DATA_WIDTH = 16;
    localparam TOTAL_BITS = DATA_WIDTH * MATRIX_SIZE * MATRIX_SIZE;
    
    reg [15:0] matrix_a [0:127][0:127];
    reg [15:0] matrix_b [0:127][0:127];
    reg [15:0] result [0:127][0:127];
    
    wire [TOTAL_BITS-1:0] matrix_a_flat;
    wire [TOTAL_BITS-1:0] matrix_b_flat;
    wire [TOTAL_BITS-1:0] result_flat;
    
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
    
    // Array conversion (using generate to avoid syntax issues)
    generate
        genvar gi, gj;
        for (gi = 0; gi < 128; gi = gi + 1) begin: GEN_ROW
            for (gj = 0; gj < 128; gj = gj + 1) begin: GEN_COL
                assign matrix_a_flat[(gi*128+gj)*16 +: 16] = matrix_a[gi][gj];
                assign matrix_b_flat[(gi*128+gj)*16 +: 16] = matrix_b[gi][gj];
                assign result[gi][gj] = result_flat[(gi*128+gj)*16 +: 16];
            end
        end
    endgenerate
    
    // Create test matrices
    task create_test_matrices;
        integer i, j;
        begin
            $display("Creating Identity × Ones test...");
            for (i = 0; i < 128; i = i + 1) begin
                for (j = 0; j < 128; j = j + 1) begin
                    // Matrix A: Identity
                    if (i == j) begin
                        matrix_a[i][j] = 16'h0001;
                    end else begin
                        matrix_a[i][j] = 16'h0000;
                    end
                    // Matrix B: All ones
                    matrix_b[i][j] = 16'h0001;
                end
            end
        end
    endtask
    
    // Monitor specific positions during computation
    task monitor_key_positions;
        begin
            $display("\n=== Monitoring Key Positions ===");
            $display("Time: %0dns", $time);
            $display("Position [0][0]:   %04h", result[0][0]);
            $display("Position [0][16]:  %04h", result[0][16]);  // This was 0002
            $display("Position [0][32]:  %04h", result[0][32]);  // This was 0002
            $display("Position [0][127]: %04h", result[0][127]); // This was 0004
            $display("Position [16][0]:  %04h", result[16][0]);  // This was 0002
            $display("Position [127][0]: %04h", result[127][0]); // This was 0005
            $display("Position [127][127]: %04h", result[127][127]); // This was 0007
        end
    endtask
    
    // Check what each position SHOULD be
    task analyze_expected_values;
        begin
            $display("\n=== Expected Value Analysis ===");
            $display("For Identity × Ones, EVERY position should be 0001");
            $display("Because:");
            $display("  Row 0: [1 0 0 ... 0] × [1 1 1 ... 1]¿ = [1 1 1 ... 1]");
            $display("  Row 1: [0 1 0 ... 0] × [1 1 1 ... 1]¿ = [1 1 1 ... 1]");
            $display("  etc.");
            $display("");
            $display("If any position ¿ 0001, there's a bug!");
        end
    endtask
    
    // Main test
    initial begin
        $display("=== Simple Debug: Monitor Your Existing System ===");
        
        // Initialize
        rst_n = 1'b0;
        start = 1'b0;
        
        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        
        // Create test data
        create_test_matrices();
        analyze_expected_values();
        
        // Start computation
        $display("\nStarting computation...");
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        // Monitor during computation
        fork
            // Wait for completion
            begin
                wait(done);
                $display("\n¿ Computation completed!");
            end
            
            // Monitor progress
            begin
                while (!done) begin
                    #2000000;  // Check every 2ms
                    if (!done) monitor_key_positions();
                end
            end
        join
        
        // Final analysis
        monitor_key_positions();
        
        $display("\n=== Final Debug Analysis ===");
        
        analyze_results();
        
        $finish;
    end
    
    // Analyze results task
    task analyze_results;
        integer errors;
        integer samples; 
        integer i, j;
        begin
            errors = 0;
            samples = 0;
            
            // Check a grid of positions
            for (i = 0; i < 128; i = i + 16) begin
                for (j = 0; j < 128; j = j + 16) begin
                    samples = samples + 1;
                    if (result[i][j] != 16'h0001) begin
                        errors = errors + 1;
                        $display("ERROR [%0d][%0d]: got %04h, expected 0001 (factor: %0d)", 
                               i, j, result[i][j], result[i][j]);
                    end
                end
            end
            
            $display("\nSummary: %0d errors out of %0d sample positions", errors, samples);
            
            if (errors == 0) begin
                $display("¿ NO ERRORS FOUND! Your system might be working correctly!");
                $display("    Maybe the previous test had wrong expectations?");
            end else begin
                $display("¿ CONFIRMED: %0d positions have wrong values", errors);
                $display("    The bug is real and needs to be fixed");
                
                $display("\n¿ Error Pattern Analysis:");
                if (result[0][16] > 16'h0001) $display("  - Position [0][16] = %04h (× %0d)", result[0][16], result[0][16]);
                if (result[0][127] > 16'h0001) $display("  - Position [0][127] = %04h (× %0d)", result[0][127], result[0][127]);
                if (result[127][127] > 16'h0001) $display("  - Position [127][127] = %04h (× %0d)", result[127][127], result[127][127]);
                
                $display("\n¿ Next Debug Steps:");
                $display("  1. Check if Result Accumulator is writing to wrong positions");
                $display("  2. Check if some blocks are processed multiple times");
                $display("  3. Check if there's overlap in block boundaries");
            end
        end
    endtask
    
    
endmodule
