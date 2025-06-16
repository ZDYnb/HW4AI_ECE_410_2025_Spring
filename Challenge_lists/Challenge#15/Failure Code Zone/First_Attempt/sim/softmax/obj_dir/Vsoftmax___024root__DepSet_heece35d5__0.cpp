// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vsoftmax.h for the primary calling header

#include "Vsoftmax__pch.h"
#include "Vsoftmax__Syms.h"
#include "Vsoftmax___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vsoftmax___024root___dump_triggers__ico(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG

void Vsoftmax___024root___eval_triggers__ico(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_triggers__ico\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vsoftmax___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vsoftmax___024root___dump_triggers__act(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG

void Vsoftmax___024root___eval_triggers__act(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_triggers__act\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vsoftmax___024root___dump_triggers__act(vlSelf);
    }
#endif
}
