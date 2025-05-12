// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vnormalize.h for the primary calling header

#include "Vnormalize__pch.h"
#include "Vnormalize__Syms.h"
#include "Vnormalize___024root.h"

void Vnormalize___024root___ctor_var_reset(Vnormalize___024root* vlSelf);

Vnormalize___024root::Vnormalize___024root(Vnormalize__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vnormalize___024root___ctor_var_reset(this);
}

void Vnormalize___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vnormalize___024root::~Vnormalize___024root() {
}
