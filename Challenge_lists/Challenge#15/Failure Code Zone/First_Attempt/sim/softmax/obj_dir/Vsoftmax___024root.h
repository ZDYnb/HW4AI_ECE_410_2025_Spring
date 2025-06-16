// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vsoftmax.h for the primary calling header

#ifndef VERILATED_VSOFTMAX___024ROOT_H_
#define VERILATED_VSOFTMAX___024ROOT_H_  // guard

#include "verilated.h"


class Vsoftmax__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vsoftmax___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VL_IN16(x[4],15,0);
    VL_OUT16(y[4],15,0);
    VlUnpacked<SData/*15:0*/, 4> softmax__DOT__exp_out;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vsoftmax__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vsoftmax___024root(Vsoftmax__Syms* symsp, const char* v__name);
    ~Vsoftmax___024root();
    VL_UNCOPYABLE(Vsoftmax___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
