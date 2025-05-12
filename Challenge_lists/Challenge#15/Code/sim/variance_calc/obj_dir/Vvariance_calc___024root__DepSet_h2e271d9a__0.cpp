// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vvariance_calc.h for the primary calling header

#include "Vvariance_calc__pch.h"
#include "Vvariance_calc___024root.h"

void Vvariance_calc___024root___ico_sequent__TOP__0(Vvariance_calc___024root* vlSelf);

void Vvariance_calc___024root___eval_ico(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_ico\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vvariance_calc___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vvariance_calc___024root___ico_sequent__TOP__0(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___ico_sequent__TOP__0\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*16:0*/ variance_calc__DOT__diff;
    variance_calc__DOT__diff = 0;
    IData/*31:0*/ variance_calc__DOT__diff_sq;
    variance_calc__DOT__diff_sq = 0;
    IData/*31:0*/ variance_calc__DOT__sum;
    variance_calc__DOT__sum = 0;
    IData/*31:0*/ variance_calc__DOT__avg;
    variance_calc__DOT__avg = 0;
    // Body
    variance_calc__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                          vlSelfRef.x
                                                          [0U]) 
                                            - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    variance_calc__DOT__diff_sq = VL_MULS_III(32, VL_EXTENDS_II(32,17, variance_calc__DOT__diff), 
                                              VL_EXTENDS_II(32,17, variance_calc__DOT__diff));
    variance_calc__DOT__sum = variance_calc__DOT__diff_sq;
    variance_calc__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                          vlSelfRef.x
                                                          [1U]) 
                                            - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    variance_calc__DOT__diff_sq = VL_MULS_III(32, VL_EXTENDS_II(32,17, variance_calc__DOT__diff), 
                                              VL_EXTENDS_II(32,17, variance_calc__DOT__diff));
    variance_calc__DOT__sum = (variance_calc__DOT__sum 
                               + variance_calc__DOT__diff_sq);
    variance_calc__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                          vlSelfRef.x
                                                          [2U]) 
                                            - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    variance_calc__DOT__diff_sq = VL_MULS_III(32, VL_EXTENDS_II(32,17, variance_calc__DOT__diff), 
                                              VL_EXTENDS_II(32,17, variance_calc__DOT__diff));
    variance_calc__DOT__sum = (variance_calc__DOT__sum 
                               + variance_calc__DOT__diff_sq);
    variance_calc__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                          vlSelfRef.x
                                                          [3U]) 
                                            - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    variance_calc__DOT__diff_sq = VL_MULS_III(32, VL_EXTENDS_II(32,17, variance_calc__DOT__diff), 
                                              VL_EXTENDS_II(32,17, variance_calc__DOT__diff));
    variance_calc__DOT__sum = (variance_calc__DOT__sum 
                               + variance_calc__DOT__diff_sq);
    variance_calc__DOT__avg = VL_SHIFTRS_III(32,32,32, variance_calc__DOT__sum, 2U);
    vlSelfRef.variance = (0xffffU & (variance_calc__DOT__avg 
                                     >> 8U));
}

void Vvariance_calc___024root___eval_triggers__ico(Vvariance_calc___024root* vlSelf);

bool Vvariance_calc___024root___eval_phase__ico(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_phase__ico\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vvariance_calc___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vvariance_calc___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vvariance_calc___024root___eval_act(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_act\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vvariance_calc___024root___eval_nba(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_nba\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vvariance_calc___024root___eval_triggers__act(Vvariance_calc___024root* vlSelf);

bool Vvariance_calc___024root___eval_phase__act(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_phase__act\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vvariance_calc___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vvariance_calc___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vvariance_calc___024root___eval_phase__nba(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_phase__nba\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vvariance_calc___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vvariance_calc___024root___dump_triggers__ico(Vvariance_calc___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vvariance_calc___024root___dump_triggers__nba(Vvariance_calc___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vvariance_calc___024root___dump_triggers__act(Vvariance_calc___024root* vlSelf);
#endif  // VL_DEBUG

void Vvariance_calc___024root___eval(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vvariance_calc___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/variance_calc.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vvariance_calc___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vvariance_calc___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/variance_calc.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vvariance_calc___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/variance_calc.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vvariance_calc___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vvariance_calc___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vvariance_calc___024root___eval_debug_assertions(Vvariance_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvariance_calc___024root___eval_debug_assertions\n"); );
    Vvariance_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
