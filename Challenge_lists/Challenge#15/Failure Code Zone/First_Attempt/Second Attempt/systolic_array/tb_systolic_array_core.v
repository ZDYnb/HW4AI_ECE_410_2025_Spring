`timescale 1ns/1ps

module tb_systolic_array_core;

    // Parameters for DUT
    localparam ARRAY_DIM    = 2;
    localparam DATA_WIDTH   = 16;
    localparam WEIGHT_WIDTH = 8;
    localparam ACCUM_WIDTH  = 24;
    localparam CLK_PERIOD   = 10; // ns

    // Testbench signals
    reg clk;
    reg rst_n;
    reg core_enable;
    reg load_weights_en_array;

    // Flattened inputs for DUT
    reg [(ARRAY_DIM*ARRAY_DIM*WEIGHT_WIDTH)-1:0] core_weights_in_flat_tb;
    reg [(ARRAY_DIM*DATA_WIDTH)-1:0]             current_core_activation_in_flat_tb;
    reg [(ARRAY_DIM*ACCUM_WIDTH)-1:0]            current_core_psum_in_flat_tb;

    // Flattened outputs from DUT
    wire [(ARRAY_DIM*DATA_WIDTH)-1:0]            core_activation_out_flat_dut;
    wire [(ARRAY_DIM*ACCUM_WIDTH)-1:0]           core_psum_out_flat_dut;
    wire [ARRAY_DIM-1:0]                         core_data_out_valid_dut; // This was a vector, should be fine

    // Loop variables for Verilog-2001 compatibility
    integer r_idx, c_idx, k_idx; 
    integer i; // General purpose loop variable

    // DUT Instantiation
    systolic_array_core #(
        .ARRAY_DIM(ARRAY_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .core_enable(core_enable),
        .load_weights_en_array(load_weights_en_array),
        .core_weights_in_flat(core_weights_in_flat_tb),
        .core_activation_in_flat(current_core_activation_in_flat_tb),
        .core_psum_in_flat(current_core_psum_in_flat_tb),
        .core_activation_out_flat(core_activation_out_flat_dut),
        .core_psum_out_flat(core_psum_out_flat_dut),
        .core_data_out_valid(core_data_out_valid_dut)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Helper tasks for assigning to flattened arrays (optional, but can make TB cleaner)
    task load_flat_weights;
	begin
        // B_tile = [[1, 2], [3, 4]] for ARRAY_DIM=2
        // core_weights_in_flat_tb[PE_row][PE_col][bit]
        // Mapping: flat_index = (PE_row * ARRAY_DIM + PE_col) * WEIGHT_WIDTH
        core_weights_in_flat_tb[(0*ARRAY_DIM+0)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'd1; // PE[0][0]
        core_weights_in_flat_tb[(0*ARRAY_DIM+1)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'd2; // PE[0][1]
        core_weights_in_flat_tb[(1*ARRAY_DIM+0)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'd3; // PE[1][0]
        core_weights_in_flat_tb[(1*ARRAY_DIM+1)*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'd4; // PE[1][1]
	end
    endtask

    task drive_flat_activations;
        input [1:0] k_val; // Represents k_idx (0 or 1 for ARRAY_DIM=2)
        // A_tile = [[10, 20], [30, 40]] (A[m][k])
        // current_core_activation_in_flat_tb[PE_row_idx] = A[PE_row_idx][k_val]
        // Mapping: flat_index for PE_row_idx = PE_row_idx * DATA_WIDTH
        begin
            if (k_val == 0) begin // k=0 column of A (A[m][0])
                current_core_activation_in_flat_tb[0*DATA_WIDTH +: DATA_WIDTH] = 16'd10; // A[0][0] for PE[0][0]'s stream
                current_core_activation_in_flat_tb[1*DATA_WIDTH +: DATA_WIDTH] = 16'd30; // A[1][0] for PE[1][0]'s stream
            end else if (k_val == 1) begin // k=1 column of A (A[m][1])
                current_core_activation_in_flat_tb[0*DATA_WIDTH +: DATA_WIDTH] = 16'd20; // A[0][1]
                current_core_activation_in_flat_tb[1*DATA_WIDTH +: DATA_WIDTH] = 16'd40; // A[1][1]
            end else begin
                current_core_activation_in_flat_tb = 0; // Default to 0 if k_val is out of range for this example
            end
        end
    endtask
    
    task drive_flat_psums_zero;
        // current_core_psum_in_flat_tb[PE_col_idx] = 0
        // Mapping: flat_index for PE_col_idx = PE_col_idx * ACCUM_WIDTH
        begin
            for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin
                current_core_psum_in_flat_tb[c_idx*ACCUM_WIDTH +: ACCUM_WIDTH] = 24'd0;
            end
        end
    endtask


    // Stimulus
    initial begin
        rst_n = 0;
        core_enable = 0;
        load_weights_en_array = 0;
        core_weights_in_flat_tb = 0; 
        current_core_activation_in_flat_tb = 0;
        current_core_psum_in_flat_tb = 0;

        #(CLK_PERIOD * 2) rst_n = 1;
        $display("[%0t ns] TB: Reset Released.", $time);
        #(CLK_PERIOD);

        $display("[%0t ns] TB: Loading Weights...", $time);
        core_enable = 1; 
        load_weights_en_array = 1;
        load_flat_weights(); // Call task to set core_weights_in_flat_tb
        
        #(CLK_PERIOD); 
        load_weights_en_array = 0; 
        $display("[%0t ns] TB: Weights Loaded.", $time);
        
        $display("[%0t ns] TB: Streaming A_tile and Psum_tile (Psum_in all zeros)...", $time);
        drive_flat_psums_zero(); // Set initial psums for top row of PEs to 0

        for (k_idx = 0; k_idx < ARRAY_DIM; k_idx = k_idx + 1) begin
            drive_flat_activations(k_idx);
            $display("[%0t ns] TB: Stream k_idx=%d: ActInFlat[0]=%d, ActInFlat[1]=%d. PsumInFlat[0]=%d, PsumInFlat[1]=%d", 
                     $time, k_idx, 
                     current_core_activation_in_flat_tb[0*DATA_WIDTH +: DATA_WIDTH], 
                     current_core_activation_in_flat_tb[1*DATA_WIDTH +: DATA_WIDTH],
                     current_core_psum_in_flat_tb[0*ACCUM_WIDTH +: ACCUM_WIDTH], 
                     current_core_psum_in_flat_tb[1*ACCUM_WIDTH +: ACCUM_WIDTH]);
            #(CLK_PERIOD);
        end
        
        current_core_activation_in_flat_tb = 0; // Stop driving new activations
        
        $display("[%0t ns] TB: Finished streaming A_tile. Waiting for outputs to propagate.", $time);
        // Expected latencies for ARRAY_DIM=2:
        // act_out: 2 cycles from input port.
        // psum_out: 3 cycles from input ports.
        // Last A input for C[1][1] (A[1][1]=40) enters its PE[1][0] path at k_idx=1.
        // That PE[1][0] takes 2 cycles to output A[1][1] to PE[1][1]'s input. (k_idx=1 cycle + 2 PE_act_latency)
        // PE[1][1] then takes 3 cycles for its psum to come out.
        // Total wait cycles after last A input stream = ARRAY_DIM (for act pipe) + ARRAY_DIM (for psum pipe) is a rough guide
        #(CLK_PERIOD * (ARRAY_DIM + ARRAY_DIM + 2)); // Wait (2+2+2)=6 cycles after last stream input
        
        $display("[%0t ns] TB: Disabling core_enable.", $time);
        core_enable = 0;
        #(CLK_PERIOD * 2);
        
        $display("[%0t ns] TB: Testbench Finished.", $time);
        $finish;
    end

    // Monitor signals
    initial begin
        // Simplified monitor for flattened outputs
        $monitor("[%0t ns] En:%b LdW:%b || POut0_flat[23:0]:%4h (V:%b) POut1_flat[23:0]:%4h (V:%b) || AOut0_flat[15:0]:%3h AOut1_flat[15:0]:%3h",
                 $time, core_enable, load_weights_en_array,
                 core_psum_out_flat_dut[ACCUM_WIDTH-1 : 0], core_data_out_valid_dut[0], 
                 core_psum_out_flat_dut[2*ACCUM_WIDTH-1 : ACCUM_WIDTH], core_data_out_valid_dut[1],
                 core_activation_out_flat_dut[DATA_WIDTH-1 : 0],
                 core_activation_out_flat_dut[2*DATA_WIDTH-1 : DATA_WIDTH]
                 );
        // Hierarchical access for debugging (dut.pe_inst[r][c].stored_weight_reg etc.) can be added if needed
        // Example for stored weights if ARRAY_DIM=2:
        // $monitor("... W[0][0]=%d W[0][1]=%d W[1][0]=%d W[1][1]=%d",
        // dut.pe_inst[0][0].stored_weight_reg, dut.pe_inst[0][1].stored_weight_reg,
        // dut.pe_inst[1][0].stored_weight_reg, dut.pe_inst[1][1].stored_weight_reg);

    end

endmodule
