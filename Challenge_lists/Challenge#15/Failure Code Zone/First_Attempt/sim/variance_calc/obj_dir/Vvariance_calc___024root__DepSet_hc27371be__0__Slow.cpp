// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vvariance_calc.h for the primary calling header

#include "Vvariance_calc__pch.h"
#include "Vvariance_calc__Syms.h"
#include "Vvariance_calc___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vvariance_calc___024root___dump_triggers__stl(Vvariance_calc___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vvariance_calc___024root___eval_triggers__stl(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_triggers__stl\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.setBit(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vvariance_calc___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
