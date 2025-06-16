#include "Vdot_product.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>

#define N 4

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdot_product* top = new Vdot_product;

    // Input vectors
    int16_t a[N] = {1, 2, 3, 4};
    int16_t b[N] = {1, 2, 3, 4}; // dot = 1+4+9+16 = 30

    for (int i = 0; i < N; i++) {
        top->a[i] = a[i];
        top->b[i] = b[i];
    }

    top->eval(); // Evaluate combinational logic

    std::cout << "Dot Product Result: " << (int16_t)top->result << std::endl;

    delete top;
    return 0;
}
