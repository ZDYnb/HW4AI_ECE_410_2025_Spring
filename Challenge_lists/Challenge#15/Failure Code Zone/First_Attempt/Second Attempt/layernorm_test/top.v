//`timescale 1ns / 1ps

//******************************************************************************
// Module: top
// Description:
//   - This is the top-level wrapper that instantiates and connects the
//     streaming_controller and the user's layer_norm_top core.
//******************************************************************************
module top (
    input  wire                          clk,
    input  wire                          rst_n,
    // Control
    input  wire                          start_processing,
    output wire                          processing_done,
    // SPI Data Input
    input  wire                          spi_word_valid,
    input  wire [15:0]                   spi_word_in,
    output wire                          in_ready
);

    // -- Parameters --
    localparam D_MODEL    = 64;
    localparam DATA_WIDTH = 16;

    // -- Wires for Interconnection --
    wire                            ln_start_in_wire;
    wire [(D_MODEL*DATA_WIDTH)-1:0] ln_x_in_wire;
    wire                            ln_done_out_wire;
    wire [(D_MODEL*DATA_WIDTH)-1:0] ln_y_out_wire;
    wire [(D_MODEL*DATA_WIDTH)-1:0] result_out_wire;
    wire                            result_valid_wire;

    // 1. Instantiate the Controller
    streaming_controller #(
        .D_MODEL(D_MODEL),
        .DATA_WIDTH(DATA_WIDTH)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_processing(start_processing),
        .processing_done(processing_done),
        .spi_word_valid(spi_word_valid),
        .spi_word_in(spi_word_in),
        .in_ready(in_ready),
        .ln_start_in(ln_start_in_wire),
        .ln_x_in(ln_x_in_wire),
        .ln_done_out(ln_done_out_wire),
        .ln_y_out(ln_y_out_wire),
        .result_out(result_out_wire),
        .result_valid(result_valid_wire)
    );

    // 2. Instantiate your LayerNorm Core
    layer_norm_top #(
        .D_MODEL(D_MODEL),
        .X_WIDTH(DATA_WIDTH)
        // You MUST add all other necessary parameters for your core here.
        // e.g., .X_FRAC(10), .Y_WIDTH(16), etc.
    ) layernorm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_in(ln_start_in_wire),
        .x_vector_flat_in(ln_x_in_wire),
        // For this test, we tie gamma and beta to default values.
        // In a real design, these would come from a memory or another module.
        .gamma_vector_flat_in('1), // Tie to all 1s for scaling
        .beta_vector_flat_in(0),   // Tie to all 0s for no shift
        .y_vector_flat_out(ln_y_out_wire),
        .done_valid_out(ln_done_out_wire)
        // Connect other debug ports if you want to observe them
    );

endmodule

