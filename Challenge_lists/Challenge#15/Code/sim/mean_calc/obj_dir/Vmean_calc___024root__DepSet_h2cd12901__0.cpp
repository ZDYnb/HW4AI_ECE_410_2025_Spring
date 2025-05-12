// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmean_calc.h for the primary calling header

#include "Vmean_calc__pch.h"
#include "Vmean_calc___024root.h"

void Vmean_calc___024root___ico_sequent__TOP__0(Vmean_calc___024root* vlSelf);

void Vmean_calc___024root___eval_ico(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_ico\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vmean_calc___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vmean_calc___024root___ico_sequent__TOP__0(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___ico_sequent__TOP__0\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*19:0*/ mean_calc__DOT__sum;
    mean_calc__DOT__sum = 0;
    // Body
    mean_calc__DOT__sum = ((0x70000U & ((- (IData)(
                                                   (1U 
                                                    & (vlSelfRef.x
                                                       [0U] 
                                                       >> 0xfU)))) 
                                        << 0x10U)) 
                           | vlSelfRef.x[0U]);
    mean_calc__DOT__sum = (0xfffffU & (mean_calc__DOT__sum 
                                       + ((0x70000U 
                                           & ((- (IData)(
                                                         (1U 
                                                          & (vlSelfRef.x
                                                             [1U] 
                                                             >> 0xfU)))) 
                                              << 0x10U)) 
                                          | vlSelfRef.x
                                          [1U])));
    mean_calc__DOT__sum = (0xfffffU & (mean_calc__DOT__sum 
                                       + ((0x70000U 
                                           & ((- (IData)(
                                                         (1U 
                                                          & (vlSelfRef.x
                                                             [2U] 
                                                             >> 0xfU)))) 
                                              << 0x10U)) 
                                          | vlSelfRef.x
                                          [2U])));
    mean_calc__DOT__sum = (0xfffffU & (mean_calc__DOT__sum 
                                       + ((0x70000U 
                                           & ((- (IData)(
                                                         (1U 
                                                          & (vlSelfRef.x
                                                             [3U] 
                                                             >> 0xfU)))) 
                                              << 0x10U)) 
                                          | vlSelfRef.x
                                          [3U])));
    vlSelfRef.mean = (0xffffU & (mean_calc__DOT__sum 
                                 >> 2U));
}

void Vmean_calc___024root___eval_triggers__ico(Vmean_calc___024root* vlSelf);

bool Vmean_calc___024root___eval_phase__ico(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_phase__ico\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vmean_calc___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vmean_calc___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vmean_calc___024root___eval_act(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_act\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vmean_calc___024root___eval_nba(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_nba\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vmean_calc___024root___eval_triggers__act(Vmean_calc___024root* vlSelf);

bool Vmean_calc___024root___eval_phase__act(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_phase__act\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vmean_calc___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vmean_calc___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vmean_calc___024root___eval_phase__nba(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_phase__nba\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vmean_calc___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__ico(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__nba(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vmean_calc___024root___dump_triggers__act(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG

void Vmean_calc___024root___eval(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vmean_calc___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/mean_calc.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vmean_calc___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vmean_calc___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/mean_calc.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vmean_calc___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/mean_calc.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vmean_calc___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vmean_calc___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vmean_calc___024root___eval_debug_assertions(Vmean_calc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmean_calc___024root___eval_debug_assertions\n"); );
    Vmean_calc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
