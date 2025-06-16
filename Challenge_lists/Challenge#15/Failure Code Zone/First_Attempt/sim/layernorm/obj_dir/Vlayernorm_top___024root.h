// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vlayernorm_top.h for the primary calling header

#ifndef VERILATED_VLAYERNORM_TOP___024ROOT_H_
#define VERILATED_VLAYERNORM_TOP___024ROOT_H_  // guard

#include "verilated.h"


class Vlayernorm_top__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vlayernorm_top___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VL_IN16(x[4],15,0);
    VL_OUT16(norm_x[4],15,0);
    VlUnpacked<SData/*15:0*/, 256> layernorm_top__DOT__sqrt_inst__DOT__lut;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vlayernorm_top__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vlayernorm_top___024root(Vlayernorm_top__Syms* symsp, const char* v__name);
    ~Vlayernorm_top___024root();
    VL_UNCOPYABLE(Vlayernorm_top___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
