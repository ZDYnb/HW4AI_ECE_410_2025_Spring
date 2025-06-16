// ===========================================
// FINAL Fixed Parallel Interface Wrapper
// Fix: Result storage logic
// ===========================================

`timescale 1ns/1ps

module systolic_parallel_wrapper (
    // Parallel Interface (18 pins total)
    input  [7:0]  data_in,      // 8-bit data input
    output [7:0]  data_out,     // 8-bit data output
    input  [5:0]  addr,         // 6-bit address (64 locations)
    input         write_en,     // Write enable
    input         read_en,      // Read enable  
    input         start,        // Start computation
    output        ready,        // Ready for operations
    output        done,         // Computation complete
    input         clk,          // System clock
    input         rst_n         // Reset (active low)
);

    // ===========================================
    // Internal Register Bank
    // ===========================================
    
    // Matrix A storage: 32 bytes (16 elements × 2 bytes each)
    reg [7:0] matrix_a_bytes [0:31];
    
    // Matrix B storage: 16 bytes (16 elements × 1 byte each)  
    reg [7:0] matrix_b_bytes [0:15];
    
    // Result storage: 64 bytes (16 elements × 4 bytes each)
    reg [7:0] result_bytes [0:63];
    
    // Control registers
    reg computation_start;
    reg computation_ready;
    
    // ===========================================
    // Systolic Array Wires (DECLARE FIRST)
    // ===========================================
    
    wire [31:0] result_00, result_01, result_02, result_03;
    wire [31:0] result_10, result_11, result_12, result_13;
    wire [31:0] result_20, result_21, result_22, result_23;
    wire [31:0] result_30, result_31, result_32, result_33;
    wire        systolic_done, result_valid;
    
    // ===========================================
    // Address Decoding & Register Access
    // ===========================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Clear Matrix A storage
            matrix_a_bytes[0] <= 8'd0;   matrix_a_bytes[1] <= 8'd0;   matrix_a_bytes[2] <= 8'd0;   matrix_a_bytes[3] <= 8'd0;
            matrix_a_bytes[4] <= 8'd0;   matrix_a_bytes[5] <= 8'd0;   matrix_a_bytes[6] <= 8'd0;   matrix_a_bytes[7] <= 8'd0;
            matrix_a_bytes[8] <= 8'd0;   matrix_a_bytes[9] <= 8'd0;   matrix_a_bytes[10] <= 8'd0;  matrix_a_bytes[11] <= 8'd0;
            matrix_a_bytes[12] <= 8'd0;  matrix_a_bytes[13] <= 8'd0;  matrix_a_bytes[14] <= 8'd0;  matrix_a_bytes[15] <= 8'd0;
            matrix_a_bytes[16] <= 8'd0;  matrix_a_bytes[17] <= 8'd0;  matrix_a_bytes[18] <= 8'd0;  matrix_a_bytes[19] <= 8'd0;
            matrix_a_bytes[20] <= 8'd0;  matrix_a_bytes[21] <= 8'd0;  matrix_a_bytes[22] <= 8'd0;  matrix_a_bytes[23] <= 8'd0;
            matrix_a_bytes[24] <= 8'd0;  matrix_a_bytes[25] <= 8'd0;  matrix_a_bytes[26] <= 8'd0;  matrix_a_bytes[27] <= 8'd0;
            matrix_a_bytes[28] <= 8'd0;  matrix_a_bytes[29] <= 8'd0;  matrix_a_bytes[30] <= 8'd0;  matrix_a_bytes[31] <= 8'd0;
            
            // Clear Matrix B storage
            matrix_b_bytes[0] <= 8'd0;   matrix_b_bytes[1] <= 8'd0;   matrix_b_bytes[2] <= 8'd0;   matrix_b_bytes[3] <= 8'd0;
            matrix_b_bytes[4] <= 8'd0;   matrix_b_bytes[5] <= 8'd0;   matrix_b_bytes[6] <= 8'd0;   matrix_b_bytes[7] <= 8'd0;
            matrix_b_bytes[8] <= 8'd0;   matrix_b_bytes[9] <= 8'd0;   matrix_b_bytes[10] <= 8'd0;  matrix_b_bytes[11] <= 8'd0;
            matrix_b_bytes[12] <= 8'd0;  matrix_b_bytes[13] <= 8'd0;  matrix_b_bytes[14] <= 8'd0;  matrix_b_bytes[15] <= 8'd0;
            
            // Initialize result storage to known values
            result_bytes[0] <= 8'd0;   result_bytes[1] <= 8'd0;   result_bytes[2] <= 8'd0;   result_bytes[3] <= 8'd0;
            result_bytes[4] <= 8'd0;   result_bytes[5] <= 8'd0;   result_bytes[6] <= 8'd0;   result_bytes[7] <= 8'd0;
            result_bytes[8] <= 8'd0;   result_bytes[9] <= 8'd0;   result_bytes[10] <= 8'd0;  result_bytes[11] <= 8'd0;
            result_bytes[12] <= 8'd0;  result_bytes[13] <= 8'd0;  result_bytes[14] <= 8'd0;  result_bytes[15] <= 8'd0;
            result_bytes[16] <= 8'd0;  result_bytes[17] <= 8'd0;  result_bytes[18] <= 8'd0;  result_bytes[19] <= 8'd0;
            result_bytes[20] <= 8'd0;  result_bytes[21] <= 8'd0;  result_bytes[22] <= 8'd0;  result_bytes[23] <= 8'd0;
            result_bytes[24] <= 8'd0;  result_bytes[25] <= 8'd0;  result_bytes[26] <= 8'd0;  result_bytes[27] <= 8'd0;
            result_bytes[28] <= 8'd0;  result_bytes[29] <= 8'd0;  result_bytes[30] <= 8'd0;  result_bytes[31] <= 8'd0;
            result_bytes[32] <= 8'd0;  result_bytes[33] <= 8'd0;  result_bytes[34] <= 8'd0;  result_bytes[35] <= 8'd0;
            result_bytes[36] <= 8'd0;  result_bytes[37] <= 8'd0;  result_bytes[38] <= 8'd0;  result_bytes[39] <= 8'd0;
            result_bytes[40] <= 8'd0;  result_bytes[41] <= 8'd0;  result_bytes[42] <= 8'd0;  result_bytes[43] <= 8'd0;
            result_bytes[44] <= 8'd0;  result_bytes[45] <= 8'd0;  result_bytes[46] <= 8'd0;  result_bytes[47] <= 8'd0;
            result_bytes[48] <= 8'd0;  result_bytes[49] <= 8'd0;  result_bytes[50] <= 8'd0;  result_bytes[51] <= 8'd0;
            result_bytes[52] <= 8'd0;  result_bytes[53] <= 8'd0;  result_bytes[54] <= 8'd0;  result_bytes[55] <= 8'd0;
            result_bytes[56] <= 8'd0;  result_bytes[57] <= 8'd0;  result_bytes[58] <= 8'd0;  result_bytes[59] <= 8'd0;
            result_bytes[60] <= 8'd0;  result_bytes[61] <= 8'd0;  result_bytes[62] <= 8'd0;  result_bytes[63] <= 8'd0;
            
            computation_start <= 1'b0;
            computation_ready <= 1'b1;
        end else begin
            // Write operations
            if (write_en) begin
                if (addr >= 6'd0 && addr <= 6'd31) begin
                    // Matrix A write
                    matrix_a_bytes[addr] <= data_in;
                end else if (addr >= 6'd32 && addr <= 6'd47) begin
                    // Matrix B write
                    matrix_b_bytes[addr - 6'd32] <= data_in;
                end else if (addr == 6'd63) begin
                    // Control register
                    computation_start <= data_in[0];
                end
            end
            
            // Start computation trigger
            if (start || (write_en && addr == 6'd63 && data_in[0])) begin
                computation_start <= 1'b1;
                computation_ready <= 1'b0;
            end else if (systolic_done) begin
                computation_start <= 1'b0;
                computation_ready <= 1'b1;
            end
        end
    end
    
    // Read operations
    reg [7:0] data_out_reg;
    always @(*) begin
        data_out_reg = 8'd0;
        if (read_en) begin
            if (addr >= 6'd0 && addr <= 6'd31) begin
                // Matrix A read
                data_out_reg = matrix_a_bytes[addr];
            end else if (addr >= 6'd32 && addr <= 6'd47) begin
                // Matrix B read
                data_out_reg = matrix_b_bytes[addr - 6'd32];
            end else if (addr >= 6'd48 && addr <= 6'd62) begin
                // Result read
                data_out_reg = result_bytes[addr - 6'd48];
            end else if (addr == 6'd63) begin
                // Status register
                data_out_reg = {6'd0, systolic_done, computation_ready};
            end
        end
    end
    assign data_out = data_out_reg;
    
    // ===========================================
    // Convert Byte Storage to Matrix Format
    // ===========================================
    
    // Matrix A: Convert 32 bytes to 16×16-bit values
    wire [15:0] matrix_a_00 = {matrix_a_bytes[1],  matrix_a_bytes[0]};
    wire [15:0] matrix_a_01 = {matrix_a_bytes[3],  matrix_a_bytes[2]};
    wire [15:0] matrix_a_02 = {matrix_a_bytes[5],  matrix_a_bytes[4]};
    wire [15:0] matrix_a_03 = {matrix_a_bytes[7],  matrix_a_bytes[6]};
    wire [15:0] matrix_a_10 = {matrix_a_bytes[9],  matrix_a_bytes[8]};
    wire [15:0] matrix_a_11 = {matrix_a_bytes[11], matrix_a_bytes[10]};
    wire [15:0] matrix_a_12 = {matrix_a_bytes[13], matrix_a_bytes[12]};
    wire [15:0] matrix_a_13 = {matrix_a_bytes[15], matrix_a_bytes[14]};
    wire [15:0] matrix_a_20 = {matrix_a_bytes[17], matrix_a_bytes[16]};
    wire [15:0] matrix_a_21 = {matrix_a_bytes[19], matrix_a_bytes[18]};
    wire [15:0] matrix_a_22 = {matrix_a_bytes[21], matrix_a_bytes[20]};
    wire [15:0] matrix_a_23 = {matrix_a_bytes[23], matrix_a_bytes[22]};
    wire [15:0] matrix_a_30 = {matrix_a_bytes[25], matrix_a_bytes[24]};
    wire [15:0] matrix_a_31 = {matrix_a_bytes[27], matrix_a_bytes[26]};
    wire [15:0] matrix_a_32 = {matrix_a_bytes[29], matrix_a_bytes[28]};
    wire [15:0] matrix_a_33 = {matrix_a_bytes[31], matrix_a_bytes[30]};
    
    // Matrix B: Direct byte mapping
    wire [7:0] matrix_b_00 = matrix_b_bytes[0];
    wire [7:0] matrix_b_01 = matrix_b_bytes[1];
    wire [7:0] matrix_b_02 = matrix_b_bytes[2];
    wire [7:0] matrix_b_03 = matrix_b_bytes[3];
    wire [7:0] matrix_b_10 = matrix_b_bytes[4];
    wire [7:0] matrix_b_11 = matrix_b_bytes[5];
    wire [7:0] matrix_b_12 = matrix_b_bytes[6];
    wire [7:0] matrix_b_13 = matrix_b_bytes[7];
    wire [7:0] matrix_b_20 = matrix_b_bytes[8];
    wire [7:0] matrix_b_21 = matrix_b_bytes[9];
    wire [7:0] matrix_b_22 = matrix_b_bytes[10];
    wire [7:0] matrix_b_23 = matrix_b_bytes[11];
    wire [7:0] matrix_b_30 = matrix_b_bytes[12];
    wire [7:0] matrix_b_31 = matrix_b_bytes[13];
    wire [7:0] matrix_b_32 = matrix_b_bytes[14];
    wire [7:0] matrix_b_33 = matrix_b_bytes[15];
    
    // ===========================================
    // Systolic Array Instance
    // ===========================================
    
    systolic_array_4x4 systolic_core (
        .clk(clk),
        .rst_n(rst_n), 
        .start(computation_start),
        
        // Matrix A inputs
        .matrix_a_00(matrix_a_00), .matrix_a_01(matrix_a_01), .matrix_a_02(matrix_a_02), .matrix_a_03(matrix_a_03),
        .matrix_a_10(matrix_a_10), .matrix_a_11(matrix_a_11), .matrix_a_12(matrix_a_12), .matrix_a_13(matrix_a_13),
        .matrix_a_20(matrix_a_20), .matrix_a_21(matrix_a_21), .matrix_a_22(matrix_a_22), .matrix_a_23(matrix_a_23),
        .matrix_a_30(matrix_a_30), .matrix_a_31(matrix_a_31), .matrix_a_32(matrix_a_32), .matrix_a_33(matrix_a_33),
        
        // Matrix B inputs
        .matrix_b_00(matrix_b_00), .matrix_b_01(matrix_b_01), .matrix_b_02(matrix_b_02), .matrix_b_03(matrix_b_03),
        .matrix_b_10(matrix_b_10), .matrix_b_11(matrix_b_11), .matrix_b_12(matrix_b_12), .matrix_b_13(matrix_b_13),
        .matrix_b_20(matrix_b_20), .matrix_b_21(matrix_b_21), .matrix_b_22(matrix_b_22), .matrix_b_23(matrix_b_23),
        .matrix_b_30(matrix_b_30), .matrix_b_31(matrix_b_31), .matrix_b_32(matrix_b_32), .matrix_b_33(matrix_b_33),
        
        // Results
        .result_00(result_00), .result_01(result_01), .result_02(result_02), .result_03(result_03),
        .result_10(result_10), .result_11(result_11), .result_12(result_12), .result_13(result_13),
        .result_20(result_20), .result_21(result_21), .result_22(result_22), .result_23(result_23),
        .result_30(result_30), .result_31(result_31), .result_32(result_32), .result_33(result_33),
        
        .computation_done(systolic_done),
        .result_valid(result_valid)
    );
    
    // ===========================================
    // FIXED: Convert Results Back to Bytes
    // ===========================================
    
    // Use systolic_done instead of result_valid for more reliable triggering
    always @(posedge clk) begin
        if (systolic_done) begin
            // Result 0 (result_00)
            result_bytes[0]  <= result_00[7:0];
            result_bytes[1]  <= result_00[15:8];
            result_bytes[2]  <= result_00[23:16];
            result_bytes[3]  <= result_00[31:24];
            
            // Result 1 (result_01)
            result_bytes[4]  <= result_01[7:0];
            result_bytes[5]  <= result_01[15:8];
            result_bytes[6]  <= result_01[23:16];
            result_bytes[7]  <= result_01[31:24];
            
            // Result 2 (result_02)
            result_bytes[8]  <= result_02[7:0];
            result_bytes[9]  <= result_02[15:8];
            result_bytes[10] <= result_02[23:16];
            result_bytes[11] <= result_02[31:24];
            
            // Result 3 (result_03)
            result_bytes[12] <= result_03[7:0];
            result_bytes[13] <= result_03[15:8];
            result_bytes[14] <= result_03[23:16];
            result_bytes[15] <= result_03[31:24];
            
            // Result 4 (result_10)
            result_bytes[16] <= result_10[7:0];
            result_bytes[17] <= result_10[15:8];
            result_bytes[18] <= result_10[23:16];
            result_bytes[19] <= result_10[31:24];
            
            // Result 5 (result_11)
            result_bytes[20] <= result_11[7:0];
            result_bytes[21] <= result_11[15:8];
            result_bytes[22] <= result_11[23:16];
            result_bytes[23] <= result_11[31:24];
            
            // Result 6 (result_12)
            result_bytes[24] <= result_12[7:0];
            result_bytes[25] <= result_12[15:8];
            result_bytes[26] <= result_12[23:16];
            result_bytes[27] <= result_12[31:24];
            
            // Result 7 (result_13)
            result_bytes[28] <= result_13[7:0];
            result_bytes[29] <= result_13[15:8];
            result_bytes[30] <= result_13[23:16];
            result_bytes[31] <= result_13[31:24];
            
            // Result 8 (result_20)
            result_bytes[32] <= result_20[7:0];
            result_bytes[33] <= result_20[15:8];
            result_bytes[34] <= result_20[23:16];
            result_bytes[35] <= result_20[31:24];
            
            // Result 9 (result_21)
            result_bytes[36] <= result_21[7:0];
            result_bytes[37] <= result_21[15:8];
            result_bytes[38] <= result_21[23:16];
            result_bytes[39] <= result_21[31:24];
            
            // Result 10 (result_22)
            result_bytes[40] <= result_22[7:0];
            result_bytes[41] <= result_22[15:8];
            result_bytes[42] <= result_22[23:16];
            result_bytes[43] <= result_22[31:24];
            
            // Result 11 (result_23)
            result_bytes[44] <= result_23[7:0];
            result_bytes[45] <= result_23[15:8];
            result_bytes[46] <= result_23[16];
            result_bytes[47] <= result_23[31:24];
            
            // Result 12 (result_30)
            result_bytes[48] <= result_30[7:0];
            result_bytes[49] <= result_30[15:8];
            result_bytes[50] <= result_30[23:16];
            result_bytes[51] <= result_30[31:24];
            
            // Result 13 (result_31)
            result_bytes[52] <= result_31[7:0];
            result_bytes[53] <= result_31[15:8];
            result_bytes[54] <= result_31[23:16];
            result_bytes[55] <= result_31[31:24];
            
            // Result 14 (result_32)
            result_bytes[56] <= result_32[7:0];
            result_bytes[57] <= result_32[15:8];
            result_bytes[58] <= result_32[23:16];
            result_bytes[59] <= result_32[31:24];
            
            // Result 15 (result_33)
            result_bytes[60] <= result_33[7:0];
            result_bytes[61] <= result_33[15:8];
            result_bytes[62] <= result_33[23:16];
            result_bytes[63] <= result_33[31:24];
        end
    end
    
    // ===========================================
    // Output Assignments
    // ===========================================
    
    assign ready = computation_ready;
    assign done = systolic_done;

endmodule
