#include "Vsoftmax.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <cmath>

#define Q88(x) static_cast<int16_t>((x) * 256)
#define FROM_Q88(x) (static_cast<float>((x) & 0xFFFF) / 256.0)

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vsoftmax* top = new Vsoftmax;

    float inputs[4] = {0.1f, 0.2f, 0.3f, 1.8f};

    // Assign Q8.8 inputs to Verilog module
    for (int i = 0; i < 4; ++i) {
        top->x[i] = Q88(inputs[i]);
    }

    top->eval();

    // Compute expected softmax in C++
    float exp_vals[4];
    float exp_sum = 0.0f;
    for (int i = 0; i < 4; ++i) {
        exp_vals[i] = std::exp(inputs[i]);
        exp_sum += exp_vals[i];
    }

    std::cout << std::fixed << std::setprecision(6);
    std::cout << "  Input   |  Softmax Output  |  Expected    |  Raw (hex) |  exp_out (float)\n";
    std::cout << "----------|------------------|--------------|------------|------------------\n";

    for (int i = 0; i < 4; ++i) {
        float hw_output = FROM_Q88(top->y[i]);
        float expected = exp_vals[i] / exp_sum;
        float exp_hw = FROM_Q88(top->exp_out[i]);

        std::cout << "  " << std::setw(7) << inputs[i]
                  << " |  " << std::setw(14) << hw_output
                  << " |  " << std::setw(10) << expected
                  << " |  0x" << std::hex << std::setw(4) << std::setfill('0') << (top->y[i] & 0xFFFF)
                  << std::dec << std::setfill(' ')
                  << " |  " << std::setw(14) << exp_hw
                  << "\n";
    }

    delete top;
    return 0;
}
