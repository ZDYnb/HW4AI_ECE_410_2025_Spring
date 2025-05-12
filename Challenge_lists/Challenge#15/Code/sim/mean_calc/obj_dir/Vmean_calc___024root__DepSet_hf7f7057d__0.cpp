// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmean_calc.h for the primary calling header

#include "Vmean_calc__pch.h"
#include "Vmean_calc__Syms.h"
#include "Vmean_calc___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__ico(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG

void Vmean_calc___024root___eval_triggers__ico(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_triggers__ico\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vmean_calc___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__act(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG

void Vmean_calc___024root___eval_triggers__act(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_triggers__act\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vmean_calc___024root___dump_triggers__act(vlSelf);
    }
#endif
}
