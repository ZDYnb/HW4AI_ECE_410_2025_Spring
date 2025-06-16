#include "Vlayernorm_top.h"
#include "verilated.h"
#include <cstdio>
#include <cstdint>

int main() {
    const char* argv[] = {};
    Verilated::commandArgs(0, argv);

    Vlayernorm_top* dut = new Vlayernorm_top;

    // Set up input: x = [4.0, 6.0, 10.0, 0.0] in Q8.8
    dut->x[0] = 4 * 256;
    dut->x[1] = 6 * 256;
    dut->x[2] = 10 * 256;
    dut->x[3] = 0 * 256;

    // Evaluate the whole system
    dut->eval();

    // Print output values
    for (int i = 0; i < 4; i++) {
        int16_t val = (int16_t)dut->norm_x[i];
        printf("norm_x[%d] = %d (float: %.4f)\n", i, val, val / 256.0);
    }

    delete dut;
    return 0;
}
