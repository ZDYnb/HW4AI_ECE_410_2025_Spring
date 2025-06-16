// sqrt_non_restoring_debug.v (Verilog-2001 style - Rewritten for Clarity)
module sqrt_non_restoring #(
    parameter DATA_IN_WIDTH    = 24,
    parameter ROOT_OUT_WIDTH   = 12,
    parameter S_REG_WIDTH      = 16,
    parameter FINAL_OUT_WIDTH  = 24,
    parameter FRAC_BITS_OUT    = 10  // Conceptual for output formatting
) (
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire [DATA_IN_WIDTH-1:0]           radicand_in,
    input  wire                               valid_in,
    output wire signed [FINAL_OUT_WIDTH-1:0]  sqrt_out,
    output reg                                valid_out
);

    // FSM State Definition
    parameter S_IDLE    = 2'b00;
    parameter S_COMPUTE = 2'b01;
    parameter S_DONE    = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state; // For FSM next state logic

    // Internal Registers for Datapath
    reg signed [S_REG_WIDTH-1:0] s_reg;         // Scaled partial remainder
    reg [ROOT_OUT_WIDTH-1:0]     Q_reg;         // Root being formed
    reg [DATA_IN_WIDTH-1:0]      D_reg_shifted; // Stores the input radicand, shifted each cycle
    reg [$clog2(ROOT_OUT_WIDTH)-1:0] iteration_counter;

    // Wires for Combinational Datapath Logic
    wire [1:0]                    D_pair_current_w;
    wire signed [S_REG_WIDTH-1:0] s_shifted_with_D_bits_w;
    wire signed [S_REG_WIDTH-1:0] term_4Q_plus_1_extended_w;
    wire signed [S_REG_WIDTH-1:0] term_4Q_plus_3_extended_w;
    wire signed [S_REG_WIDTH-1:0] s_next_val_w;
    wire                          current_root_bit_w;

    // --- Combinational Logic Calculations ---

    // Extract current 2-bit pair from the top of D_reg_shifted
    assign D_pair_current_w = D_reg_shifted[DATA_IN_WIDTH-1 : DATA_IN_WIDTH-2];

    // Shift current s_reg and OR/add the D_pair_current_w
    assign s_shifted_with_D_bits_w = (s_reg <<< 2) | {{(S_REG_WIDTH-2){1'b0}}, D_pair_current_w};

    // Form 4Q+1 and 4Q+3 (these are (ROOT_OUT_WIDTH+2) bit positive values)
    wire [ROOT_OUT_WIDTH+1:0] val_4Q_w        = Q_reg <<< 2;
    wire [ROOT_OUT_WIDTH+1:0] val_4Q_plus_1_narrow_w = val_4Q_w + 2'd1;
    wire [ROOT_OUT_WIDTH+1:0] val_4Q_plus_3_narrow_w = val_4Q_w + 2'd3;

    // Assign narrower positive values to wider signed wires. Verilog should zero-extend.
    assign term_4Q_plus_1_extended_w = val_4Q_plus_1_narrow_w;
    assign term_4Q_plus_3_extended_w = val_4Q_plus_3_narrow_w;

    // Calculate next value of s_reg based on current s_reg's sign
    assign s_next_val_w = (s_reg[S_REG_WIDTH-1] == 1'b0) ? // If s_reg >= 0 (sign bit is 0)
                          (s_shifted_with_D_bits_w - term_4Q_plus_1_extended_w) :
                          (s_shifted_with_D_bits_w + term_4Q_plus_3_extended_w);

    // Determine current root bit based on the sign of s_next_val_w
    assign current_root_bit_w = (s_next_val_w[S_REG_WIDTH-1] == 1'b0); // 1 if s_next_val >= 0, else 0


    // --- FSM Logic ---
    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic (Combinational) and Debug Display
    always @(*) begin
        next_state = S_IDLE; // Default assignment

        case (current_state)
            S_IDLE: begin
                if (valid_in) begin
                    next_state = S_COMPUTE;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_COMPUTE: begin
                 if (iteration_counter == ROOT_OUT_WIDTH - 1) begin
                    next_state = S_DONE;
                end else begin
                    next_state = S_COMPUTE;
                end
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // --- Datapath Register Updates (Sequential) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_reg <= 0;
            Q_reg <= 0;
            D_reg_shifted <= 0;
            iteration_counter <= 0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0; // Default

            if (current_state == S_IDLE && next_state == S_COMPUTE) begin // Latch inputs on transition to COMPUTE
                D_reg_shifted <= radicand_in; // Load full radicand
                s_reg <= 0;
                Q_reg <= 0;
                iteration_counter <= 0;
            end else if (current_state == S_COMPUTE) begin
                s_reg <= s_next_val_w;
                Q_reg <= (Q_reg <<< 1) | current_root_bit_w;
                D_reg_shifted <= D_reg_shifted <<< 2; // Shift radicand for next pair

                if (next_state == S_COMPUTE) begin // Only increment if staying in S_COMPUTE
                    iteration_counter <= iteration_counter + 1;
                end
                // If transitioning to S_DONE, counter can hold or reset later
            end else if (current_state == S_DONE && next_state == S_IDLE) begin // When S_DONE asserts valid_out
                valid_out <= 1'b1;
            end
        end
    end

    // Output Formatting
    assign sqrt_out = {1'b0, {{(FINAL_OUT_WIDTH - ROOT_OUT_WIDTH - 1){1'b0}}}, Q_reg};
endmodule

