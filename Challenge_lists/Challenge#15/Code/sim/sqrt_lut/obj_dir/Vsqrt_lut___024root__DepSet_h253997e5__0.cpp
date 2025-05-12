// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vsqrt_lut.h for the primary calling header

#include "Vsqrt_lut__pch.h"
#include "Vsqrt_lut__Syms.h"
#include "Vsqrt_lut___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vsqrt_lut___024root___dump_triggers__ico(Vsqrt_lut___024root* vlSelf);
#endif  // VL_DEBUG

void Vsqrt_lut___024root___eval_triggers__ico(Vsqrt_lut___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsqrt_lut___024root___eval_triggers__ico\n"); );
    Vsqrt_lut__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vsqrt_lut___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vsqrt_lut___024root___dump_triggers__act(Vsqrt_lut___024root* vlSelf);
#endif  // VL_DEBUG

void Vsqrt_lut___024root___eval_triggers__act(Vsqrt_lut___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsqrt_lut___024root___eval_triggers__act\n"); );
    Vsqrt_lut__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vsqrt_lut___024root___dump_triggers__act(vlSelf);
    }
#endif
}
