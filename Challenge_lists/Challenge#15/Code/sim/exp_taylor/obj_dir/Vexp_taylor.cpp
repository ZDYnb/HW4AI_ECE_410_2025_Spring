// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vexp_taylor__pch.h"

//============================================================
// Constructors

Vexp_taylor::Vexp_taylor(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vexp_taylor__Syms(contextp(), _vcname__, this)}
    , x_q88{vlSymsp->TOP.x_q88}
    , y_q88{vlSymsp->TOP.y_q88}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vexp_taylor::Vexp_taylor(const char* _vcname__)
    : Vexp_taylor(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vexp_taylor::~Vexp_taylor() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vexp_taylor___024root___eval_debug_assertions(Vexp_taylor___024root* vlSelf);
#endif  // VL_DEBUG
void Vexp_taylor___024root___eval_static(Vexp_taylor___024root* vlSelf);
void Vexp_taylor___024root___eval_initial(Vexp_taylor___024root* vlSelf);
void Vexp_taylor___024root___eval_settle(Vexp_taylor___024root* vlSelf);
void Vexp_taylor___024root___eval(Vexp_taylor___024root* vlSelf);

void Vexp_taylor::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vexp_taylor::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vexp_taylor___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vexp_taylor___024root___eval_static(&(vlSymsp->TOP));
        Vexp_taylor___024root___eval_initial(&(vlSymsp->TOP));
        Vexp_taylor___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vexp_taylor___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vexp_taylor::eventsPending() { return false; }

uint64_t Vexp_taylor::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vexp_taylor::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vexp_taylor___024root___eval_final(Vexp_taylor___024root* vlSelf);

VL_ATTR_COLD void Vexp_taylor::final() {
    Vexp_taylor___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vexp_taylor::hierName() const { return vlSymsp->name(); }
const char* Vexp_taylor::modelName() const { return "Vexp_taylor"; }
unsigned Vexp_taylor::threads() const { return 1; }
void Vexp_taylor::prepareClone() const { contextp()->prepareClone(); }
void Vexp_taylor::atClone() const {
    contextp()->threadPoolpOnClone();
}
