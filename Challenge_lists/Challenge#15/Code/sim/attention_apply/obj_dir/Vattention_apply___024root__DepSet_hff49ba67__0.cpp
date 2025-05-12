// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vattention_apply.h for the primary calling header

#include "Vattention_apply__pch.h"
#include "Vattention_apply___024root.h"

void Vattention_apply___024root___ico_sequent__TOP__0(Vattention_apply___024root* vlSelf);

void Vattention_apply___024root___eval_ico(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_ico\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vattention_apply___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vattention_apply___024root___ico_sequent__TOP__0(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___ico_sequent__TOP__0\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    QData/*34:0*/ attention_apply__DOT__sum;
    attention_apply__DOT__sum = 0;
    // Body
    vlSelfRef.attention_apply__DOT__mul[0U] = VL_MULS_III(32, 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.weights
                                                                        [0U]), 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.v
                                                                        [0U]));
    attention_apply__DOT__sum = (0x7ffffffffULL & VL_EXTENDS_QI(35,32, 
                                                                vlSelfRef.attention_apply__DOT__mul
                                                                [0U]));
    vlSelfRef.attention_apply__DOT__mul[1U] = VL_MULS_III(32, 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.weights
                                                                        [1U]), 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.v
                                                                        [1U]));
    attention_apply__DOT__sum = (0x7ffffffffULL & (attention_apply__DOT__sum 
                                                   + 
                                                   VL_EXTENDS_QI(35,32, 
                                                                 vlSelfRef.attention_apply__DOT__mul
                                                                 [1U])));
    vlSelfRef.attention_apply__DOT__mul[2U] = VL_MULS_III(32, 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.weights
                                                                        [2U]), 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.v
                                                                        [2U]));
    attention_apply__DOT__sum = (0x7ffffffffULL & (attention_apply__DOT__sum 
                                                   + 
                                                   VL_EXTENDS_QI(35,32, 
                                                                 vlSelfRef.attention_apply__DOT__mul
                                                                 [2U])));
    vlSelfRef.attention_apply__DOT__mul[3U] = VL_MULS_III(32, 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.weights
                                                                        [3U]), 
                                                          VL_EXTENDS_II(32,16, 
                                                                        vlSelfRef.v
                                                                        [3U]));
    attention_apply__DOT__sum = (0x7ffffffffULL & (attention_apply__DOT__sum 
                                                   + 
                                                   VL_EXTENDS_QI(35,32, 
                                                                 vlSelfRef.attention_apply__DOT__mul
                                                                 [3U])));
    vlSelfRef.out = (0xffffU & (IData)((attention_apply__DOT__sum 
                                        >> 8U)));
}

void Vattention_apply___024root___eval_triggers__ico(Vattention_apply___024root* vlSelf);

bool Vattention_apply___024root___eval_phase__ico(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_phase__ico\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vattention_apply___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vattention_apply___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vattention_apply___024root___eval_act(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_act\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vattention_apply___024root___eval_nba(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_nba\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vattention_apply___024root___eval_triggers__act(Vattention_apply___024root* vlSelf);

bool Vattention_apply___024root___eval_phase__act(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_phase__act\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vattention_apply___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vattention_apply___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vattention_apply___024root___eval_phase__nba(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_phase__nba\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vattention_apply___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_apply___024root___dump_triggers__ico(Vattention_apply___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_apply___024root___dump_triggers__nba(Vattention_apply___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_apply___024root___dump_triggers__act(Vattention_apply___024root* vlSelf);
#endif  // VL_DEBUG

void Vattention_apply___024root___eval(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY(((0x64U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vattention_apply___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/attention_apply.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vattention_apply___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vattention_apply___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/attention_apply.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vattention_apply___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/attention_apply.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vattention_apply___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vattention_apply___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vattention_apply___024root___eval_debug_assertions(Vattention_apply___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_apply___024root___eval_debug_assertions\n"); );
    Vattention_apply__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
