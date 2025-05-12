// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vexp_taylor.h for the primary calling header

#include "Vexp_taylor__pch.h"
#include "Vexp_taylor__Syms.h"
#include "Vexp_taylor___024root.h"

void Vexp_taylor___024root___ctor_var_reset(Vexp_taylor___024root* vlSelf);

Vexp_taylor___024root::Vexp_taylor___024root(Vexp_taylor__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vexp_taylor___024root___ctor_var_reset(this);
}

void Vexp_taylor___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vexp_taylor___024root::~Vexp_taylor___024root() {
}
