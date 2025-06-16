module exp_taylor_unit #(
    parameter INPUT_WIDTH         = 33,
    parameter INPUT_FRAC_BITS     = 16,
    parameter OUTPUT_WIDTH        = 16,
    parameter OUTPUT_FRAC_BITS    = 15, // Q1.15 format
    parameter NUM_TERMS           = 4,
    parameter INTERNAL_FRAC_BITS  = 20,
    parameter LATENCY             = 5
)(
    input wire                          clk,
    input wire                          rst_n,
    input wire                          start_exp,
    input wire signed [INPUT_WIDTH-1:0] x_in,
    output reg signed [OUTPUT_WIDTH-1:0] y_out,
    output reg                          exp_done
);

    localparam INTERNAL_INT_BITS       = INPUT_WIDTH - INPUT_FRAC_BITS - 1;
    localparam INTERNAL_CALC_INT_BITS  = INTERNAL_INT_BITS * 3 + 3;
    localparam INTERNAL_WIDTH          = 1 + INTERNAL_CALC_INT_BITS + INTERNAL_FRAC_BITS;

    localparam C0_TERM                 = (1 << INTERNAL_FRAC_BITS);
    localparam C2_TERM                 = (1 << INTERNAL_FRAC_BITS) / 2;
    localparam C3_TERM                 = $rtoi(0.16666666666666666 * (1 << INTERNAL_FRAC_BITS));

    localparam MIN_POS_Y              = OUTPUT_WIDTH'(1);
    localparam ONE_POINT_ZERO_Y       = OUTPUT_WIDTH'(1 << OUTPUT_FRAC_BITS);

    // Pipeline registers
    reg signed [INPUT_WIDTH-1:0] x_in_s0_reg;

    reg signed [INTERNAL_WIDTH-1:0] x_s1_reg;
    reg signed [INTERNAL_WIDTH-1:0] term0_s1_reg, term1_s1_reg;

    reg signed [INTERNAL_WIDTH-1:0] x_s2_reg, term0_s2_reg, term1_s2_reg;
    reg signed [INTERNAL_WIDTH-1:0] x_sq_s2_reg, term2_s2_reg;

    reg signed [INTERNAL_WIDTH-1:0] x_s3_reg, term0_s3_reg, term1_s3_reg, term2_s3_reg;
    reg signed [INTERNAL_WIDTH-1:0] x_cub_s3_reg, term3_s3_reg;

    reg [($clog2(LATENCY+1))-1:0] latency_counter_reg;
    reg processing_reg;

    // Function: scale x_in to internal format
    function automatic signed [INTERNAL_WIDTH-1:0] scale_to_internal;
        input signed [INPUT_WIDTH-1:0] val_in;
        input integer current_frac_bits_in, target_frac_bits_in;
        integer shift_val;
        logic signed [INTERNAL_WIDTH-1:0] extended_val_in, scaled_val;
        begin
            shift_val = target_frac_bits_in - current_frac_bits_in;
            extended_val_in = {{(INTERNAL_WIDTH-INPUT_WIDTH){val_in[INPUT_WIDTH-1]}}, val_in};
            scaled_val = (shift_val >= 0) ? (extended_val_in <<< shift_val) : (extended_val_in >>> -shift_val);
            scale_to_internal = scaled_val;
        end
    endfunction

    // Function: fixed-point multiplication
    function automatic signed [INTERNAL_WIDTH-1:0] multiply_internal;
        input signed [INTERNAL_WIDTH-1:0] a, b;
        logic signed [(2*INTERNAL_WIDTH)-1:0] product;
        begin
            product = a * b;
            multiply_internal = product >>> INTERNAL_FRAC_BITS;
        end
    endfunction

    // Combinational scaled input
    wire signed [INTERNAL_WIDTH-1:0] x_scaled = scale_to_internal(x_in_s0_reg, INPUT_FRAC_BITS, INTERNAL_FRAC_BITS);

    always @(posedge clk or negedge rst_n) begin
        // Declarations must be at the top
        logic signed [INTERNAL_WIDTH-1:0] sum_internal;
        integer shift_amt;
        logic signed [OUTPUT_WIDTH-1:0] scaled_result;

        if (!rst_n) begin
            x_in_s0_reg       <= 0;
            x_s1_reg          <= 0; term0_s1_reg <= 0; term1_s1_reg <= 0;
            x_s2_reg          <= 0; term0_s2_reg <= 0; term1_s2_reg <= 0;
            x_sq_s2_reg       <= 0; term2_s2_reg <= 0;
            x_s3_reg          <= 0; term0_s3_reg <= 0; term1_s3_reg <= 0;
            term2_s3_reg      <= 0; x_cub_s3_reg <= 0; term3_s3_reg <= 0;
            y_out             <= 0;
            exp_done          <= 1'b0;
            processing_reg    <= 1'b0;
            latency_counter_reg <= 0;
        end else begin
            if (start_exp && !processing_reg) begin
                x_in_s0_reg       <= x_in;
                latency_counter_reg <= LATENCY;
                processing_reg    <= 1'b1;
                exp_done          <= 1'b0;
            end else if (processing_reg && latency_counter_reg > 0) begin
                latency_counter_reg <= latency_counter_reg - 1;
            end

            // Stage 1
            x_s1_reg       <= x_scaled;
            term0_s1_reg   <= C0_TERM;
            term1_s1_reg   <= x_scaled;

            // Stage 2
            x_s2_reg       <= x_s1_reg;
            term0_s2_reg   <= term0_s1_reg;
            term1_s2_reg   <= term1_s1_reg;
            x_sq_s2_reg    <= multiply_internal(x_s1_reg, x_s1_reg);
            term2_s2_reg   <= multiply_internal(x_sq_s2_reg, C2_TERM);

            // Stage 3
            x_s3_reg       <= x_s2_reg;
            term0_s3_reg   <= term0_s2_reg;
            term1_s3_reg   <= term1_s2_reg;
            term2_s3_reg   <= term2_s2_reg;
            x_cub_s3_reg   <= multiply_internal(x_sq_s2_reg, x_s2_reg);
            term3_s3_reg   <= multiply_internal(x_cub_s3_reg, C3_TERM);

            // Stage 4: Final sum and scaling
            if (processing_reg && latency_counter_reg == 1) begin
                case (NUM_TERMS)
                    1: sum_internal = term0_s3_reg;
                    2: sum_internal = term0_s3_reg + term1_s3_reg;
                    3: sum_internal = term0_s3_reg + term1_s3_reg + term2_s3_reg;
                    default: sum_internal = term0_s3_reg + term1_s3_reg + term2_s3_reg + term3_s3_reg;
                endcase

                shift_amt = INTERNAL_FRAC_BITS - OUTPUT_FRAC_BITS;
                if (shift_amt >= 0)
                    scaled_result = sum_internal >>> shift_amt;
                else
                    scaled_result = sum_internal <<< -shift_amt;

                if (scaled_result <= 0)
                    y_out <= MIN_POS_Y;
                else if (scaled_result > ONE_POINT_ZERO_Y)
                    y_out <= ONE_POINT_ZERO_Y;
                else
                    y_out <= scaled_result;

                exp_done <= 1'b1;
                processing_reg <= 1'b0;
            end
        end
    end

endmodule

