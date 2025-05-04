`timescale 1ns/1ps

module tb_token_embedding;
    reg clk = 0;
    reg [3:0] token_id;
    wire [7:0] embedding_vector0, embedding_vector1, embedding_vector2, embedding_vector3;

    token_embedding dut (
        .clk(clk),
        .token_id(token_id),
        .embedding_vector0(embedding_vector0),
        .embedding_vector1(embedding_vector1),
        .embedding_vector2(embedding_vector2),
        .embedding_vector3(embedding_vector3)
    );

    always #5 clk = ~clk; // Clock: 100 MHz

    initial begin
        $dumpfile("wave.vcd"); //This tells Verilator (or any simulator) to write a waveform file named wave.vcd.
        $dumpvars(0, tb_token_embedding);// This tells the simulator which module's signals to record in the VCD file

        token_id = 4'd0; #10; //This sets token_id to decimal 0, and then waits 10 nanoseconds.
        token_id = 4'd1; #10;
        token_id = 4'd2; #10;

        $finish;
    end
endmodule
