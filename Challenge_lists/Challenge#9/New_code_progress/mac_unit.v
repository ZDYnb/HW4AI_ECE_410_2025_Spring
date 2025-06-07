// mac_unit.v
module mac_unit #(
    parameter DATA_A_WIDTH = 8,
    parameter DATA_B_WIDTH = 8,
    parameter ACCUM_WIDTH  = 32
) (
    input wire                      clk,
    input wire                      rst_n,
    input wire                      en,

    input wire signed [DATA_A_WIDTH-1:0] data_a,
    input wire signed [DATA_B_WIDTH-1:0] data_b,
    input wire signed [ACCUM_WIDTH-1:0]  accum_in, // For iterative accumulation

    output reg signed [ACCUM_WIDTH-1:0]  accum_out
);

    // Intermediate register for the product
    // Product of two N-bit numbers can be 2N bits.
    localparam PRODUCT_WIDTH = DATA_A_WIDTH + DATA_B_WIDTH;
    reg signed [PRODUCT_WIDTH-1:0] product_reg;
    
    // Registers for inputs to align with pipeline stages if accum_in changes
    reg signed [DATA_A_WIDTH-1:0] data_a_reg;
    reg signed [DATA_B_WIDTH-1:0] data_b_reg;
    reg signed [ACCUM_WIDTH-1:0]  accum_in_reg;
    reg                           en_reg_stage1; // Enable for multiplication stage
    reg                           en_reg_stage2; // Enable for accumulation stage

    // Stage 1: Multiplication and input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg    <= {DATA_A_WIDTH{1'b0}};
            data_b_reg    <= {DATA_B_WIDTH{1'b0}};
            product_reg   <= {PRODUCT_WIDTH{1'b0}};
            accum_in_reg  <= {ACCUM_WIDTH{1'b0}};
            en_reg_stage1 <= 1'b0;
            en_reg_stage2 <= 1'b0;
        end else begin
            if (en) begin // Capture inputs when top-level enable is high
                data_a_reg   <= data_a;
                data_b_reg   <= data_b;
                accum_in_reg <= accum_in; // Capture accum_in for the next stage
            end
            // The multiplication happens combinationally based on registered inputs,
            // or directly if we want a more direct path.
            // For a clear pipeline stage, register inputs then multiply.
            // So, product_reg is updated based on *previous* cycle's data_a & data_b if en was high.
            if (en_reg_stage1) begin // If previous cycle's enable was high
                 product_reg <= data_a_reg * data_b_reg;
            end else begin
                // Optional: clear product_reg if not enabled to avoid propagating old values,
                // or let it hold. For MAC, typically new product replaces old.
                // If en_reg_stage1 is low, it implies data_a_reg and data_b_reg were not validly loaded
                // for this specific operation, so the product might not be meaningful.
                // However, the structure `accum_out = accum_in + product` means `accum_in` can pass through if product is 0.
            end
            
            // Manage enables for pipeline flow
            en_reg_stage1 <= en;         // en for current cycle becomes en_reg_stage1 for next
            en_reg_stage2 <= en_reg_stage1; // en_reg_stage1 for current cycle becomes en_reg_stage2 for next
        end
    end

    // Stage 2: Addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_out <= {ACCUM_WIDTH{1'b0}};
        end else begin
            if (en_reg_stage2) begin // Use the enable from the previous stage
                // The product_reg was calculated in the previous cycle from data_a_reg * data_b_reg
                // The accum_in_reg was also captured from the input `accum_in` in the previous cycle
                accum_out <= accum_in_reg + product_reg;
            end else begin
                // Optional: if not enabled, perhaps pass accum_in_reg through or hold accum_out.
                // For a MAC that might be part of a larger dot product where `en` controls valid operations,
                // not enabling means the accum_out should not update with a new MAC result.
                // If it should just sum with 0: accum_out <= accum_in_reg; (if product_reg is forced to 0 when not enabled)
                // Or simply: accum_out <= accum_out; (hold previous value) - this is typical for registered outputs.
            end
        end
    end

endmodule