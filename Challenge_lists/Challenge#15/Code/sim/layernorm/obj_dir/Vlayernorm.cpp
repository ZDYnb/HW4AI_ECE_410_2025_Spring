// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vlayernorm__pch.h"

//============================================================
// Constructors

Vlayernorm::Vlayernorm(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vlayernorm__Syms(contextp(), _vcname__, this)}
    , a{vlSymsp->TOP.a}
    , b{vlSymsp->TOP.b}
    , y{vlSymsp->TOP.y}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vlayernorm::Vlayernorm(const char* _vcname__)
    : Vlayernorm(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vlayernorm::~Vlayernorm() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vlayernorm___024root___eval_debug_assertions(Vlayernorm___024root* vlSelf);
#endif  // VL_DEBUG
void Vlayernorm___024root___eval_static(Vlayernorm___024root* vlSelf);
void Vlayernorm___024root___eval_initial(Vlayernorm___024root* vlSelf);
void Vlayernorm___024root___eval_settle(Vlayernorm___024root* vlSelf);
void Vlayernorm___024root___eval(Vlayernorm___024root* vlSelf);

void Vlayernorm::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vlayernorm::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vlayernorm___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vlayernorm___024root___eval_static(&(vlSymsp->TOP));
        Vlayernorm___024root___eval_initial(&(vlSymsp->TOP));
        Vlayernorm___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vlayernorm___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vlayernorm::eventsPending() { return false; }

uint64_t Vlayernorm::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vlayernorm::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vlayernorm___024root___eval_final(Vlayernorm___024root* vlSelf);

VL_ATTR_COLD void Vlayernorm::final() {
    Vlayernorm___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vlayernorm::hierName() const { return vlSymsp->name(); }
const char* Vlayernorm::modelName() const { return "Vlayernorm"; }
unsigned Vlayernorm::threads() const { return 1; }
void Vlayernorm::prepareClone() const { contextp()->prepareClone(); }
void Vlayernorm::atClone() const {
    contextp()->threadPoolpOnClone();
}
