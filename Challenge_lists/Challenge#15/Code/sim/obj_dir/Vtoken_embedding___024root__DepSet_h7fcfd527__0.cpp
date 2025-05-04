// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtoken_embedding.h for the primary calling header

#include "Vtoken_embedding__pch.h"
#include "Vtoken_embedding___024root.h"

void Vtoken_embedding___024root___eval_act(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_act\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vtoken_embedding___024root___nba_sequent__TOP__0(Vtoken_embedding___024root* vlSelf);

void Vtoken_embedding___024root___eval_nba(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_nba\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtoken_embedding___024root___nba_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtoken_embedding___024root___nba_sequent__TOP__0(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___nba_sequent__TOP__0\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.embedding_vector0 = vlSelfRef.token_embedding__DOT__rom
        [vlSelfRef.token_id][0U];
    vlSelfRef.embedding_vector1 = vlSelfRef.token_embedding__DOT__rom
        [vlSelfRef.token_id][1U];
    vlSelfRef.embedding_vector2 = vlSelfRef.token_embedding__DOT__rom
        [vlSelfRef.token_id][2U];
    vlSelfRef.embedding_vector3 = vlSelfRef.token_embedding__DOT__rom
        [vlSelfRef.token_id][3U];
}

void Vtoken_embedding___024root___eval_triggers__act(Vtoken_embedding___024root* vlSelf);

bool Vtoken_embedding___024root___eval_phase__act(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_phase__act\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtoken_embedding___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vtoken_embedding___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtoken_embedding___024root___eval_phase__nba(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_phase__nba\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtoken_embedding___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtoken_embedding___024root___dump_triggers__nba(Vtoken_embedding___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtoken_embedding___024root___dump_triggers__act(Vtoken_embedding___024root* vlSelf);
#endif  // VL_DEBUG

void Vtoken_embedding___024root___eval(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtoken_embedding___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../rtl/token_embedding.v", 3, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vtoken_embedding___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../rtl/token_embedding.v", 3, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vtoken_embedding___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vtoken_embedding___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtoken_embedding___024root___eval_debug_assertions(Vtoken_embedding___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtoken_embedding___024root___eval_debug_assertions\n"); );
    Vtoken_embedding__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.token_id & 0xf0U)))) {
        Verilated::overWidthError("token_id");}
}
#endif  // VL_DEBUG
