// matrix_layer_norm_wrapper.v - 64x64 Matrix LayerNorm with column-wise processing
module matrix_layer_norm_wrapper #(
    parameter MATRIX_SIZE = 64,
    parameter D_MODEL = 64,     // Number of elements per column (rows)
    parameter X_WIDTH = 16, 
    parameter X_FRAC = 10,
    parameter Y_WIDTH = 16, 
    parameter Y_FRAC = 10, 
    parameter PARAM_WIDTH = 8, 
    parameter PARAM_FRAC = 6
) (
    input wire clk,
    input wire rst_n,
    input wire start_in,
    
    // Matrix input - 64x64 = 4096 elements
    input wire signed [(MATRIX_SIZE * MATRIX_SIZE * X_WIDTH) - 1 : 0] matrix_flat_in,
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in,
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in,
    
    // Matrix output
    output wire signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] matrix_flat_out,
    output wire done_out,
    output wire busy_out
);

    // State machine state definitions
    parameter IDLE = 3'b000;
    parameter PROCESSING = 3'b001;
    parameter WAIT_COL_DONE = 3'b010;
    parameter DONE = 3'b011;
    
    reg [2:0] current_state, next_state;
    
    // Column counter
    reg [7:0] col_counter;
    
    // Current column data as individual registers
    reg signed [X_WIDTH-1:0] col_data_0, col_data_1, col_data_2, col_data_3;
    reg signed [X_WIDTH-1:0] col_data_4, col_data_5, col_data_6, col_data_7;
    // ... We'll need all 64, but let's simplify for now
    
    // Current column data packed
    wire signed [(D_MODEL * X_WIDTH) - 1 : 0] current_col_data;
    
    // LayerNorm core module interface
    wire layernorm_start;
    wire layernorm_done;
    wire layernorm_busy;
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] layernorm_output;
    
    // Output buffer
    reg signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] output_buffer;
    
    // Temporary storage for matrix extraction and writing
    reg signed [X_WIDTH-1:0] temp_matrix_element;
    reg signed [Y_WIDTH-1:0] temp_output_element;
    reg [15:0] temp_bit_index;
    
    // Extract current column data using procedural blocks
    always @(*) begin
        // Extract column elements using shifts instead of bit-select
        temp_bit_index = 0;
        col_data_0 = matrix_flat_in >> ((0 * 64 + col_counter) * 16);
        col_data_1 = matrix_flat_in >> ((1 * 64 + col_counter) * 16);
        col_data_2 = matrix_flat_in >> ((2 * 64 + col_counter) * 16);
        col_data_3 = matrix_flat_in >> ((3 * 64 + col_counter) * 16);
        col_data_4 = matrix_flat_in >> ((4 * 64 + col_counter) * 16);
        col_data_5 = matrix_flat_in >> ((5 * 64 + col_counter) * 16);
        col_data_6 = matrix_flat_in >> ((6 * 64 + col_counter) * 16);
        col_data_7 = matrix_flat_in >> ((7 * 64 + col_counter) * 16);
    end
    
    // Pack first 8 elements (simplified version)
    assign current_col_data[15:0] = col_data_0;
    assign current_col_data[31:16] = col_data_1;
    assign current_col_data[47:32] = col_data_2;
    assign current_col_data[63:48] = col_data_3;
    assign current_col_data[79:64] = col_data_4;
    assign current_col_data[95:80] = col_data_5;
    assign current_col_data[111:96] = col_data_6;
    assign current_col_data[127:112] = col_data_7;
    // Note: This is only showing 8 elements for simplicity
    // In real implementation, you'd need to declare all 64 reg variables
    // and assign all parts of current_col_data
    
    // For now, let's use a simpler approach with memory blocks
    reg [15:0] input_mem [0:4095];   // 64x64 matrix as memory
    reg [15:0] output_mem [0:4095];  // Output matrix as memory
    
    // Convert flat input to memory (one-time initialization)
    integer init_i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (init_i = 0; init_i < 4096; init_i = init_i + 1) begin
                input_mem[init_i] <= matrix_flat_in[init_i*16 +: 16];
                output_mem[init_i] <= 0;
            end
        end
    end
    
    // Extract current column from memory
    reg signed [X_WIDTH-1:0] column_mem [0:63];
    integer col_extract_i;
    always @(*) begin
        for (col_extract_i = 0; col_extract_i < 64; col_extract_i = col_extract_i + 1) begin
            column_mem[col_extract_i] = input_mem[col_extract_i * 64 + col_counter];
        end
    end
    
    // Pack column memory into flat vector
    genvar pack_i;
    generate
        for (pack_i = 0; pack_i < 64; pack_i = pack_i + 1) begin : pack_gen
            assign current_col_data[pack_i*16 +: 16] = column_mem[pack_i];
        end
    endgenerate
    
    // Write results back to memory
    integer write_i;
    always @(posedge clk) begin
        if (layernorm_done && (current_state == WAIT_COL_DONE)) begin
            for (write_i = 0; write_i < 64; write_i = write_i + 1) begin
                output_mem[write_i * 64 + col_counter] <= layernorm_output[write_i*16 +: 16];
            end
        end
    end
    
    // Convert memory back to flat output
    generate
        for (pack_i = 0; pack_i < 4096; pack_i = pack_i + 1) begin : output_pack
            assign matrix_flat_out[pack_i*16 +: 16] = output_mem[pack_i];
        end
    endgenerate
    
    // LayerNorm control signal
    assign layernorm_start = (current_state == PROCESSING) && !layernorm_busy;
    
    // Instantiate the original LayerNorm module
    layer_norm_top #(
        .D_MODEL(D_MODEL),
        .X_WIDTH(X_WIDTH), 
        .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH), 
        .Y_FRAC(Y_FRAC), 
        .PARAM_WIDTH(PARAM_WIDTH), 
        .PARAM_FRAC(PARAM_FRAC)
    ) layernorm_core (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(layernorm_start),
        .x_vector_flat_in(current_col_data),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_vector_flat_out(layernorm_output),
        .done_valid_out(layernorm_done),
        .mu_out_debug(),
        .mu_valid_debug(),
        .sigma_sq_out_debug(),
        .sigma_sq_valid_debug(),
        .var_plus_eps_out_debug(),
        .var_plus_eps_valid_debug(),
        .std_dev_out_debug(),
        .std_dev_valid_debug(),
        .recip_std_dev_out_debug(),
        .recip_std_dev_valid_debug(),
        .busy_out_debug(layernorm_busy)
    );
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            col_counter <= 0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    if (start_in) begin
                        col_counter <= 0;
                    end
                end
                
                WAIT_COL_DONE: begin
                    if (layernorm_done) begin
                        if (col_counter < 63) begin
                            col_counter <= col_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
    
    // State machine - combinational logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (start_in) begin
                    next_state = PROCESSING;
                end
            end
            
            PROCESSING: begin
                if (layernorm_start) begin
                    next_state = WAIT_COL_DONE;
                end
            end
            
            WAIT_COL_DONE: begin
                if (layernorm_done) begin
                    if (col_counter < 63) begin
                        next_state = PROCESSING;
                    end else begin
                        next_state = DONE;
                    end
                end
            end
            
            DONE: begin
                if (!start_in) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output signals
    assign done_out = (current_state == DONE);
    assign busy_out = (current_state != IDLE && current_state != DONE);

endmodule
