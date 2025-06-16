// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmean_calc.h for the primary calling header

#include "Vmean_calc__pch.h"
#include "Vmean_calc___024root.h"

VL_ATTR_COLD void Vmean_calc___024root___eval_static(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_static\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vmean_calc___024root___eval_initial(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_initial\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vmean_calc___024root___eval_final(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_final\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__stl(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vmean_calc___024root___eval_phase__stl(Vmean_calc___024root* vlSelf);

VL_ATTR_COLD void Vmean_calc___024root___eval_settle(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_settle\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vmean_calc___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/mean_calc.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vmean_calc___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__stl(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___dump_triggers__stl\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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

void Vmean_calc___024root___ico_sequent__TOP__0(Vmean_calc___024root* vlSelf);

VL_ATTR_COLD void Vmean_calc___024root___eval_stl(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_stl\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vmean_calc___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vmean_calc___024root___eval_triggers__stl(Vmean_calc___024root* vlSelf);

VL_ATTR_COLD bool Vmean_calc___024root___eval_phase__stl(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_phase__stl\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vmean_calc___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vmean_calc___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__ico(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___dump_triggers__ico\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__act(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___dump_triggers__act\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__nba(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___dump_triggers__nba\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vmean_calc___024root___ctor_var_reset(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___ctor_var_reset\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->x[__Vi0] = VL_RAND_RESET_I(16);
    }
    vlSelf->mean = VL_RAND_RESET_I(16);
}
