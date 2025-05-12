// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vlif_neuron__Syms.h"


void Vlif_neuron___024root__trace_chg_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vlif_neuron___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_chg_0\n"); );
    // Init
    Vlif_neuron___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vlif_neuron___024root*>(voidSelf);
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vlif_neuron___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vlif_neuron___024root__trace_chg_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_chg_0_sub_0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(((vlSelfRef.__Vm_traceActivity[1U] 
                      | vlSelfRef.__Vm_traceActivity
                      [2U])))) {
        bufp->chgSData(oldp+0,(vlSelfRef.lif_neuron__DOT__input_fixed),16);
        bufp->chgIData(oldp+1,(vlSelfRef.lif_neuron__DOT__mult_result),32);
        bufp->chgIData(oldp+2,(vlSelfRef.lif_neuron__DOT__mult_scaled),17);
        bufp->chgIData(oldp+3,(vlSelfRef.lif_neuron__DOT__next_potential),17);
        bufp->chgBit(oldp+4,(vlSelfRef.lif_neuron__DOT__spike_next));
    }
    bufp->chgBit(oldp+5,(vlSelfRef.clk));
    bufp->chgBit(oldp+6,(vlSelfRef.rst));
    bufp->chgBit(oldp+7,(vlSelfRef.in_bit));
    bufp->chgBit(oldp+8,(vlSelfRef.spike));
    bufp->chgSData(oldp+9,(vlSelfRef.potential),16);
}

void Vlif_neuron___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_cleanup\n"); );
    // Init
    Vlif_neuron___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vlif_neuron___024root*>(voidSelf);
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[2U] = 0U;
}
