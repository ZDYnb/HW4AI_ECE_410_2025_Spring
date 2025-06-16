// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VSQRT_LUT__SYMS_H_
#define VERILATED_VSQRT_LUT__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vsqrt_lut.h"

// INCLUDE MODULE CLASSES
#include "Vsqrt_lut___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vsqrt_lut__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vsqrt_lut* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vsqrt_lut___024root            TOP;

    // CONSTRUCTORS
    Vsqrt_lut__Syms(VerilatedContext* contextp, const char* namep, Vsqrt_lut* modelp);
    ~Vsqrt_lut__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
