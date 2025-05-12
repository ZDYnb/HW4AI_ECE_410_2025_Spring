#include "Vlif_neuron.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

void tick(Vlif_neuron* top, VerilatedVcdC* tfp) {
top->clk = 0; top->eval(); tfp->dump(main_time); main_time += 5;
top->clk = 1; top->eval(); tfp->dump(main_time); main_time += 5;

}

void print_state(int t, Vlif_neuron* top, const char* tag) {
    std::cout << tag
              << " T=" << t
              << " | in_bit=" << top->in_bit
              << " | spike=" << top->spike
              << " | potential=" << top->potential
              << "\n";
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vlif_neuron* top = new Vlif_neuron;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("wave.vcd");

    top->rst = 1;
    top->in_bit = 0;
    tick(top, tfp);
    top->rst = 0;

    // ===== Phase 1: Constant zero input (below threshold) =====
    std::cout << "\n--- Phase 1: Constant input below threshold ---\n";
    for (int i = 0; i < 50; i++) {  // 100ns
        top->in_bit = 0;
        tick(top, tfp);
        print_state(i, top, "[Below]");
    }

    // ===== Phase 2: Accumulate input until spike =====
    std::cout << "\n--- Phase 2: Accumulating input ---\n";
    for (int i = 0; i < 50; i++) {
        top->in_bit = 1;
        tick(top, tfp);
        print_state(i, top, "[Accum]");
        if (top->spike) break;
    }

    // ===== Phase 3: Leakage with no input =====
    std::cout << "\n--- Phase 3: No input (leakage) ---\n";
    for (int i = 0; i < 40; i++) {
        top->in_bit = 0;
        tick(top, tfp);
        print_state(i, top, "[Leak ]");
    }

    // ===== Phase 4: Strong input causes immediate spike =====
    std::cout << "\n--- Phase 4: Strong input (force spike) ---\n";
    top->rst = 1; tick(top, tfp);
    top->rst = 0;

    for (int i = 0; i < 2; i++) {
        top->in_bit = 1;
        tick(top, tfp);
        print_state(i, top, "[Force]");
    }

    tfp->close();
    delete tfp;
    delete top;
    return 0;
}
