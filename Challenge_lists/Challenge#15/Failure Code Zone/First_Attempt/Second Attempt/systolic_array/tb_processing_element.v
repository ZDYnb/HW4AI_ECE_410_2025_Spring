`timescale 1ns/1ps

module tb_processing_element;

    // Parameters for DUT
    localparam DATA_WIDTH   = 16;
    localparam WEIGHT_WIDTH = 8;
    localparam ACCUM_WIDTH  = 24;
    localparam CLK_PERIOD   = 10; // ns, for a 100MHz clock

    // Testbench signals
    reg                          clk;
    reg                          rst_n;
    reg                          pe_enable;
    reg  [DATA_WIDTH-1:0]        activation_in;
    reg  [WEIGHT_WIDTH-1:0]      weight_to_load;
    reg                          load_weight_en;
    reg  [ACCUM_WIDTH-1:0]       psum_in;

    wire [DATA_WIDTH-1:0]        activation_out;
    wire [ACCUM_WIDTH-1:0]       psum_out;
    wire                         data_out_valid;

    // Instantiate the Unit Under Test (DUT)
    processing_element #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pe_enable(pe_enable),
        .activation_in(activation_in),
        .activation_out(activation_out),
        .weight_to_load(weight_to_load),
        .load_weight_en(load_weight_en),
        .psum_in(psum_in),
        .psum_out(psum_out),
        .data_out_valid(data_out_valid)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Stimulus and test sequence
    initial begin
        // 1. Initialize all input signals
        rst_n = 0; // Assert reset
        pe_enable = 0;
        activation_in = 0;
        weight_to_load = 0;
        load_weight_en = 0;
        psum_in = 0;

        // 2. Release reset
        #(CLK_PERIOD * 2) rst_n = 1;
        $display("[%0t ns] TB: Reset Released.", $time);
        #(CLK_PERIOD);

        // --- Scenario 1: Weight Loading ---
        $display("[%0t ns] TB: Scenario 1: Weight Loading ---", $time);
        pe_enable = 1;
        load_weight_en = 1;
        weight_to_load = 8'd5; // Load weight = 5
        
        $display("[%0t ns] TB: Asserting load_weight_en=1, weight_to_load=5. Stored weight (dut.stored_weight_reg) should update on next posedge.", $time);
        #(CLK_PERIOD); // Wait for one clock cycle for the weight to be loaded (into dut.stored_weight_reg)

        load_weight_en = 0; // Disable weight loading
        $display("[%0t ns] TB: Deasserting load_weight_en. Stored weight should now be 5 and hold.", $time);
        // dut.stored_weight_reg is now 5.
        
        #(CLK_PERIOD); // Give one more cycle to observe stored weight is stable via monitor

        // --- Scenario 2: Basic MACC (using stored weight 5) ---
        // Inputs: activation_in = 2, psum_in = 10. Stored weight = 5.
        // Expected:
        //   activation_out = 2 (1 cycle after activation_in=2 is latched by PE)
        //   psum_out = 10 (psum_in) + (2 * 5) = 20 (2 cycles after inputs are latched by PE)
        $display("[%0t ns] TB: Scenario 2: Basic MACC (ActIn=2, PsumIn=10, StoredWeight=5) ---", $time);
        activation_in = 16'd2; // Applied at current time (let's call this T_input)
        psum_in       = 24'd10; // Applied at T_input
        // pe_enable is still 1, load_weight_en is 0.
        
        $display("[%0t ns] TB: Inputs: ActIn=2, PsumIn=10. Expect ActOut=2 at T_input+2*CP, PsumOut=20 at T_input+3*CP (from port perspective).", $time);
        // T_input + 1*CP: act_s1_reg becomes 2, psum_s1_reg becomes 10. act_out shows previous act_s1_reg.
        // T_input + 2*CP: act_out becomes 2. mac_product (2*5=10) is ready. psum_out uses previous psum_s1 and previous mac_product.
        // T_input + 3*CP: psum_out reflects psum_s1 (value 10) + mac_product (value 10).
        // Let's re-verify PE latency from code:
        // act_in -> act_s1_reg (1st clk after act_in)
        // act_out <= act_s1_reg (2nd clk after act_in, so act_out(T+2)=act_in(T))
        // psum_in -> psum_s1_reg (1st clk after psum_in)
        // mac_product uses act_s1_reg. mac_product is ready 1 clk after act_s1_reg is ready (2nd clk after act_in)
        // psum_out <= psum_s1_reg + mac_product (3rd clk after inputs)
        // So, activation_out latency is 2 cycles. psum_out latency is 3 cycles.
        
        #(CLK_PERIOD); // Current_Time = T_input + 1*CP. act_s1_reg=2, psum_s1_reg=10.
        $display("[%0t ns] TB: Cycle 1 post-input. act_s1_reg=%d, psum_s1_reg=%d. act_out=%d, psum_out=%d, valid=%b", 
                    $time, dut.activation_s1_reg, dut.psum_in_s1_reg, activation_out, psum_out, data_out_valid);

        #(CLK_PERIOD); // Current_Time = T_input + 2*CP. act_out should be 2. mac_product is 10.
        $display("[%0t ns] TB: Cycle 2 post-input. act_out=%d. Expect 2. (mac_product=%d). psum_out=%d, valid=%b", 
                    $time, activation_out, dut.mac_product_output, psum_out, data_out_valid);

        #(CLK_PERIOD); // Current_Time = T_input + 3*CP. psum_out should be 20.
        $display("[%0t ns] TB: Cycle 3 post-input. psum_out=%d. Expect 20. valid=%b", 
                    $time, psum_out, data_out_valid);

        #(CLK_PERIOD * 2); // Observe for a couple more cycles

        // --- End of basic tests ---
        pe_enable = 0; // Disable PE
        #(CLK_PERIOD * 2);

        $display("[%0t ns] TB: Testbench Finished.", $time);
        $finish;
    end

    // Monitor signals
    initial begin
        // Monitor a bit less frequently to reduce spam, e.g., at negedge or specific events
        // For now, standard monitor:
        $monitor("[%0t ns] CLK=%b RSTN=%b PE_EN=%b LOAD_W_EN=%b | A_in:%3d P_in:%3d W_load:%2d || StoredW:%2d A_s1:%3d P_s1:%3d MAC_prod:%3d MAC_vld:%b || A_out:%3d P_out:%3d PE_vld:%b",
                 $time, clk, rst_n, pe_enable, load_weight_en,
                 activation_in, psum_in, weight_to_load,
                 dut.stored_weight_reg, 
                 dut.activation_s1_reg, dut.psum_in_s1_reg, 
                 dut.mac_product_output, dut.mac_product_valid,
                 activation_out, psum_out, data_out_valid);
    end

endmodule
