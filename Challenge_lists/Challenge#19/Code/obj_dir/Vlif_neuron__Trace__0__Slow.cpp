// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vlif_neuron__Syms.h"


VL_ATTR_COLD void Vlif_neuron___024root__trace_init_sub__TOP__0(Vlif_neuron___024root* vlSelf, VerilatedVcd* tracep) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_init_sub__TOP__0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+6,0,"clk",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+7,0,"rst",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+8,0,"in_bit",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+9,0,"spike",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+10,0,"potential",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 15,0);
    tracep->pushPrefix("lif_neuron", VerilatedTracePrefixType::SCOPE_MODULE);
    tracep->declBus(c+11,0,"WIDTH",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::PARAMETER, VerilatedTraceSigType::LOGIC, false,-1, 31,0);
    tracep->declBus(c+12,0,"LAMBDA",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::PARAMETER, VerilatedTraceSigType::LOGIC, false,-1, 15,0);
    tracep->declBus(c+13,0,"THRESHOLD",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::PARAMETER, VerilatedTraceSigType::LOGIC, false,-1, 15,0);
    tracep->declBit(c+6,0,"clk",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+7,0,"rst",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+8,0,"in_bit",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+9,0,"spike",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+10,0,"potential",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 15,0);
    tracep->declBus(c+1,0,"input_fixed",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 15,0);
    tracep->declBus(c+2,0,"mult_result",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 31,0);
    tracep->declBus(c+3,0,"mult_scaled",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 16,0);
    tracep->declBus(c+4,0,"next_potential",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 16,0);
    tracep->declBit(c+5,0,"spike_next",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_init_top(Vlif_neuron___024root* vlSelf, VerilatedVcd* tracep) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_init_top\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vlif_neuron___024root__trace_init_sub__TOP__0(vlSelf, tracep);
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_const_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
VL_ATTR_COLD void Vlif_neuron___024root__trace_full_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
void Vlif_neuron___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp);
void Vlif_neuron___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/);

VL_ATTR_COLD void Vlif_neuron___024root__trace_register(Vlif_neuron___024root* vlSelf, VerilatedVcd* tracep) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_register\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    tracep->addConstCb(&Vlif_neuron___024root__trace_const_0, 0U, vlSelf);
    tracep->addFullCb(&Vlif_neuron___024root__trace_full_0, 0U, vlSelf);
    tracep->addChgCb(&Vlif_neuron___024root__trace_chg_0, 0U, vlSelf);
    tracep->addCleanupCb(&Vlif_neuron___024root__trace_cleanup, vlSelf);
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_const_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp);

VL_ATTR_COLD void Vlif_neuron___024root__trace_const_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_const_0\n"); );
    // Init
    Vlif_neuron___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vlif_neuron___024root*>(voidSelf);
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    Vlif_neuron___024root__trace_const_0_sub_0((&vlSymsp->TOP), bufp);
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_const_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_const_0_sub_0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode);
    // Body
    bufp->fullIData(oldp+11,(0x10U),32);
    bufp->fullSData(oldp+12,(0x8000U),16);
    bufp->fullSData(oldp+13,(0xc000U),16);
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_full_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp);

VL_ATTR_COLD void Vlif_neuron___024root__trace_full_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_full_0\n"); );
    // Init
    Vlif_neuron___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vlif_neuron___024root*>(voidSelf);
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    Vlif_neuron___024root__trace_full_0_sub_0((&vlSymsp->TOP), bufp);
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_full_0_sub_0(Vlif_neuron___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vlif_neuron___024root__trace_full_0_sub_0\n"); );
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode);
    // Body
    bufp->fullSData(oldp+1,(vlSelfRef.lif_neuron__DOT__input_fixed),16);
    bufp->fullIData(oldp+2,(vlSelfRef.lif_neuron__DOT__mult_result),32);
    bufp->fullIData(oldp+3,(vlSelfRef.lif_neuron__DOT__mult_scaled),17);
    bufp->fullIData(oldp+4,(vlSelfRef.lif_neuron__DOT__next_potential),17);
    bufp->fullBit(oldp+5,(vlSelfRef.lif_neuron__DOT__spike_next));
    bufp->fullBit(oldp+6,(vlSelfRef.clk));
    bufp->fullBit(oldp+7,(vlSelfRef.rst));
    bufp->fullBit(oldp+8,(vlSelfRef.in_bit));
    bufp->fullBit(oldp+9,(vlSelfRef.spike));
    bufp->fullSData(oldp+10,(vlSelfRef.potential),16);
}
