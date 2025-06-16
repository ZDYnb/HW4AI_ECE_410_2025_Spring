// ===========================================
// Systolic Array Top Module - Parameterized
// Based on your original 4x4 design with parameterization
// Uses modular processing_element.v
// ===========================================

`timescale 1ns/1ps

module systolic_array_top #(
    parameter ARRAY_SIZE = 4,           // Configurable: 4, 8, 16, 32, 64
    parameter DATA_WIDTH = 16,          // Data width (S5.10)
    parameter WEIGHT_WIDTH = 8,         // Weight width (S1.6)
    parameter ACCUM_WIDTH = 32,         // Accumulator width (keep original 32-bit)
    parameter MAX_CYCLES = 255           // Expanded for larger arrays (2*64-1 = 127 max)
)(
    input                               clk,
    input                               rst_n,
    input                               start,              // Start computation
    
    // Matrix A inputs (flattened for Verilog compatibility)
    input  [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0]  matrix_a_flat,
    
    // Matrix B inputs (flattened for Verilog compatibility)  
    input  [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat,
    
    // Results output (flattened for Verilog compatibility)
    output [ACCUM_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0]  result_flat,
    
    output                              computation_done,
    output                              result_valid
);

    // ==========================================
    // Internal 2D Arrays (for easy indexing)
    // ==========================================
    reg  [DATA_WIDTH-1:0]               matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg  [WEIGHT_WIDTH-1:0]             matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [ACCUM_WIDTH-1:0]              result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Generate variables
    genvar row, col;
    
    // ==========================================
    // Flatten/Unflatten Logic
    // ==========================================
    
    // Unflatten inputs to 2D arrays
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin: UNFLATTEN_ROW
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin: UNFLATTEN_COL
                always @(*) begin
                    matrix_a[row][col] = matrix_a_flat[(row*ARRAY_SIZE + col + 1)*DATA_WIDTH - 1 : (row*ARRAY_SIZE + col)*DATA_WIDTH];
                    matrix_b[row][col] = matrix_b_flat[(row*ARRAY_SIZE + col + 1)*WEIGHT_WIDTH - 1 : (row*ARRAY_SIZE + col)*WEIGHT_WIDTH];
                end
                
                // Flatten outputs
                assign result_flat[(row*ARRAY_SIZE + col + 1)*ACCUM_WIDTH - 1 : (row*ARRAY_SIZE + col)*ACCUM_WIDTH] = result[row][col];
            end
        end
    endgenerate
    
    // ==========================================
    // FSM States (Keep your original design)
    // ==========================================
    parameter IDLE       = 3'b000;
    parameter LOAD_DATA  = 3'b001;
    parameter COMPUTE    = 3'b010;
    parameter DRAIN      = 3'b011;
    parameter DONE       = 3'b100;
    
    // ==========================================
    // FSM Signals
    // ==========================================
    reg [2:0] current_state, next_state;
    reg [7:0] cycle_counter;        // Expanded to 8-bit for larger arrays (255 max)
    reg [7:0] compute_counter;      // Expanded to 8-bit for larger arrays
    
    // ==========================================
    // Control Signals
    // ==========================================
    reg enable_pe;
    reg clear_accum_pe;
    reg data_feed_enable;
    reg weight_feed_enable;
    
    // ==========================================
    // Data Scheduling Arrays (Dynamic sizing)
    // ==========================================
    reg [DATA_WIDTH-1:0]    data_schedule [0:MAX_CYCLES-1][0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0]  weight_schedule [0:MAX_CYCLES-1][0:ARRAY_SIZE-1];
    reg                     data_valid_schedule [0:MAX_CYCLES-1][0:ARRAY_SIZE-1];
    reg                     weight_valid_schedule [0:MAX_CYCLES-1][0:ARRAY_SIZE-1];
    
    // ==========================================
    // Current Cycle Inputs
    // ==========================================
    reg [DATA_WIDTH-1:0]    data_in [0:ARRAY_SIZE-1];
    reg [WEIGHT_WIDTH-1:0]  weight_in [0:ARRAY_SIZE-1];
    reg                     data_valid [0:ARRAY_SIZE-1];
    reg                     weight_valid [0:ARRAY_SIZE-1];
    
    // ==========================================
    // PE Array Interconnects (2D arrays)
    // ==========================================
    wire [DATA_WIDTH-1:0]   data_h [0:ARRAY_SIZE-1][0:ARRAY_SIZE];     // Horizontal data flow
    wire                    data_valid_h [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
    wire [WEIGHT_WIDTH-1:0] weight_v [0:ARRAY_SIZE][0:ARRAY_SIZE-1];    // Vertical weight flow  
    wire                    weight_valid_v [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
    wire [ACCUM_WIDTH-1:0]  pe_result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire                    pe_valid [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // ==========================================
    // FSM State Machine (Keep your original logic)
    // ==========================================
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start)
                    next_state = LOAD_DATA;
                else
                    next_state = IDLE;
            end
            
            LOAD_DATA: begin
                if (cycle_counter == (2*ARRAY_SIZE-2))  // Parameterized cycle count
                    next_state = COMPUTE;
                else
                    next_state = LOAD_DATA;
            end
            
            COMPUTE: begin
                if (compute_counter == (ARRAY_SIZE-1))  // Dynamic compute cycles based on array size
                    next_state = DRAIN;
                else
                    next_state = COMPUTE;
            end
            
            DRAIN: begin
                if (cycle_counter == 3)  // Drain pipeline
                    next_state = DONE;
                else
                    next_state = DRAIN;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Counter management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 8'd0;
            compute_counter <= 8'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    cycle_counter <= 8'd0;
                    compute_counter <= 8'd0;
                end
                
                LOAD_DATA: begin
                    if (cycle_counter < (2*ARRAY_SIZE-2))
                        cycle_counter <= cycle_counter + 1;
                end
                
                COMPUTE: begin
                    cycle_counter <= 8'd0;  // Reset for drain phase
                    if (compute_counter < (ARRAY_SIZE-1))
                        compute_counter <= compute_counter + 1;
                end
                
                DRAIN: begin
                    if (cycle_counter < 3)
                        cycle_counter <= cycle_counter + 1;
                end
                
                DONE: begin
                    cycle_counter <= 8'd0;
                    compute_counter <= 8'd0;
                end
            endcase
        end
    end
    
    // Control signal generation
    always @(*) begin
        enable_pe = 1'b0;
        clear_accum_pe = 1'b0;
        data_feed_enable = 1'b0;
        weight_feed_enable = 1'b0;
        
        case (current_state)
            IDLE: begin
                clear_accum_pe = 1'b1;
            end
            
            LOAD_DATA: begin
                enable_pe = 1'b1;
                data_feed_enable = 1'b1;
                weight_feed_enable = 1'b1;
                if (cycle_counter == 8'd0)
                    clear_accum_pe = 1'b1;
            end
            
            COMPUTE: begin
                enable_pe = 1'b1;
            end
            
            DRAIN: begin
                enable_pe = 1'b1;
            end
            
            DONE: begin
                // Results are ready
            end
        endcase
    end
    
    // ==========================================
    // Data Scheduling Logic (Parameterized)
    // ==========================================
    
    integer i, j, cycle;
    
    // Initialize data schedule for systolic loading pattern
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Clear all schedules
            for (cycle = 0; cycle < MAX_CYCLES; cycle = cycle + 1) begin
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    data_schedule[cycle][i] <= {DATA_WIDTH{1'b0}};
                    weight_schedule[cycle][i] <= {WEIGHT_WIDTH{1'b0}};
                    data_valid_schedule[cycle][i] <= 1'b0;
                    weight_valid_schedule[cycle][i] <= 1'b0;
                end
            end
        end else if (start) begin
            // Generate systolic loading pattern algorithmically
            for (cycle = 0; cycle < 2*ARRAY_SIZE-1; cycle = cycle + 1) begin
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    // Data (Matrix A) scheduling - diagonal loading
                    if ((cycle >= i) && (cycle - i < ARRAY_SIZE)) begin
                        data_schedule[cycle][i] <= matrix_a[i][cycle - i];
                        data_valid_schedule[cycle][i] <= 1'b1;
                    end else begin
                        data_schedule[cycle][i] <= {DATA_WIDTH{1'b0}};
                        data_valid_schedule[cycle][i] <= 1'b0;
                    end
                    
                    // Weight (Matrix B) scheduling - diagonal loading
                    if ((cycle >= i) && (cycle - i < ARRAY_SIZE)) begin
                        weight_schedule[cycle][i] <= matrix_b[cycle - i][i];
                        weight_valid_schedule[cycle][i] <= 1'b1;
                    end else begin
                        weight_schedule[cycle][i] <= {WEIGHT_WIDTH{1'b0}};
                        weight_valid_schedule[cycle][i] <= 1'b0;
                    end
                end
            end
        end
    end
    
    // Current cycle data/weight selection
    always @(*) begin
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            if (data_feed_enable && cycle_counter < (2*ARRAY_SIZE-1)) begin
                data_in[i] = data_schedule[cycle_counter][i];
                weight_in[i] = weight_schedule[cycle_counter][i];
                data_valid[i] = data_valid_schedule[cycle_counter][i];
                weight_valid[i] = weight_valid_schedule[cycle_counter][i];
            end else begin
                data_in[i] = {DATA_WIDTH{1'b0}};
                weight_in[i] = {WEIGHT_WIDTH{1'b0}};
                data_valid[i] = 1'b0;
                weight_valid[i] = 1'b0;
            end
        end
    end
    
    // ==========================================
    // PE Array Generation (Parameterized)
    // ==========================================
    
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin: PE_ROW
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin: PE_COL
                
                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .WEIGHT_WIDTH(WEIGHT_WIDTH),
                    .ACCUM_WIDTH(ACCUM_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(enable_pe),
                    .clear_accum(clear_accum_pe),
                    
                    // Horizontal data flow
                    .data_in(data_h[row][col]),
                    .data_valid_in(data_valid_h[row][col]),
                    .data_out(data_h[row][col+1]),
                    .data_valid_out(data_valid_h[row][col+1]),
                    
                    // Vertical weight flow
                    .weight_in(weight_v[row][col]),
                    .weight_valid_in(weight_valid_v[row][col]),
                    .weight_out(weight_v[row+1][col]),
                    .weight_valid_out(weight_valid_v[row+1][col]),
                    
                    // Results
                    .accum_out(result[row][col]),
                    .result_valid(pe_valid[row][col])
                );
                
            end
        end
    endgenerate
    
    // ==========================================
    // Array Input Connections
    // ==========================================
    
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin: INPUT_ROW
            // Connect data inputs (left edge)
            assign data_h[row][0] = data_in[row];
            assign data_valid_h[row][0] = data_valid[row];
        end
        
        for (col = 0; col < ARRAY_SIZE; col = col + 1) begin: INPUT_COL
            // Connect weight inputs (top edge)  
            assign weight_v[0][col] = weight_in[col];
            assign weight_valid_v[0][col] = weight_valid[col];
        end
    endgenerate
    
    // ==========================================
    // Output Assignment  
    // ==========================================
    
    // Results are already connected via flatten logic above
    
    assign computation_done = (current_state == DONE);
    assign result_valid = (current_state == DONE);

endmodule
