// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vqkv_linear.h for the primary calling header

#ifndef VERILATED_VQKV_LINEAR___024ROOT_H_
#define VERILATED_VQKV_LINEAR___024ROOT_H_  // guard

#include "verilated.h"


class Vqkv_linear__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vqkv_linear___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(start,0,0);
    VL_OUT8(done,0,0);
    CData/*1:0*/ qkv_linear__DOT__state;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VL_IN16(x[4],15,0);
    VL_OUT16(q[4],15,0);
    VL_OUT16(k[4],15,0);
    VL_OUT16(v[4],15,0);
    VlUnpacked<SData/*15:0*/, 4> qkv_linear__DOT__q_acc;
    VlUnpacked<SData/*15:0*/, 4> qkv_linear__DOT__k_acc;
    VlUnpacked<SData/*15:0*/, 4> qkv_linear__DOT__v_acc;
    VlUnpacked<VlUnpacked<SData/*15:0*/, 4>, 4> qkv_linear__DOT__WQ;
    VlUnpacked<VlUnpacked<SData/*15:0*/, 4>, 4> qkv_linear__DOT__WK;
    VlUnpacked<VlUnpacked<SData/*15:0*/, 4>, 4> qkv_linear__DOT__WV;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vqkv_linear__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vqkv_linear___024root(Vqkv_linear__Syms* symsp, const char* v__name);
    ~Vqkv_linear___024root();
    VL_UNCOPYABLE(Vqkv_linear___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
