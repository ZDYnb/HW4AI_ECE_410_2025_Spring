// tb_layer_norm_pe.v (Corrected DUT instantiation port name)
`timescale 1ns/1ps

module tb_layer_norm_pe;

    // Parameters for DUT instantiation & Testbench Control
    parameter D_MODEL_TB = 1; // Testing single PE, so D_MODEL for arrays is 1
    parameter PE_LATENCY_TB = 6; 

    // Data Format Parameters (matching DUT)
    parameter X_WIDTH = 16, X_FRAC = 10;
    parameter Y_WIDTH = 16, Y_FRAC = 10;
    parameter MU_WIDTH = 24, MU_FRAC = 10;
    parameter INV_STD_WIDTH = 24, INV_STD_FRAC = 14;
    parameter GAMMA_WIDTH = 8, GAMMA_FRAC = 6;
    parameter BETA_WIDTH = 8,  BETA_FRAC = 6;
    
    parameter PE_STAGE1_OUT_WIDTH = MU_WIDTH;
    parameter PE_STAGE1_OUT_FRAC = MU_FRAC;
    parameter PE_STAGE2_OUT_WIDTH = 24;
    parameter PE_STAGE2_OUT_FRAC = 21;
    parameter PE_STAGE3_OUT_WIDTH = 24;
    parameter PE_STAGE3_OUT_FRAC = 18;
    parameter PE_STAGE4_OUT_WIDTH = 24;
    parameter PE_STAGE4_OUT_FRAC = 18;

    // Test bench signals
    reg clk;
    reg rst_n;
    reg valid_in_pe_tb;
    reg signed [X_WIDTH-1:0]         x_i_in_tb;
    reg signed [MU_WIDTH-1:0]        mu_common_in_tb;
    reg signed [INV_STD_WIDTH-1:0]   inv_std_eff_common_in_tb; // This is the TB reg
    reg signed [GAMMA_WIDTH-1:0]     gamma_i_in_tb;
    reg signed [BETA_WIDTH-1:0]      beta_i_in_tb;
    
    wire signed [Y_WIDTH-1:0]         y_i_out_tb;
    wire                              valid_out_pe_tb;

    reg signed [Y_WIDTH-1:0]         expected_y_i_out_tb; 
    integer                           test_case_num; 

    // DUT Instantiation
    layer_norm_pe #(
        .X_WIDTH(X_WIDTH), .X_FRAC(X_FRAC), .MU_WIDTH(MU_WIDTH), .MU_FRAC(MU_FRAC),
        .INV_STD_WIDTH(INV_STD_WIDTH), .INV_STD_FRAC(INV_STD_FRAC),
        .GAMMA_WIDTH(GAMMA_WIDTH), .GAMMA_FRAC(GAMMA_FRAC),
        .BETA_WIDTH(BETA_WIDTH), .BETA_FRAC(BETA_FRAC),
        .Y_WIDTH(Y_WIDTH), .Y_FRAC(Y_FRAC),
        .STAGE1_OUT_WIDTH(PE_STAGE1_OUT_WIDTH), .STAGE1_OUT_FRAC(PE_STAGE1_OUT_FRAC),
        .STAGE2_OUT_WIDTH(PE_STAGE2_OUT_WIDTH), .STAGE2_OUT_FRAC(PE_STAGE2_OUT_FRAC),
        .STAGE3_OUT_WIDTH(PE_STAGE3_OUT_WIDTH), .STAGE3_OUT_FRAC(PE_STAGE3_OUT_FRAC),
        .STAGE4_OUT_WIDTH(PE_STAGE4_OUT_WIDTH), .STAGE4_OUT_FRAC(PE_STAGE4_OUT_FRAC)
    ) DUT (
        .clk(clk), .rst_n(rst_n), .valid_in_pe(valid_in_pe_tb),
        .x_i_in(x_i_in_tb), .mu_common_in(mu_common_in_tb), 
        .inv_std_eff_common_in(inv_std_eff_common_in_tb), // ** CORRECTED PORT CONNECTION NAME **
        .gamma_i_in(gamma_i_in_tb), .beta_i_in(beta_i_in_tb),
        .y_i_out(y_i_out_tb), .valid_out_pe(valid_out_pe_tb)
    );

    parameter CLK_PERIOD = 10;
    initial clk = 1'b0;
    always #((CLK_PERIOD)/2) clk = ~clk;

    task apply_pe_test; // Renamed from apply_and_check from other TB
        input signed [X_WIDTH-1:0]         x_i_val;
        input signed [MU_WIDTH-1:0]        mu_val;
        input signed [INV_STD_WIDTH-1:0]   inv_std_val;
        input signed [GAMMA_WIDTH-1:0]     gamma_val;
        input signed [BETA_WIDTH-1:0]      beta_val;
        input signed [Y_WIDTH-1:0]         expected_y_val;
        
        integer wait_cycles_task_local; 
        parameter TIMEOUT_PE_TASK = PE_LATENCY_TB + 14; // Latency + margin

        begin
            wait_cycles_task_local = 0; 
            test_case_num = test_case_num + 1;
            @(posedge clk);
            x_i_in_tb = x_i_val; 
            mu_common_in_tb = mu_val;
            inv_std_eff_common_in_tb = inv_std_val;
            gamma_i_in_tb = gamma_val;
            beta_i_in_tb = beta_val;
            expected_y_i_out_tb = expected_y_val; 
            valid_in_pe_tb = 1'b1;

            $display("[%t ns] TC%0d (PE): Applying x_i=%d, mu=%d, inv_std=%d, gamma=%d, beta=%d. Expect y_i=%d",
                     $time, test_case_num, x_i_val, mu_val, inv_std_val, gamma_val, beta_val, expected_y_val);
            
            @(posedge clk);
            valid_in_pe_tb = 1'b0;

            while (!valid_out_pe_tb && wait_cycles_task_local < TIMEOUT_PE_TASK) begin 
                @(posedge clk);
                wait_cycles_task_local = wait_cycles_task_local + 1;
            end

            if (valid_out_pe_tb) begin
                if (y_i_out_tb == expected_y_i_out_tb) begin
                    $display("[%t ns] TC%0d (PE) PASS: y_i_out = %d (waited %0d cycles)", 
                             $time, test_case_num, y_i_out_tb, wait_cycles_task_local);
                end else begin
                    $display("[%t ns] TC%0d (PE) FAIL: y_i_out = %d, Expected = %d (valid after %0d cycles)", 
                           $time, test_case_num, y_i_out_tb, expected_y_i_out_tb, wait_cycles_task_local);
                end
            end else begin
                $display("[%t ns] TC%0d (PE) FAIL: valid_out_pe_tb was not asserted within timeout (%0d cycles waited).", 
                         $time, test_case_num, wait_cycles_task_local); 
            end
            #(CLK_PERIOD * 2); 
        end
    endtask

    initial begin
        rst_n = 1'b0; 
        test_case_num = 0; 
        #(CLK_PERIOD * 2); 
        rst_n = 1'b1; 
        #(CLK_PERIOD);

        apply_pe_test(16'sd1024, 24'sd512, 24'sd32768, 8'sd80, 8'sd16, 16'sd1536);
        apply_pe_test(16'sd512,  24'sd512, 24'sd16384, 8'sd64, 8'sd32, 16'sd512);
        apply_pe_test(16'sd10240, 24'sd0, 24'sd1638, 8'sd64, 8'sd64, 16'sd2048); // Using your corrected TC3 beta and expected
        apply_pe_test(16'sd1024, 24'sd512, 24'sd32768, 8'sd80, 8'sd16, 16'sd1536);


        #(CLK_PERIOD * 10); 
        $display("[%t ns] PE Test bench finished.", $time);
        $finish;
    end
endmodule
