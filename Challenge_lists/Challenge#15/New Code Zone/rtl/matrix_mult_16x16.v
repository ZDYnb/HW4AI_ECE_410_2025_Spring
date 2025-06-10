// 16x16 Systolic Array Matrix Multiplier - SIMPLIFIED VERSION
// C = A × B, where A, B, C are all 16x16 matrices

module matrix_mult_16x16 (
    input clk,
    input rst_n,
    input start,
    output reg done,
    
    // Matrix A input (row-wise, 256 elements)
    input [15:0] matrix_a [0:255],
    
    // Matrix B input (column-wise, 256 elements) 
    input [15:0] matrix_b [0:255],
    
    // Result matrix C (256 elements)
    output [15:0] matrix_c [0:255]
);

// =============================================================================
// Parameters and Internal Signals
// =============================================================================

localparam ARRAY_SIZE = 16;
localparam FEED_CYCLES = 31;     // Cycles to feed all data
localparam COMPUTE_CYCLES = 16;  // Additional cycles for computation

// PE array interconnect signals - using explicit indexing
wire [15:0] a_wire [0:ARRAY_SIZE-1][0:ARRAY_SIZE];   // A data flow 
wire [15:0] b_wire [0:ARRAY_SIZE][0:ARRAY_SIZE-1];   // B data flow
wire [15:0] pe_results [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];  // PE results

// Boundary feeding registers
reg [15:0] a_feed [0:ARRAY_SIZE-1];  // Left boundary feeding
reg [15:0] b_feed [0:ARRAY_SIZE-1];  // Top boundary feeding

// Control signals
reg pe_enable;
reg [5:0] cycle_counter;
reg [1:0] state;

// State machine states
localparam IDLE = 2'b00;
localparam FEEDING = 2'b01;
localparam COMPUTING = 2'b10;
localparam DONE_STATE = 2'b11;

// =============================================================================
// Boundary Assignment
// =============================================================================

genvar k;
generate
    for (k = 0; k < ARRAY_SIZE; k = k + 1) begin : boundary_assign
        assign a_wire[k][0] = a_feed[k];   // Left boundary
        assign b_wire[0][k] = b_feed[k];   // Top boundary
    end
endgenerate

// =============================================================================
// 16x16 PE Array Instantiation
// =============================================================================

genvar i, j;
generate
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : row_gen
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : col_gen
            
            systolic_pe pe_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enable(pe_enable),
                
                // Data inputs
                .a_in(a_wire[i][j]),
                .b_in(b_wire[i][j]),
                
                // Data outputs
                .a_out(a_wire[i][j+1]),
                .b_out(b_wire[i+1][j]),
                
                // Computation result
                .c_out(pe_results[i][j])
            );
            
        end
    end
endgenerate

// =============================================================================
// Data Feeding Logic - SIMPLIFIED
// =============================================================================

// A matrix feeding (horizontal, from left boundary)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        integer row;
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin
            a_feed[row] <= 16'h0000;
        end
    end else begin
        if (state == FEEDING) begin
            integer row;
            for (row = 0; row < ARRAY_SIZE; row = row + 1) begin
                // Feed A data with diagonal timing
                if (cycle_counter >= row && cycle_counter < (row + ARRAY_SIZE)) begin
                    a_feed[row] <= matrix_a[row * ARRAY_SIZE + (cycle_counter - row)];
                end else begin
                    a_feed[row] <= 16'h0000;
                end
            end
        end else begin
            integer row;
            for (row = 0; row < ARRAY_SIZE; row = row + 1) begin
                a_feed[row] <= 16'h0000;
            end
        end
    end
end

// B matrix feeding (vertical, from top boundary)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        integer col;
        for (col = 0; col < ARRAY_SIZE; col = col + 1) begin
            b_feed[col] <= 16'h0000;
        end
    end else begin
        if (state == FEEDING) begin
            integer col;
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin
                // Feed B data with diagonal timing
                if (cycle_counter >= col && cycle_counter < (col + ARRAY_SIZE)) begin
                    b_feed[col] <= matrix_b[col * ARRAY_SIZE + (cycle_counter - col)];
                end else begin
                    b_feed[col] <= 16'h0000;
                end
            end
        end else begin
            integer col;
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin
                b_feed[col] <= 16'h0000;
            end
        end
    end
end

// =============================================================================
// Output Assignment
// =============================================================================

// Map PE results to output matrix (row-major order)
generate
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : output_row_gen
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : output_col_gen
            assign matrix_c[i * ARRAY_SIZE + j] = pe_results[i][j];
        end
    end
endgenerate

// =============================================================================
// Control State Machine
// =============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        cycle_counter <= 6'b0;
        pe_enable <= 1'b0;
        done <= 1'b0;
    end else begin
        case (state)
            
            IDLE: begin
                done <= 1'b0;
                cycle_counter <= 6'b0;
                pe_enable <= 1'b0;
                
                if (start) begin
                    state <= FEEDING;
                    pe_enable <= 1'b1;
                end
            end
            
            FEEDING: begin
                cycle_counter <= cycle_counter + 1;
                
                if (cycle_counter >= FEED_CYCLES) begin
                    state <= COMPUTING;
                    cycle_counter <= 6'b0;
                end
            end
            
            COMPUTING: begin
                cycle_counter <= cycle_counter + 1;
                
                if (cycle_counter >= COMPUTE_CYCLES) begin
                    state <= DONE_STATE;
                    pe_enable <= 1'b0;
                end
            end
            
            DONE_STATE: begin
                done <= 1'b1;
                
                if (!start) begin
                    state <= IDLE;
                    done <= 1'b0;
                end
            end
            
        endcase
    end
end

endmodule