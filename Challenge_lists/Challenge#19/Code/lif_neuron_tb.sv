`timescale 1ns/1ps
module lif_neuron_tb;

   logic clk = 0;
   logic rst;
   logic in_bit;
   logic spike;
   logic [15:0] potential;

   always #5 clk = ~clk;

   lif_neuron dut (
      .clk       (clk),
      .rst       (rst),
      .in_bit    (in_bit),
      .spike     (spike),
      .potential (potential)
   );

   task automatic show(string tag);
      $display("%0t  %-6s  in=%0d  pot=%h  spike=%0d",
               $time, tag,  in_bit, potential, spike);
   endtask

   initial begin
      rst = 1; in_bit = 0;
      repeat (2) @(posedge clk);
      rst = 0;

      $display("\n---- Phase 1: constant 0 (100 ns) ----");
      repeat (10) begin
         @(posedge clk);
         in_bit = 0;
         show("P1");
      end

      $display("\n---- Phase 2: input 1 until spike ----");
      forever begin
         @(posedge clk);
         in_bit = 1;
         show("P2");
         if (spike) break;
      end

      $display("\n---- Phase 3: leakage ----");
      repeat (4) begin
         @(posedge clk);
         in_bit = 0;
         show("P3");
      end

      $display("\n---- Phase 4: reset then force spike ----");
      rst = 1; @(posedge clk); rst = 0;
      repeat (2) begin
         @(posedge clk);
         in_bit = 1;
         show("P4");
      end

      $display("\nSimulation finished.");
      $stop;
   end

   initial begin
      $dumpfile("lif_neuron.vcd");
      $dumpvars(0, lif_neuron_tb);
   end

endmodule
