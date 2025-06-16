// ===========================================
// 64-Way Parallel Max Finder Unit
// Pure Verilog-2001 Compatible
// S5.10 Fixed Point Format
// ===========================================

`timescale 1ns/1ps

module max_finder_64 (
    // 64¿?16¿?¿?¿?¿?¿?¿?¿?¿?1024¿?
    input [1023:0] data_in,  // 64 × 16 = 1024 bits
    output [15:0] max_out
);

// ===========================================
// ¿?¿?¿?¿?¿?¿?
// ===========================================
wire [15:0] level0 [31:0];  // Level 0: 64->32
wire [15:0] level1 [15:0];  // Level 1: 32->16
wire [15:0] level2 [7:0];   // Level 2: 16->8
wire [15:0] level3 [3:0];   // Level 3: 8->4
wire [15:0] level4 [1:0];   // Level 4: 4->2

// ===========================================
// Level 0: 64¿?¿?¿? -> 32¿?¿?¿?
// ===========================================
max_comparator_2 comp0_0  (.a(data_in[15:0]),     .b(data_in[31:16]),    .max_out(level0[0]));
max_comparator_2 comp0_1  (.a(data_in[47:32]),    .b(data_in[63:48]),    .max_out(level0[1]));
max_comparator_2 comp0_2  (.a(data_in[79:64]),    .b(data_in[95:80]),    .max_out(level0[2]));
max_comparator_2 comp0_3  (.a(data_in[111:96]),   .b(data_in[127:112]),  .max_out(level0[3]));
max_comparator_2 comp0_4  (.a(data_in[143:128]),  .b(data_in[159:144]),  .max_out(level0[4]));
max_comparator_2 comp0_5  (.a(data_in[175:160]),  .b(data_in[191:176]),  .max_out(level0[5]));
max_comparator_2 comp0_6  (.a(data_in[207:192]),  .b(data_in[223:208]),  .max_out(level0[6]));
max_comparator_2 comp0_7  (.a(data_in[239:224]),  .b(data_in[255:240]),  .max_out(level0[7]));
max_comparator_2 comp0_8  (.a(data_in[271:256]),  .b(data_in[287:272]),  .max_out(level0[8]));
max_comparator_2 comp0_9  (.a(data_in[303:288]),  .b(data_in[319:304]),  .max_out(level0[9]));
max_comparator_2 comp0_10 (.a(data_in[335:320]),  .b(data_in[351:336]),  .max_out(level0[10]));
max_comparator_2 comp0_11 (.a(data_in[367:352]),  .b(data_in[383:368]),  .max_out(level0[11]));
max_comparator_2 comp0_12 (.a(data_in[399:384]),  .b(data_in[415:400]),  .max_out(level0[12]));
max_comparator_2 comp0_13 (.a(data_in[431:416]),  .b(data_in[447:432]),  .max_out(level0[13]));
max_comparator_2 comp0_14 (.a(data_in[463:448]),  .b(data_in[479:464]),  .max_out(level0[14]));
max_comparator_2 comp0_15 (.a(data_in[495:480]),  .b(data_in[511:496]),  .max_out(level0[15]));
max_comparator_2 comp0_16 (.a(data_in[527:512]),  .b(data_in[543:528]),  .max_out(level0[16]));
max_comparator_2 comp0_17 (.a(data_in[559:544]),  .b(data_in[575:560]),  .max_out(level0[17]));
max_comparator_2 comp0_18 (.a(data_in[591:576]),  .b(data_in[607:592]),  .max_out(level0[18]));
max_comparator_2 comp0_19 (.a(data_in[623:608]),  .b(data_in[639:624]),  .max_out(level0[19]));
max_comparator_2 comp0_20 (.a(data_in[655:640]),  .b(data_in[671:656]),  .max_out(level0[20]));
max_comparator_2 comp0_21 (.a(data_in[687:672]),  .b(data_in[703:688]),  .max_out(level0[21]));
max_comparator_2 comp0_22 (.a(data_in[719:704]),  .b(data_in[735:720]),  .max_out(level0[22]));
max_comparator_2 comp0_23 (.a(data_in[751:736]),  .b(data_in[767:752]),  .max_out(level0[23]));
max_comparator_2 comp0_24 (.a(data_in[783:768]),  .b(data_in[799:784]),  .max_out(level0[24]));
max_comparator_2 comp0_25 (.a(data_in[815:800]),  .b(data_in[831:816]),  .max_out(level0[25]));
max_comparator_2 comp0_26 (.a(data_in[847:832]),  .b(data_in[863:848]),  .max_out(level0[26]));
max_comparator_2 comp0_27 (.a(data_in[879:864]),  .b(data_in[895:880]),  .max_out(level0[27]));
max_comparator_2 comp0_28 (.a(data_in[911:896]),  .b(data_in[927:912]),  .max_out(level0[28]));
max_comparator_2 comp0_29 (.a(data_in[943:928]),  .b(data_in[959:944]),  .max_out(level0[29]));
max_comparator_2 comp0_30 (.a(data_in[975:960]),  .b(data_in[991:976]),  .max_out(level0[30]));
max_comparator_2 comp0_31 (.a(data_in[1007:992]), .b(data_in[1023:1008]), .max_out(level0[31]));

// ===========================================
// Level 1: 32¿?¿?¿? -> 16¿?¿?¿?
// ===========================================
max_comparator_2 comp1_0  (.a(level0[0]),  .b(level0[1]),  .max_out(level1[0]));
max_comparator_2 comp1_1  (.a(level0[2]),  .b(level0[3]),  .max_out(level1[1]));
max_comparator_2 comp1_2  (.a(level0[4]),  .b(level0[5]),  .max_out(level1[2]));
max_comparator_2 comp1_3  (.a(level0[6]),  .b(level0[7]),  .max_out(level1[3]));
max_comparator_2 comp1_4  (.a(level0[8]),  .b(level0[9]),  .max_out(level1[4]));
max_comparator_2 comp1_5  (.a(level0[10]), .b(level0[11]), .max_out(level1[5]));
max_comparator_2 comp1_6  (.a(level0[12]), .b(level0[13]), .max_out(level1[6]));
max_comparator_2 comp1_7  (.a(level0[14]), .b(level0[15]), .max_out(level1[7]));
max_comparator_2 comp1_8  (.a(level0[16]), .b(level0[17]), .max_out(level1[8]));
max_comparator_2 comp1_9  (.a(level0[18]), .b(level0[19]), .max_out(level1[9]));
max_comparator_2 comp1_10 (.a(level0[20]), .b(level0[21]), .max_out(level1[10]));
max_comparator_2 comp1_11 (.a(level0[22]), .b(level0[23]), .max_out(level1[11]));
max_comparator_2 comp1_12 (.a(level0[24]), .b(level0[25]), .max_out(level1[12]));
max_comparator_2 comp1_13 (.a(level0[26]), .b(level0[27]), .max_out(level1[13]));
max_comparator_2 comp1_14 (.a(level0[28]), .b(level0[29]), .max_out(level1[14]));
max_comparator_2 comp1_15 (.a(level0[30]), .b(level0[31]), .max_out(level1[15]));

// ===========================================
// Level 2: 16¿?¿?¿? -> 8¿?¿?¿?
// ===========================================
max_comparator_2 comp2_0 (.a(level1[0]),  .b(level1[1]),  .max_out(level2[0]));
max_comparator_2 comp2_1 (.a(level1[2]),  .b(level1[3]),  .max_out(level2[1]));
max_comparator_2 comp2_2 (.a(level1[4]),  .b(level1[5]),  .max_out(level2[2]));
max_comparator_2 comp2_3 (.a(level1[6]),  .b(level1[7]),  .max_out(level2[3]));
max_comparator_2 comp2_4 (.a(level1[8]),  .b(level1[9]),  .max_out(level2[4]));
max_comparator_2 comp2_5 (.a(level1[10]), .b(level1[11]), .max_out(level2[5]));
max_comparator_2 comp2_6 (.a(level1[12]), .b(level1[13]), .max_out(level2[6]));
max_comparator_2 comp2_7 (.a(level1[14]), .b(level1[15]), .max_out(level2[7]));

// ===========================================
// Level 3: 8¿?¿?¿? -> 4¿?¿?¿?
// ===========================================
max_comparator_2 comp3_0 (.a(level2[0]), .b(level2[1]), .max_out(level3[0]));
max_comparator_2 comp3_1 (.a(level2[2]), .b(level2[3]), .max_out(level3[1]));
max_comparator_2 comp3_2 (.a(level2[4]), .b(level2[5]), .max_out(level3[2]));
max_comparator_2 comp3_3 (.a(level2[6]), .b(level2[7]), .max_out(level3[3]));

// ===========================================
// Level 4: 4¿?¿?¿? -> 2¿?¿?¿?
// ===========================================
max_comparator_2 comp4_0 (.a(level3[0]), .b(level3[1]), .max_out(level4[0]));
max_comparator_2 comp4_1 (.a(level3[2]), .b(level3[3]), .max_out(level4[1]));

// ===========================================
// Level 5: 2¿?¿?¿? -> 1¿?¿?¿? (¿?¿?¿?¿?)
// ===========================================
max_comparator_2 comp_final (.a(level4[0]), .b(level4[1]), .max_out(max_out));

endmodule

// ===========================================
// 2¿?¿?¿?¿?¿?¿? (¿?¿?S5.10¿?¿?¿?¿?)
// ===========================================
module max_comparator_2 (
    input [15:0] a,
    input [15:0] b,
    output [15:0] max_out
);

// S5.10¿?¿?¿?¿?¿?¿?
wire signed [15:0] a_signed;
wire signed [15:0] b_signed;

assign a_signed = a;
assign b_signed = b;
assign max_out = (a_signed > b_signed) ? a : b;

endmodule
