// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VDOT_PRODUCT__SYMS_H_
#define VERILATED_VDOT_PRODUCT__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vdot_product.h"

// INCLUDE MODULE CLASSES
#include "Vdot_product___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vdot_product__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vdot_product* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vdot_product___024root         TOP;

    // CONSTRUCTORS
    Vdot_product__Syms(VerilatedContext* contextp, const char* namep, Vdot_product* modelp);
    ~Vdot_product__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
