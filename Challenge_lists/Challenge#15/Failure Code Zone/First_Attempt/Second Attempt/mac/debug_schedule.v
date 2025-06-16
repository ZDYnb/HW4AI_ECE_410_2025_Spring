// ===========================================
// Debug Schedule Analysis
// Analyze why rows 25-31 are getting 0s
// ===========================================

`timescale 1ns/1ps

module debug_schedule;

    parameter ARRAY_SIZE = 32;
    parameter DATA_WIDTH = 16;
    parameter WEIGHT_WIDTH = 8;
    
    // Test matrices
    reg [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Schedule arrays (same as main design)
    reg [DATA_WIDTH-1:0]    data_schedule [0:254][0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0]  weight_schedule [0:254][0:ARRAY_SIZE-1];
    reg                     data_valid_schedule [0:254][0:ARRAY_SIZE-1];
    reg                     weight_valid_schedule [0:254][0:ARRAY_SIZE-1];
    
    integer cycle, i, j;
    integer valid_count;
    integer valid_count_working;
    
    initial begin
        $display("=== DEBUG: Schedule Analysis for 32x32 ===");
        
        // Initialize test matrices (same pattern as failed test)
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                matrix_a[i][j] = (i*ARRAY_SIZE + j + 1) % 256;
                if (i == j) begin
                    matrix_b[i][j] = 1;  // Identity
                end else begin
                    matrix_b[i][j] = 0;
                end
            end
        end
        
        // Clear schedules
        for (cycle = 0; cycle < 255; cycle = cycle + 1) begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                data_schedule[cycle][i] = 0;
                weight_schedule[cycle][i] = 0;
                data_valid_schedule[cycle][i] = 0;
                weight_valid_schedule[cycle][i] = 0;
            end
        end
        
        // Generate schedule (same algorithm as main design)
        $display("Generating schedule for %0d cycles...", 2*ARRAY_SIZE-1);
        for (cycle = 0; cycle < 2*ARRAY_SIZE-1; cycle = cycle + 1) begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                // Data (Matrix A) scheduling - diagonal loading
                if ((cycle >= i) && (cycle - i < ARRAY_SIZE)) begin
                    data_schedule[cycle][i] = matrix_a[i][cycle - i];
                    data_valid_schedule[cycle][i] = 1'b1;
                end else begin
                    data_schedule[cycle][i] = 0;
                    data_valid_schedule[cycle][i] = 1'b0;
                end
                
                // Weight (Matrix B) scheduling - diagonal loading
                if ((cycle >= i) && (cycle - i < ARRAY_SIZE)) begin
                    weight_schedule[cycle][i] = matrix_b[cycle - i][i];
                    weight_valid_schedule[cycle][i] = 1'b1;
                end else begin
                    weight_schedule[cycle][i] = 0;
                    weight_valid_schedule[cycle][i] = 1'b0;
                end
            end
        end
        
        // Debug Analysis
        $display("\n=== SCHEDULE ANALYSIS ===");
        
        // Check problem rows (25-31)
        $display("\nProblem Rows Analysis:");
        for (i = 25; i < ARRAY_SIZE; i = i + 1) begin
            $display("\nRow %0d analysis:", i);
            
            // Count how many valid data this row gets
            valid_count = 0;
            for (cycle = 0; cycle < 2*ARRAY_SIZE-1; cycle = cycle + 1) begin
                if (data_valid_schedule[cycle][i]) begin
                    valid_count = valid_count + 1;
                    if (valid_count <= 5) begin  // Show first 5 valid data
                        $display("  Cycle %2d: data=%0d, valid=%b", 
                               cycle, data_schedule[cycle][i], data_valid_schedule[cycle][i]);
                    end
                end
            end
            $display("  Total valid data count: %0d (should be %0d)", valid_count, ARRAY_SIZE);
            
            // Check expected data for this row
            $display("  Expected data for row %0d:", i);
            for (j = 0; j < 8; j = j + 1) begin  // Show first 8 elements
                $display("    matrix_a[%0d][%0d] = %0d", i, j, matrix_a[i][j]);
            end
        end
        
        // Check working rows (0-24) for comparison
        $display("\nWorking Rows Analysis (sample):");
        for (i = 0; i < 4; i = i + 1) begin
            valid_count_working = 0;
            for (cycle = 0; cycle < 2*ARRAY_SIZE-1; cycle = cycle + 1) begin
                if (data_valid_schedule[cycle][i]) begin
                    valid_count_working = valid_count_working + 1;
                end
            end
            $display("Row %0d: %0d valid data points", i, valid_count_working);
        end
        
        // Check cycle range analysis
        $display("\n=== CYCLE RANGE ANALYSIS ===");
        for (i = 25; i < ARRAY_SIZE; i = i + 1) begin
            $display("Row %0d needs data in cycles %0d to %0d", i, i, i+ARRAY_SIZE-1);
            $display("  Available cycles: 0 to %0d", 2*ARRAY_SIZE-2);
            if (i+ARRAY_SIZE-1 > 2*ARRAY_SIZE-2) begin
                $display("  *** PROBLEM: Row %0d needs cycle %0d but max available is %0d ***", 
                       i, i+ARRAY_SIZE-1, 2*ARRAY_SIZE-2);
            end
        end
        
        $display("\n=== DEBUG COMPLETE ===");
        $finish;
    end

endmodule
