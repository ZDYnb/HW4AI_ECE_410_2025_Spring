// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VLAYERNORM__SYMS_H_
#define VERILATED_VLAYERNORM__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vlayernorm.h"

// INCLUDE MODULE CLASSES
#include "Vlayernorm___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vlayernorm__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vlayernorm* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vlayernorm___024root           TOP;

    // CONSTRUCTORS
    Vlayernorm__Syms(VerilatedContext* contextp, const char* namep, Vlayernorm* modelp);
    ~Vlayernorm__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
