// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vexp_taylor.h for the primary calling header

#include "Vexp_taylor__pch.h"
#include "Vexp_taylor__Syms.h"
#include "Vexp_taylor___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vexp_taylor___024root___dump_triggers__ico(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG

void Vexp_taylor___024root___eval_triggers__ico(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_triggers__ico\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vexp_taylor___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vexp_taylor___024root___dump_triggers__act(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG

void Vexp_taylor___024root___eval_triggers__act(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_triggers__act\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vexp_taylor___024root___dump_triggers__act(vlSelf);
    }
#endif
}
