#include "Vattention_apply.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <cmath>

#define Q88(x) static_cast<int16_t>((x) * 256)
#define FROM_Q88(x) (static_cast<float>((x) & 0xFFFF) / 256.0)

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vattention_apply* top = new Vattention_apply;

    // Example weights (softmax output) and values (Q8.8 float)
    float weights[4] = {0.1f, 0.2f, 0.3f, 0.5f};  // sum = 1.0
    float values[4]  = {0.0f, 1.0f, 2.0f, 3.0f};  // linear values

    float expected = 0.0;
    for (int i = 0; i < 4; ++i) {
        top->weights[i] = Q88(weights[i]);
        top->v[i]       = Q88(values[i]);
        expected += weights[i] * values[i];
    }

    top->eval();

    float output = FROM_Q88(top->out);

    std::cout << std::fixed << std::setprecision(6);
    std::cout << "Expected: " << expected << "\n";
    std::cout << "HW Output: " << output << "\n";
    std::cout << "Raw Hex  : 0x" << std::hex << (top->out & 0xFFFF) << std::dec << "\n";

    delete top;
    return 0;
}

