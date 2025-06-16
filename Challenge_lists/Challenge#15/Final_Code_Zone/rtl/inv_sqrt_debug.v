// Debug version of inverse square root module - simplified version for debugging
module inv_sqrt_debug (
    input clk,
    input rst_n,
    input valid_in,
    input signed [15:0] variance_in,
    output reg valid_out,
    output reg signed [15:0] inv_sigma_out
);

// Constants
localparam Q5_10_THREE = 16'h0C00;    // 3.0 in Q5.10

// Pipeline registers
reg valid_stage [0:7];
reg signed [15:0] variance_stage [0:7];
reg signed [15:0] x0;
reg signed [31:0] x0_sq_full;  // Add full 32-bit intermediate result
reg signed [15:0] x0_sq, var_x0_sq, three_minus_1, x1;

// Initial guess lookup table
function [15:0] get_initial_guess;
    input [15:0] variance;
    begin
        casez (variance[15:12])
            4'b0000: get_initial_guess = 16'h1000;  // ~4.0 in Q5.10
            4'b0001: get_initial_guess = 16'h0B50;  // ~2.83 in Q5.10  
            4'b001?: get_initial_guess = 16'h0800;  // 2.0 in Q5.10
            4'b01??: get_initial_guess = 16'h05A8;  // ~1.41 in Q5.10
            4'b1???: get_initial_guess = 16'h0400;  // 1.0 in Q5.10
            default: get_initial_guess = 16'h0200;  // 0.5 in Q5.10
        endcase
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        integer i;
        for (i = 0; i <= 7; i = i + 1) begin
            valid_stage[i] <= 1'b0;
        end
        valid_out <= 1'b0;
    end else begin
        
        // Stage 0: Initial guess
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            variance_stage[0] <= variance_in;
            x0 <= get_initial_guess(variance_in);
            $display("Time %0t: Stage0 - variance=0x%04x (%f), x0=0x%04x (%f)", 
                     $time, variance_in, $itor(variance_in)/1024.0, 
                     get_initial_guess(variance_in), $itor(get_initial_guess(variance_in))/1024.0);
        end
        
        // Stage 1: x0²
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            variance_stage[1] <= variance_stage[0];
            x0_sq <= (x0 * x0) >>> 10;
            $display("Time %0t: Stage1 - x0=0x%04x, x0*x0=0x%08x, x0_sq=0x%04x (%f)", 
                     $time, x0, x0*x0, (x0*x0)>>>10, $itor((x0*x0)>>>10)/1024.0);
        end
        
        // Stage 2: variance × x0²
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            variance_stage[2] <= variance_stage[1];
            var_x0_sq <= (variance_stage[1] * x0_sq) >>> 10;
            $display("Time %0t: Stage2 - var=0x%04x, x0_sq=0x%04x, var*x0_sq=0x%08x, result=0x%04x", 
                     $time, variance_stage[1], x0_sq, variance_stage[1]*x0_sq, (variance_stage[1]*x0_sq)>>>10);
        end
        
        // Stage 3: 3 - variance×x0²
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            variance_stage[3] <= variance_stage[2];
            three_minus_1 <= Q5_10_THREE - var_x0_sq;
            $display("Time %0t: Stage3 - 3=0x%04x, var_x0_sq=0x%04x, 3-var_x0_sq=0x%04x (%f)", 
                     $time, Q5_10_THREE, var_x0_sq, Q5_10_THREE - var_x0_sq, $itor(Q5_10_THREE - var_x0_sq)/1024.0);
        end
        
        // Stage 4: x1 = x0×(3-variance×x0²)÷2
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            variance_stage[4] <= variance_stage[3];
            x1 <= (x0 * three_minus_1) >>> 11;
            $display("Time %0t: Stage4 - x0=0x%04x, three_minus_1=0x%04x, x0*three_minus_1=0x%08x, x1=0x%04x (%f)", 
                     $time, x0, three_minus_1, x0*three_minus_1, (x0*three_minus_1)>>>11, $itor((x0*three_minus_1)>>>11)/1024.0);
        end
        
        // Simplified: directly output x1 as result
        valid_stage[5] <= valid_stage[4];
        valid_stage[6] <= valid_stage[5];
        valid_stage[7] <= valid_stage[6];
        
        if (valid_stage[4]) variance_stage[5] <= variance_stage[4];
        if (valid_stage[5]) variance_stage[6] <= variance_stage[5];
        if (valid_stage[6]) variance_stage[7] <= variance_stage[6];
        
        // Output
        valid_out <= valid_stage[7];
        if (valid_stage[7]) begin
            inv_sigma_out <= x1;
            $display("Time %0t: Final output - inv_sigma=0x%04x (%f)", 
                     $time, x1, $itor(x1)/1024.0);
        end
    end
end

endmodule