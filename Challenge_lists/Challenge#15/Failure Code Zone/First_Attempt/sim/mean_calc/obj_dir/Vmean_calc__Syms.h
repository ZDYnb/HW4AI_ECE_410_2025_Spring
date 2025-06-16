// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VMEAN_CALC__SYMS_H_
#define VERILATED_VMEAN_CALC__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vmean_calc.h"

// INCLUDE MODULE CLASSES
#include "Vmean_calc___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vmean_calc__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vmean_calc* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vmean_calc___024root           TOP;

    // CONSTRUCTORS
    Vmean_calc__Syms(VerilatedContext* contextp, const char* namep, Vmean_calc* modelp);
    ~Vmean_calc__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
