`timescale 1ns/1ps

// ===========================================
// Processing Element for Weight-Stationary Systolic Array
// (Corrected psum pipeline alignment)
// ===========================================
module processing_element #(
    parameter DATA_WIDTH = 16,     // Activation width
    parameter WEIGHT_WIDTH = 8,    // Weight width
    parameter ACCUM_WIDTH = 24     // Partial sum / Accumulator width for MAC output
)(
    input                            clk,
    input                            rst_n,
    input                            pe_enable,         // Enables PE's clocked operations

    // Activation path (e.g., flows left to right)
    input      [DATA_WIDTH-1:0]      activation_in,
    output reg [DATA_WIDTH-1:0]      activation_out,    // Pipelined activation_in

    // Weight loading path (for the stationary weight)
    input      [WEIGHT_WIDTH-1:0]    weight_to_load,    // Weight value to be loaded
    input                            load_weight_en,    // Enable signal to load/update the PE's weight

    // Partial sum path (e.g., flows top to bottom)
    input      [ACCUM_WIDTH-1:0]     psum_in,           // Partial sum from PE above/previous stage
    output reg [ACCUM_WIDTH-1:0]     psum_out,          // Output partial sum to PE below/next stage
    
    output reg                       data_out_valid     // Indicates valid activation_out and psum_out
);

    // Internal register for the stationary weight
    reg [WEIGHT_WIDTH-1:0] stored_weight_reg;

    // Pipeline stage 1 registers (input latches)
    reg [DATA_WIDTH-1:0]   activation_s1_reg; // Holds activation_in for one cycle, feeds MAC
    reg [ACCUM_WIDTH-1:0]  psum_in_s1_reg;    // Holds psum_in for one cycle

    // Pipeline stage 2 register for psum path, to align with MAC product availability
    reg [ACCUM_WIDTH-1:0]  psum_in_s2_reg;    // Further pipelines psum_in_s1_reg

    // Output of the MAC unit (product of activation_s1_reg and stored_weight_reg)
    wire [ACCUM_WIDTH-1:0] mac_product_output; 
    wire                   mac_product_valid;

    // Instantiate the MAC unit
    mac_unit_basic #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(pe_enable),
        .clear_accum(1'b1),             // Makes MAC output product only
        .data_in(activation_s1_reg),
        .weight_in(stored_weight_reg),
        .accum_out(mac_product_output),
        .valid_out(mac_product_valid)
    );

    // Stage 1 & 2 Pipeline for inputs and intermediate psum:
    // Latches inputs and passes psum_in through an extra register stage (s2).
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activation_s1_reg <= {DATA_WIDTH{1'b0}};
            psum_in_s1_reg    <= {ACCUM_WIDTH{1'b0}};
            psum_in_s2_reg    <= {ACCUM_WIDTH{1'b0}};
            stored_weight_reg <= {WEIGHT_WIDTH{1'b0}}; 
        end else if (pe_enable) begin
            // Stage 1 input latching
            activation_s1_reg <= activation_in;
            psum_in_s1_reg    <= psum_in;
            
            // Stage 2 for psum path (delaying psum_in_s1_reg by one more cycle)
            psum_in_s2_reg    <= psum_in_s1_reg;

            if (load_weight_en) begin
                stored_weight_reg <= weight_to_load;
            end
        end
        // If not pe_enable, registers hold their values.
    end

    // Stage 2/3 Pipeline for Outputs:
    // Computes sum and registers final PE outputs.
    // activation_out is based on activation_s1_reg (1-cycle latency from input port).
    // psum_out is based on psum_in_s2_reg and mac_product_output.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activation_out <= {DATA_WIDTH{1'b0}};
            psum_out       <= {ACCUM_WIDTH{1'b0}};
            data_out_valid <= 1'b0;
        end else if (pe_enable) begin
            // activation_out gets the value that was latched into activation_s1_reg in the PREVIOUS cycle.
            // So, activation_out(T+1) = activation_s1_reg(at T+1) = activation_in(at T).
            // This means activation_out has a 1-cycle latency from activation_in port.
            activation_out <= activation_s1_reg; 
                                        
            // psum_out calculation:
            // mac_product_output is available at T+1 (based on activation_s1_reg at T+1, which is activation_in at T).
            // psum_in_s2_reg is available at T+1 (based on psum_in_s1_reg at T+1, which is psum_in at T).
            // So, at T+1, the inputs to the adder are aligned with values derived from inputs at T.
            // The result is registered in psum_out.
            // So, psum_out(T+2) = psum_in(T) + (activation_in(T) * W_stored).
            // This is a 2-cycle latency for psum_out from the input ports.
            psum_out <= psum_in_s2_reg + mac_product_output;

            data_out_valid <= mac_product_valid; 
        end else begin 
            data_out_valid <= 1'b0;
        end
    end

endmodule
