// ==========================================
// Debug 32-bit to 16-bit Conversion
// Check if the bit width conversion is causing the problem
// ==========================================

`timescale 1ns/1ps

module debug_bit_conversion;

    // Test the bit conversion logic
    reg [31:0] test_32bit [0:15];
    wire [15:0] converted_16bit [0:15];
    
    // Test different conversion methods
    generate
        genvar i;
        for (i = 0; i < 16; i = i + 1) begin: CONVERT_TEST
            // Method 1: Take bits [31:16] (high 16 bits)
            wire [15:0] method1 = test_32bit[i][31:16];
            
            // Method 2: Take bits [15:0] (low 16 bits) 
            wire [15:0] method2 = test_32bit[i][15:0];
            
            // Method 3: Original suspicious method [16+:16] = bits [31:16]
            wire [15:0] method3 = test_32bit[i][16 +: 16];
            
            // Method 4: Correct method for getting low 16 bits
            wire [15:0] method4 = test_32bit[i][15:0];
        end
    endgenerate
    
    initial begin
        $display("=== 32-bit to 16-bit Conversion Debug ===");
        
        // Test with known values
        test_32bit[0] = 32'h00000001;  // Should become 0001
        test_32bit[1] = 32'h00010000;  // High bit set
        test_32bit[2] = 32'h00010001;  // Both high and low bits
        test_32bit[3] = 32'h12345678;  // Complex pattern
        
        #1;  // Let signals settle
        
        $display("\nTesting conversion methods:");
        $display("Input 32-bit: %08h", test_32bit[0]);
        $display("  Method 1 [31:16]: %04h", CONVERT_TEST[0].method1);
        $display("  Method 2 [15:0]:  %04h", CONVERT_TEST[0].method2);
        $display("  Method 3 [16+:16]: %04h", CONVERT_TEST[0].method3);
        $display("  Method 4 [15:0]:  %04h", CONVERT_TEST[0].method4);
        
        $display("\nInput 32-bit: %08h", test_32bit[1]);
        $display("  Method 1 [31:16]: %04h", CONVERT_TEST[1].method1);
        $display("  Method 2 [15:0]:  %04h", CONVERT_TEST[1].method2);
        $display("  Method 3 [16+:16]: %04h", CONVERT_TEST[1].method3);
        
        $display("\nInput 32-bit: %08h", test_32bit[2]);
        $display("  Method 1 [31:16]: %04h", CONVERT_TEST[2].method1);
        $display("  Method 2 [15:0]:  %04h", CONVERT_TEST[2].method2);
        $display("  Method 3 [16+:16]: %04h", CONVERT_TEST[2].method3);
        
        $display("\n=== Analysis ===");
        $display("For systolic array results (typically small values like 1, 2, 3...):");
        $display("- Correct method should be [15:0] (low 16 bits)");
        $display("- Method [16+:16] extracts bits [31:16] (high 16 bits)");
        $display("- If systolic array produces 32'h00010000, [16+:16] gives 0001");
        $display("- But this would be wrong if actual result is 32'h00000001");
        
        $display("\n=== Potential Bug ===");
        $display("If your matrix_mult_128x128.v uses:");
        $display("  systolic_result_flat[i*32 + 16 +: 16]");
        $display("This extracts the HIGH 16 bits, not the low 16 bits!");
        $display("Should be:");
        $display("  systolic_result_flat[i*32 +: 16]  // Low 16 bits");
        $display("Or:");
        $display("  systolic_result_flat[i*32 + 15 : i*32]  // Low 16 bits");
        
        // Test what happens with accumulated values
        $display("\n=== Accumulation Test ===");
        test_32bit[4] = 32'h00000001;  // 1
        test_32bit[5] = 32'h00000002;  // 2  
        test_32bit[6] = 32'h00000004;  // 4
        test_32bit[7] = 32'h00000007;  // 7
        
        #1;
        
        $display("Value 1: 32'h%08h ¿ [15:0]=%04h, [16+:16]=%04h", 
                test_32bit[4], CONVERT_TEST[4].method2, CONVERT_TEST[4].method3);
        $display("Value 2: 32'h%08h ¿ [15:0]=%04h, [16+:16]=%04h", 
                test_32bit[5], CONVERT_TEST[5].method2, CONVERT_TEST[5].method3);
        $display("Value 4: 32'h%08h ¿ [15:0]=%04h, [16+:16]=%04h", 
                test_32bit[6], CONVERT_TEST[6].method2, CONVERT_TEST[6].method3);
        $display("Value 7: 32'h%08h ¿ [15:0]=%04h, [16+:16]=%04h", 
                test_32bit[7], CONVERT_TEST[7].method2, CONVERT_TEST[7].method3);
        
        $display("\n¿ CONCLUSION:");
        $display("If your systolic array produces correct 32-bit results like:");
        $display("  32'h00000001, 32'h00000002, 32'h00000004, 32'h00000007");
        $display("But you use [16+:16] conversion, you get:");
        $display("  0000, 0000, 0000, 0000 (all zeros!)");
        $display("This doesn't match your actual error pattern.");
        $display("");
        $display("However, if systolic array has internal accumulation bugs,");
        $display("it might produce values like 32'h00010000, 32'h00020000, etc.");
        $display("Then [16+:16] would give 0001, 0002, etc. - matching your pattern!");
        
        $finish;
    end

endmodule
