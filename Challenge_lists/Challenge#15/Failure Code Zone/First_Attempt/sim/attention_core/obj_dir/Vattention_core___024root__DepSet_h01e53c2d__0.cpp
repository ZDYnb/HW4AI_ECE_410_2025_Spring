// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vattention_core.h for the primary calling header

#include "Vattention_core__pch.h"
#include "Vattention_core___024root.h"

void Vattention_core___024root___ico_sequent__TOP__0(Vattention_core___024root* vlSelf);

void Vattention_core___024root___eval_ico(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_ico\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vattention_core___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vattention_core___024root___ico_sequent__TOP__0(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___ico_sequent__TOP__0\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    SData/*15:0*/ attention_core__DOT__qk_dot;
    attention_core__DOT__qk_dot = 0;
    IData/*31:0*/ attention_core__DOT__dot_inst__DOT__temp_sum;
    attention_core__DOT__dot_inst__DOT__temp_sum = 0;
    IData/*18:0*/ attention_core__DOT__softmax_inst__DOT__sum_exp;
    attention_core__DOT__softmax_inst__DOT__sum_exp = 0;
    SData/*15:0*/ attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum = 0;
    QData/*34:0*/ attention_core__DOT__apply_inst__DOT__sum;
    attention_core__DOT__apply_inst__DOT__sum = 0;
    // Body
    attention_core__DOT__dot_inst__DOT__temp_sum = 
        VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.q
                                      [0U]), VL_EXTENDS_II(32,16, 
                                                           vlSelfRef.k
                                                           [0U]));
    attention_core__DOT__dot_inst__DOT__temp_sum = 
        (attention_core__DOT__dot_inst__DOT__temp_sum 
         + VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.q
                                         [1U]), VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.k
                                                              [1U])));
    attention_core__DOT__dot_inst__DOT__temp_sum = 
        (attention_core__DOT__dot_inst__DOT__temp_sum 
         + VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.q
                                         [2U]), VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.k
                                                              [2U])));
    attention_core__DOT__dot_inst__DOT__temp_sum = 
        (attention_core__DOT__dot_inst__DOT__temp_sum 
         + VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.q
                                         [3U]), VL_EXTENDS_II(32,16, 
                                                              vlSelfRef.k
                                                              [3U])));
    attention_core__DOT__qk_dot = (0xffffU & attention_core__DOT__dot_inst__DOT__temp_sum);
    vlSelfRef.attention_core__DOT__qk_vector[0U] = attention_core__DOT__qk_dot;
    vlSelfRef.attention_core__DOT__qk_vector[1U] = attention_core__DOT__qk_dot;
    vlSelfRef.attention_core__DOT__qk_vector[2U] = attention_core__DOT__qk_dot;
    vlSelfRef.attention_core__DOT__qk_vector[3U] = attention_core__DOT__qk_dot;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum = 0U;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.attention_core__DOT__qk_vector
                   [0U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.attention_core__DOT__qk_vector
                          [0U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__qk_vector
                            [0U]);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 
            = attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1;
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 
                                    + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2) 
                                   + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3) 
                                  + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4));
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 
            = (0xffffU & attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum);
    }
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum = 0U;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.attention_core__DOT__qk_vector
                   [1U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.attention_core__DOT__qk_vector
                          [1U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__qk_vector
                            [1U]);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 
            = attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1;
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 
                                    + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2) 
                                   + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3) 
                                  + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4));
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 
            = (0xffffU & attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum);
    }
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum = 0U;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.attention_core__DOT__qk_vector
                   [2U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.attention_core__DOT__qk_vector
                          [2U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__qk_vector
                            [2U]);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 
            = attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1;
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 
                                    + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2) 
                                   + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3) 
                                  + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4));
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 
            = (0xffffU & attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum);
    }
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 = 0U;
    attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum = 0U;
    attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.attention_core__DOT__qk_vector
                   [3U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.attention_core__DOT__qk_vector
                          [3U])) {
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__qk_vector
                            [3U]);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 
            = attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1;
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 
                                    + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2) 
                                   + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3) 
                                  + attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4));
        attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 
            = (0xffffU & attention_core__DOT__softmax_inst__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum);
    }
    vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out[0U] 
        = attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88;
    vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out[1U] 
        = attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88;
    vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out[2U] 
        = attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88;
    vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out[3U] 
        = attention_core__DOT__softmax_inst__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88;
    attention_core__DOT__softmax_inst__DOT__sum_exp 
        = (0x7ffffU & VL_EXTENDS_II(19,16, vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                    [0U]));
    attention_core__DOT__softmax_inst__DOT__sum_exp 
        = (0x7ffffU & (attention_core__DOT__softmax_inst__DOT__sum_exp 
                       + VL_EXTENDS_II(19,16, vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                       [1U])));
    attention_core__DOT__softmax_inst__DOT__sum_exp 
        = (0x7ffffU & (attention_core__DOT__softmax_inst__DOT__sum_exp 
                       + VL_EXTENDS_II(19,16, vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                       [2U])));
    attention_core__DOT__softmax_inst__DOT__sum_exp 
        = (0x7ffffU & (attention_core__DOT__softmax_inst__DOT__sum_exp 
                       + VL_EXTENDS_II(19,16, vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                       [3U])));
    if ((0U != VL_EXTENDS_II(32,19, attention_core__DOT__softmax_inst__DOT__sum_exp))) {
        vlSelfRef.attention_core__DOT__softmax_out[0U] 
            = (0xffffU & VL_DIVS_III(19, (0x7ffffU 
                                          & VL_SHIFTL_III(19,19,32, 
                                                          VL_EXTENDS_II(19,16, 
                                                                        vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                                                        [0U]), 8U)), attention_core__DOT__softmax_inst__DOT__sum_exp));
        vlSelfRef.attention_core__DOT__softmax_out[1U] 
            = (0xffffU & VL_DIVS_III(19, (0x7ffffU 
                                          & VL_SHIFTL_III(19,19,32, 
                                                          VL_EXTENDS_II(19,16, 
                                                                        vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                                                        [1U]), 8U)), attention_core__DOT__softmax_inst__DOT__sum_exp));
        vlSelfRef.attention_core__DOT__softmax_out[2U] 
            = (0xffffU & VL_DIVS_III(19, (0x7ffffU 
                                          & VL_SHIFTL_III(19,19,32, 
                                                          VL_EXTENDS_II(19,16, 
                                                                        vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                                                        [2U]), 8U)), attention_core__DOT__softmax_inst__DOT__sum_exp));
        vlSelfRef.attention_core__DOT__softmax_out[3U] 
            = (0xffffU & VL_DIVS_III(19, (0x7ffffU 
                                          & VL_SHIFTL_III(19,19,32, 
                                                          VL_EXTENDS_II(19,16, 
                                                                        vlSelfRef.attention_core__DOT__softmax_inst__DOT__exp_out
                                                                        [3U]), 8U)), attention_core__DOT__softmax_inst__DOT__sum_exp));
    } else {
        vlSelfRef.attention_core__DOT__softmax_out[0U] = 0U;
        vlSelfRef.attention_core__DOT__softmax_out[1U] = 0U;
        vlSelfRef.attention_core__DOT__softmax_out[2U] = 0U;
        vlSelfRef.attention_core__DOT__softmax_out[3U] = 0U;
    }
    vlSelfRef.attention_core__DOT__apply_inst__DOT__mul[0U] 
        = VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__softmax_out
                                        [0U]), VL_EXTENDS_II(32,16, 
                                                             vlSelfRef.v
                                                             [0U]));
    attention_core__DOT__apply_inst__DOT__sum = (0x7ffffffffULL 
                                                 & VL_EXTENDS_QI(35,32, 
                                                                 vlSelfRef.attention_core__DOT__apply_inst__DOT__mul
                                                                 [0U]));
    vlSelfRef.attention_core__DOT__apply_inst__DOT__mul[1U] 
        = VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__softmax_out
                                        [1U]), VL_EXTENDS_II(32,16, 
                                                             vlSelfRef.v
                                                             [1U]));
    attention_core__DOT__apply_inst__DOT__sum = (0x7ffffffffULL 
                                                 & (attention_core__DOT__apply_inst__DOT__sum 
                                                    + 
                                                    VL_EXTENDS_QI(35,32, 
                                                                  vlSelfRef.attention_core__DOT__apply_inst__DOT__mul
                                                                  [1U])));
    vlSelfRef.attention_core__DOT__apply_inst__DOT__mul[2U] 
        = VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__softmax_out
                                        [2U]), VL_EXTENDS_II(32,16, 
                                                             vlSelfRef.v
                                                             [2U]));
    attention_core__DOT__apply_inst__DOT__sum = (0x7ffffffffULL 
                                                 & (attention_core__DOT__apply_inst__DOT__sum 
                                                    + 
                                                    VL_EXTENDS_QI(35,32, 
                                                                  vlSelfRef.attention_core__DOT__apply_inst__DOT__mul
                                                                  [2U])));
    vlSelfRef.attention_core__DOT__apply_inst__DOT__mul[3U] 
        = VL_MULS_III(32, VL_EXTENDS_II(32,16, vlSelfRef.attention_core__DOT__softmax_out
                                        [3U]), VL_EXTENDS_II(32,16, 
                                                             vlSelfRef.v
                                                             [3U]));
    attention_core__DOT__apply_inst__DOT__sum = (0x7ffffffffULL 
                                                 & (attention_core__DOT__apply_inst__DOT__sum 
                                                    + 
                                                    VL_EXTENDS_QI(35,32, 
                                                                  vlSelfRef.attention_core__DOT__apply_inst__DOT__mul
                                                                  [3U])));
    vlSelfRef.y = (0xffffU & (IData)((attention_core__DOT__apply_inst__DOT__sum 
                                      >> 8U)));
}

void Vattention_core___024root___eval_triggers__ico(Vattention_core___024root* vlSelf);

bool Vattention_core___024root___eval_phase__ico(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_phase__ico\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vattention_core___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vattention_core___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vattention_core___024root___eval_act(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_act\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vattention_core___024root___nba_sequent__TOP__0(Vattention_core___024root* vlSelf);

void Vattention_core___024root___eval_nba(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_nba\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vattention_core___024root___nba_sequent__TOP__0(vlSelf);
    }
}

extern const VlUnpacked<CData/*1:0*/, 16> Vattention_core__ConstPool__TABLE_h1e9879c3_0;
extern const VlUnpacked<CData/*1:0*/, 16> Vattention_core__ConstPool__TABLE_h5bab4a38_0;
extern const VlUnpacked<CData/*0:0*/, 16> Vattention_core__ConstPool__TABLE_hbcbc6965_0;

VL_INLINE_OPT void Vattention_core___024root___nba_sequent__TOP__0(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___nba_sequent__TOP__0\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*3:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    __Vtableidx1 = (((IData)(vlSelfRef.start) << 3U) 
                    | (((IData)(vlSelfRef.attention_core__DOT__state) 
                        << 1U) | (IData)(vlSelfRef.rst)));
    if ((1U & Vattention_core__ConstPool__TABLE_h1e9879c3_0
         [__Vtableidx1])) {
        vlSelfRef.attention_core__DOT__state = Vattention_core__ConstPool__TABLE_h5bab4a38_0
            [__Vtableidx1];
    }
    if ((2U & Vattention_core__ConstPool__TABLE_h1e9879c3_0
         [__Vtableidx1])) {
        vlSelfRef.done = Vattention_core__ConstPool__TABLE_hbcbc6965_0
            [__Vtableidx1];
    }
}

void Vattention_core___024root___eval_triggers__act(Vattention_core___024root* vlSelf);

bool Vattention_core___024root___eval_phase__act(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_phase__act\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vattention_core___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vattention_core___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vattention_core___024root___eval_phase__nba(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_phase__nba\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vattention_core___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__ico(Vattention_core___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__nba(Vattention_core___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vattention_core___024root___dump_triggers__act(Vattention_core___024root* vlSelf);
#endif  // VL_DEBUG

void Vattention_core___024root___eval(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vattention_core___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/attention_core.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vattention_core___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vattention_core___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/attention_core.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vattention_core___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/attention_core.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vattention_core___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vattention_core___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vattention_core___024root___eval_debug_assertions(Vattention_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vattention_core___024root___eval_debug_assertions\n"); );
    Vattention_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
