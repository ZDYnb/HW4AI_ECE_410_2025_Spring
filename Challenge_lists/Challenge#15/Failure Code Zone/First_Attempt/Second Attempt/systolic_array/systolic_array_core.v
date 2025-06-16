`timescale 1ns/1ps

module systolic_array_core #(
    parameter ARRAY_DIM    = 4,
    parameter DATA_WIDTH   = 16,
    parameter WEIGHT_WIDTH = 8,
    parameter ACCUM_WIDTH  = 24
)(
    input                               clk,
    input                               rst_n,
    input                               core_enable,
    input                               load_weights_en_array,

    // FLATTENED Port Declarations:
    input [ARRAY_DIM*ARRAY_DIM*WEIGHT_WIDTH-1:0] core_weights_in_flat,
    input [ARRAY_DIM*DATA_WIDTH-1:0]             core_activation_in_flat,
    input [ARRAY_DIM*ACCUM_WIDTH-1:0]            core_psum_in_flat,

    output [ARRAY_DIM*DATA_WIDTH-1:0]            core_activation_out_flat,
    output [ARRAY_DIM*ACCUM_WIDTH-1:0]           core_psum_out_flat,

    // This port was likely okay, as [N-1:0] name is a standard vector port.
    // If it also errors, it can be flattened too, but usually not necessary for single dimension after name.
    // For consistency with errors, let's assume it's a vector. If it errors, it needs to be output some_name [0:N-1].
    // No, the error indicates `output [ARRAY_DIM-1:0] core_data_out_valid` IS an array port.
    // The correct Verilog-2001 way for a multi-bit output is just `output [N-1:0] name;`
    // The previous fix for this was `output [ARRAY_DIM-1:0] core_data_out_valid;` which is a vector.
    // The error log didn't show an error for core_data_out_valid, so it was probably okay.
    // Let's keep it as a vector as it's standard.
    output [ARRAY_DIM-1:0]                       core_data_out_valid
);

    // --- Internal Reconstructed Arrays (from flattened inputs) ---
    wire [WEIGHT_WIDTH-1:0] internal_core_weights_in [0:ARRAY_DIM-1][0:ARRAY_DIM-1];
    wire [DATA_WIDTH-1:0]   internal_core_activation_in [0:ARRAY_DIM-1];
    wire [ACCUM_WIDTH-1:0]  internal_core_psum_in [0:ARRAY_DIM-1];

    // --- Internal Arrays (feeding flattened outputs) ---
    wire [DATA_WIDTH-1:0]   internal_core_activation_out [0:ARRAY_DIM-1];
    wire [ACCUM_WIDTH-1:0]  internal_core_psum_out [0:ARRAY_DIM-1];
    // internal_core_data_out_valid is directly connected to core_data_out_valid (vector)

    genvar r_idx, c_idx;

    // Unpack flattened inputs into internal 2D/1D arrays
    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin: unpack_weights_rows
        for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin: unpack_weights_cols
            localparam base_w = (r_idx * ARRAY_DIM + c_idx) * WEIGHT_WIDTH;
            assign internal_core_weights_in[r_idx][c_idx] = core_weights_in_flat[base_w + WEIGHT_WIDTH - 1 : base_w];
        end
    end

    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin: unpack_activations
        localparam base_a = r_idx * DATA_WIDTH;
        assign internal_core_activation_in[r_idx] = core_activation_in_flat[base_a + DATA_WIDTH - 1 : base_a];
    end

    for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin: unpack_psums_in
        localparam base_p_in = c_idx * ACCUM_WIDTH;
        assign internal_core_psum_in[c_idx] = core_psum_in_flat[base_p_in + ACCUM_WIDTH - 1 : base_p_in];
    end

    // Internal wires for connecting PEs (same as before, but now fed by internal_core_* arrays)
    wire [DATA_WIDTH-1:0]  activation_wires [0:ARRAY_DIM-1][0:ARRAY_DIM];
    wire [ACCUM_WIDTH-1:0] psum_wires       [0:ARRAY_DIM][0:ARRAY_DIM-1];
    wire pe_data_out_valid [0:ARRAY_DIM-1][0:ARRAY_DIM-1];    


    // Assign internal_core_activation_in to the input of the first column of PEs
    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin : connect_act_inputs_internal
        assign activation_wires[r_idx][0] = internal_core_activation_in[r_idx];
    end

    // Connect internal_core_psum_in to the input of the first row of PEs
    for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin : connect_psum_inputs_internal
        assign psum_wires[0][c_idx] = internal_core_psum_in[c_idx];
    end

    // Generate the 2D array of Processing Elements
    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin : gen_pe_rows
        for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin : gen_pe_cols
            
            processing_element #(
                .DATA_WIDTH(DATA_WIDTH),
                .WEIGHT_WIDTH(WEIGHT_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH)
            ) pe_inst (
                .clk(clk),
                .rst_n(rst_n),
                .pe_enable(core_enable),

                .activation_in(activation_wires[r_idx][c_idx]),
                .activation_out(activation_wires[r_idx][c_idx+1]),

                .weight_to_load(internal_core_weights_in[r_idx][c_idx]), 
                .load_weight_en(load_weights_en_array),

                .psum_in(psum_wires[r_idx][c_idx]),
                .psum_out(psum_wires[r_idx+1][c_idx]),          
                
                .data_out_valid(pe_data_out_valid[r_idx][c_idx])
            );
        end
    end

    // Connect outputs of the array to internal_core_out arrays
    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin : connect_act_outputs_internal
        assign internal_core_activation_out[r_idx] = activation_wires[r_idx][ARRAY_DIM];
    end

    for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin : connect_psum_outputs_internal
        assign internal_core_psum_out[c_idx] = psum_wires[ARRAY_DIM][c_idx];
        // core_data_out_valid is a vector [ARRAY_DIM-1:0]
        // Assign from the last row of PEs' valid signals
        assign core_data_out_valid[c_idx] = pe_data_out_valid[ARRAY_DIM-1][c_idx];
    end

    // Pack internal output arrays into flattened output ports
    for (r_idx = 0; r_idx < ARRAY_DIM; r_idx = r_idx + 1) begin: pack_activations_out
        localparam base_a_out = r_idx * DATA_WIDTH;
        assign core_activation_out_flat[base_a_out + DATA_WIDTH - 1 : base_a_out] = internal_core_activation_out[r_idx];
    end

    for (c_idx = 0; c_idx < ARRAY_DIM; c_idx = c_idx + 1) begin: pack_psums_out
        localparam base_p_out = c_idx * ACCUM_WIDTH;
        assign core_psum_out_flat[base_p_out + ACCUM_WIDTH - 1 : base_p_out] = internal_core_psum_out[c_idx];
    end

endmodule
