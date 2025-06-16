// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vmean_calc__pch.h"
#include "Vmean_calc.h"
#include "Vmean_calc___024root.h"

// FUNCTIONS
Vmean_calc__Syms::~Vmean_calc__Syms()
{
}

Vmean_calc__Syms::Vmean_calc__Syms(VerilatedContext* contextp, const char* namep, Vmean_calc* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(41);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}
