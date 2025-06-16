// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vattention_core__pch.h"
#include "Vattention_core.h"
#include "Vattention_core___024root.h"

// FUNCTIONS
Vattention_core__Syms::~Vattention_core__Syms()
{
}

Vattention_core__Syms::Vattention_core__Syms(VerilatedContext* contextp, const char* namep, Vattention_core* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(707);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}
