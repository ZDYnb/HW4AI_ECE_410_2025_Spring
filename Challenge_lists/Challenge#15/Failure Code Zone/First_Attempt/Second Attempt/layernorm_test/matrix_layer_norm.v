// matrix_layer_norm.v - Pure Verilog controller for processing 64x64 matrix with LayerNorm (column-wise)
module matrix_layer_norm #(
    parameter MATRIX_SIZE = 64,
    parameter D_MODEL = 64,  // Feature dimension (column height)
    parameter SEQ_LEN = 64,  // Sequence length (number of columns)
    parameter X_WIDTH = 16,
    parameter X_FRAC = 10,
    parameter Y_WIDTH = 16,
    parameter Y_FRAC = 10,
    parameter PARAM_WIDTH = 8,
    parameter PARAM_FRAC = 6
) (
    input wire clk,
    input wire rst_n,
    input wire start_matrix_norm,
    
    // Matrix input - 64x64 flattened (row-major: [row0_col0, row0_col1, ..., row1_col0, ...])
    input wire signed [(MATRIX_SIZE * MATRIX_SIZE * X_WIDTH) - 1 : 0] matrix_in_flat,
    
    // Parameters for LayerNorm (same gamma/beta for all positions)
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in,
    input wire signed [(D_MODEL * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in,
    
    // Matrix output - 64x64 flattened (same layout as input)
    output reg signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] matrix_out_flat,
    output reg matrix_norm_done,
    output wire matrix_busy
);

    // State machine states
    localparam IDLE = 2'b00;
    localparam EXTRACT_COLUMN = 2'b01;
    localparam PROCESS_COLUMN = 2'b10;
    localparam WAIT_COMPLETE = 2'b11;
    
    reg [1:0] state, next_state;
    reg [5:0] col_counter; // 0 to 63 (current column being processed)
    reg layernorm_start;
    
    // Signals for LayerNorm instance
    reg signed [(D_MODEL * X_WIDTH) - 1 : 0] current_column_in;
    wire signed [(D_MODEL * Y_WIDTH) - 1 : 0] current_column_out;
    wire layernorm_done;
    wire layernorm_busy;
    
    // LayerNorm instance - processes one column (feature vector) at a time
    layer_norm_top #(
        .D_MODEL(D_MODEL),
        .X_WIDTH(X_WIDTH),
        .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH),
        .Y_FRAC(Y_FRAC),
        .PARAM_WIDTH(PARAM_WIDTH),
        .PARAM_FRAC(PARAM_FRAC)
        // Add other parameters from your original module here
    ) layernorm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(layernorm_start),
        .x_vector_flat_in(current_column_in),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_vector_flat_out(current_column_out),
        .done_valid_out(layernorm_done),
        .busy_out_debug(layernorm_busy),
        // Connect other debug outputs as needed
        .mu_out_debug(),
        .mu_valid_debug(),
        .sigma_sq_out_debug(),
        .sigma_sq_valid_debug(),
        .var_plus_eps_out_debug(),
        .var_plus_eps_valid_debug(),
        .std_dev_out_debug(),
        .std_dev_valid_debug(),
        .recip_std_dev_out_debug(),
        .recip_std_dev_valid_debug()
    );
    
    assign matrix_busy = (state != IDLE);
    
    // Extract column from row-major matrix
    integer extract_i;
    always @(*) begin
        for (extract_i = 0; extract_i < D_MODEL; extract_i = extract_i + 1) begin
            current_column_in[(extract_i * X_WIDTH) +: X_WIDTH] = 
                matrix_in_flat[((extract_i * MATRIX_SIZE + col_counter) * X_WIDTH) +: X_WIDTH];
        end
    end
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            col_counter <= 6'b0;
            matrix_norm_done <= 1'b0;
            layernorm_start <= 1'b0;
            matrix_out_flat <= {(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH){1'b0}};
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    matrix_norm_done <= 1'b0;
                    layernorm_start <= 1'b0;
                    if (start_matrix_norm) begin
                        col_counter <= 6'b0;
                        matrix_out_flat <= {(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH){1'b0}};
                    end
                end
                
                EXTRACT_COLUMN: begin
                    // Column is extracted combinationally
                end
                
                PROCESS_COLUMN: begin
                    layernorm_start <= 1'b1;
                end
                
                WAIT_COMPLETE: begin
                    layernorm_start <= 1'b0;
                    if (layernorm_done) begin
                        // Store the processed column back to matrix
                        // This is done in a separate always block below
                        if (col_counter == SEQ_LEN - 1'b1) begin
                            matrix_norm_done <= 1'b1;
                        end else begin
                            col_counter <= col_counter + 1'b1;
                        end
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Store processed column back to matrix
    integer store_i;
    always @(posedge clk) begin
        if (layernorm_done && state == WAIT_COMPLETE) begin
            for (store_i = 0; store_i < D_MODEL; store_i = store_i + 1) begin
                matrix_out_flat[((store_i * MATRIX_SIZE + col_counter) * Y_WIDTH) +: Y_WIDTH] <= 
                    current_column_out[(store_i * Y_WIDTH) +: Y_WIDTH];
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_matrix_norm) 
                    next_state = EXTRACT_COLUMN;
            end
            
            EXTRACT_COLUMN: begin
                // Column extraction is immediate (combinational)
                next_state = PROCESS_COLUMN;
            end
            
            PROCESS_COLUMN: begin
                next_state = WAIT_COMPLETE;
            end
            
            WAIT_COMPLETE: begin
                if (layernorm_done) begin
                    if (col_counter == SEQ_LEN - 1'b1) 
                        next_state = IDLE;  // All done, back to IDLE
                    else 
                        next_state = EXTRACT_COLUMN;  // Process next column
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
