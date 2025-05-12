// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vexp_taylor.h for the primary calling header

#ifndef VERILATED_VEXP_TAYLOR___024ROOT_H_
#define VERILATED_VEXP_TAYLOR___024ROOT_H_  // guard

#include "verilated.h"


class Vexp_taylor__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vexp_taylor___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    VL_IN16(x_q88,15,0);
    VL_OUT16(y_q88,15,0);
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vexp_taylor__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vexp_taylor___024root(Vexp_taylor__Syms* symsp, const char* v__name);
    ~Vexp_taylor___024root();
    VL_UNCOPYABLE(Vexp_taylor___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
