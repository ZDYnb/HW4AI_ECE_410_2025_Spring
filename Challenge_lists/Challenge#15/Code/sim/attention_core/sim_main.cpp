#include "Vattention_core.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <cmath>

#define Q88(x) static_cast<int16_t>((x) * 256)
#define FROM_Q88(x) (static_cast<float>((x) & 0xFFFF) / 256.0)

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vattention_core* top = new Vattention_core;

    // Example Q, K, V input vectors
    float q[4] = {0.5f, 0.3f, 0.2f, 1.0f};
    float k[4] = {0.5f, 0.0f, 0.1f, 1.2f};
    float v[4] = {0.3f, 0.5f, 0.5f, 0.3f};

    // Load Q, K, V into DUT
    for (int i = 0; i < 4; ++i) {
        top->q[i] = Q88(q[i]);
        top->k[i] = Q88(k[i]);
        top->v[i] = Q88(v[i]);
    }

    top->clk = 0;
    top->rst = 1;
    top->eval();
    top->clk = 1;
    top->eval();

    top->rst = 0;
    top->start = 1;

    // Step through clock cycles
    int cycles = 0;
    do {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
        cycles++;
        if (cycles > 10) break;
    } while (!top->done);

    float hw_result = FROM_Q88(top->y);

    // Calculate expected result in float
    float dot = 0.0;
    for (int i = 0; i < 4; ++i)
        dot += q[i] * k[i];

    float exp_vals[4], exp_sum = 0.0;
    for (int i = 0; i < 4; ++i) {
        exp_vals[i] = std::exp(dot);  // same dot for all positions
        exp_sum += exp_vals[i];
    }

    float softmax[4];
    for (int i = 0; i < 4; ++i)
        softmax[i] = exp_vals[i] / exp_sum;

    float expected = 0.0;
    for (int i = 0; i < 4; ++i)
        expected += softmax[i] * v[i];

    std::cout << std::fixed << std::setprecision(6);
    std::cout << "HW Output : " << hw_result << "\n";
    std::cout << "Expected  : " << expected << "\n";
    std::cout << "Raw Hex   : 0x" << std::hex << (top->y & 0xFFFF) << std::dec << "\n";

    delete top;
    return 0;
}
