// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlayernorm.h for the primary calling header

#include "Vlayernorm__pch.h"
#include "Vlayernorm___024root.h"

void Vlayernorm___024root___ico_sequent__TOP__0(Vlayernorm___024root* vlSelf);

void Vlayernorm___024root___eval_ico(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_ico\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vlayernorm___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vlayernorm___024root___ico_sequent__TOP__0(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___ico_sequent__TOP__0\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.layernorm__DOT__in_vector[0U] = (0xffU 
                                               & vlSelfRef.in_vector_flat);
    vlSelfRef.layernorm__DOT__in_vector[1U] = (0xffU 
                                               & (vlSelfRef.in_vector_flat 
                                                  >> 8U));
    vlSelfRef.layernorm__DOT__in_vector[2U] = (0xffU 
                                               & (vlSelfRef.in_vector_flat 
                                                  >> 0x10U));
    vlSelfRef.layernorm__DOT__in_vector[3U] = (vlSelfRef.in_vector_flat 
                                               >> 0x18U);
}

void Vlayernorm___024root___eval_triggers__ico(Vlayernorm___024root* vlSelf);

bool Vlayernorm___024root___eval_phase__ico(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_phase__ico\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vlayernorm___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vlayernorm___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vlayernorm___024root___eval_act(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_act\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vlayernorm___024root___nba_sequent__TOP__0(Vlayernorm___024root* vlSelf);

void Vlayernorm___024root___eval_nba(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_nba\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vlayernorm___024root___nba_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vlayernorm___024root___nba_sequent__TOP__0(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___nba_sequent__TOP__0\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*7:0*/ __VdlyVal__layernorm__DOT__out_vector__v0;
    __VdlyVal__layernorm__DOT__out_vector__v0 = 0;
    CData/*0:0*/ __VdlySet__layernorm__DOT__out_vector__v0;
    __VdlySet__layernorm__DOT__out_vector__v0 = 0;
    CData/*7:0*/ __VdlyVal__layernorm__DOT__out_vector__v1;
    __VdlyVal__layernorm__DOT__out_vector__v1 = 0;
    CData/*7:0*/ __VdlyVal__layernorm__DOT__out_vector__v2;
    __VdlyVal__layernorm__DOT__out_vector__v2 = 0;
    CData/*7:0*/ __VdlyVal__layernorm__DOT__out_vector__v3;
    __VdlyVal__layernorm__DOT__out_vector__v3 = 0;
    // Body
    __VdlySet__layernorm__DOT__out_vector__v0 = 0U;
    if ((1U & (~ (IData)(vlSelfRef.rst)))) {
        __VdlyVal__layernorm__DOT__out_vector__v0 = 
            vlSelfRef.layernorm__DOT__in_vector[0U];
        __VdlySet__layernorm__DOT__out_vector__v0 = 1U;
        __VdlyVal__layernorm__DOT__out_vector__v1 = 
            vlSelfRef.layernorm__DOT__in_vector[1U];
        __VdlyVal__layernorm__DOT__out_vector__v2 = 
            vlSelfRef.layernorm__DOT__in_vector[2U];
        __VdlyVal__layernorm__DOT__out_vector__v3 = 
            vlSelfRef.layernorm__DOT__in_vector[3U];
    }
    if (__VdlySet__layernorm__DOT__out_vector__v0) {
        vlSelfRef.layernorm__DOT__out_vector[0U] = __VdlyVal__layernorm__DOT__out_vector__v0;
        vlSelfRef.layernorm__DOT__out_vector[1U] = __VdlyVal__layernorm__DOT__out_vector__v1;
        vlSelfRef.layernorm__DOT__out_vector[2U] = __VdlyVal__layernorm__DOT__out_vector__v2;
        vlSelfRef.layernorm__DOT__out_vector[3U] = __VdlyVal__layernorm__DOT__out_vector__v3;
    }
    vlSelfRef.out_vector_flat = ((0xff000000U & vlSelfRef.out_vector_flat) 
                                 | ((vlSelfRef.layernorm__DOT__out_vector
                                     [2U] << 0x10U) 
                                    | ((vlSelfRef.layernorm__DOT__out_vector
                                        [1U] << 8U) 
                                       | vlSelfRef.layernorm__DOT__out_vector
                                       [0U])));
    vlSelfRef.out_vector_flat = ((0xffffffU & vlSelfRef.out_vector_flat) 
                                 | (vlSelfRef.layernorm__DOT__out_vector
                                    [3U] << 0x18U));
}

void Vlayernorm___024root___eval_triggers__act(Vlayernorm___024root* vlSelf);

bool Vlayernorm___024root___eval_phase__act(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_phase__act\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vlayernorm___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vlayernorm___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vlayernorm___024root___eval_phase__nba(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_phase__nba\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vlayernorm___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm___024root___dump_triggers__ico(Vlayernorm___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm___024root___dump_triggers__nba(Vlayernorm___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm___024root___dump_triggers__act(Vlayernorm___024root* vlSelf);
#endif  // VL_DEBUG

void Vlayernorm___024root___eval(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vlayernorm___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../rtl/layernorm.sv", 2, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vlayernorm___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vlayernorm___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../rtl/layernorm.sv", 2, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vlayernorm___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../rtl/layernorm.sv", 2, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vlayernorm___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vlayernorm___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vlayernorm___024root___eval_debug_assertions(Vlayernorm___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm___024root___eval_debug_assertions\n"); );
    Vlayernorm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");}
}
#endif  // VL_DEBUG
