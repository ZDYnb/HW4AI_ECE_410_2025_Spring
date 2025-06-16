// ===========================================
// Processing Element (PE) - MAC + Data Forwarding
// Building block for systolic array
// ===========================================

`timescale 1ns/1ps

// ===========================================
// Processing Element
// ===========================================
module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       enable,
    input  logic                       clear_accum,
    
    // Data flow (horizontal - left to right)
    input  logic [DATA_WIDTH-1:0]      data_in,
    input  logic                       data_valid_in,
    output logic [DATA_WIDTH-1:0]      data_out,
    output logic                       data_valid_out,
    
    // Weight flow (vertical - top to bottom)  
    input  logic [WEIGHT_WIDTH-1:0]    weight_in,
    input  logic                       weight_valid_in,
    output logic [WEIGHT_WIDTH-1:0]    weight_out,
    output logic                       weight_valid_out,
    
    // Accumulation result
    output logic [ACCUM_WIDTH-1:0]     accum_out,
    output logic                       result_valid
);

    // Internal MAC unit signals
    logic [DATA_WIDTH-1:0]      mac_data;
    logic [WEIGHT_WIDTH-1:0]    mac_weight;
    logic [ACCUM_WIDTH-1:0]     mac_accum;
    logic                       mac_valid;
    
    // Data forwarding registers (for pipeline)
    logic [DATA_WIDTH-1:0]      data_reg;
    logic                       data_valid_reg;
    logic [WEIGHT_WIDTH-1:0]    weight_reg;
    logic                       weight_valid_reg;
    
    // ===========================================
    // Combinational Logic: Data Selection
    // ===========================================
    
    // Use input data/weight for MAC when both are valid
    assign mac_data = (data_valid_in && weight_valid_in) ? data_in : '0;
    assign mac_weight = (data_valid_in && weight_valid_in) ? weight_in : '0;
    
    // ===========================================
    // Sequential Logic: Data Forwarding Pipeline  
    // ===========================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all forwarding registers
            data_reg <= '0;
            data_valid_reg <= '0;
            weight_reg <= '0;
            weight_valid_reg <= '0;
        end else if (enable) begin
            // Forward data horizontally (left ¿ right)
            data_reg <= data_in;
            data_valid_reg <= data_valid_in;
            
            // Forward weight vertically (top ¿ bottom)  
            weight_reg <= weight_in;
            weight_valid_reg <= weight_valid_in;
        end else begin
            // When disabled, don't forward
            data_valid_reg <= '0;
            weight_valid_reg <= '0;
        end
    end
    
    // ===========================================
    // Output Assignments
    // ===========================================
    
    // Forwarded outputs
    assign data_out = data_reg;
    assign data_valid_out = data_valid_reg;
    assign weight_out = weight_reg;
    assign weight_valid_out = weight_valid_reg;
    
    // ===========================================
    // MAC Unit Instance
    // ===========================================
    
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && data_valid_in && weight_valid_in), // Only when both inputs valid
        .clear_accum(clear_accum),
        .data_in(mac_data),
        .weight_in(mac_weight),
        .accum_out(mac_accum),
        .valid_out(mac_valid)
    );
    
    // Connect MAC outputs
    assign accum_out = mac_accum;
    assign result_valid = mac_valid;

endmodule

// ===========================================
// Testbench for Processing Element
// ===========================================
module tb_processing_element;

    parameter CLK_PERIOD = 10;
    
    // PE signals
    logic        clk;
    logic        rst_n;
    logic        enable;
    logic        clear_accum;
    
    // Data flow
    logic [15:0] data_in;
    logic        data_valid_in;
    logic [15:0] data_out;
    logic        data_valid_out;
    
    // Weight flow
    logic [7:0]  weight_in;
    logic        weight_valid_in;
    logic [7:0]  weight_out;
    logic        weight_valid_out;
    
    // Results
    logic [31:0] accum_out;
    logic        result_valid;
    
    // DUT
    processing_element dut (.*);
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test
    initial begin
        $display("=== Processing Element Test ===");
        
        // Initialize
        rst_n = 0; enable = 0; clear_accum = 0;
        data_in = 0; data_valid_in = 0;
        weight_in = 0; weight_valid_in = 0;
        #20 rst_n = 1; #10;
        
        // Test 1: Basic MAC with forwarding
        $display("Test 1: MAC operation + data forwarding");
        enable = 1;
        clear_accum = 1;
        data_in = 5; data_valid_in = 1;
        weight_in = 3; weight_valid_in = 1;
        #10;
        
        $display("  MAC result: %0d (expected 15)", accum_out);
        $display("  Data forwarded: %0d (expected 5)", data_out);
        $display("  Weight forwarded: %0d (expected 3)", weight_out);
        
        if (accum_out == 15 && data_out == 5 && weight_out == 3) begin
            $display("¿ PASS: MAC and forwarding work");
        end else begin
            $display("¿ FAIL: Something wrong");
        end
        
        // Test 2: Data flow without valid signals
        $display("Test 2: Invalid inputs (should not compute)");
        data_in = 10; data_valid_in = 0;  // Invalid data
        weight_in = 2; weight_valid_in = 1; // Valid weight
        clear_accum = 1;
        #10;
        
        $display("  MAC result: %0d (should be 0)", accum_out);
        if (accum_out == 0) begin
            $display("¿ PASS: No computation with invalid inputs");
        end else begin
            $display("¿ FAIL: Should not compute with invalid inputs");
        end
        
        // Test 3: Chain of operations (simulate systolic behavior)
        $display("Test 3: Simulating systolic chain");
        
        // Step 1: First data flows through
        clear_accum = 1;
        data_in = 1; data_valid_in = 1;
        weight_in = 4; weight_valid_in = 1;
        #10;
        $display("  Step 1: 1*4=%0d, forwarded data=%0d", accum_out, data_out);
        
        // Step 2: Second data (uses forwarded weight from previous step)
        clear_accum = 0; // Accumulate
        data_in = 2; data_valid_in = 1;
        weight_in = 5; weight_valid_in = 1;
        #10;
        $display("  Step 2: 4+(2*5)=%0d, forwarded data=%0d", accum_out, data_out);
        
        // Step 3: Third data
        data_in = 3; data_valid_in = 1;
        weight_in = 6; weight_valid_in = 1;
        #10;
        $display("  Step 3: 14+(3*6)=%0d, forwarded data=%0d", accum_out, data_out);
        
        if (accum_out == 32) begin // 4 + 10 + 18 = 32
            $display("¿ PASS: Systolic-like operation works");
        end else begin
            $display("¿ FAIL: Expected 32, got %0d", accum_out);
        end
        
        // Test 4: Disable test
        $display("Test 4: Disable PE");
        enable = 0;
        data_in = 100; data_valid_in = 1;
        weight_in = 100; weight_valid_in = 1;
        #10;
        
        if (!data_valid_out && !weight_valid_out) begin
            $display("¿ PASS: PE disabled correctly");
        end else begin
            $display("¿ FAIL: PE should be disabled");
        end
        
        $display("=== PE Test Complete ===");
        $finish;
    end
    
    // Monitor critical signals
    initial begin
        $monitor("T=%0t: data_in=%0d->%0d, weight_in=%0d->%0d, accum=%0d, valid=%b", 
                 $time, data_in, data_out, weight_in, weight_out, accum_out, result_valid);
    end

endmodule

// ===========================================
// Include the MAC unit from previous step
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
