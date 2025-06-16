// LayerNorm Matrix Processor - Continuous Stream Scheduling Version (Q5.10 format)
// Function: Performs LayerNorm on each row of a 16×16 matrix
// Input: Matrix of 256 elements (16 rows × 16 columns, row-major order)
// Output: 256-element normalized matrix
// Scheduling strategy: Continuous stream - 16 cycles send + ~20 cycles wait + 16 cycles receive = ~36 cycles total time

module layernorm_matrix_processor (
    input clk,
    input rst_n,
    
    // Control interface
    input start,                    // Start processing matrix
    output reg done,                // Processing done flag
    
    // Matrix input interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    input [15:0] matrix_i [0:255],
    
    // Matrix output interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    output reg [15:0] matrix_o [0:255]
);

// =============================================================================
// LayerNorm parameter definitions (fixed at compile time)
// =============================================================================
// Gamma parameter (scaling factor) - default 1.0 (Q5.10 = 0x0400)
parameter [15:0] GAMMA_0  = 16'h0400, GAMMA_1  = 16'h0400, GAMMA_2  = 16'h0400, GAMMA_3  = 16'h0400;
parameter [15:0] GAMMA_4  = 16'h0400, GAMMA_5  = 16'h0400, GAMMA_6  = 16'h0400, GAMMA_7  = 16'h0400;
parameter [15:0] GAMMA_8  = 16'h0400, GAMMA_9  = 16'h0400, GAMMA_10 = 16'h0400, GAMMA_11 = 16'h0400;
parameter [15:0] GAMMA_12 = 16'h0400, GAMMA_13 = 16'h0400, GAMMA_14 = 16'h0400, GAMMA_15 = 16'h0400;

// Beta parameter (offset) - default 0.0 (Q5.10 = 0x0000)
parameter [15:0] BETA_0  = 16'h0000, BETA_1  = 16'h0000, BETA_2  = 16'h0000, BETA_3  = 16'h0000;
parameter [15:0] BETA_4  = 16'h0000, BETA_5  = 16'h0000, BETA_6  = 16'h0000, BETA_7  = 16'h0000;
parameter [15:0] BETA_8  = 16'h0000, BETA_9  = 16'h0000, BETA_10 = 16'h0000, BETA_11 = 16'h0000;
parameter [15:0] BETA_12 = 16'h0000, BETA_13 = 16'h0000, BETA_14 = 16'h0000, BETA_15 = 16'h0000;

// =============================================================================
// State machine definition - continuous stream scheduling
// =============================================================================
localparam STATE_IDLE        = 3'b000;
localparam STATE_SEND        = 3'b001;  // Continuously send 16 rows
localparam STATE_WAIT_FIRST  = 3'b010;  // Wait for first output
localparam STATE_RECEIVE     = 3'b011;  // Continuously receive 16 rows of output
localparam STATE_DONE        = 3'b100;

reg [2:0] state, next_state;

// =============================================================================
// Control counters
// =============================================================================
reg [4:0] send_counter;        // Send row counter (0-15)
reg [4:0] recv_counter;        // Receive row counter (0-15)
reg first_output_received;    // Flag for receiving first output

// =============================================================================
// LayerNorm pipeline interface signals
// =============================================================================
reg pipeline_valid_in;
reg [15:0] pipeline_input_0,  pipeline_input_1,  pipeline_input_2,  pipeline_input_3;
reg [15:0] pipeline_input_4,  pipeline_input_5,  pipeline_input_6,  pipeline_input_7;
reg [15:0] pipeline_input_8,  pipeline_input_9,  pipeline_input_10, pipeline_input_11;
reg [15:0] pipeline_input_12, pipeline_input_13, pipeline_input_14, pipeline_input_15;

wire pipeline_valid_out;
wire signed [15:0] pipeline_output_0,  pipeline_output_1,  pipeline_output_2,  pipeline_output_3;
wire signed [15:0] pipeline_output_4,  pipeline_output_5,  pipeline_output_6,  pipeline_output_7;
wire signed [15:0] pipeline_output_8,  pipeline_output_9,  pipeline_output_10, pipeline_output_11;
wire signed [15:0] pipeline_output_12, pipeline_output_13, pipeline_output_14, pipeline_output_15;

// =============================================================================
// Address calculation - combinational logic
// =============================================================================
wire [8:0] send_row_base = send_counter * 16;    // Send row base address
wire [8:0] recv_row_base = recv_counter * 16;    // Receive row base address

// =============================================================================
// LayerNorm pipeline instantiation
// =============================================================================
layernorm_pipeline #(
    .GAMMA_0(GAMMA_0),   .GAMMA_1(GAMMA_1),   .GAMMA_2(GAMMA_2),   .GAMMA_3(GAMMA_3),
    .GAMMA_4(GAMMA_4),   .GAMMA_5(GAMMA_5),   .GAMMA_6(GAMMA_6),   .GAMMA_7(GAMMA_7),
    .GAMMA_8(GAMMA_8),   .GAMMA_9(GAMMA_9),   .GAMMA_10(GAMMA_10), .GAMMA_11(GAMMA_11),
    .GAMMA_12(GAMMA_12), .GAMMA_13(GAMMA_13), .GAMMA_14(GAMMA_14), .GAMMA_15(GAMMA_15),
    .BETA_0(BETA_0),     .BETA_1(BETA_1),     .BETA_2(BETA_2),     .BETA_3(BETA_3),
    .BETA_4(BETA_4),     .BETA_5(BETA_5),     .BETA_6(BETA_6),     .BETA_7(BETA_7),
    .BETA_8(BETA_8),     .BETA_9(BETA_9),     .BETA_10(BETA_10),   .BETA_11(BETA_11),
    .BETA_12(BETA_12),   .BETA_13(BETA_13),   .BETA_14(BETA_14),   .BETA_15(BETA_15)
) u_layernorm_pipeline (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(pipeline_valid_in),
    .input_vector_0(pipeline_input_0),   .input_vector_1(pipeline_input_1),
    .input_vector_2(pipeline_input_2),   .input_vector_3(pipeline_input_3),
    .input_vector_4(pipeline_input_4),   .input_vector_5(pipeline_input_5),
    .input_vector_6(pipeline_input_6),   .input_vector_7(pipeline_input_7),
    .input_vector_8(pipeline_input_8),   .input_vector_9(pipeline_input_9),
    .input_vector_10(pipeline_input_10), .input_vector_11(pipeline_input_11),
    .input_vector_12(pipeline_input_12), .input_vector_13(pipeline_input_13),
    .input_vector_14(pipeline_input_14), .input_vector_15(pipeline_input_15),
    
    // Output
    .valid_out(pipeline_valid_out),
    .output_vector_0(pipeline_output_0),   .output_vector_1(pipeline_output_1),
    .output_vector_2(pipeline_output_2),   .output_vector_3(pipeline_output_3),
    .output_vector_4(pipeline_output_4),   .output_vector_5(pipeline_output_5),
    .output_vector_6(pipeline_output_6),   .output_vector_7(pipeline_output_7),
    .output_vector_8(pipeline_output_8),   .output_vector_9(pipeline_output_9),
    .output_vector_10(pipeline_output_10), .output_vector_11(pipeline_output_11),
    .output_vector_12(pipeline_output_12), .output_vector_13(pipeline_output_13),
    .output_vector_14(pipeline_output_14), .output_vector_15(pipeline_output_15)
);

// =============================================================================
// State machine - sequential logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= STATE_IDLE;
    end else begin
        state <= next_state;
    end
end

// =============================================================================
// State machine - combinational logic
// =============================================================================
always @(*) begin
    next_state = state;
    
    case (state)
        STATE_IDLE: begin
            if (start) begin
                next_state = STATE_SEND;
            end
        end
        
        STATE_SEND: begin
            if (send_counter >= 15) begin  // Finished sending 16 rows (0-15)
                next_state = STATE_WAIT_FIRST;
            end
        end
        
        STATE_WAIT_FIRST: begin
            if (pipeline_valid_out) begin  // Received first output
                next_state = STATE_RECEIVE;
            end
        end
        
        STATE_RECEIVE: begin
            if (recv_counter == 15 && pipeline_valid_out) begin  // When receiving the 15th (last) output
                next_state = STATE_DONE;
            end
        end
        
        STATE_DONE: begin
            next_state = STATE_IDLE;
        end
        
        default: begin
            next_state = STATE_IDLE;
        end
    endcase
end

// =============================================================================
// Data path control - continuous stream scheduling logic
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 1'b0;
        send_counter <= 5'b0;
        recv_counter <= 5'b0;
        first_output_received <= 1'b0;
        pipeline_valid_in <= 1'b0;
        
        // Clear pipeline input
        pipeline_input_0  <= 16'h0000; pipeline_input_1  <= 16'h0000;
        pipeline_input_2  <= 16'h0000; pipeline_input_3  <= 16'h0000;
        pipeline_input_4  <= 16'h0000; pipeline_input_5  <= 16'h0000;
        pipeline_input_6  <= 16'h0000; pipeline_input_7  <= 16'h0000;
        pipeline_input_8  <= 16'h0000; pipeline_input_9  <= 16'h0000;
        pipeline_input_10 <= 16'h0000; pipeline_input_11 <= 16'h0000;
        pipeline_input_12 <= 16'h0000; pipeline_input_13 <= 16'h0000;
        pipeline_input_14 <= 16'h0000; pipeline_input_15 <= 16'h0000;
        
    end else begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                pipeline_valid_in <= 1'b0;
                first_output_received <= 1'b0;
                
                if (start) begin
                    send_counter <= 5'b0;
                    recv_counter <= 5'b0;
                end
            end
            
            STATE_SEND: begin
                // Continuously send 16 rows of data to pipeline
                pipeline_valid_in <= 1'b1;
                
                pipeline_input_0  <= matrix_i[send_row_base + 0];
                pipeline_input_1  <= matrix_i[send_row_base + 1];
                pipeline_input_2  <= matrix_i[send_row_base + 2];
                pipeline_input_3  <= matrix_i[send_row_base + 3];
                pipeline_input_4  <= matrix_i[send_row_base + 4];
                pipeline_input_5  <= matrix_i[send_row_base + 5];
                pipeline_input_6  <= matrix_i[send_row_base + 6];
                pipeline_input_7  <= matrix_i[send_row_base + 7];
                pipeline_input_8  <= matrix_i[send_row_base + 8];
                pipeline_input_9  <= matrix_i[send_row_base + 9];
                pipeline_input_10 <= matrix_i[send_row_base + 10];
                pipeline_input_11 <= matrix_i[send_row_base + 11];
                pipeline_input_12 <= matrix_i[send_row_base + 12];
                pipeline_input_13 <= matrix_i[send_row_base + 13];
                pipeline_input_14 <= matrix_i[send_row_base + 14];
                pipeline_input_15 <= matrix_i[send_row_base + 15];

                
                
                // Increment send counter
                send_counter <= send_counter + 1;
            end
            
        STATE_WAIT_FIRST: begin
            pipeline_valid_in <= 1'b0;
            
            if (pipeline_valid_out && !first_output_received) begin
                first_output_received <= 1'b1;
                
                // Receive first output (use recv_counter=0 address)
                matrix_o[0]  <= pipeline_output_0;
                matrix_o[1]  <= pipeline_output_1;
                matrix_o[2]  <= pipeline_output_2;
                matrix_o[3]  <= pipeline_output_3;
                matrix_o[4]  <= pipeline_output_4;
                matrix_o[5]  <= pipeline_output_5;
                matrix_o[6]  <= pipeline_output_6;
                matrix_o[7]  <= pipeline_output_7;
                matrix_o[8]  <= pipeline_output_8;
                matrix_o[9]  <= pipeline_output_9;
                matrix_o[10] <= pipeline_output_10;
                matrix_o[11] <= pipeline_output_11;
                matrix_o[12] <= pipeline_output_12;
                matrix_o[13] <= pipeline_output_13;
                matrix_o[14] <= pipeline_output_14;
                matrix_o[15] <= pipeline_output_15;
                
                // Set counter to 1, indicating first output received
                recv_counter <= 1;
            end
        end
            
            STATE_RECEIVE: begin
                // Continuously receive 16 rows of output
                pipeline_valid_in <= 1'b0;
                
                if (pipeline_valid_out) begin
                    // Store current row's 16 outputs according to recv_counter
                    matrix_o[recv_row_base + 0]  <= pipeline_output_0;
                    matrix_o[recv_row_base + 1]  <= pipeline_output_1;
                    matrix_o[recv_row_base + 2]  <= pipeline_output_2;
                    matrix_o[recv_row_base + 3]  <= pipeline_output_3;
                    matrix_o[recv_row_base + 4]  <= pipeline_output_4;
                    matrix_o[recv_row_base + 5]  <= pipeline_output_5;
                    matrix_o[recv_row_base + 6]  <= pipeline_output_6;
                    matrix_o[recv_row_base + 7]  <= pipeline_output_7;
                    matrix_o[recv_row_base + 8]  <= pipeline_output_8;
                    matrix_o[recv_row_base + 9]  <= pipeline_output_9;
                    matrix_o[recv_row_base + 10] <= pipeline_output_10;
                    matrix_o[recv_row_base + 11] <= pipeline_output_11;
                    matrix_o[recv_row_base + 12] <= pipeline_output_12;
                    matrix_o[recv_row_base + 13] <= pipeline_output_13;
                    matrix_o[recv_row_base + 14] <= pipeline_output_14;
                    matrix_o[recv_row_base + 15] <= pipeline_output_15;
                    
                    // Increment receive counter
                    recv_counter <= recv_counter + 1;
                end
            end
            
            STATE_DONE: begin
                // Processing complete
                done <= 1'b1;
                pipeline_valid_in <= 1'b0;
            end
            
            default: begin
                // Default state
                pipeline_valid_in <= 1'b0;
            end
        endcase
    end
end

endmodule