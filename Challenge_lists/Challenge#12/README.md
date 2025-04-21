# Challenge #12
**Eric Zhou**  
**April 20, 2025**

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