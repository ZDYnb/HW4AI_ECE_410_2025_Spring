// Softmax Matrix Processor - Pipeline FSM Version (Q5.10 format)
// Function: Perform Softmax on each row of a 16×16 matrix
// Input: Matrix of 256 elements (16 rows × 16 columns, row-major order)
// Output: Probability distribution matrix of 256 elements (each row sums to 1.0)
// Scheduling: Pipeline - send and receive in parallel, total time = 16 + pipeline_latency

module softmax_matrix_processor (
    input clk,
    input rst_n,
    
    // Control interface
    input start,                    // Start processing the matrix
    output reg done,                // Processing done flag
    
    // Matrix input interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    input [15:0] matrix_i [0:255],
    
    // Matrix output interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    output reg [15:0] matrix_o [0:255]
);

// =============================================================================
// Pipeline FSM Definition
// =============================================================================
// Send FSM
reg [1:0] send_state;
localparam SEND_IDLE = 2'b00;
localparam SENDING   = 2'b01;

// Receive FSM  
reg [1:0] recv_state;
localparam RECV_IDLE = 2'b00;
localparam RECEIVING = 2'b01;

// =============================================================================
// Control Counters
// =============================================================================
reg [4:0] send_counter;        // Send row counter (0-15)
reg [4:0] recv_counter;        // Receive row counter (0-15)
reg send_complete;             // Send complete flag
reg recv_complete;             // Receive complete flag

// =============================================================================
// Softmax Pipeline Interface Signals
// =============================================================================
reg pipeline_valid_in;
reg [15:0] pipeline_input [0:15];      // Current row vector to send

wire pipeline_valid_out;
wire [15:0] pipeline_output [0:15];    // Current row vector to receive

// =============================================================================
// Softmax Processor Instantiation
// =============================================================================
softmax_processor u_softmax_processor (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(pipeline_valid_in),
    .input_vector(pipeline_input),
    
    // Output
    .valid_out(pipeline_valid_out),
    .softmax_out(pipeline_output)
);

// =============================================================================
// Done Signal - Both FSMs Complete
// =============================================================================
//assign done;

// =============================================================================
// Send FSM - Controls Data Sending Independently
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        send_state <= SEND_IDLE;
        send_counter <= 5'b0;
        send_complete <= 1'b0;
        pipeline_valid_in <= 1'b0;
        
        // Clear pipeline input
        pipeline_input[0]  <= 16'h0000; pipeline_input[1]  <= 16'h0000;
        pipeline_input[2]  <= 16'h0000; pipeline_input[3]  <= 16'h0000;
        pipeline_input[4]  <= 16'h0000; pipeline_input[5]  <= 16'h0000;
        pipeline_input[6]  <= 16'h0000; pipeline_input[7]  <= 16'h0000;
        pipeline_input[8]  <= 16'h0000; pipeline_input[9]  <= 16'h0000;
        pipeline_input[10] <= 16'h0000; pipeline_input[11] <= 16'h0000;
        pipeline_input[12] <= 16'h0000; pipeline_input[13] <= 16'h0000;
        pipeline_input[14] <= 16'h0000; pipeline_input[15] <= 16'h0000;
        
    end else begin
        case (send_state)
            SEND_IDLE: begin
                pipeline_valid_in <= 1'b0;
                
                if (start) begin
                    send_state <= SENDING;
                    send_counter <= 5'b0;
                    send_complete <= 1'b0;  // Only clear on new start
                end
            end
            
SENDING: begin
                // Continuously send 16 rows of data to the pipeline
                pipeline_valid_in <= 1'b1;
                
                if (send_counter < 16) begin
                    // Send current row data
                    pipeline_input[0]  <= matrix_i[send_counter * 16 + 0];
                    pipeline_input[1]  <= matrix_i[send_counter * 16 + 1];
                    pipeline_input[2]  <= matrix_i[send_counter * 16 + 2];
                    pipeline_input[3]  <= matrix_i[send_counter * 16 + 3];
                    pipeline_input[4]  <= matrix_i[send_counter * 16 + 4];
                    pipeline_input[5]  <= matrix_i[send_counter * 16 + 5];
                    pipeline_input[6]  <= matrix_i[send_counter * 16 + 6];
                    pipeline_input[7]  <= matrix_i[send_counter * 16 + 7];
                    pipeline_input[8]  <= matrix_i[send_counter * 16 + 8];
                    pipeline_input[9]  <= matrix_i[send_counter * 16 + 9];
                    pipeline_input[10] <= matrix_i[send_counter * 16 + 10];
                    pipeline_input[11] <= matrix_i[send_counter * 16 + 11];
                    pipeline_input[12] <= matrix_i[send_counter * 16 + 12];
                    pipeline_input[13] <= matrix_i[send_counter * 16 + 13];
                    pipeline_input[14] <= matrix_i[send_counter * 16 + 14];
                    pipeline_input[15] <= matrix_i[send_counter * 16 + 15];
                    
                    // Increment send counter
                    send_counter <= send_counter + 1;
                end else begin
                    send_state <= SEND_IDLE;
                    send_complete <= 1'b1;
                    pipeline_valid_in <= 1'b0;
                end
            end
        endcase
    end
end

// =============================================================================
// Receive FSM - Controls Data Receiving Independently
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        recv_state <= RECV_IDLE;
        recv_counter <= 5'b0;
        recv_complete <= 1'b0;
        
    end else begin
        case (recv_state)
            RECV_IDLE: begin
                if (pipeline_valid_out) begin
                    recv_state <= RECEIVING;
                    recv_counter <= 5'b1;  // Set to 1, since we just received row 0
                    recv_complete <= 1'b0;  // Clear at start of new receive
                    
                    // Receive first row output (row 0)
                    matrix_o[0]  <= pipeline_output[0];
                    matrix_o[1]  <= pipeline_output[1];
                    matrix_o[2]  <= pipeline_output[2];
                    matrix_o[3]  <= pipeline_output[3];
                    matrix_o[4]  <= pipeline_output[4];
                    matrix_o[5]  <= pipeline_output[5];
                    matrix_o[6]  <= pipeline_output[6];
                    matrix_o[7]  <= pipeline_output[7];
                    matrix_o[8]  <= pipeline_output[8];
                    matrix_o[9]  <= pipeline_output[9];
                    matrix_o[10] <= pipeline_output[10];
                    matrix_o[11] <= pipeline_output[11];
                    matrix_o[12] <= pipeline_output[12];
                    matrix_o[13] <= pipeline_output[13];
                    matrix_o[14] <= pipeline_output[14];
                    matrix_o[15] <= pipeline_output[15];
                end
            end
            
            RECEIVING: begin
                if (pipeline_valid_out) begin
                    // Receive current row data
                    matrix_o[recv_counter * 16 + 0]  <= pipeline_output[0];
                    matrix_o[recv_counter * 16 + 1]  <= pipeline_output[1];
                    matrix_o[recv_counter * 16 + 2]  <= pipeline_output[2];
                    matrix_o[recv_counter * 16 + 3]  <= pipeline_output[3];
                    matrix_o[recv_counter * 16 + 4]  <= pipeline_output[4];
                    matrix_o[recv_counter * 16 + 5]  <= pipeline_output[5];
                    matrix_o[recv_counter * 16 + 6]  <= pipeline_output[6];
                    matrix_o[recv_counter * 16 + 7]  <= pipeline_output[7];
                    matrix_o[recv_counter * 16 + 8]  <= pipeline_output[8];
                    matrix_o[recv_counter * 16 + 9]  <= pipeline_output[9];
                    matrix_o[recv_counter * 16 + 10] <= pipeline_output[10];
                    matrix_o[recv_counter * 16 + 11] <= pipeline_output[11];
                    matrix_o[recv_counter * 16 + 12] <= pipeline_output[12];
                    matrix_o[recv_counter * 16 + 13] <= pipeline_output[13];
                    matrix_o[recv_counter * 16 + 14] <= pipeline_output[14];
                    matrix_o[recv_counter * 16 + 15] <= pipeline_output[15];
                    // Increment receive counter
                    recv_counter <= recv_counter + 1;
                end
                if (recv_counter == 15) begin
                    recv_state <= RECV_IDLE;
                    recv_complete <= 1'b1;
                    done <= 1'b1;
                end
            end
        endcase
    end
end

endmodule