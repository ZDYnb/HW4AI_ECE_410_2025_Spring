`timescale 1ns / 1ps

//******************************************************************************
// Module: testbench
// Description:
//   - Verifies the top-level design which contains the streaming controller
//     and the LayerNorm core.
//******************************************************************************
module testbench;

    // -- Parameters --
    localparam D_MODEL    = 64;
    localparam DATA_WIDTH = 16;
    localparam CLK_PERIOD = 10;

    // -- Testbench Internal Signals --
    reg clk;
    reg rst_n;

    // -- Wires to connect to the DUT (top module) --
    reg  start_processing;
    wire processing_done;
    reg  spi_word_valid;
    reg  [DATA_WIDTH-1:0] spi_word_in;
    wire in_ready;

    // 1. Instantiate the complete Top-Level Design
    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_processing(start_processing),
        .processing_done(processing_done),
        .spi_word_valid(spi_word_valid),
        .spi_word_in(spi_word_in),
        .in_ready(in_ready)
    );

    // 2. Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 3. Test Sequence and Stimulus
    initial begin
        $display("Testbench: Simulation Started at time %0t", $time);
        rst_n = 1'b0;
        start_processing = 1'b0;
        spi_word_valid = 1'b0;
        spi_word_in = 0;
        # (CLK_PERIOD * 2);
        rst_n = 1'b1;
        $display("Testbench: Reset released at time %0t", $time);
        
        // --- Fork two parallel processes: one for sending data, one for control ---
        fork
            // Process 1: Control the start and end of the test
            begin
                @(posedge clk);
                start_processing = 1'b1;
                @(posedge clk);
                start_processing = 1'b0;

                wait (processing_done == 1'b1);
                @(posedge clk);

                $display("Testbench: 'processing_done' signal received at time %0t. TEST PASSED!", $time);
                #100;
                $finish;
            end

            // Process 2: The data sender (SPI Master)
            begin
                for (integer col = 0; col < D_MODEL; col = col + 1) begin
                    $display("Testbench: Starting to send column %0d at time %0t", col, $time);
                    send_one_column(col);
                    $display("Testbench: Finished sending column %0d.", col);
                end
                $display("Testbench: All columns sent.");
            end
        join
    end

    // -- Task to send one full column (64 words) --
    task send_one_column(input integer col_num);
        begin
            for (integer word_idx = 0; word_idx < D_MODEL; word_idx = word_idx + 1) begin
                wait (in_ready == 1'b1);
                @(posedge clk);
                spi_word_valid <= 1'b1;
                spi_word_in <= col_num * 100 + word_idx;
                @(posedge clk);
                spi_word_valid <= 1'b0;
            end
        end
    endtask

endmodule
