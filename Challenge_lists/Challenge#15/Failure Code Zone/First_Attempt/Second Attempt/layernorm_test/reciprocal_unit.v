// reciprocal_unit.v (Verilog-2001 style - with Q_reg << 1 fix)
module reciprocal_unit #(
    parameter INPUT_X_WIDTH   = 24,
    parameter DIVISOR_WIDTH   = 24,
    parameter QUOTIENT_WIDTH  = 24,
    parameter DIVIDEND_REG_WIDTH = QUOTIENT_WIDTH + 1, 
    parameter REMAINDER_WIDTH = DIVISOR_WIDTH + 2, 
    parameter FINAL_OUT_WIDTH = 24
) (
    input wire                               clk,
    input wire                               rst_n,
    input wire signed [INPUT_X_WIDTH-1:0]    X_in,
    input wire                               valid_in,
    output reg signed [FINAL_OUT_WIDTH-1:0]  reciprocal_out, // Output is a reg
    output reg                               valid_out
);

    // FSM State Definition
    parameter S_IDLE    = 2'b00;
    parameter S_LOAD    = 2'b01;
    parameter S_COMPUTE = 2'b10;
    parameter S_DONE    = 2'b11;

    reg [1:0] current_state, next_state;

    reg signed [REMAINDER_WIDTH-1:0] P_reg;
    reg [QUOTIENT_WIDTH-1:0]         Q_reg;
    reg [DIVISOR_WIDTH-1:0]          D_hw_reg;
    reg [DIVIDEND_REG_WIDTH-1:0]     N_shift_reg; 
    reg [$clog2(QUOTIENT_WIDTH)-1:0] iteration_counter;

    wire signed [REMAINDER_WIDTH-1:0] P_val_after_shift_N_bit_w;
    wire signed [REMAINDER_WIDTH-1:0] P_val_after_add_sub_w;
    wire                              current_quotient_bit_w;
    wire                              next_N_bit_w;
    wire signed [REMAINDER_WIDTH-1:0] D_extended_w;

    assign next_N_bit_w = N_shift_reg[DIVIDEND_REG_WIDTH-1];
    assign P_val_after_shift_N_bit_w = {P_reg[REMAINDER_WIDTH-2:0], next_N_bit_w};
    assign D_extended_w = {{ (REMAINDER_WIDTH-DIVISOR_WIDTH) {1'b0} }, D_hw_reg};

    assign P_val_after_add_sub_w = (P_reg[REMAINDER_WIDTH-1] == 1'b0) ? 
                                   (P_val_after_shift_N_bit_w - D_extended_w) :
                                   (P_val_after_shift_N_bit_w + D_extended_w);
    assign current_quotient_bit_w = (P_val_after_add_sub_w[REMAINDER_WIDTH-1] == 1'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= S_IDLE;
        else        current_state <= next_state;
    end

    always @(*) begin
        next_state = S_IDLE; 
        case (current_state)
            S_IDLE:    if (valid_in) next_state = S_LOAD; else next_state = S_IDLE;
            S_LOAD:    next_state = S_COMPUTE;
            S_COMPUTE: if (iteration_counter == QUOTIENT_WIDTH - 1) next_state = S_DONE;
                       else next_state = S_COMPUTE;
            S_DONE:    next_state = S_IDLE;
            default:   next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            P_reg <= 0;
            Q_reg <= 0;
            D_hw_reg <= 0;
            N_shift_reg <= 0;
            iteration_counter <= 0;
            valid_out <= 1'b0;
            reciprocal_out <= 0;
        end else begin
            valid_out <= 1'b0; 

            case (current_state)
                S_IDLE: begin
                    // Registers retain value or reset if specified
                end
                S_LOAD: begin
                    D_hw_reg <= X_in[DIVISOR_WIDTH-1:0]; // Assuming X_in provides the correct magnitude
                    N_shift_reg <= {1'b1, {(QUOTIENT_WIDTH){1'b0}}}; 
                    P_reg <= 0;
                    Q_reg <= 0;
                    iteration_counter <= 0;
                end
                S_COMPUTE: begin
                    P_reg <= P_val_after_add_sub_w;
                    Q_reg <= (Q_reg <<< 1) | current_quotient_bit_w;
                    N_shift_reg <= N_shift_reg <<< 1; 

                    if (iteration_counter != QUOTIENT_WIDTH - 1) begin
                        iteration_counter <= iteration_counter + 1;
                    end
                    // Add //$display here for debugging if needed, like in previous debug version
                    // //$display for S_COMPUTE values (P_reg, Q_reg are previous cycle's here)
                    // //$display("[%0t ns] DUT DBG Recip: Iter=%0d, s_reg_prev=%d, Q_reg_prev=%d, N_bit=%b, P_shift_N=%d, D_ext=%d, P_after_add_sub=%d, q_bit=%b",
                    //      $time, iteration_counter, P_reg, Q_reg, next_N_bit_w, P_val_after_shift_N_bit_w,
                    //      (P_reg[REMAINDER_WIDTH-1] == 1'b0) ? -D_extended_w : D_extended_w, // approx term used
                    //      P_val_after_add_sub_w, current_quotient_bit_w);
                end
                S_DONE: begin
                    valid_out <= 1'b1;
                    // Q_reg holds Q_hw_calculated = (N_hw/2) / D_hw
                    // We need N_hw / D_hw, so multiply by 2.
                    // Ensure Q_reg <<< 1 does not incorrectly overflow into sign bit of reciprocal_out
                    // Max Q_hw_calculated ~ 2^21. Q_hw_calculated <<< 1 ~ 2^22. Fits in 23 magnitude bits.
                    reciprocal_out <= signed'(Q_reg <<< 1); 
                end
            endcase
        end
    end
endmodule
