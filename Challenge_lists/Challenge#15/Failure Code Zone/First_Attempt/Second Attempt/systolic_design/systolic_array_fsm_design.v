// ===========================================
// 4×4 Systolic Array with FSM Controller
// Pure Verilog Design
// ===========================================

`timescale 1ns/1ps

// ===========================================
// FSM-Controlled 4×4 Systolic Array Top Module
// ===========================================
module systolic_array_4x4 (
    input         clk,
    input         rst_n,
    input         start,              // Start computation
    
    // Matrix A inputs (row-wise)
    input  [15:0] matrix_a_00, matrix_a_01, matrix_a_02, matrix_a_03,
    input  [15:0] matrix_a_10, matrix_a_11, matrix_a_12, matrix_a_13,
    input  [15:0] matrix_a_20, matrix_a_21, matrix_a_22, matrix_a_23,
    input  [15:0] matrix_a_30, matrix_a_31, matrix_a_32, matrix_a_33,
    
    // Matrix B inputs (column-wise)
    input  [7:0]  matrix_b_00, matrix_b_01, matrix_b_02, matrix_b_03,
    input  [7:0]  matrix_b_10, matrix_b_11, matrix_b_12, matrix_b_13,
    input  [7:0]  matrix_b_20, matrix_b_21, matrix_b_22, matrix_b_23,
    input  [7:0]  matrix_b_30, matrix_b_31, matrix_b_32, matrix_b_33,
    
    // Results output (4×4 matrix)
    output [31:0] result_00, result_01, result_02, result_03,
    output [31:0] result_10, result_11, result_12, result_13,
    output [31:0] result_20, result_21, result_22, result_23,
    output [31:0] result_30, result_31, result_32, result_33,
    
    output        computation_done,
    output        result_valid
);

    // FSM States
    parameter IDLE       = 3'b000;
    parameter LOAD_DATA  = 3'b001;
    parameter COMPUTE    = 3'b010;
    parameter DRAIN      = 3'b011;
    parameter DONE       = 3'b100;
    
    // FSM signals
    reg [2:0] current_state, next_state;
    reg [3:0] cycle_counter;
    reg [3:0] compute_counter;
    
    // Control signals
    reg enable_pe;
    reg clear_accum_pe;
    reg data_feed_enable;
    reg weight_feed_enable;
    
    // Data input scheduling registers
    reg [15:0] data_schedule [0:6][0:3];  // 7 cycles, 4 data inputs
    reg [7:0]  weight_schedule [0:6][0:3]; // 7 cycles, 4 weight inputs
    reg        data_valid_schedule [0:6][0:3];
    reg        weight_valid_schedule [0:6][0:3];
    
    // Current cycle inputs to PE array
    reg [15:0] data_in_0, data_in_1, data_in_2, data_in_3;
    reg [7:0]  weight_in_0, weight_in_1, weight_in_2, weight_in_3;
    reg        data_valid_0, data_valid_1, data_valid_2, data_valid_3;
    reg        weight_valid_0, weight_valid_1, weight_valid_2, weight_valid_3;
    
    // Internal PE interconnects
    wire [15:0] data_h_0_1, data_h_0_2, data_h_0_3, data_h_0_4;
    wire [15:0] data_h_1_1, data_h_1_2, data_h_1_3, data_h_1_4;
    wire [15:0] data_h_2_1, data_h_2_2, data_h_2_3, data_h_2_4;
    wire [15:0] data_h_3_1, data_h_3_2, data_h_3_3, data_h_3_4;
    
    wire data_valid_h_0_1, data_valid_h_0_2, data_valid_h_0_3, data_valid_h_0_4;
    wire data_valid_h_1_1, data_valid_h_1_2, data_valid_h_1_3, data_valid_h_1_4;
    wire data_valid_h_2_1, data_valid_h_2_2, data_valid_h_2_3, data_valid_h_2_4;
    wire data_valid_h_3_1, data_valid_h_3_2, data_valid_h_3_3, data_valid_h_3_4;
    
    wire [7:0] weight_v_1_0, weight_v_2_0, weight_v_3_0, weight_v_4_0;
    wire [7:0] weight_v_1_1, weight_v_2_1, weight_v_3_1, weight_v_4_1;
    wire [7:0] weight_v_1_2, weight_v_2_2, weight_v_3_2, weight_v_4_2;
    wire [7:0] weight_v_1_3, weight_v_2_3, weight_v_3_3, weight_v_4_3;
    
    wire weight_valid_v_1_0, weight_valid_v_2_0, weight_valid_v_3_0, weight_valid_v_4_0;
    wire weight_valid_v_1_1, weight_valid_v_2_1, weight_valid_v_3_1, weight_valid_v_4_1;
    wire weight_valid_v_1_2, weight_valid_v_2_2, weight_valid_v_3_2, weight_valid_v_4_2;
    wire weight_valid_v_1_3, weight_valid_v_2_3, weight_valid_v_3_3, weight_valid_v_4_3;
    
    wire valid_00, valid_01, valid_02, valid_03;
    wire valid_10, valid_11, valid_12, valid_13;
    wire valid_20, valid_21, valid_22, valid_23;
    wire valid_30, valid_31, valid_32, valid_33;
    
    // ===========================================
    // FSM State Machine
    // ===========================================
    
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
                if (cycle_counter == 4'd6)  // 7 cycles (0-6) for loading
                    next_state = COMPUTE;
                else
                    next_state = LOAD_DATA;
            end
            
            COMPUTE: begin
                if (compute_counter == 4'd7)  // Additional compute cycles
                    next_state = DRAIN;
                else
                    next_state = COMPUTE;
            end
            
            DRAIN: begin
                if (cycle_counter == 4'd3)  // Drain pipeline
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
            cycle_counter <= 4'd0;
            compute_counter <= 4'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    cycle_counter <= 4'd0;
                    compute_counter <= 4'd0;
                end
                
                LOAD_DATA: begin
                    if (cycle_counter < 4'd6)
                        cycle_counter <= cycle_counter + 1;
                end
                
                COMPUTE: begin
                    cycle_counter <= 4'd0;  // Reset for drain phase
                    if (compute_counter < 4'd7)
                        compute_counter <= compute_counter + 1;
                end
                
                DRAIN: begin
                    if (cycle_counter < 4'd3)
                        cycle_counter <= cycle_counter + 1;
                end
                
                DONE: begin
                    cycle_counter <= 4'd0;
                    compute_counter <= 4'd0;
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
                if (cycle_counter == 4'd0)
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
    
    // ===========================================
    // Data Scheduling Logic
    // ===========================================
    
    // Initialize data schedule for systolic loading pattern
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Clear all schedules
            data_schedule[0][0] <= 16'd0; data_schedule[0][1] <= 16'd0; data_schedule[0][2] <= 16'd0; data_schedule[0][3] <= 16'd0;
            data_schedule[1][0] <= 16'd0; data_schedule[1][1] <= 16'd0; data_schedule[1][2] <= 16'd0; data_schedule[1][3] <= 16'd0;
            data_schedule[2][0] <= 16'd0; data_schedule[2][1] <= 16'd0; data_schedule[2][2] <= 16'd0; data_schedule[2][3] <= 16'd0;
            data_schedule[3][0] <= 16'd0; data_schedule[3][1] <= 16'd0; data_schedule[3][2] <= 16'd0; data_schedule[3][3] <= 16'd0;
            data_schedule[4][0] <= 16'd0; data_schedule[4][1] <= 16'd0; data_schedule[4][2] <= 16'd0; data_schedule[4][3] <= 16'd0;
            data_schedule[5][0] <= 16'd0; data_schedule[5][1] <= 16'd0; data_schedule[5][2] <= 16'd0; data_schedule[5][3] <= 16'd0;
            data_schedule[6][0] <= 16'd0; data_schedule[6][1] <= 16'd0; data_schedule[6][2] <= 16'd0; data_schedule[6][3] <= 16'd0;
        end else if (start) begin
            // Systolic loading pattern for Matrix A
            // Cycle 0
            data_schedule[0][0] <= matrix_a_00; data_schedule[0][1] <= 16'd0;      data_schedule[0][2] <= 16'd0;      data_schedule[0][3] <= 16'd0;
            // Cycle 1  
            data_schedule[1][0] <= matrix_a_01; data_schedule[1][1] <= matrix_a_10; data_schedule[1][2] <= 16'd0;      data_schedule[1][3] <= 16'd0;
            // Cycle 2
            data_schedule[2][0] <= matrix_a_02; data_schedule[2][1] <= matrix_a_11; data_schedule[2][2] <= matrix_a_20; data_schedule[2][3] <= 16'd0;
            // Cycle 3
            data_schedule[3][0] <= matrix_a_03; data_schedule[3][1] <= matrix_a_12; data_schedule[3][2] <= matrix_a_21; data_schedule[3][3] <= matrix_a_30;
            // Cycle 4
            data_schedule[4][0] <= 16'd0;      data_schedule[4][1] <= matrix_a_13; data_schedule[4][2] <= matrix_a_22; data_schedule[4][3] <= matrix_a_31;
            // Cycle 5
            data_schedule[5][0] <= 16'd0;      data_schedule[5][1] <= 16'd0;      data_schedule[5][2] <= matrix_a_23; data_schedule[5][3] <= matrix_a_32;
            // Cycle 6
            data_schedule[6][0] <= 16'd0;      data_schedule[6][1] <= 16'd0;      data_schedule[6][2] <= 16'd0;      data_schedule[6][3] <= matrix_a_33;
            
            // Weight scheduling pattern for Matrix B
            weight_schedule[0][0] <= matrix_b_00; weight_schedule[0][1] <= 8'd0;       weight_schedule[0][2] <= 8'd0;       weight_schedule[0][3] <= 8'd0;
            weight_schedule[1][0] <= matrix_b_10; weight_schedule[1][1] <= matrix_b_01; weight_schedule[1][2] <= 8'd0;       weight_schedule[1][3] <= 8'd0;
            weight_schedule[2][0] <= matrix_b_20; weight_schedule[2][1] <= matrix_b_11; weight_schedule[2][2] <= matrix_b_02; weight_schedule[2][3] <= 8'd0;
            weight_schedule[3][0] <= matrix_b_30; weight_schedule[3][1] <= matrix_b_21; weight_schedule[3][2] <= matrix_b_12; weight_schedule[3][3] <= matrix_b_03;
            weight_schedule[4][0] <= 8'd0;       weight_schedule[4][1] <= matrix_b_31; weight_schedule[4][2] <= matrix_b_22; weight_schedule[4][3] <= matrix_b_13;
            weight_schedule[5][0] <= 8'd0;       weight_schedule[5][1] <= 8'd0;       weight_schedule[5][2] <= matrix_b_32; weight_schedule[5][3] <= matrix_b_23;
            weight_schedule[6][0] <= 8'd0;       weight_schedule[6][1] <= 8'd0;       weight_schedule[6][2] <= 8'd0;       weight_schedule[6][3] <= matrix_b_33;
            
            // Valid signals
            data_valid_schedule[0][0] <= 1'b1; data_valid_schedule[0][1] <= 1'b0; data_valid_schedule[0][2] <= 1'b0; data_valid_schedule[0][3] <= 1'b0;
            data_valid_schedule[1][0] <= 1'b1; data_valid_schedule[1][1] <= 1'b1; data_valid_schedule[1][2] <= 1'b0; data_valid_schedule[1][3] <= 1'b0;
            data_valid_schedule[2][0] <= 1'b1; data_valid_schedule[2][1] <= 1'b1; data_valid_schedule[2][2] <= 1'b1; data_valid_schedule[2][3] <= 1'b0;
            data_valid_schedule[3][0] <= 1'b1; data_valid_schedule[3][1] <= 1'b1; data_valid_schedule[3][2] <= 1'b1; data_valid_schedule[3][3] <= 1'b1;
            data_valid_schedule[4][0] <= 1'b0; data_valid_schedule[4][1] <= 1'b1; data_valid_schedule[4][2] <= 1'b1; data_valid_schedule[4][3] <= 1'b1;
            data_valid_schedule[5][0] <= 1'b0; data_valid_schedule[5][1] <= 1'b0; data_valid_schedule[5][2] <= 1'b1; data_valid_schedule[5][3] <= 1'b1;
            data_valid_schedule[6][0] <= 1'b0; data_valid_schedule[6][1] <= 1'b0; data_valid_schedule[6][2] <= 1'b0; data_valid_schedule[6][3] <= 1'b1;
            
            weight_valid_schedule[0][0] <= 1'b1; weight_valid_schedule[0][1] <= 1'b0; weight_valid_schedule[0][2] <= 1'b0; weight_valid_schedule[0][3] <= 1'b0;
            weight_valid_schedule[1][0] <= 1'b1; weight_valid_schedule[1][1] <= 1'b1; weight_valid_schedule[1][2] <= 1'b0; weight_valid_schedule[1][3] <= 1'b0;
            weight_valid_schedule[2][0] <= 1'b1; weight_valid_schedule[2][1] <= 1'b1; weight_valid_schedule[2][2] <= 1'b1; weight_valid_schedule[2][3] <= 1'b0;
            weight_valid_schedule[3][0] <= 1'b1; weight_valid_schedule[3][1] <= 1'b1; weight_valid_schedule[3][2] <= 1'b1; weight_valid_schedule[3][3] <= 1'b1;
            weight_valid_schedule[4][0] <= 1'b0; weight_valid_schedule[4][1] <= 1'b1; weight_valid_schedule[4][2] <= 1'b1; weight_valid_schedule[4][3] <= 1'b1;
            weight_valid_schedule[5][0] <= 1'b0; weight_valid_schedule[5][1] <= 1'b0; weight_valid_schedule[5][2] <= 1'b1; weight_valid_schedule[5][3] <= 1'b1;
            weight_valid_schedule[6][0] <= 1'b0; weight_valid_schedule[6][1] <= 1'b0; weight_valid_schedule[6][2] <= 1'b0; weight_valid_schedule[6][3] <= 1'b1;
        end
    end
    
    // Current cycle data/weight selection
    always @(*) begin
        if (data_feed_enable && cycle_counter <= 4'd6) begin
            data_in_0 = data_schedule[cycle_counter][0];
            data_in_1 = data_schedule[cycle_counter][1];
            data_in_2 = data_schedule[cycle_counter][2];
            data_in_3 = data_schedule[cycle_counter][3];
            
            weight_in_0 = weight_schedule[cycle_counter][0];
            weight_in_1 = weight_schedule[cycle_counter][1];
            weight_in_2 = weight_schedule[cycle_counter][2];
            weight_in_3 = weight_schedule[cycle_counter][3];
            
            data_valid_0 = data_valid_schedule[cycle_counter][0];
            data_valid_1 = data_valid_schedule[cycle_counter][1];
            data_valid_2 = data_valid_schedule[cycle_counter][2];
            data_valid_3 = data_valid_schedule[cycle_counter][3];
            
            weight_valid_0 = weight_valid_schedule[cycle_counter][0];
            weight_valid_1 = weight_valid_schedule[cycle_counter][1];
            weight_valid_2 = weight_valid_schedule[cycle_counter][2];
            weight_valid_3 = weight_valid_schedule[cycle_counter][3];
        end else begin
            data_in_0 = 16'd0;    data_in_1 = 16'd0;    data_in_2 = 16'd0;    data_in_3 = 16'd0;
            weight_in_0 = 8'd0;   weight_in_1 = 8'd0;   weight_in_2 = 8'd0;   weight_in_3 = 8'd0;
            data_valid_0 = 1'b0;  data_valid_1 = 1'b0;  data_valid_2 = 1'b0;  data_valid_3 = 1'b0;
            weight_valid_0 = 1'b0; weight_valid_1 = 1'b0; weight_valid_2 = 1'b0; weight_valid_3 = 1'b0;
        end
    end
    
    // ===========================================
    // 4×4 Processing Element Array
    // ===========================================
    
    // Row 0
    processing_element pe_00 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_in_0), .data_valid_in(data_valid_0),
        .data_out(data_h_0_1), .data_valid_out(data_valid_h_0_1),
        .weight_in(weight_in_0), .weight_valid_in(weight_valid_0),
        .weight_out(weight_v_1_0), .weight_valid_out(weight_valid_v_1_0),
        .accum_out(result_00), .result_valid(valid_00)
    );
    
    processing_element pe_01 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_0_1), .data_valid_in(data_valid_h_0_1),
        .data_out(data_h_0_2), .data_valid_out(data_valid_h_0_2),
        .weight_in(weight_in_1), .weight_valid_in(weight_valid_1),
        .weight_out(weight_v_1_1), .weight_valid_out(weight_valid_v_1_1),
        .accum_out(result_01), .result_valid(valid_01)
    );
    
    processing_element pe_02 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_0_2), .data_valid_in(data_valid_h_0_2),
        .data_out(data_h_0_3), .data_valid_out(data_valid_h_0_3),
        .weight_in(weight_in_2), .weight_valid_in(weight_valid_2),
        .weight_out(weight_v_1_2), .weight_valid_out(weight_valid_v_1_2),
        .accum_out(result_02), .result_valid(valid_02)
    );
    
    processing_element pe_03 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_0_3), .data_valid_in(data_valid_h_0_3),
        .data_out(data_h_0_4), .data_valid_out(data_valid_h_0_4),
        .weight_in(weight_in_3), .weight_valid_in(weight_valid_3),
        .weight_out(weight_v_1_3), .weight_valid_out(weight_valid_v_1_3),
        .accum_out(result_03), .result_valid(valid_03)
    );
    
    // Row 1
    processing_element pe_10 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_in_1), .data_valid_in(data_valid_1),
        .data_out(data_h_1_1), .data_valid_out(data_valid_h_1_1),
        .weight_in(weight_v_1_0), .weight_valid_in(weight_valid_v_1_0),
        .weight_out(weight_v_2_0), .weight_valid_out(weight_valid_v_2_0),
        .accum_out(result_10), .result_valid(valid_10)
    );
    
    processing_element pe_11 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_1_1), .data_valid_in(data_valid_h_1_1),
        .data_out(data_h_1_2), .data_valid_out(data_valid_h_1_2),
        .weight_in(weight_v_1_1), .weight_valid_in(weight_valid_v_1_1),
        .weight_out(weight_v_2_1), .weight_valid_out(weight_valid_v_2_1),
        .accum_out(result_11), .result_valid(valid_11)
    );
    
    processing_element pe_12 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_1_2), .data_valid_in(data_valid_h_1_2),
        .data_out(data_h_1_3), .data_valid_out(data_valid_h_1_3),
        .weight_in(weight_v_1_2), .weight_valid_in(weight_valid_v_1_2),
        .weight_out(weight_v_2_2), .weight_valid_out(weight_valid_v_2_2),
        .accum_out(result_12), .result_valid(valid_12)
    );
    
    processing_element pe_13 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_1_3), .data_valid_in(data_valid_h_1_3),
        .data_out(data_h_1_4), .data_valid_out(data_valid_h_1_4),
        .weight_in(weight_v_1_3), .weight_valid_in(weight_valid_v_1_3),
        .weight_out(weight_v_2_3), .weight_valid_out(weight_valid_v_2_3),
        .accum_out(result_13), .result_valid(valid_13)
    );
    
    // Row 2
    processing_element pe_20 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_in_2), .data_valid_in(data_valid_2),
        .data_out(data_h_2_1), .data_valid_out(data_valid_h_2_1),
        .weight_in(weight_v_2_0), .weight_valid_in(weight_valid_v_2_0),
        .weight_out(weight_v_3_0), .weight_valid_out(weight_valid_v_3_0),
        .accum_out(result_20), .result_valid(valid_20)
    );
    
    processing_element pe_21 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_2_1), .data_valid_in(data_valid_h_2_1),
        .data_out(data_h_2_2), .data_valid_out(data_valid_h_2_2),
        .weight_in(weight_v_2_1), .weight_valid_in(weight_valid_v_2_1),
        .weight_out(weight_v_3_1), .weight_valid_out(weight_valid_v_3_1),
        .accum_out(result_21), .result_valid(valid_21)
    );
    
    processing_element pe_22 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_2_2), .data_valid_in(data_valid_h_2_2),
        .data_out(data_h_2_3), .data_valid_out(data_valid_h_2_3),
        .weight_in(weight_v_2_2), .weight_valid_in(weight_valid_v_2_2),
        .weight_out(weight_v_3_2), .weight_valid_out(weight_valid_v_3_2),
        .accum_out(result_22), .result_valid(valid_22)
    );
    
    processing_element pe_23 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_2_3), .data_valid_in(data_valid_h_2_3),
        .data_out(data_h_2_4), .data_valid_out(data_valid_h_2_4),
        .weight_in(weight_v_2_3), .weight_valid_in(weight_valid_v_2_3),
        .weight_out(weight_v_3_3), .weight_valid_out(weight_valid_v_3_3),
        .accum_out(result_23), .result_valid(valid_23)
    );
    
    // Row 3
    processing_element pe_30 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_in_3), .data_valid_in(data_valid_3),
        .data_out(data_h_3_1), .data_valid_out(data_valid_h_3_1),
        .weight_in(weight_v_3_0), .weight_valid_in(weight_valid_v_3_0),
        .weight_out(weight_v_4_0), .weight_valid_out(weight_valid_v_4_0),
        .accum_out(result_30), .result_valid(valid_30)
    );
    
    processing_element pe_31 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_3_1), .data_valid_in(data_valid_h_3_1),
        .data_out(data_h_3_2), .data_valid_out(data_valid_h_3_2),
        .weight_in(weight_v_3_1), .weight_valid_in(weight_valid_v_3_1),
        .weight_out(weight_v_4_1), .weight_valid_out(weight_valid_v_4_1),
        .accum_out(result_31), .result_valid(valid_31)
    );
    
    processing_element pe_32 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_3_2), .data_valid_in(data_valid_h_3_2),
        .data_out(data_h_3_3), .data_valid_out(data_valid_h_3_3),
        .weight_in(weight_v_3_2), .weight_valid_in(weight_valid_v_3_2),
        .weight_out(weight_v_4_2), .weight_valid_out(weight_valid_v_4_2),
        .accum_out(result_32), .result_valid(valid_32)
    );
    
    processing_element pe_33 (
        .clk(clk), .rst_n(rst_n), .enable(enable_pe), .clear_accum(clear_accum_pe),
        .data_in(data_h_3_3), .data_valid_in(data_valid_h_3_3),
        .data_out(data_h_3_4), .data_valid_out(data_valid_h_3_4),
        .weight_in(weight_v_3_3), .weight_valid_in(weight_valid_v_3_3),
        .weight_out(weight_v_4_3), .weight_valid_out(weight_valid_v_4_3),
        .accum_out(result_33), .result_valid(valid_33)
    );
    
    // ===========================================
    // Output Control
    // ===========================================
    assign computation_done = (current_state == DONE);
    assign result_valid = (current_state == DONE);

endmodule

// ===========================================
// Processing Element (Same as before)
// ===========================================
module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,
    
    input  [DATA_WIDTH-1:0]       data_in,
    input                         data_valid_in,
    output [DATA_WIDTH-1:0]       data_out,
    output                        data_valid_out,
    
    input  [WEIGHT_WIDTH-1:0]     weight_in,
    input                         weight_valid_in,
    output [WEIGHT_WIDTH-1:0]     weight_out,
    output                        weight_valid_out,
    
    output [ACCUM_WIDTH-1:0]      accum_out,
    output                        result_valid
);

    wire [DATA_WIDTH-1:0]      mac_data;
    wire [WEIGHT_WIDTH-1:0]    mac_weight;
    wire [ACCUM_WIDTH-1:0]     mac_accum;
    wire                       mac_valid;
    
    reg [DATA_WIDTH-1:0]       data_reg;
    reg                        data_valid_reg;
    reg [WEIGHT_WIDTH-1:0]     weight_reg;
    reg                        weight_valid_reg;
    
    // MAC unit gets valid data/weight only when both are valid
    assign mac_data = (data_valid_in && weight_valid_in) ? data_in : {DATA_WIDTH{1'b0}};
    assign mac_weight = (data_valid_in && weight_valid_in) ? weight_in : {WEIGHT_WIDTH{1'b0}};
    
    // Register data and weights for systolic flow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
            weight_reg <= {WEIGHT_WIDTH{1'b0}};
            weight_valid_reg <= 1'b0;
        end else if (enable) begin
            data_reg <= data_in;
            data_valid_reg <= data_valid_in;
            weight_reg <= weight_in;
            weight_valid_reg <= weight_valid_in;
        end else begin
            data_valid_reg <= 1'b0;
            weight_valid_reg <= 1'b0;
        end
    end
    
    // Output registered values for systolic flow
    assign data_out = data_reg;
    assign data_valid_out = data_valid_reg;
    assign weight_out = weight_reg;
    assign weight_valid_out = weight_valid_reg;
    
    // MAC unit instantiation
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && data_valid_in && weight_valid_in),
        .clear_accum(clear_accum),
        .data_in(mac_data),
        .weight_in(mac_weight),
        .accum_out(mac_accum),
        .valid_out(mac_valid)
    );
    
    assign accum_out = mac_accum;
    assign result_valid = mac_valid;

endmodule

// ===========================================
// MAC Unit (Same as before)
// ===========================================
module mac_unit_basic #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input                         clk,
    input                         rst_n,
    input                         enable,
    input                         clear_accum,
    
    input  [DATA_WIDTH-1:0]       data_in,
    input  [WEIGHT_WIDTH-1:0]     weight_in,
    
    output [ACCUM_WIDTH-1:0]      accum_out,
    output                        valid_out
);

    wire signed [DATA_WIDTH-1:0]      data_signed;
    wire signed [WEIGHT_WIDTH-1:0]    weight_signed;
    wire signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] mult_result;
    reg signed [ACCUM_WIDTH-1:0]      accum_reg;
    wire signed [ACCUM_WIDTH-1:0]     next_accum;
    reg                               valid_out_reg;
    
    // Convert to signed for arithmetic
    assign data_signed = $signed(data_in);
    assign weight_signed = $signed(weight_in);
    assign mult_result = data_signed * weight_signed;
    
    // Accumulator logic: clear or accumulate
    assign next_accum = clear_accum ? mult_result : (accum_reg + mult_result);
    
    // Accumulator register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= {ACCUM_WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end else if (enable) begin
            accum_reg <= next_accum;
            valid_out_reg <= 1'b1;
        end else begin
            valid_out_reg <= 1'b0;
        end
    end
    
    assign accum_out = accum_reg;
    assign valid_out = valid_out_reg;

endmodule
