`timescale 1ns/1ps

module tb_pos_embedding;

  // Parameters
  localparam N_POS   = 8;
  localparam N_EMBD  = 4;
  localparam CLK_PERIOD = 10;

  // DUT I/O
  logic clk = 0;
  logic [$clog2(N_POS)-1:0] pos;
  logic [7:0] embedding [0:N_EMBD-1];

  // DUT Instance
  pos_embedding #(
    .N_POS(N_POS),
    .N_EMBD(N_EMBD)
  ) dut (
    .clk(clk),
    .pos(pos),
    .embedding(embedding)
  );

  // Clock generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Stimulus
  initial begin
    $display("Start Simulation");
    for (int i = 0; i < N_POS; i++) begin
      pos = i;
      #(CLK_PERIOD);
      $display("Pos ID = %0d => [ %0d, %0d, %0d, %0d ]", i, embedding[0], embedding[1], embedding[2], embedding[3]);
    end
    $display("End Simulation");
    $finish;
  end

endmodule

