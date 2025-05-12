// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vvariance_calc__pch.h"

//============================================================
// Constructors

Vvariance_calc::Vvariance_calc(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vvariance_calc__Syms(contextp(), _vcname__, this)}
    , mean{vlSymsp->TOP.mean}
    , variance{vlSymsp->TOP.variance}
    , x{vlSymsp->TOP.x}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vvariance_calc::Vvariance_calc(const char* _vcname__)
    : Vvariance_calc(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vvariance_calc::~Vvariance_calc() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vvariance_calc___024root___eval_debug_assertions(Vvariance_calc___024root* vlSelf);
#endif  // VL_DEBUG
void Vvariance_calc___024root___eval_static(Vvariance_calc___024root* vlSelf);
void Vvariance_calc___024root___eval_initial(Vvariance_calc___024root* vlSelf);
void Vvariance_calc___024root___eval_settle(Vvariance_calc___024root* vlSelf);
void Vvariance_calc___024root___eval(Vvariance_calc___024root* vlSelf);

void Vvariance_calc::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vvariance_calc::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vvariance_calc___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vvariance_calc___024root___eval_static(&(vlSymsp->TOP));
        Vvariance_calc___024root___eval_initial(&(vlSymsp->TOP));
        Vvariance_calc___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vvariance_calc___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vvariance_calc::eventsPending() { return false; }

uint64_t Vvariance_calc::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vvariance_calc::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vvariance_calc___024root___eval_final(Vvariance_calc___024root* vlSelf);

VL_ATTR_COLD void Vvariance_calc::final() {
    Vvariance_calc___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vvariance_calc::hierName() const { return vlSymsp->name(); }
const char* Vvariance_calc::modelName() const { return "Vvariance_calc"; }
unsigned Vvariance_calc::threads() const { return 1; }
void Vvariance_calc::prepareClone() const { contextp()->prepareClone(); }
void Vvariance_calc::atClone() const {
    contextp()->threadPoolpOnClone();
}
