// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdot_product.h for the primary calling header

#include "Vdot_product__pch.h"
#include "Vdot_product__Syms.h"
#include "Vdot_product___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdot_product___024root___dump_triggers__stl(Vdot_product___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vdot_product___024root___eval_triggers__stl(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_triggers__stl\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.setBit(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vdot_product___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
