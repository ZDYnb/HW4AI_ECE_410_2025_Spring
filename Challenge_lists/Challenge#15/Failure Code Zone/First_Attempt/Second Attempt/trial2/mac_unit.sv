
// ===========================================
// Basic MAC Unit
// ===========================================
module mac_unit_basic #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       enable,
    input  logic                       clear_accum,
    
    input  logic [DATA_WIDTH-1:0]      data_in,
    input  logic [WEIGHT_WIDTH-1:0]    weight_in,
    
    output logic [ACCUM_WIDTH-1:0]     accum_out,
    output logic                       valid_out
);

    logic signed [DATA_WIDTH-1:0]      data_signed;
    logic signed [WEIGHT_WIDTH-1:0]    weight_signed;
    logic signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] mult_result;
    logic signed [ACCUM_WIDTH-1:0]     accum_reg;
    logic signed [ACCUM_WIDTH-1:0]     next_accum;
    
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);
    assign mult_result = data_signed * weight_signed;
    assign next_accum = clear_accum ? mult_result : (accum_reg + mult_result);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= '0;
            valid_out <= '0;
        end else if (enable) begin
            accum_reg <= next_accum;
            valid_out <= '1;
        end else begin
            valid_out <= '0;
        end
    end
    
    assign accum_out = accum_reg;

endmodule

// ===========================================
// Simple Testbench
// ===========================================
module tb_mac_unit_basic;

    parameter CLK_PERIOD = 10;
    
    logic        clk;
    logic        rst_n;
    logic        enable;
    logic        clear_accum;
    logic [15:0] data_in;
    logic [7:0]  weight_in;
    logic [31:0] accum_out;
    logic        valid_out;
    
    // DUT
    mac_unit_basic dut (.*);
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test
    initial begin
        $display("=== MAC Unit Test ===");
        
        // Reset
        rst_n = 0; enable = 0; clear_accum = 0; data_in = 0; weight_in = 0;
        #20 rst_n = 1; #10;
        
        // Test 1: 5 * 3 = 15
        $display("Test 1: 5 * 3 = ?");
        data_in = 5; weight_in = 3; clear_accum = 1; enable = 1; #10;
        if (accum_out == 15) $display("PASS: Got %0d", accum_out);
        else $display("FAIL: Expected 15, Got %0d", accum_out);
        
        // Test 2: Accumulate 2 * 4 = 15 + 8 = 23
        $display("Test 2: 15 + (2 * 4) = ?");
        data_in = 2; weight_in = 4; clear_accum = 0; enable = 1; #10;
        if (accum_out == 23) $display("PASS: Got %0d", accum_out);
        else $display("FAIL: Expected 23, Got %0d", accum_out);
        
        // Test 3: Clear and new: 10 * 2 = 20
        $display("Test 3: 10 * 2 = ?");
        data_in = 10; weight_in = 2; clear_accum = 1; enable = 1; #10;
        if (accum_out == 20) $display("PASS: Got %0d", accum_out);
        else $display("FAIL: Expected 20, Got %0d", accum_out);
        
        // Test 4: Negative: 6 * (-2) = -12
        $display("Test 4: 6 * (-2) = ?");
        data_in = 6; weight_in = 8'hFE; clear_accum = 1; enable = 1; #10; // -2 in 2's complement
        if ($signed(accum_out) == -12) $display("PASS: Got %0d", $signed(accum_out));
        else $display("FAIL: Expected -12, Got %0d", $signed(accum_out));
        
        $display("=== Test Complete ===");
        $finish;
    end

endmodule
