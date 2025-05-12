// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vlif_neuron__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vlif_neuron::Vlif_neuron(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vlif_neuron__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , in_bit{vlSymsp->TOP.in_bit}
    , spike{vlSymsp->TOP.spike}
    , potential{vlSymsp->TOP.potential}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
    contextp()->traceBaseModelCbAdd(
        [this](VerilatedTraceBaseC* tfp, int levels, int options) { traceBaseModel(tfp, levels, options); });
}

Vlif_neuron::Vlif_neuron(const char* _vcname__)
    : Vlif_neuron(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vlif_neuron::~Vlif_neuron() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vlif_neuron___024root___eval_debug_assertions(Vlif_neuron___024root* vlSelf);
#endif  // VL_DEBUG
void Vlif_neuron___024root___eval_static(Vlif_neuron___024root* vlSelf);
void Vlif_neuron___024root___eval_initial(Vlif_neuron___024root* vlSelf);
void Vlif_neuron___024root___eval_settle(Vlif_neuron___024root* vlSelf);
void Vlif_neuron___024root___eval(Vlif_neuron___024root* vlSelf);

void Vlif_neuron::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vlif_neuron::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vlif_neuron___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vlif_neuron___024root___eval_static(&(vlSymsp->TOP));
        Vlif_neuron___024root___eval_initial(&(vlSymsp->TOP));
        Vlif_neuron___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vlif_neuron___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vlif_neuron::eventsPending() { return false; }

uint64_t Vlif_neuron::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vlif_neuron::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vlif_neuron___024root___eval_final(Vlif_neuron___024root* vlSelf);

VL_ATTR_COLD void Vlif_neuron::final() {
    Vlif_neuron___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vlif_neuron::hierName() const { return vlSymsp->name(); }
const char* Vlif_neuron::modelName() const { return "Vlif_neuron"; }
unsigned Vlif_neuron::threads() const { return 1; }
void Vlif_neuron::prepareClone() const { contextp()->prepareClone(); }
void Vlif_neuron::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vlif_neuron::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vlif_neuron___024root__trace_decl_types(VerilatedVcd* tracep);

void Vlif_neuron___024root__trace_init_top(Vlif_neuron___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vlif_neuron___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vlif_neuron___024root*>(voidSelf);
    Vlif_neuron__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vlif_neuron___024root__trace_decl_types(tracep);
    Vlif_neuron___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vlif_neuron___024root__trace_register(Vlif_neuron___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vlif_neuron::traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options) {
    (void)levels; (void)options;
    VerilatedVcdC* const stfp = dynamic_cast<VerilatedVcdC*>(tfp);
    if (VL_UNLIKELY(!stfp)) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vlif_neuron::trace()' called on non-VerilatedVcdC object;"
            " use --trace-fst with VerilatedFst object, and --trace-vcd with VerilatedVcd object");
    }
    stfp->spTrace()->addModel(this);
    stfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vlif_neuron___024root__trace_register(&(vlSymsp->TOP), stfp->spTrace());
}
