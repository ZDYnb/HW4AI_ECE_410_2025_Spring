# Challenge #15
**Eric Zhou**  
**April 30, 2025**

# introduction
in this project we are going to try to map our algurithm to systemverilog to achieve hardware acceleration. However, as I am a new nerd to HDL, I heavily used chatgpt as a reference in this challenge, from code Block plan, software too choice and installation and coding itself.

In challenge 15, I would like to map my gpt2 algurithm into HDL. after above digging into the code, I thik I am ready to pose the code diagram
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