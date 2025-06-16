// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vqkv_linear.h for the primary calling header

#include "Vqkv_linear__pch.h"
#include "Vqkv_linear___024root.h"

VL_ATTR_COLD void Vqkv_linear___024root___eval_static(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_static\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__rst__0 = vlSelfRef.rst;
}

VL_ATTR_COLD void Vqkv_linear___024root___eval_initial__TOP(Vqkv_linear___024root* vlSelf);

VL_ATTR_COLD void Vqkv_linear___024root___eval_initial(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_initial\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vqkv_linear___024root___eval_initial__TOP(vlSelf);
}

VL_ATTR_COLD void Vqkv_linear___024root___eval_initial__TOP(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_initial__TOP\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.qkv_linear__DOT__WQ[0U][0U] = 1U;
    vlSelfRef.qkv_linear__DOT__WQ[0U][1U] = 2U;
    vlSelfRef.qkv_linear__DOT__WQ[0U][2U] = 3U;
    vlSelfRef.qkv_linear__DOT__WQ[0U][3U] = 4U;
    vlSelfRef.qkv_linear__DOT__WQ[1U][0U] = 4U;
    vlSelfRef.qkv_linear__DOT__WQ[1U][1U] = 3U;
    vlSelfRef.qkv_linear__DOT__WQ[1U][2U] = 2U;
    vlSelfRef.qkv_linear__DOT__WQ[1U][3U] = 1U;
    vlSelfRef.qkv_linear__DOT__WQ[2U][0U] = 1U;
    vlSelfRef.qkv_linear__DOT__WQ[2U][1U] = 0xffffU;
    vlSelfRef.qkv_linear__DOT__WQ[2U][2U] = 1U;
    vlSelfRef.qkv_linear__DOT__WQ[2U][3U] = 0xffffU;
    vlSelfRef.qkv_linear__DOT__WQ[3U][0U] = 2U;
    vlSelfRef.qkv_linear__DOT__WQ[3U][1U] = 2U;
    vlSelfRef.qkv_linear__DOT__WQ[3U][2U] = 2U;
    vlSelfRef.qkv_linear__DOT__WQ[3U][3U] = 2U;
    vlSelfRef.qkv_linear__DOT__WK[0U][0U] = 1U;
    vlSelfRef.qkv_linear__DOT__WK[0U][1U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[0U][2U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[0U][3U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[1U][0U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[1U][1U] = 1U;
    vlSelfRef.qkv_linear__DOT__WK[1U][2U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[1U][3U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[2U][0U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[2U][1U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[2U][2U] = 1U;
    vlSelfRef.qkv_linear__DOT__WK[2U][3U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[3U][0U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[3U][1U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[3U][2U] = 0U;
    vlSelfRef.qkv_linear__DOT__WK[3U][3U] = 1U;
    vlSelfRef.qkv_linear__DOT__WV[0U][0U] = 2U;
    vlSelfRef.qkv_linear__DOT__WV[0U][1U] = 2U;
    vlSelfRef.qkv_linear__DOT__WV[0U][2U] = 2U;
    vlSelfRef.qkv_linear__DOT__WV[0U][3U] = 2U;
    vlSelfRef.qkv_linear__DOT__WV[1U][0U] = 0xfffeU;
    vlSelfRef.qkv_linear__DOT__WV[1U][1U] = 0xfffeU;
    vlSelfRef.qkv_linear__DOT__WV[1U][2U] = 0xfffeU;
    vlSelfRef.qkv_linear__DOT__WV[1U][3U] = 0xfffeU;
    vlSelfRef.qkv_linear__DOT__WV[2U][0U] = 1U;
    vlSelfRef.qkv_linear__DOT__WV[2U][1U] = 0U;
    vlSelfRef.qkv_linear__DOT__WV[2U][2U] = 0xffffU;
    vlSelfRef.qkv_linear__DOT__WV[2U][3U] = 0U;
    vlSelfRef.qkv_linear__DOT__WV[3U][0U] = 0U;
    vlSelfRef.qkv_linear__DOT__WV[3U][1U] = 1U;
    vlSelfRef.qkv_linear__DOT__WV[3U][2U] = 0U;
    vlSelfRef.qkv_linear__DOT__WV[3U][3U] = 0xffffU;
}

VL_ATTR_COLD void Vqkv_linear___024root___eval_final(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_final\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vqkv_linear___024root___eval_settle(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_settle\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vqkv_linear___024root___dump_triggers__act(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___dump_triggers__act\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
VL_ATTR_COLD void Vqkv_linear___024root___dump_triggers__nba(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___dump_triggers__nba\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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

VL_ATTR_COLD void Vqkv_linear___024root___ctor_var_reset(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___ctor_var_reset\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->start = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->x[__Vi0] = VL_RAND_RESET_I(16);
    }
    vlSelf->done = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->q[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->k[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->v[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->qkv_linear__DOT__q_acc[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->qkv_linear__DOT__k_acc[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->qkv_linear__DOT__v_acc[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->qkv_linear__DOT__WQ[__Vi0][__Vi1] = VL_RAND_RESET_I(16);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->qkv_linear__DOT__WK[__Vi0][__Vi1] = VL_RAND_RESET_I(16);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->qkv_linear__DOT__WV[__Vi0][__Vi1] = VL_RAND_RESET_I(16);
        }
    }
    vlSelf->qkv_linear__DOT__state = VL_RAND_RESET_I(2);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst__0 = VL_RAND_RESET_I(1);
}
