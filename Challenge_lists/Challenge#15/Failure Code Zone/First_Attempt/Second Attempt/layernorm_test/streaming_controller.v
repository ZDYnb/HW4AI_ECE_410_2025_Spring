//`timescale 1ns / 1ps

//******************************************************************************
// Module: streaming_controller
// Description:
//   - Implements a streaming architecture using a Ping-Pong Buffer.
//   - Receives data column-by-column via a simple word-based interface.
//   - Processes data using the layer_norm_top core concurrently.
//   - Decouples receiving and processing for maximum throughput.
//******************************************************************************
module streaming_controller #(
    parameter D_MODEL    = 64,
    parameter DATA_WIDTH = 16
) (
    // -- Global Signals --
    input  wire                          clk,
    input  wire                          rst_n,

    // -- Control Signals --
    input  wire                          start_processing, // Starts the processing part
    output reg                           processing_done,  // All 64 columns are processed

    // -- Input Stream Interface (from an SPI Slave module) --
    input  wire                          spi_word_valid,   // A new 16-bit word is ready
    input  wire [DATA_WIDTH-1:0]         spi_word_in,      // The 16-bit data word
    output reg                           in_ready,         // Flow control: "I'm ready for the next word"

    // -- LayerNorm Core Interface --
    output reg                           ln_start_in,
    output reg  [(D_MODEL*DATA_WIDTH)-1:0] ln_x_in,
    input  wire                          ln_done_out,
    input  wire [(D_MODEL*DATA_WIDTH)-1:0] ln_y_out,
    
    // -- Output Stream Interface --
    output reg [(D_MODEL*DATA_WIDTH)-1:0] result_out,
    output reg                           result_valid
);

    // 1. Ping-Pong Buffers and State Variables
    reg [DATA_WIDTH-1:0] buffer_A [0:D_MODEL-1];
    reg [DATA_WIDTH-1:0] buffer_B [0:D_MODEL-1];
    reg buffer_A_is_full;
    reg buffer_B_is_full;
    reg spi_writes_to_A;
    reg proc_reads_from_A;
    reg [5:0] spi_word_cnt;
    reg [5:0] processed_col_cnt;

    localparam S_IDLE              = 3'h0;
    localparam S_WAIT_FOR_BUFFER   = 3'h1;
    localparam S_START_LN          = 3'h2;
    localparam S_WAIT_LN           = 3'h3;
    localparam S_FINISH_PROC       = 3'h4;
    localparam S_DONE              = 3'h5;
    
    reg [2:0] proc_state, proc_next_state;

    integer i;

    // 2. Receiver Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_writes_to_A <= 1'b1;
            spi_word_cnt    <= 0;
            buffer_A_is_full <= 1'b0;
            buffer_B_is_full <= 1'b0;
        end else begin
            if (spi_word_valid && in_ready) begin
                if (spi_writes_to_A) begin
                    buffer_A[spi_word_cnt] <= spi_word_in;
                end else begin
                    buffer_B[spi_word_cnt] <= spi_word_in;
                end
                if (spi_word_cnt == D_MODEL - 1) begin
                    spi_word_cnt <= 0;
                    if (spi_writes_to_A) buffer_A_is_full <= 1'b1;
                    else                 buffer_B_is_full <= 1'b1;
                    spi_writes_to_A <= ~spi_writes_to_A;
                end else begin
                    spi_word_cnt <= spi_word_cnt + 1;
                end
            end
        end
    end

    always @(*) begin
        if (spi_writes_to_A) in_ready = ~buffer_A_is_full;
        else                 in_ready = ~buffer_B_is_full;
    end

    // 3. Processing Logic FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            proc_state        <= S_IDLE;
            proc_reads_from_A <= 1'b1;
            processed_col_cnt <= 0;
            result_valid      <= 1'b0;
        end else begin
            proc_state <= proc_next_state;
            
            if (result_valid) result_valid <= 1'b0;

            if (proc_state == S_FINISH_PROC) begin
                proc_reads_from_A <= ~proc_reads_from_A;
                if (processed_col_cnt == D_MODEL - 1) begin
                    processed_col_cnt <= 0; // Reset for next run
                end else begin
                    processed_col_cnt <= processed_col_cnt + 1;
                end
                result_valid <= 1'b1;
                if (proc_reads_from_A) buffer_A_is_full <= 1'b0;
                else                   buffer_B_is_full <= 1'b0;
            end
        end
    end

    always @(*) begin
        proc_next_state = proc_state;
        ln_start_in     = 1'b0;
        ln_x_in         = 0;
        result_out      = 0;
        processing_done = 1'b0;

        case (proc_state)
            S_IDLE: if (start_processing) proc_next_state = S_WAIT_FOR_BUFFER;
            S_WAIT_FOR_BUFFER: begin
                if (proc_reads_from_A ? buffer_A_is_full : buffer_B_is_full) begin
                    proc_next_state = S_START_LN;
                end
            end
            S_START_LN: begin
                if (proc_reads_from_A) begin
                    for (i = 0; i < D_MODEL; i = i + 1) ln_x_in[(i*DATA_WIDTH)+:DATA_WIDTH] = buffer_A[i];
                end else begin
                    for (i = 0; i < D_MODEL; i = i + 1) ln_x_in[(i*DATA_WIDTH)+:DATA_WIDTH] = buffer_B[i];
                end
                ln_start_in = 1'b1;
                proc_next_state = S_WAIT_LN;
            end
            S_WAIT_LN: if (ln_done_out) proc_next_state = S_FINISH_PROC;
            S_FINISH_PROC: begin
                result_out = ln_y_out;
                if (processed_col_cnt == D_MODEL - 1) proc_next_state = S_DONE;
                else                                  proc_next_state = S_WAIT_FOR_BUFFER;
            end
            S_DONE: begin
                processing_done = 1'b1;
                proc_next_state = S_IDLE;
            end
            default: proc_next_state = S_IDLE;
        endcase
    end
endmodule
