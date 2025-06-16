#include "Vsqrt_lut.h"
#include "verilated.h"
#include <cstdio>

int main() {
    const char* argv[] = {};
    Verilated::commandArgs(0, argv);

    Vsqrt_lut* dut = new Vsqrt_lut;

    // Set input: 13.0 → Q8.8 = 13 * 256 = 3328
    dut->in_q88 = 36 * 256;

    // Evaluate combinational logic
    dut->eval();

    // Print raw and float result
    printf("Input  (fixed): %d\n", dut->in_q88);
    printf("Input  (float): %.4f\n", dut->in_q88 / 256.0);
    printf("Output (fixed): %d\n", dut->out_q88);
    printf("Output (float): %.4f\n", dut->out_q88 / 256.0);

    delete dut;
    return 0;
}
