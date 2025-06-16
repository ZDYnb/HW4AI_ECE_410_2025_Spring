// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VEXP_TAYLOR__SYMS_H_
#define VERILATED_VEXP_TAYLOR__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vexp_taylor.h"

// INCLUDE MODULE CLASSES
#include "Vexp_taylor___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vexp_taylor__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vexp_taylor* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vexp_taylor___024root          TOP;

    // CONSTRUCTORS
    Vexp_taylor__Syms(VerilatedContext* contextp, const char* namep, Vexp_taylor* modelp);
    ~Vexp_taylor__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
