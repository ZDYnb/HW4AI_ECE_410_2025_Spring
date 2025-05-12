// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vnormalize.h for the primary calling header

#include "Vnormalize__pch.h"
#include "Vnormalize___024root.h"

VL_ATTR_COLD void Vnormalize___024root___eval_static(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_static\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vnormalize___024root___eval_initial(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_initial\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vnormalize___024root___eval_final(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_final\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__stl(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vnormalize___024root___eval_phase__stl(Vnormalize___024root* vlSelf);

VL_ATTR_COLD void Vnormalize___024root___eval_settle(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_settle\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY(((0x64U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vnormalize___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/normalize.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vnormalize___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__stl(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___dump_triggers__stl\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

void Vnormalize___024root___ico_sequent__TOP__0(Vnormalize___024root* vlSelf);

VL_ATTR_COLD void Vnormalize___024root___eval_stl(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_stl\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vnormalize___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vnormalize___024root___eval_triggers__stl(Vnormalize___024root* vlSelf);

VL_ATTR_COLD bool Vnormalize___024root___eval_phase__stl(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_phase__stl\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vnormalize___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vnormalize___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__ico(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___dump_triggers__ico\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VicoTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__act(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___dump_triggers__act\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__nba(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___dump_triggers__nba\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vnormalize___024root___ctor_var_reset(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___ctor_var_reset\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->x[__Vi0] = VL_RAND_RESET_I(16);
    }
    vlSelf->mean = VL_RAND_RESET_I(16);
    vlSelf->stddev = VL_RAND_RESET_I(16);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->norm_x[__Vi0] = VL_RAND_RESET_I(16);
    }
}
