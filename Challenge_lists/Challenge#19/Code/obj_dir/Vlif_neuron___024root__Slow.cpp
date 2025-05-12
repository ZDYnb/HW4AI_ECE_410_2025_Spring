// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlif_neuron.h for the primary calling header

#include "Vlif_neuron__pch.h"
#include "Vlif_neuron__Syms.h"
#include "Vlif_neuron___024root.h"

void Vlif_neuron___024root___ctor_var_reset(Vlif_neuron___024root* vlSelf);

Vlif_neuron___024root::Vlif_neuron___024root(Vlif_neuron__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vlif_neuron___024root___ctor_var_reset(this);
}

void Vlif_neuron___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vlif_neuron___024root::~Vlif_neuron___024root() {
}
