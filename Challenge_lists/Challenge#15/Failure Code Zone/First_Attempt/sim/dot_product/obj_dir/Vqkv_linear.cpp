// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vqkv_linear__pch.h"

//============================================================
// Constructors

Vqkv_linear::Vqkv_linear(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vqkv_linear__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , start{vlSymsp->TOP.start}
    , done{vlSymsp->TOP.done}
    , x{vlSymsp->TOP.x}
    , q{vlSymsp->TOP.q}
    , k{vlSymsp->TOP.k}
    , v{vlSymsp->TOP.v}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vqkv_linear::Vqkv_linear(const char* _vcname__)
    : Vqkv_linear(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vqkv_linear::~Vqkv_linear() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vqkv_linear___024root___eval_debug_assertions(Vqkv_linear___024root* vlSelf);
#endif  // VL_DEBUG
void Vqkv_linear___024root___eval_static(Vqkv_linear___024root* vlSelf);
void Vqkv_linear___024root___eval_initial(Vqkv_linear___024root* vlSelf);
void Vqkv_linear___024root___eval_settle(Vqkv_linear___024root* vlSelf);
void Vqkv_linear___024root___eval(Vqkv_linear___024root* vlSelf);

void Vqkv_linear::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vqkv_linear::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vqkv_linear___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vqkv_linear___024root___eval_static(&(vlSymsp->TOP));
        Vqkv_linear___024root___eval_initial(&(vlSymsp->TOP));
        Vqkv_linear___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vqkv_linear___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vqkv_linear::eventsPending() { return false; }

uint64_t Vqkv_linear::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vqkv_linear::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vqkv_linear___024root___eval_final(Vqkv_linear___024root* vlSelf);

VL_ATTR_COLD void Vqkv_linear::final() {
    Vqkv_linear___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vqkv_linear::hierName() const { return vlSymsp->name(); }
const char* Vqkv_linear::modelName() const { return "Vqkv_linear"; }
unsigned Vqkv_linear::threads() const { return 1; }
void Vqkv_linear::prepareClone() const { contextp()->prepareClone(); }
void Vqkv_linear::atClone() const {
    contextp()->threadPoolpOnClone();
}
