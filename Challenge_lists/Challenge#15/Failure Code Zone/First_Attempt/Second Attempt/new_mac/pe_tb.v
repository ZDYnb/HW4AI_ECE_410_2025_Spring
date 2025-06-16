`timescale 1ns/1ps
module pe_tb;

    // ==========================================
    // Parameters (Match PE and MAC unit parameters)
    // ==========================================
    parameter DATA_WIDTH = 16;
    parameter WEIGHT_WIDTH = 8;
    parameter ACCUM_WIDTH = 32;

    // ==========================================
    // TB Signals
    // ==========================================
    reg                       clk;
    reg                       rst_n;
    reg                       global_clear_accum;

    reg  [DATA_WIDTH-1:0]     data_in_L;
    reg                       data_valid_in_L;
    reg  [WEIGHT_WIDTH-1:0]   weight_in_T;
    reg                       weight_valid_in_T;

    wire [DATA_WIDTH-1:0]     data_out_R;
    wire                      data_valid_out_R;
    wire [WEIGHT_WIDTH-1:0]   weight_out_B;
    wire                      weight_valid_out_B;
    wire [ACCUM_WIDTH-1:0]    pe_accum_out;
    wire                      pe_result_valid;

    // ==========================================
    // Instantiate the Processing Element (DUT - Device Under Test)
    // ==========================================
    processing_element #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .global_clear_accum(global_clear_accum), // This signal will be registered inside PE
        
        .data_in_L(data_in_L),
        .data_valid_in_L(data_valid_in_L),
        .data_out_R(data_out_R),
        .data_valid_out_R(data_valid_out_R),
        
        .weight_in_T(weight_in_T),
        .weight_valid_in_T(weight_valid_in_T),
        .weight_out_B(weight_out_B),
        .weight_valid_out_B(weight_valid_out_B),
        
        .pe_accum_out(pe_accum_out),
        .pe_result_valid(pe_result_valid)
    );

    // ==========================================
    // Clock Generation
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz clock
    end

    // --- Debugging for Data Flow (Print internal signals of DUT) ---
    always @(posedge clk) begin
        if (rst_n) begin // Only display after reset is released for clarity
            $display("--- Current State at Time %0d ---", $time);
            $display("  TB Inputs to PE: global_clear_accum=%b, data_in_L=%0d (0x%h), data_valid_in_L=%b, weight_in_T=%0d (0x%h), weight_valid_in_T=%b",
                     global_clear_accum, data_in_L, data_in_L, data_valid_in_L, weight_in_T, weight_in_T, weight_valid_in_T);
            $display("  PE Registered Outputs (to next PE): data_out_R=%0d (0x%h), data_valid_out_R=%b, weight_out_B=%0d (0x%h), weight_valid_out_B=%b",
                     data_out_R, data_out_R, data_valid_out_R, weight_out_B, weight_out_B, weight_valid_out_B);
            $display("  PE Internal regs: data_reg=%0d (0x%h), data_valid_reg=%b, weight_reg=%0d (0x%h), weight_valid_reg=%b, pe_clear_accum_reg=%b",
                     dut.data_reg, dut.data_reg, dut.data_valid_reg, dut.weight_reg, dut.weight_reg, dut.weight_valid_reg, dut.pe_clear_accum_reg);
            $display("  MAC Inputs: dut.mac_inst.data_in=%0d (0x%h), dut.mac_inst.weight_in=%0d (0x%h), dut.mac_inst.enable_mac=%b, dut.mac_inst.clear_accum=%b",
                     dut.mac_inst.data_in, dut.mac_inst.data_in, dut.mac_inst.weight_in, dut.mac_inst.weight_in, dut.mac_inst.enable_mac, dut.mac_inst.clear_accum);
            $display("  MAC Internal state: dut.mac_inst.mult_result_full=%0d (0x%h), dut.mac_inst.accum_reg=%0d (0x%h), dut.mac_inst.accum_valid_reg=%b",
                     dut.mac_inst.mult_result_full, dut.mac_inst.mult_result_full, dut.mac_inst.accum_reg, dut.mac_inst.accum_reg, dut.mac_inst.accum_valid_reg);
            $display("  PE Final Output: pe_accum_out=%0d (0x%h), pe_result_valid=%b",
                     pe_accum_out, pe_accum_out, pe_result_valid);
            $display("-------------------------------------------------------");
        end
    end
    // --- End Debugging for Data Flow ---

    // ==========================================
    // Test Sequence
    // ==========================================
    initial begin
        // Initialize inputs
        rst_n               = 0;
        global_clear_accum  = 0;
        data_in_L           = 0;
        data_valid_in_L     = 0;
        weight_in_T         = 0;
        weight_valid_in_T   = 0;

        $display("-------------------------------------------------------");
        $display("Starting PE Testbench at time %0d", $time);
        $display("-------------------------------------------------------");
        
        #10; // Wait a bit for initial settling (Time 10)

        // 1. Assert reset
        rst_n = 0;
        $display("Time %0d: Asserting reset (rst_n = %b)", $time, rst_n);
        #20; // Hold reset for 2 cycles (Release at Time 30)

        // 2. Release reset
        rst_n = 1;
        $display("Time %0d: Releasing reset (rst_n = %b)", $time, rst_n);
        #10; // Wait one cycle after reset release (Time 40)
        // Log output at Time 35 (posedge clk after rst_n=1) will show initial state post-reset.

        // 3. Test data propagation (no MAC computation yet)
        $display("\n--- Test 3 (Time %0d): Data Propagation without MAC computation ---", $time);
        // Inject data, but keep weight invalid. MAC should not compute.
        data_in_L         = 16'd100;    // Some dummy data
        data_valid_in_L   = 1;
        weight_in_T       = 8'd20;      // Some dummy weight
        weight_valid_in_T = 0;          // Weight invalid, so MAC should not compute (enable_mac = 0)

        #10; // clk posedge (Time 50). Log output at Time 45 (posedge clk)
        // At Time 45 (log):
        //   PE Inputs: data_in_L=100, data_valid_in_L=1, weight_in_T=20, weight_valid_in_T=0
        //   PE Registered Outputs (to next PE): data_out_R=0, data_valid_out_R=0, weight_out_B=0, weight_valid_out_B=0 (from reset)
        //   MAC Inputs: enable_mac=0
        //   PE Final Output: pe_accum_out=0, pe_result_valid=0

        data_in_L           = 0; // Clear input for next cycle
        data_valid_in_L     = 0;
        weight_in_T         = 0;
        weight_valid_in_T   = 0;

        #10; // clk posedge (Time 60). Log output at Time 55
        // At Time 55 (log):
        //   PE Inputs: data_in_L=0, data_valid_in_L=0, weight_in_T=0, weight_valid_in_T=0
        //   PE Registered Outputs (to next PE): data_out_R=100, data_valid_out_R=1, weight_out_B=20, weight_valid_out_B=0 (from Time 45 inputs)
        //   MAC Inputs: enable_mac=0
        //   PE Final Output: pe_accum_out=0, pe_result_valid=0

        #10; // clk posedge (Time 70). Log output at Time 65
        // At Time 65 (log):
        //   PE Inputs: data_in_L=0, data_valid_in_L=0, weight_in_T=0, weight_valid_in_T=0
        //   PE Registered Outputs (to next PE): data_out_R=0, data_valid_out_R=0, weight_out_B=0, weight_valid_out_B=0 (from Time 55 inputs)
        //   MAC Inputs: enable_mac=0
        //   PE Final Output: pe_accum_out=0, pe_result_valid=0

        // 4. Test MAC computation - single valid input with clear
        $display("\n--- Test 4 (Time %0d): Single MAC Computation (with clear_accum) ---", $time);
        // Set global_clear_accum ONE CYCLE BEFORE data and weight become valid.
        // This ensures pe_clear_accum_reg is high when MAC sees valid data/weight.
        global_clear_accum  = 1; 

        #10; // clk posedge (Time 80). Log output at Time 75
        // At Time 75 (log):
        //   TB Inputs to PE: global_clear_accum=1
        //   PE Internal regs: pe_clear_accum_reg should latch '1' from global_clear_accum at NEXT posedge (Time 85 log).
        //                     Current pe_clear_accum_reg is '0'.
        //   MAC Inputs: dut.mac_inst.clear_accum=0 (based on current pe_clear_accum_reg). enable_mac=0.

        // Now inject valid data and weight for one cycle.
        // Data: 5.0 (S5.10) -> 5 * 2^10 = 5120 (16'h1400)
        // Weight: 1.0 (S1.6) -> 1 * 2^6 = 64 (8'h40)
        // Expected Product: 5.0 * 1.0 = 5.0. Raw S15.16: 5 * 2^16 = 327680 (32'h00050000)
        data_in_L           = 16'h1400;    
        weight_in_T         = 8'h40;      
        data_valid_in_L     = 1;
        weight_valid_in_T   = 1;
        // global_clear_accum is still 1 from previous step, will be latched by pe_clear_accum_reg.
        // We can set global_clear_accum back to 0 now for the next cycle's pe_clear_accum_reg input.
        global_clear_accum  = 0; 

        #10; // clk posedge (Time 90). Log output at Time 85
        // At Time 85 (log):
        //   TB Inputs to PE: data_in_L=16'h1400, weight_in_T=8'h40, valid_L=1, valid_T=1, global_clear_accum=0
        //   PE Internal regs: pe_clear_accum_reg=1 (latched from global_clear_accum at Time 75)
        //   MAC Inputs: dut.mac_inst.data_in=16'h1400, dut.mac_inst.weight_in=8'h40, dut.mac_inst.enable_mac=1, dut.mac_inst.clear_accum=1
        //   MAC Internal state: mult_result_full=327680. accum_reg is OLD value. accum_valid_reg is OLD value.
        //   PE Final Output: pe_accum_out=OLD value (e.g. 0), pe_result_valid=OLD value (e.g. 0)
        //   * At this posedge, MAC unit calculates and schedules update for accum_reg and accum_valid_reg *

        // Clear inputs for next cycle
        data_in_L           = 0;
        weight_in_T         = 0;
        data_valid_in_L     = 0;
        weight_valid_in_T   = 0;
        
        #10; // clk posedge (Time 100). Log output at Time 95
        // At Time 95 (log):
        //   TB Inputs to PE: data_in_L=0, etc. global_clear_accum=0
        //   PE Internal regs: pe_clear_accum_reg=0 (latched from global_clear_accum at Time 85)
        //   PE Registered Outputs (to next PE): data_out_R=16'h1400, data_valid_out_R=1, weight_out_B=8'h40, weight_valid_out_B=1 (from Time 85 inputs)
        //   MAC Inputs: dut.mac_inst.enable_mac=0 (due to invalid inputs now)
        //   MAC Internal state: accum_reg=327680 (updated from Time 85 calculation), accum_valid_reg=1 (updated from Time 85).
        //   PE Final Output: pe_accum_out=327680 (0x00050000), pe_result_valid=1 (reflects Time 85 MAC operation)

        #10; // clk posedge (Time 110). Log output at Time 105
        // At Time 105 (log):
        //   MAC Inputs: dut.mac_inst.enable_mac=0
        //   MAC Internal state: accum_reg=327680 (holds value), accum_valid_reg=0 (due to enable_mac=0 at Time 95)
        //   PE Final Output: pe_accum_out=327680 (0x00050000), pe_result_valid=0

        // 5. Test MAC computation - accumulation
        $display("\n--- Test 5 (Time %0d): Accumulation Test ---", $time);
        // Prev accum = 5.0 (327680)
        // Data: 2.0 (S5.10) -> 2 * 2^10 = 2048 (16'h0800)
        // Weight: -1.0 (S1.6) -> from 8'hC0. Raw $signed(8'hC0) = -64. Scaled: -64 / 2^6 = -1.0.
        // Expected Product: 2.0 * -1.0 = -2.0. Raw S15.16: -2.0 * 2^16 = -131072 (32'hFFFE0000)
        // Expected Accumulation: 5.0 + (-2.0) = 3.0. Raw S15.16: 3.0 * 2^16 = 196608 (32'h00030000)
        data_in_L           = 16'h0800;    
        weight_in_T         = 8'hC0;      // This is -1.0 in S1.6 after $signed()
        data_valid_in_L     = 1;
        weight_valid_in_T   = 1;
        global_clear_accum  = 0; // Ensure we are accumulating

        #10; // clk posedge (Time 120). Log output at Time 115
        // At Time 115 (log):
        //   TB Inputs to PE: data_in_L=16'h0800, weight_in_T=8'hC0, valid_L=1, valid_T=1
        //   PE Internal regs: pe_clear_accum_reg=0
        //   MAC Inputs: dut.mac_inst.enable_mac=1, dut.mac_inst.clear_accum=0
        //   MAC Internal state: mult_result_full=-131072. accum_reg=327680 (OLD value). accum_valid_reg=0 (OLD value).
        //   PE Final Output: pe_accum_out=327680 (OLD), pe_result_valid=0 (OLD)
        //   * MAC unit calculates accum_reg <= 327680 + (-131072) = 196608. accum_valid_reg <= 1. *

        // Clear inputs for next cycle
        data_in_L           = 0;
        weight_in_T         = 0;
        data_valid_in_L     = 0;
        weight_valid_in_T   = 0;

        #10; // clk posedge (Time 130). Log output at Time 125
        // At Time 125 (log):
        //   MAC Inputs: dut.mac_inst.enable_mac=0
        //   MAC Internal state: accum_reg=196608 (0x00030000) (updated from Time 115 calculation), accum_valid_reg=1.
        //   PE Final Output: pe_accum_out=196608 (0x00030000), pe_result_valid=1

        #10; // clk posedge (Time 140). Log output at Time 135
        // At Time 135 (log):
        //   MAC Inputs: dut.mac_inst.enable_mac=0
        //   MAC Internal state: accum_reg=196608 (holds value), accum_valid_reg=0.
        //   PE Final Output: pe_accum_out=196608 (0x00030000), pe_result_valid=0
        
        // 6. Test global_clear_accum again
        $display("\n--- Test 6 (Time %0d): Reset Accumulator via global_clear_accum ---", $time);
        // Prev accum = 3.0 (196608)
        // Data: 1.0 (S5.10) -> 1 * 2^10 = 1024 (16'h0400)
        // Weight: 1.0 (S1.6) -> 1 * 2^6 = 64 (8'h40)
        // Expected Product: 1.0 * 1.0 = 1.0. Raw S15.16: 1.0 * 2^16 = 65536 (32'h00010000)
        // Accumulator will be cleared and loaded with this product.

        global_clear_accum  = 1; 

        #10; // clk posedge (Time 150). Log output at Time 145
        // At Time 145 (log):
        //   TB Inputs to PE: global_clear_accum=1
        //   PE Internal regs: pe_clear_accum_reg should latch '1' at NEXT posedge. Current is '0'.
        
        data_in_L           = 16'h0400; 
        weight_in_T         = 8'h40;  
        data_valid_in_L     = 1;
        weight_valid_in_T   = 1;
        global_clear_accum  = 0; 

        #10; // clk posedge (Time 160). Log output at Time 155
        // At Time 155 (log):
        //   TB Inputs to PE: data_in_L=16'h0400, weight_in_T=8'h40, valid_L=1, valid_T=1, global_clear_accum=0
        //   PE Internal regs: pe_clear_accum_reg=1 (latched from global_clear_accum at Time 145)
        //   MAC Inputs: dut.mac_inst.enable_mac=1, dut.mac_inst.clear_accum=1
        //   MAC Internal state: mult_result_full=65536. accum_reg=196608 (OLD). accum_valid_reg=0 (OLD).
        //   PE Final Output: pe_accum_out=196608 (OLD), pe_result_valid=0 (OLD)
        //   * MAC unit calculates accum_reg <= 65536. accum_valid_reg <= 1. *

        data_in_L           = 0;
        weight_in_T         = 0;
        data_valid_in_L     = 0;
        weight_valid_in_T   = 0;

        #10; // clk posedge (Time 170). Log output at Time 165
        // At Time 165 (log):
        //   MAC Inputs: dut.mac_inst.enable_mac=0
        //   MAC Internal state: accum_reg=65536 (0x00010000) (updated from Time 155 calculation), accum_valid_reg=1.
        //   PE Final Output: pe_accum_out=65536 (0x00010000), pe_result_valid=1

        #10; // clk posedge (Time 180). Log output at Time 175
        // At Time 175 (log):
        //   MAC Inputs: dut.mac_inst.enable_mac=0
        //   MAC Internal state: accum_reg=65536 (holds value), accum_valid_reg=0.
        //   PE Final Output: pe_accum_out=65536 (0x00010000), pe_result_valid=0

        #40; // Final delay, total time will be 220ns
        $display("\n-------------------------------------------------------");
        $display("Testbench finished at time %0d", $time);
        $display("-------------------------------------------------------");
        $finish;
    end
endmodule
