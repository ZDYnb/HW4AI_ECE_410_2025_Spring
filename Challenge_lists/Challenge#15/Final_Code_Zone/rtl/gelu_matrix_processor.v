// =============================================================================
// GELU Matrix Processor - ASIC Version (Q5.10 Format)
// =============================================================================
// Function: Apply GELU activation to each element of a 16x16 matrix
// Input: 256 elements matrix (16 rows × 16 cols, row-major order)
// Output: 256 elements GELU activated matrix
// Schedule: Pipeline - ROM lookup, single cycle throughput, total time = 16 + 1 pipeline_latency
// ASIC Implementation: Uses assign statements for ROM definition, no initial blocks

module gelu_matrix_processor (
    input clk,
    input rst_n,
    
    // Control Interface
    input start,                    // Start matrix processing
    output reg done,                    // Processing complete flag
    
    // Matrix Input Interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    input [15:0] matrix_i [0:255],
    
    // Matrix Output Interface (Q5.10 format) - 16×16 = 256 elements, row-major order
    output reg [15:0] matrix_o [0:255]
);

// =============================================================================
// Pipeline State Machine Definitions
// =============================================================================
reg [1:0] send_state;
localparam SEND_IDLE = 2'b00;
localparam SENDING   = 2'b01;

reg [1:0] recv_state;
localparam RECV_IDLE = 2'b00;
localparam RECEIVING = 2'b01;

// =============================================================================
// Control Counters
// =============================================================================
reg [4:0] send_counter;        // Send row counter (0-15)
reg [4:0] recv_counter;        // Receive row counter (0-15)
reg send_complete;             // Send completion flag
reg recv_complete;             // Receive completion flag

// =============================================================================
// GELU Pipeline Interface Signals
// =============================================================================
reg pipeline_valid_in;
reg [15:0] pipeline_input [0:15];      // Current row being sent

wire pipeline_valid_out;
wire [15:0] pipeline_output [0:15];    // Current row being received

// =============================================================================
// ASIC-Ready GELU ROM - 256 entries, 8-bit addressing
// =============================================================================
// Strategy: Use MSB 8 bits of Q5.10 input as index [15:8]
// ROM size: 512 bytes (256 × 16bit)
// Range: -32.0 to +31.75, step size 0.25
// ASIC implementation: Use wire + assign statements to define ROM

wire [15:0] gelu_rom [0:255];

// ROM Content - Complete 256 entries using assign statements (ASIC-friendly)
// Negative values region (index 0-127, corresponds to -32.0 to -0.25)
assign gelu_rom[  0] = 16'h0000; assign gelu_rom[  1] = 16'h0099; assign gelu_rom[  2] = 16'h0162; assign gelu_rom[  3] = 16'h0252;
assign gelu_rom[  4] = 16'h035D; assign gelu_rom[  5] = 16'h0479; assign gelu_rom[  6] = 16'h0599; assign gelu_rom[  7] = 16'h06B8;
assign gelu_rom[  8] = 16'h07D2; assign gelu_rom[  9] = 16'h08E4; assign gelu_rom[ 10] = 16'h09F1; assign gelu_rom[ 11] = 16'h0AF8;
assign gelu_rom[ 12] = 16'h0BFC; assign gelu_rom[ 13] = 16'h0CFE; assign gelu_rom[ 14] = 16'h0DFF; assign gelu_rom[ 15] = 16'h0F00;
assign gelu_rom[ 16] = 16'h1000; assign gelu_rom[ 17] = 16'h1100; assign gelu_rom[ 18] = 16'h1200; assign gelu_rom[ 19] = 16'h1300;
assign gelu_rom[ 20] = 16'h1400; assign gelu_rom[ 21] = 16'h1500; assign gelu_rom[ 22] = 16'h1600; assign gelu_rom[ 23] = 16'h1700;
assign gelu_rom[ 24] = 16'h1800; assign gelu_rom[ 25] = 16'h1900; assign gelu_rom[ 26] = 16'h1A00; assign gelu_rom[ 27] = 16'h1B00;
assign gelu_rom[ 28] = 16'h1C00; assign gelu_rom[ 29] = 16'h1D00; assign gelu_rom[ 30] = 16'h1E00; assign gelu_rom[ 31] = 16'h1F00;
assign gelu_rom[ 32] = 16'h2000; assign gelu_rom[ 33] = 16'h2100; assign gelu_rom[ 34] = 16'h2200; assign gelu_rom[ 35] = 16'h2300;
assign gelu_rom[ 36] = 16'h2400; assign gelu_rom[ 37] = 16'h2500; assign gelu_rom[ 38] = 16'h2600; assign gelu_rom[ 39] = 16'h2700;
assign gelu_rom[ 40] = 16'h2800; assign gelu_rom[ 41] = 16'h2900; assign gelu_rom[ 42] = 16'h2A00; assign gelu_rom[ 43] = 16'h2B00;
assign gelu_rom[ 44] = 16'h2C00; assign gelu_rom[ 45] = 16'h2D00; assign gelu_rom[ 46] = 16'h2E00; assign gelu_rom[ 47] = 16'h2F00;
assign gelu_rom[ 48] = 16'h3000; assign gelu_rom[ 49] = 16'h3100; assign gelu_rom[ 50] = 16'h3200; assign gelu_rom[ 51] = 16'h3300;
assign gelu_rom[ 52] = 16'h3400; assign gelu_rom[ 53] = 16'h3500; assign gelu_rom[ 54] = 16'h3600; assign gelu_rom[ 55] = 16'h3700;
assign gelu_rom[ 56] = 16'h3800; assign gelu_rom[ 57] = 16'h3900; assign gelu_rom[ 58] = 16'h3A00; assign gelu_rom[ 59] = 16'h3B00;
assign gelu_rom[ 60] = 16'h3C00; assign gelu_rom[ 61] = 16'h3D00; assign gelu_rom[ 62] = 16'h3E00; assign gelu_rom[ 63] = 16'h3F00;
assign gelu_rom[ 64] = 16'h4000; assign gelu_rom[ 65] = 16'h4100; assign gelu_rom[ 66] = 16'h4200; assign gelu_rom[ 67] = 16'h4300;
assign gelu_rom[ 68] = 16'h4400; assign gelu_rom[ 69] = 16'h4500; assign gelu_rom[ 70] = 16'h4600; assign gelu_rom[ 71] = 16'h4700;
assign gelu_rom[ 72] = 16'h4800; assign gelu_rom[ 73] = 16'h4900; assign gelu_rom[ 74] = 16'h4A00; assign gelu_rom[ 75] = 16'h4B00;
assign gelu_rom[ 76] = 16'h4C00; assign gelu_rom[ 77] = 16'h4D00; assign gelu_rom[ 78] = 16'h4E00; assign gelu_rom[ 79] = 16'h4F00;
assign gelu_rom[ 80] = 16'h5000; assign gelu_rom[ 81] = 16'h5100; assign gelu_rom[ 82] = 16'h5200; assign gelu_rom[ 83] = 16'h5300;
assign gelu_rom[ 84] = 16'h5400; assign gelu_rom[ 85] = 16'h5500; assign gelu_rom[ 86] = 16'h5600; assign gelu_rom[ 87] = 16'h5700;
assign gelu_rom[ 88] = 16'h5800; assign gelu_rom[ 89] = 16'h5900; assign gelu_rom[ 90] = 16'h5A00; assign gelu_rom[ 91] = 16'h5B00;
assign gelu_rom[ 92] = 16'h5C00; assign gelu_rom[ 93] = 16'h5D00; assign gelu_rom[ 94] = 16'h5E00; assign gelu_rom[ 95] = 16'h5F00;
assign gelu_rom[ 96] = 16'h6000; assign gelu_rom[ 97] = 16'h6100; assign gelu_rom[ 98] = 16'h6200; assign gelu_rom[ 99] = 16'h6300;
assign gelu_rom[100] = 16'h6400; assign gelu_rom[101] = 16'h6500; assign gelu_rom[102] = 16'h6600; assign gelu_rom[103] = 16'h6700;
assign gelu_rom[104] = 16'h6800; assign gelu_rom[105] = 16'h6900; assign gelu_rom[106] = 16'h6A00; assign gelu_rom[107] = 16'h6B00;
assign gelu_rom[108] = 16'h6C00; assign gelu_rom[109] = 16'h6D00; assign gelu_rom[110] = 16'h6E00; assign gelu_rom[111] = 16'h6F00;
assign gelu_rom[112] = 16'h7000; assign gelu_rom[113] = 16'h7100; assign gelu_rom[114] = 16'h7200; assign gelu_rom[115] = 16'h7300;
assign gelu_rom[116] = 16'h7400; assign gelu_rom[117] = 16'h7500; assign gelu_rom[118] = 16'h7600; assign gelu_rom[119] = 16'h7700;
assign gelu_rom[120] = 16'h7800; assign gelu_rom[121] = 16'h7900; assign gelu_rom[122] = 16'h7A00; assign gelu_rom[123] = 16'h7B00;
assign gelu_rom[124] = 16'h7C00; assign gelu_rom[125] = 16'h7D00; assign gelu_rom[126] = 16'h7E00; assign gelu_rom[127] = 16'h7F00;
assign gelu_rom[128] = 16'h0000; assign gelu_rom[129] = 16'h0000; assign gelu_rom[130] = 16'h0000; assign gelu_rom[131] = 16'h0000;
assign gelu_rom[132] = 16'h0000; assign gelu_rom[133] = 16'h0000; assign gelu_rom[134] = 16'h0000; assign gelu_rom[135] = 16'h0000;
assign gelu_rom[136] = 16'h0000; assign gelu_rom[137] = 16'h0000; assign gelu_rom[138] = 16'h0000; assign gelu_rom[139] = 16'h0000;
assign gelu_rom[140] = 16'h0000; assign gelu_rom[141] = 16'h0000; assign gelu_rom[142] = 16'h0000; assign gelu_rom[143] = 16'h0000;
assign gelu_rom[144] = 16'h0000; assign gelu_rom[145] = 16'h0000; assign gelu_rom[146] = 16'h0000; assign gelu_rom[147] = 16'h0000;
assign gelu_rom[148] = 16'h0000; assign gelu_rom[149] = 16'h0000; assign gelu_rom[150] = 16'h0000; assign gelu_rom[151] = 16'h0000;
assign gelu_rom[152] = 16'h0000; assign gelu_rom[153] = 16'h0000; assign gelu_rom[154] = 16'h0000; assign gelu_rom[155] = 16'h0000;
assign gelu_rom[156] = 16'h0000; assign gelu_rom[157] = 16'h0000; assign gelu_rom[158] = 16'h0000; assign gelu_rom[159] = 16'h0000;
assign gelu_rom[160] = 16'h0000; assign gelu_rom[161] = 16'h0000; assign gelu_rom[162] = 16'h0000; assign gelu_rom[163] = 16'h0000;
assign gelu_rom[164] = 16'h0000; assign gelu_rom[165] = 16'h0000; assign gelu_rom[166] = 16'h0000; assign gelu_rom[167] = 16'h0000;
assign gelu_rom[168] = 16'h0000; assign gelu_rom[169] = 16'h0000; assign gelu_rom[170] = 16'h0000; assign gelu_rom[171] = 16'h0000;
assign gelu_rom[172] = 16'h0000; assign gelu_rom[173] = 16'h0000; assign gelu_rom[174] = 16'h0000; assign gelu_rom[175] = 16'h0000;
assign gelu_rom[176] = 16'h0000; assign gelu_rom[177] = 16'h0000; assign gelu_rom[178] = 16'h0000; assign gelu_rom[179] = 16'h0000;
assign gelu_rom[180] = 16'h0000; assign gelu_rom[181] = 16'h0000; assign gelu_rom[182] = 16'h0000; assign gelu_rom[183] = 16'h0000;
assign gelu_rom[184] = 16'h0000; assign gelu_rom[185] = 16'h0000; assign gelu_rom[186] = 16'h0000; assign gelu_rom[187] = 16'h0000;
assign gelu_rom[188] = 16'h0000; assign gelu_rom[189] = 16'h0000; assign gelu_rom[190] = 16'h0000; assign gelu_rom[191] = 16'h0000;
assign gelu_rom[192] = 16'h0000; assign gelu_rom[193] = 16'h0000; assign gelu_rom[194] = 16'h0000; assign gelu_rom[195] = 16'h0000;
assign gelu_rom[196] = 16'h0000; assign gelu_rom[197] = 16'h0000; assign gelu_rom[198] = 16'h0000; assign gelu_rom[199] = 16'h0000;
assign gelu_rom[200] = 16'h0000; assign gelu_rom[201] = 16'h0000; assign gelu_rom[202] = 16'h0000; assign gelu_rom[203] = 16'h0000;
assign gelu_rom[204] = 16'h0000; assign gelu_rom[205] = 16'h0000; assign gelu_rom[206] = 16'h0000; assign gelu_rom[207] = 16'h0000;
assign gelu_rom[208] = 16'h0000; assign gelu_rom[209] = 16'h0000; assign gelu_rom[210] = 16'h0000; assign gelu_rom[211] = 16'h0000;
assign gelu_rom[212] = 16'h0000; assign gelu_rom[213] = 16'h0000; assign gelu_rom[214] = 16'h0000; assign gelu_rom[215] = 16'h0000;
assign gelu_rom[216] = 16'h0000; assign gelu_rom[217] = 16'h0000; assign gelu_rom[218] = 16'h0000; assign gelu_rom[219] = 16'h0000;
assign gelu_rom[220] = 16'h0000; assign gelu_rom[221] = 16'h0000; assign gelu_rom[222] = 16'h0000; assign gelu_rom[223] = 16'h0000;
assign gelu_rom[224] = 16'h0000; assign gelu_rom[225] = 16'h0000; assign gelu_rom[226] = 16'h0000; assign gelu_rom[227] = 16'h0000;
assign gelu_rom[228] = 16'h0000; assign gelu_rom[229] = 16'h0000; assign gelu_rom[230] = 16'h0000; assign gelu_rom[231] = 16'h0000;
assign gelu_rom[232] = 16'h0000; assign gelu_rom[233] = 16'h0000; assign gelu_rom[234] = 16'h0000; assign gelu_rom[235] = 16'h0000;
assign gelu_rom[236] = 16'h0000; assign gelu_rom[237] = 16'h0000; assign gelu_rom[238] = 16'h0000; assign gelu_rom[239] = 16'h0000;
assign gelu_rom[240] = 16'h0000; assign gelu_rom[241] = 16'h0000; assign gelu_rom[242] = 16'hFFFF; assign gelu_rom[243] = 16'hFFFE;
assign gelu_rom[244] = 16'hFFFC; assign gelu_rom[245] = 16'hFFF8; assign gelu_rom[246] = 16'hFFF1; assign gelu_rom[247] = 16'hFFE4;
assign gelu_rom[248] = 16'hFFD2; assign gelu_rom[249] = 16'hFFB8; assign gelu_rom[250] = 16'hFF99; assign gelu_rom[251] = 16'hFF79;
assign gelu_rom[252] = 16'hFF5D; assign gelu_rom[253] = 16'hFF52; assign gelu_rom[254] = 16'hFF62; assign gelu_rom[255] = 16'hFF99;

// =============================================================================
// GELU Processor Instance - 16 elements parallel ROM lookup
// =============================================================================
gelu_processor u_gelu_processor (
    .clk(clk),
    .rst_n(rst_n),
    
    // Input
    .valid_in(pipeline_valid_in),
    .input_vector(pipeline_input),
    
    // Output
    .valid_out(pipeline_valid_out),
    .gelu_out(pipeline_output)
);

// =============================================================================
// Completion Signal - Both state machines completed
// =============================================================================
//assign done = send_complete && recv_complete;

// =============================================================================
// Send State Machine - Independent data sending control
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        send_state <= SEND_IDLE;
        send_counter <= 5'b0;
        send_complete <= 1'b0;
        pipeline_valid_in <= 1'b0;
        
        // Clear pipeline input
        pipeline_input[0]  <= 16'h0000; pipeline_input[1]  <= 16'h0000;
        pipeline_input[2]  <= 16'h0000; pipeline_input[3]  <= 16'h0000;
        pipeline_input[4]  <= 16'h0000; pipeline_input[5]  <= 16'h0000;
        pipeline_input[6]  <= 16'h0000; pipeline_input[7]  <= 16'h0000;
        pipeline_input[8]  <= 16'h0000; pipeline_input[9]  <= 16'h0000;
        pipeline_input[10] <= 16'h0000; pipeline_input[11] <= 16'h0000;
        pipeline_input[12] <= 16'h0000; pipeline_input[13] <= 16'h0000;
        pipeline_input[14] <= 16'h0000; pipeline_input[15] <= 16'h0000;
        
    end else begin
        case (send_state)
            SEND_IDLE: begin
                pipeline_valid_in <= 1'b0;
                
                if (start) begin
                    send_state <= SENDING;
                    send_counter <= 5'b0;
                    send_complete <= 1'b0;
                end
            end
            
            SENDING: begin
                // Send 16 rows of data continuously to pipeline
                pipeline_valid_in <= 1'b1;
                
                if (send_counter < 16) begin
                    // Send current row data
                    pipeline_input[0]  <= matrix_i[send_counter * 16 + 0];
                    pipeline_input[1]  <= matrix_i[send_counter * 16 + 1];
                    pipeline_input[2]  <= matrix_i[send_counter * 16 + 2];
                    pipeline_input[3]  <= matrix_i[send_counter * 16 + 3];
                    pipeline_input[4]  <= matrix_i[send_counter * 16 + 4];
                    pipeline_input[5]  <= matrix_i[send_counter * 16 + 5];
                    pipeline_input[6]  <= matrix_i[send_counter * 16 + 6];
                    pipeline_input[7]  <= matrix_i[send_counter * 16 + 7];
                    pipeline_input[8]  <= matrix_i[send_counter * 16 + 8];
                    pipeline_input[9]  <= matrix_i[send_counter * 16 + 9];
                    pipeline_input[10] <= matrix_i[send_counter * 16 + 10];
                    pipeline_input[11] <= matrix_i[send_counter * 16 + 11];
                    pipeline_input[12] <= matrix_i[send_counter * 16 + 12];
                    pipeline_input[13] <= matrix_i[send_counter * 16 + 13];
                    pipeline_input[14] <= matrix_i[send_counter * 16 + 14];
                    pipeline_input[15] <= matrix_i[send_counter * 16 + 15];
                    
                    // Increment send counter
                    send_counter <= send_counter + 1;
                end else begin
                    send_state <= SEND_IDLE;
                    send_complete <= 1'b1;
                    pipeline_valid_in <= 1'b0;
                end
            end
        endcase
    end
end

// =============================================================================
// Receive State Machine - Independent data receiving control
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        recv_state <= RECV_IDLE;
        recv_counter <= 5'b0;
        recv_complete <= 1'b0;
        
    end else begin
        case (recv_state)
            RECV_IDLE: begin
                if (pipeline_valid_out) begin
                    recv_state <= RECEIVING;
                    recv_counter <= 5'b1;  // Set to 1, since we just received row 0
                    recv_complete <= 1'b0;
                    
                    // Receive first row output (row 0)
                    matrix_o[0]  <= pipeline_output[0];
                    matrix_o[1]  <= pipeline_output[1];
                    matrix_o[2]  <= pipeline_output[2];
                    matrix_o[3]  <= pipeline_output[3];
                    matrix_o[4]  <= pipeline_output[4];
                    matrix_o[5]  <= pipeline_output[5];
                    matrix_o[6]  <= pipeline_output[6];
                    matrix_o[7]  <= pipeline_output[7];
                    matrix_o[8]  <= pipeline_output[8];
                    matrix_o[9]  <= pipeline_output[9];
                    matrix_o[10] <= pipeline_output[10];
                    matrix_o[11] <= pipeline_output[11];
                    matrix_o[12] <= pipeline_output[12];
                    matrix_o[13] <= pipeline_output[13];
                    matrix_o[14] <= pipeline_output[14];
                    matrix_o[15] <= pipeline_output[15];
                end
            end
            
            RECEIVING: begin
                if (pipeline_valid_out) begin
                    // Receive current row data
                    matrix_o[recv_counter * 16 + 0]  <= pipeline_output[0];
                    matrix_o[recv_counter * 16 + 1]  <= pipeline_output[1];
                    matrix_o[recv_counter * 16 + 2]  <= pipeline_output[2];
                    matrix_o[recv_counter * 16 + 3]  <= pipeline_output[3];
                    matrix_o[recv_counter * 16 + 4]  <= pipeline_output[4];
                    matrix_o[recv_counter * 16 + 5]  <= pipeline_output[5];
                    matrix_o[recv_counter * 16 + 6]  <= pipeline_output[6];
                    matrix_o[recv_counter * 16 + 7]  <= pipeline_output[7];
                    matrix_o[recv_counter * 16 + 8]  <= pipeline_output[8];
                    matrix_o[recv_counter * 16 + 9]  <= pipeline_output[9];
                    matrix_o[recv_counter * 16 + 10] <= pipeline_output[10];
                    matrix_o[recv_counter * 16 + 11] <= pipeline_output[11];
                    matrix_o[recv_counter * 16 + 12] <= pipeline_output[12];
                    matrix_o[recv_counter * 16 + 13] <= pipeline_output[13];
                    matrix_o[recv_counter * 16 + 14] <= pipeline_output[14];
                    matrix_o[recv_counter * 16 + 15] <= pipeline_output[15];
                    
                    // Increment receive counter
                    recv_counter <= recv_counter + 1;
                end
                
                if (recv_counter == 16) begin
                    recv_state <= RECV_IDLE;
                    recv_complete <= 1'b1;
                    done <= 1'b1;
                end
            end
        endcase
    end
end

endmodule

// =============================================================================
// GELU Processor Core - 16 elements parallel ROM lookup
// =============================================================================
module gelu_processor (
    input clk,
    input rst_n,
    
    // Input vector (16 Q5.10 elements)
    input valid_in,
    input [15:0] input_vector [0:15],
    
    // Output vector (16 Q5.10 elements)
    output reg valid_out,
    output reg [15:0] gelu_out [0:15]
);

// =============================================================================
// GELU ROM Access - References ROM defined in parent module
// =============================================================================
// Note: The gelu_rom is defined in the parent module (gelu_matrix_processor)
// This module accesses it through hierarchical reference

// =============================================================================
// ASIC Pipeline Processing - 8-bit ROM lookup
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 1'b0;
        gelu_out[0]  <= 16'h0000; gelu_out[1]  <= 16'h0000;
        gelu_out[2]  <= 16'h0000; gelu_out[3]  <= 16'h0000;
        gelu_out[4]  <= 16'h0000; gelu_out[5]  <= 16'h0000;
        gelu_out[6]  <= 16'h0000; gelu_out[7]  <= 16'h0000;
        gelu_out[8]  <= 16'h0000; gelu_out[9]  <= 16'h0000;
        gelu_out[10] <= 16'h0000; gelu_out[11] <= 16'h0000;
        gelu_out[12] <= 16'h0000; gelu_out[13] <= 16'h0000;
        gelu_out[14] <= 16'h0000; gelu_out[15] <= 16'h0000;
    end else begin
        // Single cycle parallel ROM lookup - use MSB 8 bits for addressing
        valid_out <= valid_in;
        
        if (valid_in) begin
            // Access parent module's ROM using hierarchical reference
            gelu_out[0]  <= gelu_matrix_processor.gelu_rom[input_vector[0][15:8]];
            gelu_out[1]  <= gelu_matrix_processor.gelu_rom[input_vector[1][15:8]];
            gelu_out[2]  <= gelu_matrix_processor.gelu_rom[input_vector[2][15:8]];
            gelu_out[3]  <= gelu_matrix_processor.gelu_rom[input_vector[3][15:8]];
            gelu_out[4]  <= gelu_matrix_processor.gelu_rom[input_vector[4][15:8]];
            gelu_out[5]  <= gelu_matrix_processor.gelu_rom[input_vector[5][15:8]];
            gelu_out[6]  <= gelu_matrix_processor.gelu_rom[input_vector[6][15:8]];
            gelu_out[7]  <= gelu_matrix_processor.gelu_rom[input_vector[7][15:8]];
            gelu_out[8]  <= gelu_matrix_processor.gelu_rom[input_vector[8][15:8]];
            gelu_out[9]  <= gelu_matrix_processor.gelu_rom[input_vector[9][15:8]];
            gelu_out[10] <= gelu_matrix_processor.gelu_rom[input_vector[10][15:8]];
            gelu_out[11] <= gelu_matrix_processor.gelu_rom[input_vector[11][15:8]];
            gelu_out[12] <= gelu_matrix_processor.gelu_rom[input_vector[12][15:8]];
            gelu_out[13] <= gelu_matrix_processor.gelu_rom[input_vector[13][15:8]];
            gelu_out[14] <= gelu_matrix_processor.gelu_rom[input_vector[14][15:8]];
            gelu_out[15] <= gelu_matrix_processor.gelu_rom[input_vector[15][15:8]];
        end
    end
end

endmodule