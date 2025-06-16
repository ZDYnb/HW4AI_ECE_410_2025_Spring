// =============================================================================
// GELU Activation Unit (LUT-Based, Pure Verilog, Q6.10 Format) - ¿?¿?¿?
// =============================================================================

module gelu_lut_unit #(
    parameter DATA_WIDTH = 16,        // Q6.10: 6 int bits + 10 frac bits
    parameter FRAC_BITS  = 10,
    parameter LUT_BITS   = 6,
    parameter LUT_SIZE   = 64
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire signed [DATA_WIDTH-1:0] x_in,

    output reg signed [DATA_WIDTH-1:0] gelu_out,
    output reg valid_out,
    output reg out_of_range
);

    // ¿?¿?¿?¿?
    parameter signed [DATA_WIDTH-1:0] LUT_MIN  = 16'hF000; // -4.0 in Q6.10
    parameter signed [DATA_WIDTH-1:0] LUT_MAX  = 16'h0F80; // +3.875 in Q6.10
    
    // =============================================================================
    // ROM: GELU Lookup Table (¿?¿?¿?¿?¿?¿?¿?)
    // =============================================================================
    reg signed [DATA_WIDTH-1:0] lut_rom [0:LUT_SIZE-1];

    initial begin
        // ¿?¿?¿?GELU LUT¿?¿?
        lut_rom[ 0] = 16'h0000; // x=-4.000, GELU=-0.00007
        lut_rom[ 1] = 16'h0000; // x=-3.875, GELU=-0.00013
        lut_rom[ 2] = 16'h0000; // x=-3.750, GELU=-0.00022
        lut_rom[ 3] = 16'h0000; // x=-3.625, GELU=-0.00037
        lut_rom[ 4] = 16'hFFFF; // x=-3.500, GELU=-0.00062
        lut_rom[ 5] = 16'hFFFF; // x=-3.375, GELU=-0.00100
        lut_rom[ 6] = 16'hFFFE; // x=-3.250, GELU=-0.00157
        lut_rom[ 7] = 16'hFFFE; // x=-3.125, GELU=-0.00242
        lut_rom[ 8] = 16'hFFFC; // x=-3.000, GELU=-0.00364
        lut_rom[ 9] = 16'hFFFB; // x=-2.875, GELU=-0.00536
        lut_rom[10] = 16'hFFF8; // x=-2.750, GELU=-0.00772
        lut_rom[11] = 16'hFFF5; // x=-2.625, GELU=-0.01090
        lut_rom[12] = 16'hFFF1; // x=-2.500, GELU=-0.01508
        lut_rom[13] = 16'hFFEB; // x=-2.375, GELU=-0.02046
        lut_rom[14] = 16'hFFE4; // x=-2.250, GELU=-0.02720
        lut_rom[15] = 16'hFFDC; // x=-2.125, GELU=-0.03548
        lut_rom[16] = 16'hFFD2; // x=-2.000, GELU=-0.04540
        lut_rom[17] = 16'hFFC6; // x=-1.875, GELU=-0.05700
        lut_rom[18] = 16'hFFB8; // x=-1.750, GELU=-0.07020
        lut_rom[19] = 16'hFFA9; // x=-1.625, GELU=-0.08481
        lut_rom[20] = 16'hFF99; // x=-1.500, GELU=-0.10043
        lut_rom[21] = 16'hFF89; // x=-1.375, GELU=-0.11651
        lut_rom[22] = 16'hFF79; // x=-1.250, GELU=-0.13229
        lut_rom[23] = 16'hFF6A; // x=-1.125, GELU=-0.14678
        lut_rom[24] = 16'hFF5D; // x=-1.000, GELU=-0.15881
        lut_rom[25] = 16'hFF55; // x=-0.875, GELU=-0.16705
        lut_rom[26] = 16'hFF52; // x=-0.750, GELU=-0.17004
        lut_rom[27] = 16'hFF56; // x=-0.625, GELU=-0.16628
        lut_rom[28] = 16'hFF62; // x=-0.500, GELU=-0.15429
        lut_rom[29] = 16'hFF78; // x=-0.375, GELU=-0.13269
        lut_rom[30] = 16'hFF99; // x=-0.250, GELU=-0.10032
        lut_rom[31] = 16'hFFC6; // x=-0.125, GELU=-0.05628
        lut_rom[32] = 16'h0000; // x=0.000, GELU=0.00000
        lut_rom[33] = 16'h0046; // x=0.125, GELU=0.06872
        lut_rom[34] = 16'h0099; // x=0.250, GELU=0.14968
        lut_rom[35] = 16'h00F8; // x=0.375, GELU=0.24231
        lut_rom[36] = 16'h0162; // x=0.500, GELU=0.34571
        lut_rom[37] = 16'h01D6; // x=0.625, GELU=0.45872
        lut_rom[38] = 16'h0252; // x=0.750, GELU=0.57996
        lut_rom[39] = 16'h02D5; // x=0.875, GELU=0.70795
        lut_rom[40] = 16'h035D; // x=1.000, GELU=0.84119
        lut_rom[41] = 16'h03EA; // x=1.125, GELU=0.97822
        lut_rom[42] = 16'h0479; // x=1.250, GELU=1.11771
        lut_rom[43] = 16'h0509; // x=1.375, GELU=1.25849
        lut_rom[44] = 16'h0599; // x=1.500, GELU=1.39957
        lut_rom[45] = 16'h0629; // x=1.625, GELU=1.54019
        lut_rom[46] = 16'h06B8; // x=1.750, GELU=1.67980
        lut_rom[47] = 16'h0746; // x=1.875, GELU=1.81800
        lut_rom[48] = 16'h07D2; // x=2.000, GELU=1.95460
        lut_rom[49] = 16'h085C; // x=2.125, GELU=2.08952
        lut_rom[50] = 16'h08E4; // x=2.250, GELU=2.22280
        lut_rom[51] = 16'h096B; // x=2.375, GELU=2.35454
        lut_rom[52] = 16'h09F1; // x=2.500, GELU=2.48492
        lut_rom[53] = 16'h0A75; // x=2.625, GELU=2.61410
        lut_rom[54] = 16'h0AF8; // x=2.750, GELU=2.74228
        lut_rom[55] = 16'h0B7B; // x=2.875, GELU=2.86964
        lut_rom[56] = 16'h0BFC; // x=3.000, GELU=2.99636
        lut_rom[57] = 16'h0C7E; // x=3.125, GELU=3.12258
        lut_rom[58] = 16'h0CFE; // x=3.250, GELU=3.24843
        lut_rom[59] = 16'h0D7F; // x=3.375, GELU=3.37400
        lut_rom[60] = 16'h0DFF; // x=3.500, GELU=3.49938
        lut_rom[61] = 16'h0E80; // x=3.625, GELU=3.62463
        lut_rom[62] = 16'h0F00; // x=3.750, GELU=3.74978
        lut_rom[63] = 16'h0F80; // x=3.875, GELU=3.87487
    end

    // =============================================================================
    // ¿?¿?¿?¿? (¿?¿?¿?)
    // =============================================================================
    wire signed [DATA_WIDTH-1:0] offset;
    wire [LUT_BITS-1:0] lut_addr;
    wire in_range;
    
    assign offset = x_in - LUT_MIN;
    
    // ¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?128 (0.125 in Q6.10)
    // offset[12:7] ¿?¿?¿? offset >> 7¿?¿?¿?¿?128
    assign lut_addr = offset[12:7];
    
    // ¿?¿?¿?¿?
    assign in_range = (x_in >= LUT_MIN) && (x_in < LUT_MAX);

    // =============================================================================
    // ¿?¿?¿?¿? (1-cycle latency)
    // =============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gelu_out     <= 0;
            valid_out    <= 0;
            out_of_range <= 0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                if (in_range) begin
                    gelu_out     <= lut_rom[lut_addr];
                    out_of_range <= 0;
                end else begin
                    // ¿?¿?¿?¿?¿?¿?¿?
                    out_of_range <= 1;
                    if (x_in < LUT_MIN) begin
                        gelu_out <= 16'h0000; // GELU ¿ 0 for large negative
                    end else begin
                        gelu_out <= x_in;      // GELU ¿ x for large positive
                    end
                end
            end
        end
    end

endmodule

