// ===========================================
// Processing Element - PE Unit (Final Revised for Systolic Array)
// ===========================================
`timescale 1ns/1ps

module processing_element #(
    parameter DATA_WIDTH = 16,      // Data width (S5.10)
    parameter WEIGHT_WIDTH = 8,     // Weight width (S1.6)
    parameter ACCUM_WIDTH = 32      // Accumulator width (e.g., S15.16)
)(
    input                           clk,
    input                           rst_n,
    
    // Global control for array initialization (can be pulsed and propagated)
    input                           global_clear_accum, 

    // Data flow: horizontal pass-through (data comes from left, goes to right)
    input  [DATA_WIDTH-1:0]         data_in_L,          // Data from Left
    input                           data_valid_in_L,    // Valid for data_in_L
    output [DATA_WIDTH-1:0]         data_out_R,         // Data to Right
    output                          data_valid_out_R,   // Valid for data_out_R
    
    // Weight flow: vertical pass-through (weight comes from top, goes to bottom)
    input  [WEIGHT_WIDTH-1:0]       weight_in_T,        // Weight from Top
    input                           weight_valid_in_T,  // Valid for weight_in_T
    output [WEIGHT_WIDTH-1:0]       weight_out_B,       // Weight to Bottom
    output                          weight_valid_out_B, // Valid for weight_out_B
    
    // Result output (accumulator value from internal MAC)
    output [ACCUM_WIDTH-1:0]        pe_accum_out,       // Accumulator value
    output                          pe_result_valid     // Indicates pe_accum_out is valid
);

    // ==========================================
    // Internal Signals for Data/Weight Propagation (Registered)
    // ==========================================
    reg  [DATA_WIDTH-1:0]           data_reg;
    reg                             data_valid_reg;
    reg  [WEIGHT_WIDTH-1:0]         weight_reg;
    reg                             weight_valid_reg;

    // ==========================================
    // Internal Signals for MAC Unit
    // ==========================================
    wire [ACCUM_WIDTH-1:0]          mac_accum_result;
    wire                            mac_accum_valid;
    
    // PE-local clear_accum: Registered version of global_clear_accum to propagate.
    reg                             pe_clear_accum_reg; 

    // ==========================================
    // Systolic Dataflow Registers
    // These registers ensure all inputs are delayed by one clock cycle
    // before being passed to the next PE in the array.
    // This is crucial for proper systolic wave propagation.
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg        <= {DATA_WIDTH{1'b0}};
            data_valid_reg  <= 1'b0;
            weight_reg      <= {WEIGHT_WIDTH{1'b0}};
            weight_valid_reg<= 1'b0;
            pe_clear_accum_reg <= 1'b0; // Reset local clear
        end else begin
            // Data flows horizontally (X-direction). Always registered.
            data_reg        <= data_in_L;
            data_valid_reg  <= data_valid_in_L;
            
            // Weight flows vertically (Y-direction). Always registered.
            weight_reg      <= weight_in_T;
            weight_valid_reg<= weight_valid_in_T;

            // Local clear_accum signal for MAC unit. Also registered to propagate.
            pe_clear_accum_reg <= global_clear_accum; 
            // In a full array, global_clear_accum might come from a previous PE,
            // e.g., pe_clear_accum_reg <= clear_accum_in_L; (if propagating horizontally)
            // Or a dedicated clear_in_T; (if propagating vertically)
            // For this single PE test, it takes directly from TB's global_clear_accum.
        end
    end
    
    // ==========================================
    // Output Dataflow (registered outputs)
    // These outputs will reflect data_in_L and weight_in_T from the PREVIOUS cycle.
    // ==========================================
    assign data_out_R       = data_reg;         // data_in_L is outputted one cycle later
    assign data_valid_out_R = data_valid_reg;   // valid for data_out_R is also delayed
    assign weight_out_B     = weight_reg;       // weight_in_T is outputted one cycle later
    assign weight_valid_out_B = weight_valid_reg; // valid for weight_out_B is also delayed

    // ==========================================
    // MAC Unit Instantiation
    // ==========================================
    // MAC unit processes the *current* data/weight and their valid signals.
    // MAC enable should ONLY be active when both *current* data and weight are valid.
    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        // MAC enable directly from current input valid signals.
        // This means MAC computes *when* data_in_L and weight_in_T are valid.
        .enable_mac(data_valid_in_L && weight_valid_in_T), 
        // Use the registered local clear signal.
        // This ensures clear_accum is synchronized with enable_mac due to propagation.
        .clear_accum(pe_clear_accum_reg), 
        // MAC uses current input data (not registered)
        .data_in(data_in_L), 
        // MAC uses current input weight (not registered)
        .weight_in(weight_in_T), 
        .accum_out(mac_accum_result),
        .accum_valid_out(mac_accum_valid)
    );
    
    // ==========================================
    // Result Output (from MAC unit)
    // ==========================================
    assign pe_accum_out = mac_accum_result;
    assign pe_result_valid = mac_accum_valid;

endmodule
