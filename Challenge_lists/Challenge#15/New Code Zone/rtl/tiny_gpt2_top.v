module tiny_gpt2_top (
    input clk,
    input rst_n,
    
    // Control interface
    input start,
    output reg done,
    
    // Input: 16 tokens (4-bit each for vocab size 16)
    input [3:0] input_tokens_0, input_tokens_1, input_tokens_2, input_tokens_3,
    input [3:0] input_tokens_4, input_tokens_5, input_tokens_6, input_tokens_7,
    input [3:0] input_tokens_8, input_tokens_9, input_tokens_10, input_tokens_11,
    input [3:0] input_tokens_12, input_tokens_13, input_tokens_14, input_tokens_15,
    
    // Output: 16x16 probability matrix (simplified to first 16 elements for now)
    output reg [15:0] output_prob_0, output_prob_1, output_prob_2, output_prob_3,
    output reg [15:0] output_prob_4, output_prob_5, output_prob_6, output_prob_7,
    output reg [15:0] output_prob_8, output_prob_9, output_prob_10, output_prob_11,
    output reg [15:0] output_prob_12, output_prob_13, output_prob_14, output_prob_15
);

// ================================================================
// SEPARATED WIRE ARCHITECTURE - NO MORE SHARED OUTPUT BUS!
// ================================================================
reg [15:0] bus_matrix_a [0:255];    // Input matrix A (can be shared - only one writer)
reg [15:0] bus_matrix_b [0:255];    // Input matrix B (can be shared - only one writer)

// SEPARATED OUTPUT WIRES - This fixes the race condition!
wire [15:0] mult_matrix_c [0:255];   // Matrix multiplication result
wire [15:0] ln_matrix_c [0:255];     // Layer normalization result  
wire [15:0] sm_matrix_c [0:255];     // Softmax result
wire [15:0] gelu_matrix_c [0:255];   // GELU result

// Bus control signals
reg mult_start, layernorm_start, softmax_start, gelu_start;
wire mult_done, layernorm_done, softmax_done, gelu_done;

integer i, j;

// ================================================================
// WEIGHT STORAGE
// ================================================================
// Single block RAM for all weights (ASIC-friendly)
reg [15:0] weight_ram [0:1791];

// ASIC initialization - use $readmemh for synthesis
initial begin
    $readmemh("tiny_gpt2_weights.hex", weight_ram);
end

// Direct wire mapping (combinational, fast access)
wire [15:0] w_q [0:255];
wire [15:0] w_k [0:255]; 
wire [15:0] w_v [0:255];
wire [15:0] w_ff1 [0:255];
wire [15:0] w_ff2 [0:255];
wire [15:0] w_out [0:255];
wire [15:0] embedding [0:255];

// Map RAM to weight matrices (combinational)
genvar g;
generate
    for (g = 0; g < 256; g = g + 1) begin : weight_mapping
        assign w_q[g] = weight_ram[g];              // 0-255
        assign w_k[g] = weight_ram[256 + g];        // 256-511
        assign w_v[g] = weight_ram[512 + g];        // 512-767
        assign w_ff1[g] = weight_ram[768 + g];      // 768-1023
        assign w_ff2[g] = weight_ram[1024 + g];     // 1024-1279
        assign w_out[g] = weight_ram[1280 + g];     // 1280-1535
        assign embedding[g] = weight_ram[1536 + g]; // 1536-1791
    end
endgenerate

// ================================================================
// INTERMEDIATE STORAGE
// ================================================================
reg [15:0] input_matrix [0:255];     // Embedded input (needed for residual)
reg [15:0] k_matrix [0:255];         // K matrix (needed for attention scores)
reg [15:0] v_matrix [0:255];         // V matrix (needed for attention output)
reg [15:0] ln_input_output [0:255];  // Input layer norm output (for Q/K/V)
reg [15:0] ln1_output [0:255];       // Layer norm 1 output (needed for residual)
reg [15:0] working_matrix [0:255];   // Reused for Q, scores, weights, etc.

// Helper to convert input tokens to array indices
reg [3:0] input_tokens [0:15];
always @(*) begin
    input_tokens[0] = input_tokens_0;
    input_tokens[1] = input_tokens_1;
    input_tokens[2] = input_tokens_2;
    input_tokens[3] = input_tokens_3;
    input_tokens[4] = input_tokens_4;
    input_tokens[5] = input_tokens_5;
    input_tokens[6] = input_tokens_6;
    input_tokens[7] = input_tokens_7;
    input_tokens[8] = input_tokens_8;
    input_tokens[9] = input_tokens_9;
    input_tokens[10] = input_tokens_10;
    input_tokens[11] = input_tokens_11;
    input_tokens[12] = input_tokens_12;
    input_tokens[13] = input_tokens_13;
    input_tokens[14] = input_tokens_14;
    input_tokens[15] = input_tokens_15;
end

// ================================================================
// MODULE INSTANTIATIONS (FIXED - Separated Output Wires)
// ================================================================

// Matrix multiplication unit
matrix_mult_16x16 mult_unit (
    .clk(clk),
    .rst_n(rst_n),
    .start(mult_start),
    .done(mult_done),
    .matrix_a(bus_matrix_a),
    .matrix_b(bus_matrix_b),
    .matrix_c(mult_matrix_c)        // ← Separated wire!
);

// Layer normalization unit
layernorm_matrix_processor ln_unit (
    .clk(clk),
    .rst_n(rst_n),
    .start(layernorm_start),
    .done(layernorm_done),
    .matrix_i(bus_matrix_a),
    .matrix_o(ln_matrix_c)          // ← Separated wire!
);

// Softmax unit
softmax_matrix_processor sm_unit (
    .clk(clk),
    .rst_n(rst_n),
    .start(softmax_start),
    .done(softmax_done),
    .matrix_i(bus_matrix_a),
    .matrix_o(sm_matrix_c)          // ← Separated wire!
);

// GELU activation unit
gelu_matrix_processor gelu_unit (
    .clk(clk),
    .rst_n(rst_n),
    .start(gelu_start),
    .done(gelu_done),
    .matrix_i(bus_matrix_a),
    .matrix_o(gelu_matrix_c)        // ← Separated wire!
);

// ================================================================
// FSM STATE MACHINE
// ================================================================

// State encoding (pure Verilog style)
localparam IDLE = 5'd0;
localparam EMBEDDING = 5'd1;
localparam LAYERNORM_INPUT = 5'd2;
localparam SAVE_LN_INPUT = 5'd3;
localparam COMPUTE_Q = 5'd4;
localparam SAVE_Q = 5'd5;
localparam COMPUTE_K = 5'd6;
localparam SAVE_K = 5'd7;
localparam COMPUTE_V = 5'd8;
localparam SAVE_V = 5'd9;
localparam COMPUTE_SCORES = 5'd10;
localparam SOFTMAX_SCORES = 5'd11;
localparam COMPUTE_ATTN = 5'd12;
localparam ADD_RESIDUAL_1 = 5'd13;
localparam LAYERNORM_1 = 5'd14;
localparam SAVE_LN1 = 5'd15;
localparam COMPUTE_FF1 = 5'd16;
localparam GELU_FF1 = 5'd17;
localparam COMPUTE_FF2 = 5'd18;
localparam ADD_RESIDUAL_2 = 5'd19;
localparam LAYERNORM_2 = 5'd20;
localparam COMPUTE_OUTPUT = 5'd21;
localparam SOFTMAX_OUTPUT = 5'd22;
localparam DONE_STATE = 5'd23;

reg [4:0] current_state, next_state;

// ================================================================
// STATE MACHINE LOGIC (FIXED - Removed duplicate EMBEDDING)
// ================================================================

// Sequential state update
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always @(*) begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (start) next_state = EMBEDDING;
        end
        
        EMBEDDING: begin
            next_state = LAYERNORM_INPUT;
        end
        
        // REMOVED DUPLICATE EMBEDDING STATE
        
        LAYERNORM_INPUT: begin
            if (layernorm_done) next_state = SAVE_LN_INPUT;
        end
        
        SAVE_LN_INPUT: begin
            next_state = COMPUTE_Q;
        end
        
        COMPUTE_Q: begin
            if (mult_done) next_state = SAVE_Q;
        end
        
        SAVE_Q: begin
            next_state = COMPUTE_K;
        end
        
        COMPUTE_K: begin
            if (mult_done) next_state = SAVE_K;
        end
        
        SAVE_K: begin
            next_state = COMPUTE_V;
        end
        
        COMPUTE_V: begin
            if (mult_done) next_state = SAVE_V;
        end
        
        SAVE_V: begin
            next_state = COMPUTE_SCORES;
        end
        
        COMPUTE_SCORES: begin
            if (mult_done) next_state = SOFTMAX_SCORES;
        end
        
        SOFTMAX_SCORES: begin
            if (softmax_done) next_state = COMPUTE_ATTN;
        end
        
        COMPUTE_ATTN: begin
            if (mult_done) next_state = ADD_RESIDUAL_1;
        end
        
        ADD_RESIDUAL_1: begin
            next_state = LAYERNORM_1;
        end
        
        LAYERNORM_1: begin
            if (layernorm_done) next_state = SAVE_LN1;
        end
        
        SAVE_LN1: begin
            next_state = COMPUTE_FF1;
        end
        
        COMPUTE_FF1: begin
            if (mult_done) next_state = GELU_FF1;
        end
        
        GELU_FF1: begin
            if (gelu_done) next_state = COMPUTE_FF2;
        end
        
        COMPUTE_FF2: begin
            if (mult_done) next_state = ADD_RESIDUAL_2;
        end
        
        ADD_RESIDUAL_2: begin
            next_state = LAYERNORM_2;
        end
        
        LAYERNORM_2: begin
            if (layernorm_done) next_state = COMPUTE_OUTPUT;
        end
        
        COMPUTE_OUTPUT: begin
            if (mult_done) next_state = SOFTMAX_OUTPUT;
        end
        
        SOFTMAX_OUTPUT: begin
            if (softmax_done) next_state = DONE_STATE;
        end
        
        DONE_STATE: begin
            next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

// ================================================================
// DATA PATH CONTROL (FIXED - Use Correct Output Wires)
// ================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 1'b0;
        mult_start <= 1'b0;
        layernorm_start <= 1'b0;
        softmax_start <= 1'b0;
        gelu_start <= 1'b0;
    end else begin
        // Default: all control signals inactive
        mult_start <= 1'b0;
        layernorm_start <= 1'b0;
        softmax_start <= 1'b0;
        gelu_start <= 1'b0;
        done <= 1'b0;
        
        case (current_state)
            IDLE: begin
                done <= 1'b0;
            end
            
            EMBEDDING: begin
                // Convert 4-bit token IDs to Q5.10 embeddings
                for (i = 0; i < 16; i = i + 1) begin
                    for (j = 0; j < 16; j = j + 1) begin
                        input_matrix[i*16 + j] <= embedding[input_tokens[i]*16 + j];
                    end
                end
            end
            
            LAYERNORM_INPUT: begin
                // Layer normalization of input embeddings
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= input_matrix[i];
                end
                layernorm_start <= 1'b1;
            end
            
            SAVE_LN_INPUT: begin
                // Save normalized input for Q/K/V computation
                for (i = 0; i < 256; i = i + 1) begin
                    ln_input_output[i] <= ln_matrix_c[i];  // ← FIXED: Use ln_matrix_c
                end
            end
            
            COMPUTE_Q: begin
                // Q = Normalized_Input × W_q
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= ln_input_output[i];
                    bus_matrix_b[i] <= w_q[i];
                end
                mult_start <= 1'b1;
            end
            
            SAVE_Q: begin
                // Save Q matrix to working storage
                for (i = 0; i < 256; i = i + 1) begin
                    working_matrix[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
            end
            
            COMPUTE_K: begin
                // K = Normalized_Input × W_k
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= ln_input_output[i];
                    bus_matrix_b[i] <= w_k[i];
                end
                mult_start <= 1'b1;
            end
            
            SAVE_K: begin
                // Save K matrix
                for (i = 0; i < 256; i = i + 1) begin
                    k_matrix[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
            end
            
            COMPUTE_V: begin
                // V = Normalized_Input × W_v
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= ln_input_output[i];
                    bus_matrix_b[i] <= w_v[i];
                end
                mult_start <= 1'b1;
            end
            
            SAVE_V: begin
                // Save V matrix
                for (i = 0; i < 256; i = i + 1) begin
                    v_matrix[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
            end
            
            COMPUTE_SCORES: begin
                // Attention scores = Q × K^T
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= working_matrix[i];  // Q matrix
                    // Transpose K matrix
                    bus_matrix_b[i] <= k_matrix[((i%16)*16) + (i/16)];  // K^T
                end
                mult_start <= 1'b1;
            end
            
            SOFTMAX_SCORES: begin
                // Attention weights = softmax(scores)
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
                softmax_start <= 1'b1;
            end
            
            COMPUTE_ATTN: begin
                // Attention output = weights × V
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= sm_matrix_c[i];    // ← FIXED: Use sm_matrix_c
                    bus_matrix_b[i] <= v_matrix[i];
                end
                mult_start <= 1'b1;
            end
            
            ADD_RESIDUAL_1: begin
                // Residual connection: input + attention_output
                for (i = 0; i < 256; i = i + 1) begin
                    working_matrix[i] <= input_matrix[i] + mult_matrix_c[i];  // ← FIXED
                end
            end
            
            LAYERNORM_1: begin
                // Layer normalization
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= working_matrix[i];
                end
                layernorm_start <= 1'b1;
            end
            
            SAVE_LN1: begin
                // Save layer norm output
                for (i = 0; i < 256; i = i + 1) begin
                    ln1_output[i] <= ln_matrix_c[i];  // ← FIXED: Use ln_matrix_c
                end
            end
            
            COMPUTE_FF1: begin
                // First feed-forward layer
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= ln1_output[i];
                    bus_matrix_b[i] <= w_ff1[i];
                end
                mult_start <= 1'b1;
            end
            
            GELU_FF1: begin
                // GELU activation
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
                gelu_start <= 1'b1;
            end
            
            COMPUTE_FF2: begin
                // Second feed-forward layer
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= gelu_matrix_c[i];  // ← FIXED: Use gelu_matrix_c
                    bus_matrix_b[i] <= w_ff2[i];
                end
                mult_start <= 1'b1;
            end
            
            ADD_RESIDUAL_2: begin
                // Second residual connection
                for (i = 0; i < 256; i = i + 1) begin
                    working_matrix[i] <= ln1_output[i] + mult_matrix_c[i];  // ← FIXED
                end
            end
            
            LAYERNORM_2: begin
                // Second layer normalization
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= working_matrix[i];
                end
                layernorm_start <= 1'b1;
            end
            
            COMPUTE_OUTPUT: begin
                // Output projection
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= ln_matrix_c[i];    // ← FIXED: Use ln_matrix_c
                    bus_matrix_b[i] <= w_out[i];
                end
                mult_start <= 1'b1;
            end
            
            SOFTMAX_OUTPUT: begin
                // Final softmax for probabilities
                for (i = 0; i < 256; i = i + 1) begin
                    bus_matrix_a[i] <= mult_matrix_c[i];  // ← FIXED: Use mult_matrix_c
                end
                softmax_start <= 1'b1;
            end
            
            DONE_STATE: begin
                // Copy final probabilities to output
                output_prob_0 <= sm_matrix_c[0];   // ← FIXED: Use sm_matrix_c
                output_prob_1 <= sm_matrix_c[1];
                output_prob_2 <= sm_matrix_c[2];
                output_prob_3 <= sm_matrix_c[3];
                output_prob_4 <= sm_matrix_c[4];
                output_prob_5 <= sm_matrix_c[5];
                output_prob_6 <= sm_matrix_c[6];
                output_prob_7 <= sm_matrix_c[7];
                output_prob_8 <= sm_matrix_c[8];
                output_prob_9 <= sm_matrix_c[9];
                output_prob_10 <= sm_matrix_c[10];
                output_prob_11 <= sm_matrix_c[11];
                output_prob_12 <= sm_matrix_c[12];
                output_prob_13 <= sm_matrix_c[13];
                output_prob_14 <= sm_matrix_c[14];
                output_prob_15 <= sm_matrix_c[15];
                done <= 1'b1;
            end
            
        endcase
    end
end

endmodule