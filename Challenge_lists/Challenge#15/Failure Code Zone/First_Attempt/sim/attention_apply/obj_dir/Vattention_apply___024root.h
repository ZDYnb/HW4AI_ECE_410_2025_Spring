// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vattention_apply.h for the primary calling header

#ifndef VERILATED_VATTENTION_APPLY___024ROOT_H_
#define VERILATED_VATTENTION_APPLY___024ROOT_H_  // guard

#include "verilated.h"


class Vattention_apply__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vattention_apply___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    VL_OUT16(out,15,0);
    IData/*31:0*/ __VactIterCount;
    VL_IN16(weights[4],15,0);
    VL_IN16(v[4],15,0);
    VlUnpacked<IData/*31:0*/, 4> attention_apply__DOT__mul;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vattention_apply__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vattention_apply___024root(Vattention_apply__Syms* symsp, const char* v__name);
    ~Vattention_apply___024root();
    VL_UNCOPYABLE(Vattention_apply___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
