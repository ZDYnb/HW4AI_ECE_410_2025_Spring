// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtoken_embedding.h for the primary calling header

#ifndef VERILATED_VTOKEN_EMBEDDING___024ROOT_H_
#define VERILATED_VTOKEN_EMBEDDING___024ROOT_H_  // guard

#include "verilated.h"


class Vtoken_embedding__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtoken_embedding___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(token_id,3,0);
    VL_OUT8(embedding_vector0,7,0);
    VL_OUT8(embedding_vector1,7,0);
    VL_OUT8(embedding_vector2,7,0);
    VL_OUT8(embedding_vector3,7,0);
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<VlUnpacked<CData/*7:0*/, 4>, 16> token_embedding__DOT__rom;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtoken_embedding__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtoken_embedding___024root(Vtoken_embedding__Syms* symsp, const char* v__name);
    ~Vtoken_embedding___024root();
    VL_UNCOPYABLE(Vtoken_embedding___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
