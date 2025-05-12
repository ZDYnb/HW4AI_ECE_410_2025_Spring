// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlif_neuron.h for the primary calling header

#include "Vlif_neuron__pch.h"
#include "Vlif_neuron___024root.h"

VL_ATTR_COLD void Vlif_neuron___024root___eval_static(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_static\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__rst__0 = vlSelfRef.rst;
}

VL_ATTR_COLD void Vlif_neuron___024root___eval_initial(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_initial\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vlif_neuron___024root___eval_final(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_final\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__stl(Vlif_neuron___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vlif_neuron___024root___eval_phase__stl(Vlif_neuron___024root* vlSelf);

VL_ATTR_COLD void Vlif_neuron___024root___eval_settle(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_settle\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vlif_neuron___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("lif_neuron.sv", 2, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vlif_neuron___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__stl(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___dump_triggers__stl\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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

void Vlif_neuron___024root___ico_sequent__TOP__0(Vlif_neuron___024root* vlSelf);
VL_ATTR_COLD void Vlif_neuron___024root____Vm_traceActivitySetAll(Vlif_neuron___024root* vlSelf);

VL_ATTR_COLD void Vlif_neuron___024root___eval_stl(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_stl\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vlif_neuron___024root___ico_sequent__TOP__0(vlSelf);
        Vlif_neuron___024root____Vm_traceActivitySetAll(vlSelf);
    }
}

VL_ATTR_COLD void Vlif_neuron___024root___eval_triggers__stl(Vlif_neuron___024root* vlSelf);

VL_ATTR_COLD bool Vlif_neuron___024root___eval_phase__stl(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_phase__stl\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vlif_neuron___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vlif_neuron___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__ico(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___dump_triggers__ico\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__act(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___dump_triggers__act\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(posedge rst)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__nba(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___dump_triggers__nba\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(posedge rst)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vlif_neuron___024root____Vm_traceActivitySetAll(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root____Vm_traceActivitySetAll\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vm_traceActivity[0U] = 1U;
    vlSelfRef.__Vm_traceActivity[1U] = 1U;
    vlSelfRef.__Vm_traceActivity[2U] = 1U;
}

VL_ATTR_COLD void Vlif_neuron___024root___ctor_var_reset(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___ctor_var_reset\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->in_bit = VL_RAND_RESET_I(1);
    vlSelf->spike = VL_RAND_RESET_I(1);
    vlSelf->potential = VL_RAND_RESET_I(16);
    vlSelf->lif_neuron__DOT__input_fixed = VL_RAND_RESET_I(16);
    vlSelf->lif_neuron__DOT__mult_result = VL_RAND_RESET_I(32);
    vlSelf->lif_neuron__DOT__mult_scaled = VL_RAND_RESET_I(17);
    vlSelf->lif_neuron__DOT__next_potential = VL_RAND_RESET_I(17);
    vlSelf->lif_neuron__DOT__spike_next = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
