// ===========================================
// Max Finder 64 Testbench
// Pure Verilog-2001 Compatible
// S5.10 Fixed Point Format Testing
// ===========================================

`timescale 1ns/1ps

module tb_max_finder_64;

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
parameter WIDTH = 16;
parameter INPUTS = 64;
parameter FRAC_BITS = 10;

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
reg [WIDTH-1:0] data_in [INPUTS-1:0];
reg [1023:0] data_in_flat;  // 64 × 16 = 1024 bits
wire [WIDTH-1:0] max_out;

// ¿?¿?¿?¿?¿?¿?¿?
reg [WIDTH-1:0] software_max;
integer i, j;

// ===========================================
// ¿?¿?¿?¿?¿?¿?¿?¿?¿?¿?
// ===========================================
always @(*) begin
    data_in_flat[15:0]     = data_in[0];
    data_in_flat[31:16]    = data_in[1];
    data_in_flat[47:32]    = data_in[2];
    data_in_flat[63:48]    = data_in[3];
    data_in_flat[79:64]    = data_in[4];
    data_in_flat[95:80]    = data_in[5];
    data_in_flat[111:96]   = data_in[6];
    data_in_flat[127:112]  = data_in[7];
    data_in_flat[143:128]  = data_in[8];
    data_in_flat[159:144]  = data_in[9];
    data_in_flat[175:160]  = data_in[10];
    data_in_flat[191:176]  = data_in[11];
    data_in_flat[207:192]  = data_in[12];
    data_in_flat[223:208]  = data_in[13];
    data_in_flat[239:224]  = data_in[14];
    data_in_flat[255:240]  = data_in[15];
    data_in_flat[271:256]  = data_in[16];
    data_in_flat[287:272]  = data_in[17];
    data_in_flat[303:288]  = data_in[18];
    data_in_flat[319:304]  = data_in[19];
    data_in_flat[335:320]  = data_in[20];
    data_in_flat[351:336]  = data_in[21];
    data_in_flat[367:352]  = data_in[22];
    data_in_flat[383:368]  = data_in[23];
    data_in_flat[399:384]  = data_in[24];
    data_in_flat[415:400]  = data_in[25];
    data_in_flat[431:416]  = data_in[26];
    data_in_flat[447:432]  = data_in[27];
    data_in_flat[463:448]  = data_in[28];
    data_in_flat[479:464]  = data_in[29];
    data_in_flat[495:480]  = data_in[30];
    data_in_flat[511:496]  = data_in[31];
    data_in_flat[527:512]  = data_in[32];
    data_in_flat[543:528]  = data_in[33];
    data_in_flat[559:544]  = data_in[34];
    data_in_flat[575:560]  = data_in[35];
    data_in_flat[591:576]  = data_in[36];
    data_in_flat[607:592]  = data_in[37];
    data_in_flat[623:608]  = data_in[38];
    data_in_flat[639:624]  = data_in[39];
    data_in_flat[655:640]  = data_in[40];
    data_in_flat[671:656]  = data_in[41];
    data_in_flat[687:672]  = data_in[42];
    data_in_flat[703:688]  = data_in[43];
    data_in_flat[719:704]  = data_in[44];
    data_in_flat[735:720]  = data_in[45];
    data_in_flat[751:736]  = data_in[46];
    data_in_flat[767:752]  = data_in[47];
    data_in_flat[783:768]  = data_in[48];
    data_in_flat[799:784]  = data_in[49];
    data_in_flat[815:800]  = data_in[50];
    data_in_flat[831:816]  = data_in[51];
    data_in_flat[847:832]  = data_in[52];
    data_in_flat[863:848]  = data_in[53];
    data_in_flat[879:864]  = data_in[54];
    data_in_flat[895:880]  = data_in[55];
    data_in_flat[911:896]  = data_in[56];
    data_in_flat[927:912]  = data_in[57];
    data_in_flat[943:928]  = data_in[58];
    data_in_flat[959:944]  = data_in[59];
    data_in_flat[975:960]  = data_in[60];
    data_in_flat[991:976]  = data_in[61];
    data_in_flat[1007:992] = data_in[62];
    data_in_flat[1023:1008] = data_in[63];
end

// ===========================================
// DUT¿?¿?¿?
// ===========================================
max_finder_64 dut (
    .data_in(data_in_flat),
    .max_out(max_out)
);

// ===========================================
// S5.10¿?¿?¿?¿?¿?¿?
// ===========================================
function real s5p10_to_real;
    input [WIDTH-1:0] fixed_val;
    reg signed [WIDTH-1:0] signed_val;
    begin
        signed_val = fixed_val;
        s5p10_to_real = $itor(signed_val) / 1024.0;  // 2^10 = 1024
    end
endfunction

function [WIDTH-1:0] real_to_s5p10;
    input real real_val;
    begin
        real_to_s5p10 = $rtoi(real_val * 1024.0);
    end
endfunction

// ===========================================
// ¿?¿?¿?¿?¿?¿?
// ===========================================
task find_max_software;
    reg signed [WIDTH-1:0] temp_a, temp_b;
    begin
        software_max = data_in[0];
        for (i = 1; i < INPUTS; i = i + 1) begin
            temp_a = data_in[i];
            temp_b = software_max;
            if (temp_a > temp_b) begin
                software_max = data_in[i];
            end
        end
    end
endtask

// ===========================================
// ¿?¿?¿?¿?¿?¿?¿?¿?
// ===========================================
task generate_test_data;
    input integer test_type;
    begin
        case (test_type)
            0: begin // ¿?¿?¿?¿?¿?
                $display("=== Test 0: All Positive Numbers ===");
                for (i = 0; i < INPUTS; i = i + 1) begin
                    data_in[i] = real_to_s5p10(($random % 1000) / 100.0);
                end
                data_in[32] = real_to_s5p10(15.999); // ¿?¿?¿?¿?¿?
            end
            
            1: begin // ¿?¿?¿?¿?¿?
                $display("=== Test 1: All Negative Numbers ===");
                for (i = 0; i < INPUTS; i = i + 1) begin
                    data_in[i] = real_to_s5p10(-(($random % 1000) / 100.0));
                end
                data_in[45] = real_to_s5p10(-0.001); // ¿?¿?¿?¿?¿?
            end
            
            2: begin // ¿?¿?¿?¿?¿?
                $display("=== Test 2: Mixed Positive/Negative ===");
                for (i = 0; i < INPUTS; i = i + 1) begin
                    if (i[0] == 1'b0) begin  // ¿?¿?¿?¿?
                        data_in[i] = real_to_s5p10(($random % 1000) / 100.0);
                    end else begin
                        data_in[i] = real_to_s5p10(-(($random % 1000) / 100.0));
                    end
                end
                data_in[63] = real_to_s5p10(12.345); // ¿?¿?¿?¿?¿?
            end
            
            3: begin // ¿?¿?¿?¿?¿?
                $display("=== Test 3: Boundary Values ===");
                for (i = 0; i < INPUTS; i = i + 1) begin
                    data_in[i] = real_to_s5p10(0.0);
                end
                data_in[0] = real_to_s5p10(15.999);  // ¿?¿?¿?¿?
                data_in[1] = real_to_s5p10(-16.0);   // ¿?¿?¿?¿?
                data_in[2] = real_to_s5p10(0.001);   // ¿?¿?¿?¿?
                data_in[3] = real_to_s5p10(-0.001);  // ¿?¿?¿?¿?
            end
            
            4: begin // ¿?¿?¿?¿?¿?
                $display("=== Test 4: All Same Values ===");
                for (i = 0; i < INPUTS; i = i + 1) begin
                    data_in[i] = real_to_s5p10(5.5);
                end
            end
        endcase
    end
endtask

// ===========================================
// ¿?¿?¿?¿?
// ===========================================
task verify_result;
    begin
        find_max_software();
        
        if (max_out === software_max) begin
            $display("¿ PASS: Hardware=%f, Software=%f", 
                     s5p10_to_real(max_out), s5p10_to_real(software_max));
        end else begin
            $display("¿ FAIL: Hardware=%f, Software=%f", 
                     s5p10_to_real(max_out), s5p10_to_real(software_max));
            $display("    Hardware=0x%04x, Software=0x%04x", max_out, software_max);
        end
    end
endtask

// ===========================================
// ¿?¿?¿?¿?¿?
// ===========================================
initial begin
    $display("===========================================");
    $display("Max Finder 64 Testbench Started");
    $display("S5.10 Format: Range [-16.0, +15.999]");
    $display("===========================================");
    
    // ¿?¿?¿?¿?¿?¿?
    for (j = 0; j < 5; j = j + 1) begin
        generate_test_data(j);
        
        // ¿?¿?¿?¿?¿?¿?¿?¿?
        #1;
        
        // ¿?¿?¿?¿?
        verify_result();
        
        // ¿?¿?¿?¿?¿?¿?¿?¿?
        $display("Sample inputs: [0]=%f, [31]=%f, [63]=%f", 
                 s5p10_to_real(data_in[0]), 
                 s5p10_to_real(data_in[31]), 
                 s5p10_to_real(data_in[63]));
        $display("");
    end
    
    $display("===========================================");
    $display("All tests completed!");
    $display("===========================================");
    
    $finish;
end

endmodule
