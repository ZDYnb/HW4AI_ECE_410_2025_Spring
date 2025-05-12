// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlayernorm_top.h for the primary calling header

#include "Vlayernorm_top__pch.h"
#include "Vlayernorm_top__Syms.h"
#include "Vlayernorm_top___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__ico(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG

void Vlayernorm_top___024root___eval_triggers__ico(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_triggers__ico\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vlayernorm_top___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__act(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG

void Vlayernorm_top___024root___eval_triggers__act(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_triggers__act\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vlayernorm_top___024root___dump_triggers__act(vlSelf);
    }
#endif
}
