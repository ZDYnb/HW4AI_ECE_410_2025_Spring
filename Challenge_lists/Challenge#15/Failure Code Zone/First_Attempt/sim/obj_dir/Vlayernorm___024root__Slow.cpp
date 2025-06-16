// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlayernorm.h for the primary calling header

#include "Vlayernorm__pch.h"
#include "Vlayernorm__Syms.h"
#include "Vlayernorm___024root.h"

void Vlayernorm___024root___ctor_var_reset(Vlayernorm___024root* vlSelf);

Vlayernorm___024root::Vlayernorm___024root(Vlayernorm__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vlayernorm___024root___ctor_var_reset(this);
}

void Vlayernorm___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vlayernorm___024root::~Vlayernorm___024root() {
}
