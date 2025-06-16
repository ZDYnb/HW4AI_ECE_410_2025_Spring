// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VNORMALIZE__SYMS_H_
#define VERILATED_VNORMALIZE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vnormalize.h"

// INCLUDE MODULE CLASSES
#include "Vnormalize___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vnormalize__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vnormalize* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vnormalize___024root           TOP;

    // CONSTRUCTORS
    Vnormalize__Syms(VerilatedContext* contextp, const char* namep, Vnormalize* modelp);
    ~Vnormalize__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
