// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vnormalize.h for the primary calling header

#include "Vnormalize__pch.h"
#include "Vnormalize__Syms.h"
#include "Vnormalize___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__ico(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG

void Vnormalize___024root___eval_triggers__ico(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_triggers__ico\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vnormalize___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__act(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG

void Vnormalize___024root___eval_triggers__act(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_triggers__act\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vnormalize___024root___dump_triggers__act(vlSelf);
    }
#endif
}
