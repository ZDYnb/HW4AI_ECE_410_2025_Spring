// ==========================================
// Debug Systolic Array Signals
// Check actual port widths and signal behavior
// ==========================================

`timescale 1ns/1ps

module debug_systolic_signals;

    // Test signals
    reg clk;
    reg rst_n;
    reg start;
    wire computation_done;
    wire result_valid;
    
    // Use minimal size to check port widths
    localparam TEST_SIZE = 4;  // Start with 4x4 to debug
    
    // Try different bit widths to match your systolic array
    wire [16*TEST_SIZE*TEST_SIZE-1:0] matrix_a_flat;   // 16-bit data
    wire [8*TEST_SIZE*TEST_SIZE-1:0] matrix_b_flat;    // 8-bit weights  
    wire [32*TEST_SIZE*TEST_SIZE-1:0] result_flat;     // 32-bit results
    
    // Test matrices
    reg [15:0] matrix_a [0:TEST_SIZE-1][0:TEST_SIZE-1];
    reg [7:0] matrix_b [0:TEST_SIZE-1][0:TEST_SIZE-1];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Array conversion  
    generate
        genvar gi, gj;
        for (gi = 0; gi < TEST_SIZE; gi = gi + 1) begin: GEN_ROW
            for (gj = 0; gj < TEST_SIZE; gj = gj + 1) begin: GEN_COL
                assign matrix_a_flat[(gi*TEST_SIZE+gj)*16 +: 16] = matrix_a[gi][gj];
                assign matrix_b_flat[(gi*TEST_SIZE+gj)*8 +: 8] = matrix_b[gi][gj];
            end
        end
    endgenerate
    
    // DUT instantiation - using correct parameters
    systolic_array_top #(
        .ARRAY_SIZE(TEST_SIZE),
        .DATA_WIDTH(16),
        .WEIGHT_WIDTH(8),
        .ACCUM_WIDTH(32)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .matrix_a_flat(matrix_a_flat),
        .matrix_b_flat(matrix_b_flat),
        .result_flat(result_flat),
        .computation_done(computation_done),
        .result_valid(result_valid)
    );
    
    // Create simple test data
    task create_simple_data;
        integer i, j;
        begin
            for (i = 0; i < TEST_SIZE; i = i + 1) begin
                for (j = 0; j < TEST_SIZE; j = j + 1) begin
                    if (i == 0 && j == 0) begin
                        matrix_a[i][j] = 16'h0001;
                    end else begin
                        matrix_a[i][j] = 16'h0000;
                    end
                    matrix_b[i][j] = 8'h01;
                end
            end
        end
    endtask
    
    // Monitor signals
    initial begin
        $display("=== Systolic Array Signal Debug ===");
        $display("Testing with %0dx%0d array", TEST_SIZE, TEST_SIZE);
        $display("Matrix A width: %0d bits", $bits(matrix_a_flat));
        $display("Matrix B width: %0d bits", $bits(matrix_b_flat));
        $display("Result width: %0d bits", $bits(result_flat));
        
        // Initialize
        rst_n = 1'b0;
        start = 1'b0;
        create_simple_data();
        
        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        $display("\nT=%0d: Starting systolic array test", $time);
        $display("Initial signals:");
        $display("  start = %b", start);
        $display("  computation_done = %b", computation_done);
        $display("  result_valid = %b", result_valid);
        $display("  rst_n = %b", rst_n);
        
        // Start computation
        start = 1'b1;
        @(posedge clk);
        $display("\nT=%0d: Start asserted", $time);
        $display("  start = %b", start);
        $display("  computation_done = %b", computation_done);
        $display("  result_valid = %b", result_valid);
        
        start = 1'b0;
        @(posedge clk);
        $display("\nT=%0d: Start deasserted", $time);
        $display("  start = %b", start);
        $display("  computation_done = %b", computation_done);
        $display("  result_valid = %b", result_valid);
        
        // Monitor for 50 cycles
        repeat(50) begin
            @(posedge clk);
            if (computation_done) begin
                $display("\nT=%0d: ¿ Computation completed!", $time);
                $display("  computation_done = %b", computation_done);
                $display("  result_valid = %b", result_valid);
                $display("  Sample result[0] = %08h", result_flat[31:0]);
                $finish;
            end
            
            // Print status every 10 cycles
            if (($time / 10) % 10 == 0) begin
                $display("T=%0d: computation_done=%b, result_valid=%b", $time, computation_done, result_valid);
            end
        end
        
        $display("\nT=%0d: ¿ No completion signal after 50 cycles", $time);
        $display("Final signals:");
        $display("  computation_done = %b", computation_done);
        $display("  result_valid = %b", result_valid);
        
        $display("\n¿ Debug Summary:");
        $display("- If computation_done never goes high, the systolic array isn't working");
        $display("- Check if your systolic_array_top module has the expected interface");
        $display("- Check if the array size parameters are correct");
        
        $finish;
    end
    
    // Safety timeout
    initial begin
        #10000;
        $display("ERROR: Debug timeout!");
        $finish;
    end

endmodule
