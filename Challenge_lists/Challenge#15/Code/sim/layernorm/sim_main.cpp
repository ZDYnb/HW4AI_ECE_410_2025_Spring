#include "Vlayernorm.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vlayernorm* top = new Vlayernorm;

    // Clock and reset init
    top->clk = 0;
    top->rst = 1;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 0;

    // Pack 4 8-bit numbers into one 32-bit bus
    uint32_t packed_input = (10 << 0) | (20 << 8) | (30 << 16) | (40 << 24);
    top->in_vector_flat = packed_input;

    // Simulate a few clock cycles
    for (int i = 0; i < 5; ++i) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
    }

    // Extract output
    for (int i = 0; i < 4; ++i) {
        uint8_t val = (top->out_vector_flat >> (i * 8)) & 0xFF;
        printf("Normalized[%d] = %d\n", i, val);
    }

    delete top;
    return 0;
}
