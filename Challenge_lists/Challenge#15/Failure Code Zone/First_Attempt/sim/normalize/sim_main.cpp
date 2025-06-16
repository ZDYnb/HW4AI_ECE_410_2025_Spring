#include "Vnormalize.h"
#include "verilated.h"
#include <cstdio>

int main() {
    const char* argv[] = {};
    Verilated::commandArgs(0, argv);

    Vnormalize* dut = new Vnormalize;

    // Inputs (Q8.8 format)
    dut->x[0] = 4 * 256;
    dut->x[1] = 6 * 256;
    dut->x[2] = 10 * 256;
    dut->x[3] = 0 * 256;

    dut->mean = 5 * 256;     // mean = 5.0
    dut->stddev = 2 * 256;   // stddev = 2.0

    // Evaluate combinational logic
    dut->eval();
    // you may have to int16_t to recognize the negtive numbers
    // if you do not do this, uint16_t will be used
    for (int i = 0; i < 4; i++) {
    printf("norm_x[%d] = %d (float: %.4f)\n", i,
    dut->norm_x[i],
    ((int16_t)dut->norm_x[i]) / 256.0
    );
   }

    delete dut;
    return 0;
}
