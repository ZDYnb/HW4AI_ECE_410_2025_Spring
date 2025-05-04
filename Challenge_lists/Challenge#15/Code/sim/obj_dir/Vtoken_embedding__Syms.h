// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTOKEN_EMBEDDING__SYMS_H_
#define VERILATED_VTOKEN_EMBEDDING__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtoken_embedding.h"

// INCLUDE MODULE CLASSES
#include "Vtoken_embedding___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtoken_embedding__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtoken_embedding* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtoken_embedding___024root     TOP;

    // CONSTRUCTORS
    Vtoken_embedding__Syms(VerilatedContext* contextp, const char* namep, Vtoken_embedding* modelp);
    ~Vtoken_embedding__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
