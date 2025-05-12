#include "Vvariance_calc.h"
#include "verilated.h"
#include <cstdio>

int main() {
    const char* argv[] = {};
    Verilated::commandArgs(0, argv);

    Vvariance_calc* dut = new Vvariance_calc;

    // Input values: x = [4, 6, 10, 0], Q8.8 format = value * 256
    dut->x[0] = 4 * 256;
    dut->x[1] = 6 * 256;    
    dut->x[2] = 10 * 256;
    dut->x[3] = 0 * 256;

    // Precomputed mean = 5.0 → 5 * 256 = 1280
    dut->mean = 5 * 256;

    // Evaluate the combinational block
    dut->eval();

    printf("Variance (fixed): %d\n", dut->variance);
    printf("Variance (float): %.4f\n", dut->variance / 256.0);

    delete dut;
    return 0;
}
