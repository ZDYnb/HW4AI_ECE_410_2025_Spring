// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmean_calc.h for the primary calling header

#include "Vmean_calc__pch.h"
#include "Vmean_calc__Syms.h"
#include "Vmean_calc___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__stl(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vmean_calc___024root___eval_triggers__stl(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_triggers__stl\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.setBit(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vmean_calc___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
