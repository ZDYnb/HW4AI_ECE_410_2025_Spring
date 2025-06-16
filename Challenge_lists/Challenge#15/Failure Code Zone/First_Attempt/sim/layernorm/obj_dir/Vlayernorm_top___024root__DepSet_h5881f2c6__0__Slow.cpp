// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlayernorm_top.h for the primary calling header

#include "Vlayernorm_top__pch.h"
#include "Vlayernorm_top___024root.h"

VL_ATTR_COLD void Vlayernorm_top___024root___eval_static(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_static\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vlayernorm_top___024root___eval_initial__TOP(Vlayernorm_top___024root* vlSelf);

VL_ATTR_COLD void Vlayernorm_top___024root___eval_initial(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_initial\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vlayernorm_top___024root___eval_initial__TOP(vlSelf);
}

VL_ATTR_COLD void Vlayernorm_top___024root___eval_initial__TOP(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_initial__TOP\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlWide<3>/*95:0*/ __Vtemp_1;
    // Body
    __Vtemp_1[0U] = 0x2e686578U;
    __Vtemp_1[1U] = 0x5f713838U;
    __Vtemp_1[2U] = 0x73717274U;
    VL_READMEM_N(true, 16, 256, 0, VL_CVT_PACK_STR_NW(3, __Vtemp_1)
                 ,  &(vlSelfRef.layernorm_top__DOT__sqrt_inst__DOT__lut)
                 , 0, ~0ULL);
}

VL_ATTR_COLD void Vlayernorm_top___024root___eval_final(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_final\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__stl(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vlayernorm_top___024root___eval_phase__stl(Vlayernorm_top___024root* vlSelf);

VL_ATTR_COLD void Vlayernorm_top___024root___eval_settle(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_settle\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY(((0x64U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vlayernorm_top___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../../rtl/layernorm_top.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vlayernorm_top___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__stl(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___dump_triggers__stl\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

void Vlayernorm_top___024root___ico_sequent__TOP__0(Vlayernorm_top___024root* vlSelf);

VL_ATTR_COLD void Vlayernorm_top___024root___eval_stl(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_stl\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vlayernorm_top___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vlayernorm_top___024root___eval_triggers__stl(Vlayernorm_top___024root* vlSelf);

VL_ATTR_COLD bool Vlayernorm_top___024root___eval_phase__stl(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___eval_phase__stl\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vlayernorm_top___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vlayernorm_top___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__ico(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___dump_triggers__ico\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VicoTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__act(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___dump_triggers__act\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlayernorm_top___024root___dump_triggers__nba(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___dump_triggers__nba\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vlayernorm_top___024root___ctor_var_reset(Vlayernorm_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlayernorm_top___024root___ctor_var_reset\n"); );
    Vlayernorm_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->x[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->norm_x[__Vi0] = VL_RAND_RESET_I(16);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->layernorm_top__DOT__sqrt_inst__DOT__lut[__Vi0] = VL_RAND_RESET_I(16);
    }
}
