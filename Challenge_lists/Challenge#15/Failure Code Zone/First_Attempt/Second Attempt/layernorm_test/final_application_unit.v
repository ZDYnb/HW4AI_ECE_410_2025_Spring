// final_application_unit.v (Corrected with Generate Blocks)
module final_application_unit #(
    parameter D_MODEL = 128,
    parameter N_PE_APP = 8,
    parameter PE_LATENCY = 6, 

    parameter X_WIDTH = 16, parameter X_FRAC = 10,
    parameter Y_WIDTH = 16, parameter Y_FRAC = 10,
    parameter MU_WIDTH = 24, parameter MU_FRAC = 10,
    parameter INV_STD_WIDTH = 24, parameter INV_STD_FRAC = 14,
    parameter GAMMA_WIDTH = 8, parameter GAMMA_FRAC = 6,
    parameter BETA_WIDTH = 8,  parameter BETA_FRAC = 6,
    
    parameter PE_STAGE1_OUT_WIDTH = MU_WIDTH, 
    parameter PE_STAGE1_OUT_FRAC = MU_FRAC,
    parameter PE_STAGE2_OUT_WIDTH = 24, parameter PE_STAGE2_OUT_FRAC = 21,
    parameter PE_STAGE3_OUT_WIDTH = 24, parameter PE_STAGE3_OUT_FRAC = 18,
    parameter PE_STAGE4_OUT_WIDTH = 24, parameter PE_STAGE4_OUT_FRAC = 18
) (
    input wire clk,
    input wire rst_n,
    input wire start_process_valid_in,

    input wire signed [MU_WIDTH-1:0]        mu_scalar_in,
    input wire signed [INV_STD_WIDTH-1:0]   inv_std_eff_scalar_in,
    input wire signed [(D_MODEL * X_WIDTH) - 1 : 0]     x_vector_in,
    input wire signed [(D_MODEL * GAMMA_WIDTH) - 1 : 0] gamma_vector_in,
    input wire signed [(D_MODEL * BETA_WIDTH) - 1 : 0]  beta_vector_in,

    output wire signed [(D_MODEL * Y_WIDTH) - 1 : 0]    y_vector_out, // Changed to wire
    output reg                                          y_vector_valid_out,
    output reg                                          busy_out
);

    // --- Calculated Parameters ---
    parameter NUM_ROUNDS = (D_MODEL + N_PE_APP - 1) / N_PE_APP;
    parameter ROUND_COUNTER_WIDTH = 7; 
    parameter TOTAL_S_PROCESS_CYCLES = NUM_ROUNDS + PE_LATENCY; 
    parameter PROC_CYCLE_CNT_WIDTH = 7; 

    // --- FSM States ---
    parameter S_IDLE    = 2'b00, S_LOAD    = 2'b01, 
              S_PROCESS = 2'b10, S_DONE    = 2'b11;

    reg [1:0] current_state, next_state;

    // --- Internal Registers ---
    reg signed [MU_WIDTH-1:0]      mu_reg;
    reg signed [INV_STD_WIDTH-1:0] inv_std_eff_reg;

    // Input buffers are now wires driven by generate block assignments
    wire signed [X_WIDTH-1:0]       x_input_buffer [D_MODEL-1:0];
    wire signed [GAMMA_WIDTH-1:0]   gamma_input_buffer [D_MODEL-1:0];
    wire signed [BETA_WIDTH-1:0]    beta_input_buffer [D_MODEL-1:0];
    
    reg signed [Y_WIDTH-1:0]       y_output_array [D_MODEL-1:0]; // Output array remains reg

    reg [ROUND_COUNTER_WIDTH-1:0]  dispatch_round_count_reg; 
    reg [PROC_CYCLE_CNT_WIDTH-1:0] processing_cycle_count_reg;
    
    integer k_fau_loop_reset; // For reset loop

    // --- PE Array Wires and Instantiation (Same as before) ---
    wire signed [X_WIDTH-1:0]         pe_x_i_in_w       [N_PE_APP-1:0];
    wire signed [GAMMA_WIDTH-1:0]     pe_gamma_i_in_w   [N_PE_APP-1:0];
    wire signed [BETA_WIDTH-1:0]      pe_beta_i_in_w    [N_PE_APP-1:0];
    wire                              pe_valid_in_dispatch_w; 
    wire signed [Y_WIDTH-1:0]         pe_y_i_out_w      [N_PE_APP-1:0];
    wire                              pe_valid_out_collect_w [N_PE_APP-1:0];

    genvar i_pe_inst_fau_dut5;
    generate
        for (i_pe_inst_fau_dut5 = 0; i_pe_inst_fau_dut5 < N_PE_APP; i_pe_inst_fau_dut5 = i_pe_inst_fau_dut5 + 1) begin : pe_array_fau_dut_gen5
            layer_norm_pe #( /* .PARAMETER_ASSIGNMENTS */ ) 
            layer_norm_pe_inst_ ( /* .PORT_CONNECTIONS */ 
                .clk(clk), .rst_n(rst_n), .valid_in_pe(pe_valid_in_dispatch_w),
                .x_i_in(pe_x_i_in_w[i_pe_inst_fau_dut5]), .mu_common_in(mu_reg), 
                .inv_std_eff_common_in(inv_std_eff_reg), 
                .gamma_i_in(pe_gamma_i_in_w[i_pe_inst_fau_dut5]), .beta_i_in(pe_beta_i_in_w[i_pe_inst_fau_dut5]),
                .y_i_out(pe_y_i_out_w[i_pe_inst_fau_dut5]), .valid_out_pe(pe_valid_out_collect_w[i_pe_inst_fau_dut5])
            );
        end
    endgenerate

    // --- Combinational Logic for Unpacking Input Vectors (using generate) ---
    genvar k_unpack_loop;
    generate
        for (k_unpack_loop = 0; k_unpack_loop < D_MODEL; k_unpack_loop = k_unpack_loop + 1) begin : unpack_input_gen
            assign x_input_buffer[k_unpack_loop]     = x_vector_in[    (k_unpack_loop * X_WIDTH) + X_WIDTH - 1 : (k_unpack_loop * X_WIDTH)];
            assign gamma_input_buffer[k_unpack_loop] = gamma_vector_in[(k_unpack_loop * GAMMA_WIDTH) + GAMMA_WIDTH -1 : (k_unpack_loop * GAMMA_WIDTH)];
            assign beta_input_buffer[k_unpack_loop]  = beta_vector_in[ (k_unpack_loop * BETA_WIDTH) + BETA_WIDTH - 1 : (k_unpack_loop * BETA_WIDTH)];
        end
    endgenerate

    // --- Combinational Logic for Data Dispatch to PEs (using generate) ---
    // $clog2(D_MODEL) needs to be replaced by a parameter or fixed width if not supported well
    parameter INDEX_DISPATCH_WIDTH = 10; // Example fixed width for D_MODEL up to 1024
    genvar i_pe_dispatch_logic_fau_dut5;
    generate
        for (i_pe_dispatch_logic_fau_dut5 = 0; i_pe_dispatch_logic_fau_dut5 < N_PE_APP; i_pe_dispatch_logic_fau_dut5 = i_pe_dispatch_logic_fau_dut5 + 1) begin : data_dispatch_fau_dut_gen5
            wire [INDEX_DISPATCH_WIDTH-1:0] current_element_idx_dispatch_w_local; 
            assign current_element_idx_dispatch_w_local = dispatch_round_count_reg * N_PE_APP + i_pe_dispatch_logic_fau_dut5;

            assign pe_x_i_in_w[i_pe_dispatch_logic_fau_dut5] = 
                (current_element_idx_dispatch_w_local < D_MODEL) ? x_input_buffer[current_element_idx_dispatch_w_local] : {X_WIDTH{1'b0}};
            assign pe_gamma_i_in_w[i_pe_dispatch_logic_fau_dut5] = 
                (current_element_idx_dispatch_w_local < D_MODEL) ? gamma_input_buffer[current_element_idx_dispatch_w_local] : {GAMMA_WIDTH{1'b0}};
            assign pe_beta_i_in_w[i_pe_dispatch_logic_fau_dut5] = 
                (current_element_idx_dispatch_w_local < D_MODEL) ? beta_input_buffer[current_element_idx_dispatch_w_local] : {BETA_WIDTH{1'b0}};
        end
    endgenerate
    
    assign pe_valid_in_dispatch_w = (current_state == S_PROCESS) && (dispatch_round_count_reg < NUM_ROUNDS);

    // --- Combinational Logic for Packing Output Vector (using generate) ---
    genvar k_pack_loop;
    generate
        for (k_pack_loop = 0; k_pack_loop < D_MODEL; k_pack_loop = k_pack_loop + 1) begin : pack_output_gen
            assign y_vector_out[(k_pack_loop * Y_WIDTH) + Y_WIDTH - 1 : (k_pack_loop * Y_WIDTH)] = y_output_array[k_pack_loop];
        end
    endgenerate

    // --- FSM ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= S_IDLE;
        else        current_state <= next_state;
    end

    always @(*) begin 
        next_state = S_IDLE; 
        case (current_state)
            S_IDLE:    if (start_process_valid_in) next_state = S_LOAD; else next_state = S_IDLE;
            S_LOAD:    next_state = S_PROCESS;
            S_PROCESS: if (processing_cycle_count_reg == TOTAL_S_PROCESS_CYCLES - 1) next_state = S_DONE;
                       else next_state = S_PROCESS;
            S_DONE:    next_state = S_IDLE;
            default:   next_state = S_IDLE;
        endcase
    end
        integer k_collect_loop_var_procedural; // Changed name
        integer element_absolute_idx_to_write_var_procedural; // Changed name
        integer collect_dispatch_round_idx_val_var_procedural; // Changed name
   
    // --- Datapath Registers, Counters, Output Logic & Result Collection ---
    always @(posedge clk or negedge rst_n) begin
        // Declare procedural loop variables here for Verilog-2001
     
        if (!rst_n) begin
            busy_out <= 1'b0;
            y_vector_valid_out <= 1'b0;
            mu_reg <= 0;
            inv_std_eff_reg <= 0;
            // x_input_buffer, etc., are wires now, no reset needed here for them
            // y_output_array is reg, reset it
            for (k_fau_loop_reset = 0; k_fau_loop_reset < D_MODEL; k_fau_loop_reset = k_fau_loop_reset + 1) begin
                y_output_array[k_fau_loop_reset] <= 0;
            end
            dispatch_round_count_reg <= 0;
            processing_cycle_count_reg <= 0;
            // y_vector_out is wire, assigned combinationally
        end else begin
            y_vector_valid_out <= 1'b0; 

            case (current_state)
                S_IDLE: begin
                    busy_out <= 1'b0;
                end
                S_LOAD: begin 
                    busy_out <= 1'b1;
                    mu_reg <= mu_scalar_in;
                    inv_std_eff_reg <= inv_std_eff_scalar_in;
                    // Input vectors are now directly wired to x_input_buffer etc. via generate block
                    // Clear y_output_array for new vector processing
                    for (k_fau_loop_reset = 0; k_fau_loop_reset < D_MODEL; k_fau_loop_reset = k_fau_loop_reset + 1) begin
                        y_output_array[k_fau_loop_reset] <= 0; 
                    end
                    dispatch_round_count_reg <= 0;
                    processing_cycle_count_reg <= 0;
                end
                S_PROCESS: begin
                    busy_out <= 1'b1; 
                    processing_cycle_count_reg <= processing_cycle_count_reg + 1;

                    if (pe_valid_in_dispatch_w) begin 
                        dispatch_round_count_reg <= dispatch_round_count_reg + 1;
                    end
                    
                    // Result Collection Logic
                    if (processing_cycle_count_reg >= PE_LATENCY) begin
                        collect_dispatch_round_idx_val_var_procedural = (processing_cycle_count_reg - PE_LATENCY); 
                        if (collect_dispatch_round_idx_val_var_procedural < NUM_ROUNDS && collect_dispatch_round_idx_val_var_procedural >= 0) begin
                            for (k_collect_loop_var_procedural = 0; k_collect_loop_var_procedural < N_PE_APP; k_collect_loop_var_procedural = k_collect_loop_var_procedural + 1) begin
                                if (pe_valid_out_collect_w[k_collect_loop_var_procedural]) begin
                                    element_absolute_idx_to_write_var_procedural = collect_dispatch_round_idx_val_var_procedural * N_PE_APP + k_collect_loop_var_procedural;
                                    if (element_absolute_idx_to_write_var_procedural < D_MODEL) begin
                                        y_output_array[element_absolute_idx_to_write_var_procedural] <= pe_y_i_out_w[k_collect_loop_var_procedural];
                                    end
                                end
                            end
                        end
                    end
                end
                S_DONE: begin
                    // y_vector_out is now combinationally assigned from y_output_array
                    y_vector_valid_out <= 1'b1;
                    busy_out <= 0;
                end
            endcase
        end
    end
endmodule
