// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vsqrt_lut__pch.h"

//============================================================
// Constructors

Vsqrt_lut::Vsqrt_lut(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vsqrt_lut__Syms(contextp(), _vcname__, this)}
    , in_q88{vlSymsp->TOP.in_q88}
    , out_q88{vlSymsp->TOP.out_q88}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vsqrt_lut::Vsqrt_lut(const char* _vcname__)
    : Vsqrt_lut(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vsqrt_lut::~Vsqrt_lut() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vsqrt_lut___024root___eval_debug_assertions(Vsqrt_lut___024root* vlSelf);
#endif  // VL_DEBUG
void Vsqrt_lut___024root___eval_static(Vsqrt_lut___024root* vlSelf);
void Vsqrt_lut___024root___eval_initial(Vsqrt_lut___024root* vlSelf);
void Vsqrt_lut___024root___eval_settle(Vsqrt_lut___024root* vlSelf);
void Vsqrt_lut___024root___eval(Vsqrt_lut___024root* vlSelf);

void Vsqrt_lut::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vsqrt_lut::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vsqrt_lut___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vsqrt_lut___024root___eval_static(&(vlSymsp->TOP));
        Vsqrt_lut___024root___eval_initial(&(vlSymsp->TOP));
        Vsqrt_lut___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vsqrt_lut___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vsqrt_lut::eventsPending() { return false; }

uint64_t Vsqrt_lut::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vsqrt_lut::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vsqrt_lut___024root___eval_final(Vsqrt_lut___024root* vlSelf);

VL_ATTR_COLD void Vsqrt_lut::final() {
    Vsqrt_lut___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vsqrt_lut::hierName() const { return vlSymsp->name(); }
const char* Vsqrt_lut::modelName() const { return "Vsqrt_lut"; }
unsigned Vsqrt_lut::threads() const { return 1; }
void Vsqrt_lut::prepareClone() const { contextp()->prepareClone(); }
void Vsqrt_lut::atClone() const {
    contextp()->threadPoolpOnClone();
}
