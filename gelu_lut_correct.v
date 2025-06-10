// CORRECTED GELU LUT - 256 entries (8-bit addressing)
// Usage: gelu_output = gelu_lut[q510_input[15:8]];
// Address mapping: MSB 8 bits directly index into LUT

reg [15:0] gelu_lut [0:255];

initial begin
    gelu_lut[  0] = 16'h0000; gelu_lut[  1] = 16'h0099; gelu_lut[  2] = 16'h0162; gelu_lut[  3] = 16'h0252; 
    gelu_lut[  4] = 16'h035D; gelu_lut[  5] = 16'h0479; gelu_lut[  6] = 16'h0599; gelu_lut[  7] = 16'h06B8; 
    gelu_lut[  8] = 16'h07D2; gelu_lut[  9] = 16'h08E4; gelu_lut[ 10] = 16'h09F1; gelu_lut[ 11] = 16'h0AF8; 
    gelu_lut[ 12] = 16'h0BFC; gelu_lut[ 13] = 16'h0CFE; gelu_lut[ 14] = 16'h0DFF; gelu_lut[ 15] = 16'h0F00; 
    gelu_lut[ 16] = 16'h1000; gelu_lut[ 17] = 16'h1100; gelu_lut[ 18] = 16'h1200; gelu_lut[ 19] = 16'h1300; 
    gelu_lut[ 20] = 16'h1400; gelu_lut[ 21] = 16'h1500; gelu_lut[ 22] = 16'h1600; gelu_lut[ 23] = 16'h1700; 
    gelu_lut[ 24] = 16'h1800; gelu_lut[ 25] = 16'h1900; gelu_lut[ 26] = 16'h1A00; gelu_lut[ 27] = 16'h1B00; 
    gelu_lut[ 28] = 16'h1C00; gelu_lut[ 29] = 16'h1D00; gelu_lut[ 30] = 16'h1E00; gelu_lut[ 31] = 16'h1F00; 
    gelu_lut[ 32] = 16'h2000; gelu_lut[ 33] = 16'h2100; gelu_lut[ 34] = 16'h2200; gelu_lut[ 35] = 16'h2300; 
    gelu_lut[ 36] = 16'h2400; gelu_lut[ 37] = 16'h2500; gelu_lut[ 38] = 16'h2600; gelu_lut[ 39] = 16'h2700; 
    gelu_lut[ 40] = 16'h2800; gelu_lut[ 41] = 16'h2900; gelu_lut[ 42] = 16'h2A00; gelu_lut[ 43] = 16'h2B00; 
    gelu_lut[ 44] = 16'h2C00; gelu_lut[ 45] = 16'h2D00; gelu_lut[ 46] = 16'h2E00; gelu_lut[ 47] = 16'h2F00; 
    gelu_lut[ 48] = 16'h3000; gelu_lut[ 49] = 16'h3100; gelu_lut[ 50] = 16'h3200; gelu_lut[ 51] = 16'h3300; 
    gelu_lut[ 52] = 16'h3400; gelu_lut[ 53] = 16'h3500; gelu_lut[ 54] = 16'h3600; gelu_lut[ 55] = 16'h3700; 
    gelu_lut[ 56] = 16'h3800; gelu_lut[ 57] = 16'h3900; gelu_lut[ 58] = 16'h3A00; gelu_lut[ 59] = 16'h3B00; 
    gelu_lut[ 60] = 16'h3C00; gelu_lut[ 61] = 16'h3D00; gelu_lut[ 62] = 16'h3E00; gelu_lut[ 63] = 16'h3F00; 
    gelu_lut[ 64] = 16'h4000; gelu_lut[ 65] = 16'h4100; gelu_lut[ 66] = 16'h4200; gelu_lut[ 67] = 16'h4300; 
    gelu_lut[ 68] = 16'h4400; gelu_lut[ 69] = 16'h4500; gelu_lut[ 70] = 16'h4600; gelu_lut[ 71] = 16'h4700; 
    gelu_lut[ 72] = 16'h4800; gelu_lut[ 73] = 16'h4900; gelu_lut[ 74] = 16'h4A00; gelu_lut[ 75] = 16'h4B00; 
    gelu_lut[ 76] = 16'h4C00; gelu_lut[ 77] = 16'h4D00; gelu_lut[ 78] = 16'h4E00; gelu_lut[ 79] = 16'h4F00; 
    gelu_lut[ 80] = 16'h5000; gelu_lut[ 81] = 16'h5100; gelu_lut[ 82] = 16'h5200; gelu_lut[ 83] = 16'h5300; 
    gelu_lut[ 84] = 16'h5400; gelu_lut[ 85] = 16'h5500; gelu_lut[ 86] = 16'h5600; gelu_lut[ 87] = 16'h5700; 
    gelu_lut[ 88] = 16'h5800; gelu_lut[ 89] = 16'h5900; gelu_lut[ 90] = 16'h5A00; gelu_lut[ 91] = 16'h5B00; 
    gelu_lut[ 92] = 16'h5C00; gelu_lut[ 93] = 16'h5D00; gelu_lut[ 94] = 16'h5E00; gelu_lut[ 95] = 16'h5F00; 
    gelu_lut[ 96] = 16'h6000; gelu_lut[ 97] = 16'h6100; gelu_lut[ 98] = 16'h6200; gelu_lut[ 99] = 16'h6300; 
    gelu_lut[100] = 16'h6400; gelu_lut[101] = 16'h6500; gelu_lut[102] = 16'h6600; gelu_lut[103] = 16'h6700; 
    gelu_lut[104] = 16'h6800; gelu_lut[105] = 16'h6900; gelu_lut[106] = 16'h6A00; gelu_lut[107] = 16'h6B00; 
    gelu_lut[108] = 16'h6C00; gelu_lut[109] = 16'h6D00; gelu_lut[110] = 16'h6E00; gelu_lut[111] = 16'h6F00; 
    gelu_lut[112] = 16'h7000; gelu_lut[113] = 16'h7100; gelu_lut[114] = 16'h7200; gelu_lut[115] = 16'h7300; 
    gelu_lut[116] = 16'h7400; gelu_lut[117] = 16'h7500; gelu_lut[118] = 16'h7600; gelu_lut[119] = 16'h7700; 
    gelu_lut[120] = 16'h7800; gelu_lut[121] = 16'h7900; gelu_lut[122] = 16'h7A00; gelu_lut[123] = 16'h7B00; 
    gelu_lut[124] = 16'h7C00; gelu_lut[125] = 16'h7D00; gelu_lut[126] = 16'h7E00; gelu_lut[127] = 16'h7F00; 
    gelu_lut[128] = 16'h0000; gelu_lut[129] = 16'h0000; gelu_lut[130] = 16'h0000; gelu_lut[131] = 16'h0000; 
    gelu_lut[132] = 16'h0000; gelu_lut[133] = 16'h0000; gelu_lut[134] = 16'h0000; gelu_lut[135] = 16'h0000; 
    gelu_lut[136] = 16'h0000; gelu_lut[137] = 16'h0000; gelu_lut[138] = 16'h0000; gelu_lut[139] = 16'h0000; 
    gelu_lut[140] = 16'h0000; gelu_lut[141] = 16'h0000; gelu_lut[142] = 16'h0000; gelu_lut[143] = 16'h0000; 
    gelu_lut[144] = 16'h0000; gelu_lut[145] = 16'h0000; gelu_lut[146] = 16'h0000; gelu_lut[147] = 16'h0000; 
    gelu_lut[148] = 16'h0000; gelu_lut[149] = 16'h0000; gelu_lut[150] = 16'h0000; gelu_lut[151] = 16'h0000; 
    gelu_lut[152] = 16'h0000; gelu_lut[153] = 16'h0000; gelu_lut[154] = 16'h0000; gelu_lut[155] = 16'h0000; 
    gelu_lut[156] = 16'h0000; gelu_lut[157] = 16'h0000; gelu_lut[158] = 16'h0000; gelu_lut[159] = 16'h0000; 
    gelu_lut[160] = 16'h0000; gelu_lut[161] = 16'h0000; gelu_lut[162] = 16'h0000; gelu_lut[163] = 16'h0000; 
    gelu_lut[164] = 16'h0000; gelu_lut[165] = 16'h0000; gelu_lut[166] = 16'h0000; gelu_lut[167] = 16'h0000; 
    gelu_lut[168] = 16'h0000; gelu_lut[169] = 16'h0000; gelu_lut[170] = 16'h0000; gelu_lut[171] = 16'h0000; 
    gelu_lut[172] = 16'h0000; gelu_lut[173] = 16'h0000; gelu_lut[174] = 16'h0000; gelu_lut[175] = 16'h0000; 
    gelu_lut[176] = 16'h0000; gelu_lut[177] = 16'h0000; gelu_lut[178] = 16'h0000; gelu_lut[179] = 16'h0000; 
    gelu_lut[180] = 16'h0000; gelu_lut[181] = 16'h0000; gelu_lut[182] = 16'h0000; gelu_lut[183] = 16'h0000; 
    gelu_lut[184] = 16'h0000; gelu_lut[185] = 16'h0000; gelu_lut[186] = 16'h0000; gelu_lut[187] = 16'h0000; 
    gelu_lut[188] = 16'h0000; gelu_lut[189] = 16'h0000; gelu_lut[190] = 16'h0000; gelu_lut[191] = 16'h0000; 
    gelu_lut[192] = 16'h0000; gelu_lut[193] = 16'h0000; gelu_lut[194] = 16'h0000; gelu_lut[195] = 16'h0000; 
    gelu_lut[196] = 16'h0000; gelu_lut[197] = 16'h0000; gelu_lut[198] = 16'h0000; gelu_lut[199] = 16'h0000; 
    gelu_lut[200] = 16'h0000; gelu_lut[201] = 16'h0000; gelu_lut[202] = 16'h0000; gelu_lut[203] = 16'h0000; 
    gelu_lut[204] = 16'h0000; gelu_lut[205] = 16'h0000; gelu_lut[206] = 16'h0000; gelu_lut[207] = 16'h0000; 
    gelu_lut[208] = 16'h0000; gelu_lut[209] = 16'h0000; gelu_lut[210] = 16'h0000; gelu_lut[211] = 16'h0000; 
    gelu_lut[212] = 16'h0000; gelu_lut[213] = 16'h0000; gelu_lut[214] = 16'h0000; gelu_lut[215] = 16'h0000; 
    gelu_lut[216] = 16'h0000; gelu_lut[217] = 16'h0000; gelu_lut[218] = 16'h0000; gelu_lut[219] = 16'h0000; 
    gelu_lut[220] = 16'h0000; gelu_lut[221] = 16'h0000; gelu_lut[222] = 16'h0000; gelu_lut[223] = 16'h0000; 
    gelu_lut[224] = 16'h0000; gelu_lut[225] = 16'h0000; gelu_lut[226] = 16'h0000; gelu_lut[227] = 16'h0000; 
    gelu_lut[228] = 16'h0000; gelu_lut[229] = 16'h0000; gelu_lut[230] = 16'h0000; gelu_lut[231] = 16'h0000; 
    gelu_lut[232] = 16'h0000; gelu_lut[233] = 16'h0000; gelu_lut[234] = 16'h0000; gelu_lut[235] = 16'h0000; 
    gelu_lut[236] = 16'h0000; gelu_lut[237] = 16'h0000; gelu_lut[238] = 16'h0000; gelu_lut[239] = 16'h0000; 
    gelu_lut[240] = 16'h0000; gelu_lut[241] = 16'h0000; gelu_lut[242] = 16'hFFFF; gelu_lut[243] = 16'hFFFE; 
    gelu_lut[244] = 16'hFFFC; gelu_lut[245] = 16'hFFF8; gelu_lut[246] = 16'hFFF1; gelu_lut[247] = 16'hFFE4; 
    gelu_lut[248] = 16'hFFD2; gelu_lut[249] = 16'hFFB8; gelu_lut[250] = 16'hFF99; gelu_lut[251] = 16'hFF79; 
    gelu_lut[252] = 16'hFF5D; gelu_lut[253] = 16'hFF52; gelu_lut[254] = 16'hFF62; gelu_lut[255] = 16'hFF99; 
end

// Address mapping examples:
// Input 0.0 (0x0000) -> Address 0x00 -> LUT[0]
// Input 1.0 (0x0400) -> Address 0x04 -> LUT[4]
// Input -1.0 (0xFC00) -> Address 0xFC -> LUT[252]
