// transformer_core.v - Simple passthrough transformer for initial testing
module transformer_core #(
    parameter MATRIX_SIZE = 64,
    parameter DATA_WIDTH = 16,
    parameter MATRIX_ELEMENTS = MATRIX_SIZE * MATRIX_SIZE
)(
    input wire clk,
    input wire rst_n,
    
    // Input interface
    input wire signed [DATA_WIDTH-1:0] matrix_in [0:MATRIX_ELEMENTS-1],
    input wire matrix_valid,
    
    // Output interface  
    output reg signed [DATA_WIDTH-1:0] matrix_out [0:MATRIX_ELEMENTS-1],
    output reg matrix_ready,
    
    // Control
    input wire compute_start,
    output reg compute_done
);

// Simple state machine for timing
localparam IDLE = 2'b00;
localparam COMPUTING = 2'b01; 
localparam DONE = 2'b10;

reg [1:0] current_state;
reg [7:0] compute_counter;
integer i;

// For now, just do passthrough with fixed delay
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        compute_counter <= 8'h00;
        compute_done <= 1'b0;
        matrix_ready <= 1'b0;
        for (i = 0; i < MATRIX_ELEMENTS; i = i + 1) begin
            matrix_out[i] <= 16'h0000;
        end
    end else begin
        case (current_state)
            IDLE: begin
                compute_done <= 1'b0;
                matrix_ready <= 1'b0;
                
                if (compute_start && matrix_valid) begin
                    current_state <= COMPUTING;
                    compute_counter <= 8'h00;
                    
                    // Copy input to output (passthrough)
                    for (i = 0; i < MATRIX_ELEMENTS; i = i + 1) begin
                        matrix_out[i] <= matrix_in[i];
                    end
                end
            end
            
            COMPUTING: begin
                compute_counter <= compute_counter + 1;
                
                // Simulate some processing time (33 cycles as designed)
                if (compute_counter >= 8'd32) begin
                    current_state <= DONE;
                    compute_done <= 1'b1;
                    matrix_ready <= 1'b1;
                end
            end
            
            DONE: begin
                if (!compute_start) begin
                    current_state <= IDLE;
                    compute_done <= 1'b0;
                end
            end
            
            default: begin
                current_state <= IDLE;
            end
        endcase
    end
end

endmodule