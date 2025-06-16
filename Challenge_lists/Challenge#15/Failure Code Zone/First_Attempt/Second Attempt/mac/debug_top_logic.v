// ==========================================
// Debug Top Level Logic Issues
// Check for common integration problems
// ==========================================

`timescale 1ns/1ps

module debug_top_logic;

    // Let's analyze the potential issues in matrix_mult_128x128.v
    
    initial begin
        $display("=== Top Level Logic Debug Analysis ===");
        
        $display("\n¿ Potential Issues in matrix_mult_128x128.v:");
        
        $display("\n1. Block Sequence Problem:");
        $display("   - Are blocks processed in wrong order?");
        $display("   - Block[0,0] ¿ step 0,1 ¿");
        $display("   - Block[0,1] ¿ step 2,3 ¿");  
        $display("   - Block[1,0] ¿ step 4,5 ¿");
        $display("   - Block[1,1] ¿ step 6,7 ¿");
        $display("   From debug: sequence looks correct");
        
        $display("\n2. Matrix Splitter Output Routing:");
        $display("   - Does Matrix Splitter A output go to correct systolic input?");
        $display("   - Does Matrix Splitter B output go to correct systolic input?");
        $display("   - Are block indices passed correctly?");
        
        $display("\n3. Result Accumulator Input Routing:");
        $display("   - Does systolic result go to correct accumulator input?");
        $display("   - Are row_block_idx/col_block_idx correct for each step?");
        
        $display("\n4. Signal Timing Issues:");
        $display("   - accumulate_result signal timing");
        $display("   - Data/control signal synchronization");
        
        $display("\n5. Block Index Calculation:");
        test_block_index_logic();
        
        $display("\n6. Data Path Analysis:");
        analyze_data_flow();
        
        $finish;
    end
    
    // Test the block index calculation logic
    task test_block_index_logic;
        reg [2:0] step;
        reg [1:0] expected_row_idx, expected_col_idx;
        reg [1:0] calculated_row_idx, calculated_col_idx;
        begin
            $display("\n=== Block Index Calculation Test ===");
            
            for (step = 0; step < 8; step = step + 1) begin
                // Expected block indices for each step
                case (step)
                    0: begin expected_row_idx = 0; expected_col_idx = 0; end  // A[0,0] × B[0,0]
                    1: begin expected_row_idx = 0; expected_col_idx = 0; end  // A[0,1] × B[1,0] ¿ C[0,0]
                    2: begin expected_row_idx = 0; expected_col_idx = 1; end  // A[0,0] × B[0,1]
                    3: begin expected_row_idx = 0; expected_col_idx = 1; end  // A[0,1] × B[1,1] ¿ C[0,1]
                    4: begin expected_row_idx = 1; expected_col_idx = 0; end  // A[1,0] × B[0,0]
                    5: begin expected_row_idx = 1; expected_col_idx = 0; end  // A[1,1] × B[1,0] ¿ C[1,0]
                    6: begin expected_row_idx = 1; expected_col_idx = 1; end  // A[1,0] × B[0,1]
                    7: begin expected_row_idx = 1; expected_col_idx = 1; end  // A[1,1] × B[1,1] ¿ C[1,1]
                endcase
                
                // How the indices SHOULD be calculated in matrix_mult_128x128.v
                // This depends on the actual implementation
                calculated_row_idx = (step >= 4) ? 1 : 0;  // Simple calculation
                calculated_col_idx = ((step == 2) || (step == 3) || (step == 6) || (step == 7)) ? 1 : 0;
                
                $display("Step %0d: Expected C[%0d,%0d], Calculated C[%0d,%0d] %s",
                        step, expected_row_idx, expected_col_idx, 
                        calculated_row_idx, calculated_col_idx,
                        (expected_row_idx == calculated_row_idx && expected_col_idx == calculated_col_idx) ? "¿" : "¿");
            end
        end
    endtask
    
    // Analyze the data flow issues
    task analyze_data_flow;
        begin
            $display("\n=== Data Flow Analysis ===");
            
            $display("\nFrom debug results, we see this pattern:");
            $display("Step 1: A[0,0]×B[0,0]¿C[0,0], systolic_out=0001, result[0][16]=0001 ¿");
            $display("Step 2: A[0,1]×B[1,0]¿C[0,0], systolic_out=0000, result[0][16]=0002 ¿");
            $display("");
            $display("¿ Why does result[0][16] become 0002?");
            $display("");
            
            $display("Possible explanations:");
            $display("A. Wrong accumulation target:");
            $display("   - Step 2 should accumulate to C[0,0]");
            $display("   - But maybe it's accumulating to wrong block?");
            $display("");
            
            $display("B. Systolic array output routing error:");
            $display("   - Step 2 produces 0000 for position [0][0]");
            $display("   - But maybe [0][16] gets a different value?");
            $display("");
            
            $display("C. Result accumulator write pattern error:");
            $display("   - Maybe step 2 writes to multiple positions?");
            $display("   - Or writes the wrong value?");
            $display("");
            
            $display("D. Block boundary confusion:");
            $display("   - Position [0][16] is in Block[0,0]");
            $display("   - But maybe step 2 thinks it should write to [0][16]?");
            $display("");
            
            $display("¿ Key insight from debug:");
            $display("   'Sample accumulator input = 0000'");
            $display("   'Sample accumulator output = 0001'");  
            $display("   'result[0][16] changed to 0002'");
            $display("");
            $display("This suggests:");
            $display("- Accumulator receives 0000 (correct)");
            $display("- Accumulator outputs 0001 (might be from previous step)");
            $display("- But somehow result[0][16] becomes 0002");
            $display("");
            $display("¿ Hypothesis: Result might be written twice!");
            $display("   - Once from step 1 result (0001)");
            $display("   - Once from step 2 result (0001)"); 
            $display("   - Total: 0001 + 0001 = 0002");
        end
    endtask

endmodule
