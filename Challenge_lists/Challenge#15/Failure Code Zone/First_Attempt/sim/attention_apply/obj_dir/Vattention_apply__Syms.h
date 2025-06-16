// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VATTENTION_APPLY__SYMS_H_
#define VERILATED_VATTENTION_APPLY__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vattention_apply.h"

// INCLUDE MODULE CLASSES
#include "Vattention_apply___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vattention_apply__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vattention_apply* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vattention_apply___024root     TOP;

    // CONSTRUCTORS
    Vattention_apply__Syms(VerilatedContext* contextp, const char* namep, Vattention_apply* modelp);
    ~Vattention_apply__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
