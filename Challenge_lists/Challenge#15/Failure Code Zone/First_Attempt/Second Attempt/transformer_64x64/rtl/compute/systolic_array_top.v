// ===========================================
// Systolic Array Top Module - Fixed Point Support
// Completely rewritten for S5.10 compatibility
// ===========================================
`timescale 1ns/1ps
module systolic_array_top #(
    parameter ARRAY_SIZE = 64,
    
    // Fixed point format parameters
    parameter DATA_WIDTH = 16,      // S5.10 format
    parameter DATA_FRAC = 10,       // Fractional bits in data
    parameter WEIGHT_WIDTH = 8,     // S1.6 format  
    parameter WEIGHT_FRAC = 6,      // Fractional bits in weight
    parameter ACCUM_WIDTH = 32,     // S15.16 format (internal)
    parameter ACCUM_FRAC = 16       // Fractional bits in accumulator
)(
    input clk,
    input rst_n,
    input start,
    
    // Flattened matrix inputs (S5.10 and S1.6 formats)
    input [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_a_flat,
    input [WEIGHT_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] matrix_b_flat,
    
    // Control outputs
    output reg done,
    output reg result_valid,
    
    // Flattened result output (S5.10 format)
    output [DATA_WIDTH*ARRAY_SIZE*ARRAY_SIZE-1:0] result_flat
);

// ===========================================
// Internal Signals
// ===========================================
// 2D arrays for easier indexing
reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
reg signed [WEIGHT_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

// PE internal results (S15.16 format)
wire signed [ACCUM_WIDTH-1:0] pe_results [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

// Control signals
reg computing;
reg [7:0] compute_counter;
reg [7:0] input_cycle;

// PE interconnection signals
wire signed [DATA_WIDTH-1:0] data_horizontal [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
wire signed [WEIGHT_WIDTH-1:0] weight_vertical [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
wire data_valid_horizontal [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
wire weight_valid_vertical [0:ARRAY_SIZE][0:ARRAY_SIZE-1];

// ===========================================
// Input Matrix Unflattening
// ===========================================
genvar input_i, input_j;
generate
    for (input_i = 0; input_i < ARRAY_SIZE; input_i = input_i + 1) begin: INPUT_ROW
        for (input_j = 0; input_j < ARRAY_SIZE; input_j = input_j + 1) begin: INPUT_COL
            always @(*) begin
                matrix_a[input_i][input_j] = matrix_a_flat[(input_i*ARRAY_SIZE+input_j)*DATA_WIDTH +: DATA_WIDTH];
                matrix_b[input_i][input_j] = matrix_b_flat[(input_i*ARRAY_SIZE+input_j)*WEIGHT_WIDTH +: WEIGHT_WIDTH];
            end
        end
    end
endgenerate

// ===========================================
// PE Array Generation
// ===========================================
genvar pe_i, pe_j;
generate
    for (pe_i = 0; pe_i < ARRAY_SIZE; pe_i = pe_i + 1) begin: PE_ROW
        for (pe_j = 0; pe_j < ARRAY_SIZE; pe_j = pe_j + 1) begin: PE_COL
            processing_element #(
                .DATA_WIDTH(DATA_WIDTH),
                .WEIGHT_WIDTH(WEIGHT_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH)
            ) pe_inst (
                .clk(clk),
                .rst_n(rst_n),
                
                // Data inputs (horizontal flow) - S5.10
                .data_in(data_horizontal[pe_i][pe_j]),
                .data_valid(data_valid_horizontal[pe_i][pe_j]),
                
                // Weight inputs (vertical flow) - S1.6
                .weight_in(weight_vertical[pe_i][pe_j]),
                .weight_valid(weight_valid_vertical[pe_i][pe_j]),
                
                // Control
                .accumulate_en(computing),
                
                // Data outputs (to next PE) - S5.10
                .data_out(data_horizontal[pe_i][pe_j+1]),
                .data_valid_out(data_valid_horizontal[pe_i][pe_j+1]),
                
                // Weight outputs (to next PE) - S1.6
                .weight_out(weight_vertical[pe_i+1][pe_j]),
                .weight_valid_out(weight_valid_vertical[pe_i+1][pe_j]),
                
                // Result - S15.16 (full precision)
                .result(pe_results[pe_i][pe_j])
            );
        end
    end
endgenerate

// ===========================================
// Data Input Scheduling (Systolic Flow)
// ===========================================
genvar sched_i, sched_j;
generate
    for (sched_i = 0; sched_i < ARRAY_SIZE; sched_i = sched_i + 1) begin: SCHED_ROW
        // Horizontal data injection (left edge) - S5.10
        assign data_horizontal[sched_i][0] = (computing && input_cycle >= sched_i && input_cycle < (sched_i + ARRAY_SIZE)) ? 
                                           matrix_a[sched_i][input_cycle - sched_i] : {DATA_WIDTH{1'b0}};
        assign data_valid_horizontal[sched_i][0] = computing && input_cycle >= sched_i && input_cycle < (sched_i + ARRAY_SIZE);
        
        for (sched_j = 0; sched_j < ARRAY_SIZE; sched_j = sched_j + 1) begin: SCHED_COL
            // Vertical weight injection (top edge) - S1.6
            assign weight_vertical[0][sched_j] = (computing && input_cycle >= sched_j && input_cycle < (sched_j + ARRAY_SIZE)) ? 
                                               matrix_b[input_cycle - sched_j][sched_j] : {WEIGHT_WIDTH{1'b0}};
            assign weight_valid_vertical[0][sched_j] = computing && input_cycle >= sched_j && input_cycle < (sched_j + ARRAY_SIZE);
        end
    end
endgenerate

// ===========================================
// Format Conversion: S15.16 ¿ S5.10
// ===========================================
genvar out_i, out_j;
generate
    for (out_i = 0; out_i < ARRAY_SIZE; out_i = out_i + 1) begin: OUTPUT_ROW
        for (out_j = 0; out_j < ARRAY_SIZE; out_j = out_j + 1) begin: OUTPUT_COL
            // Convert each PE result from S15.16 to S5.10
            wire signed [ACCUM_WIDTH-1:0] pe_result_internal;
            wire signed [DATA_WIDTH-1:0] result_s5_10;
            
            // Get PE result
            assign pe_result_internal = pe_results[out_i][out_j];
            
            // Convert: right shift by 6 bits (16-10=6) with rounding
            assign result_s5_10 = (pe_result_internal >>> 6) + pe_result_internal[5];
            
            // Connect to output
            assign result_flat[(out_i*ARRAY_SIZE+out_j)*DATA_WIDTH +: DATA_WIDTH] = result_s5_10;
        end
    end
endgenerate

// ===========================================
// Control FSM
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        computing <= 1'b0;
        compute_counter <= 8'd0;
        done <= 1'b0;
        result_valid <= 1'b0;
    end else begin
        if (start && !computing) begin
            computing <= 1'b1;
            compute_counter <= 8'd0;
            done <= 1'b0;
            result_valid <= 1'b0;
        end else if (computing) begin
            compute_counter <= compute_counter + 1;
            // Complete after sufficient cycles for all PEs to finish
            if (compute_counter >= (2 * ARRAY_SIZE + ARRAY_SIZE - 1)) begin
                computing <= 1'b0;
                done <= 1'b1;
                result_valid <= 1'b1;
            end
        end else begin
            done <= 1'b0;
        end
    end
end

// ===========================================
// Input Cycle Counter
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_cycle <= 8'd0;
    end else if (computing) begin
        input_cycle <= input_cycle + 1;
    end else begin
        input_cycle <= 8'd0;
    end
end

endmodule

