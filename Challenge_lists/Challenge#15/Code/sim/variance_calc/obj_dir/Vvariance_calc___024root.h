// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vvariance_calc.h for the primary calling header

#ifndef VERILATED_VVARIANCE_CALC___024ROOT_H_
#define VERILATED_VVARIANCE_CALC___024ROOT_H_  // guard

#include "verilated.h"


class Vvariance_calc__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vvariance_calc___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    VL_IN16(mean,15,0);
    VL_OUT16(variance,15,0);
    IData/*31:0*/ __VactIterCount;
    VL_IN16(x[4],15,0);
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vvariance_calc__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vvariance_calc___024root(Vvariance_calc__Syms* symsp, const char* v__name);
    ~Vvariance_calc___024root();
    VL_UNCOPYABLE(Vvariance_calc___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
