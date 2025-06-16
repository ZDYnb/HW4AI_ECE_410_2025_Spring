// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vattention_core.h for the primary calling header

#ifndef VERILATED_VATTENTION_CORE___024ROOT_H_
#define VERILATED_VATTENTION_CORE___024ROOT_H_  // guard

#include "verilated.h"


class Vattention_core__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vattention_core___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(start,0,0);
    VL_OUT8(done,0,0);
    CData/*1:0*/ attention_core__DOT__state;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
    CData/*0:0*/ __VactContinue;
    VL_OUT16(y,15,0);
    IData/*31:0*/ __VactIterCount;
    VL_IN16(q[4],15,0);
    VL_IN16(k[4],15,0);
    VL_IN16(v[4],15,0);
    VlUnpacked<SData/*15:0*/, 4> attention_core__DOT__softmax_out;
    VlUnpacked<SData/*15:0*/, 4> attention_core__DOT__qk_vector;
    VlUnpacked<SData/*15:0*/, 4> attention_core__DOT__softmax_inst__DOT__exp_out;
    VlUnpacked<IData/*31:0*/, 4> attention_core__DOT__apply_inst__DOT__mul;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vattention_core__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vattention_core___024root(Vattention_core__Syms* symsp, const char* v__name);
    ~Vattention_core___024root();
    VL_UNCOPYABLE(Vattention_core___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
