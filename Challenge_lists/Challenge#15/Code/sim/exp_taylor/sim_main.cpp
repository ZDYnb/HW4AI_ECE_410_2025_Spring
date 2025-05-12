#include "Vexp_taylor.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <cmath>

#define Q88(x) static_cast<int16_t>((x) * 256)
#define FROM_Q88(x) ((float)((x) & 0xFFFF) / 256.0)


int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vexp_taylor* top = new Vexp_taylor;

    float test_inputs[] = {-20.0f, -0.5f, 0.0f, 0.5f, 20.0f};

    std::cout << std::fixed << std::setprecision(4);
    std::cout << " Q8.8 input  |  exp_taylor(x)  |  expected exp(x)\n";
    std::cout << "-------------|-----------------|------------------\n";

    for (float x : test_inputs) {
        top->x_q88 = Q88(x);
        top->eval();

        float result = FROM_Q88(top->y_q88);
        float expected = std::exp(x);

std::cout << "  " << std::setw(8) << x
          << "   |   " << std::setw(10) << result
          << "   |   " << std::setw(10) << expected
          << "   |   raw: 0x" << std::hex << top->y_q88 << std::dec << "\n";
    }

    delete top;
    return 0;
}
