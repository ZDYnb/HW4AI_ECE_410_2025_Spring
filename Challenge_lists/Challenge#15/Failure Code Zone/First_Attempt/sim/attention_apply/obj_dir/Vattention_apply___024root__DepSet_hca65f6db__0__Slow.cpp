// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vattention_apply.h for the primary calling header

#include "Vattention_apply__pch.h"
#include "Vattention_apply__Syms.h"
#include "Vattention_apply___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_apply___024root___dump_triggers__stl(Vattention_apply___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vattention_apply___024root___eval_triggers__stl(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_triggers__stl\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.setBit(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vattention_apply___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
