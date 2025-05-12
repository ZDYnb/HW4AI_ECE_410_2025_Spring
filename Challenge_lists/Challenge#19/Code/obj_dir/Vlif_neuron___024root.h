// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vlif_neuron.h for the primary calling header

#ifndef VERILATED_VLIF_NEURON___024ROOT_H_
#define VERILATED_VLIF_NEURON___024ROOT_H_  // guard

#include "verilated.h"


class Vlif_neuron__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vlif_neuron___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(in_bit,0,0);
    VL_OUT8(spike,0,0);
    CData/*0:0*/ lif_neuron__DOT__spike_next;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
    CData/*0:0*/ __VactContinue;
    VL_OUT16(potential,15,0);
    SData/*15:0*/ lif_neuron__DOT__input_fixed;
    IData/*31:0*/ lif_neuron__DOT__mult_result;
    IData/*16:0*/ lif_neuron__DOT__mult_scaled;
    IData/*16:0*/ lif_neuron__DOT__next_potential;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*0:0*/, 3> __Vm_traceActivity;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vlif_neuron__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vlif_neuron___024root(Vlif_neuron__Syms* symsp, const char* v__name);
    ~Vlif_neuron___024root();
    VL_UNCOPYABLE(Vlif_neuron___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
