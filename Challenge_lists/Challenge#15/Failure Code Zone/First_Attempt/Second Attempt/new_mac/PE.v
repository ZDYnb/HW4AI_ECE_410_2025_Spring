// PE.v
// Processing Element (PE) for Systolic Array
// Handles 8-bit Weight * 16-bit Activation + 24-bit Accumulation

module PE (
    // System Control Signals
    input wire          clk,        // System Clock
    input wire          rst_n,      // Asynchronous Reset (active low)

    // Weight Loading Ports (Configuration Phase)
    input wire  [7:0]   W_load_data, // 8-bit data for weight loading (Q1.6)
    input wire          W_load_en,   // 1-bit enable for weight loading

    // Data Flow Inputs (Computation Phase)
    input wire  [15:0]  A_in,        // 16-bit Activation input (Q5.10)
    input wire  [23:0]  Acc_in,      // 24-bit Accumulation input (Q7.16)

    // Data Flow Outputs (Computation Phase)
    output reg  [15:0]  A_out,       // 16-bit Activation output (pipelined A_in)
    output reg  [23:0]  Acc_out      // 24-bit Accumulation output (pipelined Acc_internal_reg)
);

    // Internal Registers
    reg [7:0]   W_reg;          // 8-bit register to store the Weight (Q1.6)
    reg [23:0]  Acc_internal_reg; // 24-bit register for internal accumulation (Q7.16)

    // Internal Wires for Combinational Logic
    wire [23:0] product;        // 24-bit wire for the multiplication result (Q6.16)
    wire [23:0] sum;            // 24-bit wire for the addition result (Q7.16)

    // --- Combinational Logic ---
    // Multiplier: W_reg (Q1.6) * A_in (Q5.10) = product (Q6.16)
    assign product = $signed(W_reg) * $signed(A_in);

    // Adder: Acc_in (Q7.16) + product (Q6.16) = sum (Q7.16)
    assign sum = Acc_in + product;

    // --- Sequential Logic ---

    // ALWAYS BLOCK 1: For W_reg update (Weight Loading)
    // This block specifically handles the loading of the weight into W_reg.
    // It's independent of the MAC operation.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            W_reg <= 8'b0; // Reset W_reg
        end else begin
            if (W_load_en) begin
                W_reg <= W_load_data; // Load weight
            end
            // Else, W_reg holds its current value (stationary)
        end
    end

    // ALWAYS BLOCK 2: For MAC operation and Data Forwarding
    // This block handles the main computation flow.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Acc_internal_reg <= 24'b0; // Reset internal accumulator
            A_out <= 16'b0;             // Reset activation output
            Acc_out <= 24'b0;           // Reset accumulation output
        end else begin
            // Main MAC Operation & Internal Accumulation
            Acc_internal_reg <= sum; // Update the internal accumulator with the new sum.

            // Data Forwarding (Systolic Movement)
            A_out <= A_in; // Pass A_in to A_out with a register delay.
            Acc_out <= Acc_internal_reg; // Pass the previous cycle's accumulated value to Acc_out.
        end
    end

endmodule
