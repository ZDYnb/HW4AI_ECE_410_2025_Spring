// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VVARIANCE_CALC__SYMS_H_
#define VERILATED_VVARIANCE_CALC__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vvariance_calc.h"

// INCLUDE MODULE CLASSES
#include "Vvariance_calc___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vvariance_calc__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vvariance_calc* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vvariance_calc___024root       TOP;

    // CONSTRUCTORS
    Vvariance_calc__Syms(VerilatedContext* contextp, const char* namep, Vvariance_calc* modelp);
    ~Vvariance_calc__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
