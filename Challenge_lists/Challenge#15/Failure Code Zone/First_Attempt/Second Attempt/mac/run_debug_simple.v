// Simple debug test without parameter issues
`timescale 1ns/1ps

module run_debug_simple;

    reg clk;
    reg rst_n;
    reg start;
    wire done;
    
    reg [15:0] matrix_a [0:127][0:127];
    reg [15:0] matrix_b [0:127][0:127];
    wire [262143:0] matrix_a_flat;
    wire [262143:0] matrix_b_flat;
    wire [262143:0] result_flat;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT - use default parameters
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
            end
        end
    endgenerate
    
    // Create test matrices
    initial begin
        integer i, j;
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
    end
    
    // Main test
    initial begin
        $display("=== Simple Debug Test ===");
        
        // Initialize
        rst_n = 1'b0;
        start = 1'b0;
        
        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        
        $display("Starting computation...");
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        // Wait for completion
        wait(done);
        $display("Computation completed!");
        
        // Check results
        $display("Final results:");
        $display("  result[0][0]   = %04h", result_flat[0*128*16 + 0*16 +: 16]);
        $display("  result[0][16]  = %04h", result_flat[0*128*16 + 16*16 +: 16]);
        $display("  result[0][127] = %04h", result_flat[0*128*16 + 127*16 +: 16]);
        $display("  result[127][127] = %04h", result_flat[127*128*16 + 127*16 +: 16]);
        
        $finish;
    end
    
    // Timeout
    initial begin
        #300000000;
        $display("Test timeout!");
        $finish;
    end

endmodule
