// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vsoftmax__pch.h"

//============================================================
// Constructors

Vsoftmax::Vsoftmax(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vsoftmax__Syms(contextp(), _vcname__, this)}
    , x{vlSymsp->TOP.x}
    , y{vlSymsp->TOP.y}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vsoftmax::Vsoftmax(const char* _vcname__)
    : Vsoftmax(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vsoftmax::~Vsoftmax() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vsoftmax___024root___eval_debug_assertions(Vsoftmax___024root* vlSelf);
#endif  // VL_DEBUG
void Vsoftmax___024root___eval_static(Vsoftmax___024root* vlSelf);
void Vsoftmax___024root___eval_initial(Vsoftmax___024root* vlSelf);
void Vsoftmax___024root___eval_settle(Vsoftmax___024root* vlSelf);
void Vsoftmax___024root___eval(Vsoftmax___024root* vlSelf);

void Vsoftmax::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vsoftmax::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vsoftmax___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vsoftmax___024root___eval_static(&(vlSymsp->TOP));
        Vsoftmax___024root___eval_initial(&(vlSymsp->TOP));
        Vsoftmax___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vsoftmax___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vsoftmax::eventsPending() { return false; }

uint64_t Vsoftmax::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vsoftmax::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vsoftmax___024root___eval_final(Vsoftmax___024root* vlSelf);

VL_ATTR_COLD void Vsoftmax::final() {
    Vsoftmax___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vsoftmax::hierName() const { return vlSymsp->name(); }
const char* Vsoftmax::modelName() const { return "Vsoftmax"; }
unsigned Vsoftmax::threads() const { return 1; }
void Vsoftmax::prepareClone() const { contextp()->prepareClone(); }
void Vsoftmax::atClone() const {
    contextp()->threadPoolpOnClone();
}
