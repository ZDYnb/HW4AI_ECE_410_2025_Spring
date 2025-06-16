// ===========================================
// Debug Testbench for Fixed Point Issues
// ===========================================
`timescale 1ns/1ps

module tb_debug_fixed_point;

// ===========================================
// Parameters
// ===========================================
parameter ARRAY_SIZE = 2;              // Very small for debugging
parameter DATA_WIDTH = 16;
parameter WEIGHT_WIDTH = 8;
parameter ACCUM_WIDTH = 32;
parameter CLK_PERIOD = 10;

// ===========================================
// Testbench Signals
// ===========================================
reg clk;
reg rst_n;
reg start;
reg [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat;
reg [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat;
wire done;
wire result_valid;
wire [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

integer i, j;

// ===========================================
// DUT Instantiation
// ===========================================
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

// ===========================================
// Clock Generation
// ===========================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// ===========================================
// Debug Functions
// ===========================================
function real s5_10_to_real;
    input [15:0] val;
    begin
        s5_10_to_real = $itor($signed(val)) / 1024.0;
    end
endfunction

function [15:0] real_to_s5_10;
    input real val;
    begin
        real_to_s5_10 = $rtoi(val * 1024.0);
    end
endfunction

function real s1_6_to_real;
    input [7:0] val;
    begin
        s1_6_to_real = $itor($signed(val)) / 64.0;
    end
endfunction

function [7:0] real_to_s1_6;
    input real val;
    begin
        real_to_s1_6 = $rtoi(val * 64.0);
    end
endfunction

// ===========================================
// Test
// ===========================================
initial begin
    $display("=== Fixed Point Debug Test ===");
    
    // Initialize
    clk = 0;
    rst_n = 0;
    start = 0;
    
    // Set up simple 2x2 identity matrices
    // A = [1, 0]    B = [1, 0]
    //     [0, 1]        [0, 1]
    
    // Convert to fixed point
    matrix_a_flat[15:0]   = real_to_s5_10(1.0);   // A[0][0] = 1.0
    matrix_a_flat[31:16]  = real_to_s5_10(0.0);   // A[0][1] = 0.0
    matrix_a_flat[47:32]  = real_to_s5_10(0.0);   // A[1][0] = 0.0
    matrix_a_flat[63:48]  = real_to_s5_10(1.0);   // A[1][1] = 1.0
    
    matrix_b_flat[7:0]    = real_to_s1_6(1.0);    // B[0][0] = 1.0
    matrix_b_flat[15:8]   = real_to_s1_6(0.0);    // B[0][1] = 0.0
    matrix_b_flat[23:16]  = real_to_s1_6(0.0);    // B[1][0] = 0.0
    matrix_b_flat[31:24]  = real_to_s1_6(1.0);    // B[1][1] = 1.0
    
    $display("Input matrices (fixed point):");
    $display("  A[0][0] = %f (0x%04h)", s5_10_to_real(matrix_a_flat[15:0]), matrix_a_flat[15:0]);
    $display("  A[0][1] = %f (0x%04h)", s5_10_to_real(matrix_a_flat[31:16]), matrix_a_flat[31:16]);
    $display("  A[1][0] = %f (0x%04h)", s5_10_to_real(matrix_a_flat[47:32]), matrix_a_flat[47:32]);
    $display("  A[1][1] = %f (0x%04h)", s5_10_to_real(matrix_a_flat[63:48]), matrix_a_flat[63:48]);
    
    $display("  B[0][0] = %f (0x%02h)", s1_6_to_real(matrix_b_flat[7:0]), matrix_b_flat[7:0]);
    $display("  B[0][1] = %f (0x%02h)", s1_6_to_real(matrix_b_flat[15:8]), matrix_b_flat[15:8]);
    $display("  B[1][0] = %f (0x%02h)", s1_6_to_real(matrix_b_flat[23:16]), matrix_b_flat[23:16]);
    $display("  B[1][1] = %f (0x%02h)", s1_6_to_real(matrix_b_flat[31:24]), matrix_b_flat[31:24]);
    
    // Reset sequence
    #(CLK_PERIOD * 3);
    rst_n = 1;
    #(CLK_PERIOD);
    
    // Start computation
    $display("\nStarting computation...");
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    
    // Wait for done
    wait(done);
    #(CLK_PERIOD * 2);
    
    // Extract and display results
    $display("\nResults:");
    $display("  Result[0][0] = %f (0x%04h)", s5_10_to_real(result_flat[15:0]), result_flat[15:0]);
    $display("  Result[0][1] = %f (0x%04h)", s5_10_to_real(result_flat[31:16]), result_flat[31:16]);
    $display("  Result[1][0] = %f (0x%04h)", s5_10_to_real(result_flat[47:32]), result_flat[47:32]);
    $display("  Result[1][1] = %f (0x%04h)", s5_10_to_real(result_flat[63:48]), result_flat[63:48]);
    
    // Debug the raw result_flat
    $display("\nRaw result_flat: 0x%016h", result_flat);
    
    // Check if internal results are in different positions
    $display("\nAll PE internal results:");
    $display("  PE[0][0]: 0x%08h", dut.PE_ROW[0].PE_COL[0].pe_inst.result);
    $display("  PE[0][1]: 0x%08h", dut.PE_ROW[0].PE_COL[1].pe_inst.result);
    $display("  PE[1][0]: 0x%08h", dut.PE_ROW[1].PE_COL[0].pe_inst.result);
    $display("  PE[1][1]: 0x%08h", dut.PE_ROW[1].PE_COL[1].pe_inst.result);
    
    // Manual calculation of what should happen
    $display("\nManual conversion verification:");
    $display("  PE[0][0] internal: 0x%08h", dut.PE_ROW[0].PE_COL[0].pe_inst.result);
    $display("  Should convert to: 0x%04h", dut.PE_ROW[0].PE_COL[0].pe_inst.result >> 6);
    $display("  Actually got in result_flat[15:0]: 0x%04h", result_flat[15:0]);
    
    $display("  PE[1][1] internal: 0x%08h", dut.PE_ROW[1].PE_COL[1].pe_inst.result);
    $display("  Should convert to: 0x%04h", dut.PE_ROW[1].PE_COL[1].pe_inst.result >> 6);
    $display("  Actually got in result_flat[63:48]: 0x%04h", result_flat[63:48]);
    
    // Debug internal signals
    $display("\nInternal Debug:");
    $display("  Computing: %b", dut.computing);
    $display("  Result valid: %b", dut.result_valid);
    $display("  Done: %b", dut.done);
    
    // Try to access PE results
    $display("  PE[0][0] result: 0x%08h", dut.PE_ROW[0].PE_COL[0].pe_inst.result);
    
    // Manual calculation check
    $display("\nExpected results:");
    $display("  1.0 × 1.0 = 1.0 (should be 0x0400 in S5.10)");
    
    #(CLK_PERIOD * 5);
    $finish;
end

// Monitor key signals
initial begin
    $monitor("Time: %0t | Computing: %b | PE[0][0] data_in: 0x%04h | weight_in: 0x%02h | result: 0x%08h", 
             $time, dut.computing, 
             dut.PE_ROW[0].PE_COL[0].pe_inst.data_in,
             dut.PE_ROW[0].PE_COL[0].pe_inst.weight_in,
             dut.PE_ROW[0].PE_COL[0].pe_inst.result);
end

endmodule
