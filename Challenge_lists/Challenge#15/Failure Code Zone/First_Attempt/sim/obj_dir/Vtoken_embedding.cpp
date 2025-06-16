// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtoken_embedding__pch.h"

//============================================================
// Constructors

Vtoken_embedding::Vtoken_embedding(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtoken_embedding__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , token_id{vlSymsp->TOP.token_id}
    , embedding_vector0{vlSymsp->TOP.embedding_vector0}
    , embedding_vector1{vlSymsp->TOP.embedding_vector1}
    , embedding_vector2{vlSymsp->TOP.embedding_vector2}
    , embedding_vector3{vlSymsp->TOP.embedding_vector3}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtoken_embedding::Vtoken_embedding(const char* _vcname__)
    : Vtoken_embedding(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtoken_embedding::~Vtoken_embedding() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtoken_embedding___024root___eval_debug_assertions(Vtoken_embedding___024root* vlSelf);
#endif  // VL_DEBUG
void Vtoken_embedding___024root___eval_static(Vtoken_embedding___024root* vlSelf);
void Vtoken_embedding___024root___eval_initial(Vtoken_embedding___024root* vlSelf);
void Vtoken_embedding___024root___eval_settle(Vtoken_embedding___024root* vlSelf);
void Vtoken_embedding___024root___eval(Vtoken_embedding___024root* vlSelf);

void Vtoken_embedding::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtoken_embedding::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtoken_embedding___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtoken_embedding___024root___eval_static(&(vlSymsp->TOP));
        Vtoken_embedding___024root___eval_initial(&(vlSymsp->TOP));
        Vtoken_embedding___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtoken_embedding___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtoken_embedding::eventsPending() { return false; }

uint64_t Vtoken_embedding::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vtoken_embedding::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtoken_embedding___024root___eval_final(Vtoken_embedding___024root* vlSelf);

VL_ATTR_COLD void Vtoken_embedding::final() {
    Vtoken_embedding___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtoken_embedding::hierName() const { return vlSymsp->name(); }
const char* Vtoken_embedding::modelName() const { return "Vtoken_embedding"; }
unsigned Vtoken_embedding::threads() const { return 1; }
void Vtoken_embedding::prepareClone() const { contextp()->prepareClone(); }
void Vtoken_embedding::atClone() const {
    contextp()->threadPoolpOnClone();
}
