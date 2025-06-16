// tb_softmax_unit.v
`timescale 1ns / 1ps

module tb_softmax_unit;

    // Parameters for DUT instantiation - MATCHING softmax_unit's DEFAULTS from Canvas
    localparam N_TB                   = 4;
    localparam INPUT_DATA_WIDTH_TB    = 16; 
    localparam INPUT_FRAC_BITS_TB     = 8;
    localparam OUTPUT_DATA_WIDTH_TB   = 16; 
    localparam OUTPUT_FRAC_BITS_TB    = 15;

    // These are internal parameters of the DUT, but the TB needs to know them
    // to correctly instantiate the DUT and for its own expected value calculation.
    localparam DUT_MAX_VAL_WIDTH       = INPUT_DATA_WIDTH_TB; 
    localparam DUT_SHIFTED_X_WIDTH     = INPUT_DATA_WIDTH_TB + 1; 
    localparam DUT_SHIFTED_X_FRAC_BITS = INPUT_FRAC_BITS_TB; // Matches INPUT_FRAC_BITS_TB
    localparam EXP_UNIT_INPUT_WIDTH_TB    = 12; // Param for exp_inst
    localparam EXP_UNIT_INPUT_FRAC_TB  = 8;  // Param for exp_inst
    localparam EXP_UNIT_OUTPUT_WIDTH_TB   = 16; 
    localparam EXP_UNIT_OUTPUT_FRAC_TB  = 15; 
    
    localparam SUM_EXP_INT_BITS_TB    = $clog2(N_TB); 
    localparam SUM_EXP_WIDTH_TB       = 1 + SUM_EXP_INT_BITS_TB + EXP_UNIT_OUTPUT_FRAC_TB;
    
    localparam RECIP_SUM_FRAC_BITS_TB = 15; 
    localparam RECIP_SUM_WIDTH_TB     = 16; 

    localparam EXP_LATENCY_TB         = 1; 
    localparam RECIP_LATENCY_TB       = 5; 

    localparam CLK_PERIOD             = 10;

    localparam TB_FINAL_NORM_SHIFT = (EXP_UNIT_OUTPUT_FRAC_TB + RECIP_SUM_FRAC_BITS_TB) - OUTPUT_FRAC_BITS_TB;

    // DUT Interface Signals
    reg                               clk_tb;
    reg                               rst_n_tb;
    reg                               op_start_tb;
    reg signed [INPUT_DATA_WIDTH_TB-1:0] input_vector_x_tb [0:N_TB-1];
    wire signed [OUTPUT_DATA_WIDTH_TB-1:0] output_vector_y_dut [0:N_TB-1];
    wire                              op_busy_dut;
    wire                              op_done_dut;

    // Instantiate the DUT
    softmax_unit #(
        .N(N_TB),
        .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH_TB),
        .INPUT_FRAC_BITS(INPUT_FRAC_BITS_TB),
        .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH_TB),
        .OUTPUT_FRAC_BITS(OUTPUT_FRAC_BITS_TB),  
        
        .EXP_UNIT_INPUT_WIDTH(EXP_UNIT_INPUT_WIDTH_TB), 
        .EXP_UNIT_INPUT_FRAC(EXP_UNIT_INPUT_FRAC_TB),   
        .EXP_UNIT_OUTPUT_WIDTH(EXP_UNIT_OUTPUT_WIDTH_TB),
        .EXP_UNIT_OUTPUT_FRAC(EXP_UNIT_OUTPUT_FRAC_TB),
        .EXP_UNIT_LATENCY(EXP_LATENCY_TB),
        
        .SUM_EXP_WIDTH(SUM_EXP_WIDTH_TB),       
        .RECIP_SUM_FRAC_BITS(RECIP_SUM_FRAC_BITS_TB),
        .RECIP_SUM_WIDTH(RECIP_SUM_WIDTH_TB),
        .RECIP_LATENCY(RECIP_LATENCY_TB)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .op_start(op_start_tb),
        .input_vector_x(input_vector_x_tb),
        .output_vector_y(output_vector_y_dut),
        .op_busy(op_busy_dut),
        .op_done(op_done_dut)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    // Function to mimic DUT's placeholder exp logic as used by exp_lut_unit
    function signed [EXP_UNIT_OUTPUT_WIDTH_TB-1:0] calculate_tb_expected_exp;
        input signed [EXP_UNIT_INPUT_WIDTH_TB-1:0] shifted_x_for_exp; 
        // Local variables for function
        logic signed [EXP_UNIT_OUTPUT_WIDTH_TB-1:0] scaled_for_add_func;
        integer shift_to_exp_val_frac_func;
        localparam FUNC_LUT_ADDR_W = 8; 

        logic signed [EXP_UNIT_INPUT_WIDTH_TB-1:0] abs_x_val_func;
        // Corrected: Use EXP_UNIT_INPUT_FRAC_TB for width calculation
        logic [EXP_UNIT_INPUT_WIDTH_TB-1-EXP_UNIT_INPUT_FRAC_TB:0] abs_x_int_part_func; 
        logic [FUNC_LUT_ADDR_W-1:0] lut_addr_func;
        begin
            abs_x_val_func = (shifted_x_for_exp[EXP_UNIT_INPUT_WIDTH_TB-1] && shifted_x_for_exp != 0) ? -shifted_x_for_exp : shifted_x_for_exp;
            
            // Corrected: Use EXP_UNIT_INPUT_FRAC_TB for width calculation
            if (EXP_UNIT_INPUT_WIDTH_TB-1 >= EXP_UNIT_INPUT_FRAC_TB) begin
                 abs_x_int_part_func = abs_x_val_func[EXP_UNIT_INPUT_WIDTH_TB-1 : EXP_UNIT_INPUT_FRAC_TB];
            end else begin
                 abs_x_int_part_func = 0; 
            end

            // Corrected: Use EXP_UNIT_INPUT_FRAC_TB
            if (EXP_UNIT_INPUT_FRAC_TB > 0 && FUNC_LUT_ADDR_W <= EXP_UNIT_INPUT_FRAC_TB) begin
                lut_addr_func = abs_x_val_func[EXP_UNIT_INPUT_FRAC_TB-1 : EXP_UNIT_INPUT_FRAC_TB-FUNC_LUT_ADDR_W];
            end else if (EXP_UNIT_INPUT_FRAC_TB > 0 && FUNC_LUT_ADDR_W > EXP_UNIT_INPUT_FRAC_TB) begin
                lut_addr_func = abs_x_val_func[EXP_UNIT_INPUT_FRAC_TB-1 : 0]; 
            end else begin
                lut_addr_func = 0; 
            end

            if (shifted_x_for_exp == 0) begin 
                calculate_tb_expected_exp = (1 << EXP_UNIT_OUTPUT_FRAC_TB); 
            // Corrected: Use EXP_UNIT_INPUT_FRAC_TB
            end else if (shifted_x_for_exp < EXP_UNIT_INPUT_WIDTH_TB'(-5 * (1<<EXP_UNIT_INPUT_FRAC_TB)) ) begin 
                calculate_tb_expected_exp = EXP_UNIT_OUTPUT_WIDTH_TB'(1); 
            end else if (|abs_x_int_part_func && shifted_x_for_exp < 0) begin 
                calculate_tb_expected_exp = EXP_UNIT_OUTPUT_WIDTH_TB'(1);
            end else if (lut_addr_func == 8'd1 && shifted_x_for_exp < 0) begin 
                calculate_tb_expected_exp = 16'h7F80; 
            end else if (lut_addr_func == 8'd128 && shifted_x_for_exp < 0) begin 
                calculate_tb_expected_exp = 16'h4DA3; 
            end else begin 
                // Corrected: Use EXP_UNIT_INPUT_FRAC_TB
                shift_to_exp_val_frac_func = EXP_UNIT_INPUT_FRAC_TB - EXP_UNIT_OUTPUT_FRAC_TB;
                if (shift_to_exp_val_frac_func >= 0) begin
                    scaled_for_add_func = shifted_x_for_exp >>> shift_to_exp_val_frac_func;
                end else begin
                    scaled_for_add_func = shifted_x_for_exp <<< (-shift_to_exp_val_frac_func);
                end
                calculate_tb_expected_exp = $signed(scaled_for_add_func[EXP_UNIT_OUTPUT_WIDTH_TB-1:0]) + $signed(1 << EXP_UNIT_OUTPUT_FRAC_TB);
            end
        end
    endfunction

    initial begin
        integer i;
        reg signed [OUTPUT_DATA_WIDTH_TB-1:0] expected_y_fixed [0:N_TB-1];
        reg signed [EXP_UNIT_OUTPUT_WIDTH_TB-1:0] tb_exp_values [0:N_TB-1]; 
        reg signed [SUM_EXP_WIDTH_TB-1:0]   tb_sum_exp;               
        reg signed [RECIP_SUM_WIDTH_TB-1:0] tb_recip_sum_exp;         
        logic signed [EXP_UNIT_OUTPUT_WIDTH_TB + RECIP_SUM_WIDTH_TB - 1:0] temp_prod; 
        reg signed [INPUT_DATA_WIDTH_TB-1:0] tb_max_val_fixed;
        reg signed [EXP_UNIT_INPUT_WIDTH_TB-1:0] tb_shifted_x_for_exp_input_scaled; 
        integer shift_to_exp_in_frac_tb; 
        logic signed [INPUT_DATA_WIDTH_TB:0] temp_shifted_x_tb_local; 

        integer timeout_counter;
        integer max_timeout_cycles;
        logic test_passed;
        
        clk_tb = 1'b0; rst_n_tb = 1'b0; op_start_tb = 1'b0;
        max_timeout_cycles = (N_TB * (EXP_LATENCY_TB + RECIP_LATENCY_TB + 15)) + 150; 

        for (i = 0; i < N_TB; i = i + 1) input_vector_x_tb[i] = 0;

        $display("[%0t TB] Starting Softmax Unit Testbench (Aligned)...", $time);

        #(CLK_PERIOD * 2); rst_n_tb = 1'b1;
        $display("[%0t TB] Reset de-asserted.", $time); #(CLK_PERIOD);

        // --- Test Case 1: Input all zeros ---
        $display("[%0t TB] === Test Case 1: Input Vector All Zeros (Q%0d.%0d input) ===", 
                 $time, (INPUT_DATA_WIDTH_TB-INPUT_FRAC_BITS_TB-1), INPUT_FRAC_BITS_TB);
        for (i = 0; i < N_TB; i = i + 1) input_vector_x_tb[i] = 0; 

        tb_max_val_fixed = 0; tb_sum_exp = 0;
        for (i = 0; i < N_TB; i = i + 1) begin
            temp_shifted_x_tb_local = $signed(input_vector_x_tb[i]) - $signed(tb_max_val_fixed);
            
            shift_to_exp_in_frac_tb = INPUT_FRAC_BITS_TB - EXP_UNIT_INPUT_FRAC_TB; // Corrected
            if(shift_to_exp_in_frac_tb >=0) tb_shifted_x_for_exp_input_scaled = temp_shifted_x_tb_local >>> shift_to_exp_in_frac_tb;
            else tb_shifted_x_for_exp_input_scaled = temp_shifted_x_tb_local <<< (-shift_to_exp_in_frac_tb);
            tb_shifted_x_for_exp_input_scaled = tb_shifted_x_for_exp_input_scaled[EXP_UNIT_INPUT_WIDTH_TB-1:0];

            tb_exp_values[i] = calculate_tb_expected_exp(tb_shifted_x_for_exp_input_scaled);
            tb_sum_exp = tb_sum_exp + $signed({{(SUM_EXP_WIDTH_TB-EXP_UNIT_OUTPUT_WIDTH_TB){tb_exp_values[i][EXP_UNIT_OUTPUT_WIDTH_TB-1]}},tb_exp_values[i]});
        end
        // Corrected: Use EXP_UNIT_OUTPUT_FRAC_TB for reciprocal calculation consistency
        if (tb_sum_exp != 0) tb_recip_sum_exp = (1 << (RECIP_SUM_FRAC_BITS_TB + EXP_UNIT_OUTPUT_FRAC_TB)) / tb_sum_exp; 
        else tb_recip_sum_exp = 0;
        for (i = 0; i < N_TB; i = i + 1) begin
            temp_prod = $signed(tb_exp_values[i]) * $signed(tb_recip_sum_exp);
            if (TB_FINAL_NORM_SHIFT >= 0) expected_y_fixed[i] = temp_prod >>> TB_FINAL_NORM_SHIFT;
            else expected_y_fixed[i] = temp_prod <<< (-TB_FINAL_NORM_SHIFT);
        end
        
        $write("[%0t TB] TC1 Expected Y (Q%0d.%0d): [", $time, (OUTPUT_DATA_WIDTH_TB-OUTPUT_FRAC_BITS_TB-1), OUTPUT_FRAC_BITS_TB);
        for (i = 0; i < N_TB; i = i+1) $write("%d ", expected_y_fixed[i]); $display("]");

        op_start_tb = 1'b0; @(posedge clk_tb); op_start_tb = 1'b1; @(posedge clk_tb); op_start_tb = 1'b0; 
        $display("[%0t TB] TC1 op_start pulse sent.", $time);
        
        timeout_counter = 0;
        if(!op_busy_dut && op_start_tb==1'b0) @(posedge clk_tb); 
        if(!op_busy_dut && op_start_tb==1'b0) $error("TC1 DUT did not become busy!"); 
        else if (op_busy_dut) $display("TC1 DUT is busy...");

        while (!op_done_dut && op_busy_dut && timeout_counter < max_timeout_cycles) begin @(posedge clk_tb); timeout_counter = timeout_counter + 1; end

        if (timeout_counter >= max_timeout_cycles) $error("TC1 TIMEOUT");
        else if (op_done_dut) begin 
            @(posedge clk_tb); $display("TC1 op_done_dut received."); test_passed = 1'b1; 
            for (i = 0; i < N_TB; i = i + 1) begin
                if (output_vector_y_dut[i] !== expected_y_fixed[i]) begin
                    if (!((output_vector_y_dut[i] >= expected_y_fixed[i] - 2) && (output_vector_y_dut[i] <= expected_y_fixed[i] + 2))) begin
                        $error("TC1 FAILED Output[%0d]. E:%d G:%d", i, expected_y_fixed[i], output_vector_y_dut[i]); test_passed = 1'b0;
                    end else $display("TC1 Output[%0d] +/-2 LSB. E:%d G:%d", i, expected_y_fixed[i], output_vector_y_dut[i]);
                end
            end
            if (test_passed) $display("TC1 PASSED (allowing +/-2 LSB)."); else $display("TC1 FAILED overall.");
        end
        #(CLK_PERIOD * 3); 

        // --- Test Case 2: Varied Inputs ---
        $display("[%0t TB] === Test Case 2: Varied Inputs (Q%0d.%0d) ===", $time, (INPUT_DATA_WIDTH_TB-INPUT_FRAC_BITS_TB-1), INPUT_FRAC_BITS_TB);
        input_vector_x_tb[0] = $rtoi(0.0 * (1<<INPUT_FRAC_BITS_TB));   
        input_vector_x_tb[1] = $rtoi(-1.0 * (1<<INPUT_FRAC_BITS_TB)); 
        input_vector_x_tb[2] = $rtoi(1.0 * (1<<INPUT_FRAC_BITS_TB));  
        input_vector_x_tb[3] = $rtoi(-2.0 * (1<<INPUT_FRAC_BITS_TB)); 
        $display("[%0t TB] TC2 Inputs (Q%0d.%0d): [%d, %d, %d, %d]", $time, 
            (INPUT_DATA_WIDTH_TB-INPUT_FRAC_BITS_TB-1), INPUT_FRAC_BITS_TB,
            input_vector_x_tb[0], input_vector_x_tb[1], input_vector_x_tb[2], input_vector_x_tb[3]);

        tb_max_val_fixed = input_vector_x_tb[0]; 
        for (i = 1; i < N_TB; i = i + 1) if (input_vector_x_tb[i] > tb_max_val_fixed) tb_max_val_fixed = input_vector_x_tb[i];
        $display("[%0t TB] TC2 MaxVal (fixed Q%0d.%0d): %d", $time, (INPUT_DATA_WIDTH_TB-INPUT_FRAC_BITS_TB-1), INPUT_FRAC_BITS_TB, tb_max_val_fixed);
        
        tb_sum_exp = 0;
        for (i = 0; i < N_TB; i = i + 1) begin
            temp_shifted_x_tb_local = $signed(input_vector_x_tb[i]) - $signed(tb_max_val_fixed);
            
            shift_to_exp_in_frac_tb = INPUT_FRAC_BITS_TB - EXP_UNIT_INPUT_FRAC_TB; // Corrected
            if(shift_to_exp_in_frac_tb >=0) tb_shifted_x_for_exp_input_scaled = temp_shifted_x_tb_local >>> shift_to_exp_in_frac_tb;
            else tb_shifted_x_for_exp_input_scaled = temp_shifted_x_tb_local <<< (-shift_to_exp_in_frac_tb);
            tb_shifted_x_for_exp_input_scaled = tb_shifted_x_for_exp_input_scaled[EXP_UNIT_INPUT_WIDTH_TB-1:0];

            tb_exp_values[i] = calculate_tb_expected_exp(tb_shifted_x_for_exp_input_scaled);
            $display("[%0t TB] TC2: x_in=%d, shifted_for_exp(Q%0d.%0d)=%d, exp_val(Q%0d.%0d)=%d", $time, 
                input_vector_x_tb[i], 
                (EXP_UNIT_INPUT_WIDTH_TB-EXP_UNIT_INPUT_FRAC_TB-1), EXP_UNIT_INPUT_FRAC_TB, tb_shifted_x_for_exp_input_scaled, 
                (EXP_UNIT_OUTPUT_WIDTH_TB-EXP_UNIT_OUTPUT_FRAC_TB-1), EXP_UNIT_OUTPUT_FRAC_TB, tb_exp_values[i]);
            tb_sum_exp = tb_sum_exp + $signed({{(SUM_EXP_WIDTH_TB-EXP_UNIT_OUTPUT_WIDTH_TB){tb_exp_values[i][EXP_UNIT_OUTPUT_WIDTH_TB-1]}},tb_exp_values[i]});
        end
        $display("[%0t TB] TC2 SumExp (fixed Q%0d.%0d): %d", $time, 
                 (SUM_EXP_WIDTH_TB-EXP_UNIT_OUTPUT_FRAC_TB-1), EXP_UNIT_OUTPUT_FRAC_TB, tb_sum_exp); 

        // Corrected: Use EXP_UNIT_OUTPUT_FRAC_TB for reciprocal calculation consistency
        if (tb_sum_exp != 0) tb_recip_sum_exp = (1 << (RECIP_SUM_FRAC_BITS_TB + EXP_UNIT_OUTPUT_FRAC_TB)) / tb_sum_exp; 
        else tb_recip_sum_exp = 0;
        $display("[%0t TB] TC2 RecipSumExp (fixed Q%0d.%0d): %d", $time, 
                 (RECIP_SUM_WIDTH_TB-RECIP_SUM_FRAC_BITS_TB-1),RECIP_SUM_FRAC_BITS_TB, tb_recip_sum_exp);
        
        for (i = 0; i < N_TB; i = i + 1) begin
            temp_prod = $signed(tb_exp_values[i]) * $signed(tb_recip_sum_exp);
            if (TB_FINAL_NORM_SHIFT >= 0) expected_y_fixed[i] = temp_prod >>> TB_FINAL_NORM_SHIFT;
            else expected_y_fixed[i] = temp_prod <<< (-TB_FINAL_NORM_SHIFT);
        end

        $write("[%0t TB] TC2 Expected Y (fixed Q%0d.%0d): [", $time, (OUTPUT_DATA_WIDTH_TB-OUTPUT_FRAC_BITS_TB-1), OUTPUT_FRAC_BITS_TB);
        for (i = 0; i < N_TB; i = i+1) $write("%h ", expected_y_fixed[i]); $display("]");

        op_start_tb = 1'b0; @(posedge clk_tb); op_start_tb = 1'b1; @(posedge clk_tb); op_start_tb = 1'b0; 
        $display("[%0t TB] TC2 op_start pulse sent.", $time);
        
        timeout_counter = 0;
        if(!op_busy_dut) @(posedge clk_tb); 
        if(!op_busy_dut && op_start_tb==1'b0) $error("TC2 DUT did not become busy!"); else $display("TC2 DUT is busy...");

        while (!op_done_dut && op_busy_dut && timeout_counter < max_timeout_cycles) begin @(posedge clk_tb); timeout_counter = timeout_counter + 1; end

        if (timeout_counter >= max_timeout_cycles) $error("TC2 TIMEOUT");
        else if (op_done_dut) begin 
            @(posedge clk_tb); $display("TC2 op_done_dut received."); test_passed = 1'b1; 
            for (i = 0; i < N_TB; i = i + 1) begin
                 $display("[%0t TB] Checking Output[%0d]: Expected_Fixed: %h, DUT_Out: %h", 
                         $time, i, expected_y_fixed[i], output_vector_y_dut[i]);
                if (output_vector_y_dut[i] !== expected_y_fixed[i]) begin
                    if (!((output_vector_y_dut[i] >= expected_y_fixed[i] - 5) && (output_vector_y_dut[i] <= expected_y_fixed[i] + 5))) begin 
                        $error("TC2 FAILED Output[%0d]. E:%h G:%h", i, expected_y_fixed[i], output_vector_y_dut[i]); test_passed = 1'b0;
                    end else $display("TC2 Output[%0d] within +/-5 LSB. E:%h G:%h", i, expected_y_fixed[i], output_vector_y_dut[i]);
                end
            end
            if (test_passed) $display("TC2 PASSED (allowing +/-5 LSB diff)."); else $display("TC2 FAILED overall.");
        end

        #(CLK_PERIOD * 5); 
        $display("[%0t TB] Softmax Unit Testbench Finished.", $time);
        $finish;
    end

endmodule
