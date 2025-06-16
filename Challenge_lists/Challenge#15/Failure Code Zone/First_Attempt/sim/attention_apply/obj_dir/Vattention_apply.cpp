// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vattention_apply__pch.h"

//============================================================
// Constructors

Vattention_apply::Vattention_apply(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vattention_apply__Syms(contextp(), _vcname__, this)}
    , out{vlSymsp->TOP.out}
    , weights{vlSymsp->TOP.weights}
    , v{vlSymsp->TOP.v}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vattention_apply::Vattention_apply(const char* _vcname__)
    : Vattention_apply(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vattention_apply::~Vattention_apply() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vattention_apply___024root___eval_debug_assertions(Vattention_apply___024root* vlSelf);
#endif  // VL_DEBUG
void Vattention_apply___024root___eval_static(Vattention_apply___024root* vlSelf);
void Vattention_apply___024root___eval_initial(Vattention_apply___024root* vlSelf);
void Vattention_apply___024root___eval_settle(Vattention_apply___024root* vlSelf);
void Vattention_apply___024root___eval(Vattention_apply___024root* vlSelf);

void Vattention_apply::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vattention_apply::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vattention_apply___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vattention_apply___024root___eval_static(&(vlSymsp->TOP));
        Vattention_apply___024root___eval_initial(&(vlSymsp->TOP));
        Vattention_apply___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vattention_apply___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vattention_apply::eventsPending() { return false; }

uint64_t Vattention_apply::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vattention_apply::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vattention_apply___024root___eval_final(Vattention_apply___024root* vlSelf);

VL_ATTR_COLD void Vattention_apply::final() {
    Vattention_apply___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vattention_apply::hierName() const { return vlSymsp->name(); }
const char* Vattention_apply::modelName() const { return "Vattention_apply"; }
unsigned Vattention_apply::threads() const { return 1; }
void Vattention_apply::prepareClone() const { contextp()->prepareClone(); }
void Vattention_apply::atClone() const {
    contextp()->threadPoolpOnClone();
}
