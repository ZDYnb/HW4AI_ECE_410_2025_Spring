// =========================================== 
// Block Manager - 128x128 Matrix Computation Controller
// Manages 8 sequential 64x64 computations for 2x2 block matrix multiplication
// ===========================================

`timescale 1ns/1ps

module block_manager #(
    parameter BLOCK_SIZE = 64
)(
    input clk,
    input rst_n,
    
    // Control interface
    input start,
    output reg done,
    output reg computation_valid,
    
    // Current computation indices (for external units)
    output reg [1:0] a_row_idx,      // A matrix row block index (0 or 1)
    output reg [1:0] a_col_idx,      // A matrix column block index (0 or 1) 
    output reg [1:0] b_row_idx,      // B matrix row block index (0 or 1)
    output reg [1:0] b_col_idx,      // B matrix column block index (0 or 1)
    output reg [1:0] c_row_idx,      // C matrix row block index (0 or 1)
    output reg [1:0] c_col_idx,      // C matrix column block index (0 or 1)
    
    // Computation control
    output reg start_systolic,       // Start signal for systolic array
    input systolic_done,             // Done signal from systolic array
    output reg accumulate_result,    // Signal to accumulate current result
    
    // Progress monitoring
    output reg [3:0] computation_count  // Current computation number (0-7)
);

// =========================================== 
// FSM States
// ===========================================
localparam IDLE = 2'b00;
localparam COMPUTE = 2'b01;
localparam WAIT_SYSTOLIC = 2'b10;
localparam DONE_STATE = 2'b11;

reg [1:0] state, next_state;

// =========================================== 
// Computation Sequence Table
// For C[i,j] = A[i,0]*B[0,j] + A[i,1]*B[1,j]
// ===========================================
reg [1:0] sequence_a_row [0:7];
reg [1:0] sequence_a_col [0:7];
reg [1:0] sequence_b_row [0:7];
reg [1:0] sequence_b_col [0:7];
reg [1:0] sequence_c_row [0:7];
reg [1:0] sequence_c_col [0:7];

// Initialize computation sequence
initial begin
    // Computation 0: A[0,0] × B[0,0] ¿ C[0,0]
    sequence_a_row[0] = 0; sequence_a_col[0] = 0;
    sequence_b_row[0] = 0; sequence_b_col[0] = 0;
    sequence_c_row[0] = 0; sequence_c_col[0] = 0;
    
    // Computation 1: A[0,1] × B[1,0] ¿ C[0,0] (accumulate)
    sequence_a_row[1] = 0; sequence_a_col[1] = 1;
    sequence_b_row[1] = 1; sequence_b_col[1] = 0;
    sequence_c_row[1] = 0; sequence_c_col[1] = 0;
    
    // Computation 2: A[0,0] × B[0,1] ¿ C[0,1]
    sequence_a_row[2] = 0; sequence_a_col[2] = 0;
    sequence_b_row[2] = 0; sequence_b_col[2] = 1;
    sequence_c_row[2] = 0; sequence_c_col[2] = 1;
    
    // Computation 3: A[0,1] × B[1,1] ¿ C[0,1] (accumulate)
    sequence_a_row[3] = 0; sequence_a_col[3] = 1;
    sequence_b_row[3] = 1; sequence_b_col[3] = 1;
    sequence_c_row[3] = 0; sequence_c_col[3] = 1;
    
    // Computation 4: A[1,0] × B[0,0] ¿ C[1,0]
    sequence_a_row[4] = 1; sequence_a_col[4] = 0;
    sequence_b_row[4] = 0; sequence_b_col[4] = 0;
    sequence_c_row[4] = 1; sequence_c_col[4] = 0;
    
    // Computation 5: A[1,1] × B[1,0] ¿ C[1,0] (accumulate)
    sequence_a_row[5] = 1; sequence_a_col[5] = 1;
    sequence_b_row[5] = 1; sequence_b_col[5] = 0;
    sequence_c_row[5] = 1; sequence_c_col[5] = 0;
    
    // Computation 6: A[1,0] × B[0,1] ¿ C[1,1]
    sequence_a_row[6] = 1; sequence_a_col[6] = 0;
    sequence_b_row[6] = 0; sequence_b_col[6] = 1;
    sequence_c_row[6] = 1; sequence_c_col[6] = 1;
    
    // Computation 7: A[1,1] × B[1,1] ¿ C[1,1] (accumulate)
    sequence_a_row[7] = 1; sequence_a_col[7] = 1;
    sequence_b_row[7] = 1; sequence_b_col[7] = 1;
    sequence_c_row[7] = 1; sequence_c_col[7] = 1;
end

// =========================================== 
// FSM State Transition
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            if (start)
                next_state = COMPUTE;
            else
                next_state = IDLE;
        end
        
        COMPUTE: begin
            next_state = WAIT_SYSTOLIC;
        end
        
        WAIT_SYSTOLIC: begin
            if (systolic_done) begin
                if (computation_count == 7)
                    next_state = DONE_STATE;
                else
                    next_state = COMPUTE;
            end else begin
                next_state = WAIT_SYSTOLIC;
            end
        end
        
        DONE_STATE: begin
            next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

// =========================================== 
// Computation Counter and Index Management
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        computation_count <= 0;
        a_row_idx <= 0;
        a_col_idx <= 0;
        b_row_idx <= 0;
        b_col_idx <= 0;
        c_row_idx <= 0;
        c_col_idx <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin
                    computation_count <= 0;
                    // Load first computation indices
                    a_row_idx <= sequence_a_row[0];
                    a_col_idx <= sequence_a_col[0];
                    b_row_idx <= sequence_b_row[0];
                    b_col_idx <= sequence_b_col[0];
                    c_row_idx <= sequence_c_row[0];
                    c_col_idx <= sequence_c_col[0];
                end
            end
            
            WAIT_SYSTOLIC: begin
                if (systolic_done && computation_count < 7) begin
                    computation_count <= computation_count + 1;
                    // Load next computation indices
                    a_row_idx <= sequence_a_row[computation_count + 1];
                    a_col_idx <= sequence_a_col[computation_count + 1];
                    b_row_idx <= sequence_b_row[computation_count + 1];
                    b_col_idx <= sequence_b_col[computation_count + 1];
                    c_row_idx <= sequence_c_row[computation_count + 1];
                    c_col_idx <= sequence_c_col[computation_count + 1];
                end
            end
            
            default: begin
                // Keep current values
            end
        endcase
    end
end

// =========================================== 
// Control Signal Generation
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_systolic <= 1'b0;
        computation_valid <= 1'b0;
        done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                start_systolic <= 1'b0;
                computation_valid <= 1'b0;
                done <= 1'b0;
            end
            
            COMPUTE: begin
                start_systolic <= 1'b1;  // Start systolic computation
                computation_valid <= 1'b1;
                done <= 1'b0;
            end
            
            WAIT_SYSTOLIC: begin
                start_systolic <= 1'b0;
                computation_valid <= 1'b1;
                done <= 1'b0;
            end
            
            DONE_STATE: begin
                start_systolic <= 1'b0;
                computation_valid <= 1'b0;
                done <= 1'b1;
            end
            
            default: begin
                start_systolic <= 1'b0;
                computation_valid <= 1'b0;
                done <= 1'b0;
            end
        endcase
    end
end

// Separate accumulate_result generation - USE COMBINATIONAL LOGIC
always @(*) begin
    accumulate_result = (state == WAIT_SYSTOLIC) && systolic_done;
end

// Debug monitoring
`ifdef SIMULATION
    always @(posedge clk) begin
        if (systolic_done) begin
            $display("Block Manager Debug: systolic_done=1, state=%0d, accumulate_result=%0b", 
                     state, accumulate_result);
        end
    end
`endif

// =========================================== 
// Debug and Monitoring
// ===========================================
`ifdef SIMULATION
    always @(posedge clk) begin
        if (state == COMPUTE) begin
            $display("Block Manager: Starting computation %0d", computation_count);
            $display("  A[%0d,%0d] × B[%0d,%0d] ¿ C[%0d,%0d]", 
                     a_row_idx, a_col_idx, b_row_idx, b_col_idx, c_row_idx, c_col_idx);
        end
        
        if (accumulate_result) begin
            $display("Block Manager: Accumulating result for computation %0d", computation_count);
        end
        
        if (done) begin
            $display("Block Manager: All 8 computations completed");
        end
    end
`endif

endmodule
