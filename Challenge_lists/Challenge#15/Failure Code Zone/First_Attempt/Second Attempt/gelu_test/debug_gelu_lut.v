// =============================================================================
// Debug LUT Address Calculation
// =============================================================================
// Let's create a simple version to debug the address calculation

module debug_gelu_lut #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 10
) (
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] x_in,
    input wire valid_in,
    output reg [5:0] lut_addr,    // Debug: show the calculated address
    output reg [DATA_WIDTH-1:0] gelu_out,
    output reg valid_out,
    output reg out_of_range
);

// Simplified LUT with only a few key values for debugging
reg [DATA_WIDTH-1:0] lut_data [0:63];

initial begin
    // Initialize with simple test pattern first
    // Let's manually calculate a few key points
    
    // x = -4.0 (index 0): GELU ¿ 0
    lut_data[0] = 16'h0000;
    
    // x = -2.0 (index 16): GELU ¿ -0.045
    lut_data[16] = 16'hFFD1;  // -0.045 in Q6.10 = -46
    
    // x = -1.0 (index 24): GELU ¿ -0.159  
    lut_data[24] = 16'hFEDB;  // -0.159 in Q6.10 = -163
    
    // x = 0.0 (index 32): GELU = 0
    lut_data[32] = 16'h0000;
    
    // x = 1.0 (index 40): GELU ¿ 0.841
    lut_data[40] = 16'h0358;  // 0.841 in Q6.10 = 861
    
    // x = 2.0 (index 48): GELU ¿ 1.955  
    lut_data[48] = 16'h07D7;  // 1.955 in Q6.10 = 2007
    
    // Fill rest with zeros for now
    integer i;
    for (i = 1; i < 64; i = i + 1) begin
        if (i != 16 && i != 24 && i != 32 && i != 40 && i != 48) begin
            lut_data[i] = 16'h0000;
        end
    end
end

// Address calculation logic
wire signed [DATA_WIDTH-1:0] x_signed;
wire signed [DATA_WIDTH-1:0] LUT_MIN;
wire signed [DATA_WIDTH-1:0] offset;

assign x_signed = x_in;
assign LUT_MIN = -16'h1000; // -4.0 in Q6.10

// Debug the calculation step by step
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_addr <= 0;
        gelu_out <= 0;
        valid_out <= 0;
        out_of_range <= 0;
    end else begin
        valid_out <= valid_in;
        
        if (valid_in) begin
            // Calculate offset from LUT_MIN
            offset = x_signed - LUT_MIN;
            
            // Divide by step size (0.125 = 128 in Q6.10)
            // This should give us the LUT index
            lut_addr <= offset[12:7]; // Take bits [12:7] to divide by 128
            
            // Range check
            if (x_signed >= -16'h1000 && x_signed < 16'h0F80) begin
                out_of_range <= 0;
                gelu_out <= lut_data[offset[12:7]];
            end else begin
                out_of_range <= 1;
                if (x_signed < -16'h1000) begin
                    gelu_out <= 16'h0000; // GELU ¿ 0 for very negative
                end else begin
                    gelu_out <= x_signed;  // GELU ¿ x for very positive
                end
            end
        end
    end
end

endmodule

// Simple testbench for debugging
module tb_debug_gelu_lut();

reg clk, rst_n;
reg [15:0] x_in;
reg valid_in;
wire [5:0] lut_addr;
wire [15:0] gelu_out;
wire valid_out, out_of_range;

debug_gelu_lut dut (
    .clk(clk), .rst_n(rst_n), .x_in(x_in), .valid_in(valid_in),
    .lut_addr(lut_addr), .gelu_out(gelu_out), .valid_out(valid_out), .out_of_range(out_of_range)
);

initial clk = 0;
always #5 clk = ~clk;

function [15:0] real_to_fixed;
    input real val;
    begin
        real_to_fixed = val * 1024; // 2^10
    end
endfunction

function real fixed_to_real;
    input [15:0] val;
    begin
        fixed_to_real = $signed(val) / 1024.0;
    end
endfunction

initial begin
    rst_n = 0; valid_in = 0; x_in = 0;
    #20; rst_n = 1; #10;
    
    $display("=== Debug LUT Address Calculation ===");
    $display("Testing key values to check address calculation");
    $display("Input   | Expected Addr | Actual Addr | GELU Out | Expected GELU");
    $display("--------+---------------+-------------+----------+--------------");
    
    // Test x = -4.0, should map to address 0
    x_in = real_to_fixed(-4.0); valid_in = 1; #10; valid_in = 0;
    wait(valid_out); #1;
    $display("-4.000  |       0       |      %2d     |   %04h   |    0.000", lut_addr, gelu_out);
    
    // Test x = -2.0, should map to address 16  
    x_in = real_to_fixed(-2.0); valid_in = 1; #10; valid_in = 0;
    wait(valid_out); #1;
    $display("-2.000  |      16       |      %2d     |   %04h   |   -0.045", lut_addr, gelu_out);
    
    // Test x = -1.0, should map to address 24
    x_in = real_to_fixed(-1.0); valid_in = 1; #10; valid_in = 0;
    wait(valid_out); #1;
    $display("-1.000  |      24       |      %2d     |   %04h   |   -0.159", lut_addr, gelu_out);
    
    // Test x = 0.0, should map to address 32
    x_in = real_to_fixed(0.0); valid_in = 1; #10; valid_in = 0;
    wait(valid_out); #1;
    $display(" 0.000  |      32       |      %2d     |   %04h   |    0.000", lut_addr, gelu_out);
    
    // Test x = 1.0, should map to address 40
    x_in = real_to_fixed(1.0); valid_in = 1; #10; valid_in = 0;
    wait(valid_out); #1;
    $display(" 1.000  |      40       |      %2d     |   %04h   |    0.841", lut_addr, gelu_out);
    
    #50; $finish;
end

endmodule
