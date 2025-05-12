// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vsoftmax.h for the primary calling header

#include "Vsoftmax__pch.h"
#include "Vsoftmax__Syms.h"
#include "Vsoftmax___024root.h"

void Vsoftmax___024root___ctor_var_reset(Vsoftmax___024root* vlSelf);

Vsoftmax___024root::Vsoftmax___024root(Vsoftmax__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vsoftmax___024root___ctor_var_reset(this);
}

void Vsoftmax___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vsoftmax___024root::~Vsoftmax___024root() {
}
