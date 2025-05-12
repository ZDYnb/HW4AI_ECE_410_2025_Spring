#include "Vqkv_linear.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>

#define N 4  // Must match Verilog

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vqkv_linear* top = new Vqkv_linear;

    vluint64_t sim_time = 0;

    // Reset the design
    top->clk = 0;
    top->rst = 1;
    top->start = 0;
    top->eval();

    for (int i = 0; i < 2; i++) {
        top->clk ^= 1;
        top->eval();
        sim_time++;
    }

    top->rst = 0;
    top->eval();

    // Initialize input vector x
    for (int i = 0; i < N; i++) {
        top->x[i] = i + 1;  // x = [1, 2, 3, 4]
    }

    // Pulse start for 1 clock cycle
    top->start = 1;
    top->clk = 0; top->eval();
    top->clk = 1; top->eval(); sim_time++;
    top->start = 0;

    // Wait for done = 1
    while (!top->done) {
        top->clk ^= 1;
        top->eval();
        sim_time++;
    }

    // Capture and print outputs
    std::cout << "Q: ";
    for (int i = 0; i < N; i++) std::cout << std::setw(6) << (int16_t)top->q[i] << " ";
    std::cout << "\nK: ";
    for (int i = 0; i < N; i++) std::cout << std::setw(6) << (int16_t)top->k[i] << " ";
    std::cout << "\nV: ";
    for (int i = 0; i < N; i++) std::cout << std::setw(6) << (int16_t)top->v[i] << " ";
    std::cout << std::endl;
    
    delete top;
    return 0;
}
