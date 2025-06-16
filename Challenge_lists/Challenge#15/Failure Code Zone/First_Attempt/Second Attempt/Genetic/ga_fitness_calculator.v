// ga_fitness_calculator.v
`timescale 1ns/1ps

module ga_fitness_calculator #(
    parameter CHROMOSOME_LENGTH = 19,
    parameter CHAR_WIDTH        = 8,
    parameter FITNESS_WIDTH     = 5  // To store fitness up to 19 (2^4=16, 2^5=32)
) (
    input wire                          clk,
    input wire                          rst_n,

    // Control and Data from Software/Host
    input wire                          start_new_individual, // Pulse (1 cycle high) to begin loading
    input wire [CHAR_WIDTH-1:0]         char_in,              // Serial character input
    input wire                          char_valid,           // char_in is valid this cycle

    // Output to Software/Host
    output reg [FITNESS_WIDTH-1:0]      fitness_out,
    output reg                          evaluation_done       // Pulsed high for one cycle when fitness_out is valid
);

    // Internal storage for the TARGET chromosome
    reg [CHAR_WIDTH-1:0] target_chromosome_regs [0:CHROMOSOME_LENGTH-1];

    // Buffer to store the serially incoming individual's chromosome
    reg [CHAR_WIDTH-1:0] individual_chromosome_buffer [0:CHROMOSOME_LENGTH-1];

    // Counter for received characters
    localparam COUNT_WIDTH = $clog2(CHROMOSOME_LENGTH + 1);
    reg [COUNT_WIDTH-1:0] char_receive_count;

    // Register to hold the calculated fitness before outputting
    reg [FITNESS_WIDTH-1:0] current_fitness_score_reg;

    // FSM state registers
    localparam FSM_IDLE        = 2'b00;
    localparam FSM_LOADING_CHARS = 2'b01;
    localparam FSM_CALCULATE   = 2'b10;
    localparam FSM_DONE        = 2'b11;
    reg [1:0] current_fsm_state, next_fsm_state;

    // Wire for combinational fitness calculation
    wire [FITNESS_WIDTH-1:0] calculated_fitness_w;
    integer i_loop; // for generate and initial block

    // Initialize TARGET = "I love GeeksforGeeks" (19 characters)
    // ASCII values:
    // I=73,  =32, l=108, o=111, v=118, e=101,  =32, G=71, e=101, e=101, k=107, s=115,
    // f=102, o=111, r=114, G=71, e=101, e=101, k=107, s=115
    initial begin
        target_chromosome_regs[0]  = 8'h49; // I
        target_chromosome_regs[1]  = 8'h20; // ' '
        target_chromosome_regs[2]  = 8'h6C; // l
        target_chromosome_regs[3]  = 8'h6F; // o
        target_chromosome_regs[4]  = 8'h76; // v
        target_chromosome_regs[5]  = 8'h65; // e
        target_chromosome_regs[6]  = 8'h20; // ' '
        target_chromosome_regs[7]  = 8'h47; // G
        target_chromosome_regs[8]  = 8'h65; // e
        target_chromosome_regs[9]  = 8'h65; // e
        target_chromosome_regs[10] = 8'h6B; // k
        target_chromosome_regs[11] = 8'h73; // s
        target_chromosome_regs[12] = 8'h66; // f
        target_chromosome_regs[13] = 8'h6F; // o
        target_chromosome_regs[14] = 8'h72; // r
        target_chromosome_regs[15] = 8'h47; // G
        target_chromosome_regs[16] = 8'h65; // e
        target_chromosome_regs[17] = 8'h65; // e
        target_chromosome_regs[18] = 8'h6B; // k  -- Fixed: last char should be 'k' not 's'
    end

    // Datapath: Fitness Calculation (Combinational)
    // Compares individual_chromosome_buffer with target_chromosome_regs
    // and sums the differences.
    wire [CHROMOSOME_LENGTH-1:0] diff_flags;
    genvar k_gen;
    generate
        for (k_gen = 0; k_gen < CHROMOSOME_LENGTH; k_gen = k_gen + 1) begin: char_comparators
            assign diff_flags[k_gen] = (individual_chromosome_buffer[k_gen] != target_chromosome_regs[k_gen]);
        end
    endgenerate

    // Adder to sum diff_flags.
    // This combinational adder sums up the 1-bit flags.
    reg [FITNESS_WIDTH-1:0] sum_of_diffs_comb;
    always @(*) begin
        sum_of_diffs_comb = {FITNESS_WIDTH{1'b0}};
        for (i_loop = 0; i_loop < CHROMOSOME_LENGTH; i_loop = i_loop + 1) begin
            sum_of_diffs_comb = sum_of_diffs_comb + diff_flags[i_loop];
        end
    end
    assign calculated_fitness_w = sum_of_diffs_comb;

    // FSM Sequential Logic (State Transitions and Registers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_fsm_state <= FSM_IDLE;
            char_receive_count <= 0;
            current_fitness_score_reg <= {FITNESS_WIDTH{1'b0}};
            fitness_out <= {FITNESS_WIDTH{1'b0}};
            evaluation_done <= 1'b0;
        end else begin
            current_fsm_state <= next_fsm_state;
            evaluation_done <= 1'b0; // Default to low, will be pulsed high in FSM_DONE

            case (current_fsm_state) // Actions based on *current* state before transition
                FSM_IDLE: begin
                    if (next_fsm_state == FSM_LOADING_CHARS) begin // Triggered by start_new_individual
                        char_receive_count <= 0;
                    end
                end
                FSM_LOADING_CHARS: begin
                    if (char_valid && (char_receive_count < CHROMOSOME_LENGTH)) begin
                        individual_chromosome_buffer[char_receive_count] <= char_in;
                        char_receive_count <= char_receive_count + 1;
                    end
                end
                FSM_CALCULATE: begin
                    current_fitness_score_reg <= calculated_fitness_w; // Latch the combinational result
                end
                FSM_DONE: begin
                    fitness_out <= current_fitness_score_reg;
                    evaluation_done <= 1'b1; // Pulse evaluation_done high for one cycle
                end
            endcase
        end
    end

    // FSM Combinational Logic (Next State Logic) - SIMPLIFIED
    always @(*) begin
        next_fsm_state = current_fsm_state; // Default to stay in current state

        case (current_fsm_state)
            FSM_IDLE: begin
                if (start_new_individual) begin
                    next_fsm_state = FSM_LOADING_CHARS;
                end
            end
            FSM_LOADING_CHARS: begin
                // Transition when all characters have been received
                if (char_receive_count == CHROMOSOME_LENGTH) begin
                    next_fsm_state = FSM_CALCULATE;
                end
            end
            FSM_CALCULATE: begin
                // This state takes one cycle to latch the fitness result
                next_fsm_state = FSM_DONE;
            end
            FSM_DONE: begin
                // After asserting evaluation_done for one cycle, go back to IDLE
                next_fsm_state = FSM_IDLE;
            end
            default: next_fsm_state = FSM_IDLE;
        endcase
    end

endmodule
