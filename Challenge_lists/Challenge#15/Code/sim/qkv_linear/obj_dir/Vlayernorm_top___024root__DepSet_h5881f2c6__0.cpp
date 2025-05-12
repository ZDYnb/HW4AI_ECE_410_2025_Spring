// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlayernorm_top.h for the primary calling header

#include "Vlayernorm_top__pch.h"
#include "Vlayernorm_top___024root.h"

void Vlayernorm_top___024root___ico_sequent__TOP__0(Vlayernorm_top___024root* vlSelf);

void Vlayernorm_top___024root___eval_ico(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_ico\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vlayernorm_top___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vlayernorm_top___024root___ico_sequent__TOP__0(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___ico_sequent__TOP__0\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    SData/*15:0*/ layernorm_top__DOT__mean;
    layernorm_top__DOT__mean = 0;
    SData/*15:0*/ layernorm_top__DOT__variance;
    layernorm_top__DOT__variance = 0;
    SData/*15:0*/ layernorm_top__DOT__stddev;
    layernorm_top__DOT__stddev = 0;
    IData/*19:0*/ layernorm_top__DOT__mean_inst__DOT__sum;
    layernorm_top__DOT__mean_inst__DOT__sum = 0;
    IData/*16:0*/ layernorm_top__DOT__var_inst__DOT__diff;
    layernorm_top__DOT__var_inst__DOT__diff = 0;
    IData/*31:0*/ layernorm_top__DOT__var_inst__DOT__diff_sq;
    layernorm_top__DOT__var_inst__DOT__diff_sq = 0;
    IData/*31:0*/ layernorm_top__DOT__var_inst__DOT__sum;
    layernorm_top__DOT__var_inst__DOT__sum = 0;
    IData/*31:0*/ layernorm_top__DOT__var_inst__DOT__avg;
    layernorm_top__DOT__var_inst__DOT__avg = 0;
    IData/*16:0*/ layernorm_top__DOT__norm_inst__DOT__diff;
    layernorm_top__DOT__norm_inst__DOT__diff = 0;
    IData/*31:0*/ layernorm_top__DOT__norm_inst__DOT__scaled_diff;
    layernorm_top__DOT__norm_inst__DOT__scaled_diff = 0;
    IData/*31:0*/ layernorm_top__DOT__norm_inst__DOT__result;
    layernorm_top__DOT__norm_inst__DOT__result = 0;
    // Body
    layernorm_top__DOT__mean_inst__DOT__sum = ((0x70000U 
                                                & ((- (IData)(
                                                              (1U 
                                                               & (vlSelfRef.x
                                                                  [0U] 
                                                                  >> 0xfU)))) 
                                                   << 0x10U)) 
                                               | vlSelfRef.x
                                               [0U]);
    layernorm_top__DOT__mean_inst__DOT__sum = (0xfffffU 
                                               & (layernorm_top__DOT__mean_inst__DOT__sum 
                                                  + 
                                                  ((0x70000U 
                                                    & ((- (IData)(
                                                                  (1U 
                                                                   & (vlSelfRef.x
                                                                      [1U] 
                                                                      >> 0xfU)))) 
                                                       << 0x10U)) 
                                                   | vlSelfRef.x
                                                   [1U])));
    layernorm_top__DOT__mean_inst__DOT__sum = (0xfffffU 
                                               & (layernorm_top__DOT__mean_inst__DOT__sum 
                                                  + 
                                                  ((0x70000U 
                                                    & ((- (IData)(
                                                                  (1U 
                                                                   & (vlSelfRef.x
                                                                      [2U] 
                                                                      >> 0xfU)))) 
                                                       << 0x10U)) 
                                                   | vlSelfRef.x
                                                   [2U])));
    layernorm_top__DOT__mean_inst__DOT__sum = (0xfffffU 
                                               & (layernorm_top__DOT__mean_inst__DOT__sum 
                                                  + 
                                                  ((0x70000U 
                                                    & ((- (IData)(
                                                                  (1U 
                                                                   & (vlSelfRef.x
                                                                      [3U] 
                                                                      >> 0xfU)))) 
                                                       << 0x10U)) 
                                                   | vlSelfRef.x
                                                   [3U])));
    layernorm_top__DOT__mean = (0xffffU & (layernorm_top__DOT__mean_inst__DOT__sum 
                                           >> 2U));
    layernorm_top__DOT__var_inst__DOT__diff = (0x1ffffU 
                                               & (VL_EXTENDS_II(17,16, 
                                                                vlSelfRef.x
                                                                [0U]) 
                                                  - 
                                                  VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__var_inst__DOT__diff_sq = VL_MULS_III(32, 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff), 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff));
    layernorm_top__DOT__var_inst__DOT__sum = layernorm_top__DOT__var_inst__DOT__diff_sq;
    layernorm_top__DOT__var_inst__DOT__diff = (0x1ffffU 
                                               & (VL_EXTENDS_II(17,16, 
                                                                vlSelfRef.x
                                                                [1U]) 
                                                  - 
                                                  VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__var_inst__DOT__diff_sq = VL_MULS_III(32, 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff), 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff));
    layernorm_top__DOT__var_inst__DOT__sum = (layernorm_top__DOT__var_inst__DOT__sum 
                                              + layernorm_top__DOT__var_inst__DOT__diff_sq);
    layernorm_top__DOT__var_inst__DOT__diff = (0x1ffffU 
                                               & (VL_EXTENDS_II(17,16, 
                                                                vlSelfRef.x
                                                                [2U]) 
                                                  - 
                                                  VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__var_inst__DOT__diff_sq = VL_MULS_III(32, 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff), 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff));
    layernorm_top__DOT__var_inst__DOT__sum = (layernorm_top__DOT__var_inst__DOT__sum 
                                              + layernorm_top__DOT__var_inst__DOT__diff_sq);
    layernorm_top__DOT__var_inst__DOT__diff = (0x1ffffU 
                                               & (VL_EXTENDS_II(17,16, 
                                                                vlSelfRef.x
                                                                [3U]) 
                                                  - 
                                                  VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__var_inst__DOT__diff_sq = VL_MULS_III(32, 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff), 
                                                             VL_EXTENDS_II(32,17, layernorm_top__DOT__var_inst__DOT__diff));
    layernorm_top__DOT__var_inst__DOT__sum = (layernorm_top__DOT__var_inst__DOT__sum 
                                              + layernorm_top__DOT__var_inst__DOT__diff_sq);
    layernorm_top__DOT__var_inst__DOT__avg = VL_SHIFTRS_III(32,32,32, layernorm_top__DOT__var_inst__DOT__sum, 2U);
    layernorm_top__DOT__variance = (0xffffU & (layernorm_top__DOT__var_inst__DOT__avg 
                                               >> 8U));
    layernorm_top__DOT__stddev = vlSelfRef.layernorm_top__DOT__sqrt_inst__DOT__lut
        [(0xffU & ((IData)(layernorm_top__DOT__variance) 
                   >> 8U))];
    layernorm_top__DOT__norm_inst__DOT__diff = (0x1ffffU 
                                                & (VL_EXTENDS_II(17,16, 
                                                                 vlSelfRef.x
                                                                 [0U]) 
                                                   - 
                                                   VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__norm_inst__DOT__scaled_diff 
        = VL_SHIFTL_III(32,32,32, VL_EXTENDS_II(32,17, layernorm_top__DOT__norm_inst__DOT__diff), 8U);
    layernorm_top__DOT__norm_inst__DOT__result = VL_DIVS_III(32, layernorm_top__DOT__norm_inst__DOT__scaled_diff, 
                                                             VL_EXTENDS_II(32,16, (IData)(layernorm_top__DOT__stddev)));
    vlSelfRef.norm_x[0U] = (0xffffU & layernorm_top__DOT__norm_inst__DOT__result);
    layernorm_top__DOT__norm_inst__DOT__diff = (0x1ffffU 
                                                & (VL_EXTENDS_II(17,16, 
                                                                 vlSelfRef.x
                                                                 [1U]) 
                                                   - 
                                                   VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__norm_inst__DOT__scaled_diff 
        = VL_SHIFTL_III(32,32,32, VL_EXTENDS_II(32,17, layernorm_top__DOT__norm_inst__DOT__diff), 8U);
    layernorm_top__DOT__norm_inst__DOT__result = VL_DIVS_III(32, layernorm_top__DOT__norm_inst__DOT__scaled_diff, 
                                                             VL_EXTENDS_II(32,16, (IData)(layernorm_top__DOT__stddev)));
    vlSelfRef.norm_x[1U] = (0xffffU & layernorm_top__DOT__norm_inst__DOT__result);
    layernorm_top__DOT__norm_inst__DOT__diff = (0x1ffffU 
                                                & (VL_EXTENDS_II(17,16, 
                                                                 vlSelfRef.x
                                                                 [2U]) 
                                                   - 
                                                   VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__norm_inst__DOT__scaled_diff 
        = VL_SHIFTL_III(32,32,32, VL_EXTENDS_II(32,17, layernorm_top__DOT__norm_inst__DOT__diff), 8U);
    layernorm_top__DOT__norm_inst__DOT__result = VL_DIVS_III(32, layernorm_top__DOT__norm_inst__DOT__scaled_diff, 
                                                             VL_EXTENDS_II(32,16, (IData)(layernorm_top__DOT__stddev)));
    vlSelfRef.norm_x[2U] = (0xffffU & layernorm_top__DOT__norm_inst__DOT__result);
    layernorm_top__DOT__norm_inst__DOT__diff = (0x1ffffU 
                                                & (VL_EXTENDS_II(17,16, 
                                                                 vlSelfRef.x
                                                                 [3U]) 
                                                   - 
                                                   VL_EXTENDS_II(17,16, (IData)(layernorm_top__DOT__mean))));
    layernorm_top__DOT__norm_inst__DOT__scaled_diff 
        = VL_SHIFTL_III(32,32,32, VL_EXTENDS_II(32,17, layernorm_top__DOT__norm_inst__DOT__diff), 8U);
    layernorm_top__DOT__norm_inst__DOT__result = VL_DIVS_III(32, layernorm_top__DOT__norm_inst__DOT__scaled_diff, 
                                                             VL_EXTENDS_II(32,16, (IData)(layernorm_top__DOT__stddev)));
    vlSelfRef.norm_x[3U] = (0xffffU & layernorm_top__DOT__norm_inst__DOT__result);
}

void Vlayernorm_top___024root___eval_triggers__ico(Vlayernorm_top___024root* vlSelf);

bool Vlayernorm_top___024root___eval_phase__ico(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_phase__ico\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vlayernorm_top___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vlayernorm_top___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vlayernorm_top___024root___eval_act(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_act\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vlayernorm_top___024root___eval_nba(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_nba\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vlayernorm_top___024root___eval_triggers__act(Vlayernorm_top___024root* vlSelf);

bool Vlayernorm_top___024root___eval_phase__act(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_phase__act\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vlayernorm_top___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vlayernorm_top___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vlayernorm_top___024root___eval_phase__nba(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_phase__nba\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vlayernorm_top___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__ico(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__nba(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__act(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG

void Vlayernorm_top___024root___eval(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vlayernorm_top___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/layernorm_top.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vlayernorm_top___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vlayernorm_top___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/layernorm_top.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vlayernorm_top___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../../rtl/layernorm_top.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vlayernorm_top___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vlayernorm_top___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vlayernorm_top___024root___eval_debug_assertions(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_debug_assertions\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
