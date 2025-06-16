# Challenge #15
**Eric Zhou**  
**April 30, 2025**

## Introduction

In this project, I set out to map my GPT-2 algorithm to hardware using Verilog or SystemVerilog, aiming for efficient hardware acceleration. As someone new to HDL, I relied heavily on AI tools like ChatGPT, Claude, and Gemini for guidance—drawing on their help for architectural planning, tool selection, and even code generation.

Despite the promise of these AI tools, the process was far from smooth. I encountered numerous challenges, from toolchain compatibility issues to the realization that AI-generated HDL often lacks the architectural awareness needed for real hardware design. These hurdles forced me to rethink my approach, deepen my understanding of digital design fundamentals, and iteratively refine both my methodology and implementation.

This document details my journey: the initial ambitions, the obstacles faced, and the lessons learned as I transitioned from software-level thinking to a hardware-oriented mindset.

---

## GPT-2 Model Analysis

In Challenge 15, my goal was to map my GPT-2 algorithm into HDL. After previous profiling and code analysis, I was ready to pose the code diagram:

```
┌────────────────────┐
│ 1. Model Config    │
│ GPTConfig:         │
│  - block_size=1024 │
│  - vocab_size=50304│
│  - n_layer=12      │
│  - n_head=12       │
│  - n_embd=768      │
└────────┬───────────┘
     ↓
┌──────────────────────┐
│ 2. Model Construction│
│  - Token Embedding   │
│  - Positional Embed  │
│  - Transformer Blocks│
│      • LayerNorm     │
│      • SelfAttention │
│      • MLP + Res     │
│  - Final LayerNorm   │
│  - Linear lm_head    │
└────────┬─────────────┘
     ↓
┌─────────────────────────────┐
│ 3. Load Pretrained Weights  │
│  - Match with HF checkpoint │
│  - Transpose where needed   │
└────────┬────────────────────┘
     ↓
┌───────────────────────────────┐
│ 4. Inference Loop (generate)  │
│  Input Prompt → Encode (token IDs) │
│  For each token to generate:       │
│   - Crop context if too long       │
│   - Forward through model          │
│   - Predict next token probs       │
│   - Sample next token              │
│   - Append to prompt               │
└────────┬──────────────────────────┘
     ↓
┌──────────────────────────┐
│ 5. Decode Token Sequence │
│  - Convert back to text  │
│  - Output final string   │
└──────────────────────────┘
```

**Summary:**  
- Build a Transformer-based language model with GPTConfig (depth, width, vocab size).
- Initialize the model (GPT) with embedding layers, transformer blocks, and projection head.
- Load pretrained weights from Hugging Face.
- Feed in a prompt, crop context, forward through the model, sample tokens, and decode output.

---

## HDL Mapping and Block-Level Architecture

My scope was to build hardware acceleration for the GPT-2 124M model (n_layer=12, n_head=12, n_embd=768), focusing on inference only with fixed weights.

### HDL Module Plan (RTL Perspective)

| HDL Module         | Description                                | Estimated Complexity      |
|--------------------|--------------------------------------------|--------------------------|
| token_embedding.v  | ROM + lookup                               | Low                      |
| pos_embedding.v    | ROM + adder                                | Low                      |
| qkv_linear.v       | Fixed-weight matrix-vector product (3x)    | High                     |
| attention_core.v   | QKᵀ → softmax → weighted sum (V)           | Very High                |
| mlp_ffn.v          | Linear + GELU + Linear                     | High                     |
| layernorm.v        | Mean/Var normalize                         | Medium (LUT-approx)      |
| final_linear.v     | Linear projection to vocab                  | High                     |
| softmax.v          | Exp + Normalize                            | Medium (LUT/CORDIC)      |
| controller.v       | Token FSM + Layer scheduler                | Medium                   |

### Block-Level HDL Mapping

```
┌────────────────────────────────────────────┐
│ Module: GPT2_TOP.v                         │
│ - Controls token stream & orchestrates     │
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
│ [2] Transformer Block × 12 (pipelined/FSM) │
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

#### Module Breakdown and HDL Notes

| HDL Module         | Description                        | HDL Strategy                |
|--------------------|------------------------------------|-----------------------------|
| token_embedding.v  | Token ID → Embedding Vec (ROM)     | Preload weights in BRAM     |
| pos_embedding.v    | Position ID → Pos Vec + Add        | Offset adder, ROM           |
| layernorm.v        | Normalize to mean/std              | LUT/log approximations      |
| qkv_linear.v       | 3× Matrix-Vector Multiply (Q,K,V)  | MAC array (systolic/time-mux)|
| attention_core.v   | QKᵀ → softmax → V                  | Matrix mult + softmax + MAC |
| mlp_ffn.v          | Linear → GELU → Linear             | ReLU/GELU LUT, two FCs      |
| final_linear.v     | Projection to vocab size (50304)   | Partial/tiled/compressed    |
| softmax.v          | Normalization                      | Exp LUT + div               |
| sampling.v         | Next token sampling                | Argmax or CDF with RNG      |
| controller.v       | FSM to control pipeline            | Handles context window      |

---

## Toolchain Struggles

Initially, I wanted to use Python-based tools (PyMTL) for hardware design, hoping for better integration with my software logic. However, GPT-generated PyMTL code was unstable due to frequent library version mismatches. After troubleshooting, I switched to generating plain Verilog.

My first choice for validation was Verilator, but installation and compatibility issues (especially with PyMTL3) made it impractical. I eventually moved to Questa and focused on writing pure Verilog.

---

## Lessons Learned: From Naive HDL to Hardware-Aware Design

At first, I expected ChatGPT to "just write the code" for me, describing the function and asking for Verilog. I soon realized this was flawed—without understanding hardware design fundamentals, AI-generated HDL is often architecturally broken.

**Example:**

```verilog
always_comb begin
  sum = 0;
  for (int i = 0; i < N; i++) begin
    mul[i] = weights[i] * v[i];       // Q8.8 × Q8.8 = Q16.16
    sum += mul[i];
  end
  out = sum[23:8];  // Q16.16 → Q8.8 (truncation)
end
```

This code computes the math but ignores pipelining, clocking, and enable signals—it's not a real compute unit.

**Key Takeaway:**  
AI tools like GPT can only help if you already know the design structure you want. Without a hardware-aware mindset, AI-generated HDL becomes a distraction.

---

## Refocusing: Matrix Multiply as the Core

Matrix multiplication dominates the transformer workload. Building a fast, reusable matrix multiply unit benefits almost every stage of the transformer pipeline.

### Systolic Array: The Foundation

A systolic array is a structured architecture where data flows rhythmically through a grid of processing elements, enabling high-throughput matrix multiplication with predictable timing.

**Advantages:**
- **Parallelism:** Each PE computes in parallel
- **Pipelining:** Data flows stage by stage
- **Local communication:** No global interconnect needed

---

## Design Progress: From Systolic Arrays to Full Tiny Transformer

### step 1: Systolic Array Construction

- Implemented small `pe` (processing element) and `mac_unit`
- Built systolic arrays: 2×2 → 4×4 → 8×8 → 64×64
- Simulated and verified each version
- Used Q5.10 fixed-point format

### Step 2: Transformer Submodules

#### LayerNorm

- Mean computation using an adder tree
- Centering and squaring of inputs
- Variance computation
- Square root via Newton-Raphson iteration
- Normalization and scaling

**Pipeline Architecture (21 Stages):**
- 16-way adder trees for parallel reduction
- Stage 0-2: Mean adder tree (3 stages)
- Stage 3: Mean division μ = sum/16
- Stage 4: Difference calculation diff = xi - μ
- Stage 5: Squaring diff²
- Stage 6-8: Variance adder tree (3 stages)
- Stage 9: Variance division + epsilon σ² = sum/16 + ε
- Stage 10: Initial guess lookup x0
- Stage 11: First multiplication x0²
- Stage 12: Second multiplication variance × x0²
- Stage 13: First subtraction 3 - variance×x0²
- Stage 14: Third multiplication + shift x1 = x0×result÷2
- Stage 15: Fourth multiplication x1²
- Stage 16: Fifth multiplication variance × x1²
- Stage 17: Second subtraction 3 - variance×x1²
- Stage 18: Sixth multiplication + shift inv_sigma = x1×result÷2
- Stage 19: 16 parallel multiplications normalized = diff × inv_sigma
- Stage 20: 16 parallel multiplications scaled = normalized × γ
- Stage 21: 16 parallel additions output = scaled + β

#### GELU Activation

- Used LUT for GELU approximation (quantized input)

- should be be just 1 stage of cycle.

#### Softmax

- LUT for exponential approximation
- Adder tree sum
- Division via normalization-by-max and element-wise division

- Stage 0: Input latch       (Cycle 1)
- Stage 1: 64→32 addition   (Cycle 2)  
- Stage 2: 32→16 addition   (Cycle 3)
- Stage 3: 16→8  addition   (Cycle 4)
- Stage 4: 8→4   addition   (Cycle 5)
- Stage 5: 4→2   addition   (Cycle 6)
- Stage 6: 2→1   addition   (Cycle 7)
- Stage 7: Output register  (Cycle 8) ← sum_valid=1

### Step 3: Integration and FSM Control

After we finished building all the individual modules - the matrix multiplier, layer normalization processor, softmax processor, and GELU processor - we needed to connect them all together in a top-level design. This is where the real challenge began.

The first question was how to connect these modules efficiently. Each module needed to communicate with the others, passing data from one computation to the next. We had several options: we could create dedicated point-to-point connections between every module, or we could use some kind of shared communication system.

I asked for gpt's help using a shared bus architecture. The idea was simple - instead of having separate wires connecting every module to every other module, we would have common buses that all modules could use. This would save a lot of wiring and make the design much cleaner.

The shared bus concept meant having common input buses - bus_matrix_a and bus_matrix_b - that could carry data to whichever module needed to process it at any given time. Since our transformer computation is sequential, not parallel, only one module would be active at a time anyway. So sharing the input buses made perfect sense.

But then I ran into the race condition problem. Initially, that all modules could also share the output bus - bus_matrix_c. This seemed logical at first, but it created a serious problem. When multiple modules are instantiated and all connected to the same output wire, they can all try to drive that wire simultaneously, even when they're not supposed to be active. This creates race conditions and hazards.

So I choose to separate the output wires. Instead of one shared bus_matrix_c, we created dedicated output wires for each module - mult_matrix_c for the matrix multiplier, ln_matrix_c for the layer normalization, sm_matrix_c for softmax, and gelu_matrix_c for GELU. This way, each module had its own dedicated output path, eliminating any possibility of contention.

The FSM design became the brain of the system. 
Starting with token embedding, the FSM would load the input tokens and convert them to embedding vectors. Then it would perform the pre-attention layer normalization, storing the result for the Q, K, V computations that would follow.
The Q, K, V computation required three separate matrix multiplications, but we only had one matrix multiplier. So the FSM would sequence through these operations one by one. First, it would load the normalized input and the Q weights onto the input buses, start the matrix multiplier, wait for completion, and store the Q result. Then it would repeat this process for K and V.
The attention mechanism required computing Q×K^T, which meant transposing the K matrix and multiplying. The FSM handled this by loading Q onto one bus and K-transposed onto the other bus, then using the matrix multiplier again.
After getting the attention scores, we needed softmax, which required switching to the softmax processor. The FSM would load the scores onto the input bus, activate the softmax unit, and collect the attention weights from its dedicated output wire.
Computing the attention output meant another matrix multiplication - the attention weights times V. So back to the matrix multiplier, with the FSM loading the appropriate data and collecting results.
The residual connections were handled directly by the FSM - simple element-wise additions that didn't require a separate module. Then came another layer normalization, using the same layer norm processor but with different input data.
The feed-forward network required two more matrix multiplications with a GELU activation in between. The FSM would orchestrate matrix mult for the first FF layer, then switch to the GELU processor, then back to matrix mult for the second FF layer.

Finally, there was another residual connection, a final layer normalization, the output projection matrix multiplication, and a final softmax to get the probability distribution.

Throughout this entire process, the FSM was managing the shared buses, making sure the right data was loaded at the right time, starting and stopping the appropriate modules, and collecting results from the separated output wires.

The key insight was that by separating the output wires while keeping the input buses shared, we got the best of both worlds - efficient resource utilization without race conditions. The FSM could reliably know where each piece of data was coming from and where it needed to go next.

This approach allowed us to implement a complete transformer with just four processing modules instead of needing dozens of separate units. The trade-off was increased control complexity and more cycles to complete the computation, but for an ASIC implementation focused on area efficiency, this was exactly the right choice.

The final result was a clean, race-free design that could reliably process transformer computations in 482 clock cycles, with all the complex orchestration handled by the FSM and the shared bus architecture providing efficient resource utilization.

## Final Digital System Architecture

```
          ┌─────────────────────────────┐
          │        Control FSM          │
          │   (23 states, 482 cycles)   │
          └──────────┬───────────┬──────┘
                 │           │
          ┌──────────▼─────┐     │
          │  Bus Control   │     │
          │   & MUX Logic  │     │
          └──────────┬─────┘     │
                 │           │
      ┌──────────────────▼───────────▼──────────────────┐
      │                Shared Buses                     │
      │   bus_matrix_a[255:0]   bus_matrix_b[255:0]     │
      └──────┬─────────┬─────────┬─────────┬────────────┘
           │         │         │         │
       ┌───────▼──┐ ┌────▼────┐ ┌──▼────┐ ┌──▼─────┐
       │ Matrix   │ │ Layer   │ │ Soft- │ │  GELU  │
       │ Mult     │ │ Norm    │ │ max   │ │  Unit  │
       │ Unit     │ │ Unit    │ │ Unit  │ │        │
       └───────┬──┘ └────┬────┘ └──┬────┘ └──┬─────┘
           │         │         │         │
       ┌───────▼──┐ ┌────▼────┐ ┌──▼────┐ ┌──▼─────┐
       │ mult_    │ │ ln_     │ │ sm_   │ │ gelu_  │
       │ matrix_c │ │ matrix_c│ │ matrix_c│ matrix_c│
       └──────────┘ └─────────┘ └────────┘ └────────┘
```

**Description:**  
- The **Control FSM** orchestrates the computation, sequencing through 23 states over 482 cycles.
- **Bus Control & MUX Logic** manages data flow on shared input buses (`bus_matrix_a`, `bus_matrix_b`).
- Four main compute units (Matrix Multiplier, LayerNorm, Softmax, GELU) share input buses but have dedicated output wires to avoid contention.
- Each compute unit outputs results on its own bus (`*_matrix_c`), ensuring race-free operation.
- This modular, bus-based architecture enables efficient resource sharing and clean integration for the full transformer pipeline.



> This compromise allowed me to walk through the full digital design process—from building reusable submodules, to integrating them at the top level, and finally validating a complete forward pass in hardware.

---

### Final Performance

- Complete forward pass in **476 clock cycles**
- On a 20 MHz ASIC:  
  476 cycles ÷ 20,000,000 Hz ≈ **23.8 µs** per inference

That’s roughly **24 microseconds per inference**, enabling lightweight inference at the edge.

---
