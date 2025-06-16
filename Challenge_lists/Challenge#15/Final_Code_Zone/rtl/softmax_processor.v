// Complete Softmax Processor - Top Module (Q5.10 format)
// Function: Connects softmax_frontend and softmax_backend
// Total latency: 8 cycles (frontend) + 2 cycles (backend) = 10 cycles

module softmax_processor (
    input clk,
    input rst_n,
    
    // Pipeline control interface
    input valid_in,                     // Input valid signal
    input [15:0] input_vector [0:15],   // Input vector (Q5.10 format)
    
    // Pipeline output interface  
    output valid_out,                   // Output valid signal
    output [15:0] softmax_out [0:15]    // Softmax result (Q5.10 format)
);

// =============================================================================
// Signals connecting frontend and backend
// =============================================================================
wire frontend_valid;
wire [31:0] frontend_exp_sum;
wire [15:0] frontend_exp_values [0:15];

// =============================================================================
// Softmax Frontend instance - EXP LUT + Tree Adder
// =============================================================================
softmax_frontend u_frontend (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(valid_in),
    .input_vector(input_vector),
    
    // Output (connects to backend)
    .valid_out(frontend_valid),
    .exp_sum(frontend_exp_sum),
    .exp_values(frontend_exp_values)
);

// =============================================================================
// Softmax Backend instance - Division Normalization  
// =============================================================================
softmax_backend u_backend (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input (from frontend)
    .valid_in(frontend_valid),
    .exp_sum_in(frontend_exp_sum),
    .exp_values_in(frontend_exp_values),
    
    // Output
    .valid_out(valid_out),
    .softmax_out(softmax_out)
);

endmodule