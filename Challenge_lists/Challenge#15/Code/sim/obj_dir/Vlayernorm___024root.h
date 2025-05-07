// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vlayernorm.h for the primary calling header

#ifndef VERILATED_VLAYERNORM___024ROOT_H_
#define VERILATED_VLAYERNORM___024ROOT_H_  // guard

#include "verilated.h"


class Vlayernorm__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vlayernorm___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    VL_IN(in_vector_flat,31,0);
    VL_OUT(out_vector_flat,31,0);
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*7:0*/, 4> layernorm__DOT__in_vector;
    VlUnpacked<CData/*7:0*/, 4> layernorm__DOT__out_vector;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vlayernorm__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vlayernorm___024root(Vlayernorm__Syms* symsp, const char* v__name);
    ~Vlayernorm___024root();
    VL_UNCOPYABLE(Vlayernorm___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
