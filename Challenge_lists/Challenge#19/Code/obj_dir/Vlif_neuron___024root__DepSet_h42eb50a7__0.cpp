// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vlif_neuron.h for the primary calling header

#include "Vlif_neuron__pch.h"
#include "Vlif_neuron___024root.h"

void Vlif_neuron___024root___ico_sequent__TOP__0(Vlif_neuron___024root* vlSelf);

void Vlif_neuron___024root___eval_ico(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_ico\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vlif_neuron___024root___ico_sequent__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[1U] = 1U;
    }
}

VL_INLINE_OPT void Vlif_neuron___024root___ico_sequent__TOP__0(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___ico_sequent__TOP__0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.lif_neuron__DOT__input_fixed = ((IData)(vlSelfRef.in_bit) 
                                              << 0xfU);
    vlSelfRef.lif_neuron__DOT__mult_result = VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.potential), 0xfU);
    vlSelfRef.lif_neuron__DOT__mult_scaled = (vlSelfRef.lif_neuron__DOT__mult_result 
                                              >> 0x10U);
    vlSelfRef.lif_neuron__DOT__next_potential = (0x1ffffU 
                                                 & (vlSelfRef.lif_neuron__DOT__mult_scaled 
                                                    + (IData)(vlSelfRef.lif_neuron__DOT__input_fixed)));
    vlSelfRef.lif_neuron__DOT__spike_next = (0xc000U 
                                             <= vlSelfRef.lif_neuron__DOT__next_potential);
}

void Vlif_neuron___024root___eval_triggers__ico(Vlif_neuron___024root* vlSelf);

bool Vlif_neuron___024root___eval_phase__ico(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_phase__ico\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vlif_neuron___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vlif_neuron___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vlif_neuron___024root___eval_act(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_act\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vlif_neuron___024root___nba_sequent__TOP__0(Vlif_neuron___024root* vlSelf);

void Vlif_neuron___024root___eval_nba(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_nba\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vlif_neuron___024root___nba_sequent__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[2U] = 1U;
    }
}

VL_INLINE_OPT void Vlif_neuron___024root___nba_sequent__TOP__0(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___nba_sequent__TOP__0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.spike = ((1U & (~ (IData)(vlSelfRef.rst))) 
                       && (IData)(vlSelfRef.lif_neuron__DOT__spike_next));
    vlSelfRef.potential = ((IData)(vlSelfRef.rst) ? 0U
                            : ((IData)(vlSelfRef.lif_neuron__DOT__spike_next)
                                ? 0U : (0xffffU & vlSelfRef.lif_neuron__DOT__next_potential)));
    vlSelfRef.lif_neuron__DOT__input_fixed = ((IData)(vlSelfRef.in_bit) 
                                              << 0xfU);
    vlSelfRef.lif_neuron__DOT__mult_result = VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.potential), 0xfU);
    vlSelfRef.lif_neuron__DOT__mult_scaled = (vlSelfRef.lif_neuron__DOT__mult_result 
                                              >> 0x10U);
    vlSelfRef.lif_neuron__DOT__next_potential = (0x1ffffU 
                                                 & (vlSelfRef.lif_neuron__DOT__mult_scaled 
                                                    + (IData)(vlSelfRef.lif_neuron__DOT__input_fixed)));
    vlSelfRef.lif_neuron__DOT__spike_next = (0xc000U 
                                             <= vlSelfRef.lif_neuron__DOT__next_potential);
}

void Vlif_neuron___024root___eval_triggers__act(Vlif_neuron___024root* vlSelf);

bool Vlif_neuron___024root___eval_phase__act(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_phase__act\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vlif_neuron___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vlif_neuron___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vlif_neuron___024root___eval_phase__nba(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_phase__nba\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vlif_neuron___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__ico(Vlif_neuron___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__nba(Vlif_neuron___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vlif_neuron___024root___dump_triggers__act(Vlif_neuron___024root* vlSelf);
#endif  // VL_DEBUG

void Vlif_neuron___024root___eval(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
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
            Vlif_neuron___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("lif_neuron.sv", 2, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vlif_neuron___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vlif_neuron___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("lif_neuron.sv", 2, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vlif_neuron___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("lif_neuron.sv", 2, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vlif_neuron___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vlif_neuron___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vlif_neuron___024root___eval_debug_assertions(Vlif_neuron___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root___eval_debug_assertions\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY(((vlSelfRef.in_bit & 0xfeU)))) {
        Verilated::overWidthError("in_bit");}
}
#endif  // VL_DEBUG
