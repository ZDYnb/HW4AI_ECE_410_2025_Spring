// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vexp_taylor.h for the primary calling header

#include "Vexp_taylor__pch.h"
#include "Vexp_taylor___024root.h"

void Vexp_taylor___024root___ico_sequent__TOP__0(Vexp_taylor___024root* vlSelf);

void Vexp_taylor___024root___eval_ico(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_ico\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vexp_taylor___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vexp_taylor___024root___ico_sequent__TOP__0(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___ico_sequent__TOP__0\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ exp_taylor__DOT__x1;
    exp_taylor__DOT__x1 = 0;
    IData/*31:0*/ exp_taylor__DOT__x2;
    exp_taylor__DOT__x2 = 0;
    IData/*31:0*/ exp_taylor__DOT__x3;
    exp_taylor__DOT__x3 = 0;
    IData/*31:0*/ exp_taylor__DOT__x4;
    exp_taylor__DOT__x4 = 0;
    IData/*31:0*/ exp_taylor__DOT__term1;
    exp_taylor__DOT__term1 = 0;
    IData/*31:0*/ exp_taylor__DOT__term2;
    exp_taylor__DOT__term2 = 0;
    IData/*31:0*/ exp_taylor__DOT__term3;
    exp_taylor__DOT__term3 = 0;
    IData/*31:0*/ exp_taylor__DOT__term4;
    exp_taylor__DOT__term4 = 0;
    IData/*31:0*/ exp_taylor__DOT__sum;
    exp_taylor__DOT__sum = 0;
    // Body
    exp_taylor__DOT__x1 = 0U;
    exp_taylor__DOT__x2 = 0U;
    exp_taylor__DOT__x3 = 0U;
    exp_taylor__DOT__x4 = 0U;
    exp_taylor__DOT__term1 = 0U;
    exp_taylor__DOT__term2 = 0U;
    exp_taylor__DOT__term3 = 0U;
    exp_taylor__DOT__term4 = 0U;
    exp_taylor__DOT__sum = 0U;
    vlSelfRef.y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, (IData)(vlSelfRef.x_q88))) {
        vlSelfRef.y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, (IData)(vlSelfRef.x_q88))) {
        vlSelfRef.y_q88 = 0xffffU;
    } else {
        exp_taylor__DOT__x1 = VL_EXTENDS_II(32,16, (IData)(vlSelfRef.x_q88));
        exp_taylor__DOT__x2 = VL_SHIFTRS_III(32,32,32, 
                                             VL_MULS_III(32, exp_taylor__DOT__x1, exp_taylor__DOT__x1), 8U);
        exp_taylor__DOT__x3 = VL_SHIFTRS_III(32,32,32, 
                                             VL_MULS_III(32, exp_taylor__DOT__x2, exp_taylor__DOT__x1), 8U);
        exp_taylor__DOT__x4 = VL_SHIFTRS_III(32,32,32, 
                                             VL_MULS_III(32, exp_taylor__DOT__x3, exp_taylor__DOT__x1), 8U);
        exp_taylor__DOT__term1 = exp_taylor__DOT__x1;
        exp_taylor__DOT__term2 = VL_DIVS_III(32, exp_taylor__DOT__x2, (IData)(2U));
        exp_taylor__DOT__term3 = VL_DIVS_III(32, exp_taylor__DOT__x3, (IData)(6U));
        exp_taylor__DOT__term4 = VL_DIVS_III(32, exp_taylor__DOT__x4, (IData)(0x18U));
        exp_taylor__DOT__sum = ((IData)(0x100U) + (
                                                   ((exp_taylor__DOT__term1 
                                                     + exp_taylor__DOT__term2) 
                                                    + exp_taylor__DOT__term3) 
                                                   + exp_taylor__DOT__term4));
        vlSelfRef.y_q88 = (0xffffU & exp_taylor__DOT__sum);
    }
}

void Vexp_taylor___024root___eval_triggers__ico(Vexp_taylor___024root* vlSelf);

bool Vexp_taylor___024root___eval_phase__ico(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_phase__ico\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vexp_taylor___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vexp_taylor___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vexp_taylor___024root___eval_act(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_act\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vexp_taylor___024root___eval_nba(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_nba\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vexp_taylor___024root___eval_triggers__act(Vexp_taylor___024root* vlSelf);

bool Vexp_taylor___024root___eval_phase__act(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_phase__act\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vexp_taylor___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vexp_taylor___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vexp_taylor___024root___eval_phase__nba(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_phase__nba\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vexp_taylor___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vexp_taylor___024root___dump_triggers__ico(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vexp_taylor___024root___dump_triggers__nba(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vexp_taylor___024root___dump_triggers__act(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG

void Vexp_taylor___024root___eval(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vexp_taylor___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/exp_taylor.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vexp_taylor___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vexp_taylor___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/exp_taylor.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vexp_taylor___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/exp_taylor.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vexp_taylor___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vexp_taylor___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vexp_taylor___024root___eval_debug_assertions(Vexp_taylor___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vexp_taylor___024root___eval_debug_assertions\n"); );
    Vexp_taylor__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
