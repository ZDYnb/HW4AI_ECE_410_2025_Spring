// normalization_unit.v - PE Array for Vector Normalization (FIXED)
module normalization_unit #(
    parameter D_MODEL = 128,
    parameter NUM_PE = 8,
    
    // Input/Output Data Format Parameters
    parameter X_WIDTH = 16, parameter X_FRAC = 10,        // x_i: S5.10
    parameter MU_WIDTH = 24, parameter MU_FRAC = 10,      // mu: S13.10
    parameter INV_STD_WIDTH = 24, parameter INV_STD_FRAC = 14, // inv_std: S9.14
    parameter GAMMA_WIDTH = 8, parameter GAMMA_FRAC = 6,  // gamma_i: S1.6
    parameter BETA_WIDTH = 8, parameter BETA_FRAC = 6,    // beta_i: S1.6
    parameter Y_WIDTH = 16, parameter Y_FRAC = 10,        // y_i: S5.10
    
    // Processing parameters
    parameter PE_CYCLES = D_MODEL / NUM_PE,               // 16 cycles
    parameter PE_PIPELINE_DELAY = 6,                      // FIXED: PE pipeline stages (was 5, should be 6)
    parameter TOTAL_CYCLES = PE_CYCLES + PE_PIPELINE_DELAY // 22 total cycles
) (
    input wire clk,
    input wire rst_n,
    input wire start_normalize,
    
    // Vector inputs
    input wire signed [(D_MODEL * X_WIDTH) - 1 : 0] x_vector_in,
    input wire signed [(D_MODEL * GAMMA_WIDTH) - 1 : 0] gamma_vector_in,
    input wire signed [(D_MODEL * BETA_WIDTH) - 1 : 0] beta_vector_in,
    
    // Statistics inputs
    input wire signed [MU_WIDTH-1:0] mu_in,
    input wire signed [INV_STD_WIDTH-1:0] inv_std_in,
    
    // Vector output
    output reg signed [(D_MODEL * Y_WIDTH) - 1 : 0] y_vector_out,
    output reg normalize_done,
    output wire busy
);

    // FSM States
    parameter S_IDLE = 2'b00;
    parameter S_PROCESSING = 2'b01;
    parameter S_OUTPUT = 2'b10;
    
    reg [1:0] current_state, next_state;
    
    // Control signals
    reg [$clog2(TOTAL_CYCLES)-1:0] cycle_counter;
    reg processing_active;
    
    // PE Array signals
    wire signed [X_WIDTH-1:0] pe_x_inputs [NUM_PE-1:0];
    wire signed [GAMMA_WIDTH-1:0] pe_gamma_inputs [NUM_PE-1:0];
    wire signed [BETA_WIDTH-1:0] pe_beta_inputs [NUM_PE-1:0];
    wire pe_valid_inputs [NUM_PE-1:0];
    
    wire signed [Y_WIDTH-1:0] pe_y_outputs [NUM_PE-1:0];
    wire pe_valid_outputs [NUM_PE-1:0];
    
    // Data collection - FIXED: Use individual registers instead of packed array
    reg signed [Y_WIDTH-1:0] y_collected_array [D_MODEL-1:0];
    
    // Loop variables and working registers
    genvar gen_i;
    integer i, j;
    integer base_index;  // FIXED: Pre-declare base_index
    
    assign busy = (current_state != S_IDLE);
    
    // FSM Next State Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE: begin
                if (start_normalize) next_state = S_PROCESSING;
            end
            S_PROCESSING: begin
                if (cycle_counter == TOTAL_CYCLES - 1) next_state = S_OUTPUT;
            end
            S_OUTPUT: begin
                next_state = S_IDLE;
            end
        endcase
    end
    
    // FSM State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // FIXED: Separate combinational logic for base_index calculation
    always @(*) begin
        base_index = (cycle_counter - PE_PIPELINE_DELAY) * NUM_PE;
    end
    
    // Main Control Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 0;
            processing_active <= 1'b0;
            y_vector_out <= 0;
            normalize_done <= 1'b0;
            
            // Initialize y_collected_array
            for (i = 0; i < D_MODEL; i = i + 1) begin
                y_collected_array[i] <= 0;
            end
        end else begin
            normalize_done <= 1'b0; // Default
            
            case (current_state)
                S_IDLE: begin
                    cycle_counter <= 0;
                    processing_active <= 1'b0;
                    if (start_normalize) begin
                        processing_active <= 1'b1;
                        // Clear y_collected_array
                        for (i = 0; i < D_MODEL; i = i + 1) begin
                            y_collected_array[i] <= 0;
                        end
                    end
                end
                
                S_PROCESSING: begin
                    // FIXED: Collect PE outputs during output phase
                    if (cycle_counter >= PE_PIPELINE_DELAY) begin
                        // Use pre-calculated base_index
                        if (pe_valid_outputs[0] && (base_index + 0) < D_MODEL) 
                            y_collected_array[base_index + 0] <= pe_y_outputs[0];
                        if (pe_valid_outputs[1] && (base_index + 1) < D_MODEL) 
                            y_collected_array[base_index + 1] <= pe_y_outputs[1];
                        if (pe_valid_outputs[2] && (base_index + 2) < D_MODEL) 
                            y_collected_array[base_index + 2] <= pe_y_outputs[2];
                        if (pe_valid_outputs[3] && (base_index + 3) < D_MODEL) 
                            y_collected_array[base_index + 3] <= pe_y_outputs[3];
                        if (pe_valid_outputs[4] && (base_index + 4) < D_MODEL) 
                            y_collected_array[base_index + 4] <= pe_y_outputs[4];
                        if (pe_valid_outputs[5] && (base_index + 5) < D_MODEL) 
                            y_collected_array[base_index + 5] <= pe_y_outputs[5];
                        if (pe_valid_outputs[6] && (base_index + 6) < D_MODEL) 
                            y_collected_array[base_index + 6] <= pe_y_outputs[6];
                        if (pe_valid_outputs[7] && (base_index + 7) < D_MODEL) 
                            y_collected_array[base_index + 7] <= pe_y_outputs[7];
                    end
                    
                    cycle_counter <= cycle_counter + 1;
                end
                
                S_OUTPUT: begin
                    // Pack y_collected_array into y_vector_out
                    for (j = 0; j < D_MODEL; j = j + 1) begin
                        y_vector_out[j * Y_WIDTH +: Y_WIDTH] <= y_collected_array[j];
                    end
                    normalize_done <= 1'b1;
                    processing_active <= 1'b0;
                end
            endcase
        end
    end
    
    // PE Array Generation
    generate
        for (gen_i = 0; gen_i < NUM_PE; gen_i = gen_i + 1) begin : pe_array_gen
            
            // Input data selection (only during input phase)
            wire [$clog2(D_MODEL)-1:0] pe_data_index = cycle_counter * NUM_PE + gen_i;
            
            assign pe_x_inputs[gen_i] = (processing_active && cycle_counter < PE_CYCLES && pe_data_index < D_MODEL) ? 
                   x_vector_in[pe_data_index * X_WIDTH +: X_WIDTH] : 16'h0000;
            assign pe_gamma_inputs[gen_i] = (processing_active && cycle_counter < PE_CYCLES && pe_data_index < D_MODEL) ? 
                   gamma_vector_in[pe_data_index * GAMMA_WIDTH +: GAMMA_WIDTH] : 8'h40; // Default gamma = 1.0
            assign pe_beta_inputs[gen_i] = (processing_active && cycle_counter < PE_CYCLES && pe_data_index < D_MODEL) ? 
                   beta_vector_in[pe_data_index * BETA_WIDTH +: BETA_WIDTH] : 8'h00; // Default beta = 0.0
            assign pe_valid_inputs[gen_i] = processing_active && cycle_counter < PE_CYCLES && (pe_data_index < D_MODEL);
            
            // PE instantiation
            layer_norm_pe #(
                .X_WIDTH(X_WIDTH), .X_FRAC(X_FRAC),
                .MU_WIDTH(MU_WIDTH), .MU_FRAC(MU_FRAC),
                .INV_STD_WIDTH(INV_STD_WIDTH), .INV_STD_FRAC(INV_STD_FRAC),
                .GAMMA_WIDTH(GAMMA_WIDTH), .GAMMA_FRAC(GAMMA_FRAC),
                .BETA_WIDTH(BETA_WIDTH), .BETA_FRAC(BETA_FRAC),
                .Y_WIDTH(Y_WIDTH), .Y_FRAC(Y_FRAC)
            ) pe_inst (
                .clk(clk), .rst_n(rst_n),
                .valid_in_pe(pe_valid_inputs[gen_i]),
                .x_i_in(pe_x_inputs[gen_i]),
                .mu_common_in(mu_in),
                .inv_std_eff_common_in(inv_std_in),
                .gamma_i_in(pe_gamma_inputs[gen_i]),
                .beta_i_in(pe_beta_inputs[gen_i]),
                .y_i_out(pe_y_outputs[gen_i]),
                .valid_out_pe(pe_valid_outputs[gen_i])
            );
        end
    endgenerate
    
endmodule

