// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vqkv_linear.h for the primary calling header

#include "Vqkv_linear__pch.h"
#include "Vqkv_linear___024root.h"

void Vqkv_linear___024root___eval_act(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_act\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vqkv_linear___024root___nba_sequent__TOP__0(Vqkv_linear___024root* vlSelf);

void Vqkv_linear___024root___eval_nba(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_nba\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vqkv_linear___024root___nba_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vqkv_linear___024root___nba_sequent__TOP__0(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___nba_sequent__TOP__0\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*1:0*/ __Vdly__qkv_linear__DOT__state;
    __Vdly__qkv_linear__DOT__state = 0;
    SData/*15:0*/ __VdlyVal__q__v0;
    __VdlyVal__q__v0 = 0;
    CData/*0:0*/ __VdlySet__q__v0;
    __VdlySet__q__v0 = 0;
    SData/*15:0*/ __VdlyVal__k__v0;
    __VdlyVal__k__v0 = 0;
    SData/*15:0*/ __VdlyVal__v__v0;
    __VdlyVal__v__v0 = 0;
    SData/*15:0*/ __VdlyVal__q__v1;
    __VdlyVal__q__v1 = 0;
    CData/*0:0*/ __VdlySet__q__v1;
    __VdlySet__q__v1 = 0;
    SData/*15:0*/ __VdlyVal__k__v1;
    __VdlyVal__k__v1 = 0;
    SData/*15:0*/ __VdlyVal__v__v1;
    __VdlyVal__v__v1 = 0;
    SData/*15:0*/ __VdlyVal__q__v2;
    __VdlyVal__q__v2 = 0;
    SData/*15:0*/ __VdlyVal__k__v2;
    __VdlyVal__k__v2 = 0;
    SData/*15:0*/ __VdlyVal__v__v2;
    __VdlyVal__v__v2 = 0;
    SData/*15:0*/ __VdlyVal__q__v3;
    __VdlyVal__q__v3 = 0;
    SData/*15:0*/ __VdlyVal__k__v3;
    __VdlyVal__k__v3 = 0;
    SData/*15:0*/ __VdlyVal__v__v3;
    __VdlyVal__v__v3 = 0;
    // Body
    __Vdly__qkv_linear__DOT__state = vlSelfRef.qkv_linear__DOT__state;
    __VdlySet__q__v0 = 0U;
    __VdlySet__q__v1 = 0U;
    if (vlSelfRef.rst) {
        vlSelfRef.done = 0U;
        __Vdly__qkv_linear__DOT__state = 0U;
    } else if ((0U == (IData)(vlSelfRef.qkv_linear__DOT__state))) {
        vlSelfRef.done = 0U;
        if (vlSelfRef.start) {
            vlSelfRef.qkv_linear__DOT__q_acc[0U] = 0U;
            vlSelfRef.qkv_linear__DOT__k_acc[0U] = 0U;
            vlSelfRef.qkv_linear__DOT__v_acc[0U] = 0U;
            vlSelfRef.qkv_linear__DOT__q_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [0U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__k_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [0U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__v_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [0U]
                                               [0U])));
            __Vdly__qkv_linear__DOT__state = 1U;
            vlSelfRef.qkv_linear__DOT__q_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [0U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__k_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [0U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__v_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [0U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__q_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [0U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__k_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [0U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__v_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [0U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__q_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [0U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__k_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [0U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__v_acc[0U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [0U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [0U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__q_acc[1U] = 0U;
            vlSelfRef.qkv_linear__DOT__k_acc[1U] = 0U;
            vlSelfRef.qkv_linear__DOT__v_acc[1U] = 0U;
            vlSelfRef.qkv_linear__DOT__q_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [1U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__k_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [1U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__v_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [1U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__q_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [1U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__k_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [1U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__v_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [1U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__q_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [1U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__k_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [1U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__v_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [1U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__q_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [1U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__k_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [1U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__v_acc[1U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [1U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [1U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__q_acc[2U] = 0U;
            vlSelfRef.qkv_linear__DOT__k_acc[2U] = 0U;
            vlSelfRef.qkv_linear__DOT__v_acc[2U] = 0U;
            vlSelfRef.qkv_linear__DOT__q_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [2U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__k_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [2U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__v_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [2U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__q_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [2U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__k_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [2U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__v_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [2U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__q_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [2U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__k_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [2U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__v_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [2U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__q_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [2U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__k_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [2U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__v_acc[2U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [2U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [2U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__q_acc[3U] = 0U;
            vlSelfRef.qkv_linear__DOT__k_acc[3U] = 0U;
            vlSelfRef.qkv_linear__DOT__v_acc[3U] = 0U;
            vlSelfRef.qkv_linear__DOT__q_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [3U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__k_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [3U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__v_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [0U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [3U]
                                               [0U])));
            vlSelfRef.qkv_linear__DOT__q_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [3U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__k_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [3U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__v_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [1U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [3U]
                                               [1U])));
            vlSelfRef.qkv_linear__DOT__q_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [3U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__k_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [3U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__v_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [2U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [3U]
                                               [2U])));
            vlSelfRef.qkv_linear__DOT__q_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__q_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WQ
                                               [3U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__k_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__k_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WK
                                               [3U]
                                               [3U])));
            vlSelfRef.qkv_linear__DOT__v_acc[3U] = 
                (0xffffU & (vlSelfRef.qkv_linear__DOT__v_acc
                            [3U] + VL_MULS_III(16, 
                                               vlSelfRef.x
                                               [3U], 
                                               vlSelfRef.qkv_linear__DOT__WV
                                               [3U]
                                               [3U])));
        }
    } else if ((1U == (IData)(vlSelfRef.qkv_linear__DOT__state))) {
        __VdlyVal__q__v0 = vlSelfRef.qkv_linear__DOT__q_acc
            [0U];
        __VdlySet__q__v0 = 1U;
        __VdlyVal__k__v0 = vlSelfRef.qkv_linear__DOT__k_acc
            [0U];
        __VdlyVal__v__v0 = vlSelfRef.qkv_linear__DOT__v_acc
            [0U];
        vlSelfRef.done = 1U;
        __Vdly__qkv_linear__DOT__state = 2U;
        __VdlyVal__q__v1 = vlSelfRef.qkv_linear__DOT__q_acc
            [1U];
        __VdlySet__q__v1 = 1U;
        __VdlyVal__k__v1 = vlSelfRef.qkv_linear__DOT__k_acc
            [1U];
        __VdlyVal__v__v1 = vlSelfRef.qkv_linear__DOT__v_acc
            [1U];
        __VdlyVal__q__v2 = vlSelfRef.qkv_linear__DOT__q_acc
            [2U];
        __VdlyVal__k__v2 = vlSelfRef.qkv_linear__DOT__k_acc
            [2U];
        __VdlyVal__v__v2 = vlSelfRef.qkv_linear__DOT__v_acc
            [2U];
        __VdlyVal__q__v3 = vlSelfRef.qkv_linear__DOT__q_acc
            [3U];
        __VdlyVal__k__v3 = vlSelfRef.qkv_linear__DOT__k_acc
            [3U];
        __VdlyVal__v__v3 = vlSelfRef.qkv_linear__DOT__v_acc
            [3U];
    } else if ((2U == (IData)(vlSelfRef.qkv_linear__DOT__state))) {
        vlSelfRef.done = 0U;
        __Vdly__qkv_linear__DOT__state = 0U;
    }
    vlSelfRef.qkv_linear__DOT__state = __Vdly__qkv_linear__DOT__state;
    if (__VdlySet__q__v0) {
        vlSelfRef.q[0U] = __VdlyVal__q__v0;
        vlSelfRef.k[0U] = __VdlyVal__k__v0;
        vlSelfRef.v[0U] = __VdlyVal__v__v0;
    }
    if (__VdlySet__q__v1) {
        vlSelfRef.q[1U] = __VdlyVal__q__v1;
        vlSelfRef.q[2U] = __VdlyVal__q__v2;
        vlSelfRef.q[3U] = __VdlyVal__q__v3;
        vlSelfRef.k[1U] = __VdlyVal__k__v1;
        vlSelfRef.k[2U] = __VdlyVal__k__v2;
        vlSelfRef.k[3U] = __VdlyVal__k__v3;
        vlSelfRef.v[1U] = __VdlyVal__v__v1;
        vlSelfRef.v[2U] = __VdlyVal__v__v2;
        vlSelfRef.v[3U] = __VdlyVal__v__v3;
    }
}

void Vqkv_linear___024root___eval_triggers__act(Vqkv_linear___024root* vlSelf);

bool Vqkv_linear___024root___eval_phase__act(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_phase__act\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vqkv_linear___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vqkv_linear___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vqkv_linear___024root___eval_phase__nba(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_phase__nba\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vqkv_linear___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vqkv_linear___024root___dump_triggers__nba(Vqkv_linear___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vqkv_linear___024root___dump_triggers__act(Vqkv_linear___024root* vlSelf);
#endif  // VL_DEBUG

void Vqkv_linear___024root___eval(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vqkv_linear___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/qkv_linear.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vqkv_linear___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/qkv_linear.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vqkv_linear___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vqkv_linear___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vqkv_linear___024root___eval_debug_assertions(Vqkv_linear___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vqkv_linear___024root___eval_debug_assertions\n"); );
    Vqkv_linear__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY(((vlSelfRef.start & 0xfeU)))) {
        Verilated::overWidthError("start");}
}
#endif  // VL_DEBUG
