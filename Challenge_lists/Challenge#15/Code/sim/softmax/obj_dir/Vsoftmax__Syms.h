// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VSOFTMAX__SYMS_H_
#define VERILATED_VSOFTMAX__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vsoftmax.h"

// INCLUDE MODULE CLASSES
#include "Vsoftmax___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vsoftmax__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vsoftmax* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vsoftmax___024root             TOP;

    // CONSTRUCTORS
    Vsoftmax__Syms(VerilatedContext* contextp, const char* namep, Vsoftmax* modelp);
    ~Vsoftmax__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
