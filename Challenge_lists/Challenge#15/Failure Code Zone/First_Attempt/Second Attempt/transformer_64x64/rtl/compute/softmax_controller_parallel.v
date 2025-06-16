`timescale 1ns/1ps

module softmax_controller_parallel (
    input clk,
    input rst_n,
    input start,                    // Start processing
    input [1023:0] qk_input,       // 64×16 Q×K^T values (S5.10)
    output reg [1023:0] softmax_out, // 64×16 softmax results (S5.10)
    output reg valid_out            // Processing complete
);

// =========================================== 
// Internal signals
// ===========================================
reg [15:0] qk_values [63:0];       // Unpacked Q×K^T values
wire [15:0] exp_values [63:0];     // Parallel EXP outputs (combinational)
reg [15:0] softmax_results [63:0]; // Final softmax results

// Max finder signals
wire [15:0] max_value;

// Tree sum signals
reg [1023:0] tree_sum_input;
reg tree_start;
wire [23:0] sum_result;      // S13.10 format
wire sum_valid;

// Reciprocal unit signals
wire signed [23:0] reciprocal_input;
reg reciprocal_start;
wire signed [23:0] reciprocal_output;   // 2^14/sum format
wire reciprocal_valid;

// Control signals
reg do_multiply;  // ¿?¿?¿?¿?¿?¿?¿?¿?
integer i;

// FSM states - ¿?¿?¿?¿?¿?
parameter IDLE = 3'b000;
parameter CALC_SUM = 3'b001;
parameter CALC_RECIPROCAL = 3'b010;
parameter MULTIPLY = 3'b011;
parameter DONE = 3'b100;

reg [2:0] state;

// =========================================== 
// Unpack input
// ===========================================
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        qk_values[i] = qk_input[i*16 +: 16];
    end
end

// =========================================== 
// Pack output  
// ===========================================
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        softmax_out[i*16 +: 16] = softmax_results[i];
    end
end

// =========================================== 
// Parallel Max Finder (combinational)
// ===========================================
max_finder_64 max_finder (
    .data_in(qk_input),
    .max_out(max_value)
);

// =========================================== 
// 64 Parallel EXP LUTs (combinational)
// ===========================================
genvar j;
generate
    for (j = 0; j < 64; j = j + 1) begin : exp_lut_array
        // Each EXP LUT gets (qk_values[j] - max_value) as input
        exp_lut_combinational exp_lut (
            .x_in(qk_values[j] - max_value),
            .exp_out(exp_values[j])
        );
    end
endgenerate

// =========================================== 
// Tree Sum Accumulator
// ===========================================
tree_sum_accumulator tree_sum (
    .clk(clk),
    .rst_n(rst_n),
    .start(tree_start),
    .exp_values_in(tree_sum_input),
    .sum_out(sum_result),
    .sum_valid(sum_valid)
);

// =========================================== 
// Reciprocal Unit
// ===========================================
reciprocal_unit #(
    .INPUT_X_WIDTH(24),
    .DIVISOR_WIDTH(24), 
    .QUOTIENT_WIDTH(24),
    .FINAL_OUT_WIDTH(24)
) reciprocal_calc (
    .clk(clk),
    .rst_n(rst_n),
    .X_in(reciprocal_input),
    .valid_in(reciprocal_start),
    .reciprocal_out(reciprocal_output),
    .valid_out(reciprocal_valid)
);

// =========================================== 
// 64 Parallel Multipliers (1 cycle!)
// ===========================================
genvar k;
generate
    for (k = 0; k < 64; k = k + 1) begin : mult_array
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                softmax_results[k] <= 16'b0;
            end else if (do_multiply) begin
                // 64¿?¿?¿?¿?¿?¿?¿?¿?¿?
                softmax_results[k] <= (exp_values[k] * reciprocal_output) >> 14;
            end
        end
    end
endgenerate

assign reciprocal_input = sum_result;
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        tree_sum_input[i*16 +: 16] = exp_values[i];
    end
end

// =========================================== 
// Main FSM - Super simple now!
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        valid_out <= 1'b0;
        tree_start <= 1'b0;
        reciprocal_start <= 1'b0;
        do_multiply <= 1'b0;  // ¿?¿?¿?¿?¿?¿?¿?¿?
    end
    else begin
        case (state)
            IDLE: begin
                valid_out <= 1'b0;
                if (start) begin
                    // All EXP calculations happen in parallel immediately!
                    // Start tree sum right away
                    state <= CALC_SUM;
                    tree_start <= 1'b1;
                end
            end
            
            CALC_SUM: begin
                tree_start <= 1'b0;
                if (sum_valid) begin
                    reciprocal_start <= 1'b1;
                    state <= CALC_RECIPROCAL;
                end
            end
            
            CALC_RECIPROCAL: begin
                reciprocal_start <= 1'b0;
                if (reciprocal_valid) begin
                    state <= MULTIPLY;
                    do_multiply <= 1'b1;  // ¿?¿?¿?¿?¿?¿?
                end
            end
            
            MULTIPLY: begin
                do_multiply <= 1'b0;  // 1¿?¿?¿?¿?¿?¿?
                state <= DONE;
            end
            
            DONE: begin
                valid_out <= 1'b1;
                if (!start) begin
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule


// =========================================== 
// Combinational EXP LUT (no clock needed!)
// ===========================================
module exp_lut_combinational (
    input [15:0] x_in,        // S5.10 input
    output reg [15:0] exp_out // S5.10 exp(x) output
);

// Address calculation (combinational)
parameter INPUT_MIN = -8192;   // -8.0 in S5.10
parameter INPUT_MAX = 0;       // 0.0 in S5.10

wire signed [15:0] x_signed;
wire signed [15:0] x_clamped;
wire [15:0] x_offset;
wire [7:0] rom_addr;

assign x_signed = x_in;
assign x_clamped = (x_signed < INPUT_MIN) ? INPUT_MIN :
                   (x_signed > INPUT_MAX) ? INPUT_MAX : x_signed;
assign x_offset = x_clamped - INPUT_MIN;
assign rom_addr = (x_offset >= 16'd8160) ? 8'd255 : x_offset[12:5];

// Combinational LUT
always @(*) begin
    case (rom_addr)
        8'h00: exp_out = 16'h0001; 8'h01: exp_out = 16'h0001; 8'h02: exp_out = 16'h0001; 8'h03: exp_out = 16'h0001;
        8'h04: exp_out = 16'h0001; 8'h05: exp_out = 16'h0001; 8'h06: exp_out = 16'h0001; 8'h07: exp_out = 16'h0001;
        8'h08: exp_out = 16'h0001; 8'h09: exp_out = 16'h0001; 8'h0A: exp_out = 16'h0001; 8'h0B: exp_out = 16'h0001;
        8'h0C: exp_out = 16'h0001; 8'h0D: exp_out = 16'h0001; 8'h0E: exp_out = 16'h0001; 8'h0F: exp_out = 16'h0001;
        8'h10: exp_out = 16'h0001; 8'h11: exp_out = 16'h0001; 8'h12: exp_out = 16'h0001; 8'h13: exp_out = 16'h0001;
        8'h14: exp_out = 16'h0001; 8'h15: exp_out = 16'h0001; 8'h16: exp_out = 16'h0001; 8'h17: exp_out = 16'h0001;
        8'h18: exp_out = 16'h0001; 8'h19: exp_out = 16'h0001; 8'h1A: exp_out = 16'h0001; 8'h1B: exp_out = 16'h0001;
        8'h1C: exp_out = 16'h0001; 8'h1D: exp_out = 16'h0001; 8'h1E: exp_out = 16'h0001; 8'h1F: exp_out = 16'h0001;
        8'h20: exp_out = 16'h0001; 8'h21: exp_out = 16'h0001; 8'h22: exp_out = 16'h0001; 8'h23: exp_out = 16'h0001;
        8'h24: exp_out = 16'h0001; 8'h25: exp_out = 16'h0001; 8'h26: exp_out = 16'h0001; 8'h27: exp_out = 16'h0001;
        8'h28: exp_out = 16'h0001; 8'h29: exp_out = 16'h0001; 8'h2A: exp_out = 16'h0001; 8'h2B: exp_out = 16'h0001;
        8'h2C: exp_out = 16'h0001; 8'h2D: exp_out = 16'h0001; 8'h2E: exp_out = 16'h0001; 8'h2F: exp_out = 16'h0002;
        8'h30: exp_out = 16'h0002; 8'h31: exp_out = 16'h0002; 8'h32: exp_out = 16'h0002; 8'h33: exp_out = 16'h0002;
        8'h34: exp_out = 16'h0002; 8'h35: exp_out = 16'h0002; 8'h36: exp_out = 16'h0002; 8'h37: exp_out = 16'h0002;
        8'h38: exp_out = 16'h0002; 8'h39: exp_out = 16'h0002; 8'h3A: exp_out = 16'h0002; 8'h3B: exp_out = 16'h0002;
        8'h3C: exp_out = 16'h0002; 8'h3D: exp_out = 16'h0002; 8'h3E: exp_out = 16'h0002; 8'h3F: exp_out = 16'h0002;
        8'h40: exp_out = 16'h0003; 8'h41: exp_out = 16'h0003; 8'h42: exp_out = 16'h0003; 8'h43: exp_out = 16'h0003;
        8'h44: exp_out = 16'h0003; 8'h45: exp_out = 16'h0003; 8'h46: exp_out = 16'h0003; 8'h47: exp_out = 16'h0003;
        8'h48: exp_out = 16'h0003; 8'h49: exp_out = 16'h0003; 8'h4A: exp_out = 16'h0004; 8'h4B: exp_out = 16'h0004;
        8'h4C: exp_out = 16'h0004; 8'h4D: exp_out = 16'h0004; 8'h4E: exp_out = 16'h0004; 8'h4F: exp_out = 16'h0004;
        8'h50: exp_out = 16'h0004; 8'h51: exp_out = 16'h0004; 8'h52: exp_out = 16'h0004; 8'h53: exp_out = 16'h0005;
        8'h54: exp_out = 16'h0005; 8'h55: exp_out = 16'h0005; 8'h56: exp_out = 16'h0005; 8'h57: exp_out = 16'h0005;
        8'h58: exp_out = 16'h0005; 8'h59: exp_out = 16'h0006; 8'h5A: exp_out = 16'h0006; 8'h5B: exp_out = 16'h0006;
        8'h5C: exp_out = 16'h0006; 8'h5D: exp_out = 16'h0006; 8'h5E: exp_out = 16'h0007; 8'h5F: exp_out = 16'h0007;
        8'h60: exp_out = 16'h0007; 8'h61: exp_out = 16'h0007; 8'h62: exp_out = 16'h0007; 8'h63: exp_out = 16'h0008;
        8'h64: exp_out = 16'h0008; 8'h65: exp_out = 16'h0008; 8'h66: exp_out = 16'h0008; 8'h67: exp_out = 16'h0009;
        8'h68: exp_out = 16'h0009; 8'h69: exp_out = 16'h0009; 8'h6A: exp_out = 16'h000A; 8'h6B: exp_out = 16'h000A;
        8'h6C: exp_out = 16'h000A; 8'h6D: exp_out = 16'h000A; 8'h6E: exp_out = 16'h000B; 8'h6F: exp_out = 16'h000B;
        8'h70: exp_out = 16'h000C; 8'h71: exp_out = 16'h000C; 8'h72: exp_out = 16'h000C; 8'h73: exp_out = 16'h000D;
        8'h74: exp_out = 16'h000D; 8'h75: exp_out = 16'h000D; 8'h76: exp_out = 16'h000E; 8'h77: exp_out = 16'h000E;
        8'h78: exp_out = 16'h000F; 8'h79: exp_out = 16'h000F; 8'h7A: exp_out = 16'h0010; 8'h7B: exp_out = 16'h0010;
        8'h7C: exp_out = 16'h0011; 8'h7D: exp_out = 16'h0011; 8'h7E: exp_out = 16'h0012; 8'h7F: exp_out = 16'h0012;
        8'h80: exp_out = 16'h0013; 8'h81: exp_out = 16'h0014; 8'h82: exp_out = 16'h0014; 8'h83: exp_out = 16'h0015;
        8'h84: exp_out = 16'h0016; 8'h85: exp_out = 16'h0016; 8'h86: exp_out = 16'h0017; 8'h87: exp_out = 16'h0018;
        8'h88: exp_out = 16'h0018; 8'h89: exp_out = 16'h0019; 8'h8A: exp_out = 16'h001A; 8'h8B: exp_out = 16'h001B;
        8'h8C: exp_out = 16'h001C; 8'h8D: exp_out = 16'h001D; 8'h8E: exp_out = 16'h001E; 8'h8F: exp_out = 16'h001F;
        8'h90: exp_out = 16'h001F; 8'h91: exp_out = 16'h0020; 8'h92: exp_out = 16'h0022; 8'h93: exp_out = 16'h0023;
        8'h94: exp_out = 16'h0024; 8'h95: exp_out = 16'h0025; 8'h96: exp_out = 16'h0026; 8'h97: exp_out = 16'h0027;
        8'h98: exp_out = 16'h0028; 8'h99: exp_out = 16'h002A; 8'h9A: exp_out = 16'h002B; 8'h9B: exp_out = 16'h002C;
        8'h9C: exp_out = 16'h002E; 8'h9D: exp_out = 16'h002F; 8'h9E: exp_out = 16'h0031; 8'h9F: exp_out = 16'h0032;
        8'hA0: exp_out = 16'h0034; 8'hA1: exp_out = 16'h0036; 8'hA2: exp_out = 16'h0037; 8'hA3: exp_out = 16'h0039;
        8'hA4: exp_out = 16'h003B; 8'hA5: exp_out = 16'h003D; 8'hA6: exp_out = 16'h003F; 8'hA7: exp_out = 16'h0041;
        8'hA8: exp_out = 16'h0043; 8'hA9: exp_out = 16'h0045; 8'hAA: exp_out = 16'h0047; 8'hAB: exp_out = 16'h0049;
        8'hAC: exp_out = 16'h004C; 8'hAD: exp_out = 16'h004E; 8'hAE: exp_out = 16'h0051; 8'hAF: exp_out = 16'h0053;
        8'hB0: exp_out = 16'h0056; 8'hB1: exp_out = 16'h0059; 8'hB2: exp_out = 16'h005B; 8'hB3: exp_out = 16'h005E;
        8'hB4: exp_out = 16'h0061; 8'hB5: exp_out = 16'h0064; 8'hB6: exp_out = 16'h0068; 8'hB7: exp_out = 16'h006B;
        8'hB8: exp_out = 16'h006E; 8'hB9: exp_out = 16'h0072; 8'hBA: exp_out = 16'h0076; 8'hBB: exp_out = 16'h0079;
        8'hBC: exp_out = 16'h007D; 8'hBD: exp_out = 16'h0081; 8'hBE: exp_out = 16'h0085; 8'hBF: exp_out = 16'h008A;
        8'hC0: exp_out = 16'h008E; 8'hC1: exp_out = 16'h0092; 8'hC2: exp_out = 16'h0097; 8'hC3: exp_out = 16'h009C;
        8'hC4: exp_out = 16'h00A1; 8'hC5: exp_out = 16'h00A6; 8'hC6: exp_out = 16'h00AB; 8'hC7: exp_out = 16'h00B1;
        8'hC8: exp_out = 16'h00B6; 8'hC9: exp_out = 16'h00BC; 8'hCA: exp_out = 16'h00C2; 8'hCB: exp_out = 16'h00C8;
        8'hCC: exp_out = 16'h00CF; 8'hCD: exp_out = 16'h00D5; 8'hCE: exp_out = 16'h00DC; 8'hCF: exp_out = 16'h00E3;
        8'hD0: exp_out = 16'h00EA; 8'hD1: exp_out = 16'h00F2; 8'hD2: exp_out = 16'h00FA; 8'hD3: exp_out = 16'h0102;
        8'hD4: exp_out = 16'h010A; 8'hD5: exp_out = 16'h0112; 8'hD6: exp_out = 16'h011B; 8'hD7: exp_out = 16'h0124;
        8'hD8: exp_out = 16'h012D; 8'hD9: exp_out = 16'h0137; 8'hDA: exp_out = 16'h0141; 8'hDB: exp_out = 16'h014B;
        8'hDC: exp_out = 16'h0156; 8'hDD: exp_out = 16'h0160; 8'hDE: exp_out = 16'h016C; 8'hDF: exp_out = 16'h0177;
        8'hE0: exp_out = 16'h0183; 8'hE1: exp_out = 16'h0190; 8'hE2: exp_out = 16'h019C; 8'hE3: exp_out = 16'h01A9;
        8'hE4: exp_out = 16'h01B7; 8'hE5: exp_out = 16'h01C5; 8'hE6: exp_out = 16'h01D3; 8'hE7: exp_out = 16'h01E2;
        8'hE8: exp_out = 16'h01F2; 8'hE9: exp_out = 16'h0202; 8'hEA: exp_out = 16'h0212; 8'hEB: exp_out = 16'h0223;
        8'hEC: exp_out = 16'h0234; 8'hED: exp_out = 16'h0246; 8'hEE: exp_out = 16'h0259; 8'hEF: exp_out = 16'h026C;
        8'hF0: exp_out = 16'h0280; 8'hF1: exp_out = 16'h0294; 8'hF2: exp_out = 16'h02A9; 8'hF3: exp_out = 16'h02BF;
        8'hF4: exp_out = 16'h02D5; 8'hF5: exp_out = 16'h02EC; 8'hF6: exp_out = 16'h0304; 8'hF7: exp_out = 16'h031D;
        8'hF8: exp_out = 16'h0336; 8'hF9: exp_out = 16'h0350; 8'hFA: exp_out = 16'h036B; 8'hFB: exp_out = 16'h0387;
        8'hFC: exp_out = 16'h03A4; 8'hFD: exp_out = 16'h03C2; 8'hFE: exp_out = 16'h03E0; 8'hFF: exp_out = 16'h0400;
        default: exp_out = 16'h0001;
    endcase
end

endmodule

