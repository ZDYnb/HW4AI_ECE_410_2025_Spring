// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmean_calc.h for the primary calling header

#include "Vmean_calc__pch.h"
#include "Vmean_calc__Syms.h"
#include "Vmean_calc___024root.h"

void Vmean_calc___024root___ctor_var_reset(Vmean_calc___024root* vlSelf);

Vmean_calc___024root::Vmean_calc___024root(Vmean_calc__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vmean_calc___024root___ctor_var_reset(this);
}

void Vmean_calc___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vmean_calc___024root::~Vmean_calc___024root() {
}
