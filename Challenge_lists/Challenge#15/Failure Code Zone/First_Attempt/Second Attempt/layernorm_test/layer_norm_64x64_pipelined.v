// layer_norm_64x64_pipelined.v - 64×64 Matrix LayerNorm with Time Multiplexing
module layer_norm_64x64_pipelined #(
    parameter MATRIX_SIZE = 64,
    parameter X_WIDTH = 16,
    parameter X_FRAC = 10,
    parameter Y_WIDTH = 16, 
    parameter Y_FRAC = 10,
    parameter PARAM_WIDTH = 8,
    parameter PARAM_FRAC = 6,
    parameter INTERNAL_X_WIDTH = 24,
    parameter INTERNAL_X_FRAC = 10,
    parameter ADDER_OUTPUT_WIDTH = INTERNAL_X_WIDTH + 7,
    parameter MEAN_CALC_OUT_WIDTH = INTERNAL_X_WIDTH,
    parameter VARIANCE_UNIT_DATA_WIDTH = INTERNAL_X_WIDTH,
    parameter VARIANCE_UNIT_OUT_WIDTH = INTERNAL_X_WIDTH,
    parameter VARIANCE_UNIT_NUM_PE = 8,
    parameter VAR_EPS_DATA_WIDTH = INTERNAL_X_WIDTH,
    parameter VAR_EPS_FRAC_BITS = 20,
    parameter VAR_EPS_EPSILON_INT_VAL = 11,
    parameter SQRT_DATA_IN_WIDTH = INTERNAL_X_WIDTH,
    parameter SQRT_ROOT_OUT_WIDTH = 12,
    parameter SQRT_S_REG_WIDTH = 16,
    parameter SQRT_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH,
    parameter SQRT_FRAC_BITS_OUT = INTERNAL_X_FRAC,
    parameter RECIP_INPUT_X_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_DIVISOR_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_QUOTIENT_WIDTH = INTERNAL_X_WIDTH,
    parameter RECIP_FINAL_OUT_WIDTH = INTERNAL_X_WIDTH,
    parameter NORM_NUM_PE = 8
) (
    input wire clk,
    input wire rst_n,
    input wire start_matrix,
    
    // 64×64 Matrix inputs (flattened)
    input wire signed [(MATRIX_SIZE * MATRIX_SIZE * X_WIDTH) - 1 : 0] x_matrix_flat_in,
    input wire signed [(MATRIX_SIZE * PARAM_WIDTH) - 1 : 0] gamma_vector_flat_in,
    input wire signed [(MATRIX_SIZE * PARAM_WIDTH) - 1 : 0] beta_vector_flat_in,
    
    // 64×64 Matrix outputs
    output reg signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] y_matrix_flat_out,
    output wire matrix_done,
    output wire busy,
    
    // Debug outputs
    output wire [5:0] current_row_debug,
    output wire row_processing_debug,
    output wire [7:0] total_cycles_debug
);

    // FSM States
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DONE = 2'b10;
    
    // State registers
    reg [1:0] state, next_state;
    reg [5:0] row_counter;
    reg [5:0] next_row_counter;
    reg [7:0] cycle_counter;
    
    // Row processor control
    reg start_row_proc;
    wire row_proc_done;
    wire row_proc_busy;
    
    // Current row data extraction
    wire signed [(MATRIX_SIZE * X_WIDTH) - 1 : 0] current_x_row;
    wire signed [(MATRIX_SIZE * Y_WIDTH) - 1 : 0] current_y_row;
    
    // Extract current row from matrix (row-wise processing)
    assign current_x_row = x_matrix_flat_in[
        (row_counter * MATRIX_SIZE * X_WIDTH) +: (MATRIX_SIZE * X_WIDTH)
    ];
    
    // Matrix output buffer
    reg signed [(MATRIX_SIZE * MATRIX_SIZE * Y_WIDTH) - 1 : 0] y_matrix_buffer;
    
    // Row processor instance - reuse your existing layer_norm_top
    layer_norm_top #(
        .D_MODEL(MATRIX_SIZE),                    // Process 64-element vectors
        .X_WIDTH(X_WIDTH),
        .X_FRAC(X_FRAC),
        .Y_WIDTH(Y_WIDTH),
        .Y_FRAC(Y_FRAC),
        .PARAM_WIDTH(PARAM_WIDTH),
        .PARAM_FRAC(PARAM_FRAC),
        .INTERNAL_X_WIDTH(INTERNAL_X_WIDTH),
        .INTERNAL_X_FRAC(INTERNAL_X_FRAC),
        .ADDER_OUTPUT_WIDTH(ADDER_OUTPUT_WIDTH),
        .MEAN_CALC_OUT_WIDTH(MEAN_CALC_OUT_WIDTH),
        .VARIANCE_UNIT_DATA_WIDTH(VARIANCE_UNIT_DATA_WIDTH),
        .VARIANCE_UNIT_OUT_WIDTH(VARIANCE_UNIT_OUT_WIDTH),
        .VARIANCE_UNIT_NUM_PE(VARIANCE_UNIT_NUM_PE),
        .VAR_EPS_DATA_WIDTH(VAR_EPS_DATA_WIDTH),
        .VAR_EPS_FRAC_BITS(VAR_EPS_FRAC_BITS),
        .VAR_EPS_EPSILON_INT_VAL(VAR_EPS_EPSILON_INT_VAL),
        .SQRT_DATA_IN_WIDTH(SQRT_DATA_IN_WIDTH),
        .SQRT_ROOT_OUT_WIDTH(SQRT_ROOT_OUT_WIDTH),
        .SQRT_S_REG_WIDTH(SQRT_S_REG_WIDTH),
        .SQRT_FINAL_OUT_WIDTH(SQRT_FINAL_OUT_WIDTH),
        .SQRT_FRAC_BITS_OUT(SQRT_FRAC_BITS_OUT),
        .RECIP_INPUT_X_WIDTH(RECIP_INPUT_X_WIDTH),
        .RECIP_DIVISOR_WIDTH(RECIP_DIVISOR_WIDTH),
        .RECIP_QUOTIENT_WIDTH(RECIP_QUOTIENT_WIDTH),
        .RECIP_FINAL_OUT_WIDTH(RECIP_FINAL_OUT_WIDTH),
        .NORM_NUM_PE(NORM_NUM_PE)
    ) row_processor (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(start_row_proc),
        .x_vector_flat_in(current_x_row),
        .gamma_vector_flat_in(gamma_vector_flat_in),
        .beta_vector_flat_in(beta_vector_flat_in),
        .y_vector_flat_out(current_y_row),
        .done_valid_out(row_proc_done),
        .busy_out_debug(row_proc_busy),
        
        // Connect debug outputs if needed
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
    
    // FSM State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            row_counter <= 6'b0;
            cycle_counter <= 8'b0;
            y_matrix_buffer <= 0;
        end else begin
            state <= next_state;
            row_counter <= next_row_counter;
            cycle_counter <= cycle_counter + 1;
            
            // Store completed row result
            if (row_proc_done) begin
                y_matrix_buffer[
                    (row_counter * MATRIX_SIZE * Y_WIDTH) +: (MATRIX_SIZE * Y_WIDTH)
                ] <= current_y_row;
            end
        end
    end
    
    // FSM Next State Logic
    always @(*) begin
        next_state = state;
        next_row_counter = row_counter;
        start_row_proc = 1'b0;
        
        case (state)
            IDLE: begin
                if (start_matrix) begin
                    next_state = PROCESSING;
                    next_row_counter = 6'b0;
                    start_row_proc = 1'b1;  // Start processing first row
                end
            end
            
            PROCESSING: begin
                if (row_proc_done) begin
                    if (row_counter == MATRIX_SIZE - 1) begin
                        // Last row completed
                        next_state = DONE;
                    end else begin
                        // Start processing next row
                        next_row_counter = row_counter + 1;
                        start_row_proc = 1'b1;
                    end
                end
            end
            
            DONE: begin
                // Stay in DONE for one cycle to output result, then return to IDLE
                next_state = IDLE;
            end
        endcase
    end
    
    // Output Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_matrix_flat_out <= 0;
        end else begin
            if (state == DONE) begin
                y_matrix_flat_out <= y_matrix_buffer;
            end
        end
    end
    
    // Output assignments
    assign matrix_done = (state == DONE);
    assign busy = (state == PROCESSING);
    
    // Debug outputs
    assign current_row_debug = row_counter;
    assign row_processing_debug = (state == PROCESSING);
    assign total_cycles_debug = cycle_counter;

endmodule
