// ===========================================
// Systolic Array Top-Level Module
// Target: GEMM operations for GPT-2 ASIC
// Dataflow: Activations stream left-to-right,
//           Weights stream top-to-bottom.
//           PE results output directly for now.
// ===========================================
`timescale 1ns/1ps

module systolic_array #(
    parameter PE_ROWS = 4,                // Number of PE rows
    parameter PE_COLS = 4,                // Number of PE columns
    parameter DATA_WIDTH = 16,            // Activation width (e.g., S5.10)
    parameter WEIGHT_WIDTH = 8,           // Weight width (e.g., S1.6)
    parameter MAC_ACCUM_WIDTH = 24,       // Accumulator width for MAC and PE output (e.g., S7.16)
    parameter MAC_ACCUM_FRAC_BITS = 16    // Fractional bits in accumulator (for reference, not directly used by PE params)
) ( // Non-ANSI style: List all port names here
    clk,
    rst_n,
    global_clear_accum,
    activations_in_L,
    activations_valid_in_L,
    weights_in_T,
    weights_valid_in_T,
    results_out,
    results_valid_out,
    activations_out_R,
    activations_valid_out_R,
    weights_out_B,
    weights_valid_out_B
);

    // Port Declarations (Non-ANSI style, using direct SystemVerilog unpacked array syntax)
    input   logic                               clk;
    input   logic                               rst_n;
    input   logic                               global_clear_accum;

    // Activation inputs
    input   logic [DATA_WIDTH-1:0]              activations_in_L [PE_ROWS-1:0];
    input   logic                               activations_valid_in_L [PE_ROWS-1:0];

    // Weight inputs
    input   logic [WEIGHT_WIDTH-1:0]            weights_in_T [PE_COLS-1:0];
    input   logic                               weights_valid_in_T [PE_COLS-1:0];

    // Result outputs
    output  logic [MAC_ACCUM_WIDTH-1:0]         results_out [PE_ROWS-1:0][PE_COLS-1:0];
    output  logic                               results_valid_out [PE_ROWS-1:0][PE_COLS-1:0];

    // Propagated activations
    output  logic [DATA_WIDTH-1:0]              activations_out_R [PE_ROWS-1:0];
    output  logic                               activations_valid_out_R [PE_ROWS-1:0];

    // Propagated weights
    output  logic [WEIGHT_WIDTH-1:0]            weights_out_B [PE_COLS-1:0];
    output  logic                               weights_valid_out_B [PE_COLS-1:0];


    // Internal wires for connecting PEs
    // Note: Typedefs can still be used for internal signals if desired,
    // but are removed from port declarations for maximum clarity to the simulator.
    wire [DATA_WIDTH-1:0]   data_signals_out_R_internal [PE_ROWS-1:0][PE_COLS-1:0];
    wire                    data_valid_signals_out_R_internal [PE_ROWS-1:0][PE_COLS-1:0];

    wire [WEIGHT_WIDTH-1:0] weight_signals_out_B_internal [PE_ROWS-1:0][PE_COLS-1:0];
    wire                    weight_valid_signals_out_B_internal [PE_ROWS-1:0][PE_COLS-1:0];

    // Generate PE array
    genvar r, c;
    generate
        for (r = 0; r < PE_ROWS; r = r + 1) begin : row_generate_block
            for (c = 0; c < PE_COLS; c = c + 1) begin : col_generate_block
                
                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .WEIGHT_WIDTH(WEIGHT_WIDTH),
                    .ACCUM_WIDTH(MAC_ACCUM_WIDTH)
                ) pe_instance (
                    .clk(clk),
                    .rst_n(rst_n),
                    .global_clear_accum(global_clear_accum),

                    .data_in_L( (c == 0) ? activations_in_L[r] : data_signals_out_R_internal[r][c-1] ),
                    .data_valid_in_L( (c == 0) ? activations_valid_in_L[r] : data_valid_signals_out_R_internal[r][c-1] ),
                    
                    .data_out_R(data_signals_out_R_internal[r][c]),
                    .data_valid_out_R(data_valid_signals_out_R_internal[r][c]),

                    .weight_in_T( (r == 0) ? weights_in_T[c] : weight_signals_out_B_internal[r-1][c] ),
                    .weight_valid_in_T( (r == 0) ? weights_valid_in_T[c] : weight_valid_signals_out_B_internal[r-1][c] ),

                    .weight_out_B(weight_signals_out_B_internal[r][c]),
                    .weight_valid_out_B(weight_valid_signals_out_B_internal[r][c]),

                    .pe_accum_out(results_out[r][c]),
                    .pe_result_valid(results_valid_out[r][c])
                );
            end
        end
    endgenerate

    // Assign propagated outputs at array boundaries
    generate
        for (r = 0; r < PE_ROWS; r = r + 1) begin : assign_activations_out
            assign activations_out_R[r] = data_signals_out_R_internal[r][PE_COLS-1];
            assign activations_valid_out_R[r] = data_valid_signals_out_R_internal[r][PE_COLS-1];
        end
    endgenerate

    generate
        for (c = 0; c < PE_COLS; c = c + 1) begin : assign_weights_out
            assign weights_out_B[c] = weight_signals_out_B_internal[PE_ROWS-1][c];
            assign weights_valid_out_B[c] = weight_valid_signals_out_B_internal[PE_ROWS-1][c];
        end
    endgenerate

endmodule

