// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vattention_core.h for the primary calling header

#include "Vattention_core__pch.h"
#include "Vattention_core___024root.h"

VL_ATTR_COLD void Vattention_core___024root___eval_static(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_static\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__rst__0 = vlSelfRef.rst;
}

VL_ATTR_COLD void Vattention_core___024root___eval_initial(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_initial\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vattention_core___024root___eval_final(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_final\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__stl(Vattention_core___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vattention_core___024root___eval_phase__stl(Vattention_core___024root* vlSelf);

VL_ATTR_COLD void Vattention_core___024root___eval_settle(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_settle\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vattention_core___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/attention_core.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vattention_core___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__stl(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___dump_triggers__stl\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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

void Vattention_core___024root___ico_sequent__TOP__0(Vattention_core___024root* vlSelf);

VL_ATTR_COLD void Vattention_core___024root___eval_stl(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_stl\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vattention_core___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vattention_core___024root___eval_triggers__stl(Vattention_core___024root* vlSelf);

VL_ATTR_COLD bool Vattention_core___024root___eval_phase__stl(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_phase__stl\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vattention_core___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vattention_core___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__ico(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___dump_triggers__ico\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__act(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___dump_triggers__act\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(posedge rst)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__nba(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___dump_triggers__nba\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(posedge rst)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vattention_core___024root___ctor_var_reset(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___ctor_var_reset\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->start = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->q[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->k[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->v[__Vi0] = VL_RAND_RESET_I(16);
    }
    vlSelf->done = VL_RAND_RESET_I(1);
    vlSelf->y = VL_RAND_RESET_I(16);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->attention_core__DOT__softmax_out[__Vi0] = VL_RAND_RESET_I(16);
    }
    vlSelf->attention_core__DOT__state = VL_RAND_RESET_I(2);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->attention_core__DOT__qk_vector[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->attention_core__DOT__softmax_inst__DOT__exp_out[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->attention_core__DOT__apply_inst__DOT__mul[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst__0 = VL_RAND_RESET_I(1);
}
