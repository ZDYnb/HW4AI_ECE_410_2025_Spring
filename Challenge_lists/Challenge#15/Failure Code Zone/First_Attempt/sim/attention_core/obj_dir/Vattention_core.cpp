// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vattention_core__pch.h"

//============================================================
// Constructors

Vattention_core::Vattention_core(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vattention_core__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , start{vlSymsp->TOP.start}
    , done{vlSymsp->TOP.done}
    , y{vlSymsp->TOP.y}
    , q{vlSymsp->TOP.q}
    , k{vlSymsp->TOP.k}
    , v{vlSymsp->TOP.v}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vattention_core::Vattention_core(const char* _vcname__)
    : Vattention_core(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vattention_core::~Vattention_core() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vattention_core___024root___eval_debug_assertions(Vattention_core___024root* vlSelf);
#endif  // VL_DEBUG
void Vattention_core___024root___eval_static(Vattention_core___024root* vlSelf);
void Vattention_core___024root___eval_initial(Vattention_core___024root* vlSelf);
void Vattention_core___024root___eval_settle(Vattention_core___024root* vlSelf);
void Vattention_core___024root___eval(Vattention_core___024root* vlSelf);

void Vattention_core::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vattention_core::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vattention_core___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vattention_core___024root___eval_static(&(vlSymsp->TOP));
        Vattention_core___024root___eval_initial(&(vlSymsp->TOP));
        Vattention_core___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vattention_core___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vattention_core::eventsPending() { return false; }

uint64_t Vattention_core::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vattention_core::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vattention_core___024root___eval_final(Vattention_core___024root* vlSelf);

VL_ATTR_COLD void Vattention_core::final() {
    Vattention_core___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vattention_core::hierName() const { return vlSymsp->name(); }
const char* Vattention_core::modelName() const { return "Vattention_core"; }
unsigned Vattention_core::threads() const { return 1; }
void Vattention_core::prepareClone() const { contextp()->prepareClone(); }
void Vattention_core::atClone() const {
    contextp()->threadPoolpOnClone();
}
