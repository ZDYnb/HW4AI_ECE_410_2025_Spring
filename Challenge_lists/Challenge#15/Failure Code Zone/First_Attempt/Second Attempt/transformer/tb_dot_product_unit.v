// tb_dot_product_unit.v (Corrected syntax in if-else if)
`timescale 1ns / 1ps

module tb_dot_product_unit;

    // Parameters from DUT (or matching them)
    localparam DATA_WIDTH              = 8;
    localparam ACCUM_WIDTH             = 32;
    localparam MAX_VECTOR_LENGTH_PARAM = 1024; // Matches DUT
    localparam CLK_PERIOD              = 10;   // 10ns => 100 MHz

    // Testbench specific parameters
    localparam TEST_VEC_MAX_LEN = 16; // Max length of test vectors stored in TB

    // DUT Interface Signals
    reg                               clk;
    reg                               rst_n;
    reg                               start_pulse;
    reg [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] current_vector_length;
    reg signed [DATA_WIDTH-1:0]       vec_a_element_in_tb;
    reg signed [DATA_WIDTH-1:0]       vec_b_element_in_tb;

    wire signed [ACCUM_WIDTH-1:0]     result_out_dut;
    wire                              result_valid_dut;
    wire                              busy_dut;
    wire                              request_next_elements_dut;

    // Test vector storage
    reg signed [DATA_WIDTH-1:0] test_vector_a [0:TEST_VEC_MAX_LEN-1];
    reg signed [DATA_WIDTH-1:0] test_vector_b [0:TEST_VEC_MAX_LEN-1];
    reg signed [ACCUM_WIDTH-1:0]expected_dot_product;

    // Internal TB signals
    reg [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] elements_sent_count_for_always;
    reg test_active;


    // Instantiate the DUT
    dot_product_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .MAX_VECTOR_LENGTH_PARAM(MAX_VECTOR_LENGTH_PARAM)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_pulse),
        .vector_length(current_vector_length),
        .vec_a_element_in(vec_a_element_in_tb),
        .vec_b_element_in(vec_b_element_in_tb),
        .result_out(result_out_dut),
        .result_valid(result_valid_dut),
        .busy(busy_dut),
        .request_next_elements(request_next_elements_dut)
    );

    // Clock generation
    always # (CLK_PERIOD/2) clk = ~clk;

    // Handle providing vector elements when requested
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vec_a_element_in_tb <= 0;
            vec_b_element_in_tb <= 0;
            elements_sent_count_for_always <= 0;
        end else begin
            if (test_active && request_next_elements_dut) begin
                if (elements_sent_count_for_always < current_vector_length) begin
                    vec_a_element_in_tb <= test_vector_a[elements_sent_count_for_always];
                    vec_b_element_in_tb <= test_vector_b[elements_sent_count_for_always];
                    $display("[%0t TB] Feeding DUT: A[%0d]=%d, B[%0d]=%d",
                             $time, elements_sent_count_for_always, test_vector_a[elements_sent_count_for_always],
                             elements_sent_count_for_always, test_vector_b[elements_sent_count_for_always]);
                    elements_sent_count_for_always <= elements_sent_count_for_always + 1;
                end else begin 
                    vec_a_element_in_tb <= 0; 
                    vec_b_element_in_tb <= 0;
                end
            end else if (test_active && elements_sent_count_for_always >= current_vector_length && !busy_dut) begin
                vec_a_element_in_tb <= 0; 
                vec_b_element_in_tb <= 0;
            end
        end
    end

    // Test sequence
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start_pulse = 1'b0;
        current_vector_length = 0;
        vec_a_element_in_tb = 0; 
        vec_b_element_in_tb = 0;
        test_active = 1'b0;

        $display("[%0t TB] Starting Dot Product Unit Testbench...", $time);

        test_vector_a[0] = 1; test_vector_b[0] = 10;
        test_vector_a[1] = 2; test_vector_b[1] = -2;
        test_vector_a[2] = 3; test_vector_b[2] = 3;
        test_vector_a[3] = -4; test_vector_b[3] = 5;
        test_vector_a[4] = 5; test_vector_b[4] = 1;

        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time);
        #(CLK_PERIOD);

        // --- Test Case 1: Vector Length 3 ---
        $display("[%0t TB] === Test Case 1: Vector Length 3 ===", $time);
        current_vector_length = 3; 
        expected_dot_product = 15;
        elements_sent_count_for_always = 0; 
        test_active = 1'b1;

        start_pulse = 1'b0; 
        @(posedge clk); 
        start_pulse = 1'b1; 
        @(posedge clk);     
        start_pulse = 1'b0; 
        $display("[%0t TB] Start pulse sequence completed for TC1 (length %0d).", $time, current_vector_length);

        @(posedge clk); 
        if (!busy_dut && test_active) begin
             $error("[%0t TB] TC1 Error: DUT did not become busy after start!", $time);
        end else if (busy_dut && test_active) begin // CORRECTED HERE
             $display("[%0t TB] DUT is busy for TC1, proceeding.", $time);
        end                                         // CORRECTED HERE
        
        while(busy_dut) begin
            @(posedge clk);
        end
        
        @(posedge clk); 

        $display("[%0t TB] TC1 DUT finished. Sampled result_out: %d (Expected: %d).", 
                 $time, result_out_dut, expected_dot_product);
        if (result_out_dut == expected_dot_product) begin
            $display("[%0t TB] Test Case 1 PASSED.", $time);
        end else begin
            $error("[%0t TB] Test Case 1 FAILED. Expected: %d, Got: %d", $time, expected_dot_product, result_out_dut);
        end
        test_active = 1'b0; 
        #(CLK_PERIOD * 3); 


        // --- Test Case 2: Vector Length 5 ---
        $display("[%0t TB] === Test Case 2: Vector Length 5 ===", $time);
        current_vector_length = 5; 
        expected_dot_product = 0;
        elements_sent_count_for_always = 0; 
        test_active = 1'b1;

        start_pulse = 1'b0; 
        @(posedge clk); 
        start_pulse = 1'b1; 
        @(posedge clk);     
        start_pulse = 1'b0; 
        $display("[%0t TB] Start pulse sequence completed for TC2 (length %0d).", $time, current_vector_length);

        @(posedge clk); 
        if (!busy_dut && test_active) begin
             $error("[%0t TB] TC2 Error: DUT did not become busy after start!", $time);
        end else if (busy_dut && test_active) begin // CORRECTED HERE
             $display("[%0t TB] DUT is busy for TC2, proceeding.", $time);
        end                                         // CORRECTED HERE
        
        while(busy_dut) begin
            @(posedge clk);
        end
        
        @(posedge clk); 

        $display("[%0t TB] TC2 DUT finished. Sampled result_out: %d (Expected: %d).", 
                 $time, result_out_dut, expected_dot_product);
        if (result_out_dut == expected_dot_product) begin
            $display("[%0t TB] Test Case 2 PASSED.", $time);
        end else begin
            $error("[%0t TB] Test Case 2 FAILED. Expected: %d, Got: %d", $time, expected_dot_product, result_out_dut);
        end
        test_active = 1'b0; 
        #(CLK_PERIOD * 3);


        $display("[%0t TB] Dot Product Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
