// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vnormalize__pch.h"

//============================================================
// Constructors

Vnormalize::Vnormalize(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vnormalize__Syms(contextp(), _vcname__, this)}
    , mean{vlSymsp->TOP.mean}
    , stddev{vlSymsp->TOP.stddev}
    , x{vlSymsp->TOP.x}
    , norm_x{vlSymsp->TOP.norm_x}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vnormalize::Vnormalize(const char* _vcname__)
    : Vnormalize(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vnormalize::~Vnormalize() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vnormalize___024root___eval_debug_assertions(Vnormalize___024root* vlSelf);
#endif  // VL_DEBUG
void Vnormalize___024root___eval_static(Vnormalize___024root* vlSelf);
void Vnormalize___024root___eval_initial(Vnormalize___024root* vlSelf);
void Vnormalize___024root___eval_settle(Vnormalize___024root* vlSelf);
void Vnormalize___024root___eval(Vnormalize___024root* vlSelf);

void Vnormalize::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vnormalize::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vnormalize___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vnormalize___024root___eval_static(&(vlSymsp->TOP));
        Vnormalize___024root___eval_initial(&(vlSymsp->TOP));
        Vnormalize___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vnormalize___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vnormalize::eventsPending() { return false; }

uint64_t Vnormalize::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vnormalize::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vnormalize___024root___eval_final(Vnormalize___024root* vlSelf);

VL_ATTR_COLD void Vnormalize::final() {
    Vnormalize___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vnormalize::hierName() const { return vlSymsp->name(); }
const char* Vnormalize::modelName() const { return "Vnormalize"; }
unsigned Vnormalize::threads() const { return 1; }
void Vnormalize::prepareClone() const { contextp()->prepareClone(); }
void Vnormalize::atClone() const {
    contextp()->threadPoolpOnClone();
}
