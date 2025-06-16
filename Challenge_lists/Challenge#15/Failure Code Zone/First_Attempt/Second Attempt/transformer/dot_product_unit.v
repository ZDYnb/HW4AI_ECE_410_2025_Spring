// dot_product_unit.v
module dot_product_unit #(
    parameter DATA_WIDTH              = 8,
    parameter ACCUM_WIDTH             = 32,
    parameter MAC_LATENCY             = 2,     // Physical latency of mac_unit output reg
    parameter MAX_VECTOR_LENGTH_PARAM = 1024
) (
    input wire                          clk,
    input wire                          rst_n,
    input wire                          start,
    input wire [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] vector_length,
    input wire signed [DATA_WIDTH-1:0]  vec_a_element_in,
    input wire signed [DATA_WIDTH-1:0]  vec_b_element_in,
    output reg signed [ACCUM_WIDTH-1:0] result_out,
    output reg                          result_valid,
    output reg                          busy,
    output reg                          request_next_elements
);

    // Internal signals for datapath
    reg signed [ACCUM_WIDTH-1:0] current_sum_reg;
    reg [$clog2(MAX_VECTOR_LENGTH_PARAM)-1:0] element_counter_reg;

    // FSM state register and parameters
    localparam FSM_IDLE           = 4'd0;
    localparam FSM_INIT           = 4'd1;
    localparam FSM_REQUEST_DATA   = 4'd2;
    localparam FSM_START_MAC      = 4'd3;
    localparam FSM_WAIT_MAC_S1    = 4'd4; // MAC Stage 1
    localparam FSM_WAIT_MAC_S2    = 4'd5; // MAC Stage 2 (mac_unit output reg updates at end of this cycle)
    localparam FSM_CAPTURE_SUM    = 4'd6; // Capture mac_unit output in this cycle
    localparam FSM_OUTPUT_RESULT  = 4'd7;
    
    reg [3:0] current_state_reg, next_state_comb; // FSM state registers

    // Signals to feed the mac_unit instance
    reg                           mac_en_reg;
    wire signed [DATA_WIDTH-1:0]  mac_data_a_wire;
    wire signed [DATA_WIDTH-1:0]  mac_data_b_wire;
    wire signed [ACCUM_WIDTH-1:0] mac_accum_in_wire;
    wire signed [ACCUM_WIDTH-1:0] mac_accum_out_wire; // Output from mac_unit

    mac_unit #(
        .DATA_A_WIDTH(DATA_WIDTH),
        .DATA_B_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(mac_en_reg),
        .data_a(mac_data_a_wire),
        .data_b(mac_data_b_wire),
        .accum_in(mac_accum_in_wire),
        .accum_out(mac_accum_out_wire)
    );

    // Combinational logic to drive wires feeding the MAC unit
    assign mac_data_a_wire   = vec_a_element_in;
    assign mac_data_b_wire   = vec_b_element_in;
    assign mac_accum_in_wire = current_sum_reg;

    //--------------------------------------------------------------------------
    // FSM Sequential Logic (State Register)
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_reg <= FSM_IDLE;
        end else begin
            current_state_reg <= next_state_comb;
        end
    end

    //--------------------------------------------------------------------------
    // FSM Combinational Logic (Next State and Output Logic)
    //--------------------------------------------------------------------------
    always_comb begin
        // Default assignments for FSM outputs and mac_unit control
        next_state_comb       = current_state_reg; // Stay in current state by default
        busy                  = (current_state_reg != FSM_IDLE && current_state_reg != FSM_OUTPUT_RESULT);
        result_valid          = (current_state_reg == FSM_OUTPUT_RESULT);
        mac_en_reg            = 1'b0; 
        request_next_elements = 1'b0; // Default to not requesting

        case (current_state_reg)
            FSM_IDLE: begin
                if (start) begin
                    next_state_comb = FSM_INIT;
                end
            end

            FSM_INIT: begin
                next_state_comb = FSM_REQUEST_DATA;
            end

            FSM_REQUEST_DATA: begin
                if (element_counter_reg < vector_length) begin
                    request_next_elements = 1'b1; 
                    next_state_comb = FSM_START_MAC;
                end else begin 
                    next_state_comb = FSM_OUTPUT_RESULT;
                end
            end

            FSM_START_MAC: begin 
                mac_en_reg = 1'b1; 
                // Explicit begin-end for if-else branches
                if (MAC_LATENCY >= 1) begin
                    next_state_comb = FSM_WAIT_MAC_S1;
                end else begin // For 0-cycle MAC latency (combinational MAC)
                    next_state_comb = FSM_CAPTURE_SUM; 
                end
            end

            FSM_WAIT_MAC_S1: begin 
                if (MAC_LATENCY == 1) begin // Output ready to be captured in next cycle
                    next_state_comb = FSM_CAPTURE_SUM; 
                end else if (MAC_LATENCY >= 2) begin // Need at least one more wait cycle
                    next_state_comb = FSM_WAIT_MAC_S2;
                end
                // Note: Assumes MAC_LATENCY is at least 1 if FSM_WAIT_MAC_S1 is reached from FSM_START_MAC
            end

            FSM_WAIT_MAC_S2: begin 
                // After this state, mac_accum_out_wire holds the result of the MAC operation.
                // (Assuming MAC_LATENCY is 2, its output register is updated at the end of this cycle)
                next_state_comb = FSM_CAPTURE_SUM;
            end

            FSM_CAPTURE_SUM: begin 
                // Datapath updates current_sum_reg and element_counter_reg in this state's clock cycle,
                // using the mac_accum_out_wire value that became stable during FSM_WAIT_MAC_S2.
                next_state_comb = FSM_REQUEST_DATA;
            end

            FSM_OUTPUT_RESULT: begin
                next_state_comb = FSM_IDLE;
            end

            default: begin
                next_state_comb = FSM_IDLE;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Datapath Sequential Logic (Registers for sum, counter, outputs)
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_sum_reg     <= {ACCUM_WIDTH{1'b0}};
            element_counter_reg <= {($clog2(MAX_VECTOR_LENGTH_PARAM)){1'b0}};
            result_out          <= {ACCUM_WIDTH{1'b0}};
        end else begin
            // Default behavior: Hold current values unless explicitly changed
            current_sum_reg     <= current_sum_reg;
            element_counter_reg <= element_counter_reg;
            result_out          <= result_out;

            if (next_state_comb == FSM_INIT) begin // Reset on *entry* to INIT (from IDLE + start)
                current_sum_reg     <= {ACCUM_WIDTH{1'b0}};
                element_counter_reg <= {($clog2(MAX_VECTOR_LENGTH_PARAM)){1'b0}};
            end

            if (current_state_reg == FSM_CAPTURE_SUM) begin // Capture in this new state
                current_sum_reg     <= mac_accum_out_wire;
                element_counter_reg <= element_counter_reg + 1;
            end
            
            if (current_state_reg == FSM_OUTPUT_RESULT) begin
                result_out <= current_sum_reg;
            end
        end
    end

    //--------------------------------------------------------------------------
    // DEBUGGING DISPLAY BLOCK
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n && (busy || start || (current_state_reg != FSM_IDLE) )) begin // Display when active or just started/finished
            $display("[%0t DUT] State: %s, elem_cnt: %d (len:%d), sum_reg: %d | mac_en: %b, mac_A: %d, mac_B: %d, mac_accum_in: %d => mac_OUT: %d | req_next: %b, res_valid: %b, res_out_port: %d",
                $time,
                (current_state_reg == FSM_IDLE) ? "IDLE" :
                (current_state_reg == FSM_INIT) ? "INIT" :
                (current_state_reg == FSM_REQUEST_DATA) ? "REQ_DATA" :
                (current_state_reg == FSM_START_MAC) ? "START_MAC" :
                (current_state_reg == FSM_WAIT_MAC_S1) ? "WAIT_S1" :
                (current_state_reg == FSM_WAIT_MAC_S2) ? "WAIT_S2" :
                (current_state_reg == FSM_CAPTURE_SUM) ? "CAPTURE_SUM" :
                (current_state_reg == FSM_OUTPUT_RESULT) ? "OUT_RES" : "UNKNOWN_FSM",
                element_counter_reg, vector_length, current_sum_reg,
                mac_en_reg, mac_data_a_wire, mac_data_b_wire, mac_accum_in_wire, mac_accum_out_wire,
                request_next_elements, result_valid, result_out );
        end
    end

endmodule
