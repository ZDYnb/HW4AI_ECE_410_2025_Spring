# Challenge #12
**Eric Zhou**  
**April 20, 2025**

# intro

python tool for HDL. This part of project is for exploring the feasibility for utilizing the python tool for 



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


I plan to give pyMTL (Mamba) a trial as it shown as this list in the first of our tool choice in the list.
First, I want to get myself familiar with the tool I decided to choose. As we have conclude in the Challenge #10, I will first give our ideas from challenge of 10 a tiral. 



First, Initially I first try to use PyMTL. I first simply ask GPT to help me install the tool on my computer and create example file to run upon the tool. However, it does not work as expected. I asked folks about suggestion, and they mentioned could be a wrong with chatgpt suggestion, and should come to copilot for help, which usually have better answer for coding.

I copyed and pasted all the gpt example code to copilot, it suggested the code itself had several issues. Then I think that maybe llm is not good for generating opensource tool code like that. I checked back to the PyMTL project doc file and link to their github repo and check their documentation. They suggest me to run the example code. Then I run the example code and pretty much great! I am able to run now.

But the complier of that is painful to install as compiling SystemVerilog RTL models into C++ simulators, as the PyMTL asking for specital version of verilator, when I was building, everytime I failed.
Then I chat with gpt to confirm whether I should keep trying for the spcial verilator version, but it suggested that I may not need to keep this version as the time change. Then I come back to git the latest version of code and build that and everything smoothly fine!

Then I want to move forward, I have wasted too much time on that shits!

But again, after I have done all the installation of the tools. I am confused by how to use the tool. First of all, my background is a junior year , not familiar,,,,
Here is the statement, there 


In

and also I found the 


Road map to GPT2 RTL
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
