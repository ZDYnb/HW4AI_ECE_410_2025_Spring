// ===========================================
// Simple Debug Testbench for Systolic Array
// ===========================================
`timescale 1ns/1ps

module tb_debug_simple;

// ===========================================
// Parameters
// ===========================================
parameter ARRAY_SIZE = 2;              // Very small array for debugging
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
wire [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat;

// Helper arrays
reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

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
// Test Stimulus
// ===========================================
initial begin
    $display("=== Simple Debug Test ===");
    $display("Array Size: %0d x %0d", ARRAY_SIZE, ARRAY_SIZE);
    
    // Initialize
    rst_n = 0;
    start = 0;
    
    // Set up simple 2x2 matrices
    // A = [1, 2]    B = [1, 0]
    //     [3, 4]        [0, 1]
    // Expected result = [1, 2]
    //                   [3, 4]
    
    matrix_a[0][0] = 16'd1; matrix_a[0][1] = 16'd2;
    matrix_a[1][0] = 16'd3; matrix_a[1][1] = 16'd4;
    
    matrix_b[0][0] = 8'd1; matrix_b[0][1] = 8'd0;
    matrix_b[1][0] = 8'd0; matrix_b[1][1] = 8'd1;
    
    // Flatten matrices
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
            matrix_a_flat[(i*ARRAY_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = matrix_a[i][j];
            matrix_b_flat[(i*ARRAY_SIZE+j)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = matrix_b[i][j];
        end
    end
    
    $display("Matrix A:");
    $display("  %0d  %0d", matrix_a[0][0], matrix_a[0][1]);
    $display("  %0d  %0d", matrix_a[1][0], matrix_a[1][1]);
    
    $display("Matrix B:");
    $display("  %0d  %0d", matrix_b[0][0], matrix_b[0][1]);
    $display("  %0d  %0d", matrix_b[1][0], matrix_b[1][1]);
    
    $display("Expected Result:");
    $display("  %0d  %0d", matrix_a[0][0]*matrix_b[0][0] + matrix_a[0][1]*matrix_b[1][0], 
                           matrix_a[0][0]*matrix_b[0][1] + matrix_a[0][1]*matrix_b[1][1]);
    $display("  %0d  %0d", matrix_a[1][0]*matrix_b[0][0] + matrix_a[1][1]*matrix_b[1][0], 
                           matrix_a[1][0]*matrix_b[0][1] + matrix_a[1][1]*matrix_b[1][1]);
    
    // Reset sequence
    #(CLK_PERIOD * 3);
    rst_n = 1;
    #(CLK_PERIOD);
    
    // Start computation
    $display("\nStarting computation...");
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    
    // Wait for done and add extra cycles to see final state
    wait(done);
    #(CLK_PERIOD * 5); // More settling time
    
    // Extract results
    $display("\nActual Result:");
    $display("  %0d  %0d", 
        $signed(result_flat[(0*ARRAY_SIZE+0)*ACCUM_WIDTH +: ACCUM_WIDTH]),
        $signed(result_flat[(0*ARRAY_SIZE+1)*ACCUM_WIDTH +: ACCUM_WIDTH]));
    $display("  %0d  %0d", 
        $signed(result_flat[(1*ARRAY_SIZE+0)*ACCUM_WIDTH +: ACCUM_WIDTH]),
        $signed(result_flat[(1*ARRAY_SIZE+1)*ACCUM_WIDTH +: ACCUM_WIDTH]));
    
    // Debug internal signals
    $display("\nDebug Info:");
    $display("Computing: %b", dut.computing);
    $display("Input cycle: %0d", dut.input_cycle);
    $display("Compute counter: %0d", dut.compute_counter);
    
    // Check data injection at array boundaries
    $display("\nData Injection Debug:");
    $display("data_horizontal[0][0]: %0d, valid: %b", dut.data_horizontal[0][0], dut.data_valid_horizontal[0][0]);
    $display("data_horizontal[1][0]: %0d, valid: %b", dut.data_horizontal[1][0], dut.data_valid_horizontal[1][0]);
    $display("weight_vertical[0][0]: %0d, valid: %b", dut.weight_vertical[0][0], dut.weight_valid_vertical[0][0]);
    $display("weight_vertical[0][1]: %0d, valid: %b", dut.weight_vertical[0][1], dut.weight_valid_vertical[0][1]);
    
    // Check PE[0][0] MAC unit
    $display("\nPE[0][0] Debug:");
    $display("Data valid: %b", dut.PE_ROW[0].PE_COL[0].pe_inst.data_valid);
    $display("Weight valid: %b", dut.PE_ROW[0].PE_COL[0].pe_inst.weight_valid);
    $display("Accumulate_en: %b", dut.PE_ROW[0].PE_COL[0].pe_inst.accumulate_en);
    $display("Computing signal: %b", dut.computing);
    $display("MAC enable: %b", dut.PE_ROW[0].PE_COL[0].pe_inst.mac_enable);
    $display("MAC result: %0d", dut.PE_ROW[0].PE_COL[0].pe_inst.mac_result);
    
    #(CLK_PERIOD * 5);
    $finish;
end

// Monitor key signals
initial begin
    $monitor("Time: %0t | Computing: %b | Input_cycle: %0d | PE[0][0] data_in: %0d | weight_in: %0d | data_valid: %b | weight_valid: %b | mac_enable: %b | result: %0d", 
             $time, dut.computing, dut.input_cycle, 
             dut.PE_ROW[0].PE_COL[0].pe_inst.data_in,
             dut.PE_ROW[0].PE_COL[0].pe_inst.weight_in,
             dut.PE_ROW[0].PE_COL[0].pe_inst.data_valid,
             dut.PE_ROW[0].PE_COL[0].pe_inst.weight_valid,
             dut.PE_ROW[0].PE_COL[0].pe_inst.mac_enable,
             dut.PE_ROW[0].PE_COL[0].pe_inst.result);
end

endmodule
