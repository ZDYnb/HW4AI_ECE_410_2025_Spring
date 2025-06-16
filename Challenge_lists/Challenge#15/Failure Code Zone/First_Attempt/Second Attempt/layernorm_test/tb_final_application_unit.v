`timescale 1ns / 1ps

module tb_final_application_unit;

    // Test parameters - matching the DUT
    parameter D_MODEL = 128;
    parameter N_PE_APP = 8;
    parameter PE_LATENCY = 6;
    
    parameter X_WIDTH = 16, X_FRAC = 10;
    parameter Y_WIDTH = 16, Y_FRAC = 10;
    parameter MU_WIDTH = 24, MU_FRAC = 10;
    parameter INV_STD_WIDTH = 24, INV_STD_FRAC = 14;
    parameter GAMMA_WIDTH = 8, GAMMA_FRAC = 6;
    parameter BETA_WIDTH = 8, BETA_FRAC = 6;
    
    parameter PE_STAGE1_OUT_WIDTH = MU_WIDTH;
    parameter PE_STAGE1_OUT_FRAC = MU_FRAC;
    parameter PE_STAGE2_OUT_WIDTH = 24, PE_STAGE2_OUT_FRAC = 21;
    parameter PE_STAGE3_OUT_WIDTH = 24, PE_STAGE3_OUT_FRAC = 18;
    parameter PE_STAGE4_OUT_WIDTH = 24, PE_STAGE4_OUT_FRAC = 18;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Input signals
    reg start_process_valid_in;
    reg signed [MU_WIDTH-1:0] mu_scalar_in;
    reg signed [INV_STD_WIDTH-1:0] inv_std_eff_scalar_in;
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_in;
    reg signed [(D_MODEL * GAMMA_WIDTH) - 1 : 0] gamma_vector_in;
    reg signed [(D_MODEL * BETA_WIDTH) - 1 : 0] beta_vector_in;
    
    // Output signals
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_out;
    wire y_vector_valid_out;
    wire busy_out;
    
    // Test variables
    integer i, j;
    integer test_count;
    integer error_count;
    reg [31:0] timeout_counter;
    
    // Arrays for easier data manipulation
    reg signed [X_WIDTH-1:0] x_test_array [D_MODEL-1:0];
    reg signed [GAMMA_WIDTH-1:0] gamma_test_array [D_MODEL-1:0];
    reg signed [BETA_WIDTH-1:0] beta_test_array [D_MODEL-1:0];
    wire signed [Y_WIDTH-1:0] y_result_array [D_MODEL-1:0];
    
    // Unpack output vector for easier verification
    genvar k;
    generate
        for (k = 0; k < D_MODEL; k = k + 1) begin : unpack_output
            assign y_result_array[k] = y_vector_out[k*Y_WIDTH +: Y_WIDTH];
        end
    endgenerate

    // Instantiate the DUT
    final_application_unit #(
        .D_MODEL(D_MODEL),
        .N_PE_APP(N_PE_APP),
        .PE_LATENCY(PE_LATENCY),
        .X_WIDTH(X_WIDTH), .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH), .Y_FRAC(Y_FRAC),
        .MU_WIDTH(MU_WIDTH), .MU_FRAC(MU_FRAC),
        .INV_STD_WIDTH(INV_STD_WIDTH), .INV_STD_FRAC(INV_STD_FRAC),
        .GAMMA_WIDTH(GAMMA_WIDTH), .GAMMA_FRAC(GAMMA_FRAC),
        .BETA_WIDTH(BETA_WIDTH), .BETA_FRAC(BETA_FRAC),
        .PE_STAGE1_OUT_WIDTH(PE_STAGE1_OUT_WIDTH), .PE_STAGE1_OUT_FRAC(PE_STAGE1_OUT_FRAC),
        .PE_STAGE2_OUT_WIDTH(PE_STAGE2_OUT_WIDTH), .PE_STAGE2_OUT_FRAC(PE_STAGE2_OUT_FRAC),
        .PE_STAGE3_OUT_WIDTH(PE_STAGE3_OUT_WIDTH), .PE_STAGE3_OUT_FRAC(PE_STAGE3_OUT_FRAC),
        .PE_STAGE4_OUT_WIDTH(PE_STAGE4_OUT_WIDTH), .PE_STAGE4_OUT_FRAC(PE_STAGE4_OUT_FRAC)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_process_valid_in(start_process_valid_in),
        .mu_scalar_in(mu_scalar_in),
        .inv_std_eff_scalar_in(inv_std_eff_scalar_in),
        .x_vector_in(x_vector_in),
        .gamma_vector_in(gamma_vector_in),
        .beta_vector_in(beta_vector_in),
        .y_vector_out(y_vector_out),
        .y_vector_valid_out(y_vector_valid_out),
        .busy_out(busy_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Task: Pack test arrays into input vectors
    task pack_input_vectors;
        begin
            for (i = 0; i < D_MODEL; i = i + 1) begin
                x_vector_in[i*X_WIDTH +: X_WIDTH] = x_test_array[i];
                gamma_vector_in[i*GAMMA_WIDTH +: GAMMA_WIDTH] = gamma_test_array[i];
                beta_vector_in[i*BETA_WIDTH +: BETA_WIDTH] = beta_test_array[i];
            end
        end
    endtask

    // Task: Initialize test data
    task init_test_data;
        input [31:0] test_case;
        begin
            case (test_case)
                0: begin // Test case 0: Simple incrementing pattern
                    mu_scalar_in = 24'h000400; // 1.0 in fixed point (MU_FRAC = 10)
                    inv_std_eff_scalar_in = 24'h004000; // 1.0 in fixed point (INV_STD_FRAC = 14)
                    for (i = 0; i < D_MODEL; i = i + 1) begin
                        x_test_array[i] = (i + 1) << X_FRAC; // 1.0, 2.0, 3.0, ...
                        gamma_test_array[i] = 8'h40; // 1.0 in fixed point (GAMMA_FRAC = 6)
                        beta_test_array[i] = 8'h00;  // 0.0 in fixed point (BETA_FRAC = 6)
                    end
                end
                1: begin // Test case 1: All ones
                    mu_scalar_in = 24'h000000; // 0.0
                    inv_std_eff_scalar_in = 24'h004000; // 1.0
                    for (i = 0; i < D_MODEL; i = i + 1) begin
                        x_test_array[i] = 16'h0400; // 1.0
                        gamma_test_array[i] = 8'h40; // 1.0
                        beta_test_array[i] = 8'h00;  // 0.0
                    end
                end
                2: begin // Test case 2: Mixed values with non-zero beta
                    mu_scalar_in = 24'h000200; // 0.5
                    inv_std_eff_scalar_in = 24'h008000; // 2.0
                    for (i = 0; i < D_MODEL; i = i + 1) begin
                        x_test_array[i] = (i % 2 == 0) ? 16'h0400 : 16'hFC00; // Alternating 1.0, -1.0
                        gamma_test_array[i] = 8'h20; // 0.5
                        beta_test_array[i] = 8'h10;  // 0.25
                    end
                end
                default: begin // Default case: zeros
                    mu_scalar_in = 24'h000000;
                    inv_std_eff_scalar_in = 24'h004000;
                    for (i = 0; i < D_MODEL; i = i + 1) begin
                        x_test_array[i] = 16'h0000;
                        gamma_test_array[i] = 8'h40;
                        beta_test_array[i] = 8'h00;
                    end
                end
            endcase
            pack_input_vectors();
        end
    endtask

    // Task: Wait for processing completion
    task wait_for_completion;
        begin
            timeout_counter = 0;
            while (!y_vector_valid_out && timeout_counter < 1000) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 1000) begin
                $display("ERROR: Timeout waiting for completion at test %0d", test_count);
                error_count = error_count + 1;
            end else begin
                $display("INFO: Test %0d completed in %0d cycles", test_count, timeout_counter);
            end
        end
    endtask

    // Task: Run a single test
    task run_test;
        input [31:0] test_case;
        begin
            test_count = test_count + 1;
            $display("========== Running Test Case %0d ==========", test_case);
            
            // Initialize test data
            init_test_data(test_case);
            
            // Wait for idle state
            while (busy_out) @(posedge clk);
            
            // Start processing
            @(posedge clk);
            start_process_valid_in = 1'b1;
            @(posedge clk);
            start_process_valid_in = 1'b0;
            
            // Check if busy signal is asserted (allow 1-2 clock cycles for FSM transition)
            repeat(2) @(posedge clk);
            if (!busy_out) begin
                $display("ERROR: busy_out should be asserted after start signal");
                error_count = error_count + 1;
            end
            
            // Wait for completion
            wait_for_completion();
            
            // Verify results (basic sanity check)
            if (y_vector_valid_out) begin
                $display("INFO: Output validation completed successfully");
                // Display first few results for manual verification
                for (i = 0; i < 8 && i < D_MODEL; i = i + 1) begin
                    $display("  y[%0d] = 0x%04x", i, y_result_array[i]);
                end
            end else begin
                $display("ERROR: y_vector_valid_out not asserted");
                error_count = error_count + 1;
            end
            
            // Wait a few cycles before next test
            repeat(5) @(posedge clk);
            $display("========== Test Case %0d Complete ==========\n", test_case);
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize
        test_count = 0;
        error_count = 0;
        start_process_valid_in = 1'b0;
        mu_scalar_in = 24'h000000;
        inv_std_eff_scalar_in = 24'h000000;
        x_vector_in = {(D_MODEL * X_WIDTH){1'b0}};
        gamma_vector_in = {(D_MODEL * GAMMA_WIDTH){1'b0}};
        beta_vector_in = {(D_MODEL * BETA_WIDTH){1'b0}};
        
        // Reset sequence
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        
        $display("========== Starting Final Application Unit Testbench ==========");
        $display("INFO: D_MODEL = %0d, N_PE_APP = %0d, PE_LATENCY = %0d", D_MODEL, N_PE_APP, PE_LATENCY);
        
        // Run test cases
        run_test(0); // Simple incrementing pattern
        run_test(1); // All ones
        run_test(2); // Mixed values
        
        // Test multiple consecutive operations
        $display("========== Testing Consecutive Operations ==========");
        for (j = 0; j < 3; j = j + 1) begin
            run_test(j);
        end
        
        // Final results
        repeat(10) @(posedge clk);
        $display("========== Testbench Complete ==========");
        $display("Total tests run: %0d", test_count);
        $display("Total errors: %0d", error_count);
        
        if (error_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", error_count);
        end
        
        $finish;
    end

    // Monitor key signals
    initial begin
        $monitor("Time: %0t | State: %0d | busy: %b | valid_out: %b | start: %b", 
                 $time, dut.current_state, busy_out, y_vector_valid_out, start_process_valid_in);
    end

    // Optional: VCD dump for waveform analysis
    initial begin
        $dumpfile("tb_final_application_unit.vcd");
        $dumpvars(0, tb_final_application_unit);
    end

endmodule
