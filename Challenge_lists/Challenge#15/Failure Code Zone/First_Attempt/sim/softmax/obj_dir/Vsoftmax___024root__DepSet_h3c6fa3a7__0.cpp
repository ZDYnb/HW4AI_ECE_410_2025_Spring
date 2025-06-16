// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vsoftmax.h for the primary calling header

#include "Vsoftmax__pch.h"
#include "Vsoftmax___024root.h"

void Vsoftmax___024root___ico_sequent__TOP__0(Vsoftmax___024root* vlSelf);

void Vsoftmax___024root___eval_ico(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_ico\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vsoftmax___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vsoftmax___024root___ico_sequent__TOP__0(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___ico_sequent__TOP__0\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*18:0*/ softmax__DOT__sum_exp;
    softmax__DOT__sum_exp = 0;
    SData/*15:0*/ softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88;
    softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88;
    softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88;
    softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0;
    SData/*15:0*/ softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88;
    softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 = 0;
    IData/*31:0*/ softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum = 0;
    // Body
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 = 0U;
    softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum = 0U;
    softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.x[0U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.x[0U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.x[0U]);
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 
            = softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x1;
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term1 
                                    + softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term2) 
                                   + softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term3) 
                                  + softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__term4));
        softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88 
            = (0xffffU & softmax__DOT__exp_gen__BRA__0__KET____DOT__exp_inst__DOT__sum);
    }
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 = 0U;
    softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum = 0U;
    softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.x[1U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.x[1U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.x[1U]);
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 
            = softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x1;
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term1 
                                    + softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term2) 
                                   + softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term3) 
                                  + softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__term4));
        softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88 
            = (0xffffU & softmax__DOT__exp_gen__BRA__1__KET____DOT__exp_inst__DOT__sum);
    }
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 = 0U;
    softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum = 0U;
    softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.x[2U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.x[2U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.x[2U]);
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 
            = softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x1;
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term1 
                                    + softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term2) 
                                   + softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term3) 
                                  + softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__term4));
        softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88 
            = (0xffffU & softmax__DOT__exp_gen__BRA__2__KET____DOT__exp_inst__DOT__sum);
    }
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 = 0U;
    softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum = 0U;
    softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0U;
    if (VL_GTS_III(16, 0xff00U, vlSelfRef.x[3U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 1U;
    } else if (VL_LTS_III(16, 0x180U, vlSelfRef.x[3U])) {
        softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 = 0xffffU;
    } else {
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1 
            = VL_EXTENDS_II(32,16, vlSelfRef.x[3U]);
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4 
            = VL_SHIFTRS_III(32,32,32, VL_MULS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1), 8U);
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 
            = softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x1;
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x2, (IData)(2U));
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x3, (IData)(6U));
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4 
            = VL_DIVS_III(32, softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__x4, (IData)(0x18U));
        softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum 
            = ((IData)(0x100U) + (((softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term1 
                                    + softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term2) 
                                   + softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term3) 
                                  + softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__term4));
        softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88 
            = (0xffffU & softmax__DOT__exp_gen__BRA__3__KET____DOT__exp_inst__DOT__sum);
    }
    vlSelfRef.softmax__DOT__exp_out[0U] = softmax__DOT____Vcellout__exp_gen__BRA__0__KET____DOT__exp_inst__y_q88;
    vlSelfRef.softmax__DOT__exp_out[1U] = softmax__DOT____Vcellout__exp_gen__BRA__1__KET____DOT__exp_inst__y_q88;
    vlSelfRef.softmax__DOT__exp_out[2U] = softmax__DOT____Vcellout__exp_gen__BRA__2__KET____DOT__exp_inst__y_q88;
    vlSelfRef.softmax__DOT__exp_out[3U] = softmax__DOT____Vcellout__exp_gen__BRA__3__KET____DOT__exp_inst__y_q88;
    softmax__DOT__sum_exp = (0x7ffffU & VL_EXTENDS_II(19,16, 
                                                      vlSelfRef.softmax__DOT__exp_out
                                                      [0U]));
    softmax__DOT__sum_exp = (0x7ffffU & (softmax__DOT__sum_exp 
                                         + VL_EXTENDS_II(19,16, 
                                                         vlSelfRef.softmax__DOT__exp_out
                                                         [1U])));
    softmax__DOT__sum_exp = (0x7ffffU & (softmax__DOT__sum_exp 
                                         + VL_EXTENDS_II(19,16, 
                                                         vlSelfRef.softmax__DOT__exp_out
                                                         [2U])));
    softmax__DOT__sum_exp = (0x7ffffU & (softmax__DOT__sum_exp 
                                         + VL_EXTENDS_II(19,16, 
                                                         vlSelfRef.softmax__DOT__exp_out
                                                         [3U])));
    if ((0U != VL_EXTENDS_II(32,19, softmax__DOT__sum_exp))) {
        vlSelfRef.y[0U] = (0xffffU & VL_DIVS_III(19, 
                                                 (0x7ffffU 
                                                  & VL_SHIFTL_III(19,19,32, 
                                                                  VL_EXTENDS_II(19,16, 
                                                                                vlSelfRef.softmax__DOT__exp_out
                                                                                [0U]), 8U)), softmax__DOT__sum_exp));
        vlSelfRef.y[1U] = (0xffffU & VL_DIVS_III(19, 
                                                 (0x7ffffU 
                                                  & VL_SHIFTL_III(19,19,32, 
                                                                  VL_EXTENDS_II(19,16, 
                                                                                vlSelfRef.softmax__DOT__exp_out
                                                                                [1U]), 8U)), softmax__DOT__sum_exp));
        vlSelfRef.y[2U] = (0xffffU & VL_DIVS_III(19, 
                                                 (0x7ffffU 
                                                  & VL_SHIFTL_III(19,19,32, 
                                                                  VL_EXTENDS_II(19,16, 
                                                                                vlSelfRef.softmax__DOT__exp_out
                                                                                [2U]), 8U)), softmax__DOT__sum_exp));
        vlSelfRef.y[3U] = (0xffffU & VL_DIVS_III(19, 
                                                 (0x7ffffU 
                                                  & VL_SHIFTL_III(19,19,32, 
                                                                  VL_EXTENDS_II(19,16, 
                                                                                vlSelfRef.softmax__DOT__exp_out
                                                                                [3U]), 8U)), softmax__DOT__sum_exp));
    } else {
        vlSelfRef.y[0U] = 0U;
        vlSelfRef.y[1U] = 0U;
        vlSelfRef.y[2U] = 0U;
        vlSelfRef.y[3U] = 0U;
    }
}

void Vsoftmax___024root___eval_triggers__ico(Vsoftmax___024root* vlSelf);

bool Vsoftmax___024root___eval_phase__ico(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_phase__ico\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vsoftmax___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vsoftmax___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vsoftmax___024root___eval_act(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_act\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vsoftmax___024root___eval_nba(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_nba\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vsoftmax___024root___eval_triggers__act(Vsoftmax___024root* vlSelf);

bool Vsoftmax___024root___eval_phase__act(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_phase__act\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vsoftmax___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vsoftmax___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vsoftmax___024root___eval_phase__nba(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_phase__nba\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vsoftmax___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vsoftmax___024root___dump_triggers__ico(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vsoftmax___024root___dump_triggers__nba(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vsoftmax___024root___dump_triggers__act(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG

void Vsoftmax___024root___eval(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vsoftmax___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/softmax.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vsoftmax___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vsoftmax___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/softmax.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vsoftmax___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/softmax.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vsoftmax___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vsoftmax___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vsoftmax___024root___eval_debug_assertions(Vsoftmax___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vsoftmax___024root___eval_debug_assertions\n"); );
    Vsoftmax__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
