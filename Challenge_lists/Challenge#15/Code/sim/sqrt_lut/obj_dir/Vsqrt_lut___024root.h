// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vsqrt_lut.h for the primary calling header

#ifndef VERILATED_VSQRT_LUT___024ROOT_H_
#define VERILATED_VSQRT_LUT___024ROOT_H_  // guard

#include "verilated.h"


class Vsqrt_lut__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vsqrt_lut___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    VL_IN16(in_q88,15,0);
    VL_OUT16(out_q88,15,0);
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<SData/*15:0*/, 256> sqrt_lut__DOT__lut;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vsqrt_lut__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vsqrt_lut___024root(Vsqrt_lut__Syms* symsp, const char* v__name);
    ~Vsqrt_lut___024root();
    VL_UNCOPYABLE(Vsqrt_lut___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
