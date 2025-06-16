// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtoken_embedding.h for the primary calling header

#include "Vtoken_embedding__pch.h"
#include "Vtoken_embedding___024root.h"

VL_ATTR_COLD void Vtoken_embedding___024root___eval_static(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_static\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
}

VL_ATTR_COLD void Vtoken_embedding___024root___eval_initial__TOP(Vtoken_embedding___024root* vlSelf);

VL_ATTR_COLD void Vtoken_embedding___024root___eval_initial(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_initial\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtoken_embedding___024root___eval_initial__TOP(vlSelf);
}

VL_ATTR_COLD void Vtoken_embedding___024root___eval_initial__TOP(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_initial__TOP\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.token_embedding__DOT__rom[0U][0U] = 1U;
    vlSelfRef.token_embedding__DOT__rom[0U][1U] = 2U;
    vlSelfRef.token_embedding__DOT__rom[0U][2U] = 3U;
    vlSelfRef.token_embedding__DOT__rom[0U][3U] = 4U;
    vlSelfRef.token_embedding__DOT__rom[1U][0U] = 5U;
    vlSelfRef.token_embedding__DOT__rom[1U][1U] = 6U;
    vlSelfRef.token_embedding__DOT__rom[1U][2U] = 7U;
    vlSelfRef.token_embedding__DOT__rom[1U][3U] = 8U;
    vlSelfRef.token_embedding__DOT__rom[2U][0U] = 9U;
    vlSelfRef.token_embedding__DOT__rom[2U][1U] = 0xaU;
    vlSelfRef.token_embedding__DOT__rom[2U][2U] = 0xbU;
    vlSelfRef.token_embedding__DOT__rom[2U][3U] = 0xcU;
}

VL_ATTR_COLD void Vtoken_embedding___024root___eval_final(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_final\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vtoken_embedding___024root___eval_settle(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_settle\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtoken_embedding___024root___dump_triggers__act(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___dump_triggers__act\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtoken_embedding___024root___dump_triggers__nba(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___dump_triggers__nba\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtoken_embedding___024root___ctor_var_reset(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___ctor_var_reset\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->token_id = VL_RAND_RESET_I(4);
    vlSelf->embedding_vector0 = VL_RAND_RESET_I(8);
    vlSelf->embedding_vector1 = VL_RAND_RESET_I(8);
    vlSelf->embedding_vector2 = VL_RAND_RESET_I(8);
    vlSelf->embedding_vector3 = VL_RAND_RESET_I(8);
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->token_embedding__DOT__rom[__Vi0][__Vi1] = VL_RAND_RESET_I(8);
        }
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
}
