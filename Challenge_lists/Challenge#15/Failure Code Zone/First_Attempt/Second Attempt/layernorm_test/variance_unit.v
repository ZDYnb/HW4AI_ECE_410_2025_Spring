// Variance Computing Unit with Time-Multiplexed PE Array
// Uses 8 PEs to compute variance of D_MODEL elements in 16 cycles

module variance_unit #(
    parameter D_MODEL = 128,
    parameter DATA_WIDTH = 24,
    parameter NUM_PE = 8,
    parameter INTERNAL_WIDTH = 48  // For squared values
) (
    input  wire clk,
    input  wire rst_n,
    
    // Input interface
    input  wire [(D_MODEL*DATA_WIDTH)-1:0] data_in_flat,  // Original data
    input  wire [DATA_WIDTH-1:0] mean_in,                 // From mean calculator
    input  wire start_variance,                           // Start signal
    
    // Output interface
    output reg  [DATA_WIDTH-1:0] variance_out,           // Final variance
    output reg  variance_valid,                          // Output valid
    
    // Status
    output wire busy                                     // Unit is busy
);

// ============================================================================
// Internal Signals
// ============================================================================

// Unpack input data
wire [DATA_WIDTH-1:0] data_in [D_MODEL-1:0];
genvar unpack_i;
generate
    for (unpack_i = 0; unpack_i < D_MODEL; unpack_i = unpack_i + 1) begin : unpack
        assign data_in[unpack_i] = data_in_flat[(unpack_i+1)*DATA_WIDTH-1 : unpack_i*DATA_WIDTH];
    end
endgenerate

// Control signals
reg [3:0] round_counter;        // 0-15, which round we're in
reg computing;                  // State flag
reg output_ready;               // Ready to output result
assign busy = computing;

// PE working arrays
reg signed [DATA_WIDTH-1:0] pe_data [NUM_PE-1:0];      // Current data for each PE
wire signed [DATA_WIDTH-1:0] pe_diff [NUM_PE-1:0];     // data - mean
wire [INTERNAL_WIDTH-1:0] pe_square [NUM_PE-1:0];      // squared differences

// Accumulator for variance
reg [INTERNAL_WIDTH+7:0] accumulator;   // Extra bits for accumulation

// ============================================================================
// Processing Element Array (8 parallel units)
// ============================================================================

genvar pe_i;
generate
    for (pe_i = 0; pe_i < NUM_PE; pe_i = pe_i + 1) begin : pe_array
        // Each PE computes (data - mean)^2
        assign pe_diff[pe_i] = pe_data[pe_i] - mean_in;
        assign pe_square[pe_i] = pe_diff[pe_i] * pe_diff[pe_i];
    end
endgenerate

// ============================================================================
// Main Control Logic
// ============================================================================

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers
        round_counter <= 4'd0;
        computing <= 1'b0;
        output_ready <= 1'b0;
        accumulator <= 0;
        variance_valid <= 1'b0;
        variance_out <= 0;
        
        for (i = 0; i < NUM_PE; i = i + 1) begin
            pe_data[i] <= 0;
        end
        
    end else begin
        // Clear valid by default
        variance_valid <= 1'b0;
        
        if (start_variance && !computing && !output_ready) begin
            // Start new variance computation
            computing <= 1'b1;
            round_counter <= 4'd0;
            accumulator <= 0;
            output_ready <= 1'b0;
            
            // Load first set of data (indices 0-7)
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pe_data[i] <= data_in[i];
            end
            
        end else if (computing) begin
            // Process current round
            if (round_counter == 0) begin
                // First round - initialize accumulator with first 8 squares
                accumulator <= pe_square[0] + pe_square[1] + pe_square[2] + pe_square[3] +
                              pe_square[4] + pe_square[5] + pe_square[6] + pe_square[7];
            end else begin
                // Subsequent rounds - add to accumulator
                accumulator <= accumulator + 
                              pe_square[0] + pe_square[1] + pe_square[2] + pe_square[3] +
                              pe_square[4] + pe_square[5] + pe_square[6] + pe_square[7];
            end
            
            if (round_counter == 15) begin
                // Last round - set flag to output next cycle
                computing <= 1'b0;
                output_ready <= 1'b1;
                round_counter <= 4'd0;
            end else begin
                // Move to next round
                round_counter <= round_counter + 1;
                
                // Load next set of data
                for (i = 0; i < NUM_PE; i = i + 1) begin
                    pe_data[i] <= data_in[(round_counter + 1) * NUM_PE + i];
                end
            end
            
        end else if (output_ready) begin
            // Output the result
            variance_out <= accumulator >> $clog2(D_MODEL);  // Divide by D_MODEL
            variance_valid <= 1'b1;
            output_ready <= 1'b0;
        end
    end
end

endmodule
