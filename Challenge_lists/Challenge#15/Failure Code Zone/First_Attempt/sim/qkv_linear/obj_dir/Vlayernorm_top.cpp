// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vlayernorm_top__pch.h"

//============================================================
// Constructors

Vlayernorm_top::Vlayernorm_top(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vlayernorm_top__Syms(contextp(), _vcname__, this)}
    , x{vlSymsp->TOP.x}
    , norm_x{vlSymsp->TOP.norm_x}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vlayernorm_top::Vlayernorm_top(const char* _vcname__)
    : Vlayernorm_top(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vlayernorm_top::~Vlayernorm_top() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vlayernorm_top___024root___eval_debug_assertions(Vlayernorm_top___024root* vlSelf);
#endif  // VL_DEBUG
void Vlayernorm_top___024root___eval_static(Vlayernorm_top___024root* vlSelf);
void Vlayernorm_top___024root___eval_initial(Vlayernorm_top___024root* vlSelf);
void Vlayernorm_top___024root___eval_settle(Vlayernorm_top___024root* vlSelf);
void Vlayernorm_top___024root___eval(Vlayernorm_top___024root* vlSelf);

void Vlayernorm_top::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vlayernorm_top::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vlayernorm_top___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vlayernorm_top___024root___eval_static(&(vlSymsp->TOP));
        Vlayernorm_top___024root___eval_initial(&(vlSymsp->TOP));
        Vlayernorm_top___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vlayernorm_top___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vlayernorm_top::eventsPending() { return false; }

uint64_t Vlayernorm_top::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vlayernorm_top::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vlayernorm_top___024root___eval_final(Vlayernorm_top___024root* vlSelf);

VL_ATTR_COLD void Vlayernorm_top::final() {
    Vlayernorm_top___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vlayernorm_top::hierName() const { return vlSymsp->name(); }
const char* Vlayernorm_top::modelName() const { return "Vlayernorm_top"; }
unsigned Vlayernorm_top::threads() const { return 1; }
void Vlayernorm_top::prepareClone() const { contextp()->prepareClone(); }
void Vlayernorm_top::atClone() const {
    contextp()->threadPoolpOnClone();
}
