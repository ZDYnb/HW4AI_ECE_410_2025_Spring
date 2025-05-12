// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vdot_product__pch.h"

//============================================================
// Constructors

Vdot_product::Vdot_product(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vdot_product__Syms(contextp(), _vcname__, this)}
    , result{vlSymsp->TOP.result}
    , a{vlSymsp->TOP.a}
    , b{vlSymsp->TOP.b}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vdot_product::Vdot_product(const char* _vcname__)
    : Vdot_product(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vdot_product::~Vdot_product() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vdot_product___024root___eval_debug_assertions(Vdot_product___024root* vlSelf);
#endif  // VL_DEBUG
void Vdot_product___024root___eval_static(Vdot_product___024root* vlSelf);
void Vdot_product___024root___eval_initial(Vdot_product___024root* vlSelf);
void Vdot_product___024root___eval_settle(Vdot_product___024root* vlSelf);
void Vdot_product___024root___eval(Vdot_product___024root* vlSelf);

void Vdot_product::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vdot_product::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vdot_product___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vdot_product___024root___eval_static(&(vlSymsp->TOP));
        Vdot_product___024root___eval_initial(&(vlSymsp->TOP));
        Vdot_product___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vdot_product___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vdot_product::eventsPending() { return false; }

uint64_t Vdot_product::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vdot_product::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vdot_product___024root___eval_final(Vdot_product___024root* vlSelf);

VL_ATTR_COLD void Vdot_product::final() {
    Vdot_product___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vdot_product::hierName() const { return vlSymsp->name(); }
const char* Vdot_product::modelName() const { return "Vdot_product"; }
unsigned Vdot_product::threads() const { return 1; }
void Vdot_product::prepareClone() const { contextp()->prepareClone(); }
void Vdot_product::atClone() const {
    contextp()->threadPoolpOnClone();
}
