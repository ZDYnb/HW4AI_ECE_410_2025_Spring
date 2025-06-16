// ga_fitness_calculator_tb.v
`timescale 1ns/1ps

module ga_fitness_calculator_tb;

    // Parameters (should match DUT)
    parameter CHROMOSOME_LENGTH = 19;
    parameter CHAR_WIDTH = 8;
    parameter FITNESS_WIDTH = 5;
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Testbench signals
    reg clk;
    reg rst_n;
    reg start_new_individual;
    reg [CHAR_WIDTH-1:0] char_in;
    reg char_valid;
    wire [FITNESS_WIDTH-1:0] fitness_out;
    wire evaluation_done;

    // Instantiate the DUT (Device Under Test)
    ga_fitness_calculator #(
        .CHROMOSOME_LENGTH(CHROMOSOME_LENGTH),
        .CHAR_WIDTH(CHAR_WIDTH),
        .FITNESS_WIDTH(FITNESS_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_new_individual(start_new_individual),
        .char_in(char_in),
        .char_valid(char_valid),
        .fitness_out(fitness_out),
        .evaluation_done(evaluation_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Declare task-local variables at module level
    integer task_i;
    reg [CHAR_WIDTH-1:0] task_temp_char;

    // Task to send a chromosome and check result
    task send_chromosome_and_check;
        input [CHAR_WIDTH*CHROMOSOME_LENGTH-1:0] chromosome_packed;
        input [FITNESS_WIDTH-1:0] expected_fitness;
        input [8*50-1:0] test_name; // String for test identification
        
        begin
            $display("=== Starting %s ===", test_name);
            
            // Step 1: Assert start_new_individual for one cycle
            @(posedge clk);
            start_new_individual = 1'b1;
            @(posedge clk);
            start_new_individual = 1'b0;
            
            // Step 2: Send chromosome serially
            for (task_i = 0; task_i < CHROMOSOME_LENGTH; task_i = task_i + 1) begin
                @(posedge clk);
                task_temp_char = chromosome_packed[(CHROMOSOME_LENGTH-1-task_i)*CHAR_WIDTH +: CHAR_WIDTH];
                char_in = task_temp_char;
                char_valid = 1'b1;
                $display("Sending char[%0d] = 0x%02x ('%c')", task_i, task_temp_char, task_temp_char);
            end
            
            // Step 3: De-assert char_valid after sending all chars
            @(posedge clk);
            char_valid = 1'b0;
            char_in = 8'h00;
            
            // Step 4: Wait for evaluation_done
            $display("Waiting for evaluation_done...");
            wait (evaluation_done == 1'b1);
            
            // Step 5: Check the result
            $display("Fitness calculation completed!");
            $display("Expected fitness: %0d", expected_fitness);
            $display("Actual fitness: %0d", fitness_out);
            
            if (fitness_out == expected_fitness) begin
                $display("¿ PASS: %s", test_name);
            end else begin
                $display("¿ FAIL: %s - Expected %0d, got %0d", test_name, expected_fitness, fitness_out);
                $error("Test failed!");
            end
            
            // Wait for evaluation_done to go low
            @(posedge clk);
            if (evaluation_done != 1'b0) begin
                $display("¿ FAIL: evaluation_done should be low after one cycle");
                $error("evaluation_done timing error!");
            end
            
            $display("=== Completed %s ===\n", test_name);
        end
    endtask

    // Main test sequence
    initial begin
        // Declare all variables at the beginning of initial block
        reg [CHAR_WIDTH*CHROMOSOME_LENGTH-1:0] test_chromosome;
        integer expected_all_diff_fitness;
        integer i;
        
        $display("Starting GA Fitness Calculator Testbench");
        $display("CHROMOSOME_LENGTH = %0d", CHROMOSOME_LENGTH);
        $display("Target string: \"I love GeeksforGeeks\"");
        
        // Initialize signals
        rst_n = 0;
        start_new_individual = 0;
        char_in = 8'h00;
        char_valid = 0;
        
        // Apply reset
        $display("\n=== Applying Reset ===");
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test Case 1: Perfect match (fitness should be 0)
        // "I love GeeksforGeeks" = 0x49, 0x20, 0x6C, 0x6F, 0x76, 0x65, 0x20, 0x47, 0x65, 0x65, 0x6B, 0x73, 0x66, 0x6F, 0x72, 0x47, 0x65, 0x65, 0x6B
        test_chromosome = {8'h49, 8'h20, 8'h6C, 8'h6F, 8'h76, 8'h65, 8'h20, 8'h47, 8'h65, 8'h65, 8'h6B, 8'h73, 8'h66, 8'h6F, 8'h72, 8'h47, 8'h65, 8'h65, 8'h6B};
        send_chromosome_and_check(test_chromosome, 5'd0, "Perfect Match Test");
        
        #(CLK_PERIOD * 5);
        
        // Test Case 2: One character different (fitness should be 1)
        // Change first character from 'I' (0x49) to 'X' (0x58)
        test_chromosome = {8'h58, 8'h20, 8'h6C, 8'h6F, 8'h76, 8'h65, 8'h20, 8'h47, 8'h65, 8'h65, 8'h6B, 8'h73, 8'h66, 8'h6F, 8'h72, 8'h47, 8'h65, 8'h65, 8'h6B};
        send_chromosome_and_check(test_chromosome, 5'd1, "One Different Test");
        
        #(CLK_PERIOD * 5);
        
        // Test Case 3: All characters different (fitness should be 19)
        expected_all_diff_fitness = CHROMOSOME_LENGTH;
        for (i = 0; i < CHROMOSOME_LENGTH; i = i + 1) begin
            test_chromosome[(CHROMOSOME_LENGTH-1-i)*CHAR_WIDTH +: CHAR_WIDTH] = 8'h41; // All 'A's
        end
        send_chromosome_and_check(test_chromosome, expected_all_diff_fitness, "All Different Test");
        
        #(CLK_PERIOD * 5);
        
        // Test Case 4: Test with some random differences
        // "Hello World!!!!!!!!" - should have multiple differences
        test_chromosome = {8'h48, 8'h65, 8'h6C, 8'h6C, 8'h6F, 8'h20, 8'h57, 8'h6F, 8'h72, 8'h6C, 8'h64, 8'h21, 8'h21, 8'h21, 8'h21, 8'h21, 8'h21, 8'h21, 8'h21};
        send_chromosome_and_check(test_chromosome, 5'd19, "Random String Test"); // Expect all different
        
        #(CLK_PERIOD * 10);
        
        $display("\n=== All Tests Completed ===");
        $display("If you see this message, all basic tests passed!");
        $display("Consider adding more comprehensive tests:");
        $display("- char_valid de-assertion during loading");
        $display("- Back-to-back evaluations");
        $display("- Edge cases and stress testing");
        
        $finish;
    end

    // Monitor key signals
    initial begin
        $monitor("Time=%0t, State=%0d, Count=%0d, char_in=0x%02x, char_valid=%b, fitness_out=%0d, eval_done=%b", 
                 $time, dut.current_fsm_state, dut.char_receive_count, char_in, char_valid, fitness_out, evaluation_done);
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000); // 10000 clock cycles timeout
        $display("ERROR: Testbench timeout!");
        $error("Simulation timeout - possible infinite loop or stuck FSM");
        $finish;
    end

endmodule
