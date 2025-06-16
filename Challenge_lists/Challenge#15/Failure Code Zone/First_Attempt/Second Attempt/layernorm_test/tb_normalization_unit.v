// tb_normalization_unit.v (Enhanced Debug Version)
module tb_normalization_unit;
    // Parameters
    parameter CLK_PERIOD = 10;
    parameter D_MODEL = 128;
    parameter NUM_PE = 8;
    parameter X_WIDTH = 16;
    parameter Y_WIDTH = 16;
    parameter MU_WIDTH = 24;
    parameter INV_STD_WIDTH = 24;
    parameter GAMMA_WIDTH = 8;
    parameter BETA_WIDTH = 8;
    
    // Test signals
    reg clk;
    reg rst_n;
    reg [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_in;
    reg signed [MU_WIDTH-1:0] mu_in;
    reg signed [INV_STD_WIDTH-1:0] inv_std_in;
    reg [(D_MODEL * GAMMA_WIDTH) - 1 : 0] gamma_vector_in;
    reg [(D_MODEL * BETA_WIDTH) - 1 : 0] beta_vector_in;
    reg start_normalize;
    
    wire [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_out;
    wire normalize_done;
    wire busy;
    
    // DUT
    normalization_unit #(
        .D_MODEL(D_MODEL),
        .NUM_PE(NUM_PE),
        .X_WIDTH(X_WIDTH),
        .Y_WIDTH(Y_WIDTH),
        .MU_WIDTH(MU_WIDTH),
        .INV_STD_WIDTH(INV_STD_WIDTH),
        .GAMMA_WIDTH(GAMMA_WIDTH),
        .BETA_WIDTH(BETA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .x_vector_in(x_vector_in),
        .mu_in(mu_in),
        .inv_std_in(inv_std_in),
        .gamma_vector_in(gamma_vector_in),
        .beta_vector_in(beta_vector_in),
        .start_normalize(start_normalize),
        .y_vector_out(y_vector_out),
        .normalize_done(normalize_done),
        .busy(busy)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Enhanced debug monitor
    integer pe_idx, calc_output_index, k;
    always @(posedge clk) begin
        if (rst_n) begin
            // FSM state monitoring
            $display("[%0t] FSM: state=%0d, cycle=%0d, busy=%b, done=%b", 
                     $time, dut.current_state, dut.cycle_counter, busy, normalize_done);
            
            // Data collection debug - CRITICAL SECTION
            if (dut.current_state == 1 && dut.cycle_counter >= 5 && dut.cycle_counter <= 10) begin  // Focus on early cycles
                $display("[%0t] *** DATA COLLECTION CHECK (EARLY CYCLES) ***", $time);
                $display("  cycle_counter = %0d", dut.cycle_counter);
                $display("  base_index = %0d", dut.base_index);
                $display("  Condition: cycle >= PE_PIPELINE_DELAY? %0d >= 5 = %b", 
                         dut.cycle_counter, (dut.cycle_counter >= 5));
                
                // Check each PE with detailed status
                for (pe_idx = 0; pe_idx < NUM_PE; pe_idx = pe_idx + 1) begin
                    calc_output_index = dut.base_index + pe_idx;
                    $display("  PE[%0d]: valid=%b, y_out=%h (%0d)", 
                             pe_idx, dut.pe_valid_outputs[pe_idx], 
                             dut.pe_y_outputs[pe_idx], $signed(dut.pe_y_outputs[pe_idx]));
                    $display("    target_index = %0d + %0d = %0d", 
                             dut.base_index, pe_idx, calc_output_index);
                    $display("    range_check: %0d < %0d = %b", 
                             calc_output_index, D_MODEL, (calc_output_index < D_MODEL));
                    
                    // Show the exact condition check
                    if (dut.pe_valid_outputs[pe_idx] && (calc_output_index < D_MODEL)) begin
                        $display("    *** SHOULD COLLECT: y_collected_array[%0d] <= %h ***", 
                                 calc_output_index, dut.pe_y_outputs[pe_idx]);
                    end else begin
                        $display("    >>> NOT COLLECTING: valid=%b, range_ok=%b", 
                                 dut.pe_valid_outputs[pe_idx], (calc_output_index < D_MODEL));
                    end
                end
                $display("  *** END EARLY DATA COLLECTION CHECK ***");
            end
            
            // Show y_collected contents at key moments
            if (dut.current_state == 1 && dut.cycle_counter == 20) begin
                $display("[%0t] y_collected_array contents (first 8 elements):", $time);
                for (k = 0; k < 8; k = k + 1) begin
                    $display("  y_collected_array[%0d] = %h (%0d)", 
                             k, dut.y_collected_array[k], 
                             $signed(dut.y_collected_array[k]));
                end
            end
        end
    end
    
    // Test stimulus
    integer i;
    reg signed [Y_WIDTH-1:0] y_val, y0, y1;
    
    initial begin
        // Initialize
        rst_n = 0;
        start_normalize = 0;
        x_vector_in = 0;
        mu_in = 0;
        inv_std_in = 0;
        gamma_vector_in = 0;
        beta_vector_in = 0;
        
        // Set gamma to 1.0 (64 in Q2.6) and beta to 0 for all elements
        for (i = 0; i < D_MODEL; i = i + 1) begin
            gamma_vector_in[i * GAMMA_WIDTH +: GAMMA_WIDTH] = 8'h40; // 1.0 in Q2.6
            beta_vector_in[i * BETA_WIDTH +: BETA_WIDTH] = 8'h00;    // 0.0
        end
        
        // Reset
        #(5 * CLK_PERIOD);
        rst_n = 1;
        #(2 * CLK_PERIOD);
        
        $display("=== Test Case 2: Alternating 2.0 and 0.5 inputs ===");
        
        // Set test case 2 data: alternating 2.0 and 0.5
        for (i = 0; i < D_MODEL; i = i + 1) begin
            if (i % 2 == 0) begin
                x_vector_in[i * X_WIDTH +: X_WIDTH] = 16'h0800; // 2.0 in Q5.10
            end else begin
                x_vector_in[i * X_WIDTH +: X_WIDTH] = 16'h0200; // 0.5 in Q5.10  
            end
        end
        
        // Statistics from previous calculation:
        mu_in = 24'd1280;    // 1.25 in Q13.10
        inv_std_in = 24'd21844; // 1.333 in Q14.14
        
        // Start processing
        start_normalize = 1;
        #CLK_PERIOD;
        start_normalize = 0;
        
        // Wait for completion
        wait (normalize_done);
        #(2 * CLK_PERIOD);
        
        // Check results - DIRECTLY from y_collected_array
        $display("\n=== Final Results ===");
        $display("normalize_done: %b", normalize_done);
        
        $display("Direct y_collected_array verification (first 8 elements):");
        for (i = 0; i < 8; i = i + 1) begin
            $display("  dut.y_collected_array[%0d] = %h (%0d)", i, dut.y_collected_array[i], dut.y_collected_array[i]);
        end
        
        // Also check some middle and end elements
        $display("Middle elements:");
        for (i = 60; i < 68; i = i + 1) begin
            $display("  dut.y_collected_array[%0d] = %h (%0d)", i, dut.y_collected_array[i], dut.y_collected_array[i]);
        end
        
        $display("Last elements:");
        for (i = 120; i < 128; i = i + 1) begin
            $display("  dut.y_collected_array[%0d] = %h (%0d)", i, dut.y_collected_array[i], dut.y_collected_array[i]);
        end
        
        // Verify pattern directly from y_collected_array
        // Input pattern: [2.0, 0.5, 2.0, 0.5, ...]
        // Expected output: [+1.0, -1.0, +1.0, -1.0, ...] = [0400, fc00, 0400, fc00, ...]
        if (dut.y_collected_array[0] == 16'h0400 && dut.y_collected_array[1] == 16'hFC00) begin // +1024, -1024
            $display("¿ Test Case 2 PASSED - Correct alternating pattern in y_collected_array");
            $display("  Expected: [2.0¿+1.0, 0.5¿-1.0] = [0400, fc00]");
            $display("  Got:      [%h, %h] ¿", dut.y_collected_array[0], dut.y_collected_array[1]);
        end else if (dut.y_collected_array[0] == 0 && dut.y_collected_array[1] == 0) begin
            $display("¿ Test Case 2 FAILED - All y_collected_array outputs are zero (data collection issue)");
            $display("  Debug: dut.y_collected_array[0]=%h, dut.y_collected_array[1]=%h", 
                     dut.y_collected_array[0], dut.y_collected_array[1]);
        end else begin
            $display("¿ Test Case 2 FAILED - Unexpected values in y_collected_array");
            $display("  Expected: [0400, fc00] (+1024, -1024)");  
            $display("  Got:      [%h, %h] (%0d, %0d)", 
                     dut.y_collected_array[0], dut.y_collected_array[1],
                     dut.y_collected_array[0], dut.y_collected_array[1]);
        end
        
        $display("Testbench completed!");
        #(5 * CLK_PERIOD);
        $finish;
    end
    
    // Timeout protection
    initial begin
        #(500 * CLK_PERIOD);
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
endmodule
