// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtoken_embedding.h for the primary calling header

#include "Vtoken_embedding__pch.h"
#include "Vtoken_embedding__Syms.h"
#include "Vtoken_embedding___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtoken_embedding___024root___dump_triggers__act(Vtoken_embedding___024root* vlSelf);
#endif  // VL_DEBUG

void Vtoken_embedding___024root___eval_triggers__act(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_triggers__act\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.setBit(0U, ((IData)(vlSelfRef.clk) 
                                          & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0))));
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtoken_embedding___024root___dump_triggers__act(vlSelf);
    }
#endif
}
