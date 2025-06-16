// ===========================================
// Test Systolic Array Output Format
// ===========================================
`timescale 1ns/1ps

module test_systolic_output_format;

parameter ARRAY_SIZE = 2;
parameter DATA_WIDTH = 16;
parameter WEIGHT_WIDTH = 8;
parameter ACCUM_WIDTH = 32;
parameter CLK_PERIOD = 10;

reg clk, rst_n, start;
reg [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
reg [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;
wire done;
wire result_valid;
wire [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

// DUT
systolic_array_top #(
    .ARRAY_SIZE(ARRAY_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .ACCUM_WIDTH(ACCUM_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .matrix_a_flat(matrix_a_flat),
    .matrix_b_flat(matrix_b_flat),
    .done(done),
    .result_valid(result_valid),
    .result_flat(result_flat)
);

// Clock
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    $display("=== Systolic Array Output Format Test ===");
    $display("Expected output width: %0d bits", DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE);
    $display("Actual output width: %0d bits", $bits(result_flat));
    
    // Check if port is correctly declared
    if ($bits(result_flat) == 64) begin
        $display("¿ Output width is correct (64 bits for 2x2x16)");
    end else begin
        $display("¿ Output width is wrong! Got %0d bits", $bits(result_flat));
    end
    
    rst_n = 0;
    start = 0;
    
    // Set simple inputs
    matrix_a_flat = 64'h0400000000000400; // 1.0 at [0][0] and [1][1]
    matrix_b_flat = 32'h40000040;         // 1.0 at [0][0] and [1][1]
    
    #30 rst_n = 1;
    #10 start = 1;
    #10 start = 0;
    
    wait(done);
    #20;
    
    $display("\nResults after computation:");
    $display("Raw result_flat: 0x%016h", result_flat);
    $display("Bit breakdown:");
    $display("  [15:0]:  0x%04h", result_flat[15:0]);
    $display("  [31:16]: 0x%04h", result_flat[31:16]);
    $display("  [47:32]: 0x%04h", result_flat[47:32]);
    $display("  [63:48]: 0x%04h", result_flat[63:48]);
    
    // Check PE internal results
    $display("\nPE Internal Results (before conversion):");
    $display("  PE[0][0]: 0x%08h", dut.PE_ROW[0].PE_COL[0].pe_inst.result);
    $display("  PE[1][1]: 0x%08h", dut.PE_ROW[1].PE_COL[1].pe_inst.result);
    
    $finish;
end

endmodule
