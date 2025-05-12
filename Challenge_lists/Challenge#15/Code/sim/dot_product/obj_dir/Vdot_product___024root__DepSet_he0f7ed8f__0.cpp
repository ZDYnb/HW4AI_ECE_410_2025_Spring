// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdot_product.h for the primary calling header

#include "Vdot_product__pch.h"
#include "Vdot_product___024root.h"

void Vdot_product___024root___ico_sequent__TOP__0(Vdot_product___024root* vlSelf);

void Vdot_product___024root___eval_ico(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_ico\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vdot_product___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vdot_product___024root___ico_sequent__TOP__0(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___ico_sequent__TOP__0\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ dot_product__DOT__temp_sum;
    dot_product__DOT__temp_sum = 0;
    // Body
    dot_product__DOT__temp_sum = VL_MULS_III(32, VL_EXTENDS_II(32,16, 
                                                               vlSelfRef.a
                                                               [0U]), 
                                             VL_EXTENDS_II(32,16, 
                                                           vlSelfRef.b
                                                           [0U]));
    dot_product__DOT__temp_sum = (dot_product__DOT__temp_sum 
                                  + VL_MULS_III(32, 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.a
                                                              [1U]), 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.b
                                                              [1U])));
    dot_product__DOT__temp_sum = (dot_product__DOT__temp_sum 
                                  + VL_MULS_III(32, 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.a
                                                              [2U]), 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.b
                                                              [2U])));
    dot_product__DOT__temp_sum = (dot_product__DOT__temp_sum 
                                  + VL_MULS_III(32, 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.a
                                                              [3U]), 
                                                VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.b
                                                              [3U])));
    vlSelfRef.result = (0xffffU & dot_product__DOT__temp_sum);
}

void Vdot_product___024root___eval_triggers__ico(Vdot_product___024root* vlSelf);

bool Vdot_product___024root___eval_phase__ico(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_phase__ico\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vdot_product___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vdot_product___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vdot_product___024root___eval_act(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_act\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vdot_product___024root___eval_nba(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_nba\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vdot_product___024root___eval_triggers__act(Vdot_product___024root* vlSelf);

bool Vdot_product___024root___eval_phase__act(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_phase__act\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vdot_product___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vdot_product___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vdot_product___024root___eval_phase__nba(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_phase__nba\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vdot_product___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdot_product___024root___dump_triggers__ico(Vdot_product___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vdot_product___024root___dump_triggers__nba(Vdot_product___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vdot_product___024root___dump_triggers__act(Vdot_product___024root* vlSelf);
#endif  // VL_DEBUG

void Vdot_product___024root___eval(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vdot_product___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/dot_product.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vdot_product___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vdot_product___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/dot_product.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vdot_product___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/dot_product.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vdot_product___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vdot_product___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vdot_product___024root___eval_debug_assertions(Vdot_product___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdot_product___024root___eval_debug_assertions\n"); );
    Vdot_product__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
