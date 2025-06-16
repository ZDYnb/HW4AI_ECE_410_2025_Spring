# Challenge #15
**Eric Zhou**  
**April 30, 2025**

# introduction
in this project we are going to try to map our algurithm to systemverilog or verilog to achieve hardware acceleration. However, as I am a new nerd to HDL, I heavily used chatgpt as a reference in this challenge, from code Block plan, software too choice and installation and coding itself. Things went specially not well for 





In challenge 15, I would like to map my gpt2 algurithm into HDL. after previous digging and profiling into the code, I thik I am ready to pose the code diagram
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

We start by building a Transformer-based language model with GPTConfig — specifying depth, width, and vocabulary size.
Then we initialize the model (GPT), which contains embedding layers, a stack of Transformer blocks (each with LayerNorm, Attention, MLP), and a projection head.
We then load pretrained weights from Hugging Face into our custom model.
Once ready, we feed in a prompt, and in each iteration of the generation loop:

We crop context (if needed), forward it through the model, and get token probabilities.

We sample one token, append it to the input, and repeat until we reach the desired output length.
Finally, we decode the token IDs back into text.

above is our previous analysis

and below is your previous thoughts 

My scope in this part is to build  hardware acceleration for the gpt2 model.
I will focus on GPT-2 124M inference only, with fixed weights, and explore HDL implementation. 
🎯 Model: GPT-2 124M (n_layer=12, n_head=12, n_embd=768)
- Fixed weights — no training or backpropagation

- Inference only (no gradient computation)

- Full model mapped to hardware (ideal), or block-by-block in reality


Full GPT-2 HDL Block-Level Architecture (Inference Only)!!!

I first ask gpt advice for HDL plan:

⚙️ HDL Module Plan (RTL Perspective)

HDL Module	Description	Estimated Complexity
token_embedding.v	ROM + lookup	Low
pos_embedding.v	ROM + adder	Low
qkv_linear.v	Fixed-weight matrix-vector product (3x)	High
attention_core.v	QKᵀ → softmax → weighted sum (V)	Very High
mlp_ffn.v	Linear + GELU + Linear	High
layernorm.v	Mean/Var normalize	Medium (LUT-approx optional)
final_linear.v	Linear projection to vocab	High
softmax.v	Exp + Normalize	Medium (LUT-based or CORDIC)
controller.v	Token FSM + Layer scheduler	Medium



I paste my above work to chatgpt and it help me to generate  Block-Level HDL Mapping for verilog
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
📦 Module Breakdown and HDL Notes
HDL Module	Description	HDL Strategy
token_embedding.v	Token ID → Embedding Vec (ROM lookup)	Preload weights in BRAM
pos_embedding.v	Position ID → Pos Vec + Add	Offset adder, ROM
layernorm.v	Normalize to mean/std	Use LUT/log approximations
qkv_linear.v	3× Matrix-Vector Multiply (Q,K,V)	Use MAC array (systolic or time-muxed)
attention_core.v	QKᵀ → softmax → V	Heavy: matrix mult + softmax + MAC
mlp_ffn.v	Linear → GELU → Linear	Use ReLU/GELU LUT, two FCs
final_linear.v	Projection to vocab size (50304)	Partial output, tiled, or compressed
softmax.v	Normalization	Approximate via exp LUT + div
sampling.v	Next token sampling	Argmax or CDF with RNG
controller.v	FSM to control pipeline	Handles context window, prompt token loop


Suffering:
At first I want to follow the python tool to write verilog and do validation. But I find the specicate verilator tool version the pyMTL3 asked for is a pain to install. After I rebuild in Linux. Some strange error poped up. I also search such version in Github, there is a discussion out there indicates that we are not able to use such version.
Then I move forward, I may just want to write pure verilog with latest version of verilator.

My first choice of valication tool is verilator. It has been a pain for me to first install it as at first. It would be useful to just rebuild that

verilator generate wrong results

change to Questa

rewrite in verilog

data quantalization 


`timescale 1ns/100ps    //时间单位为1ns，精度为100ps，合法
shiji




At the beginning of this challenge, I explored multiple directions — starting with PyMTL, thinking that writing hardware in Python might allow better integration with my software-level logic.

However, I quickly realized that GPT-generated PyMTL code was unstable and unreliable. Due to the fast-evolving Python ecosystem and frequent library version mismatches, most code it generated failed to run. After spending some time troubleshooting, I decided to drop this approach and let GPT directly generate plain Verilog instead.

Initially, I simply expected ChatGPT to "just write the code" for me — describing the function I wanted and asking it to implement it in Verilog.
In hindsight, this was a flawed approach. The real issue was that I didn’t yet understand what it truly means to design a digital hardware system. I thought Verilog was just like a low-level C — where writing logic line by line would automatically get mapped into hardware, and pipelining would “just happen” through sequential execution.

At that point, I had no concept of timing vs combinational logic, or of defining modular compute units. I assumed that describing the math was enough, and Verilog would take care of the rest.

For example, I would generate code like this:

verilog
Copy
Edit
always_comb begin
    sum = 0;
    for (int i = 0; i < N; i++) begin
        mul[i] = weights[i] * v[i];       // Q8.8 × Q8.8 = Q16.16
        sum += mul[i];
    end
    out = sum[23:8];  // Q16.16 → Q8.8 (truncation)
end
At first glance, this looks fine — it computes what I need. But I didn’t think about how it translates to real logic gates. There’s no pipelining, no clocking, no enable signals. It’s not a real compute unit — it’s just math written out sequentially.

⚠️ What I Learned
I’ve come to realize that AI tools like GPT can only help if you already know the design structure you want.
If you don’t understand hardware design fundamentals, GPT will happily generate syntactically valid but architecturally broken designs.

In short: without a hardware-aware mindset, AI-generated HDL becomes a distraction — not a solution.
So I stepped back and asked myself:
What is the key computational unit that’s truly worth accelerating?

Looking back at my simplified transformer model, it became clear that matrix multiplication dominates the workload. If I could build a fast and reusable matrix multiply unit, it would benefit almost every stage of the transformer pipeline — from Q/K/V projections to feed-forward layers and output projection.

This insight helped me refocus my efforts.
Instead of trying to build the full pipeline all at once, I decided to start with the core unit: a matrix multiply engine.


At this point, our course had introduced the concept of a systolic array, and I found it both elegant and practical. A systolic array is a structured architecture where data flows rhythmically through a grid of processing elements — like a heartbeat — enabling high-throughput matrix multiplication with predictable timing.

Unlike naïve implementations, a systolic array supports:

Parallelism: Each PE (processing element) computes in parallel with neighbors

Pipelining: Data flows stage by stage, minimizing stalls

Local communication: No global interconnect needed

With these advantages, the systolic array became the foundation of my acceleration plan.


## 🛠️ Design Progress: From Systolic Arrays to Full Tiny Transformer

After struggling with unclear objectives earlier, this time I approached my design with a **clear goal in mind**.  
I knew what I wanted: to build a functional, quantized, and efficient **transformer pipeline**, starting with its core — **matrix multiplication**.

---

### 🔶 Step 1: Systolic Array Construction

I began with the idea that **if we can build a powerful matrix multiplier, we can accelerate the whole design**.  
So I focused on constructing a **systolic array**, starting from the ground up.

- First, I implemented a small **`pe` (processing element)** and **`mac_unit`**.
- After verifying them independently, I gradually composed them into systolic arrays:
  - Started from a `2×2` systolic array as a **proof of concept**
  - Then scaled it up to `4×4`, `8×8`, all the way to `64×64`
- Each version was **simulated and verified to function correctly**
- The design used **Q5.10 fixed-point format**, matching the transformer computation needs

This modular, test-driven growth helped me build confidence before moving on to other components.

---

### 🔶 Step 2: Transformer Submodules

Once the systolic array was working, I moved on to building the rest of the transformer’s computation pipeline.

#### 📐 LayerNorm

I implemented LayerNorm as a pipelined process involving:

1. **Mean computation** via an adder tree
2. **Centering**: compute \( x_i - \mu \)
3. **Squaring**: compute \( (x_i - \mu)^2 \)
4. **Variance computation** with another adder tree
5. **Square root** using the **Newton-Raphson method**
6. **Normalization**:  
   \( \text{norm}_i = \frac{(x_i - \mu)}{\sqrt{\sigma^2 + \epsilon}} \)
7. **Scaling and shifting**:  
   \( y_i = \text{norm}_i × \gamma + \beta \)

This pipeline mirrors the full LayerNorm equation, and was carefully pipelined to avoid combinational delays.

---

#### ⚡ GELU Activation

For GELU, I decided to use a **lookup table (LUT)** instead of implementing the complex tanh-based function directly.

- The input is quantized
- A LUT maps the input to its approximated GELU value
- This decision reduced logic depth and made hardware implementation much easier

---

#### 📊 Softmax

For the softmax layer:

- I used a **LUT for exponential approximation**
- Then performed an **adder tree sum**
- Finally, implemented the division stage using a **normalization-by-max trick** followed by element-wise division

This allowed softmax to be implemented using only fixed-point operations.

---

### 🔧 Step 3: Integration and FSM Control

After each module was individually verified and debugged, I started **connecting them together**, designing a **top-level controller** using a **Finite State Machine (FSM)** to:

- Sequence data flow between layers
- Control valid/ready signals
- Handle memory reuse efficiently

---

### 🤏 Final Design: Scaling Down to 16×16

While my original ambition was to implement a **full 768×768 transformer**, I quickly ran into practical challenges:

- Difficulty in debugging very large Verilog designs  
- Complexity in handling arbitrary matrix dimensions (especially non-square matrices)  
- The overhead of writing and maintaining testbenches at such a large scale

💡 As a result, I decided to **scale down to a `16×16` Tiny Transformer**, with the goal of keeping the design:

- Fully modular  
- Clock-cycle accurate  
- Functionally verifiable through simulation  

---

> ✅ This compromise allowed me to **walk through the full digital design process** — from building reusable submodules, to integrating them at the top level, and finally validating a complete forward pass in hardware.

---

### 🧮 Final Performance

After full integration and testing, the design achieves a complete forward pass in **476 clock cycles**.

If fabricated on an ASIC running at **20 MHz**, this corresponds to:

476 cycles ÷ 20,000,000 Hz ≈ 23.8 µs

That’s roughly **24 microseconds per inference**, enabling lightweight inference at the edge.

---