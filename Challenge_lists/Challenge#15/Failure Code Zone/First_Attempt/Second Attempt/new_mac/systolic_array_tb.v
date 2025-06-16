// ===========================================
// Testbench for systolic_array
// ===========================================
`timescale 1ns/1ps

module systolic_array_tb;

    // Parameters for the Systolic Array instance
    localparam TB_PE_ROWS = 4; // Scaled up
    localparam TB_PE_COLS = 4; // Scaled up
    localparam DATA_WIDTH = 16;            // Activation width (S5.10)
    localparam WEIGHT_WIDTH = 8;           // Weight width (S1.6)
    localparam MAC_ACCUM_WIDTH = 24;       // Accumulator width (S7.16)
    localparam MAC_ACCUM_FRAC_BITS = 16;   // For reference in test value calculation

    // Testbench signals - Corrected Unpacked Array Syntax
    reg                                 clk;
    reg                                 rst_n;
    reg                                 global_clear_accum;

    reg      [DATA_WIDTH-1:0]           activations_in_L_tb [TB_PE_ROWS-1:0];
    reg                                 activations_valid_in_L_tb [TB_PE_ROWS-1:0];

    reg      [WEIGHT_WIDTH-1:0]         weights_in_T_tb [TB_PE_COLS-1:0];
    reg                                 weights_valid_in_T_tb [TB_PE_COLS-1:0];

    wire     [MAC_ACCUM_WIDTH-1:0]      results_out_tb [TB_PE_ROWS-1:0][TB_PE_COLS-1:0];
    wire                                results_valid_out_tb [TB_PE_ROWS-1:0][TB_PE_COLS-1:0];

    wire     [DATA_WIDTH-1:0]           activations_out_R_tb [TB_PE_ROWS-1:0];
    wire                                activations_valid_out_R_tb [TB_PE_ROWS-1:0];

    wire     [WEIGHT_WIDTH-1:0]         weights_out_B_tb [TB_PE_COLS-1:0];
    wire                                weights_valid_out_B_tb [TB_PE_COLS-1:0];

    // Instantiate the DUT (Device Under Test)
    systolic_array #(
        .PE_ROWS(TB_PE_ROWS),
        .PE_COLS(TB_PE_COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .MAC_ACCUM_WIDTH(MAC_ACCUM_WIDTH),
        .MAC_ACCUM_FRAC_BITS(MAC_ACCUM_FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .global_clear_accum(global_clear_accum),

        .activations_in_L(activations_in_L_tb),
        .activations_valid_in_L(activations_valid_in_L_tb),

        .weights_in_T(weights_in_T_tb),
        .weights_valid_in_T(weights_valid_in_T_tb),

        .results_out(results_out_tb),
        .results_valid_out(results_valid_out_tb),

        .activations_out_R(activations_out_R_tb),
        .activations_valid_out_R(activations_valid_out_R_tb),

        .weights_out_B(weights_out_B_tb),
        .weights_valid_out_B(weights_valid_out_B_tb)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz
    end

    // Test sequence
    initial begin
        integer r, c; // For loops in Test Case 2
        integer k_cycles_to_hold_valid;
        integer wait_cycles_for_results;

        $display("========================================================");
        $display("TB: Starting Testbench for %0dx%0d Systolic Array", TB_PE_ROWS, TB_PE_COLS);
        $display("========================================================");

        // Initialize inputs
        rst_n = 0; // Assert reset initially
        global_clear_accum = 0;
        // Initialize multi-dimensional arrays properly
        foreach (activations_in_L_tb[i]) activations_in_L_tb[i] = {DATA_WIDTH{1'b0}};
        foreach (activations_valid_in_L_tb[i]) activations_valid_in_L_tb[i] = 1'b0;
        foreach (weights_in_T_tb[i]) weights_in_T_tb[i] = {WEIGHT_WIDTH{1'b0}};
        foreach (weights_valid_in_T_tb[i]) weights_valid_in_T_tb[i] = 1'b0;


        // Apply reset
        #10; // Wait a bit
        // rst_n is already 0
        $display("TB: [%0t ns] Asserting reset (rst_n = 0)", $time);
        #20; // Hold reset for 2 clock cycles

        rst_n = 1;
        $display("TB: [%0t ns] Releasing reset (rst_n = 1)", $time);
        #10; // Wait for reset to propagate

        // Test Case 1: Single activation and weight input to PE[0][0]
        $display("\nTB: [%0t ns] Test Case 1: Single input to PE[0][0]", $time);
        global_clear_accum = 1; // Clear accumulator for the first operation

        activations_in_L_tb[0] = 16'h0A00; // Represents 2.5
        activations_valid_in_L_tb[0] = 1'b1;
        weights_in_T_tb[0] = 8'h50;       // Represents 1.25
        weights_valid_in_T_tb[0] = 1'b1;
        
        for (r = 1; r < TB_PE_ROWS; r = r + 1) begin
            activations_in_L_tb[r] = {DATA_WIDTH{1'b0}};
            activations_valid_in_L_tb[r] = 1'b0;
        end
        for (c = 1; c < TB_PE_COLS; c = c + 1) begin
            weights_in_T_tb[c] = {WEIGHT_WIDTH{1'b0}};
            weights_valid_in_T_tb[c] = 1'b0;
        end

        @(posedge clk); // Cycle 1 after inputs applied
        $display("TB: [%0t ns] TC1 Cycle 1: Inputs applied to PE[0][0]. global_clear_accum was 1.", $time);
        $display("   PE[0][0] Actual Inputs: data_in_L=%h (valid=%b), weight_in_T=%h (valid=%b)",
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.data_in_L,
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.data_valid_in_L,
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.weight_in_T,
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.weight_valid_in_T);
        $display("   PE[0][0] MAC State: enable_mac=%b, clear_accum_internal=%b",
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.mac_inst.enable_mac,
                 dut.row_generate_block[0].col_generate_block[0].pe_instance.mac_inst.clear_accum);

        global_clear_accum = 0; 
        activations_valid_in_L_tb[0] = 1'b0; // Make input transient
        weights_valid_in_T_tb[0] = 1'b0;     // Make input transient

        @(posedge clk); // Cycle 2
        $display("TB: [%0t ns] TC1 Cycle 2: global_clear_accum is 0. Inputs to PE[0][0] are now invalid.", $time);
        $display("   PE[0][0] Output: result_out=%h (expected 24'h032000), valid=%b (expected 1)", results_out_tb[0][0], results_valid_out_tb[0][0]);
        
        repeat (TB_PE_COLS + TB_PE_ROWS) @(posedge clk); 

        $display("TB: [%0t ns] TC1 After Propagation Delay:", $time);
        $display("   PE[0][0] Output: result_out=%h, valid=%b (valid should be 0 now)", results_out_tb[0][0], results_valid_out_tb[0][0]);
        for (r = 0; r < TB_PE_ROWS; r = r + 1) begin
            $display("   Activations Out (R)[%0d]: data=%h, valid=%b", r, activations_out_R_tb[r], activations_valid_out_R_tb[r]);
        end
        for (c = 0; c < TB_PE_COLS; c = c + 1) begin
            $display("   Weights Out (B)[%0d]: data=%h, valid=%b", c, weights_out_B_tb[c], weights_valid_out_B_tb[c]);
        end

        // Test Case 2: Apply sustained inputs to array edges
        $display("\nTB: [%0t ns] Test Case 2: Sustained inputs to array edges", $time);
        global_clear_accum = 1; 

        @(posedge clk); // Apply clear
        global_clear_accum = 0; 

        // Apply new data values
        for (r = 0; r < TB_PE_ROWS; r = r + 1) begin
            activations_in_L_tb[r] = DATA_WIDTH'(100 + r); 
        end
        for (c = 0; c < TB_PE_COLS; c = c + 1) begin
            weights_in_T_tb[c] = WEIGHT_WIDTH'(10 + c); 
        end

        // Assert valids for enough time for the wavefront to form and all PEs to compute once.
        // PE[r][c] becomes active (gets both valid inputs) at relative cycle max(r,c)
        // The input valid signals must be held at the boundary for at least this long.
        // For a 4x4 array, PE[3][3] is active at relative cycle 3.
        // So, hold valids for max(TB_PE_ROWS-1, TB_PE_COLS-1) + 1 = max(3,3)+1 = 4 cycles.
        k_cycles_to_hold_valid = (TB_PE_ROWS > TB_PE_COLS) ? TB_PE_ROWS : TB_PE_COLS;
        // Or more simply, hold for R+C-1 to ensure PE[R-1][C-1] gets its chance.
        // k_cycles_to_hold_valid = TB_PE_ROWS + TB_PE_COLS - 1; // e.g. 4+4-1 = 7 for PE[3][3]
        // Let's use a duration that ensures the PE that is furthest from one edge
        // receives its direct input valid while the propagated input is also arriving valid.
        // Hold activation valids for TB_PE_COLS cycles. Hold weight valids for TB_PE_ROWS cycles.
        
        $display("TB: [%0t ns] TC2 Applying sustained valids for %0d (acts) and %0d (wgts) cycles.", $time, TB_PE_COLS, TB_PE_ROWS);

        for (integer i = 0; i < k_cycles_to_hold_valid; i = i + 1) begin
            if (i < TB_PE_COLS) begin // Hold activation valids for TB_PE_COLS cycles
                 for (r = 0; r < TB_PE_ROWS; r = r + 1) activations_valid_in_L_tb[r] = 1'b1;
            end else begin
                 for (r = 0; r < TB_PE_ROWS; r = r + 1) activations_valid_in_L_tb[r] = 1'b0;
            end

            if (i < TB_PE_ROWS) begin // Hold weight valids for TB_PE_ROWS cycles
                for (c = 0; c < TB_PE_COLS; c = c + 1) weights_valid_in_T_tb[c] = 1'b1;
            end else begin
                 for (c = 0; c < TB_PE_COLS; c = c + 1) weights_valid_in_T_tb[c] = 1'b0;
            end
            @(posedge clk);
        end
        
        // Ensure all valids are low after the sustained input period
        for (r = 0; r < TB_PE_ROWS; r = r + 1) activations_valid_in_L_tb[r] = 1'b0; 
        for (c = 0; c < TB_PE_COLS; c = c + 1) weights_valid_in_T_tb[c] = 1'b0;     
        $display("TB: [%0t ns] TC2 De-asserted all input valids.", $time);

        // Wait for results to be computed and propagate.
        // The last PE to complete its first computation is PE[R-1][C-1].
        // It becomes active at cycle max(R-1, C-1) after start of sustained input.
        // Its result is valid one cycle later: max(R-1, C-1) + 1.
        // We have already waited k_cycles_to_hold_valid.
        // If k_cycles_to_hold_valid = max(R,C), then PE[R-1][C-1] result is ready.
        // Add a few extra cycles for safety and for valid flags to propagate if they were latched.
        wait_cycles_for_results = (TB_PE_ROWS + TB_PE_COLS); // Generous wait
        repeat (wait_cycles_for_results) @(posedge clk); 

        $display("TB: [%0t ns] TC2 After Propagation & Computation Delay (sustained input):", $time);
        for (r = 0; r < TB_PE_ROWS; r = r + 1) begin
            for (c = 0; c < TB_PE_COLS; c = c + 1) begin
                integer expected_act_val, expected_weight_val, expected_product_int;
                logic [MAC_ACCUM_WIDTH-1:0] expected_product_hex;
                expected_act_val = 100 + r;
                expected_weight_val = 10 + c;
                expected_product_int = expected_act_val * expected_weight_val;
                expected_product_hex = MAC_ACCUM_WIDTH'(expected_product_int); // Integer product directly
                
                $display("   PE[%0d][%0d] Output: result_out=%h, valid=%b. (Expected product: %0d -> %h)",
                         r, c, results_out_tb[r][c], results_valid_out_tb[r][c], 
                         expected_product_int, expected_product_hex);
            end
        end
        
        #100; 
        $display("TB: [%0t ns] Testbench finished.", $time);
        $finish;
    end

endmodule

