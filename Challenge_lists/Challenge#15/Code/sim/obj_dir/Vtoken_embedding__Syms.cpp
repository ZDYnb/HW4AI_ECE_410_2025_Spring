// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtoken_embedding__pch.h"
#include "Vtoken_embedding.h"
#include "Vtoken_embedding___024root.h"

// FUNCTIONS
Vtoken_embedding__Syms::~Vtoken_embedding__Syms()
{
}

Vtoken_embedding__Syms::Vtoken_embedding__Syms(VerilatedContext* contextp, const char* namep, Vtoken_embedding* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(11);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}
