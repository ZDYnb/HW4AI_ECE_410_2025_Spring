// Softmax Frontend Module - 真正的流水线设计 (Q5.10格式)
// 功能：EXP LUT查找 + 树形加法器求和
// Stage 0: EXP LUT查找 (16个并行查找)
// Stage 1: Tree Level 1 (16→8加法)
// Stage 2: Tree Level 2 (8→4加法)  
// Stage 3: Tree Level 3 (4→2加法)
// Stage 4: Tree Level 4 (2→1加法)
// Stage 5: 输出 (exp_values + exp_sum)

module softmax_frontend (
    input clk,
    input rst_n,
    
    // 流水线控制接口
    input valid_in,                     // 输入有效信号
    input [15:0] input_vector [0:15],   // 输入向量 (Q5.10格式)
    
    // 流水线输出接口  
    output reg valid_out,               // 输出有效信号
    output reg [15:0] exp_values [0:15], // EXP值向量 (Q5.10格式)
    output reg [31:0] exp_sum           // EXP值总和 (扩展精度)
);

// =============================================================================
// EXP LUT - 256 entries (使用高8位作为地址)
// =============================================================================
reg [15:0] exp_lut_rom [0:255];

// LUT地址提取 (Q5.10输入的高8位)
wire [7:0] exp_lut_addr [0:15];
wire [15:0] exp_lut_out [0:15];

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : exp_lut_gen
        assign exp_lut_addr[i] = input_vector[i][15:8];  // 高8位
        assign exp_lut_out[i] = exp_lut_rom[exp_lut_addr[i]];
    end
endgenerate

// =============================================================================
// 流水线数据结构
// =============================================================================

// Stage valid信号
reg valid_stage [0:5];  // Stage 0-5

// Stage 0: EXP LUT查找结果
reg [15:0] exp_s0 [0:15];

// Stage 1: Tree Level 1结果 (16→8)  
reg [16:0] tree_l1_s1 [0:7];   // 17位处理溢出

// Stage 2: Tree Level 2结果 (8→4)
reg [17:0] tree_l2_s2 [0:3];   // 18位

// Stage 3: Tree Level 3结果 (4→2)  
reg [18:0] tree_l3_s3 [0:1];   // 19位

// Stage 4: Tree Level 4结果 (2→1)
reg [19:0] tree_l4_s4;         // 20位

// Stage 5: 最终输出准备
reg [15:0] exp_final_s5 [0:15]; // exp_values的最终副本

// 临时计算变量
reg [16:0] temp_l1 [0:7];
reg [17:0] temp_l2 [0:3];  
reg [18:0] temp_l3 [0:1];
reg [19:0] temp_l4;

// =============================================================================
// 主流水线逻辑
// =============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有valid信号
        integer j;
        for (j = 0; j <= 5; j = j + 1) begin
            valid_stage[j] <= 1'b0;
        end
        valid_out <= 1'b0;
        
    end else begin
        
        // ================================================================
        // Stage 0: EXP LUT查找 + 保存exp_values到流水线
        // ================================================================
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            // EXP LUT查找 (组合逻辑，立即可用)
            exp_s0[0]  <= exp_lut_out[0];
            exp_s0[1]  <= exp_lut_out[1];
            exp_s0[2]  <= exp_lut_out[2];
            exp_s0[3]  <= exp_lut_out[3];
            exp_s0[4]  <= exp_lut_out[4];
            exp_s0[5]  <= exp_lut_out[5];
            exp_s0[6]  <= exp_lut_out[6];
            exp_s0[7]  <= exp_lut_out[7];
            exp_s0[8]  <= exp_lut_out[8];
            exp_s0[9]  <= exp_lut_out[9];
            exp_s0[10] <= exp_lut_out[10];
            exp_s0[11] <= exp_lut_out[11];
            exp_s0[12] <= exp_lut_out[12];
            exp_s0[13] <= exp_lut_out[13];
            exp_s0[14] <= exp_lut_out[14];
            exp_s0[15] <= exp_lut_out[15];
        end
        
        // ================================================================
        // Stage 1: Tree Level 1 (16→8加法) + exp_values流水传递
        // ================================================================
        valid_stage[1] <= valid_stage[0];
        if (valid_stage[0]) begin
            // Tree Level 1计算 (使用组合逻辑先计算，再寄存)
            temp_l1[0] = exp_s0[0]  + exp_s0[1];
            temp_l1[1] = exp_s0[2]  + exp_s0[3];
            temp_l1[2] = exp_s0[4]  + exp_s0[5];
            temp_l1[3] = exp_s0[6]  + exp_s0[7];
            temp_l1[4] = exp_s0[8]  + exp_s0[9];
            temp_l1[5] = exp_s0[10] + exp_s0[11];
            temp_l1[6] = exp_s0[12] + exp_s0[13];
            temp_l1[7] = exp_s0[14] + exp_s0[15];
            
            tree_l1_s1[0] <= temp_l1[0];
            tree_l1_s1[1] <= temp_l1[1];
            tree_l1_s1[2] <= temp_l1[2];
            tree_l1_s1[3] <= temp_l1[3];
            tree_l1_s1[4] <= temp_l1[4];
            tree_l1_s1[5] <= temp_l1[5];
            tree_l1_s1[6] <= temp_l1[6];
            tree_l1_s1[7] <= temp_l1[7];
        end
        
        // ================================================================
        // Stage 2: Tree Level 2 (8→4加法)
        // ================================================================
        valid_stage[2] <= valid_stage[1];
        if (valid_stage[1]) begin
            // Tree Level 2计算
            temp_l2[0] = tree_l1_s1[0] + tree_l1_s1[1];
            temp_l2[1] = tree_l1_s1[2] + tree_l1_s1[3];
            temp_l2[2] = tree_l1_s1[4] + tree_l1_s1[5];
            temp_l2[3] = tree_l1_s1[6] + tree_l1_s1[7];
            
            tree_l2_s2[0] <= temp_l2[0];
            tree_l2_s2[1] <= temp_l2[1];
            tree_l2_s2[2] <= temp_l2[2];
            tree_l2_s2[3] <= temp_l2[3];
        end
        
        // ================================================================
        // Stage 3: Tree Level 3 (4→2加法)
        // ================================================================
        valid_stage[3] <= valid_stage[2];
        if (valid_stage[2]) begin
            // Tree Level 3计算
            temp_l3[0] = tree_l2_s2[0] + tree_l2_s2[1];
            temp_l3[1] = tree_l2_s2[2] + tree_l2_s2[3];
            
            tree_l3_s3[0] <= temp_l3[0];
            tree_l3_s3[1] <= temp_l3[1];
        end
        
        // ================================================================
        // Stage 4: Tree Level 4 (2→1加法)
        // ================================================================
        valid_stage[4] <= valid_stage[3];
        if (valid_stage[3]) begin
            // Tree Level 4计算 (最终求和)
            temp_l4 = tree_l3_s3[0] + tree_l3_s3[1];
            tree_l4_s4 <= temp_l4;
        end
        
        // ================================================================
        // Stage 5: 输出准备 + exp_values恢复
        // ================================================================
        valid_stage[5] <= valid_stage[4];
        if (valid_stage[4]) begin
            // 准备最终输出 (exp_sum直接来自tree_l4_s4)
            // 注意: exp_values需要从Stage 0传递过来
            // 这里我们需要添加exp_values的流水线传递
        end
        
        // ================================================================
        // 输出: 最终结果
        // ================================================================
        valid_out <= valid_stage[5];
        if (valid_stage[5]) begin
            exp_sum <= {12'h000, tree_l4_s4};  // 高12位填0，低20位是结果
            // exp_values <= exp_final_s5;  // 来自流水线传递
        end
        
    end
end

// =============================================================================
// exp_values流水线传递 (单独的always块)
// =============================================================================
// 需要将exp_values从Stage 0传递到Stage 5
reg [15:0] exp_s1 [0:15], exp_s2 [0:15], exp_s3 [0:15], exp_s4 [0:15];

always @(posedge clk or negedge rst_n) begin
    integer k;
    if (!rst_n) begin
        for (k = 0; k < 16; k = k + 1) begin
            exp_values[k] <= 16'h0;
        end
    end else begin
        // exp_values流水线传递 - 逐个元素赋值
        if (valid_stage[0]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_s1[k] <= exp_s0[k];
            end
        end
        
        if (valid_stage[1]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_s2[k] <= exp_s1[k];
            end
        end
        
        if (valid_stage[2]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_s3[k] <= exp_s2[k];
            end
        end
        
        if (valid_stage[3]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_s4[k] <= exp_s3[k];
            end
        end
        
        if (valid_stage[4]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_final_s5[k] <= exp_s4[k];
            end
        end
        
        if (valid_stage[5]) begin
            for (k = 0; k < 16; k = k + 1) begin
                exp_values[k] <= exp_final_s5[k];
            end
        end
    end
end

// =============================================================================
// EXP LUT初始化 - Python生成的值
// =============================================================================
initial begin
    exp_lut_rom[  0] = 16'h0400; exp_lut_rom[  1] = 16'h0522; exp_lut_rom[  2] = 16'h0698; exp_lut_rom[  3] = 16'h0877; exp_lut_rom[  4] = 16'h0ADF; exp_lut_rom[  5] = 16'h0DF6; exp_lut_rom[  6] = 16'h11ED; exp_lut_rom[  7] = 16'h1704; 
    exp_lut_rom[  8] = 16'h1D8E; exp_lut_rom[  9] = 16'h25F3; exp_lut_rom[ 10] = 16'h30BA; exp_lut_rom[ 11] = 16'h3E92; exp_lut_rom[ 12] = 16'h5057; exp_lut_rom[ 13] = 16'h6729; exp_lut_rom[ 14] = 16'h7FFB; exp_lut_rom[ 15] = 16'h7FFB; 
    exp_lut_rom[ 16] = 16'h7FFB; exp_lut_rom[ 17] = 16'h7FFB; exp_lut_rom[ 18] = 16'h7FFB; exp_lut_rom[ 19] = 16'h7FFB; exp_lut_rom[ 20] = 16'h7FFB; exp_lut_rom[ 21] = 16'h7FFB; exp_lut_rom[ 22] = 16'h7FFB; exp_lut_rom[ 23] = 16'h7FFB; 
    exp_lut_rom[ 24] = 16'h7FFB; exp_lut_rom[ 25] = 16'h7FFB; exp_lut_rom[ 26] = 16'h7FFB; exp_lut_rom[ 27] = 16'h7FFB; exp_lut_rom[ 28] = 16'h7FFB; exp_lut_rom[ 29] = 16'h7FFB; exp_lut_rom[ 30] = 16'h7FFB; exp_lut_rom[ 31] = 16'h7FFB; 
    exp_lut_rom[ 32] = 16'h7FFB; exp_lut_rom[ 33] = 16'h7FFB; exp_lut_rom[ 34] = 16'h7FFB; exp_lut_rom[ 35] = 16'h7FFB; exp_lut_rom[ 36] = 16'h7FFB; exp_lut_rom[ 37] = 16'h7FFB; exp_lut_rom[ 38] = 16'h7FFB; exp_lut_rom[ 39] = 16'h7FFB; 
    exp_lut_rom[ 40] = 16'h7FFB; exp_lut_rom[ 41] = 16'h7FFB; exp_lut_rom[ 42] = 16'h7FFB; exp_lut_rom[ 43] = 16'h7FFB; exp_lut_rom[ 44] = 16'h7FFB; exp_lut_rom[ 45] = 16'h7FFB; exp_lut_rom[ 46] = 16'h7FFB; exp_lut_rom[ 47] = 16'h7FFB; 
    exp_lut_rom[ 48] = 16'h7FFB; exp_lut_rom[ 49] = 16'h7FFB; exp_lut_rom[ 50] = 16'h7FFB; exp_lut_rom[ 51] = 16'h7FFB; exp_lut_rom[ 52] = 16'h7FFB; exp_lut_rom[ 53] = 16'h7FFB; exp_lut_rom[ 54] = 16'h7FFB; exp_lut_rom[ 55] = 16'h7FFB; 
    exp_lut_rom[ 56] = 16'h7FFB; exp_lut_rom[ 57] = 16'h7FFB; exp_lut_rom[ 58] = 16'h7FFB; exp_lut_rom[ 59] = 16'h7FFB; exp_lut_rom[ 60] = 16'h7FFB; exp_lut_rom[ 61] = 16'h7FFB; exp_lut_rom[ 62] = 16'h7FFB; exp_lut_rom[ 63] = 16'h7FFB; 
    exp_lut_rom[ 64] = 16'h7FFB; exp_lut_rom[ 65] = 16'h7FFB; exp_lut_rom[ 66] = 16'h7FFB; exp_lut_rom[ 67] = 16'h7FFB; exp_lut_rom[ 68] = 16'h7FFB; exp_lut_rom[ 69] = 16'h7FFB; exp_lut_rom[ 70] = 16'h7FFB; exp_lut_rom[ 71] = 16'h7FFB; 
    exp_lut_rom[ 72] = 16'h7FFB; exp_lut_rom[ 73] = 16'h7FFB; exp_lut_rom[ 74] = 16'h7FFB; exp_lut_rom[ 75] = 16'h7FFB; exp_lut_rom[ 76] = 16'h7FFB; exp_lut_rom[ 77] = 16'h7FFB; exp_lut_rom[ 78] = 16'h7FFB; exp_lut_rom[ 79] = 16'h7FFB; 
    exp_lut_rom[ 80] = 16'h7FFB; exp_lut_rom[ 81] = 16'h7FFB; exp_lut_rom[ 82] = 16'h7FFB; exp_lut_rom[ 83] = 16'h7FFB; exp_lut_rom[ 84] = 16'h7FFB; exp_lut_rom[ 85] = 16'h7FFB; exp_lut_rom[ 86] = 16'h7FFB; exp_lut_rom[ 87] = 16'h7FFB; 
    exp_lut_rom[ 88] = 16'h7FFB; exp_lut_rom[ 89] = 16'h7FFB; exp_lut_rom[ 90] = 16'h7FFB; exp_lut_rom[ 91] = 16'h7FFB; exp_lut_rom[ 92] = 16'h7FFB; exp_lut_rom[ 93] = 16'h7FFB; exp_lut_rom[ 94] = 16'h7FFB; exp_lut_rom[ 95] = 16'h7FFB; 
    exp_lut_rom[ 96] = 16'h7FFB; exp_lut_rom[ 97] = 16'h7FFB; exp_lut_rom[ 98] = 16'h7FFB; exp_lut_rom[ 99] = 16'h7FFB; exp_lut_rom[100] = 16'h7FFB; exp_lut_rom[101] = 16'h7FFB; exp_lut_rom[102] = 16'h7FFB; exp_lut_rom[103] = 16'h7FFB; 
    exp_lut_rom[104] = 16'h7FFB; exp_lut_rom[105] = 16'h7FFB; exp_lut_rom[106] = 16'h7FFB; exp_lut_rom[107] = 16'h7FFB; exp_lut_rom[108] = 16'h7FFB; exp_lut_rom[109] = 16'h7FFB; exp_lut_rom[110] = 16'h7FFB; exp_lut_rom[111] = 16'h7FFB; 
    exp_lut_rom[112] = 16'h7FFB; exp_lut_rom[113] = 16'h7FFB; exp_lut_rom[114] = 16'h7FFB; exp_lut_rom[115] = 16'h7FFB; exp_lut_rom[116] = 16'h7FFB; exp_lut_rom[117] = 16'h7FFB; exp_lut_rom[118] = 16'h7FFB; exp_lut_rom[119] = 16'h7FFB; 
    exp_lut_rom[120] = 16'h7FFB; exp_lut_rom[121] = 16'h7FFB; exp_lut_rom[122] = 16'h7FFB; exp_lut_rom[123] = 16'h7FFB; exp_lut_rom[124] = 16'h7FFB; exp_lut_rom[125] = 16'h7FFB; exp_lut_rom[126] = 16'h7FFB; exp_lut_rom[127] = 16'h7FFB; 
    exp_lut_rom[128] = 16'h0000; exp_lut_rom[129] = 16'h0000; exp_lut_rom[130] = 16'h0000; exp_lut_rom[131] = 16'h0000; exp_lut_rom[132] = 16'h0000; exp_lut_rom[133] = 16'h0000; exp_lut_rom[134] = 16'h0000; exp_lut_rom[135] = 16'h0000; 
    exp_lut_rom[136] = 16'h0000; exp_lut_rom[137] = 16'h0000; exp_lut_rom[138] = 16'h0000; exp_lut_rom[139] = 16'h0000; exp_lut_rom[140] = 16'h0000; exp_lut_rom[141] = 16'h0000; exp_lut_rom[142] = 16'h0000; exp_lut_rom[143] = 16'h0000; 
    exp_lut_rom[144] = 16'h0000; exp_lut_rom[145] = 16'h0000; exp_lut_rom[146] = 16'h0000; exp_lut_rom[147] = 16'h0000; exp_lut_rom[148] = 16'h0000; exp_lut_rom[149] = 16'h0000; exp_lut_rom[150] = 16'h0000; exp_lut_rom[151] = 16'h0000; 
    exp_lut_rom[152] = 16'h0000; exp_lut_rom[153] = 16'h0000; exp_lut_rom[154] = 16'h0000; exp_lut_rom[155] = 16'h0000; exp_lut_rom[156] = 16'h0000; exp_lut_rom[157] = 16'h0000; exp_lut_rom[158] = 16'h0000; exp_lut_rom[159] = 16'h0000; 
    exp_lut_rom[160] = 16'h0000; exp_lut_rom[161] = 16'h0000; exp_lut_rom[162] = 16'h0000; exp_lut_rom[163] = 16'h0000; exp_lut_rom[164] = 16'h0000; exp_lut_rom[165] = 16'h0000; exp_lut_rom[166] = 16'h0000; exp_lut_rom[167] = 16'h0000; 
    exp_lut_rom[168] = 16'h0000; exp_lut_rom[169] = 16'h0000; exp_lut_rom[170] = 16'h0000; exp_lut_rom[171] = 16'h0000; exp_lut_rom[172] = 16'h0000; exp_lut_rom[173] = 16'h0000; exp_lut_rom[174] = 16'h0000; exp_lut_rom[175] = 16'h0000; 
    exp_lut_rom[176] = 16'h0000; exp_lut_rom[177] = 16'h0000; exp_lut_rom[178] = 16'h0000; exp_lut_rom[179] = 16'h0000; exp_lut_rom[180] = 16'h0000; exp_lut_rom[181] = 16'h0000; exp_lut_rom[182] = 16'h0000; exp_lut_rom[183] = 16'h0000; 
    exp_lut_rom[184] = 16'h0000; exp_lut_rom[185] = 16'h0000; exp_lut_rom[186] = 16'h0000; exp_lut_rom[187] = 16'h0000; exp_lut_rom[188] = 16'h0000; exp_lut_rom[189] = 16'h0000; exp_lut_rom[190] = 16'h0000; exp_lut_rom[191] = 16'h0000; 
    exp_lut_rom[192] = 16'h0000; exp_lut_rom[193] = 16'h0000; exp_lut_rom[194] = 16'h0000; exp_lut_rom[195] = 16'h0000; exp_lut_rom[196] = 16'h0000; exp_lut_rom[197] = 16'h0000; exp_lut_rom[198] = 16'h0000; exp_lut_rom[199] = 16'h0000; 
    exp_lut_rom[200] = 16'h0000; exp_lut_rom[201] = 16'h0000; exp_lut_rom[202] = 16'h0000; exp_lut_rom[203] = 16'h0000; exp_lut_rom[204] = 16'h0000; exp_lut_rom[205] = 16'h0000; exp_lut_rom[206] = 16'h0000; exp_lut_rom[207] = 16'h0000; 
    exp_lut_rom[208] = 16'h0000; exp_lut_rom[209] = 16'h0000; exp_lut_rom[210] = 16'h0000; exp_lut_rom[211] = 16'h0000; exp_lut_rom[212] = 16'h0000; exp_lut_rom[213] = 16'h0000; exp_lut_rom[214] = 16'h0000; exp_lut_rom[215] = 16'h0000; 
    exp_lut_rom[216] = 16'h0000; exp_lut_rom[217] = 16'h0000; exp_lut_rom[218] = 16'h0000; exp_lut_rom[219] = 16'h0000; exp_lut_rom[220] = 16'h0000; exp_lut_rom[221] = 16'h0000; exp_lut_rom[222] = 16'h0000; exp_lut_rom[223] = 16'h0000; 
    exp_lut_rom[224] = 16'h0000; exp_lut_rom[225] = 16'h0000; exp_lut_rom[226] = 16'h0000; exp_lut_rom[227] = 16'h0000; exp_lut_rom[228] = 16'h0000; exp_lut_rom[229] = 16'h0001; exp_lut_rom[230] = 16'h0001; exp_lut_rom[231] = 16'h0001; 
    exp_lut_rom[232] = 16'h0002; exp_lut_rom[233] = 16'h0003; exp_lut_rom[234] = 16'h0004; exp_lut_rom[235] = 16'h0005; exp_lut_rom[236] = 16'h0006; exp_lut_rom[237] = 16'h0008; exp_lut_rom[238] = 16'h000B; exp_lut_rom[239] = 16'h000E; 
    exp_lut_rom[240] = 16'h0012; exp_lut_rom[241] = 16'h0018; exp_lut_rom[242] = 16'h001E; exp_lut_rom[243] = 16'h0027; exp_lut_rom[244] = 16'h0032; exp_lut_rom[245] = 16'h0041; exp_lut_rom[246] = 16'h0054; exp_lut_rom[247] = 16'h006B; 
    exp_lut_rom[248] = 16'h008A; exp_lut_rom[249] = 16'h00B1; exp_lut_rom[250] = 16'h00E4; exp_lut_rom[251] = 16'h0125; exp_lut_rom[252] = 16'h0178; exp_lut_rom[253] = 16'h01E3; exp_lut_rom[254] = 16'h026D; exp_lut_rom[255] = 16'h031D;
end

endmodule