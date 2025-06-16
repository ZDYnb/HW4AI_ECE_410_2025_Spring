#include "Vmean_calc.h"
#include "verilated.h"

int main() {
    const char* argv[] = {};  // Fix for ambiguity
    Verilated::commandArgs(0, argv);

    Vmean_calc* dut = new Vmean_calc;

    // Input in Q8.8
    dut->x[0] = 4 * 256;
    dut->x[1] = 8 * 256;
    dut->x[2] = 12 * 256;
    dut->x[3] = 0 * 256;

    dut->eval();

    printf("Mean (fixed): %d\n", dut->mean);
    printf("Mean (float): %.4f\n", dut->mean / 256.0);

    delete dut;
    return 0;
}

