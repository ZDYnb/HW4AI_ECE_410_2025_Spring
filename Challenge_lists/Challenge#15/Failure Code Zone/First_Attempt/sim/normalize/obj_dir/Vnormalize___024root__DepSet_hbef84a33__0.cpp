// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vnormalize.h for the primary calling header

#include "Vnormalize__pch.h"
#include "Vnormalize___024root.h"

void Vnormalize___024root___ico_sequent__TOP__0(Vnormalize___024root* vlSelf);

void Vnormalize___024root___eval_ico(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_ico\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vnormalize___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vnormalize___024root___ico_sequent__TOP__0(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___ico_sequent__TOP__0\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*16:0*/ normalize__DOT__diff;
    normalize__DOT__diff = 0;
    IData/*31:0*/ normalize__DOT__scaled_diff;
    normalize__DOT__scaled_diff = 0;
    IData/*31:0*/ normalize__DOT__result;
    normalize__DOT__result = 0;
    // Body
    normalize__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                      vlSelfRef.x
                                                      [0U]) 
                                        - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    normalize__DOT__scaled_diff = VL_SHIFTL_III(32,32,32, 
                                                VL_EXTENDS_II(32,17, normalize__DOT__diff), 8U);
    normalize__DOT__result = VL_DIVS_III(32, normalize__DOT__scaled_diff, 
                                         VL_EXTENDS_II(32,16, (IData)(vlSelfRef.stddev)));
    vlSelfRef.norm_x[0U] = (0xffffU & normalize__DOT__result);
    normalize__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                      vlSelfRef.x
                                                      [1U]) 
                                        - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    normalize__DOT__scaled_diff = VL_SHIFTL_III(32,32,32, 
                                                VL_EXTENDS_II(32,17, normalize__DOT__diff), 8U);
    normalize__DOT__result = VL_DIVS_III(32, normalize__DOT__scaled_diff, 
                                         VL_EXTENDS_II(32,16, (IData)(vlSelfRef.stddev)));
    vlSelfRef.norm_x[1U] = (0xffffU & normalize__DOT__result);
    normalize__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                      vlSelfRef.x
                                                      [2U]) 
                                        - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    normalize__DOT__scaled_diff = VL_SHIFTL_III(32,32,32, 
                                                VL_EXTENDS_II(32,17, normalize__DOT__diff), 8U);
    normalize__DOT__result = VL_DIVS_III(32, normalize__DOT__scaled_diff, 
                                         VL_EXTENDS_II(32,16, (IData)(vlSelfRef.stddev)));
    vlSelfRef.norm_x[2U] = (0xffffU & normalize__DOT__result);
    normalize__DOT__diff = (0x1ffffU & (VL_EXTENDS_II(17,16, 
                                                      vlSelfRef.x
                                                      [3U]) 
                                        - VL_EXTENDS_II(17,16, (IData)(vlSelfRef.mean))));
    normalize__DOT__scaled_diff = VL_SHIFTL_III(32,32,32, 
                                                VL_EXTENDS_II(32,17, normalize__DOT__diff), 8U);
    normalize__DOT__result = VL_DIVS_III(32, normalize__DOT__scaled_diff, 
                                         VL_EXTENDS_II(32,16, (IData)(vlSelfRef.stddev)));
    vlSelfRef.norm_x[3U] = (0xffffU & normalize__DOT__result);
}

void Vnormalize___024root___eval_triggers__ico(Vnormalize___024root* vlSelf);

bool Vnormalize___024root___eval_phase__ico(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_phase__ico\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vnormalize___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vnormalize___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vnormalize___024root___eval_act(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_act\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vnormalize___024root___eval_nba(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_nba\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vnormalize___024root___eval_triggers__act(Vnormalize___024root* vlSelf);

bool Vnormalize___024root___eval_phase__act(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_phase__act\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vnormalize___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vnormalize___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vnormalize___024root___eval_phase__nba(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_phase__nba\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vnormalize___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__ico(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__nba(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vnormalize___024root___dump_triggers__act(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG

void Vnormalize___024root___eval(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vnormalize___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/normalize.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vnormalize___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vnormalize___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/normalize.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vnormalize___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/normalize.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vnormalize___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vnormalize___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vnormalize___024root___eval_debug_assertions(Vnormalize___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vnormalize___024root___eval_debug_assertions\n"); );
    Vnormalize__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
