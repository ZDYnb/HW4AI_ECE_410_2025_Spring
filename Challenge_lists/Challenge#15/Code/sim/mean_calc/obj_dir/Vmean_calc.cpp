// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vmean_calc__pch.h"

//============================================================
// Constructors

Vmean_calc::Vmean_calc(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vmean_calc__Syms(contextp(), _vcname__, this)}
    , mean{vlSymsp->TOP.mean}
    , x{vlSymsp->TOP.x}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vmean_calc::Vmean_calc(const char* _vcname__)
    : Vmean_calc(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vmean_calc::~Vmean_calc() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vmean_calc___024root___eval_debug_assertions(Vmean_calc___024root* vlSelf);
#endif  // VL_DEBUG
void Vmean_calc___024root___eval_static(Vmean_calc___024root* vlSelf);
void Vmean_calc___024root___eval_initial(Vmean_calc___024root* vlSelf);
void Vmean_calc___024root___eval_settle(Vmean_calc___024root* vlSelf);
void Vmean_calc___024root___eval(Vmean_calc___024root* vlSelf);

void Vmean_calc::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vmean_calc::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vmean_calc___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vmean_calc___024root___eval_static(&(vlSymsp->TOP));
        Vmean_calc___024root___eval_initial(&(vlSymsp->TOP));
        Vmean_calc___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vmean_calc___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vmean_calc::eventsPending() { return false; }

uint64_t Vmean_calc::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vmean_calc::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vmean_calc___024root___eval_final(Vmean_calc___024root* vlSelf);

VL_ATTR_COLD void Vmean_calc::final() {
    Vmean_calc___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vmean_calc::hierName() const { return vlSymsp->name(); }
const char* Vmean_calc::modelName() const { return "Vmean_calc"; }
unsigned Vmean_calc::threads() const { return 1; }
void Vmean_calc::prepareClone() const { contextp()->prepareClone(); }
void Vmean_calc::atClone() const {
    contextp()->threadPoolpOnClone();
}
