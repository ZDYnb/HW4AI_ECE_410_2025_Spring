# Challenge #12
**Eric Zhou**  
**April 20, 2025**
## Introduction

This project explores the feasibility of using Python-based hardware description tools for implementing hardware acceleration of the GPT-2 model. The focus is on inference-only deployment of GPT-2 124M (n_layer=12, n_head=12, n_embd=768) with fixed weights—no training or backpropagation. The goal is to map the full model to hardware, ideally as a complete system, or block-by-block as needed.

### Scope

- **Model:** GPT-2 124M (12 layers, 12 heads, 768 embedding size)
- **Weights:** Fixed (no training or gradient computation)
- **Task:** Inference only
- **Implementation:** HDL (Hardware Description Language), block-level architecture

---

## HDL Block-Level Architecture for GPT-2 (Inference Only)

| HDL Module         | Description                                 | Estimated Complexity         |
|--------------------|---------------------------------------------|------------------------------|
| token_embedding.v  | ROM + lookup                                | Low                          |
| pos_embedding.v    | ROM + adder                                 | Low                          |
| qkv_linear.v       | Fixed-weight matrix-vector product (3x)      | High                         |
| attention_core.v   | QKᵀ → softmax → weighted sum (V)            | Very High                    |
| mlp_ffn.v          | Linear + GELU + Linear                      | High                         |
| layernorm.v        | Mean/Var normalize (LUT-approx optional)    | Medium                       |
| final_linear.v     | Linear projection to vocab                   | High                         |
| softmax.v          | Exp + Normalize (LUT-based or CORDIC)       | Medium                       |
| controller.v       | Token FSM + Layer scheduler                  | Medium                       |

---

## Tool Selection and Initial Experience

I chose to trial **PyMTL (Mamba)**, as it was highly recommended in our tool selection process. My initial steps included:

1. **Familiarization:** Attempted to install PyMTL and run example files, initially following GPT-generated instructions, which led to issues.
2. **Troubleshooting:** Sought advice from peers and Copilot, which revealed problems in the example code. Realized that LLM-generated code for open-source tools can be unreliable.
3. **Documentation Review:** Consulted the official PyMTL documentation and GitHub repository, which provided working example code.
4. **Installation Challenges:** Faced difficulties installing the required version of Verilator for SystemVerilog RTL simulation. After several failed attempts and further research, I switched to the latest version, which resolved the issues.
5. **Outcome:** Successfully installed the tools and ran the example code.

Despite overcoming installation hurdles, I found the learning curve for using PyMTL steep, especially as a junior with limited hardware background. The documentation and community resources were essential in bridging these gaps.

---

## GPT-2 RTL Implementation Roadmap

```
┌────────────────────────────────────────────┐
│ Module: GPT2_TOP.v                         │
│ - Controls token stream & orchestrates      │
│   token generation steps                   │
│ - Interfaces with memory for embeddings    │
│ - Connects Transformer blocks sequentially │
└────────┬───────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│ [1] Token & Positional Embeddings          │
│ token_embedding.v: ROM lookup (token ID → vector)   │
│ pos_embedding.v: ROM lookup + add (position → vector) │
└────────┬───────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│ [2] Transformer Block × 12 (pipelined or FSM) │
│ ┌─────────────────────────────────────────┐ │
│ │ layernorm.v (x2)                        │ │
│ │ qkv_linear.v                            │ │
│ │ attention_core.v                        │ │
│ │ residual_add.v                          │ │
│ │ mlp_ffn.v (Linear → GELU → Linear)      │ │
│ │ residual_add.v                          │ │
│ └─────────────────────────────────────────┘ │
└────────┬───────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│ [3] Final LayerNorm & Linear Head          │
│ final_layernorm.v                          │
│ final_linear.v (projection to vocab)       │
└────────┬───────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│ [4] Softmax + Sampling                     │
│ softmax.v (LUT or CORDIC-based exp/log)    │
│ sampling.v (argmax or random + CDF)        │
└────────┬───────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│ [5] Controller.v                           │
│ FSM:                                       │
│  - Manages token iteration loop            │
│  - Schedules each Transformer layer        │
│  - Crops context if needed (fixed buffer)  │
└────────────────────────────────────────────┘
```

---

## Summary

- Explored Python-based HDL tools for GPT-2 hardware acceleration.
- Overcame installation and setup challenges with PyMTL and Verilator.
- Outlined a block-level hardware architecture for GPT-2 inference.
- Identified key modules and their complexity for RTL implementation.

This documentation serves as a foundation for further development and experimentation with hardware acceleration of large language models using modern HDL tools.
