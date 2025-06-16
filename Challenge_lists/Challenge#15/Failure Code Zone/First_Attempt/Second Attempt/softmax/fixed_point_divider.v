// ===========================================
// Fixed Point Divider Unit for Softmax
// Performs: exp_value / sum (S5.10 / S13.10 = S5.10)
// Non-restoring division algorithm with pipeline
// ===========================================

`timescale 1ns/1ps

module fixed_point_divider (
    input clk,
    input rst_n,
    input start,                    // Start division
    input [15:0] numerator,        // S5.10 exp value
    input [23:0] denominator,      // S13.10 sum value
    output reg [15:0] quotient,    // S5.10 result
    output reg div_valid           // Division complete
);

// ===========================================
// Parameters and internal signals
// ===========================================
parameter IDLE = 2'b00;
parameter DIVIDING = 2'b01;
parameter DONE = 2'b10;

reg [1:0] state;
reg [4:0] bit_count;           // 16-bit division counter
reg [31:0] remainder;          // Extended remainder for division
reg [31:0] divisor_ext;        // Extended divisor
reg [15:0] quotient_reg;       // Working quotient register

// Input processing
wire [31:0] dividend_ext;      // Extended dividend
wire [31:0] divisor_norm;      // Normalized divisor

// Extend numerator to maintain S5.10 precision 
// Shift left by 10 bits to maintain fractional precision after division
assign dividend_ext = {6'b0, numerator, 10'b0};  // 32-bit with 10-bit fractional shift

// Extend denominator (S13.10 to 32-bit)
assign divisor_norm = {8'b0, denominator};

// ===========================================
// Division state machine
// ===========================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        bit_count <= 5'b0;
        remainder <= 32'b0;
        divisor_ext <= 32'b0;
        quotient_reg <= 16'b0;
        quotient <= 16'b0;
        div_valid <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                div_valid <= 1'b0;
                if (start) begin
                    // Check for division by zero
                    if (denominator == 24'b0) begin
                        quotient <= 16'h3FF;  // Max S5.10 value (¿1.0)
                        div_valid <= 1'b1;
                        state <= DONE;
                    end else begin
                        state <= DIVIDING;
                        bit_count <= 5'd15;    // Process 16 bits
                        remainder <= dividend_ext;
                        divisor_ext <= divisor_norm;
                        quotient_reg <= 16'b0;
                    end
                end
            end
            
            DIVIDING: begin
                // Standard restoring division algorithm
                // Shift remainder left first
                remainder <= remainder << 1;
                
                // Check if we can subtract
                if ((remainder << 1) >= divisor_ext) begin
                    remainder <= (remainder << 1) - divisor_ext;
                    quotient_reg <= {quotient_reg[14:0], 1'b1};
                end else begin
                    quotient_reg <= {quotient_reg[14:0], 1'b0};
                end
                
                if (bit_count == 5'b0) begin
                    state <= DONE;
                    quotient <= quotient_reg;
                    div_valid <= 1'b1;
                end else begin
                    bit_count <= bit_count - 1;
                end
            end
            
            DONE: begin
                if (start) begin
                    // Start new division
                    div_valid <= 1'b0;
                    if (denominator == 24'b0) begin
                        quotient <= 16'h3FF;
                        div_valid <= 1'b1;
                        state <= DONE;
                    end else begin
                        state <= DIVIDING;
                        bit_count <= 5'd15;
                        remainder <= dividend_ext;
                        divisor_ext <= divisor_norm;
                        quotient_reg <= 16'b0;
                    end
                end else begin
                    div_valid <= 1'b0;
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule
