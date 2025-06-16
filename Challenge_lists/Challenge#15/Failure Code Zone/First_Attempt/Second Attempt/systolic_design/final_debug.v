`timescale 1ns/1ps

module final_debug;
    reg [7:0] b0, b1, b2, b3;
    
    initial begin
        // Simulate the values we got
        b0 = 8'h05;
        b1 = 8'h00;
        b2 = 8'h00;
        b3 = 8'h00;
        
        $display("=== FINAL DEBUG ===");
        $display("b0=0x%02x, b1=0x%02x, b2=0x%02x, b3=0x%02x", b0, b1, b2, b3);
        $display("Concatenation {b3,b2,b1,b0} = 0x%08x", {b3, b2, b1, b0});
        $display("Decimal value = %0d", {b3, b2, b1, b0});
        $display("Expected = %0d", 32'd5);
        $display("Match? %s", ({b3, b2, b1, b2} == 32'd5) ? "YES" : "NO");
        $display("Actual match? %s", ({b3, b2, b1, b0} == 32'd5) ? "YES" : "NO");
        
        // The real issue might be that we're reading the WRONG result
        // Let's check if result[0][1] and result[0][2] should actually be the first result
        $display("Maybe the issue is we're reading result[0][1] instead of result[0][0]?");
        
        $finish;
    end
endmodule
