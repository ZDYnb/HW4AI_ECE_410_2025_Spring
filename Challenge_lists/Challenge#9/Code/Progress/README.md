Ch#9

Here I start to dig into the NanoGPT code construction — how a simple GPT-2 really works, how the computing is structured inside the code, and the mystery of the transformer network. As I mainly focus on deployment, I will start by focusing on inference and reconstructing sample.py in NanoGPT here to do futher analysis and profile the original code. 

First, let us redo the overview bench mark here. To use Jupyter note book as a good trace, I restate the whole code below:



```python
import os
import pickle
from contextlib import nullcontext
import torch
import tiktoken
from model import GPTConfig, GPT

```


    ---------------------------------------------------------------------------

    ModuleNotFoundError                       Traceback (most recent call last)

    Cell In[23], line 6
          4 import torch
          5 import tiktoken
    ----> 6 from model import GPTConfig, GPT
    

    ModuleNotFoundError: No module named 'model'


As listing above, let go through first in the module in different code file and restate here.


The whole model is a implementation of GPT language model, all need to restate here
# detailed anaysis of structure
GPT module:




```python
"""
Full definition of a GPT Language Model, all of it in this single file.
References:
1) the official GPT-2 TensorFlow implementation released by OpenAI:
https://github.com/openai/gpt-2/blob/master/src/model.py
2) huggingface/transformers PyTorch implementation:
https://github.com/huggingface/transformers/blob/main/src/transformers/models/gpt2/modeling_gpt2.py
"""

import math
import inspect
from dataclasses import dataclass

import torch
import torch.nn as nn
from torch.nn import functional as F

class LayerNorm(nn.Module):
    """ LayerNorm but with an optional bias. PyTorch doesn't support simply bias=False """

    def __init__(self, ndim, bias):
        super().__init__()
        self.weight = nn.Parameter(torch.ones(ndim))
        self.bias = nn.Parameter(torch.zeros(ndim)) if bias else None

    def forward(self, input):
        return F.layer_norm(input, self.weight.shape, self.weight, self.bias, 1e-5)

class CausalSelfAttention(nn.Module):

    def __init__(self, config):
        super().__init__()
        assert config.n_embd % config.n_head == 0
        # key, query, value projections for all heads, but in a batch
        self.c_attn = nn.Linear(config.n_embd, 3 * config.n_embd, bias=config.bias)
        # output projection
        self.c_proj = nn.Linear(config.n_embd, config.n_embd, bias=config.bias)
        # regularization
        self.attn_dropout = nn.Dropout(config.dropout)
        self.resid_dropout = nn.Dropout(config.dropout)
        self.n_head = config.n_head
        self.n_embd = config.n_embd
        self.dropout = config.dropout
        # flash attention make GPU go brrrrr but support is only in PyTorch >= 2.0
        self.flash = hasattr(torch.nn.functional, 'scaled_dot_product_attention')
        if not self.flash:
            print("WARNING: using slow attention. Flash Attention requires PyTorch >= 2.0")
            # causal mask to ensure that attention is only applied to the left in the input sequence
            self.register_buffer("bias", torch.tril(torch.ones(config.block_size, config.block_size))
                                        .view(1, 1, config.block_size, config.block_size))

    def forward(self, x):
        B, T, C = x.size() # batch size, sequence length, embedding dimensionality (n_embd)

        # calculate query, key, values for all heads in batch and move head forward to be the batch dim
        q, k, v  = self.c_attn(x).split(self.n_embd, dim=2)
        k = k.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        q = q.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        v = v.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)

        # causal self-attention; Self-attend: (B, nh, T, hs) x (B, nh, hs, T) -> (B, nh, T, T)
        if self.flash:
            # efficient attention using Flash Attention CUDA kernels
            y = torch.nn.functional.scaled_dot_product_attention(q, k, v, attn_mask=None, dropout_p=self.dropout if self.training else 0, is_causal=True)
        else:
            # manual implementation of attention
            att = (q @ k.transpose(-2, -1)) * (1.0 / math.sqrt(k.size(-1)))
            att = att.masked_fill(self.bias[:,:,:T,:T] == 0, float('-inf'))
            att = F.softmax(att, dim=-1)
            att = self.attn_dropout(att)
            y = att @ v # (B, nh, T, T) x (B, nh, T, hs) -> (B, nh, T, hs)
        y = y.transpose(1, 2).contiguous().view(B, T, C) # re-assemble all head outputs side by side

        # output projection
        y = self.resid_dropout(self.c_proj(y))
        return y

class MLP(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.c_fc    = nn.Linear(config.n_embd, 4 * config.n_embd, bias=config.bias)
        self.gelu    = nn.GELU()
        self.c_proj  = nn.Linear(4 * config.n_embd, config.n_embd, bias=config.bias)
        self.dropout = nn.Dropout(config.dropout)

    def forward(self, x):
        x = self.c_fc(x)
        x = self.gelu(x)
        x = self.c_proj(x)
        x = self.dropout(x)
        return x

class Block(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.ln_1 = LayerNorm(config.n_embd, bias=config.bias)
        self.attn = CausalSelfAttention(config)
        self.ln_2 = LayerNorm(config.n_embd, bias=config.bias)
        self.mlp = MLP(config)

    def forward(self, x):
        x = x + self.attn(self.ln_1(x))
        x = x + self.mlp(self.ln_2(x))
        return x

@dataclass
class GPTConfig:
    block_size: int = 1024
    vocab_size: int = 50304 # GPT-2 vocab_size of 50257, padded up to nearest multiple of 64 for efficiency
    n_layer: int = 12
    n_head: int = 12
    n_embd: int = 768
    dropout: float = 0.0
    bias: bool = True # True: bias in Linears and LayerNorms, like GPT-2. False: a bit better and faster

class GPT(nn.Module):

    def __init__(self, config):
        super().__init__()
        assert config.vocab_size is not None
        assert config.block_size is not None
        self.config = config

        self.transformer = nn.ModuleDict(dict(
            wte = nn.Embedding(config.vocab_size, config.n_embd),
            wpe = nn.Embedding(config.block_size, config.n_embd),
            drop = nn.Dropout(config.dropout),
            h = nn.ModuleList([Block(config) for _ in range(config.n_layer)]),
            ln_f = LayerNorm(config.n_embd, bias=config.bias),
        ))
        self.lm_head = nn.Linear(config.n_embd, config.vocab_size, bias=False)
        # with weight tying when using torch.compile() some warnings get generated:
        # "UserWarning: functional_call was passed multiple values for tied weights.
        # This behavior is deprecated and will be an error in future versions"
        # not 100% sure what this is, so far seems to be harmless. TODO investigate
        self.transformer.wte.weight = self.lm_head.weight # https://paperswithcode.com/method/weight-tying

        # init all weights
        self.apply(self._init_weights)
        # apply special scaled init to the residual projections, per GPT-2 paper
        for pn, p in self.named_parameters():
            if pn.endswith('c_proj.weight'):
                torch.nn.init.normal_(p, mean=0.0, std=0.02/math.sqrt(2 * config.n_layer))

        # report number of parameters
        print("number of parameters: %.2fM" % (self.get_num_params()/1e6,))

    def get_num_params(self, non_embedding=True):
        """
        Return the number of parameters in the model.
        For non-embedding count (default), the position embeddings get subtracted.
        The token embeddings would too, except due to the parameter sharing these
        params are actually used as weights in the final layer, so we include them.
        """
        n_params = sum(p.numel() for p in self.parameters())
        if non_embedding:
            n_params -= self.transformer.wpe.weight.numel()
        return n_params

    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
            if module.bias is not None:
                torch.nn.init.zeros_(module.bias)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)

    def forward(self, idx, targets=None):
        device = idx.device
        b, t = idx.size()
        assert t <= self.config.block_size, f"Cannot forward sequence of length {t}, block size is only {self.config.block_size}"
        pos = torch.arange(0, t, dtype=torch.long, device=device) # shape (t)

        # forward the GPT model itself
        tok_emb = self.transformer.wte(idx) # token embeddings of shape (b, t, n_embd)
        pos_emb = self.transformer.wpe(pos) # position embeddings of shape (t, n_embd)
        x = self.transformer.drop(tok_emb + pos_emb)
        for block in self.transformer.h:
            x = block(x)
        x = self.transformer.ln_f(x)

        if targets is not None:
            # if we are given some desired targets also calculate the loss
            logits = self.lm_head(x)
            loss = F.cross_entropy(logits.view(-1, logits.size(-1)), targets.view(-1), ignore_index=-1)
        else:
            # inference-time mini-optimization: only forward the lm_head on the very last position
            logits = self.lm_head(x[:, [-1], :]) # note: using list [-1] to preserve the time dim
            loss = None

        return logits, loss

    def crop_block_size(self, block_size):
        # model surgery to decrease the block size if necessary
        # e.g. we may load the GPT2 pretrained model checkpoint (block size 1024)
        # but want to use a smaller block size for some smaller, simpler model
        assert block_size <= self.config.block_size
        self.config.block_size = block_size
        self.transformer.wpe.weight = nn.Parameter(self.transformer.wpe.weight[:block_size])
        for block in self.transformer.h:
            if hasattr(block.attn, 'bias'):
                block.attn.bias = block.attn.bias[:,:,:block_size,:block_size]

    @classmethod
    def from_pretrained(cls, model_type, override_args=None):
        assert model_type in {'gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'}
        override_args = override_args or {} # default to empty dict
        # only dropout can be overridden see more notes below
        assert all(k == 'dropout' for k in override_args)
        from transformers import GPT2LMHeadModel
        print("loading weights from pretrained gpt: %s" % model_type)

        # n_layer, n_head and n_embd are determined from model_type
        config_args = {
            'gpt2':         dict(n_layer=12, n_head=12, n_embd=768),  # 124M params
            'gpt2-medium':  dict(n_layer=24, n_head=16, n_embd=1024), # 350M params
            'gpt2-large':   dict(n_layer=36, n_head=20, n_embd=1280), # 774M params
            'gpt2-xl':      dict(n_layer=48, n_head=25, n_embd=1600), # 1558M params
        }[model_type]
        print("forcing vocab_size=50257, block_size=1024, bias=True")
        config_args['vocab_size'] = 50257 # always 50257 for GPT model checkpoints
        config_args['block_size'] = 1024 # always 1024 for GPT model checkpoints
        config_args['bias'] = True # always True for GPT model checkpoints
        # we can override the dropout rate, if desired
        if 'dropout' in override_args:
            print(f"overriding dropout rate to {override_args['dropout']}")
            config_args['dropout'] = override_args['dropout']
        # create a from-scratch initialized minGPT model
        config = GPTConfig(**config_args)
        model = GPT(config)
        sd = model.state_dict()
        sd_keys = sd.keys()
        sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param

        # init a huggingface/transformers model
        model_hf = GPT2LMHeadModel.from_pretrained(model_type)
        sd_hf = model_hf.state_dict()

        # copy while ensuring all of the parameters are aligned and match in names and shapes
        sd_keys_hf = sd_hf.keys()
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
        transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
        # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
        # this means that we have to transpose these weights when we import them
        assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
        for k in sd_keys_hf:
            if any(k.endswith(w) for w in transposed):
                # special treatment for the Conv1D weights we need to transpose
                assert sd_hf[k].shape[::-1] == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k].t())
            else:
                # vanilla copy over the other parameters
                assert sd_hf[k].shape == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k])

        return model

    def configure_optimizers(self, weight_decay, learning_rate, betas, device_type):
        # start with all of the candidate parameters
        param_dict = {pn: p for pn, p in self.named_parameters()}
        # filter out those that do not require grad
        param_dict = {pn: p for pn, p in param_dict.items() if p.requires_grad}
        # create optim groups. Any parameters that is 2D will be weight decayed, otherwise no.
        # i.e. all weight tensors in matmuls + embeddings decay, all biases and layernorms don't.
        decay_params = [p for n, p in param_dict.items() if p.dim() >= 2]
        nodecay_params = [p for n, p in param_dict.items() if p.dim() < 2]
        optim_groups = [
            {'params': decay_params, 'weight_decay': weight_decay},
            {'params': nodecay_params, 'weight_decay': 0.0}
        ]
        num_decay_params = sum(p.numel() for p in decay_params)
        num_nodecay_params = sum(p.numel() for p in nodecay_params)
        print(f"num decayed parameter tensors: {len(decay_params)}, with {num_decay_params:,} parameters")
        print(f"num non-decayed parameter tensors: {len(nodecay_params)}, with {num_nodecay_params:,} parameters")
        # Create AdamW optimizer and use the fused version if it is available
        fused_available = 'fused' in inspect.signature(torch.optim.AdamW).parameters
        use_fused = fused_available and device_type == 'cuda'
        extra_args = dict(fused=True) if use_fused else dict()
        optimizer = torch.optim.AdamW(optim_groups, lr=learning_rate, betas=betas, **extra_args)
        print(f"using fused AdamW: {use_fused}")

        return optimizer

    def estimate_mfu(self, fwdbwd_per_iter, dt):
        """ estimate model flops utilization (MFU) in units of A100 bfloat16 peak FLOPS """
        # first estimate the number of flops we do per iteration.
        # see PaLM paper Appendix B as ref: https://arxiv.org/abs/2204.02311
        N = self.get_num_params()
        cfg = self.config
        L, H, Q, T = cfg.n_layer, cfg.n_head, cfg.n_embd//cfg.n_head, cfg.block_size
        flops_per_token = 6*N + 12*L*H*Q*T
        flops_per_fwdbwd = flops_per_token * T
        flops_per_iter = flops_per_fwdbwd * fwdbwd_per_iter
        # express our flops throughput as ratio of A100 bfloat16 peak flops
        flops_achieved = flops_per_iter * (1.0/dt) # per second
        flops_promised = 312e12 # A100 GPU bfloat16 peak flops is 312 TFLOPS
        mfu = flops_achieved / flops_promised
        return mfu

    @torch.no_grad()
    def generate(self, idx, max_new_tokens, temperature=1.0, top_k=None):
        """
        Take a conditioning sequence of indices idx (LongTensor of shape (b,t)) and complete
        the sequence max_new_tokens times, feeding the predictions back into the model each time.
        Most likely you'll want to make sure to be in model.eval() mode of operation for this.
        """
        for _ in range(max_new_tokens):
            # if the sequence context is growing too long we must crop it at block_size
            idx_cond = idx if idx.size(1) <= self.config.block_size else idx[:, -self.config.block_size:]
            # forward the model to get the logits for the index in the sequence
            logits, _ = self(idx_cond)
            # pluck the logits at the final step and scale by desired temperature
            logits = logits[:, -1, :] / temperature
            # optionally crop the logits to only the top k options
            if top_k is not None:
                v, _ = torch.topk(logits, min(top_k, logits.size(-1)))
                logits[logits < v[:, [-1]]] = -float('Inf')
            # apply softmax to convert logits to (normalized) probabilities
            probs = F.softmax(logits, dim=-1)
            # sample from the distribution
            idx_next = torch.multinomial(probs, num_samples=1)
            # append sampled index to the running sequence and continue
            idx = torch.cat((idx, idx_next), dim=1)

        return idx



```

    The history saving thread hit an unexpected error (OperationalError('database or disk is full')).History will not be written to the database.
    

# parameter setting 


```python
# parameter setting 
# -----------------------------------------------------------------------------
init_from = 'gpt2' # either 'resume' (from an out_dir) or a gpt2 variant (e.g. 'gpt2-xl')
out_dir = 'out' # ignored if init_from is not 'resume'
start = "What is the answer to life, the universe, and everything?" # or "<|endoftext|>" or etc. Can also specify a file, use as: "FILE:prompt.txt"
num_samples = 5 # number of samples to draw
max_new_tokens = 100 # number of tokens generated in each sample
temperature = 0.8 # 1.0 = no change, < 1.0 = less random, > 1.0 = more random, in predictions
top_k = 200 # retain only the top_k most likely tokens, clamp others to have 0 probability
seed = 1337
device = 'cuda' # examples: 'cpu', 'cuda', 'cuda:0', 'cuda:1', etc.
dtype = 'bfloat16' if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else 'float16' # 'float32' or 'bfloat16' or 'float16'
compile = False # use PyTorch 2.0 to compile the model to be faster
# exec(open('configurator.py').read()) # overrides from command line or config file
# -----------------------------------------------------------------------------

```

# Device setting


```python
torch.manual_seed(seed)
torch.cuda.manual_seed(seed)
torch.backends.cuda.matmul.allow_tf32 = True # allow tf32 on matmul
torch.backends.cudnn.allow_tf32 = True # allow tf32 on cudnn
device_type = 'cuda' if 'cuda' in device else 'cpu' # for later use in torch.autocast
ptdtype = {'float32': torch.float32, 'bfloat16': torch.bfloat16, 'float16': torch.float16}[dtype]
ctx = nullcontext() if device_type == 'cpu' else torch.amp.autocast(device_type=device_type, dtype=ptdtype)
print(f"🖥️  Device type selected     : {device_type}")
print(f"📦  torch device name        : {torch.cuda.get_device_name() if device_type == 'cuda' else 'CPU'}")
print(f"🧠  Data type (ptdtype)      : {ptdtype}")
print(f"⚙️  Using autocast context   : {ctx.__class__.__name__}")
print(f"✅  TF32 matmul allowed       : {torch.backends.cuda.matmul.allow_tf32}")
print(f"✅  TF32 cudnn allowed        : {torch.backends.cudnn.allow_tf32}")
print(f"🔬  bfloat16 supported        : {torch.cuda.is_bf16_supported() if device_type == 'cuda' else 'N/A'}")
```

    🖥️  Device type selected     : cuda
    📦  torch device name        : NVIDIA T600 Laptop GPU
    🧠  Data type (ptdtype)      : torch.bfloat16
    ⚙️  Using autocast context   : autocast
    ✅  TF32 matmul allowed       : True
    ✅  TF32 cudnn allowed        : True
    🔬  bfloat16 supported        : True
    

# Model preset


```python
# model
if init_from == 'resume':
    # init from a model saved in a specific directory
    ckpt_path = os.path.join(out_dir, 'ckpt.pt')
    checkpoint = torch.load(ckpt_path, map_location=device)
    gptconf = GPTConfig(**checkpoint['model_args'])
    model = GPT(gptconf)
    state_dict = checkpoint['model']
    unwanted_prefix = '_orig_mod.'
    for k,v in list(state_dict.items()):
        if k.startswith(unwanted_prefix):
            state_dict[k[len(unwanted_prefix):]] = state_dict.pop(k)
    model.load_state_dict(state_dict)
elif init_from.startswith('gpt2'):
    # init from a given GPT-2 model
    model = GPT.from_pretrained(init_from, dict(dropout=0.0))

model.eval()
model.to(device)
if compile:
    model = torch.compile(model) # requires PyTorch 2.0 (optional)

# look for the meta pickle in case it is available in the dataset folder
load_meta = False
if init_from == 'resume' and 'config' in checkpoint and 'dataset' in checkpoint['config']: # older checkpoints might not have these...
    meta_path = os.path.join('data', checkpoint['config']['dataset'], 'meta.pkl')
    load_meta = os.path.exists(meta_path)
if load_meta:
    print(f"Loading meta from {meta_path}...")
    with open(meta_path, 'rb') as f:
        meta = pickle.load(f)
    # TODO want to make this more general to arbitrary encoder/decoder schemes
    stoi, itos = meta['stoi'], meta['itos']
    encode = lambda s: [stoi[c] for c in s]
    decode = lambda l: ''.join([itos[i] for i in l])
else:
    # ok let's assume gpt-2 encodings by default
    print("No meta.pkl found, assuming GPT-2 encodings...")
    enc = tiktoken.get_encoding("gpt2")
    encode = lambda s: enc.encode(s, allowed_special={"<|endoftext|>"})
    decode = lambda l: enc.decode(l)

# encode the beginning of the prompt
if start.startswith('FILE:'):
    with open(start[5:], 'r', encoding='utf-8') as f:
        start = f.read()
start_ids = encode(start)
x = (torch.tensor(start_ids, dtype=torch.long, device=device)[None, ...])
```

    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    No meta.pkl found, assuming GPT-2 encodings...
    

# Runing and Benchmarking again!
**python sample.py --init_from=gpt2 --start="What is the answer to life, the universe, and everything?" --num_samples=5 --max_new_tokens=100**
 
The initial benchmark below will serve as a baseline for future comparisons with my optimized hardware. Specifically, I run 5 inference samples using the same input and average their output times to establish my baseline benchmarking result.


```python
import time

# run generation and benchmark
with torch.no_grad():
    with ctx:
        start_time = time.time()

        for k in range(num_samples):
            gen_start = time.time()
            y = model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
            gen_end = time.time()

            gen_time = gen_end - gen_start
            print(f"⏱️ Sample {k+1} | Time: {gen_time:.3f}s | {max_new_tokens} tokens | {gen_time / max_new_tokens * 1000:.2f} ms/token")
            print(decode(y[0].tolist()))
            print('---------------')

        end_time = time.time()
        total_time = end_time - start_time
        avg_time_per_token = total_time / (num_samples * max_new_tokens)

        print(f"\n✅ Benchmark Summary:")
        print(f"Total time: {total_time:.3f} seconds")
        print(f"Average per sample: {total_time / num_samples:.3f} seconds")
        print(f"Average per token: {avg_time_per_token * 1000:.2f} ms/token")
        print(f"Tokens per second: {1.0 / avg_time_per_token:.2f} tokens/s")
```

    ⏱️ Sample 1 | Time: 4.797s | 100 tokens | 47.97 ms/token
    What is the answer to life, the universe, and everything?
    
    In the beginning God created everything.
    
    At its creation he created and ruled over the elements and the elements were governed by Him. He made life, His creation, and His destiny. He made the world, the universe, and the universe was governed by Him. And the law was applied. The scientists and philosophers were guided, the wise men guided, and the arts guided. God is the law…and the law of the world is the laws of the world.
    
    Thus
    ---------------
    ⏱️ Sample 2 | Time: 1.845s | 100 tokens | 18.45 ms/token
    What is the answer to life, the universe, and everything?
    
    In the previous post, I argued that the answer is now, for more than two decades, an obvious one. To simplify the arguments, I want to offer a direct response to the claim that there are no answers to the basic question of existence. I've been arguing for a long time that there are no answers to the basic question of existence, and I've always felt that these answers are not consistent with an argument that is consistent with what is logically consistent with the whole universe. I
    ---------------
    ⏱️ Sample 3 | Time: 1.814s | 100 tokens | 18.14 ms/token
    What is the answer to life, the universe, and everything? Many of us think we know? But when we consider why we evolved from the laws of nature, we quickly realize how deeply intertwined we have become. This series presents questions about the nature of nature, the nature of an infinite universe, and the ontology of natural philosophy.
    
    The Philosophy of Life
    
    As the reader has probably guessed, Einstein's theory of relativity is a quite old idea. The theory was intended as an explanation for the existence of life in an infinite universe. It had
    ---------------
    ⏱️ Sample 4 | Time: 1.837s | 100 tokens | 18.37 ms/token
    What is the answer to life, the universe, and everything? Why do we suffer in this world; why are we led to sin? Why do we fall in sin? Why do we die in this world? Why do we fail to live in this world? Why do we go to hell? Why do we die in this world? Why do we lack a grasp of the Gospel? Why are we in a lie? The Unbearable Difficulty: With no explanation, no encouragement, no comfort, no freedom, no relief, no salvation, no joy,
    ---------------
    ⏱️ Sample 5 | Time: 1.807s | 100 tokens | 18.07 ms/token
    What is the answer to life, the universe, and everything?
    
    The answer to life begins with a basic belief: the universe is not.
    
    Consider it as a singularity: we built the universe around an infinite number of interconnected stars. These stars are billions of light years from us. For their billions of stars, we have the ability to perform the basic mathematical functions that are essential for a universe. For example, our planet Saturn has an internal gravitational field that is equal to the distance from Sun to Earth. Thus, our universe looks like a
    ---------------
    
    ✅ Benchmark Summary:
    Total time: 12.162 seconds
    Average per sample: 2.432 seconds
    Average per token: 24.32 ms/token
    Tokens per second: 41.11 tokens/s
    

# Analyze the algorithm!

Recall from previous challenge python Bytecode anaysis process, I decide to follow again to analyze our code using good tools

First I wrap above code into a single whole python file and compile it as bytecode to do more analysis.



```python
import py_compile

py_compile.compile("Code Analysis/gpt2sample.py")
```




    'Code Analysis\\__pycache__\\gpt2sample.cpython-310.pyc'




```python
import dis
import marshal

with open('Code Analysis/__pycache__/gpt2sample.cpython-310.pyc', 'rb') as f:

    f.read(16)  # skip the .pyc header (magic number, timestamp, etc.)
    code = marshal.load(f)

dis.dis(code)
```

      1           0 LOAD_CONST               0 ('\nFull definition of a GPT Language Model, all of it in this single file.\nReferences:\n1) the official GPT-2 TensorFlow implementation released by OpenAI:\nhttps://github.com/openai/gpt-2/blob/master/src/model.py\n2) huggingface/transformers PyTorch implementation:\nhttps://github.com/huggingface/transformers/blob/main/src/transformers/models/gpt2/modeling_gpt2.py\n')
                  2 STORE_NAME               0 (__doc__)
    
     10           4 LOAD_CONST               1 (0)
                  6 LOAD_CONST               2 (None)
                  8 IMPORT_NAME              1 (math)
                 10 STORE_NAME               1 (math)
    
     11          12 LOAD_CONST               1 (0)
                 14 LOAD_CONST               2 (None)
                 16 IMPORT_NAME              2 (inspect)
                 18 STORE_NAME               2 (inspect)
    
     12          20 LOAD_CONST               1 (0)
                 22 LOAD_CONST               3 (('dataclass',))
                 24 IMPORT_NAME              3 (dataclasses)
                 26 IMPORT_FROM              4 (dataclass)
                 28 STORE_NAME               4 (dataclass)
                 30 POP_TOP
    
     14          32 LOAD_CONST               1 (0)
                 34 LOAD_CONST               2 (None)
                 36 IMPORT_NAME              5 (torch)
                 38 STORE_NAME               5 (torch)
    
     15          40 LOAD_CONST               1 (0)
                 42 LOAD_CONST               2 (None)
                 44 IMPORT_NAME              6 (torch.nn)
                 46 IMPORT_FROM              7 (nn)
                 48 STORE_NAME               7 (nn)
                 50 POP_TOP
    
     16          52 LOAD_CONST               1 (0)
                 54 LOAD_CONST               4 (('functional',))
                 56 IMPORT_NAME              6 (torch.nn)
                 58 IMPORT_FROM              8 (functional)
                 60 STORE_NAME               9 (F)
                 62 POP_TOP
    
     18          64 LOAD_BUILD_CLASS
                 66 LOAD_CONST               5 (<code object LayerNorm at 0x000002159E130C90, file "Code Analysis/gpt2sample.py", line 18>)
                 68 LOAD_CONST               6 ('LayerNorm')
                 70 MAKE_FUNCTION            0
                 72 LOAD_CONST               6 ('LayerNorm')
                 74 LOAD_NAME                7 (nn)
                 76 LOAD_ATTR               10 (Module)
                 78 CALL_FUNCTION            3
                 80 STORE_NAME              11 (LayerNorm)
    
     29          82 LOAD_BUILD_CLASS
                 84 LOAD_CONST               7 (<code object CausalSelfAttention at 0x000002159E130EA0, file "Code Analysis/gpt2sample.py", line 29>)
                 86 LOAD_CONST               8 ('CausalSelfAttention')
                 88 MAKE_FUNCTION            0
                 90 LOAD_CONST               8 ('CausalSelfAttention')
                 92 LOAD_NAME                7 (nn)
                 94 LOAD_ATTR               10 (Module)
                 96 CALL_FUNCTION            3
                 98 STORE_NAME              12 (CausalSelfAttention)
    
     78         100 LOAD_BUILD_CLASS
                102 LOAD_CONST               9 (<code object MLP at 0x000002159E1310B0, file "Code Analysis/gpt2sample.py", line 78>)
                104 LOAD_CONST              10 ('MLP')
                106 MAKE_FUNCTION            0
                108 LOAD_CONST              10 ('MLP')
                110 LOAD_NAME                7 (nn)
                112 LOAD_ATTR               10 (Module)
                114 CALL_FUNCTION            3
                116 STORE_NAME              13 (MLP)
    
     94         118 LOAD_BUILD_CLASS
                120 LOAD_CONST              11 (<code object Block at 0x000002159E1312C0, file "Code Analysis/gpt2sample.py", line 94>)
                122 LOAD_CONST              12 ('Block')
                124 MAKE_FUNCTION            0
                126 LOAD_CONST              12 ('Block')
                128 LOAD_NAME                7 (nn)
                130 LOAD_ATTR               10 (Module)
                132 CALL_FUNCTION            3
                134 STORE_NAME              14 (Block)
    
    108         136 LOAD_NAME                4 (dataclass)
    
    109         138 LOAD_BUILD_CLASS
                140 LOAD_CONST              13 (<code object GPTConfig at 0x000002159E131370, file "Code Analysis/gpt2sample.py", line 108>)
                142 LOAD_CONST              14 ('GPTConfig')
                144 MAKE_FUNCTION            0
                146 LOAD_CONST              14 ('GPTConfig')
                148 CALL_FUNCTION            2
                150 CALL_FUNCTION            1
                152 STORE_NAME              15 (GPTConfig)
    
    118         154 LOAD_BUILD_CLASS
                156 LOAD_CONST              15 (<code object GPT at 0x000002159E132340, file "Code Analysis/gpt2sample.py", line 118>)
                158 LOAD_CONST              16 ('GPT')
                160 MAKE_FUNCTION            0
                162 LOAD_CONST              16 ('GPT')
                164 LOAD_NAME                7 (nn)
                166 LOAD_ATTR               10 (Module)
                168 CALL_FUNCTION            3
                170 STORE_NAME              16 (GPT)
    
    334         172 LOAD_CONST              17 ('gpt2')
                174 STORE_NAME              17 (init_from)
    
    335         176 LOAD_CONST              18 ('out')
                178 STORE_NAME              18 (out_dir)
    
    336         180 LOAD_CONST              19 ('What is the answer to life, the universe, and everything?')
                182 STORE_NAME              19 (start)
    
    337         184 LOAD_CONST              20 (5)
                186 STORE_NAME              20 (num_samples)
    
    338         188 LOAD_CONST              21 (100)
                190 STORE_NAME              21 (max_new_tokens)
    
    339         192 LOAD_CONST              22 (0.8)
                194 STORE_NAME              22 (temperature)
    
    340         196 LOAD_CONST              23 (200)
                198 STORE_NAME              23 (top_k)
    
    341         200 LOAD_CONST              24 (1337)
                202 STORE_NAME              24 (seed)
    
    342         204 LOAD_CONST              25 ('cuda')
                206 STORE_NAME              25 (device)
    
    343         208 LOAD_NAME                5 (torch)
                210 LOAD_ATTR               26 (cuda)
                212 LOAD_METHOD             27 (is_available)
                214 CALL_METHOD              0
                216 POP_JUMP_IF_FALSE      116 (to 232)
                218 LOAD_NAME                5 (torch)
                220 LOAD_ATTR               26 (cuda)
                222 LOAD_METHOD             28 (is_bf16_supported)
                224 CALL_METHOD              0
                226 POP_JUMP_IF_FALSE      116 (to 232)
                228 LOAD_CONST              26 ('bfloat16')
                230 JUMP_FORWARD             1 (to 234)
            >>  232 LOAD_CONST              27 ('float16')
            >>  234 STORE_NAME              29 (dtype)
    
    344         236 LOAD_CONST              28 (False)
                238 STORE_NAME              30 (compile)
    
    348         240 LOAD_NAME                5 (torch)
                242 LOAD_METHOD             31 (manual_seed)
                244 LOAD_NAME               24 (seed)
                246 CALL_METHOD              1
                248 POP_TOP
    
    349         250 LOAD_NAME                5 (torch)
                252 LOAD_ATTR               26 (cuda)
                254 LOAD_METHOD             31 (manual_seed)
                256 LOAD_NAME               24 (seed)
                258 CALL_METHOD              1
                260 POP_TOP
    
    350         262 LOAD_CONST              29 (True)
                264 LOAD_NAME                5 (torch)
                266 LOAD_ATTR               32 (backends)
                268 LOAD_ATTR               26 (cuda)
                270 LOAD_ATTR               33 (matmul)
                272 STORE_ATTR              34 (allow_tf32)
    
    351         274 LOAD_CONST              29 (True)
                276 LOAD_NAME                5 (torch)
                278 LOAD_ATTR               32 (backends)
                280 LOAD_ATTR               35 (cudnn)
                282 STORE_ATTR              34 (allow_tf32)
    
    352         284 LOAD_CONST              25 ('cuda')
                286 LOAD_NAME               25 (device)
                288 CONTAINS_OP              0
                290 POP_JUMP_IF_FALSE      148 (to 296)
                292 LOAD_CONST              25 ('cuda')
                294 JUMP_FORWARD             1 (to 298)
            >>  296 LOAD_CONST              30 ('cpu')
            >>  298 STORE_NAME              36 (device_type)
    
    353         300 LOAD_NAME                5 (torch)
                302 LOAD_ATTR               37 (float32)
                304 LOAD_NAME                5 (torch)
                306 LOAD_ATTR               38 (bfloat16)
                308 LOAD_NAME                5 (torch)
                310 LOAD_ATTR               39 (float16)
                312 LOAD_CONST              31 (('float32', 'bfloat16', 'float16'))
                314 BUILD_CONST_KEY_MAP      3
                316 LOAD_NAME               29 (dtype)
                318 BINARY_SUBSCR
                320 STORE_NAME              40 (ptdtype)
    
    354         322 LOAD_NAME               36 (device_type)
                324 LOAD_CONST              30 ('cpu')
                326 COMPARE_OP               2 (==)
                328 POP_JUMP_IF_FALSE      168 (to 336)
                330 LOAD_NAME               41 (nullcontext)
                332 CALL_FUNCTION            0
                334 JUMP_FORWARD             7 (to 350)
            >>  336 LOAD_NAME                5 (torch)
                338 LOAD_ATTR               42 (amp)
                340 LOAD_ATTR               43 (autocast)
                342 LOAD_NAME               36 (device_type)
                344 LOAD_NAME               40 (ptdtype)
                346 LOAD_CONST              32 (('device_type', 'dtype'))
                348 CALL_FUNCTION_KW         2
            >>  350 STORE_NAME              44 (ctx)
    
    357         352 LOAD_NAME               17 (init_from)
                354 LOAD_CONST              33 ('resume')
                356 COMPARE_OP               2 (==)
                358 POP_JUMP_IF_FALSE      248 (to 496)
    
    359         360 LOAD_NAME               45 (os)
                362 LOAD_ATTR               46 (path)
                364 LOAD_METHOD             47 (join)
                366 LOAD_NAME               18 (out_dir)
                368 LOAD_CONST              34 ('ckpt.pt')
                370 CALL_METHOD              2
                372 STORE_NAME              48 (ckpt_path)
    
    360         374 LOAD_NAME                5 (torch)
                376 LOAD_ATTR               49 (load)
                378 LOAD_NAME               48 (ckpt_path)
                380 LOAD_NAME               25 (device)
                382 LOAD_CONST              35 (('map_location',))
                384 CALL_FUNCTION_KW         2
                386 STORE_NAME              50 (checkpoint)
    
    361         388 LOAD_NAME               15 (GPTConfig)
                390 LOAD_CONST              63 (())
                392 BUILD_MAP                0
                394 LOAD_NAME               50 (checkpoint)
                396 LOAD_CONST              36 ('model_args')
                398 BINARY_SUBSCR
                400 DICT_MERGE               1
                402 CALL_FUNCTION_EX         1
                404 STORE_NAME              51 (gptconf)
    
    362         406 LOAD_NAME               16 (GPT)
                408 LOAD_NAME               51 (gptconf)
                410 CALL_FUNCTION            1
                412 STORE_NAME              52 (model)
    
    363         414 LOAD_NAME               50 (checkpoint)
                416 LOAD_CONST              37 ('model')
                418 BINARY_SUBSCR
                420 STORE_NAME              53 (state_dict)
    
    364         422 LOAD_CONST              38 ('_orig_mod.')
                424 STORE_NAME              54 (unwanted_prefix)
    
    365         426 LOAD_NAME               55 (list)
                428 LOAD_NAME               53 (state_dict)
                430 LOAD_METHOD             56 (items)
                432 CALL_METHOD              0
                434 CALL_FUNCTION            1
                436 GET_ITER
            >>  438 FOR_ITER                22 (to 484)
                440 UNPACK_SEQUENCE          2
                442 STORE_NAME              57 (k)
                444 STORE_NAME              58 (v)
    
    366         446 LOAD_NAME               57 (k)
                448 LOAD_METHOD             59 (startswith)
                450 LOAD_NAME               54 (unwanted_prefix)
                452 CALL_METHOD              1
                454 POP_JUMP_IF_FALSE      241 (to 482)
    
    367         456 LOAD_NAME               53 (state_dict)
                458 LOAD_METHOD             60 (pop)
                460 LOAD_NAME               57 (k)
                462 CALL_METHOD              1
                464 LOAD_NAME               53 (state_dict)
                466 LOAD_NAME               57 (k)
                468 LOAD_NAME               61 (len)
                470 LOAD_NAME               54 (unwanted_prefix)
                472 CALL_FUNCTION            1
                474 LOAD_CONST               2 (None)
                476 BUILD_SLICE              2
                478 BINARY_SUBSCR
                480 STORE_SUBSCR
            >>  482 JUMP_ABSOLUTE          219 (to 438)
    
    368     >>  484 LOAD_NAME               52 (model)
                486 LOAD_METHOD             62 (load_state_dict)
                488 LOAD_NAME               53 (state_dict)
                490 CALL_METHOD              1
                492 POP_TOP
                494 JUMP_FORWARD            15 (to 526)
    
    369     >>  496 LOAD_NAME               17 (init_from)
                498 LOAD_METHOD             59 (startswith)
                500 LOAD_CONST              17 ('gpt2')
                502 CALL_METHOD              1
                504 EXTENDED_ARG             1
                506 POP_JUMP_IF_FALSE      263 (to 526)
    
    371         508 LOAD_NAME               16 (GPT)
                510 LOAD_METHOD             63 (from_pretrained)
                512 LOAD_NAME               17 (init_from)
                514 LOAD_NAME               64 (dict)
                516 LOAD_CONST              39 (0.0)
                518 LOAD_CONST              40 (('dropout',))
                520 CALL_FUNCTION_KW         1
                522 CALL_METHOD              2
                524 STORE_NAME              52 (model)
    
    373     >>  526 LOAD_NAME               52 (model)
                528 LOAD_METHOD             65 (eval)
                530 CALL_METHOD              0
                532 POP_TOP
    
    374         534 LOAD_NAME               52 (model)
                536 LOAD_METHOD             66 (to)
                538 LOAD_NAME               25 (device)
                540 CALL_METHOD              1
                542 POP_TOP
    
    375         544 LOAD_NAME               30 (compile)
                546 EXTENDED_ARG             1
                548 POP_JUMP_IF_FALSE      280 (to 560)
    
    376         550 LOAD_NAME                5 (torch)
                552 LOAD_METHOD             30 (compile)
                554 LOAD_NAME               52 (model)
                556 CALL_METHOD              1
                558 STORE_NAME              52 (model)
    
    379     >>  560 LOAD_CONST              28 (False)
                562 STORE_NAME              67 (load_meta)
    
    380         564 LOAD_NAME               17 (init_from)
                566 LOAD_CONST              33 ('resume')
                568 COMPARE_OP               2 (==)
                570 EXTENDED_ARG             1
                572 POP_JUMP_IF_FALSE      317 (to 634)
                574 LOAD_CONST              41 ('config')
                576 LOAD_NAME               50 (checkpoint)
                578 CONTAINS_OP              0
                580 EXTENDED_ARG             1
                582 POP_JUMP_IF_FALSE      317 (to 634)
                584 LOAD_CONST              42 ('dataset')
                586 LOAD_NAME               50 (checkpoint)
                588 LOAD_CONST              41 ('config')
                590 BINARY_SUBSCR
                592 CONTAINS_OP              0
                594 EXTENDED_ARG             1
                596 POP_JUMP_IF_FALSE      317 (to 634)
    
    381         598 LOAD_NAME               45 (os)
                600 LOAD_ATTR               46 (path)
                602 LOAD_METHOD             47 (join)
                604 LOAD_CONST              43 ('data')
                606 LOAD_NAME               50 (checkpoint)
                608 LOAD_CONST              41 ('config')
                610 BINARY_SUBSCR
                612 LOAD_CONST              42 ('dataset')
                614 BINARY_SUBSCR
                616 LOAD_CONST              44 ('meta.pkl')
                618 CALL_METHOD              3
                620 STORE_NAME              68 (meta_path)
    
    382         622 LOAD_NAME               45 (os)
                624 LOAD_ATTR               46 (path)
                626 LOAD_METHOD             69 (exists)
                628 LOAD_NAME               68 (meta_path)
                630 CALL_METHOD              1
                632 STORE_NAME              67 (load_meta)
    
    383     >>  634 LOAD_NAME               67 (load_meta)
                636 EXTENDED_ARG             1
                638 POP_JUMP_IF_FALSE      373 (to 746)
    
    384         640 LOAD_NAME               70 (print)
                642 LOAD_CONST              45 ('Loading meta from ')
                644 LOAD_NAME               68 (meta_path)
                646 FORMAT_VALUE             0
                648 LOAD_CONST              46 ('...')
                650 BUILD_STRING             3
                652 CALL_FUNCTION            1
                654 POP_TOP
    
    385         656 LOAD_NAME               71 (open)
                658 LOAD_NAME               68 (meta_path)
                660 LOAD_CONST              47 ('rb')
                662 CALL_FUNCTION            2
                664 SETUP_WITH              13 (to 692)
                666 STORE_NAME              72 (f)
    
    386         668 LOAD_NAME               73 (pickle)
                670 LOAD_METHOD             49 (load)
                672 LOAD_NAME               72 (f)
                674 CALL_METHOD              1
                676 STORE_NAME              74 (meta)
                678 POP_BLOCK
    
    385         680 LOAD_CONST               2 (None)
                682 DUP_TOP
                684 DUP_TOP
                686 CALL_FUNCTION            3
                688 POP_TOP
                690 JUMP_FORWARD             9 (to 710)
            >>  692 WITH_EXCEPT_START
                694 EXTENDED_ARG             1
                696 POP_JUMP_IF_TRUE       350 (to 700)
                698 RERAISE                  1
            >>  700 POP_TOP
                702 POP_TOP
                704 POP_TOP
                706 POP_EXCEPT
                708 POP_TOP
    
    388     >>  710 LOAD_NAME               74 (meta)
                712 LOAD_CONST              48 ('stoi')
                714 BINARY_SUBSCR
                716 LOAD_NAME               74 (meta)
                718 LOAD_CONST              49 ('itos')
                720 BINARY_SUBSCR
                722 ROT_TWO
                724 STORE_NAME              75 (stoi)
                726 STORE_NAME              76 (itos)
    
    389         728 LOAD_CONST              50 (<code object <lambda> at 0x000002159E1324A0, file "Code Analysis/gpt2sample.py", line 389>)
                730 LOAD_CONST              51 ('<lambda>')
                732 MAKE_FUNCTION            0
                734 STORE_NAME              77 (encode)
    
    390         736 LOAD_CONST              52 (<code object <lambda> at 0x000002159E132600, file "Code Analysis/gpt2sample.py", line 390>)
                738 LOAD_CONST              51 ('<lambda>')
                740 MAKE_FUNCTION            0
                742 STORE_NAME              78 (decode)
                744 JUMP_FORWARD            17 (to 780)
    
    393     >>  746 LOAD_NAME               70 (print)
                748 LOAD_CONST              53 ('No meta.pkl found, assuming GPT-2 encodings...')
                750 CALL_FUNCTION            1
                752 POP_TOP
    
    394         754 LOAD_NAME               79 (tiktoken)
                756 LOAD_METHOD             80 (get_encoding)
                758 LOAD_CONST              17 ('gpt2')
                760 CALL_METHOD              1
                762 STORE_NAME              81 (enc)
    
    395         764 LOAD_CONST              54 (<code object <lambda> at 0x000002159E1326B0, file "Code Analysis/gpt2sample.py", line 395>)
                766 LOAD_CONST              51 ('<lambda>')
                768 MAKE_FUNCTION            0
                770 STORE_NAME              77 (encode)
    
    396         772 LOAD_CONST              55 (<code object <lambda> at 0x000002159E132760, file "Code Analysis/gpt2sample.py", line 396>)
                774 LOAD_CONST              51 ('<lambda>')
                776 MAKE_FUNCTION            0
                778 STORE_NAME              78 (decode)
    
    399     >>  780 LOAD_NAME               19 (start)
                782 LOAD_METHOD             59 (startswith)
                784 LOAD_CONST              56 ('FILE:')
                786 CALL_METHOD              1
                788 EXTENDED_ARG             1
                790 POP_JUMP_IF_FALSE      428 (to 856)
    
    400         792 LOAD_NAME               71 (open)
                794 LOAD_NAME               19 (start)
                796 LOAD_CONST              20 (5)
                798 LOAD_CONST               2 (None)
                800 BUILD_SLICE              2
                802 BINARY_SUBSCR
                804 LOAD_CONST              57 ('r')
                806 LOAD_CONST              58 ('utf-8')
                808 LOAD_CONST              59 (('encoding',))
                810 CALL_FUNCTION_KW         3
                812 SETUP_WITH              12 (to 838)
                814 STORE_NAME              72 (f)
    
    401         816 LOAD_NAME               72 (f)
                818 LOAD_METHOD             82 (read)
                820 CALL_METHOD              0
                822 STORE_NAME              19 (start)
                824 POP_BLOCK
    
    400         826 LOAD_CONST               2 (None)
                828 DUP_TOP
                830 DUP_TOP
                832 CALL_FUNCTION            3
                834 POP_TOP
                836 JUMP_FORWARD             9 (to 856)
            >>  838 WITH_EXCEPT_START
                840 EXTENDED_ARG             1
                842 POP_JUMP_IF_TRUE       423 (to 846)
                844 RERAISE                  1
            >>  846 POP_TOP
                848 POP_TOP
                850 POP_TOP
                852 POP_EXCEPT
                854 POP_TOP
    
    402     >>  856 LOAD_NAME               77 (encode)
                858 LOAD_NAME               19 (start)
                860 CALL_FUNCTION            1
                862 STORE_NAME              83 (start_ids)
    
    403         864 LOAD_NAME                5 (torch)
                866 LOAD_ATTR               84 (tensor)
                868 LOAD_NAME               83 (start_ids)
                870 LOAD_NAME                5 (torch)
                872 LOAD_ATTR               85 (long)
                874 LOAD_NAME               25 (device)
                876 LOAD_CONST              60 (('dtype', 'device'))
                878 CALL_FUNCTION_KW         3
                880 LOAD_CONST              61 ((None, Ellipsis))
                882 BINARY_SUBSCR
                884 STORE_NAME              86 (x)
    
    405         886 LOAD_CONST               1 (0)
                888 LOAD_CONST               2 (None)
                890 IMPORT_NAME             87 (time)
                892 STORE_NAME              87 (time)
    
    408         894 LOAD_NAME                5 (torch)
                896 LOAD_METHOD             88 (no_grad)
                898 CALL_METHOD              0
                900 SETUP_WITH              53 (to 1008)
                902 POP_TOP
    
    409         904 LOAD_NAME               44 (ctx)
                906 SETUP_WITH              25 (to 958)
                908 POP_TOP
    
    410         910 LOAD_NAME               89 (range)
                912 LOAD_NAME               20 (num_samples)
                914 CALL_FUNCTION            1
                916 GET_ITER
            >>  918 FOR_ITER                12 (to 944)
                920 STORE_NAME              57 (k)
    
    411         922 LOAD_NAME               52 (model)
                924 LOAD_ATTR               90 (generate)
                926 LOAD_NAME               86 (x)
                928 LOAD_NAME               21 (max_new_tokens)
                930 LOAD_NAME               22 (temperature)
                932 LOAD_NAME               23 (top_k)
                934 LOAD_CONST              62 (('temperature', 'top_k'))
                936 CALL_FUNCTION_KW         4
                938 STORE_NAME              91 (y)
                940 EXTENDED_ARG             1
                942 JUMP_ABSOLUTE          459 (to 918)
    
    410     >>  944 POP_BLOCK
    
    409         946 LOAD_CONST               2 (None)
                948 DUP_TOP
                950 DUP_TOP
                952 CALL_FUNCTION            3
                954 POP_TOP
                956 JUMP_FORWARD            17 (to 992)
            >>  958 WITH_EXCEPT_START
                960 EXTENDED_ARG             1
                962 POP_JUMP_IF_TRUE       483 (to 966)
                964 RERAISE                  1
            >>  966 POP_TOP
                968 POP_TOP
                970 POP_TOP
                972 POP_EXCEPT
                974 POP_TOP
                976 POP_BLOCK
    
    408         978 LOAD_CONST               2 (None)
                980 DUP_TOP
                982 DUP_TOP
                984 CALL_FUNCTION            3
                986 POP_TOP
                988 LOAD_CONST               2 (None)
                990 RETURN_VALUE
    
    409     >>  992 POP_BLOCK
    
    408         994 LOAD_CONST               2 (None)
                996 DUP_TOP
                998 DUP_TOP
               1000 CALL_FUNCTION            3
               1002 POP_TOP
               1004 LOAD_CONST               2 (None)
               1006 RETURN_VALUE
            >> 1008 WITH_EXCEPT_START
               1010 EXTENDED_ARG             1
               1012 POP_JUMP_IF_TRUE       508 (to 1016)
               1014 RERAISE                  1
            >> 1016 POP_TOP
               1018 POP_TOP
               1020 POP_TOP
               1022 POP_EXCEPT
               1024 POP_TOP
               1026 LOAD_CONST               2 (None)
               1028 RETURN_VALUE
    
    Disassembly of <code object LayerNorm at 0x000002159E130C90, file "Code Analysis/gpt2sample.py", line 18>:
     18           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('LayerNorm')
                  6 STORE_NAME               2 (__qualname__)
    
     19           8 LOAD_CONST               1 (" LayerNorm but with an optional bias. PyTorch doesn't support simply bias=False ")
                 10 STORE_NAME               3 (__doc__)
    
     21          12 LOAD_CLOSURE             0 (__class__)
                 14 BUILD_TUPLE              1
                 16 LOAD_CONST               2 (<code object __init__ at 0x000002159E130190, file "Code Analysis/gpt2sample.py", line 21>)
                 18 LOAD_CONST               3 ('LayerNorm.__init__')
                 20 MAKE_FUNCTION            8 (closure)
                 22 STORE_NAME               4 (__init__)
    
     26          24 LOAD_CONST               4 (<code object forward at 0x000002159E1307C0, file "Code Analysis/gpt2sample.py", line 26>)
                 26 LOAD_CONST               5 ('LayerNorm.forward')
                 28 MAKE_FUNCTION            0
                 30 STORE_NAME               5 (forward)
                 32 LOAD_CLOSURE             0 (__class__)
                 34 DUP_TOP
                 36 STORE_NAME               6 (__classcell__)
                 38 RETURN_VALUE
    
    Disassembly of <code object __init__ at 0x000002159E130190, file "Code Analysis/gpt2sample.py", line 21>:
     22           0 LOAD_GLOBAL              0 (super)
                  2 CALL_FUNCTION            0
                  4 LOAD_METHOD              1 (__init__)
                  6 CALL_METHOD              0
                  8 POP_TOP
    
     23          10 LOAD_GLOBAL              2 (nn)
                 12 LOAD_METHOD              3 (Parameter)
                 14 LOAD_GLOBAL              4 (torch)
                 16 LOAD_METHOD              5 (ones)
                 18 LOAD_FAST                1 (ndim)
                 20 CALL_METHOD              1
                 22 CALL_METHOD              1
                 24 LOAD_FAST                0 (self)
                 26 STORE_ATTR               6 (weight)
    
     24          28 LOAD_FAST                2 (bias)
                 30 POP_JUMP_IF_FALSE       27 (to 54)
                 32 LOAD_GLOBAL              2 (nn)
                 34 LOAD_METHOD              3 (Parameter)
                 36 LOAD_GLOBAL              4 (torch)
                 38 LOAD_METHOD              7 (zeros)
                 40 LOAD_FAST                1 (ndim)
                 42 CALL_METHOD              1
                 44 CALL_METHOD              1
                 46 LOAD_FAST                0 (self)
                 48 STORE_ATTR               8 (bias)
                 50 LOAD_CONST               0 (None)
                 52 RETURN_VALUE
            >>   54 LOAD_CONST               0 (None)
                 56 LOAD_FAST                0 (self)
                 58 STORE_ATTR               8 (bias)
                 60 LOAD_CONST               0 (None)
                 62 RETURN_VALUE
    
    Disassembly of <code object forward at 0x000002159E1307C0, file "Code Analysis/gpt2sample.py", line 26>:
     27           0 LOAD_GLOBAL              0 (F)
                  2 LOAD_METHOD              1 (layer_norm)
                  4 LOAD_FAST                1 (input)
                  6 LOAD_FAST                0 (self)
                  8 LOAD_ATTR                2 (weight)
                 10 LOAD_ATTR                3 (shape)
                 12 LOAD_FAST                0 (self)
                 14 LOAD_ATTR                2 (weight)
                 16 LOAD_FAST                0 (self)
                 18 LOAD_ATTR                4 (bias)
                 20 LOAD_CONST               1 (1e-05)
                 22 CALL_METHOD              5
                 24 RETURN_VALUE
    
    Disassembly of <code object CausalSelfAttention at 0x000002159E130EA0, file "Code Analysis/gpt2sample.py", line 29>:
     29           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('CausalSelfAttention')
                  6 STORE_NAME               2 (__qualname__)
    
     31           8 LOAD_CLOSURE             0 (__class__)
                 10 BUILD_TUPLE              1
                 12 LOAD_CONST               1 (<code object __init__ at 0x000002159E130D40, file "Code Analysis/gpt2sample.py", line 31>)
                 14 LOAD_CONST               2 ('CausalSelfAttention.__init__')
                 16 MAKE_FUNCTION            8 (closure)
                 18 STORE_NAME               3 (__init__)
    
     52          20 LOAD_CONST               3 (<code object forward at 0x000002159E130DF0, file "Code Analysis/gpt2sample.py", line 52>)
                 22 LOAD_CONST               4 ('CausalSelfAttention.forward')
                 24 MAKE_FUNCTION            0
                 26 STORE_NAME               4 (forward)
                 28 LOAD_CLOSURE             0 (__class__)
                 30 DUP_TOP
                 32 STORE_NAME               5 (__classcell__)
                 34 RETURN_VALUE
    
    Disassembly of <code object __init__ at 0x000002159E130D40, file "Code Analysis/gpt2sample.py", line 31>:
     32           0 LOAD_GLOBAL              0 (super)
                  2 CALL_FUNCTION            0
                  4 LOAD_METHOD              1 (__init__)
                  6 CALL_METHOD              0
                  8 POP_TOP
    
     33          10 LOAD_FAST                1 (config)
                 12 LOAD_ATTR                2 (n_embd)
                 14 LOAD_FAST                1 (config)
                 16 LOAD_ATTR                3 (n_head)
                 18 BINARY_MODULO
                 20 LOAD_CONST               1 (0)
                 22 COMPARE_OP               2 (==)
                 24 POP_JUMP_IF_TRUE        15 (to 30)
                 26 LOAD_ASSERTION_ERROR
                 28 RAISE_VARARGS            1
    
     35     >>   30 LOAD_GLOBAL              4 (nn)
                 32 LOAD_ATTR                5 (Linear)
                 34 LOAD_FAST                1 (config)
                 36 LOAD_ATTR                2 (n_embd)
                 38 LOAD_CONST               2 (3)
                 40 LOAD_FAST                1 (config)
                 42 LOAD_ATTR                2 (n_embd)
                 44 BINARY_MULTIPLY
                 46 LOAD_FAST                1 (config)
                 48 LOAD_ATTR                6 (bias)
                 50 LOAD_CONST               3 (('bias',))
                 52 CALL_FUNCTION_KW         3
                 54 LOAD_FAST                0 (self)
                 56 STORE_ATTR               7 (c_attn)
    
     37          58 LOAD_GLOBAL              4 (nn)
                 60 LOAD_ATTR                5 (Linear)
                 62 LOAD_FAST                1 (config)
                 64 LOAD_ATTR                2 (n_embd)
                 66 LOAD_FAST                1 (config)
                 68 LOAD_ATTR                2 (n_embd)
                 70 LOAD_FAST                1 (config)
                 72 LOAD_ATTR                6 (bias)
                 74 LOAD_CONST               3 (('bias',))
                 76 CALL_FUNCTION_KW         3
                 78 LOAD_FAST                0 (self)
                 80 STORE_ATTR               8 (c_proj)
    
     39          82 LOAD_GLOBAL              4 (nn)
                 84 LOAD_METHOD              9 (Dropout)
                 86 LOAD_FAST                1 (config)
                 88 LOAD_ATTR               10 (dropout)
                 90 CALL_METHOD              1
                 92 LOAD_FAST                0 (self)
                 94 STORE_ATTR              11 (attn_dropout)
    
     40          96 LOAD_GLOBAL              4 (nn)
                 98 LOAD_METHOD              9 (Dropout)
                100 LOAD_FAST                1 (config)
                102 LOAD_ATTR               10 (dropout)
                104 CALL_METHOD              1
                106 LOAD_FAST                0 (self)
                108 STORE_ATTR              12 (resid_dropout)
    
     41         110 LOAD_FAST                1 (config)
                112 LOAD_ATTR                3 (n_head)
                114 LOAD_FAST                0 (self)
                116 STORE_ATTR               3 (n_head)
    
     42         118 LOAD_FAST                1 (config)
                120 LOAD_ATTR                2 (n_embd)
                122 LOAD_FAST                0 (self)
                124 STORE_ATTR               2 (n_embd)
    
     43         126 LOAD_FAST                1 (config)
                128 LOAD_ATTR               10 (dropout)
                130 LOAD_FAST                0 (self)
                132 STORE_ATTR              10 (dropout)
    
     45         134 LOAD_GLOBAL             13 (hasattr)
                136 LOAD_GLOBAL             14 (torch)
                138 LOAD_ATTR                4 (nn)
                140 LOAD_ATTR               15 (functional)
                142 LOAD_CONST               4 ('scaled_dot_product_attention')
                144 CALL_FUNCTION            2
                146 LOAD_FAST                0 (self)
                148 STORE_ATTR              16 (flash)
    
     46         150 LOAD_FAST                0 (self)
                152 LOAD_ATTR               16 (flash)
                154 POP_JUMP_IF_TRUE       107 (to 214)
    
     47         156 LOAD_GLOBAL             17 (print)
                158 LOAD_CONST               5 ('WARNING: using slow attention. Flash Attention requires PyTorch >= 2.0')
                160 CALL_FUNCTION            1
                162 POP_TOP
    
     49         164 LOAD_FAST                0 (self)
                166 LOAD_METHOD             18 (register_buffer)
                168 LOAD_CONST               6 ('bias')
                170 LOAD_GLOBAL             14 (torch)
                172 LOAD_METHOD             19 (tril)
                174 LOAD_GLOBAL             14 (torch)
                176 LOAD_METHOD             20 (ones)
                178 LOAD_FAST                1 (config)
                180 LOAD_ATTR               21 (block_size)
                182 LOAD_FAST                1 (config)
                184 LOAD_ATTR               21 (block_size)
                186 CALL_METHOD              2
                188 CALL_METHOD              1
    
     50         190 LOAD_METHOD             22 (view)
                192 LOAD_CONST               7 (1)
                194 LOAD_CONST               7 (1)
                196 LOAD_FAST                1 (config)
                198 LOAD_ATTR               21 (block_size)
                200 LOAD_FAST                1 (config)
                202 LOAD_ATTR               21 (block_size)
                204 CALL_METHOD              4
    
     49         206 CALL_METHOD              2
                208 POP_TOP
                210 LOAD_CONST               0 (None)
                212 RETURN_VALUE
    
     46     >>  214 LOAD_CONST               0 (None)
                216 RETURN_VALUE
    
    Disassembly of <code object forward at 0x000002159E130DF0, file "Code Analysis/gpt2sample.py", line 52>:
     53           0 LOAD_FAST                1 (x)
                  2 LOAD_METHOD              0 (size)
                  4 CALL_METHOD              0
                  6 UNPACK_SEQUENCE          3
                  8 STORE_FAST               2 (B)
                 10 STORE_FAST               3 (T)
                 12 STORE_FAST               4 (C)
    
     56          14 LOAD_FAST                0 (self)
                 16 LOAD_METHOD              1 (c_attn)
                 18 LOAD_FAST                1 (x)
                 20 CALL_METHOD              1
                 22 LOAD_ATTR                2 (split)
                 24 LOAD_FAST                0 (self)
                 26 LOAD_ATTR                3 (n_embd)
                 28 LOAD_CONST               1 (2)
                 30 LOAD_CONST               2 (('dim',))
                 32 CALL_FUNCTION_KW         2
                 34 UNPACK_SEQUENCE          3
                 36 STORE_FAST               5 (q)
                 38 STORE_FAST               6 (k)
                 40 STORE_FAST               7 (v)
    
     57          42 LOAD_FAST                6 (k)
                 44 LOAD_METHOD              4 (view)
                 46 LOAD_FAST                2 (B)
                 48 LOAD_FAST                3 (T)
                 50 LOAD_FAST                0 (self)
                 52 LOAD_ATTR                5 (n_head)
                 54 LOAD_FAST                4 (C)
                 56 LOAD_FAST                0 (self)
                 58 LOAD_ATTR                5 (n_head)
                 60 BINARY_FLOOR_DIVIDE
                 62 CALL_METHOD              4
                 64 LOAD_METHOD              6 (transpose)
                 66 LOAD_CONST               3 (1)
                 68 LOAD_CONST               1 (2)
                 70 CALL_METHOD              2
                 72 STORE_FAST               6 (k)
    
     58          74 LOAD_FAST                5 (q)
                 76 LOAD_METHOD              4 (view)
                 78 LOAD_FAST                2 (B)
                 80 LOAD_FAST                3 (T)
                 82 LOAD_FAST                0 (self)
                 84 LOAD_ATTR                5 (n_head)
                 86 LOAD_FAST                4 (C)
                 88 LOAD_FAST                0 (self)
                 90 LOAD_ATTR                5 (n_head)
                 92 BINARY_FLOOR_DIVIDE
                 94 CALL_METHOD              4
                 96 LOAD_METHOD              6 (transpose)
                 98 LOAD_CONST               3 (1)
                100 LOAD_CONST               1 (2)
                102 CALL_METHOD              2
                104 STORE_FAST               5 (q)
    
     59         106 LOAD_FAST                7 (v)
                108 LOAD_METHOD              4 (view)
                110 LOAD_FAST                2 (B)
                112 LOAD_FAST                3 (T)
                114 LOAD_FAST                0 (self)
                116 LOAD_ATTR                5 (n_head)
                118 LOAD_FAST                4 (C)
                120 LOAD_FAST                0 (self)
                122 LOAD_ATTR                5 (n_head)
                124 BINARY_FLOOR_DIVIDE
                126 CALL_METHOD              4
                128 LOAD_METHOD              6 (transpose)
                130 LOAD_CONST               3 (1)
                132 LOAD_CONST               1 (2)
                134 CALL_METHOD              2
                136 STORE_FAST               7 (v)
    
     62         138 LOAD_FAST                0 (self)
                140 LOAD_ATTR                7 (flash)
                142 POP_JUMP_IF_FALSE       92 (to 184)
    
     64         144 LOAD_GLOBAL              8 (torch)
                146 LOAD_ATTR                9 (nn)
                148 LOAD_ATTR               10 (functional)
                150 LOAD_ATTR               11 (scaled_dot_product_attention)
                152 LOAD_FAST                5 (q)
                154 LOAD_FAST                6 (k)
                156 LOAD_FAST                7 (v)
                158 LOAD_CONST               0 (None)
                160 LOAD_FAST                0 (self)
                162 LOAD_ATTR               12 (training)
                164 POP_JUMP_IF_FALSE       86 (to 172)
                166 LOAD_FAST                0 (self)
                168 LOAD_ATTR               13 (dropout)
                170 JUMP_FORWARD             1 (to 174)
            >>  172 LOAD_CONST               4 (0)
            >>  174 LOAD_CONST               5 (True)
                176 LOAD_CONST               6 (('attn_mask', 'dropout_p', 'is_causal'))
                178 CALL_FUNCTION_KW         6
                180 STORE_FAST               8 (y)
                182 JUMP_FORWARD            59 (to 302)
    
     67     >>  184 LOAD_FAST                5 (q)
                186 LOAD_FAST                6 (k)
                188 LOAD_METHOD              6 (transpose)
                190 LOAD_CONST               7 (-2)
                192 LOAD_CONST               8 (-1)
                194 CALL_METHOD              2
                196 BINARY_MATRIX_MULTIPLY
                198 LOAD_CONST               9 (1.0)
                200 LOAD_GLOBAL             14 (math)
                202 LOAD_METHOD             15 (sqrt)
                204 LOAD_FAST                6 (k)
                206 LOAD_METHOD              0 (size)
                208 LOAD_CONST               8 (-1)
                210 CALL_METHOD              1
                212 CALL_METHOD              1
                214 BINARY_TRUE_DIVIDE
                216 BINARY_MULTIPLY
                218 STORE_FAST               9 (att)
    
     68         220 LOAD_FAST                9 (att)
                222 LOAD_METHOD             16 (masked_fill)
                224 LOAD_FAST                0 (self)
                226 LOAD_ATTR               17 (bias)
                228 LOAD_CONST               0 (None)
                230 LOAD_CONST               0 (None)
                232 BUILD_SLICE              2
                234 LOAD_CONST               0 (None)
                236 LOAD_CONST               0 (None)
                238 BUILD_SLICE              2
                240 LOAD_CONST               0 (None)
                242 LOAD_FAST                3 (T)
                244 BUILD_SLICE              2
                246 LOAD_CONST               0 (None)
                248 LOAD_FAST                3 (T)
                250 BUILD_SLICE              2
                252 BUILD_TUPLE              4
                254 BINARY_SUBSCR
                256 LOAD_CONST               4 (0)
                258 COMPARE_OP               2 (==)
                260 LOAD_GLOBAL             18 (float)
                262 LOAD_CONST              10 ('-inf')
                264 CALL_FUNCTION            1
                266 CALL_METHOD              2
                268 STORE_FAST               9 (att)
    
     69         270 LOAD_GLOBAL             19 (F)
                272 LOAD_ATTR               20 (softmax)
                274 LOAD_FAST                9 (att)
                276 LOAD_CONST               8 (-1)
                278 LOAD_CONST               2 (('dim',))
                280 CALL_FUNCTION_KW         2
                282 STORE_FAST               9 (att)
    
     70         284 LOAD_FAST                0 (self)
                286 LOAD_METHOD             21 (attn_dropout)
                288 LOAD_FAST                9 (att)
                290 CALL_METHOD              1
                292 STORE_FAST               9 (att)
    
     71         294 LOAD_FAST                9 (att)
                296 LOAD_FAST                7 (v)
                298 BINARY_MATRIX_MULTIPLY
                300 STORE_FAST               8 (y)
    
     72     >>  302 LOAD_FAST                8 (y)
                304 LOAD_METHOD              6 (transpose)
                306 LOAD_CONST               3 (1)
                308 LOAD_CONST               1 (2)
                310 CALL_METHOD              2
                312 LOAD_METHOD             22 (contiguous)
                314 CALL_METHOD              0
                316 LOAD_METHOD              4 (view)
                318 LOAD_FAST                2 (B)
                320 LOAD_FAST                3 (T)
                322 LOAD_FAST                4 (C)
                324 CALL_METHOD              3
                326 STORE_FAST               8 (y)
    
     75         328 LOAD_FAST                0 (self)
                330 LOAD_METHOD             23 (resid_dropout)
                332 LOAD_FAST                0 (self)
                334 LOAD_METHOD             24 (c_proj)
                336 LOAD_FAST                8 (y)
                338 CALL_METHOD              1
                340 CALL_METHOD              1
                342 STORE_FAST               8 (y)
    
     76         344 LOAD_FAST                8 (y)
                346 RETURN_VALUE
    
    Disassembly of <code object MLP at 0x000002159E1310B0, file "Code Analysis/gpt2sample.py", line 78>:
     78           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('MLP')
                  6 STORE_NAME               2 (__qualname__)
    
     80           8 LOAD_CLOSURE             0 (__class__)
                 10 BUILD_TUPLE              1
                 12 LOAD_CONST               1 (<code object __init__ at 0x000002159E130F50, file "Code Analysis/gpt2sample.py", line 80>)
                 14 LOAD_CONST               2 ('MLP.__init__')
                 16 MAKE_FUNCTION            8 (closure)
                 18 STORE_NAME               3 (__init__)
    
     87          20 LOAD_CONST               3 (<code object forward at 0x000002159E131000, file "Code Analysis/gpt2sample.py", line 87>)
                 22 LOAD_CONST               4 ('MLP.forward')
                 24 MAKE_FUNCTION            0
                 26 STORE_NAME               4 (forward)
                 28 LOAD_CLOSURE             0 (__class__)
                 30 DUP_TOP
                 32 STORE_NAME               5 (__classcell__)
                 34 RETURN_VALUE
    
    Disassembly of <code object __init__ at 0x000002159E130F50, file "Code Analysis/gpt2sample.py", line 80>:
     81           0 LOAD_GLOBAL              0 (super)
                  2 CALL_FUNCTION            0
                  4 LOAD_METHOD              1 (__init__)
                  6 CALL_METHOD              0
                  8 POP_TOP
    
     82          10 LOAD_GLOBAL              2 (nn)
                 12 LOAD_ATTR                3 (Linear)
                 14 LOAD_FAST                1 (config)
                 16 LOAD_ATTR                4 (n_embd)
                 18 LOAD_CONST               1 (4)
                 20 LOAD_FAST                1 (config)
                 22 LOAD_ATTR                4 (n_embd)
                 24 BINARY_MULTIPLY
                 26 LOAD_FAST                1 (config)
                 28 LOAD_ATTR                5 (bias)
                 30 LOAD_CONST               2 (('bias',))
                 32 CALL_FUNCTION_KW         3
                 34 LOAD_FAST                0 (self)
                 36 STORE_ATTR               6 (c_fc)
    
     83          38 LOAD_GLOBAL              2 (nn)
                 40 LOAD_METHOD              7 (GELU)
                 42 CALL_METHOD              0
                 44 LOAD_FAST                0 (self)
                 46 STORE_ATTR               8 (gelu)
    
     84          48 LOAD_GLOBAL              2 (nn)
                 50 LOAD_ATTR                3 (Linear)
                 52 LOAD_CONST               1 (4)
                 54 LOAD_FAST                1 (config)
                 56 LOAD_ATTR                4 (n_embd)
                 58 BINARY_MULTIPLY
                 60 LOAD_FAST                1 (config)
                 62 LOAD_ATTR                4 (n_embd)
                 64 LOAD_FAST                1 (config)
                 66 LOAD_ATTR                5 (bias)
                 68 LOAD_CONST               2 (('bias',))
                 70 CALL_FUNCTION_KW         3
                 72 LOAD_FAST                0 (self)
                 74 STORE_ATTR               9 (c_proj)
    
     85          76 LOAD_GLOBAL              2 (nn)
                 78 LOAD_METHOD             10 (Dropout)
                 80 LOAD_FAST                1 (config)
                 82 LOAD_ATTR               11 (dropout)
                 84 CALL_METHOD              1
                 86 LOAD_FAST                0 (self)
                 88 STORE_ATTR              11 (dropout)
                 90 LOAD_CONST               0 (None)
                 92 RETURN_VALUE
    
    Disassembly of <code object forward at 0x000002159E131000, file "Code Analysis/gpt2sample.py", line 87>:
     88           0 LOAD_FAST                0 (self)
                  2 LOAD_METHOD              0 (c_fc)
                  4 LOAD_FAST                1 (x)
                  6 CALL_METHOD              1
                  8 STORE_FAST               1 (x)
    
     89          10 LOAD_FAST                0 (self)
                 12 LOAD_METHOD              1 (gelu)
                 14 LOAD_FAST                1 (x)
                 16 CALL_METHOD              1
                 18 STORE_FAST               1 (x)
    
     90          20 LOAD_FAST                0 (self)
                 22 LOAD_METHOD              2 (c_proj)
                 24 LOAD_FAST                1 (x)
                 26 CALL_METHOD              1
                 28 STORE_FAST               1 (x)
    
     91          30 LOAD_FAST                0 (self)
                 32 LOAD_METHOD              3 (dropout)
                 34 LOAD_FAST                1 (x)
                 36 CALL_METHOD              1
                 38 STORE_FAST               1 (x)
    
     92          40 LOAD_FAST                1 (x)
                 42 RETURN_VALUE
    
    Disassembly of <code object Block at 0x000002159E1312C0, file "Code Analysis/gpt2sample.py", line 94>:
     94           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('Block')
                  6 STORE_NAME               2 (__qualname__)
    
     96           8 LOAD_CLOSURE             0 (__class__)
                 10 BUILD_TUPLE              1
                 12 LOAD_CONST               1 (<code object __init__ at 0x000002159E131160, file "Code Analysis/gpt2sample.py", line 96>)
                 14 LOAD_CONST               2 ('Block.__init__')
                 16 MAKE_FUNCTION            8 (closure)
                 18 STORE_NAME               3 (__init__)
    
    103          20 LOAD_CONST               3 (<code object forward at 0x000002159E131210, file "Code Analysis/gpt2sample.py", line 103>)
                 22 LOAD_CONST               4 ('Block.forward')
                 24 MAKE_FUNCTION            0
                 26 STORE_NAME               4 (forward)
                 28 LOAD_CLOSURE             0 (__class__)
                 30 DUP_TOP
                 32 STORE_NAME               5 (__classcell__)
                 34 RETURN_VALUE
    
    Disassembly of <code object __init__ at 0x000002159E131160, file "Code Analysis/gpt2sample.py", line 96>:
     97           0 LOAD_GLOBAL              0 (super)
                  2 CALL_FUNCTION            0
                  4 LOAD_METHOD              1 (__init__)
                  6 CALL_METHOD              0
                  8 POP_TOP
    
     98          10 LOAD_GLOBAL              2 (LayerNorm)
                 12 LOAD_FAST                1 (config)
                 14 LOAD_ATTR                3 (n_embd)
                 16 LOAD_FAST                1 (config)
                 18 LOAD_ATTR                4 (bias)
                 20 LOAD_CONST               1 (('bias',))
                 22 CALL_FUNCTION_KW         2
                 24 LOAD_FAST                0 (self)
                 26 STORE_ATTR               5 (ln_1)
    
     99          28 LOAD_GLOBAL              6 (CausalSelfAttention)
                 30 LOAD_FAST                1 (config)
                 32 CALL_FUNCTION            1
                 34 LOAD_FAST                0 (self)
                 36 STORE_ATTR               7 (attn)
    
    100          38 LOAD_GLOBAL              2 (LayerNorm)
                 40 LOAD_FAST                1 (config)
                 42 LOAD_ATTR                3 (n_embd)
                 44 LOAD_FAST                1 (config)
                 46 LOAD_ATTR                4 (bias)
                 48 LOAD_CONST               1 (('bias',))
                 50 CALL_FUNCTION_KW         2
                 52 LOAD_FAST                0 (self)
                 54 STORE_ATTR               8 (ln_2)
    
    101          56 LOAD_GLOBAL              9 (MLP)
                 58 LOAD_FAST                1 (config)
                 60 CALL_FUNCTION            1
                 62 LOAD_FAST                0 (self)
                 64 STORE_ATTR              10 (mlp)
                 66 LOAD_CONST               0 (None)
                 68 RETURN_VALUE
    
    Disassembly of <code object forward at 0x000002159E131210, file "Code Analysis/gpt2sample.py", line 103>:
    104           0 LOAD_FAST                1 (x)
                  2 LOAD_FAST                0 (self)
                  4 LOAD_METHOD              0 (attn)
                  6 LOAD_FAST                0 (self)
                  8 LOAD_METHOD              1 (ln_1)
                 10 LOAD_FAST                1 (x)
                 12 CALL_METHOD              1
                 14 CALL_METHOD              1
                 16 BINARY_ADD
                 18 STORE_FAST               1 (x)
    
    105          20 LOAD_FAST                1 (x)
                 22 LOAD_FAST                0 (self)
                 24 LOAD_METHOD              2 (mlp)
                 26 LOAD_FAST                0 (self)
                 28 LOAD_METHOD              3 (ln_2)
                 30 LOAD_FAST                1 (x)
                 32 CALL_METHOD              1
                 34 CALL_METHOD              1
                 36 BINARY_ADD
                 38 STORE_FAST               1 (x)
    
    106          40 LOAD_FAST                1 (x)
                 42 RETURN_VALUE
    
    Disassembly of <code object GPTConfig at 0x000002159E131370, file "Code Analysis/gpt2sample.py", line 108>:
    108           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('GPTConfig')
                  6 STORE_NAME               2 (__qualname__)
                  8 SETUP_ANNOTATIONS
    
    110          10 LOAD_CONST               1 (1024)
                 12 STORE_NAME               3 (block_size)
                 14 LOAD_NAME                4 (int)
                 16 LOAD_NAME                5 (__annotations__)
                 18 LOAD_CONST               2 ('block_size')
                 20 STORE_SUBSCR
    
    111          22 LOAD_CONST               3 (50304)
                 24 STORE_NAME               6 (vocab_size)
                 26 LOAD_NAME                4 (int)
                 28 LOAD_NAME                5 (__annotations__)
                 30 LOAD_CONST               4 ('vocab_size')
                 32 STORE_SUBSCR
    
    112          34 LOAD_CONST               5 (12)
                 36 STORE_NAME               7 (n_layer)
                 38 LOAD_NAME                4 (int)
                 40 LOAD_NAME                5 (__annotations__)
                 42 LOAD_CONST               6 ('n_layer')
                 44 STORE_SUBSCR
    
    113          46 LOAD_CONST               5 (12)
                 48 STORE_NAME               8 (n_head)
                 50 LOAD_NAME                4 (int)
                 52 LOAD_NAME                5 (__annotations__)
                 54 LOAD_CONST               7 ('n_head')
                 56 STORE_SUBSCR
    
    114          58 LOAD_CONST               8 (768)
                 60 STORE_NAME               9 (n_embd)
                 62 LOAD_NAME                4 (int)
                 64 LOAD_NAME                5 (__annotations__)
                 66 LOAD_CONST               9 ('n_embd')
                 68 STORE_SUBSCR
    
    115          70 LOAD_CONST              10 (0.0)
                 72 STORE_NAME              10 (dropout)
                 74 LOAD_NAME               11 (float)
                 76 LOAD_NAME                5 (__annotations__)
                 78 LOAD_CONST              11 ('dropout')
                 80 STORE_SUBSCR
    
    116          82 LOAD_CONST              12 (True)
                 84 STORE_NAME              12 (bias)
                 86 LOAD_NAME               13 (bool)
                 88 LOAD_NAME                5 (__annotations__)
                 90 LOAD_CONST              13 ('bias')
                 92 STORE_SUBSCR
                 94 LOAD_CONST              14 (None)
                 96 RETURN_VALUE
    
    Disassembly of <code object GPT at 0x000002159E132340, file "Code Analysis/gpt2sample.py", line 118>:
    118           0 LOAD_NAME                0 (__name__)
                  2 STORE_NAME               1 (__module__)
                  4 LOAD_CONST               0 ('GPT')
                  6 STORE_NAME               2 (__qualname__)
    
    120           8 LOAD_CLOSURE             0 (__class__)
                 10 BUILD_TUPLE              1
                 12 LOAD_CONST               1 (<code object __init__ at 0x000002159E1314D0, file "Code Analysis/gpt2sample.py", line 120>)
                 14 LOAD_CONST               2 ('GPT.__init__')
                 16 MAKE_FUNCTION            8 (closure)
                 18 STORE_NAME               3 (__init__)
    
    150          20 LOAD_CONST              22 ((True,))
                 22 LOAD_CONST               4 (<code object get_num_params at 0x000002159E131630, file "Code Analysis/gpt2sample.py", line 150>)
                 24 LOAD_CONST               5 ('GPT.get_num_params')
                 26 MAKE_FUNCTION            1 (defaults)
                 28 STORE_NAME               4 (get_num_params)
    
    162          30 LOAD_CONST               6 (<code object _init_weights at 0x000002159E1316E0, file "Code Analysis/gpt2sample.py", line 162>)
                 32 LOAD_CONST               7 ('GPT._init_weights')
                 34 MAKE_FUNCTION            0
                 36 STORE_NAME               5 (_init_weights)
    
    170          38 LOAD_CONST              23 ((None,))
                 40 LOAD_CONST               9 (<code object forward at 0x000002159E131790, file "Code Analysis/gpt2sample.py", line 170>)
                 42 LOAD_CONST              10 ('GPT.forward')
                 44 MAKE_FUNCTION            1 (defaults)
                 46 STORE_NAME               6 (forward)
    
    195          48 LOAD_CONST              11 (<code object crop_block_size at 0x000002159E131840, file "Code Analysis/gpt2sample.py", line 195>)
                 50 LOAD_CONST              12 ('GPT.crop_block_size')
                 52 MAKE_FUNCTION            0
                 54 STORE_NAME               7 (crop_block_size)
    
    206          56 LOAD_NAME                8 (classmethod)
    
    207          58 LOAD_CONST              23 ((None,))
                 60 LOAD_CONST              13 (<code object from_pretrained at 0x000002159E131C60, file "Code Analysis/gpt2sample.py", line 206>)
                 62 LOAD_CONST              14 ('GPT.from_pretrained')
                 64 MAKE_FUNCTION            1 (defaults)
                 66 CALL_FUNCTION            1
                 68 STORE_NAME               9 (from_pretrained)
    
    263          70 LOAD_CONST              15 (<code object configure_optimizers at 0x000002159E132130, file "Code Analysis/gpt2sample.py", line 263>)
                 72 LOAD_CONST              16 ('GPT.configure_optimizers')
                 74 MAKE_FUNCTION            0
                 76 STORE_NAME              10 (configure_optimizers)
    
    289          78 LOAD_CONST              17 (<code object estimate_mfu at 0x000002159E1321E0, file "Code Analysis/gpt2sample.py", line 289>)
                 80 LOAD_CONST              18 ('GPT.estimate_mfu')
                 82 MAKE_FUNCTION            0
                 84 STORE_NAME              11 (estimate_mfu)
    
    305          86 LOAD_NAME               12 (torch)
                 88 LOAD_METHOD             13 (no_grad)
                 90 CALL_METHOD              0
    
    306          92 LOAD_CONST              24 ((1.0, None))
                 94 LOAD_CONST              20 (<code object generate at 0x000002159E132290, file "Code Analysis/gpt2sample.py", line 305>)
                 96 LOAD_CONST              21 ('GPT.generate')
                 98 MAKE_FUNCTION            1 (defaults)
                100 CALL_FUNCTION            1
                102 STORE_NAME              14 (generate)
                104 LOAD_CLOSURE             0 (__class__)
                106 DUP_TOP
                108 STORE_NAME              15 (__classcell__)
                110 RETURN_VALUE
    
    Disassembly of <code object __init__ at 0x000002159E1314D0, file "Code Analysis/gpt2sample.py", line 120>:
    121           0 LOAD_GLOBAL              0 (super)
                  2 CALL_FUNCTION            0
                  4 LOAD_METHOD              1 (__init__)
                  6 CALL_METHOD              0
                  8 POP_TOP
    
    122          10 LOAD_DEREF               0 (config)
                 12 LOAD_ATTR                2 (vocab_size)
                 14 LOAD_CONST               0 (None)
                 16 IS_OP                    1
                 18 POP_JUMP_IF_TRUE        12 (to 24)
                 20 LOAD_ASSERTION_ERROR
                 22 RAISE_VARARGS            1
    
    123     >>   24 LOAD_DEREF               0 (config)
                 26 LOAD_ATTR                3 (block_size)
                 28 LOAD_CONST               0 (None)
                 30 IS_OP                    1
                 32 POP_JUMP_IF_TRUE        19 (to 38)
                 34 LOAD_ASSERTION_ERROR
                 36 RAISE_VARARGS            1
    
    124     >>   38 LOAD_DEREF               0 (config)
                 40 LOAD_FAST                0 (self)
                 42 STORE_ATTR               4 (config)
    
    126          44 LOAD_GLOBAL              5 (nn)
                 46 LOAD_METHOD              6 (ModuleDict)
                 48 LOAD_GLOBAL              7 (dict)
    
    127          50 LOAD_GLOBAL              5 (nn)
                 52 LOAD_METHOD              8 (Embedding)
                 54 LOAD_DEREF               0 (config)
                 56 LOAD_ATTR                2 (vocab_size)
                 58 LOAD_DEREF               0 (config)
                 60 LOAD_ATTR                9 (n_embd)
                 62 CALL_METHOD              2
    
    128          64 LOAD_GLOBAL              5 (nn)
                 66 LOAD_METHOD              8 (Embedding)
                 68 LOAD_DEREF               0 (config)
                 70 LOAD_ATTR                3 (block_size)
                 72 LOAD_DEREF               0 (config)
                 74 LOAD_ATTR                9 (n_embd)
                 76 CALL_METHOD              2
    
    129          78 LOAD_GLOBAL              5 (nn)
                 80 LOAD_METHOD             10 (Dropout)
                 82 LOAD_DEREF               0 (config)
                 84 LOAD_ATTR               11 (dropout)
                 86 CALL_METHOD              1
    
    130          88 LOAD_GLOBAL              5 (nn)
                 90 LOAD_METHOD             12 (ModuleList)
                 92 LOAD_CLOSURE             0 (config)
                 94 BUILD_TUPLE              1
                 96 LOAD_CONST               1 (<code object <listcomp> at 0x000002159E131420, file "Code Analysis/gpt2sample.py", line 130>)
                 98 LOAD_CONST               2 ('GPT.__init__.<locals>.<listcomp>')
                100 MAKE_FUNCTION            8 (closure)
                102 LOAD_GLOBAL             13 (range)
                104 LOAD_DEREF               0 (config)
                106 LOAD_ATTR               14 (n_layer)
                108 CALL_FUNCTION            1
                110 GET_ITER
                112 CALL_FUNCTION            1
                114 CALL_METHOD              1
    
    131         116 LOAD_GLOBAL             15 (LayerNorm)
                118 LOAD_DEREF               0 (config)
                120 LOAD_ATTR                9 (n_embd)
                122 LOAD_DEREF               0 (config)
                124 LOAD_ATTR               16 (bias)
                126 LOAD_CONST               3 (('bias',))
                128 CALL_FUNCTION_KW         2
    
    126         130 LOAD_CONST               4 (('wte', 'wpe', 'drop', 'h', 'ln_f'))
                132 CALL_FUNCTION_KW         5
                134 CALL_METHOD              1
                136 LOAD_FAST                0 (self)
                138 STORE_ATTR              17 (transformer)
    
    133         140 LOAD_GLOBAL              5 (nn)
                142 LOAD_ATTR               18 (Linear)
                144 LOAD_DEREF               0 (config)
                146 LOAD_ATTR                9 (n_embd)
                148 LOAD_DEREF               0 (config)
                150 LOAD_ATTR                2 (vocab_size)
                152 LOAD_CONST               5 (False)
                154 LOAD_CONST               3 (('bias',))
                156 CALL_FUNCTION_KW         3
                158 LOAD_FAST                0 (self)
                160 STORE_ATTR              19 (lm_head)
    
    138         162 LOAD_FAST                0 (self)
                164 LOAD_ATTR               19 (lm_head)
                166 LOAD_ATTR               20 (weight)
                168 LOAD_FAST                0 (self)
                170 LOAD_ATTR               17 (transformer)
                172 LOAD_ATTR               21 (wte)
                174 STORE_ATTR              20 (weight)
    
    141         176 LOAD_FAST                0 (self)
                178 LOAD_METHOD             22 (apply)
                180 LOAD_FAST                0 (self)
                182 LOAD_ATTR               23 (_init_weights)
                184 CALL_METHOD              1
                186 POP_TOP
    
    143         188 LOAD_FAST                0 (self)
                190 LOAD_METHOD             24 (named_parameters)
                192 CALL_METHOD              0
                194 GET_ITER
            >>  196 FOR_ITER                27 (to 252)
                198 UNPACK_SEQUENCE          2
                200 STORE_FAST               2 (pn)
                202 STORE_FAST               3 (p)
    
    144         204 LOAD_FAST                2 (pn)
                206 LOAD_METHOD             25 (endswith)
                208 LOAD_CONST               6 ('c_proj.weight')
                210 CALL_METHOD              1
                212 POP_JUMP_IF_FALSE      125 (to 250)
    
    145         214 LOAD_GLOBAL             26 (torch)
                216 LOAD_ATTR                5 (nn)
                218 LOAD_ATTR               27 (init)
                220 LOAD_ATTR               28 (normal_)
                222 LOAD_FAST                3 (p)
                224 LOAD_CONST               7 (0.0)
                226 LOAD_CONST               8 (0.02)
                228 LOAD_GLOBAL             29 (math)
                230 LOAD_METHOD             30 (sqrt)
                232 LOAD_CONST               9 (2)
                234 LOAD_DEREF               0 (config)
                236 LOAD_ATTR               14 (n_layer)
                238 BINARY_MULTIPLY
                240 CALL_METHOD              1
                242 BINARY_TRUE_DIVIDE
                244 LOAD_CONST              10 (('mean', 'std'))
                246 CALL_FUNCTION_KW         3
                248 POP_TOP
            >>  250 JUMP_ABSOLUTE           98 (to 196)
    
    148     >>  252 LOAD_GLOBAL             31 (print)
                254 LOAD_CONST              11 ('number of parameters: %.2fM')
                256 LOAD_FAST                0 (self)
                258 LOAD_METHOD             32 (get_num_params)
                260 CALL_METHOD              0
                262 LOAD_CONST              12 (1000000.0)
                264 BINARY_TRUE_DIVIDE
                266 BUILD_TUPLE              1
                268 BINARY_MODULO
                270 CALL_FUNCTION            1
                272 POP_TOP
                274 LOAD_CONST               0 (None)
                276 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E131420, file "Code Analysis/gpt2sample.py", line 130>:
    130           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 6 (to 18)
                  6 STORE_FAST               1 (_)
                  8 LOAD_GLOBAL              0 (Block)
                 10 LOAD_DEREF               0 (config)
                 12 CALL_FUNCTION            1
                 14 LIST_APPEND              2
                 16 JUMP_ABSOLUTE            2 (to 4)
            >>   18 RETURN_VALUE
    
    Disassembly of <code object get_num_params at 0x000002159E131630, file "Code Analysis/gpt2sample.py", line 150>:
    157           0 LOAD_GLOBAL              0 (sum)
                  2 LOAD_CONST               1 (<code object <genexpr> at 0x000002159E131580, file "Code Analysis/gpt2sample.py", line 157>)
                  4 LOAD_CONST               2 ('GPT.get_num_params.<locals>.<genexpr>')
                  6 MAKE_FUNCTION            0
                  8 LOAD_FAST                0 (self)
                 10 LOAD_METHOD              1 (parameters)
                 12 CALL_METHOD              0
                 14 GET_ITER
                 16 CALL_FUNCTION            1
                 18 CALL_FUNCTION            1
                 20 STORE_FAST               2 (n_params)
    
    158          22 LOAD_FAST                1 (non_embedding)
                 24 POP_JUMP_IF_FALSE       22 (to 44)
    
    159          26 LOAD_FAST                2 (n_params)
                 28 LOAD_FAST                0 (self)
                 30 LOAD_ATTR                2 (transformer)
                 32 LOAD_ATTR                3 (wpe)
                 34 LOAD_ATTR                4 (weight)
                 36 LOAD_METHOD              5 (numel)
                 38 CALL_METHOD              0
                 40 INPLACE_SUBTRACT
                 42 STORE_FAST               2 (n_params)
    
    160     >>   44 LOAD_FAST                2 (n_params)
                 46 RETURN_VALUE
    
    Disassembly of <code object <genexpr> at 0x000002159E131580, file "Code Analysis/gpt2sample.py", line 157>:
                  0 GEN_START                0
    
    157           2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 7 (to 20)
                  6 STORE_FAST               1 (p)
                  8 LOAD_FAST                1 (p)
                 10 LOAD_METHOD              0 (numel)
                 12 CALL_METHOD              0
                 14 YIELD_VALUE
                 16 POP_TOP
                 18 JUMP_ABSOLUTE            2 (to 4)
            >>   20 LOAD_CONST               0 (None)
                 22 RETURN_VALUE
    
    Disassembly of <code object _init_weights at 0x000002159E1316E0, file "Code Analysis/gpt2sample.py", line 162>:
    163           0 LOAD_GLOBAL              0 (isinstance)
                  2 LOAD_FAST                1 (module)
                  4 LOAD_GLOBAL              1 (nn)
                  6 LOAD_ATTR                2 (Linear)
                  8 CALL_FUNCTION            2
                 10 POP_JUMP_IF_FALSE       34 (to 68)
    
    164          12 LOAD_GLOBAL              3 (torch)
                 14 LOAD_ATTR                1 (nn)
                 16 LOAD_ATTR                4 (init)
                 18 LOAD_ATTR                5 (normal_)
                 20 LOAD_FAST                1 (module)
                 22 LOAD_ATTR                6 (weight)
                 24 LOAD_CONST               1 (0.0)
                 26 LOAD_CONST               2 (0.02)
                 28 LOAD_CONST               3 (('mean', 'std'))
                 30 CALL_FUNCTION_KW         3
                 32 POP_TOP
    
    165          34 LOAD_FAST                1 (module)
                 36 LOAD_ATTR                7 (bias)
                 38 LOAD_CONST               0 (None)
                 40 IS_OP                    1
                 42 POP_JUMP_IF_FALSE       32 (to 64)
    
    166          44 LOAD_GLOBAL              3 (torch)
                 46 LOAD_ATTR                1 (nn)
                 48 LOAD_ATTR                4 (init)
                 50 LOAD_METHOD              8 (zeros_)
                 52 LOAD_FAST                1 (module)
                 54 LOAD_ATTR                7 (bias)
                 56 CALL_METHOD              1
                 58 POP_TOP
                 60 LOAD_CONST               0 (None)
                 62 RETURN_VALUE
    
    165     >>   64 LOAD_CONST               0 (None)
                 66 RETURN_VALUE
    
    167     >>   68 LOAD_GLOBAL              0 (isinstance)
                 70 LOAD_FAST                1 (module)
                 72 LOAD_GLOBAL              1 (nn)
                 74 LOAD_ATTR                9 (Embedding)
                 76 CALL_FUNCTION            2
                 78 POP_JUMP_IF_FALSE       53 (to 106)
    
    168          80 LOAD_GLOBAL              3 (torch)
                 82 LOAD_ATTR                1 (nn)
                 84 LOAD_ATTR                4 (init)
                 86 LOAD_ATTR                5 (normal_)
                 88 LOAD_FAST                1 (module)
                 90 LOAD_ATTR                6 (weight)
                 92 LOAD_CONST               1 (0.0)
                 94 LOAD_CONST               2 (0.02)
                 96 LOAD_CONST               3 (('mean', 'std'))
                 98 CALL_FUNCTION_KW         3
                100 POP_TOP
                102 LOAD_CONST               0 (None)
                104 RETURN_VALUE
    
    167     >>  106 LOAD_CONST               0 (None)
                108 RETURN_VALUE
    
    Disassembly of <code object forward at 0x000002159E131790, file "Code Analysis/gpt2sample.py", line 170>:
    171           0 LOAD_FAST                1 (idx)
                  2 LOAD_ATTR                0 (device)
                  4 STORE_FAST               3 (device)
    
    172           6 LOAD_FAST                1 (idx)
                  8 LOAD_METHOD              1 (size)
                 10 CALL_METHOD              0
                 12 UNPACK_SEQUENCE          2
                 14 STORE_FAST               4 (b)
                 16 STORE_FAST               5 (t)
    
    173          18 LOAD_FAST                5 (t)
                 20 LOAD_FAST                0 (self)
                 22 LOAD_ATTR                2 (config)
                 24 LOAD_ATTR                3 (block_size)
                 26 COMPARE_OP               1 (<=)
                 28 POP_JUMP_IF_TRUE        27 (to 54)
                 30 LOAD_ASSERTION_ERROR
                 32 LOAD_CONST               1 ('Cannot forward sequence of length ')
                 34 LOAD_FAST                5 (t)
                 36 FORMAT_VALUE             0
                 38 LOAD_CONST               2 (', block size is only ')
                 40 LOAD_FAST                0 (self)
                 42 LOAD_ATTR                2 (config)
                 44 LOAD_ATTR                3 (block_size)
                 46 FORMAT_VALUE             0
                 48 BUILD_STRING             4
                 50 CALL_FUNCTION            1
                 52 RAISE_VARARGS            1
    
    174     >>   54 LOAD_GLOBAL              4 (torch)
                 56 LOAD_ATTR                5 (arange)
                 58 LOAD_CONST               3 (0)
                 60 LOAD_FAST                5 (t)
                 62 LOAD_GLOBAL              4 (torch)
                 64 LOAD_ATTR                6 (long)
                 66 LOAD_FAST                3 (device)
                 68 LOAD_CONST               4 (('dtype', 'device'))
                 70 CALL_FUNCTION_KW         4
                 72 STORE_FAST               6 (pos)
    
    177          74 LOAD_FAST                0 (self)
                 76 LOAD_ATTR                7 (transformer)
                 78 LOAD_METHOD              8 (wte)
                 80 LOAD_FAST                1 (idx)
                 82 CALL_METHOD              1
                 84 STORE_FAST               7 (tok_emb)
    
    178          86 LOAD_FAST                0 (self)
                 88 LOAD_ATTR                7 (transformer)
                 90 LOAD_METHOD              9 (wpe)
                 92 LOAD_FAST                6 (pos)
                 94 CALL_METHOD              1
                 96 STORE_FAST               8 (pos_emb)
    
    179          98 LOAD_FAST                0 (self)
                100 LOAD_ATTR                7 (transformer)
                102 LOAD_METHOD             10 (drop)
                104 LOAD_FAST                7 (tok_emb)
                106 LOAD_FAST                8 (pos_emb)
                108 BINARY_ADD
                110 CALL_METHOD              1
                112 STORE_FAST               9 (x)
    
    180         114 LOAD_FAST                0 (self)
                116 LOAD_ATTR                7 (transformer)
                118 LOAD_ATTR               11 (h)
                120 GET_ITER
            >>  122 FOR_ITER                 6 (to 136)
                124 STORE_FAST              10 (block)
    
    181         126 LOAD_FAST               10 (block)
                128 LOAD_FAST                9 (x)
                130 CALL_FUNCTION            1
                132 STORE_FAST               9 (x)
                134 JUMP_ABSOLUTE           61 (to 122)
    
    182     >>  136 LOAD_FAST                0 (self)
                138 LOAD_ATTR                7 (transformer)
                140 LOAD_METHOD             12 (ln_f)
                142 LOAD_FAST                9 (x)
                144 CALL_METHOD              1
                146 STORE_FAST               9 (x)
    
    184         148 LOAD_FAST                2 (targets)
                150 LOAD_CONST               0 (None)
                152 IS_OP                    1
                154 POP_JUMP_IF_FALSE      105 (to 210)
    
    186         156 LOAD_FAST                0 (self)
                158 LOAD_METHOD             13 (lm_head)
                160 LOAD_FAST                9 (x)
                162 CALL_METHOD              1
                164 STORE_FAST              11 (logits)
    
    187         166 LOAD_GLOBAL             14 (F)
                168 LOAD_ATTR               15 (cross_entropy)
                170 LOAD_FAST               11 (logits)
                172 LOAD_METHOD             16 (view)
                174 LOAD_CONST               5 (-1)
                176 LOAD_FAST               11 (logits)
                178 LOAD_METHOD              1 (size)
                180 LOAD_CONST               5 (-1)
                182 CALL_METHOD              1
                184 CALL_METHOD              2
                186 LOAD_FAST                2 (targets)
                188 LOAD_METHOD             16 (view)
                190 LOAD_CONST               5 (-1)
                192 CALL_METHOD              1
                194 LOAD_CONST               5 (-1)
                196 LOAD_CONST               6 (('ignore_index',))
                198 CALL_FUNCTION_KW         3
                200 STORE_FAST              12 (loss)
    
    193         202 LOAD_FAST               11 (logits)
                204 LOAD_FAST               12 (loss)
                206 BUILD_TUPLE              2
                208 RETURN_VALUE
    
    190     >>  210 LOAD_FAST                0 (self)
                212 LOAD_METHOD             13 (lm_head)
                214 LOAD_FAST                9 (x)
                216 LOAD_CONST               0 (None)
                218 LOAD_CONST               0 (None)
                220 BUILD_SLICE              2
                222 LOAD_CONST               5 (-1)
                224 BUILD_LIST               1
                226 LOAD_CONST               0 (None)
                228 LOAD_CONST               0 (None)
                230 BUILD_SLICE              2
                232 BUILD_TUPLE              3
                234 BINARY_SUBSCR
                236 CALL_METHOD              1
                238 STORE_FAST              11 (logits)
    
    191         240 LOAD_CONST               0 (None)
                242 STORE_FAST              12 (loss)
    
    193         244 LOAD_FAST               11 (logits)
                246 LOAD_FAST               12 (loss)
                248 BUILD_TUPLE              2
                250 RETURN_VALUE
    
    Disassembly of <code object crop_block_size at 0x000002159E131840, file "Code Analysis/gpt2sample.py", line 195>:
    199           0 LOAD_FAST                1 (block_size)
                  2 LOAD_FAST                0 (self)
                  4 LOAD_ATTR                0 (config)
                  6 LOAD_ATTR                1 (block_size)
                  8 COMPARE_OP               1 (<=)
                 10 POP_JUMP_IF_TRUE         8 (to 16)
                 12 LOAD_ASSERTION_ERROR
                 14 RAISE_VARARGS            1
    
    200     >>   16 LOAD_FAST                1 (block_size)
                 18 LOAD_FAST                0 (self)
                 20 LOAD_ATTR                0 (config)
                 22 STORE_ATTR               1 (block_size)
    
    201          24 LOAD_GLOBAL              2 (nn)
                 26 LOAD_METHOD              3 (Parameter)
                 28 LOAD_FAST                0 (self)
                 30 LOAD_ATTR                4 (transformer)
                 32 LOAD_ATTR                5 (wpe)
                 34 LOAD_ATTR                6 (weight)
                 36 LOAD_CONST               0 (None)
                 38 LOAD_FAST                1 (block_size)
                 40 BUILD_SLICE              2
                 42 BINARY_SUBSCR
                 44 CALL_METHOD              1
                 46 LOAD_FAST                0 (self)
                 48 LOAD_ATTR                4 (transformer)
                 50 LOAD_ATTR                5 (wpe)
                 52 STORE_ATTR               6 (weight)
    
    202          54 LOAD_FAST                0 (self)
                 56 LOAD_ATTR                4 (transformer)
                 58 LOAD_ATTR                7 (h)
                 60 GET_ITER
            >>   62 FOR_ITER                28 (to 120)
                 64 STORE_FAST               2 (block)
    
    203          66 LOAD_GLOBAL              8 (hasattr)
                 68 LOAD_FAST                2 (block)
                 70 LOAD_ATTR                9 (attn)
                 72 LOAD_CONST               1 ('bias')
                 74 CALL_FUNCTION            2
                 76 POP_JUMP_IF_FALSE       59 (to 118)
    
    204          78 LOAD_FAST                2 (block)
                 80 LOAD_ATTR                9 (attn)
                 82 LOAD_ATTR               10 (bias)
                 84 LOAD_CONST               0 (None)
                 86 LOAD_CONST               0 (None)
                 88 BUILD_SLICE              2
                 90 LOAD_CONST               0 (None)
                 92 LOAD_CONST               0 (None)
                 94 BUILD_SLICE              2
                 96 LOAD_CONST               0 (None)
                 98 LOAD_FAST                1 (block_size)
                100 BUILD_SLICE              2
                102 LOAD_CONST               0 (None)
                104 LOAD_FAST                1 (block_size)
                106 BUILD_SLICE              2
                108 BUILD_TUPLE              4
                110 BINARY_SUBSCR
                112 LOAD_FAST                2 (block)
                114 LOAD_ATTR                9 (attn)
                116 STORE_ATTR              10 (bias)
            >>  118 JUMP_ABSOLUTE           31 (to 62)
    
    202     >>  120 LOAD_CONST               0 (None)
                122 RETURN_VALUE
    
    Disassembly of <code object from_pretrained at 0x000002159E131C60, file "Code Analysis/gpt2sample.py", line 206>:
    208           0 LOAD_FAST                1 (model_type)
                  2 LOAD_CONST               1 (frozenset({'gpt2-medium', 'gpt2-xl', 'gpt2-large', 'gpt2'}))
                  4 CONTAINS_OP              0
                  6 POP_JUMP_IF_TRUE         6 (to 12)
                  8 LOAD_ASSERTION_ERROR
                 10 RAISE_VARARGS            1
    
    209     >>   12 LOAD_FAST                2 (override_args)
                 14 JUMP_IF_TRUE_OR_POP      9 (to 18)
                 16 BUILD_MAP                0
            >>   18 STORE_FAST               2 (override_args)
    
    211          20 LOAD_GLOBAL              0 (all)
                 22 LOAD_CONST               2 (<code object <genexpr> at 0x000002159E1318F0, file "Code Analysis/gpt2sample.py", line 211>)
                 24 LOAD_CONST               3 ('GPT.from_pretrained.<locals>.<genexpr>')
                 26 MAKE_FUNCTION            0
                 28 LOAD_FAST                2 (override_args)
                 30 GET_ITER
                 32 CALL_FUNCTION            1
                 34 CALL_FUNCTION            1
                 36 POP_JUMP_IF_TRUE        21 (to 42)
                 38 LOAD_ASSERTION_ERROR
                 40 RAISE_VARARGS            1
    
    212     >>   42 LOAD_CONST               4 (0)
                 44 LOAD_CONST               5 (('GPT2LMHeadModel',))
                 46 IMPORT_NAME              1 (transformers)
                 48 IMPORT_FROM              2 (GPT2LMHeadModel)
                 50 STORE_FAST               3 (GPT2LMHeadModel)
                 52 POP_TOP
    
    213          54 LOAD_GLOBAL              3 (print)
                 56 LOAD_CONST               6 ('loading weights from pretrained gpt: %s')
                 58 LOAD_FAST                1 (model_type)
                 60 BINARY_MODULO
                 62 CALL_FUNCTION            1
                 64 POP_TOP
    
    217          66 LOAD_GLOBAL              4 (dict)
                 68 LOAD_CONST               7 (12)
                 70 LOAD_CONST               7 (12)
                 72 LOAD_CONST               8 (768)
                 74 LOAD_CONST               9 (('n_layer', 'n_head', 'n_embd'))
                 76 CALL_FUNCTION_KW         3
    
    218          78 LOAD_GLOBAL              4 (dict)
                 80 LOAD_CONST              10 (24)
                 82 LOAD_CONST              11 (16)
                 84 LOAD_CONST              12 (1024)
                 86 LOAD_CONST               9 (('n_layer', 'n_head', 'n_embd'))
                 88 CALL_FUNCTION_KW         3
    
    219          90 LOAD_GLOBAL              4 (dict)
                 92 LOAD_CONST              13 (36)
                 94 LOAD_CONST              14 (20)
                 96 LOAD_CONST              15 (1280)
                 98 LOAD_CONST               9 (('n_layer', 'n_head', 'n_embd'))
                100 CALL_FUNCTION_KW         3
    
    220         102 LOAD_GLOBAL              4 (dict)
                104 LOAD_CONST              16 (48)
                106 LOAD_CONST              17 (25)
                108 LOAD_CONST              18 (1600)
                110 LOAD_CONST               9 (('n_layer', 'n_head', 'n_embd'))
                112 CALL_FUNCTION_KW         3
    
    216         114 LOAD_CONST              19 (('gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'))
                116 BUILD_CONST_KEY_MAP      4
    
    221         118 LOAD_FAST                1 (model_type)
    
    216         120 BINARY_SUBSCR
                122 STORE_FAST               4 (config_args)
    
    222         124 LOAD_GLOBAL              3 (print)
                126 LOAD_CONST              20 ('forcing vocab_size=50257, block_size=1024, bias=True')
                128 CALL_FUNCTION            1
                130 POP_TOP
    
    223         132 LOAD_CONST              21 (50257)
                134 LOAD_FAST                4 (config_args)
                136 LOAD_CONST              22 ('vocab_size')
                138 STORE_SUBSCR
    
    224         140 LOAD_CONST              12 (1024)
                142 LOAD_FAST                4 (config_args)
                144 LOAD_CONST              23 ('block_size')
                146 STORE_SUBSCR
    
    225         148 LOAD_CONST              24 (True)
                150 LOAD_FAST                4 (config_args)
                152 LOAD_CONST              25 ('bias')
                154 STORE_SUBSCR
    
    227         156 LOAD_CONST              26 ('dropout')
                158 LOAD_FAST                2 (override_args)
                160 CONTAINS_OP              0
                162 POP_JUMP_IF_FALSE       97 (to 194)
    
    228         164 LOAD_GLOBAL              3 (print)
                166 LOAD_CONST              27 ('overriding dropout rate to ')
                168 LOAD_FAST                2 (override_args)
                170 LOAD_CONST              26 ('dropout')
                172 BINARY_SUBSCR
                174 FORMAT_VALUE             0
                176 BUILD_STRING             2
                178 CALL_FUNCTION            1
                180 POP_TOP
    
    229         182 LOAD_FAST                2 (override_args)
                184 LOAD_CONST              26 ('dropout')
                186 BINARY_SUBSCR
                188 LOAD_FAST                4 (config_args)
                190 LOAD_CONST              26 ('dropout')
                192 STORE_SUBSCR
    
    231     >>  194 LOAD_GLOBAL              5 (GPTConfig)
                196 LOAD_CONST              37 (())
                198 BUILD_MAP                0
                200 LOAD_FAST                4 (config_args)
                202 DICT_MERGE               1
                204 CALL_FUNCTION_EX         1
                206 STORE_FAST               5 (config)
    
    232         208 LOAD_GLOBAL              6 (GPT)
                210 LOAD_FAST                5 (config)
                212 CALL_FUNCTION            1
                214 STORE_FAST               6 (model)
    
    233         216 LOAD_FAST                6 (model)
                218 LOAD_METHOD              7 (state_dict)
                220 CALL_METHOD              0
                222 STORE_FAST               7 (sd)
    
    234         224 LOAD_FAST                7 (sd)
                226 LOAD_METHOD              8 (keys)
                228 CALL_METHOD              0
                230 STORE_FAST               8 (sd_keys)
    
    235         232 LOAD_CONST              28 (<code object <listcomp> at 0x000002159E1319A0, file "Code Analysis/gpt2sample.py", line 235>)
                234 LOAD_CONST              29 ('GPT.from_pretrained.<locals>.<listcomp>')
                236 MAKE_FUNCTION            0
                238 LOAD_FAST                8 (sd_keys)
                240 GET_ITER
                242 CALL_FUNCTION            1
                244 STORE_FAST               8 (sd_keys)
    
    238         246 LOAD_FAST                3 (GPT2LMHeadModel)
                248 LOAD_METHOD              9 (from_pretrained)
                250 LOAD_FAST                1 (model_type)
                252 CALL_METHOD              1
                254 STORE_FAST               9 (model_hf)
    
    239         256 LOAD_FAST                9 (model_hf)
                258 LOAD_METHOD              7 (state_dict)
                260 CALL_METHOD              0
                262 STORE_FAST              10 (sd_hf)
    
    242         264 LOAD_FAST               10 (sd_hf)
                266 LOAD_METHOD              8 (keys)
                268 CALL_METHOD              0
                270 STORE_FAST              11 (sd_keys_hf)
    
    243         272 LOAD_CONST              30 (<code object <listcomp> at 0x000002159E131A50, file "Code Analysis/gpt2sample.py", line 243>)
                274 LOAD_CONST              29 ('GPT.from_pretrained.<locals>.<listcomp>')
                276 MAKE_FUNCTION            0
                278 LOAD_FAST               11 (sd_keys_hf)
                280 GET_ITER
                282 CALL_FUNCTION            1
                284 STORE_FAST              11 (sd_keys_hf)
    
    244         286 LOAD_CONST              31 (<code object <listcomp> at 0x000002159E131B00, file "Code Analysis/gpt2sample.py", line 244>)
                288 LOAD_CONST              29 ('GPT.from_pretrained.<locals>.<listcomp>')
                290 MAKE_FUNCTION            0
                292 LOAD_FAST               11 (sd_keys_hf)
                294 GET_ITER
                296 CALL_FUNCTION            1
                298 STORE_FAST              11 (sd_keys_hf)
    
    245         300 BUILD_LIST               0
                302 LOAD_CONST              32 (('attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight'))
                304 LIST_EXTEND              1
                306 STORE_FAST              12 (transposed)
    
    248         308 LOAD_GLOBAL             10 (len)
                310 LOAD_FAST               11 (sd_keys_hf)
                312 CALL_FUNCTION            1
                314 LOAD_GLOBAL             10 (len)
                316 LOAD_FAST                8 (sd_keys)
                318 CALL_FUNCTION            1
                320 COMPARE_OP               2 (==)
                322 POP_JUMP_IF_TRUE       176 (to 352)
                324 LOAD_ASSERTION_ERROR
                326 LOAD_CONST              33 ('mismatched keys: ')
                328 LOAD_GLOBAL             10 (len)
                330 LOAD_FAST               11 (sd_keys_hf)
                332 CALL_FUNCTION            1
                334 FORMAT_VALUE             0
                336 LOAD_CONST              34 (' != ')
                338 LOAD_GLOBAL             10 (len)
                340 LOAD_FAST                8 (sd_keys)
                342 CALL_FUNCTION            1
                344 FORMAT_VALUE             0
                346 BUILD_STRING             4
                348 CALL_FUNCTION            1
                350 RAISE_VARARGS            1
    
    249     >>  352 LOAD_FAST               11 (sd_keys_hf)
                354 GET_ITER
            >>  356 FOR_ITER               104 (to 566)
                358 STORE_DEREF              0 (k)
    
    250         360 LOAD_GLOBAL             11 (any)
                362 LOAD_CLOSURE             0 (k)
                364 BUILD_TUPLE              1
                366 LOAD_CONST              35 (<code object <genexpr> at 0x000002159E131BB0, file "Code Analysis/gpt2sample.py", line 250>)
                368 LOAD_CONST               3 ('GPT.from_pretrained.<locals>.<genexpr>')
                370 MAKE_FUNCTION            8 (closure)
                372 LOAD_FAST               12 (transposed)
                374 GET_ITER
                376 CALL_FUNCTION            1
                378 CALL_FUNCTION            1
                380 POP_JUMP_IF_FALSE      240 (to 480)
    
    252         382 LOAD_FAST               10 (sd_hf)
                384 LOAD_DEREF               0 (k)
                386 BINARY_SUBSCR
                388 LOAD_ATTR               12 (shape)
                390 LOAD_CONST               0 (None)
                392 LOAD_CONST               0 (None)
                394 LOAD_CONST              36 (-1)
                396 BUILD_SLICE              3
                398 BINARY_SUBSCR
                400 LOAD_FAST                7 (sd)
                402 LOAD_DEREF               0 (k)
                404 BINARY_SUBSCR
                406 LOAD_ATTR               12 (shape)
                408 COMPARE_OP               2 (==)
                410 POP_JUMP_IF_TRUE       208 (to 416)
                412 LOAD_ASSERTION_ERROR
                414 RAISE_VARARGS            1
    
    253     >>  416 LOAD_GLOBAL             13 (torch)
                418 LOAD_METHOD             14 (no_grad)
                420 CALL_METHOD              0
                422 SETUP_WITH              19 (to 462)
                424 POP_TOP
    
    254         426 LOAD_FAST                7 (sd)
                428 LOAD_DEREF               0 (k)
                430 BINARY_SUBSCR
                432 LOAD_METHOD             15 (copy_)
                434 LOAD_FAST               10 (sd_hf)
                436 LOAD_DEREF               0 (k)
                438 BINARY_SUBSCR
                440 LOAD_METHOD             16 (t)
                442 CALL_METHOD              0
                444 CALL_METHOD              1
                446 POP_TOP
                448 POP_BLOCK
    
    253         450 LOAD_CONST               0 (None)
                452 DUP_TOP
                454 DUP_TOP
                456 CALL_FUNCTION            3
                458 POP_TOP
                460 JUMP_FORWARD             8 (to 478)
            >>  462 WITH_EXCEPT_START
                464 POP_JUMP_IF_TRUE       234 (to 468)
                466 RERAISE                  1
            >>  468 POP_TOP
                470 POP_TOP
                472 POP_TOP
                474 POP_EXCEPT
                476 POP_TOP
            >>  478 JUMP_ABSOLUTE          178 (to 356)
    
    257     >>  480 LOAD_FAST               10 (sd_hf)
                482 LOAD_DEREF               0 (k)
                484 BINARY_SUBSCR
                486 LOAD_ATTR               12 (shape)
                488 LOAD_FAST                7 (sd)
                490 LOAD_DEREF               0 (k)
                492 BINARY_SUBSCR
                494 LOAD_ATTR               12 (shape)
                496 COMPARE_OP               2 (==)
                498 POP_JUMP_IF_TRUE       252 (to 504)
                500 LOAD_ASSERTION_ERROR
                502 RAISE_VARARGS            1
    
    258     >>  504 LOAD_GLOBAL             13 (torch)
                506 LOAD_METHOD             14 (no_grad)
                508 CALL_METHOD              0
                510 SETUP_WITH              17 (to 546)
                512 POP_TOP
    
    259         514 LOAD_FAST                7 (sd)
                516 LOAD_DEREF               0 (k)
                518 BINARY_SUBSCR
                520 LOAD_METHOD             15 (copy_)
                522 LOAD_FAST               10 (sd_hf)
                524 LOAD_DEREF               0 (k)
                526 BINARY_SUBSCR
                528 CALL_METHOD              1
                530 POP_TOP
                532 POP_BLOCK
    
    258         534 LOAD_CONST               0 (None)
                536 DUP_TOP
                538 DUP_TOP
                540 CALL_FUNCTION            3
                542 POP_TOP
                544 JUMP_FORWARD             9 (to 564)
            >>  546 WITH_EXCEPT_START
                548 EXTENDED_ARG             1
                550 POP_JUMP_IF_TRUE       277 (to 554)
                552 RERAISE                  1
            >>  554 POP_TOP
                556 POP_TOP
                558 POP_TOP
                560 POP_EXCEPT
                562 POP_TOP
            >>  564 JUMP_ABSOLUTE          178 (to 356)
    
    261     >>  566 LOAD_FAST                6 (model)
                568 RETURN_VALUE
    
    Disassembly of <code object <genexpr> at 0x000002159E1318F0, file "Code Analysis/gpt2sample.py", line 211>:
                  0 GEN_START                0
    
    211           2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 7 (to 20)
                  6 STORE_FAST               1 (k)
                  8 LOAD_FAST                1 (k)
                 10 LOAD_CONST               0 ('dropout')
                 12 COMPARE_OP               2 (==)
                 14 YIELD_VALUE
                 16 POP_TOP
                 18 JUMP_ABSOLUTE            2 (to 4)
            >>   20 LOAD_CONST               1 (None)
                 22 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E1319A0, file "Code Analysis/gpt2sample.py", line 235>:
    235           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 9 (to 24)
                  6 STORE_FAST               1 (k)
                  8 LOAD_FAST                1 (k)
                 10 LOAD_METHOD              0 (endswith)
                 12 LOAD_CONST               0 ('.attn.bias')
                 14 CALL_METHOD              1
                 16 POP_JUMP_IF_TRUE         2 (to 4)
                 18 LOAD_FAST                1 (k)
                 20 LIST_APPEND              2
                 22 JUMP_ABSOLUTE            2 (to 4)
            >>   24 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E131A50, file "Code Analysis/gpt2sample.py", line 243>:
    243           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 9 (to 24)
                  6 STORE_FAST               1 (k)
                  8 LOAD_FAST                1 (k)
                 10 LOAD_METHOD              0 (endswith)
                 12 LOAD_CONST               0 ('.attn.masked_bias')
                 14 CALL_METHOD              1
                 16 POP_JUMP_IF_TRUE         2 (to 4)
                 18 LOAD_FAST                1 (k)
                 20 LIST_APPEND              2
                 22 JUMP_ABSOLUTE            2 (to 4)
            >>   24 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E131B00, file "Code Analysis/gpt2sample.py", line 244>:
    244           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 9 (to 24)
                  6 STORE_FAST               1 (k)
                  8 LOAD_FAST                1 (k)
                 10 LOAD_METHOD              0 (endswith)
                 12 LOAD_CONST               0 ('.attn.bias')
                 14 CALL_METHOD              1
                 16 POP_JUMP_IF_TRUE         2 (to 4)
                 18 LOAD_FAST                1 (k)
                 20 LIST_APPEND              2
                 22 JUMP_ABSOLUTE            2 (to 4)
            >>   24 RETURN_VALUE
    
    Disassembly of <code object <genexpr> at 0x000002159E131BB0, file "Code Analysis/gpt2sample.py", line 250>:
                  0 GEN_START                0
    
    250           2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 8 (to 22)
                  6 STORE_FAST               1 (w)
                  8 LOAD_DEREF               0 (k)
                 10 LOAD_METHOD              0 (endswith)
                 12 LOAD_FAST                1 (w)
                 14 CALL_METHOD              1
                 16 YIELD_VALUE
                 18 POP_TOP
                 20 JUMP_ABSOLUTE            2 (to 4)
            >>   22 LOAD_CONST               0 (None)
                 24 RETURN_VALUE
    
    Disassembly of <code object configure_optimizers at 0x000002159E132130, file "Code Analysis/gpt2sample.py", line 263>:
    265           0 LOAD_CONST               1 (<code object <dictcomp> at 0x000002159E131D10, file "Code Analysis/gpt2sample.py", line 265>)
                  2 LOAD_CONST               2 ('GPT.configure_optimizers.<locals>.<dictcomp>')
                  4 MAKE_FUNCTION            0
                  6 LOAD_FAST                0 (self)
                  8 LOAD_METHOD              0 (named_parameters)
                 10 CALL_METHOD              0
                 12 GET_ITER
                 14 CALL_FUNCTION            1
                 16 STORE_FAST               5 (param_dict)
    
    267          18 LOAD_CONST               3 (<code object <dictcomp> at 0x000002159E131DC0, file "Code Analysis/gpt2sample.py", line 267>)
                 20 LOAD_CONST               2 ('GPT.configure_optimizers.<locals>.<dictcomp>')
                 22 MAKE_FUNCTION            0
                 24 LOAD_FAST                5 (param_dict)
                 26 LOAD_METHOD              1 (items)
                 28 CALL_METHOD              0
                 30 GET_ITER
                 32 CALL_FUNCTION            1
                 34 STORE_FAST               5 (param_dict)
    
    270          36 LOAD_CONST               4 (<code object <listcomp> at 0x000002159E131E70, file "Code Analysis/gpt2sample.py", line 270>)
                 38 LOAD_CONST               5 ('GPT.configure_optimizers.<locals>.<listcomp>')
                 40 MAKE_FUNCTION            0
                 42 LOAD_FAST                5 (param_dict)
                 44 LOAD_METHOD              1 (items)
                 46 CALL_METHOD              0
                 48 GET_ITER
                 50 CALL_FUNCTION            1
                 52 STORE_FAST               6 (decay_params)
    
    271          54 LOAD_CONST               6 (<code object <listcomp> at 0x000002159E131F20, file "Code Analysis/gpt2sample.py", line 271>)
                 56 LOAD_CONST               5 ('GPT.configure_optimizers.<locals>.<listcomp>')
                 58 MAKE_FUNCTION            0
                 60 LOAD_FAST                5 (param_dict)
                 62 LOAD_METHOD              1 (items)
                 64 CALL_METHOD              0
                 66 GET_ITER
                 68 CALL_FUNCTION            1
                 70 STORE_FAST               7 (nodecay_params)
    
    273          72 LOAD_FAST                6 (decay_params)
                 74 LOAD_FAST                1 (weight_decay)
                 76 LOAD_CONST               7 (('params', 'weight_decay'))
                 78 BUILD_CONST_KEY_MAP      2
    
    274          80 LOAD_FAST                7 (nodecay_params)
                 82 LOAD_CONST               8 (0.0)
                 84 LOAD_CONST               7 (('params', 'weight_decay'))
                 86 BUILD_CONST_KEY_MAP      2
    
    272          88 BUILD_LIST               2
                 90 STORE_FAST               8 (optim_groups)
    
    276          92 LOAD_GLOBAL              2 (sum)
                 94 LOAD_CONST               9 (<code object <genexpr> at 0x000002159E131FD0, file "Code Analysis/gpt2sample.py", line 276>)
                 96 LOAD_CONST              10 ('GPT.configure_optimizers.<locals>.<genexpr>')
                 98 MAKE_FUNCTION            0
                100 LOAD_FAST                6 (decay_params)
                102 GET_ITER
                104 CALL_FUNCTION            1
                106 CALL_FUNCTION            1
                108 STORE_FAST               9 (num_decay_params)
    
    277         110 LOAD_GLOBAL              2 (sum)
                112 LOAD_CONST              11 (<code object <genexpr> at 0x000002159E132080, file "Code Analysis/gpt2sample.py", line 277>)
                114 LOAD_CONST              10 ('GPT.configure_optimizers.<locals>.<genexpr>')
                116 MAKE_FUNCTION            0
                118 LOAD_FAST                7 (nodecay_params)
                120 GET_ITER
                122 CALL_FUNCTION            1
                124 CALL_FUNCTION            1
                126 STORE_FAST              10 (num_nodecay_params)
    
    278         128 LOAD_GLOBAL              3 (print)
                130 LOAD_CONST              12 ('num decayed parameter tensors: ')
                132 LOAD_GLOBAL              4 (len)
                134 LOAD_FAST                6 (decay_params)
                136 CALL_FUNCTION            1
                138 FORMAT_VALUE             0
                140 LOAD_CONST              13 (', with ')
                142 LOAD_FAST                9 (num_decay_params)
                144 LOAD_CONST              14 (',')
                146 FORMAT_VALUE             4 (with format)
                148 LOAD_CONST              15 (' parameters')
                150 BUILD_STRING             5
                152 CALL_FUNCTION            1
                154 POP_TOP
    
    279         156 LOAD_GLOBAL              3 (print)
                158 LOAD_CONST              16 ('num non-decayed parameter tensors: ')
                160 LOAD_GLOBAL              4 (len)
                162 LOAD_FAST                7 (nodecay_params)
                164 CALL_FUNCTION            1
                166 FORMAT_VALUE             0
                168 LOAD_CONST              13 (', with ')
                170 LOAD_FAST               10 (num_nodecay_params)
                172 LOAD_CONST              14 (',')
                174 FORMAT_VALUE             4 (with format)
                176 LOAD_CONST              15 (' parameters')
                178 BUILD_STRING             5
                180 CALL_FUNCTION            1
                182 POP_TOP
    
    281         184 LOAD_CONST              17 ('fused')
                186 LOAD_GLOBAL              5 (inspect)
                188 LOAD_METHOD              6 (signature)
                190 LOAD_GLOBAL              7 (torch)
                192 LOAD_ATTR                8 (optim)
                194 LOAD_ATTR                9 (AdamW)
                196 CALL_METHOD              1
                198 LOAD_ATTR               10 (parameters)
                200 CONTAINS_OP              0
                202 STORE_FAST              11 (fused_available)
    
    282         204 LOAD_FAST               11 (fused_available)
                206 JUMP_IF_FALSE_OR_POP   107 (to 214)
                208 LOAD_FAST                4 (device_type)
                210 LOAD_CONST              18 ('cuda')
                212 COMPARE_OP               2 (==)
            >>  214 STORE_FAST              12 (use_fused)
    
    283         216 LOAD_FAST               12 (use_fused)
                218 POP_JUMP_IF_FALSE      115 (to 230)
                220 LOAD_GLOBAL             11 (dict)
                222 LOAD_CONST              19 (True)
                224 LOAD_CONST              20 (('fused',))
                226 CALL_FUNCTION_KW         1
                228 JUMP_FORWARD             2 (to 234)
            >>  230 LOAD_GLOBAL             11 (dict)
                232 CALL_FUNCTION            0
            >>  234 STORE_FAST              13 (extra_args)
    
    284         236 LOAD_GLOBAL              7 (torch)
                238 LOAD_ATTR                8 (optim)
                240 LOAD_ATTR                9 (AdamW)
                242 LOAD_FAST                8 (optim_groups)
                244 BUILD_TUPLE              1
                246 LOAD_FAST                2 (learning_rate)
                248 LOAD_FAST                3 (betas)
                250 LOAD_CONST              21 (('lr', 'betas'))
                252 BUILD_CONST_KEY_MAP      2
                254 LOAD_FAST               13 (extra_args)
                256 DICT_MERGE               1
                258 CALL_FUNCTION_EX         1
                260 STORE_FAST              14 (optimizer)
    
    285         262 LOAD_GLOBAL              3 (print)
                264 LOAD_CONST              22 ('using fused AdamW: ')
                266 LOAD_FAST               12 (use_fused)
                268 FORMAT_VALUE             0
                270 BUILD_STRING             2
                272 CALL_FUNCTION            1
                274 POP_TOP
    
    287         276 LOAD_FAST               14 (optimizer)
                278 RETURN_VALUE
    
    Disassembly of <code object <dictcomp> at 0x000002159E131D10, file "Code Analysis/gpt2sample.py", line 265>:
    265           0 BUILD_MAP                0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 7 (to 20)
                  6 UNPACK_SEQUENCE          2
                  8 STORE_FAST               1 (pn)
                 10 STORE_FAST               2 (p)
                 12 LOAD_FAST                1 (pn)
                 14 LOAD_FAST                2 (p)
                 16 MAP_ADD                  2
                 18 JUMP_ABSOLUTE            2 (to 4)
            >>   20 RETURN_VALUE
    
    Disassembly of <code object <dictcomp> at 0x000002159E131DC0, file "Code Analysis/gpt2sample.py", line 267>:
    267           0 BUILD_MAP                0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                10 (to 26)
                  6 UNPACK_SEQUENCE          2
                  8 STORE_FAST               1 (pn)
                 10 STORE_FAST               2 (p)
                 12 LOAD_FAST                2 (p)
                 14 LOAD_ATTR                0 (requires_grad)
                 16 POP_JUMP_IF_FALSE        2 (to 4)
                 18 LOAD_FAST                1 (pn)
                 20 LOAD_FAST                2 (p)
                 22 MAP_ADD                  2
                 24 JUMP_ABSOLUTE            2 (to 4)
            >>   26 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E131E70, file "Code Analysis/gpt2sample.py", line 270>:
    270           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                12 (to 30)
                  6 UNPACK_SEQUENCE          2
                  8 STORE_FAST               1 (n)
                 10 STORE_FAST               2 (p)
                 12 LOAD_FAST                2 (p)
                 14 LOAD_METHOD              0 (dim)
                 16 CALL_METHOD              0
                 18 LOAD_CONST               0 (2)
                 20 COMPARE_OP               5 (>=)
                 22 POP_JUMP_IF_FALSE        2 (to 4)
                 24 LOAD_FAST                2 (p)
                 26 LIST_APPEND              2
                 28 JUMP_ABSOLUTE            2 (to 4)
            >>   30 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E131F20, file "Code Analysis/gpt2sample.py", line 271>:
    271           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                12 (to 30)
                  6 UNPACK_SEQUENCE          2
                  8 STORE_FAST               1 (n)
                 10 STORE_FAST               2 (p)
                 12 LOAD_FAST                2 (p)
                 14 LOAD_METHOD              0 (dim)
                 16 CALL_METHOD              0
                 18 LOAD_CONST               0 (2)
                 20 COMPARE_OP               0 (<)
                 22 POP_JUMP_IF_FALSE        2 (to 4)
                 24 LOAD_FAST                2 (p)
                 26 LIST_APPEND              2
                 28 JUMP_ABSOLUTE            2 (to 4)
            >>   30 RETURN_VALUE
    
    Disassembly of <code object <genexpr> at 0x000002159E131FD0, file "Code Analysis/gpt2sample.py", line 276>:
                  0 GEN_START                0
    
    276           2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 7 (to 20)
                  6 STORE_FAST               1 (p)
                  8 LOAD_FAST                1 (p)
                 10 LOAD_METHOD              0 (numel)
                 12 CALL_METHOD              0
                 14 YIELD_VALUE
                 16 POP_TOP
                 18 JUMP_ABSOLUTE            2 (to 4)
            >>   20 LOAD_CONST               0 (None)
                 22 RETURN_VALUE
    
    Disassembly of <code object <genexpr> at 0x000002159E132080, file "Code Analysis/gpt2sample.py", line 277>:
                  0 GEN_START                0
    
    277           2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 7 (to 20)
                  6 STORE_FAST               1 (p)
                  8 LOAD_FAST                1 (p)
                 10 LOAD_METHOD              0 (numel)
                 12 CALL_METHOD              0
                 14 YIELD_VALUE
                 16 POP_TOP
                 18 JUMP_ABSOLUTE            2 (to 4)
            >>   20 LOAD_CONST               0 (None)
                 22 RETURN_VALUE
    
    Disassembly of <code object estimate_mfu at 0x000002159E1321E0, file "Code Analysis/gpt2sample.py", line 289>:
    293           0 LOAD_FAST                0 (self)
                  2 LOAD_METHOD              0 (get_num_params)
                  4 CALL_METHOD              0
                  6 STORE_FAST               3 (N)
    
    294           8 LOAD_FAST                0 (self)
                 10 LOAD_ATTR                1 (config)
                 12 STORE_FAST               4 (cfg)
    
    295          14 LOAD_FAST                4 (cfg)
                 16 LOAD_ATTR                2 (n_layer)
                 18 LOAD_FAST                4 (cfg)
                 20 LOAD_ATTR                3 (n_head)
                 22 LOAD_FAST                4 (cfg)
                 24 LOAD_ATTR                4 (n_embd)
                 26 LOAD_FAST                4 (cfg)
                 28 LOAD_ATTR                3 (n_head)
                 30 BINARY_FLOOR_DIVIDE
                 32 LOAD_FAST                4 (cfg)
                 34 LOAD_ATTR                5 (block_size)
                 36 BUILD_TUPLE              4
                 38 UNPACK_SEQUENCE          4
                 40 STORE_FAST               5 (L)
                 42 STORE_FAST               6 (H)
                 44 STORE_FAST               7 (Q)
                 46 STORE_FAST               8 (T)
    
    296          48 LOAD_CONST               1 (6)
                 50 LOAD_FAST                3 (N)
                 52 BINARY_MULTIPLY
                 54 LOAD_CONST               2 (12)
                 56 LOAD_FAST                5 (L)
                 58 BINARY_MULTIPLY
                 60 LOAD_FAST                6 (H)
                 62 BINARY_MULTIPLY
                 64 LOAD_FAST                7 (Q)
                 66 BINARY_MULTIPLY
                 68 LOAD_FAST                8 (T)
                 70 BINARY_MULTIPLY
                 72 BINARY_ADD
                 74 STORE_FAST               9 (flops_per_token)
    
    297          76 LOAD_FAST                9 (flops_per_token)
                 78 LOAD_FAST                8 (T)
                 80 BINARY_MULTIPLY
                 82 STORE_FAST              10 (flops_per_fwdbwd)
    
    298          84 LOAD_FAST               10 (flops_per_fwdbwd)
                 86 LOAD_FAST                1 (fwdbwd_per_iter)
                 88 BINARY_MULTIPLY
                 90 STORE_FAST              11 (flops_per_iter)
    
    300          92 LOAD_FAST               11 (flops_per_iter)
                 94 LOAD_CONST               3 (1.0)
                 96 LOAD_FAST                2 (dt)
                 98 BINARY_TRUE_DIVIDE
                100 BINARY_MULTIPLY
                102 STORE_FAST              12 (flops_achieved)
    
    301         104 LOAD_CONST               4 (312000000000000.0)
                106 STORE_FAST              13 (flops_promised)
    
    302         108 LOAD_FAST               12 (flops_achieved)
                110 LOAD_FAST               13 (flops_promised)
                112 BINARY_TRUE_DIVIDE
                114 STORE_FAST              14 (mfu)
    
    303         116 LOAD_FAST               14 (mfu)
                118 RETURN_VALUE
    
    Disassembly of <code object generate at 0x000002159E132290, file "Code Analysis/gpt2sample.py", line 305>:
    312           0 LOAD_GLOBAL              0 (range)
                  2 LOAD_FAST                2 (max_new_tokens)
                  4 CALL_FUNCTION            1
                  6 GET_ITER
            >>    8 FOR_ITER               102 (to 214)
                 10 STORE_FAST               5 (_)
    
    314          12 LOAD_FAST                1 (idx)
                 14 LOAD_METHOD              1 (size)
                 16 LOAD_CONST               1 (1)
                 18 CALL_METHOD              1
                 20 LOAD_FAST                0 (self)
                 22 LOAD_ATTR                2 (config)
                 24 LOAD_ATTR                3 (block_size)
                 26 COMPARE_OP               1 (<=)
                 28 POP_JUMP_IF_FALSE       17 (to 34)
                 30 LOAD_FAST                1 (idx)
                 32 JUMP_FORWARD            12 (to 58)
            >>   34 LOAD_FAST                1 (idx)
                 36 LOAD_CONST               2 (None)
                 38 LOAD_CONST               2 (None)
                 40 BUILD_SLICE              2
                 42 LOAD_FAST                0 (self)
                 44 LOAD_ATTR                2 (config)
                 46 LOAD_ATTR                3 (block_size)
                 48 UNARY_NEGATIVE
                 50 LOAD_CONST               2 (None)
                 52 BUILD_SLICE              2
                 54 BUILD_TUPLE              2
                 56 BINARY_SUBSCR
            >>   58 STORE_FAST               6 (idx_cond)
    
    316          60 LOAD_FAST                0 (self)
                 62 LOAD_FAST                6 (idx_cond)
                 64 CALL_FUNCTION            1
                 66 UNPACK_SEQUENCE          2
                 68 STORE_FAST               7 (logits)
                 70 STORE_FAST               5 (_)
    
    318          72 LOAD_FAST                7 (logits)
                 74 LOAD_CONST               2 (None)
                 76 LOAD_CONST               2 (None)
                 78 BUILD_SLICE              2
                 80 LOAD_CONST               3 (-1)
                 82 LOAD_CONST               2 (None)
                 84 LOAD_CONST               2 (None)
                 86 BUILD_SLICE              2
                 88 BUILD_TUPLE              3
                 90 BINARY_SUBSCR
                 92 LOAD_FAST                3 (temperature)
                 94 BINARY_TRUE_DIVIDE
                 96 STORE_FAST               7 (logits)
    
    320          98 LOAD_FAST                4 (top_k)
                100 LOAD_CONST               2 (None)
                102 IS_OP                    1
                104 POP_JUMP_IF_FALSE       83 (to 166)
    
    321         106 LOAD_GLOBAL              4 (torch)
                108 LOAD_METHOD              5 (topk)
                110 LOAD_FAST                7 (logits)
                112 LOAD_GLOBAL              6 (min)
                114 LOAD_FAST                4 (top_k)
                116 LOAD_FAST                7 (logits)
                118 LOAD_METHOD              1 (size)
                120 LOAD_CONST               3 (-1)
                122 CALL_METHOD              1
                124 CALL_FUNCTION            2
                126 CALL_METHOD              2
                128 UNPACK_SEQUENCE          2
                130 STORE_FAST               8 (v)
                132 STORE_FAST               5 (_)
    
    322         134 LOAD_GLOBAL              7 (float)
                136 LOAD_CONST               4 ('Inf')
                138 CALL_FUNCTION            1
                140 UNARY_NEGATIVE
                142 LOAD_FAST                7 (logits)
                144 LOAD_FAST                7 (logits)
                146 LOAD_FAST                8 (v)
                148 LOAD_CONST               2 (None)
                150 LOAD_CONST               2 (None)
                152 BUILD_SLICE              2
                154 LOAD_CONST               3 (-1)
                156 BUILD_LIST               1
                158 BUILD_TUPLE              2
                160 BINARY_SUBSCR
                162 COMPARE_OP               0 (<)
                164 STORE_SUBSCR
    
    324     >>  166 LOAD_GLOBAL              8 (F)
                168 LOAD_ATTR                9 (softmax)
                170 LOAD_FAST                7 (logits)
                172 LOAD_CONST               3 (-1)
                174 LOAD_CONST               5 (('dim',))
                176 CALL_FUNCTION_KW         2
                178 STORE_FAST               9 (probs)
    
    326         180 LOAD_GLOBAL              4 (torch)
                182 LOAD_ATTR               10 (multinomial)
                184 LOAD_FAST                9 (probs)
                186 LOAD_CONST               1 (1)
                188 LOAD_CONST               6 (('num_samples',))
                190 CALL_FUNCTION_KW         2
                192 STORE_FAST              10 (idx_next)
    
    328         194 LOAD_GLOBAL              4 (torch)
                196 LOAD_ATTR               11 (cat)
                198 LOAD_FAST                1 (idx)
                200 LOAD_FAST               10 (idx_next)
                202 BUILD_TUPLE              2
                204 LOAD_CONST               1 (1)
                206 LOAD_CONST               5 (('dim',))
                208 CALL_FUNCTION_KW         2
                210 STORE_FAST               1 (idx)
                212 JUMP_ABSOLUTE            4 (to 8)
    
    330     >>  214 LOAD_FAST                1 (idx)
                216 RETURN_VALUE
    
    Disassembly of <code object <lambda> at 0x000002159E1324A0, file "Code Analysis/gpt2sample.py", line 389>:
    389           0 LOAD_CONST               1 (<code object <listcomp> at 0x000002159E1323F0, file "Code Analysis/gpt2sample.py", line 389>)
                  2 LOAD_CONST               2 ('<lambda>.<locals>.<listcomp>')
                  4 MAKE_FUNCTION            0
                  6 LOAD_FAST                0 (s)
                  8 GET_ITER
                 10 CALL_FUNCTION            1
                 12 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E1323F0, file "Code Analysis/gpt2sample.py", line 389>:
    389           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 6 (to 18)
                  6 STORE_FAST               1 (c)
                  8 LOAD_GLOBAL              0 (stoi)
                 10 LOAD_FAST                1 (c)
                 12 BINARY_SUBSCR
                 14 LIST_APPEND              2
                 16 JUMP_ABSOLUTE            2 (to 4)
            >>   18 RETURN_VALUE
    
    Disassembly of <code object <lambda> at 0x000002159E132600, file "Code Analysis/gpt2sample.py", line 390>:
    390           0 LOAD_CONST               1 ('')
                  2 LOAD_METHOD              0 (join)
                  4 LOAD_CONST               2 (<code object <listcomp> at 0x000002159E132550, file "Code Analysis/gpt2sample.py", line 390>)
                  6 LOAD_CONST               3 ('<lambda>.<locals>.<listcomp>')
                  8 MAKE_FUNCTION            0
                 10 LOAD_FAST                0 (l)
                 12 GET_ITER
                 14 CALL_FUNCTION            1
                 16 CALL_METHOD              1
                 18 RETURN_VALUE
    
    Disassembly of <code object <listcomp> at 0x000002159E132550, file "Code Analysis/gpt2sample.py", line 390>:
    390           0 BUILD_LIST               0
                  2 LOAD_FAST                0 (.0)
            >>    4 FOR_ITER                 6 (to 18)
                  6 STORE_FAST               1 (i)
                  8 LOAD_GLOBAL              0 (itos)
                 10 LOAD_FAST                1 (i)
                 12 BINARY_SUBSCR
                 14 LIST_APPEND              2
                 16 JUMP_ABSOLUTE            2 (to 4)
            >>   18 RETURN_VALUE
    
    Disassembly of <code object <lambda> at 0x000002159E1326B0, file "Code Analysis/gpt2sample.py", line 395>:
    395           0 LOAD_GLOBAL              0 (enc)
                  2 LOAD_ATTR                1 (encode)
                  4 LOAD_FAST                0 (s)
                  6 LOAD_CONST               1 ('<|endoftext|>')
                  8 BUILD_SET                1
                 10 LOAD_CONST               2 (('allowed_special',))
                 12 CALL_FUNCTION_KW         2
                 14 RETURN_VALUE
    
    Disassembly of <code object <lambda> at 0x000002159E132760, file "Code Analysis/gpt2sample.py", line 396>:
    396           0 LOAD_GLOBAL              0 (enc)
                  2 LOAD_METHOD              1 (decode)
                  4 LOAD_FAST                0 (l)
                  6 CALL_METHOD              1
                  8 RETURN_VALUE
    

To better understand the computational structure of the model, I analyzed the Python bytecode using dis.get_instructions(). This breakdown helps reveal the frequency and types of operations that Python executes during inference. 


```python
import collections
# Count instructions
counter = collections.Counter()
for instr in dis.get_instructions(code):
    counter[instr.opname] += 1

# Print results
for opname, count in counter.most_common():
    print(f"{opname:20s}: {count}")
```

    LOAD_CONST          : 105
    LOAD_NAME           : 94
    STORE_NAME          : 56
    POP_TOP             : 33
    LOAD_ATTR           : 25
    CALL_FUNCTION       : 21
    LOAD_METHOD         : 21
    CALL_METHOD         : 21
    POP_JUMP_IF_FALSE   : 13
    EXTENDED_ARG        : 12
    BINARY_SUBSCR       : 11
    MAKE_FUNCTION       : 10
    DUP_TOP             : 10
    JUMP_FORWARD        : 8
    IMPORT_NAME         : 7
    LOAD_BUILD_CLASS    : 6
    CALL_FUNCTION_KW    : 6
    POP_BLOCK           : 5
    SETUP_WITH          : 4
    WITH_EXCEPT_START   : 4
    POP_JUMP_IF_TRUE    : 4
    RERAISE             : 4
    POP_EXCEPT          : 4
    IMPORT_FROM         : 3
    CONTAINS_OP         : 3
    COMPARE_OP          : 3
    RETURN_VALUE        : 3
    STORE_ATTR          : 2
    GET_ITER            : 2
    FOR_ITER            : 2
    BUILD_SLICE         : 2
    JUMP_ABSOLUTE       : 2
    BUILD_CONST_KEY_MAP : 1
    BUILD_MAP           : 1
    DICT_MERGE          : 1
    CALL_FUNCTION_EX    : 1
    UNPACK_SEQUENCE     : 1
    STORE_SUBSCR        : 1
    FORMAT_VALUE        : 1
    BUILD_STRING        : 1
    ROT_TWO             : 1
    

Similar to our previous analyses of other types of code, we again observe that memory access operations (like LOAD_CONST, LOAD_NAME) and function calls (CALL_FUNCTION, CALL_METHOD) dominate the instruction profile.

To further investigate the runtime behavior, I tried to use cProfile  with snakeviz to generate a visual breakdown of function-level execution timing. This profiling would help me to identify which parts of the code consume the most processing time, allowing me to target those segments for future optimization during hardware deployment.



```python
import subprocess
import sys

subprocess.check_call([sys.executable, "-m", "pip", "install", "snakeviz"])
```




    0



I restated the above code in a separate file, gpt2sample.py, located in the Code_Analysis folder. This allows us to run cProfile on it and generate detailed performance insights.


```python

import cProfile
from Code_Analysis import gpt2sample

cProfile.run('gpt2sample.main()', filename='profile_output.prof')


```

    c:\Users\15360\anaconda3\envs\nanoGPT\lib\site-packages\tqdm\auto.py:21: TqdmWarning: IProgress not found. Please update jupyter and ipywidgets. See https://ipywidgets.readthedocs.io/en/stable/user_install.html
      from .autonotebook import tqdm as notebook_tqdm
    

    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    


```python
import pstats

p = pstats.Stats('profile_output.prof')
p.strip_dirs().sort_stats('cumulative').print_stats(20)
```

    Sat Apr 19 21:39:35 2025    profile_output.prof
    
             5139763 function calls (4839702 primitive calls) in 18.753 seconds
    
       Ordered by: cumulative time
       List reduced from 8160 to 20 due to restriction <20>
    
       ncalls  tottime  percall  cumtime  percall filename:lineno(function)
       3695/1    0.144    0.000   18.757   18.757 {built-in method builtins.exec}
            1    0.047    0.047   18.757   18.757 gpt2sample.py:331(main)
          457    0.012    0.000   12.949    0.028 __init__.py:1(<module>)
            6    0.000    0.000    9.478    1.580 _contextlib.py:113(decorate_context)
            5    0.290    0.058    9.458    1.892 gpt2sample.py:305(generate)
    75000/500    0.091    0.000    8.868    0.018 module.py:1732(_wrapped_call_impl)
    75000/500    0.148    0.000    8.866    0.018 module.py:1740(_call_impl)
          500    3.362    0.007    8.860    0.018 gpt2sample.py:170(forward)
            1    0.002    0.002    7.903    7.903 gpt2sample.py:206(from_pretrained)
       4509/6    0.025    0.000    5.879    0.980 <frozen importlib._bootstrap>:1022(_find_and_load)
       1800/6    0.009    0.000    5.878    0.980 <frozen importlib._bootstrap>:987(_find_and_load_unlocked)
       1739/6    0.009    0.000    5.876    0.979 <frozen importlib._bootstrap>:664(_load_unlocked)
       1715/6    0.006    0.000    5.875    0.979 <frozen importlib._bootstrap_external>:877(exec_module)
       2345/6    0.002    0.000    5.869    0.978 <frozen importlib._bootstrap>:233(_call_with_frames_removed)
      1903/20    0.005    0.000    5.761    0.288 <frozen importlib._bootstrap>:1053(_handle_fromlist)
    45722/7562    0.018    0.000    5.480    0.001 {built-in method builtins.hasattr}
      2734/27    0.002    0.000    5.478    0.203 __init__.py:108(import_module)
      2736/27    0.002    0.000    5.478    0.203 <frozen importlib._bootstrap>:1038(_gcd_import)
         6000    0.273    0.000    5.270    0.001 gpt2sample.py:103(forward)
         28/1    0.000    0.000    4.735    4.735 import_utils.py:1938(__getattr__)
    
    
    




    <pstats.Stats at 0x1bb72f0ae60>



From the cProfile output analysis, I found that the functions main, generate, forward, and from_pretrained consumed most of the execution time. The time cost of main is expected, as it just the entire runtime of the script. The generate function acts like a sub-main for each inference, and since I run 5 samples, it gets executed 5 times. So they are not the key target for my profile.

The forward function is particularly revealing in the profiling results. Although each call is fast, it is called repeatedly in deep loops within the model — making it a critical bottleneck for performance. So I think the whole model interence can be worth to accelerate in Hardware, if I can.

Surprisingly, the from_pretrained function, responsible for loading the model, also accounts for a significant portion of the total execution time. This suggests that model loading could be another key area for optimization.





```python
import subprocess
# Step 2: Launch Snakeviz using subprocess
subprocess.run(["snakeviz", "profile_output.prof"])

```


```python
from IPython.display import Image

Image(filename="gpt2sampleTimer.png")
```




    
![png](Transformer_files/Transformer_28_0.png)
    



I found that SnakeViz, while helpful for visualizing the overall function call timing, doesn't provide enough detials. Since my code relies heavily on external libraries, SnakeViz only offers high-level information and cannot show more individual lines or internal library calls.

I give the line_profiler a tiral below.


```python
# This notebook demonstrates how to profile the GPT2 model using:
# - viztracer for timeline graph
# - line_profiler for line-level profiling
# - torch.profiler for GPU-level insights
# %%
# Setup
!pip install viztracer line_profiler torchviz --quiet

```


```python
!kernprof -l -v Code_Analysis/gpt2sample.py

```

    The history saving thread hit an unexpected error (OperationalError('database or disk is full')).History will not be written to the database.
    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    Wrote profile results to gpt2sample.py.lprof
    Timer unit: 1e-06 s
    
    Total time: 0.0025259 s
    File: Code_Analysis/gpt2sample.py
    Function: __init__ at line 21
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        21                                               @profile
        22                                               def __init__(self, ndim, bias):
        23        25        444.6     17.8     17.6          super().__init__()
        24        25       1439.5     57.6     57.0          self.weight = nn.Parameter(torch.ones(ndim))
        25        25        641.8     25.7     25.4          self.bias = nn.Parameter(torch.zeros(ndim)) if bias else None
    
    Total time: 0.746379 s
    File: Code_Analysis/gpt2sample.py
    Function: forward at line 26
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        26                                               @profile
        27                                               def forward(self, input):
        28     12500     746379.3     59.7    100.0          return F.layer_norm(input, self.weight.shape, self.weight, self.bias, 1e-5)
    
    Total time: 0.115965 s
    File: Code_Analysis/gpt2sample.py
    Function: __init__ at line 31
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        31                                               @profile
        32                                               def __init__(self, config):
        33        12        161.3     13.4      0.1          super().__init__()
        34        12         12.3      1.0      0.0          assert config.n_embd % config.n_head == 0
        35                                                   # key, query, value projections for all heads, but in a batch
        36        12      84306.4   7025.5     72.7          self.c_attn = nn.Linear(config.n_embd, 3 * config.n_embd, bias=config.bias)
        37                                                   # output projection
        38        12      30276.9   2523.1     26.1          self.c_proj = nn.Linear(config.n_embd, config.n_embd, bias=config.bias)
        39                                                   # regularization
        40        12        537.4     44.8      0.5          self.attn_dropout = nn.Dropout(config.dropout)
        41        12        369.8     30.8      0.3          self.resid_dropout = nn.Dropout(config.dropout)
        42        12         71.5      6.0      0.1          self.n_head = config.n_head
        43        12         67.6      5.6      0.1          self.n_embd = config.n_embd
        44        12         69.2      5.8      0.1          self.dropout = config.dropout
        45                                                   # flash attention make GPU go brrrrr but support is only in PyTorch >= 2.0
        46        12         86.3      7.2      0.1          self.flash = hasattr(torch.nn.functional, 'scaled_dot_product_attention')
        47        12          5.9      0.5      0.0          if not self.flash:
        48                                                       print("WARNING: using slow attention. Flash Attention requires PyTorch >= 2.0")
        49                                                       # causal mask to ensure that attention is only applied to the left in the input sequence
        50                                                       self.register_buffer("bias", torch.tril(torch.ones(config.block_size, config.block_size))
        51                                                                                   .view(1, 1, config.block_size, config.block_size))
    
    Total time: 5.87194 s
    File: Code_Analysis/gpt2sample.py
    Function: forward at line 52
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        52                                               @profile
        53                                               def forward(self, x):
        54      6000      17030.1      2.8      0.3          B, T, C = x.size() # batch size, sequence length, embedding dimensionality (n_embd)
        55                                           
        56                                                   # calculate query, key, values for all heads in batch and move head forward to be the batch dim
        57      6000     896223.3    149.4     15.3          q, k, v  = self.c_attn(x).split(self.n_embd, dim=2)
        58      6000      81217.8     13.5      1.4          k = k.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        59      6000      50874.3      8.5      0.9          q = q.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        60      6000      47152.6      7.9      0.8          v = v.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        61                                           
        62                                                   # causal self-attention; Self-attend: (B, nh, T, hs) x (B, nh, hs, T) -> (B, nh, T, T)
        63      6000       4162.6      0.7      0.1          if self.flash:
        64                                                       # efficient attention using Flash Attention CUDA kernels
        65      6000    3658124.0    609.7     62.3              y = torch.nn.functional.scaled_dot_product_attention(q, k, v, attn_mask=None, dropout_p=self.dropout if self.training else 0, is_causal=True)
        66                                                   else:
        67                                                       # manual implementation of attention
        68                                                       att = (q @ k.transpose(-2, -1)) * (1.0 / math.sqrt(k.size(-1)))
        69                                                       att = att.masked_fill(self.bias[:,:,:T,:T] == 0, float('-inf'))
        70                                                       att = F.softmax(att, dim=-1)
        71                                                       att = self.attn_dropout(att)
        72                                                       y = att @ v # (B, nh, T, T) x (B, nh, T, hs) -> (B, nh, T, hs)
        73      6000     318461.4     53.1      5.4          y = y.transpose(1, 2).contiguous().view(B, T, C) # re-assemble all head outputs side by side
        74                                           
        75                                                   # output projection
        76      6000     795794.3    132.6     13.6          y = self.resid_dropout(self.c_proj(y))
        77      6000       2898.5      0.5      0.0          return y
    
    Total time: 0.225292 s
    File: Code_Analysis/gpt2sample.py
    Function: __init__ at line 80
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        80                                               @profile
        81                                               def __init__(self, config):
        82        12        155.4     13.0      0.1          super().__init__()
        83        12     111609.2   9300.8     49.5          self.c_fc    = nn.Linear(config.n_embd, 4 * config.n_embd, bias=config.bias)
        84        12        486.5     40.5      0.2          self.gelu    = nn.GELU()
        85        12     112434.8   9369.6     49.9          self.c_proj  = nn.Linear(4 * config.n_embd, config.n_embd, bias=config.bias)
        86        12        606.1     50.5      0.3          self.dropout = nn.Dropout(config.dropout)
    
    Total time: 1.6476 s
    File: Code_Analysis/gpt2sample.py
    Function: forward at line 87
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        87                                               @profile
        88                                               def forward(self, x):
        89      6000     714113.7    119.0     43.3          x = self.c_fc(x)
        90      6000     293327.9     48.9     17.8          x = self.gelu(x)
        91      6000     482048.9     80.3     29.3          x = self.c_proj(x)
        92      6000     155614.9     25.9      9.4          x = self.dropout(x)
        93      6000       2490.5      0.4      0.2          return x
    
    Total time: 0.344891 s
    File: Code_Analysis/gpt2sample.py
    Function: __init__ at line 96
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
        96                                               @profile
        97                                               def __init__(self, config):
        98        12        265.9     22.2      0.1          super().__init__()
        99        12       1615.8    134.7      0.5          self.ln_1 = LayerNorm(config.n_embd, bias=config.bias)
       100        12     116264.0   9688.7     33.7          self.attn = CausalSelfAttention(config)
       101        12       1146.7     95.6      0.3          self.ln_2 = LayerNorm(config.n_embd, bias=config.bias)
       102        12     225598.9  18799.9     65.4          self.mlp = MLP(config)
    
    Total time: 9.24137 s
    File: Code_Analysis/gpt2sample.py
    Function: forward at line 103
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       103                                               @profile
       104                                               def forward(self, x):
       105      6000    6734826.8   1122.5     72.9          x = x + self.attn(self.ln_1(x))
       106      6000    2503828.7    417.3     27.1          x = x + self.mlp(self.ln_2(x))
       107      6000       2718.5      0.5      0.0          return x
    
    Total time: 1.58465 s
    File: Code_Analysis/gpt2sample.py
    Function: __init__ at line 120
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       120                                               @profile
       121                                               def __init__(self, config):
       122         1         31.3     31.3      0.0          super().__init__()
       123         1          0.6      0.6      0.0          assert config.vocab_size is not None
       124         1          0.2      0.2      0.0          assert config.block_size is not None
       125         1         14.2     14.2      0.0          self.config = config
       126                                           
       127         2        141.8     70.9      0.0          self.transformer = nn.ModuleDict(dict(
       128         1     194805.1 194805.1     12.3              wte = nn.Embedding(config.vocab_size, config.n_embd),
       129         1       3987.4   3987.4      0.3              wpe = nn.Embedding(config.block_size, config.n_embd),
       130         1         44.6     44.6      0.0              drop = nn.Dropout(config.dropout),
       131         1     346228.5 346228.5     21.8              h = nn.ModuleList([Block(config) for _ in range(config.n_layer)]),
       132         1        150.6    150.6      0.0              ln_f = LayerNorm(config.n_embd, bias=config.bias),
       133                                                   ))
       134         1     156064.0 156064.0      9.8          self.lm_head = nn.Linear(config.n_embd, config.vocab_size, bias=False)
       135                                                   # with weight tying when using torch.compile() some warnings get generated:
       136                                                   # "UserWarning: functional_call was passed multiple values for tied weights.
       137                                                   # This behavior is deprecated and will be an error in future versions"
       138                                                   # not 100% sure what this is, so far seems to be harmless. TODO investigate
       139         1         51.7     51.7      0.0          self.transformer.wte.weight = self.lm_head.weight # https://paperswithcode.com/method/weight-tying
       140                                           
       141                                                   # init all weights
       142         1     727654.9 727654.9     45.9          self.apply(self._init_weights)
       143                                                   # apply special scaled init to the residual projections, per GPT-2 paper
       144       149       2251.7     15.1      0.1          for pn, p in self.named_parameters():
       145       148        130.9      0.9      0.0              if pn.endswith('c_proj.weight'):
       146        24     151476.4   6311.5      9.6                  torch.nn.init.normal_(p, mean=0.0, std=0.02/math.sqrt(2 * config.n_layer))
       147                                           
       148                                                   # report number of parameters
       149         1       1617.6   1617.6      0.1          print("number of parameters: %.2fM" % (self.get_num_params()/1e6,))
    
    Total time: 0.0015662 s
    File: Code_Analysis/gpt2sample.py
    Function: get_num_params at line 150
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       150                                               @profile
       151                                               def get_num_params(self, non_embedding=True):
       152                                                   """
       153                                                   Return the number of parameters in the model.
       154                                                   For non-embedding count (default), the position embeddings get subtracted.
       155                                                   The token embeddings would too, except due to the parameter sharing these
       156                                                   params are actually used as weights in the final layer, so we include them.
       157                                                   """
       158         1       1547.5   1547.5     98.8          n_params = sum(p.numel() for p in self.parameters())
       159         1          0.5      0.5      0.0          if non_embedding:
       160         1         18.0     18.0      1.1              n_params -= self.transformer.wpe.weight.numel()
       161         1          0.2      0.2      0.0          return n_params
    
    Total time: 0.7249 s
    File: Code_Analysis/gpt2sample.py
    Function: _init_weights at line 162
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       162                                               @profile
       163                                               def _init_weights(self, module):
       164       164        203.1      1.2      0.0          if isinstance(module, nn.Linear):
       165        49     541965.4  11060.5     74.8              torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
       166        49        624.8     12.8      0.1              if module.bias is not None:
       167        48       1848.2     38.5      0.3                  torch.nn.init.zeros_(module.bias)
       168       115         70.8      0.6      0.0          elif isinstance(module, nn.Embedding):
       169         2     180187.3  90093.7     24.9              torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
    
    Total time: 10.9956 s
    File: Code_Analysis/gpt2sample.py
    Function: forward at line 170
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       170                                               @profile
       171                                               def forward(self, idx, targets=None):
       172       500       1134.1      2.3      0.0          device = idx.device
       173       500       1246.5      2.5      0.0          b, t = idx.size()
       174       500        459.8      0.9      0.0          assert t <= self.config.block_size, f"Cannot forward sequence of length {t}, block size is only {self.config.block_size}"
       175       500      24670.2     49.3      0.2          pos = torch.arange(0, t, dtype=torch.long, device=device) # shape (t)
       176                                           
       177                                                   # forward the GPT model itself
       178       500      89398.0    178.8      0.8          tok_emb = self.transformer.wte(idx) # token embeddings of shape (b, t, n_embd)
       179       500      32592.4     65.2      0.3          pos_emb = self.transformer.wpe(pos) # position embeddings of shape (t, n_embd)
       180       500      44503.1     89.0      0.4          x = self.transformer.drop(tok_emb + pos_emb)
       181      6500      12395.7      1.9      0.1          for block in self.transformer.h:
       182      6000    9352574.3   1558.8     85.1              x = block(x)
       183       500      42390.8     84.8      0.4          x = self.transformer.ln_f(x)
       184                                           
       185       500        353.1      0.7      0.0          if targets is not None:
       186                                                       # if we are given some desired targets also calculate the loss
       187                                                       logits = self.lm_head(x)
       188                                                       loss = F.cross_entropy(logits.view(-1, logits.size(-1)), targets.view(-1), ignore_index=-1)
       189                                                   else:
       190                                                       # inference-time mini-optimization: only forward the lm_head on the very last position
       191       500    1393167.3   2786.3     12.7              logits = self.lm_head(x[:, [-1], :]) # note: using list [-1] to preserve the time dim
       192       500        381.5      0.8      0.0              loss = None
       193                                           
       194       500        340.3      0.7      0.0          return logits, loss
    
    Total time: 0 s
    File: Code_Analysis/gpt2sample.py
    Function: crop_block_size at line 195
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       195                                               @profile
       196                                               def crop_block_size(self, block_size):
       197                                                   # model surgery to decrease the block size if necessary
       198                                                   # e.g. we may load the GPT2 pretrained model checkpoint (block size 1024)
       199                                                   # but want to use a smaller block size for some smaller, simpler model
       200                                                   assert block_size <= self.config.block_size
       201                                                   self.config.block_size = block_size
       202                                                   self.transformer.wpe.weight = nn.Parameter(self.transformer.wpe.weight[:block_size])
       203                                                   for block in self.transformer.h:
       204                                                       if hasattr(block.attn, 'bias'):
       205                                                           block.attn.bias = block.attn.bias[:,:,:block_size,:block_size]
    
    Total time: 7.40167 s
    File: Code_Analysis/gpt2sample.py
    Function: from_pretrained at line 207
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       207                                               @classmethod
       208                                               @profile
       209                                               def from_pretrained(cls, model_type, override_args=None):
       210         1          0.6      0.6      0.0          assert model_type in {'gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'}
       211         1          0.4      0.4      0.0          override_args = override_args or {} # default to empty dict
       212                                                   # only dropout can be overridden see more notes below
       213         1          4.5      4.5      0.0          assert all(k == 'dropout' for k in override_args)
       214         1    5063339.5    5e+06     68.4          from transformers import GPT2LMHeadModel
       215         1         26.4     26.4      0.0          print("loading weights from pretrained gpt: %s" % model_type)
       216                                           
       217                                                   # n_layer, n_head and n_embd are determined from model_type
       218         2          1.0      0.5      0.0          config_args = {
       219         1          1.3      1.3      0.0              'gpt2':         dict(n_layer=12, n_head=12, n_embd=768),  # 124M params
       220         1          0.3      0.3      0.0              'gpt2-medium':  dict(n_layer=24, n_head=16, n_embd=1024), # 350M params
       221         1          0.5      0.5      0.0              'gpt2-large':   dict(n_layer=36, n_head=20, n_embd=1280), # 774M params
       222         1          0.4      0.4      0.0              'gpt2-xl':      dict(n_layer=48, n_head=25, n_embd=1600), # 1558M params
       223         1          0.1      0.1      0.0          }[model_type]
       224         1          4.4      4.4      0.0          print("forcing vocab_size=50257, block_size=1024, bias=True")
       225         1          0.4      0.4      0.0          config_args['vocab_size'] = 50257 # always 50257 for GPT model checkpoints
       226         1          0.5      0.5      0.0          config_args['block_size'] = 1024 # always 1024 for GPT model checkpoints
       227         1          0.6      0.6      0.0          config_args['bias'] = True # always True for GPT model checkpoints
       228                                                   # we can override the dropout rate, if desired
       229         1          0.5      0.5      0.0          if 'dropout' in override_args:
       230         1         12.0     12.0      0.0              print(f"overriding dropout rate to {override_args['dropout']}")
       231         1          0.4      0.4      0.0              config_args['dropout'] = override_args['dropout']
       232                                                   # create a from-scratch initialized minGPT model
       233         1          7.1      7.1      0.0          config = GPTConfig(**config_args)
       234         1    1584912.5    2e+06     21.4          model = GPT(config)
       235         1       1481.3   1481.3      0.0          sd = model.state_dict()
       236         1          1.4      1.4      0.0          sd_keys = sd.keys()
       237         1         59.3     59.3      0.0          sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param
       238                                           
       239                                                   # init a huggingface/transformers model
       240         1     504585.7 504585.7      6.8          model_hf = GPT2LMHeadModel.from_pretrained(model_type)
       241         1       1334.6   1334.6      0.0          sd_hf = model_hf.state_dict()
       242                                           
       243                                                   # copy while ensuring all of the parameters are aligned and match in names and shapes
       244         1          1.0      1.0      0.0          sd_keys_hf = sd_hf.keys()
       245         1         49.6     49.6      0.0          sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
       246         1         42.2     42.2      0.0          sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
       247         1          0.5      0.5      0.0          transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
       248                                                   # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
       249                                                   # this means that we have to transpose these weights when we import them
       250         1          0.8      0.8      0.0          assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
       251       150         87.5      0.6      0.0          for k in sd_keys_hf:
       252       149        875.6      5.9      0.0              if any(k.endswith(w) for w in transposed):
       253                                                           # special treatment for the Conv1D weights we need to transpose
       254        48        160.0      3.3      0.0                  assert sd_hf[k].shape[::-1] == sd[k].shape
       255        96       1056.6     11.0      0.0                  with torch.no_grad():
       256        48     219095.2   4564.5      3.0                      sd[k].copy_(sd_hf[k].t())
       257                                                       else:
       258                                                           # vanilla copy over the other parameters
       259       101        278.8      2.8      0.0                  assert sd_hf[k].shape == sd[k].shape
       260       202       1358.4      6.7      0.0                  with torch.no_grad():
       261       101      22882.7    226.6      0.3                      sd[k].copy_(sd_hf[k])
       262                                           
       263         1          0.6      0.6      0.0          return model
    
    Total time: 0 s
    File: Code_Analysis/gpt2sample.py
    Function: configure_optimizers at line 264
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       264                                               @profile
       265                                               def configure_optimizers(self, weight_decay, learning_rate, betas, device_type):
       266                                                   # start with all of the candidate parameters
       267                                                   param_dict = {pn: p for pn, p in self.named_parameters()}
       268                                                   # filter out those that do not require grad
       269                                                   param_dict = {pn: p for pn, p in param_dict.items() if p.requires_grad}
       270                                                   # create optim groups. Any parameters that is 2D will be weight decayed, otherwise no.
       271                                                   # i.e. all weight tensors in matmuls + embeddings decay, all biases and layernorms don't.
       272                                                   decay_params = [p for n, p in param_dict.items() if p.dim() >= 2]
       273                                                   nodecay_params = [p for n, p in param_dict.items() if p.dim() < 2]
       274                                                   optim_groups = [
       275                                                       {'params': decay_params, 'weight_decay': weight_decay},
       276                                                       {'params': nodecay_params, 'weight_decay': 0.0}
       277                                                   ]
       278                                                   num_decay_params = sum(p.numel() for p in decay_params)
       279                                                   num_nodecay_params = sum(p.numel() for p in nodecay_params)
       280                                                   print(f"num decayed parameter tensors: {len(decay_params)}, with {num_decay_params:,} parameters")
       281                                                   print(f"num non-decayed parameter tensors: {len(nodecay_params)}, with {num_nodecay_params:,} parameters")
       282                                                   # Create AdamW optimizer and use the fused version if it is available
       283                                                   fused_available = 'fused' in inspect.signature(torch.optim.AdamW).parameters
       284                                                   use_fused = fused_available and device_type == 'cuda'
       285                                                   extra_args = dict(fused=True) if use_fused else dict()
       286                                                   optimizer = torch.optim.AdamW(optim_groups, lr=learning_rate, betas=betas, **extra_args)
       287                                                   print(f"using fused AdamW: {use_fused}")
       288                                           
       289                                                   return optimizer
    
    Total time: 0 s
    File: Code_Analysis/gpt2sample.py
    Function: estimate_mfu at line 290
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       290                                               @profile
       291                                               def estimate_mfu(self, fwdbwd_per_iter, dt):
       292                                                   """ estimate model flops utilization (MFU) in units of A100 bfloat16 peak FLOPS """
       293                                                   # first estimate the number of flops we do per iteration.
       294                                                   # see PaLM paper Appendix B as ref: https://arxiv.org/abs/2204.02311
       295                                                   N = self.get_num_params()
       296                                                   cfg = self.config
       297                                                   L, H, Q, T = cfg.n_layer, cfg.n_head, cfg.n_embd//cfg.n_head, cfg.block_size
       298                                                   flops_per_token = 6*N + 12*L*H*Q*T
       299                                                   flops_per_fwdbwd = flops_per_token * T
       300                                                   flops_per_iter = flops_per_fwdbwd * fwdbwd_per_iter
       301                                                   # express our flops throughput as ratio of A100 bfloat16 peak flops
       302                                                   flops_achieved = flops_per_iter * (1.0/dt) # per second
       303                                                   flops_promised = 312e12 # A100 GPU bfloat16 peak flops is 312 TFLOPS
       304                                                   mfu = flops_achieved / flops_promised
       305                                                   return mfu
    
    Total time: 11.709 s
    File: Code_Analysis/gpt2sample.py
    Function: generate at line 307
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       307                                               @torch.no_grad()
       308                                               @profile
       309                                               def generate(self, idx, max_new_tokens, temperature=1.0, top_k=None):
       310                                                   """
       311                                                   Take a conditioning sequence of indices idx (LongTensor of shape (b,t)) and complete
       312                                                   the sequence max_new_tokens times, feeding the predictions back into the model each time.
       313                                                   Most likely you'll want to make sure to be in model.eval() mode of operation for this.
       314                                                   """
       315       505       1792.6      3.5      0.0          for _ in range(max_new_tokens):
       316                                                       # if the sequence context is growing too long we must crop it at block_size
       317       500       3814.5      7.6      0.0              idx_cond = idx if idx.size(1) <= self.config.block_size else idx[:, -self.config.block_size:]
       318                                                       # forward the model to get the logits for the index in the sequence
       319       500   11026482.1  22053.0     94.2              logits, _ = self(idx_cond)
       320                                                       # pluck the logits at the final step and scale by desired temperature
       321       500      43792.2     87.6      0.4              logits = logits[:, -1, :] / temperature
       322                                                       # optionally crop the logits to only the top k options
       323       500        402.9      0.8      0.0              if top_k is not None:
       324       500     110794.3    221.6      0.9                  v, _ = torch.topk(logits, min(top_k, logits.size(-1)))
       325       500     212785.0    425.6      1.8                  logits[logits < v[:, [-1]]] = -float('Inf')
       326                                                       # apply softmax to convert logits to (normalized) probabilities
       327       500      38133.0     76.3      0.3              probs = F.softmax(logits, dim=-1)
       328                                                       # sample from the distribution
       329       500     243231.7    486.5      2.1              idx_next = torch.multinomial(probs, num_samples=1)
       330                                                       # append sampled index to the running sequence and continue
       331       500      27813.1     55.6      0.2              idx = torch.cat((idx, idx_next), dim=1)
       332                                           
       333         5          3.3      0.7      0.0          return idx
    
    Total time: 20.2001 s
    File: Code_Analysis/gpt2sample.py
    Function: main at line 334
    
    Line #      Hits         Time  Per Hit   % Time  Line Contents
    ==============================================================
       334                                           @profile
       335                                           def main():
       336                                               # == your entire script, all setup and execution code goes here ==
       337                                               # (starting from parameter setup, seed setting, model loading etc.)
       338                                           
       339                                               # parameter setup
       340         1          0.4      0.4      0.0      init_from = 'gpt2'
       341         1          0.4      0.4      0.0      num_samples = 5
       342         1          0.1      0.1      0.0      max_new_tokens = 100
       343         1          0.2      0.2      0.0      temperature = 0.8
       344         1          0.3      0.3      0.0      top_k = 200
       345         1          0.2      0.2      0.0      seed = 1337
       346         1          0.3      0.3      0.0      device = 'cuda'
       347         1     109154.5 109154.5      0.5      dtype = 'bfloat16' if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else 'float16'
       348         1          0.6      0.6      0.0      compile = False
       349                                           
       350         1      19569.1  19569.1      0.1      torch.manual_seed(seed)
       351         1         34.9     34.9      0.0      torch.cuda.manual_seed(seed)
       352         1          6.9      6.9      0.0      torch.backends.cuda.matmul.allow_tf32 = True
       353         1          7.3      7.3      0.0      torch.backends.cudnn.allow_tf32 = True
       354         1          0.8      0.8      0.0      device_type = 'cuda' if 'cuda' in device else 'cpu'
       355         1          1.9      1.9      0.0      ptdtype = {'float32': torch.float32, 'bfloat16': torch.bfloat16, 'float16': torch.float16}[dtype]
       356         1         91.9     91.9      0.0      ctx = nullcontext() if device_type == 'cpu' else torch.amp.autocast(device_type=device_type, dtype=ptdtype)
       357                                           
       358         1    7450932.2    7e+06     36.9      model = GPT.from_pretrained(init_from, dict(dropout=0.0))
       359         1     270875.0 270875.0      1.3      model.eval().to(device)
       360         1          0.4      0.4      0.0      if compile:
       361                                                   model = torch.compile(model)
       362                                           
       363         1      23795.9  23795.9      0.1      import tiktoken
       364         1     610000.4 610000.4      3.0      enc = tiktoken.get_encoding("gpt2")
       365         1          3.3      3.3      0.0      encode = lambda s: enc.encode(s, allowed_special={"<|endoftext|>"})
       366         1          0.8      0.8      0.0      decode = lambda l: enc.decode(l)
       367                                           
       368         1          0.4      0.4      0.0      start = "What is the answer to life, the universe, and everything?"
       369         1        124.5    124.5      0.0      start_ids = encode(start)
       370         1        238.8    238.8      0.0      x = (torch.tensor(start_ids, dtype=torch.long, device=device)[None, ...])
       371                                           
       372         2         32.3     16.2      0.0      with torch.no_grad():
       373         2        124.0     62.0      0.0          with ctx:
       374         6          8.3      1.4      0.0              for _ in range(num_samples):
       375         5   11715091.9    2e+06     58.0                  y = model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    

analysis from line profile result:

great profile, as it showcase in detail how the line instruction in detail and construction

Then I want to use py-spy to see more about the code struction in flame graph


```python
!pip install py-spy


```

    Collecting py-spy
      Downloading py_spy-0.4.0-py2.py3-none-win_amd64.whl.metadata (16 kB)
    Downloading py_spy-0.4.0-py2.py3-none-win_amd64.whl (1.8 MB)
       ---------------------------------------- 0.0/1.8 MB ? eta -:--:--
       ---------------------------------------- 1.8/1.8 MB 9.9 MB/s eta 0:00:00
    Installing collected packages: py-spy
    Successfully installed py-spy-0.4.0
    


```python
!py-spy record -o gpt2_flame.svg -- python Code_Analysis/gpt2sample.py

```

    [32m[1mpy-spy[0m[2m>[0m Sampling process 100 times a second. Press Control-C to exit.
    
    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    
    [32m[1mpy-spy[0m[2m>[0m Stopped sampling because process exited
    [32m[1mpy-spy[0m[2m>[0m Wrote flamegraph data to 'gpt2_flame.svg'. Samples: 2030 Errors: 22
    


```python
from IPython.display import SVG, display

# Show the flame graph inside the notebook
display(SVG(filename="gpt2_flame.svg"))

```


    
![svg](Transformer_files/Transformer_35_0.svg)
    


Py-spy's analysis truly impressive me a lot, as it exactly showed how the construct runs and what is the detailed called function, even hidden module in the libarary! 

as above, line-profile give me detailed time excuted line by line and time we hit the line. The py-spy allows us to gain more insight about how really the code run, which part is in parallal and how the persentage the time occupy, and what's more, even detailed what module it calls most. 

For our gpt model, we can see we take some time to load the model! Then we do acctual computation after through our code in function generator then mainly go into the forward and deep into the pytorch code as expected.

Then yeah! Loading take loads of time. I assume the loading from memory operation will be huge. So memory operation analysis would high light more in our code.

 Then we do memory operation analysis.


```python
!pip install memory-profiler
```

    Collecting memory-profiler
      Downloading memory_profiler-0.61.0-py3-none-any.whl.metadata (20 kB)
    Requirement already satisfied: psutil in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from memory-profiler) (5.9.0)
    Downloading memory_profiler-0.61.0-py3-none-any.whl (31 kB)
    Installing collected packages: memory-profiler
    Successfully installed memory-profiler-0.61.0
    


```python
!python -m memory_profiler Code_Analysis/gpt2sample.py


```

    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
       219    452.0 MiB    452.0 MiB           1       @classmethod
       220                                             @profile
       221                                             def from_pretrained(cls, model_type, override_args=None):
       222    452.0 MiB      0.0 MiB           1           assert model_type in {'gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'}
       223    452.0 MiB      0.0 MiB           1           override_args = override_args or {} # default to empty dict
       224                                                 # only dropout can be overridden see more notes below
       225    452.0 MiB      0.0 MiB           5           assert all(k == 'dropout' for k in override_args)
       226    536.4 MiB     84.4 MiB           1           from transformers import GPT2LMHeadModel
       227    536.4 MiB      0.0 MiB           1           print("loading weights from pretrained gpt: %s" % model_type)
       228                                         
       229                                                 # n_layer, n_head and n_embd are determined from model_type
       230    536.4 MiB      0.0 MiB           2           config_args = {
       231    536.4 MiB      0.0 MiB           1               'gpt2':         dict(n_layer=12, n_head=12, n_embd=768),  # 124M params
       232    536.4 MiB      0.0 MiB           1               'gpt2-medium':  dict(n_layer=24, n_head=16, n_embd=1024), # 350M params
       233    536.4 MiB      0.0 MiB           1               'gpt2-large':   dict(n_layer=36, n_head=20, n_embd=1280), # 774M params
       234    536.4 MiB      0.0 MiB           1               'gpt2-xl':      dict(n_layer=48, n_head=25, n_embd=1600), # 1558M params
       235    536.4 MiB      0.0 MiB           1           }[model_type]
       236    536.4 MiB      0.0 MiB           1           print("forcing vocab_size=50257, block_size=1024, bias=True")
       237    536.4 MiB      0.0 MiB           1           config_args['vocab_size'] = 50257 # always 50257 for GPT model checkpoints
       238    536.4 MiB      0.0 MiB           1           config_args['block_size'] = 1024 # always 1024 for GPT model checkpoints
       239    536.4 MiB      0.0 MiB           1           config_args['bias'] = True # always True for GPT model checkpoints
       240                                                 # we can override the dropout rate, if desired
       241    536.4 MiB      0.0 MiB           1           if 'dropout' in override_args:
       242    536.4 MiB      0.0 MiB           1               print(f"overriding dropout rate to {override_args['dropout']}")
       243    536.4 MiB      0.0 MiB           1               config_args['dropout'] = override_args['dropout']
       244                                                 # create a from-scratch initialized minGPT model
       245    536.4 MiB      0.0 MiB           1           config = GPTConfig(**config_args)
       246   1159.4 MiB    623.1 MiB           1           model = GPT(config)
       247   1159.5 MiB      0.1 MiB           1           sd = model.state_dict()
       248   1159.5 MiB      0.0 MiB           1           sd_keys = sd.keys()
       249   1159.5 MiB      0.0 MiB         152           sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param
       250                                         
       251                                                 # init a huggingface/transformers model
       252   1034.0 MiB   -125.5 MiB           1           model_hf = GPT2LMHeadModel.from_pretrained(model_type)
       253   1034.0 MiB      0.0 MiB           1           sd_hf = model_hf.state_dict()
       254                                         
       255                                                 # copy while ensuring all of the parameters are aligned and match in names and shapes
       256   1034.0 MiB      0.0 MiB           1           sd_keys_hf = sd_hf.keys()
       257   1034.0 MiB      0.0 MiB         152           sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
       258   1034.0 MiB      0.0 MiB         152           sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
       259   1034.0 MiB      0.0 MiB           1           transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
       260                                                 # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
       261                                                 # this means that we have to transpose these weights when we import them
       262   1034.0 MiB      0.0 MiB           1           assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
       263   1508.4 MiB      0.0 MiB         150           for k in sd_keys_hf:
       264   1508.4 MiB      0.0 MiB        1447               if any(k.endswith(w) for w in transposed):
       265                                                         # special treatment for the Conv1D weights we need to transpose
       266   1499.4 MiB      0.0 MiB          48                   assert sd_hf[k].shape[::-1] == sd[k].shape
       267   1508.4 MiB      0.0 MiB          96                   with torch.no_grad():
       268   1508.4 MiB    323.9 MiB          48                       sd[k].copy_(sd_hf[k].t())
       269                                                     else:
       270                                                         # vanilla copy over the other parameters
       271   1508.4 MiB      0.0 MiB         101                   assert sd_hf[k].shape == sd[k].shape
       272   1508.4 MiB      0.0 MiB         202                   with torch.no_grad():
       273   1508.4 MiB    150.4 MiB         101                       sd[k].copy_(sd_hf[k])
       274                                         
       275   1508.4 MiB      0.0 MiB           1           return model
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1056.6 MiB   1056.6 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1523.6 MiB    467.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1523.8 MiB   1523.8 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1523.8 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1523.8 MiB   1523.8 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1523.8 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1523.8 MiB   1523.8 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1523.8 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1523.8 MiB   1523.8 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1524.3 MiB      0.5 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    


```python
!pip install matplotlib

```

    Collecting matplotlib
      Downloading matplotlib-3.10.1-cp310-cp310-win_amd64.whl.metadata (11 kB)
    Collecting contourpy>=1.0.1 (from matplotlib)
      Downloading contourpy-1.3.2-cp310-cp310-win_amd64.whl.metadata (5.5 kB)
    Collecting cycler>=0.10 (from matplotlib)
      Using cached cycler-0.12.1-py3-none-any.whl.metadata (3.8 kB)
    Collecting fonttools>=4.22.0 (from matplotlib)
      Downloading fonttools-4.57.0-cp310-cp310-win_amd64.whl.metadata (104 kB)
    Collecting kiwisolver>=1.3.1 (from matplotlib)
      Downloading kiwisolver-1.4.8-cp310-cp310-win_amd64.whl.metadata (6.3 kB)
    Requirement already satisfied: numpy>=1.23 in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from matplotlib) (2.0.1)
    Requirement already satisfied: packaging>=20.0 in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from matplotlib) (24.2)
    Requirement already satisfied: pillow>=8 in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from matplotlib) (11.1.0)
    Collecting pyparsing>=2.3.1 (from matplotlib)
      Downloading pyparsing-3.2.3-py3-none-any.whl.metadata (5.0 kB)
    Requirement already satisfied: python-dateutil>=2.7 in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from matplotlib) (2.9.0.post0)
    Requirement already satisfied: six>=1.5 in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from python-dateutil>=2.7->matplotlib) (1.17.0)
    Downloading matplotlib-3.10.1-cp310-cp310-win_amd64.whl (8.1 MB)
       ---------------------------------------- 0.0/8.1 MB ? eta -:--:--
       -------------------------- ------------- 5.2/8.1 MB 26.6 MB/s eta 0:00:01
       ---------------------------------------- 8.1/8.1 MB 25.0 MB/s eta 0:00:00
    Downloading contourpy-1.3.2-cp310-cp310-win_amd64.whl (221 kB)
    Using cached cycler-0.12.1-py3-none-any.whl (8.3 kB)
    Downloading fonttools-4.57.0-cp310-cp310-win_amd64.whl (2.2 MB)
       ---------------------------------------- 0.0/2.2 MB ? eta -:--:--
       ---------------------------------------- 2.2/2.2 MB 24.9 MB/s eta 0:00:00
    Downloading kiwisolver-1.4.8-cp310-cp310-win_amd64.whl (71 kB)
    Downloading pyparsing-3.2.3-py3-none-any.whl (111 kB)
    Installing collected packages: pyparsing, kiwisolver, fonttools, cycler, contourpy, matplotlib
    

    ERROR: Could not install packages due to an OSError: [Errno 28] No space left on device
    
    


```python
!mprof run Code_Analysis/gpt2sample.py
!mprof plot

```

    mprof: Sampling memory every 0.1s
    running new process
    running as a Python program...
    loading weights from pretrained gpt: gpt2
    forcing vocab_size=50257, block_size=1024, bias=True
    overriding dropout rate to 0.0
    number of parameters: 123.65M
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
       219    451.6 MiB    451.6 MiB           1       @classmethod
       220                                             @profile
       221                                             def from_pretrained(cls, model_type, override_args=None):
       222    451.6 MiB      0.0 MiB           1           assert model_type in {'gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'}
       223    451.6 MiB      0.0 MiB           1           override_args = override_args or {} # default to empty dict
       224                                                 # only dropout can be overridden see more notes below
       225    451.6 MiB      0.0 MiB           5           assert all(k == 'dropout' for k in override_args)
       226    535.3 MiB     83.6 MiB           1           from transformers import GPT2LMHeadModel
       227    535.3 MiB      0.0 MiB           1           print("loading weights from pretrained gpt: %s" % model_type)
       228                                         
       229                                                 # n_layer, n_head and n_embd are determined from model_type
       230    535.3 MiB      0.0 MiB           2           config_args = {
       231    535.3 MiB      0.0 MiB           1               'gpt2':         dict(n_layer=12, n_head=12, n_embd=768),  # 124M params
       232    535.3 MiB      0.0 MiB           1               'gpt2-medium':  dict(n_layer=24, n_head=16, n_embd=1024), # 350M params
       233    535.3 MiB      0.0 MiB           1               'gpt2-large':   dict(n_layer=36, n_head=20, n_embd=1280), # 774M params
       234    535.3 MiB      0.0 MiB           1               'gpt2-xl':      dict(n_layer=48, n_head=25, n_embd=1600), # 1558M params
       235    535.3 MiB      0.0 MiB           1           }[model_type]
       236    535.3 MiB      0.0 MiB           1           print("forcing vocab_size=50257, block_size=1024, bias=True")
       237    535.3 MiB      0.0 MiB           1           config_args['vocab_size'] = 50257 # always 50257 for GPT model checkpoints
       238    535.3 MiB      0.0 MiB           1           config_args['block_size'] = 1024 # always 1024 for GPT model checkpoints
       239    535.3 MiB      0.0 MiB           1           config_args['bias'] = True # always True for GPT model checkpoints
       240                                                 # we can override the dropout rate, if desired
       241    535.3 MiB      0.0 MiB           1           if 'dropout' in override_args:
       242    535.3 MiB      0.0 MiB           1               print(f"overriding dropout rate to {override_args['dropout']}")
       243    535.3 MiB      0.0 MiB           1               config_args['dropout'] = override_args['dropout']
       244                                                 # create a from-scratch initialized minGPT model
       245    535.3 MiB      0.0 MiB           1           config = GPTConfig(**config_args)
       246   1158.3 MiB    623.0 MiB           1           model = GPT(config)
       247   1158.4 MiB      0.1 MiB           1           sd = model.state_dict()
       248   1158.4 MiB      0.0 MiB           1           sd_keys = sd.keys()
       249   1158.4 MiB      0.0 MiB         152           sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param
       250                                         
       251                                                 # init a huggingface/transformers model
       252   1035.0 MiB   -123.4 MiB           1           model_hf = GPT2LMHeadModel.from_pretrained(model_type)
       253   1035.0 MiB      0.0 MiB           1           sd_hf = model_hf.state_dict()
       254                                         
       255                                                 # copy while ensuring all of the parameters are aligned and match in names and shapes
       256   1035.0 MiB      0.0 MiB           1           sd_keys_hf = sd_hf.keys()
       257   1035.0 MiB      0.0 MiB         152           sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
       258   1035.0 MiB      0.0 MiB         152           sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
       259   1035.0 MiB      0.0 MiB           1           transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
       260                                                 # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
       261                                                 # this means that we have to transpose these weights when we import them
       262   1035.0 MiB      0.0 MiB           1           assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
       263   1509.3 MiB      0.0 MiB         150           for k in sd_keys_hf:
       264   1509.3 MiB      0.0 MiB        1447               if any(k.endswith(w) for w in transposed):
       265                                                         # special treatment for the Conv1D weights we need to transpose
       266   1500.3 MiB      0.0 MiB          48                   assert sd_hf[k].shape[::-1] == sd[k].shape
       267   1509.3 MiB      0.0 MiB          96                   with torch.no_grad():
       268   1509.3 MiB    323.9 MiB          48                       sd[k].copy_(sd_hf[k].t())
       269                                                     else:
       270                                                         # vanilla copy over the other parameters
       271   1509.3 MiB      0.0 MiB         101                   assert sd_hf[k].shape == sd[k].shape
       272   1509.3 MiB      0.0 MiB         202                   with torch.no_grad():
       273   1509.3 MiB    150.4 MiB         101                       sd[k].copy_(sd_hf[k])
       274                                         
       275   1509.3 MiB      0.0 MiB           1           return model
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28    897.8 MiB    897.8 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1365.0 MiB    467.2 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1365.1 MiB   1365.1 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1365.1 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1365.1 MiB   1365.1 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1365.1 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1365.1 MiB   1365.1 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1365.1 MiB      0.0 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Filename: Code_Analysis/gpt2sample.py
    
    Line #    Mem usage    Increment  Occurrences   Line Contents
    =============================================================
        28   1365.1 MiB   1365.1 MiB           1   @profile
        29                                         def generate_tokens(model, x, max_new_tokens, temperature, top_k):
        30   1365.7 MiB      0.6 MiB           1       return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)
    
    
    Using last profile data.
    Figure(1260x540)
    


```python
import matplotlib.pyplot as plt
import os

dat_files = [f for f in os.listdir() if f.startswith("mprof") and f.endswith(".dat")]
latest_file = max(dat_files, key=os.path.getctime)

times = []
memories = []

with open(latest_file, "r") as f:
    for line in f:
        if line.startswith("MEM"):
            parts = line.strip().split()
            memory = float(parts[1])
            timestamp = float(parts[2])
            memories.append(memory)
            times.append(timestamp)

t0 = times[0]
rel_times = [t - t0 for t in times]

plt.figure(figsize=(12, 5))
plt.plot(rel_times, memories, color="green", linewidth=2, label="Memory Usage (MiB)")
plt.xlabel("Time (s)")
plt.ylabel("Memory (MiB)")
plt.title(f"Memory Usage Over Time\n{latest_file}")
plt.grid(True, linestyle='--', alpha=0.6)
plt.legend()
plt.tight_layout()
plt.show()

```


    
![png](Transformer_files/Transformer_42_0.png)
    


Then I gave Doxygen more trials, as it was mentioned as a suggested tool for understanding and documenting complex code structures.


```python
!choco install doxygen.install graphviz     # Windows (using Chocolatey) - you may need to run it through a administation mode
```

    ^C
    


```python
import os
os.chdir("Code_Analysis")
! "C:/Program Files/doxygen/bin/doxygen.exe" -g

```

    
    
    Configuration file 'Doxyfile' created.
    
    Now edit the configuration file and enter
    
      doxygen
    
    to generate the documentation for your project
    
    


```python
import os

doxyfile_path = "Doxyfile"

updates = {
    "PROJECT_NAME": "GPT2_Analyzer",
    "OUTPUT_DIRECTORY": "docs",
    "INPUT": ".",
    "RECURSIVE": "YES",
    "FILE_PATTERNS": "*.py",
    "EXTENSION_MAPPING": "py=C++",
    "GENERATE_CALL_GRAPH": "YES",
    "CALL_GRAPH": "YES",
    "HAVE_DOT": "YES",
    "DOT_PATH": '"C:/Program Files/Graphviz/bin"',
    "DOT_FONTNAME": '"Arial"',
    "EXTRACT_ALL": "YES",
    "QUIET": "YES"
}

with open(doxyfile_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped == "" or stripped.startswith("#"):
        new_lines.append(line)
        continue

    key = stripped.split()[0]
    if key in updates:
        new_lines.append(f"{key.ljust(25)}= {updates[key]}\n")
    else:
        new_lines.append(line)

with open(doxyfile_path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("✅ Doxyfile updated successfully.")

```

    ✅ Doxyfile updated successfully.
    


```python
! "C:/Program Files/doxygen/bin/doxygen.exe" Doxyfile

```


```python
cleaned_lines = []
with open("Doxyfile", "r", encoding="utf-8") as f:
    for line in f:
        # 去掉奇怪的注释和 markdown 语法行
        if line.strip().startswith(("*", ".", "#", "+")):
            continue
        cleaned_lines.append(line)

with open("Doxyfile", "w", encoding="utf-8") as f:
    f.writelines(cleaned_lines)

print("✅ Cleaned Doxyfile from weird characters.")

```

    ✅ Cleaned Doxyfile from weird characters.
    


```python
import webbrowser
webbrowser.open("docs/html/index.html")

```




    True



However, as I can tell, I only generated garbage throughout the process of using Doxygen. I don’t know if I happened to run it the wrong way, but I couldn’t get any useful output from it — the tool is hard to use for me.

So far, I have tried many good tools to profile my code. Honestly, all of them seem to just verify my own predictions: as we discussed, we should care more about the operations that are running in many loops — those parts are critical for optimization.

As I found not all the recommend methods are as useful as expected, I asked gpt for some good ways for my special gpt generated code

🔥 Recommendation for You
Here’s a smart progression path for your gpt2sample.py analysis:


Phase	Tool	Purpose
🧱 Basic	line_profiler, py-spy, memory_profiler	✅ Done. You already did this excellently.
🧠 Structure	StaticFG, PYCFG, ast + networkx	To visualize structure and flow
🔍 Deep Dive	CodeQL	For precise data dependencies
⚙️ Dynamic View	PyFlowGraph, torch.fx	For true runtime execution graphs
🧠 Final Thought
For GPT2, combining:

torch.fx (to trace tensor-level forward path),

ast + networkx (for code logic),

mprof or py-spy (for profiling and bottlenecks)

would give you a full picture: structure + data + timing.

# StaticFG
I find installion for the opensource package, GPT's guidance is not always helpful. Better check back to offical desciption to see how really you can set the package and call the libarary the correct way.
For installing the staticFG, I struggled a long time chatting with GPT to get me the correct setup. After checking back the offical desciption under their repo, I manage to achieve the setup of libaray. Check https://github.com/JonathanSalwan/StatiCFG.git to find the correct setup.


```python
# Then use StaticFG to get our code runing # run_staticfg.py
from staticfg import CFGBuilder

cfg = CFGBuilder().build_from_file('GPT_CFG', 'Code_Analysis/gpt2sample.py')
cfg.build_visual('gpt_output', 'pdf')  # will generate example_output.pdf

```


    ---------------------------------------------------------------------------

    ImportError                               Traceback (most recent call last)

    Cell In[43], line 2
          1 # Then use StaticFG to get our code runing # run_staticfg.py
    ----> 2 from staticfg import CFGBuilder
          4 cfg = CFGBuilder().build_from_file('GPT_CFG', 'Code_Analysis/gpt2sample.py')
          5 cfg.build_visual('gpt_output', 'pdf')
    

    ImportError: cannot import name 'CFGBuilder' from 'staticfg' (unknown location)


I found I still cannot run file out of Staticfg package folder. Even though I have checked the description and run the demanding line as the README.md file declear. It may be a package path issue that I didn't know how to set. Then I move forward to place my file under the Staticfg folder and finally run the analysis correctly and generate the cool file below:


```python
from IPython.display import Image

Image(filename='gpt2_output.png')

```




    
![png](Transformer_files/Transformer_56_0.png)
    



# pycallgraph2
another trial: pip install pycallgraph2

I add code below to the code file to do pycall graph2 replace below our code:


```python
from pycallgraph2 import PyCallGraph
from pycallgraph2.output import GraphvizOutput

if __name__ == "__main__":
    graphviz = GraphvizOutput()
    graphviz.output_file = 'gpt2_callgraph.png'

    with PyCallGraph(output=graphviz):
        main()
```


```python
from IPython.display import Image

Image(filename='Code_Analysis/gpt2_callgraph.png')

```




    
![png](Transformer_files/Transformer_60_0.png)
    



The above shows everything about the structure, but to me, it does not show anything useful. I think analysis tools make some sense if you know nothing about the code. I found the generated call/control logic diagrams are very detailed, but in reality, the control logic is too fragmented. The blocks are separated from their original code context. I can roughly identify which parts look complex or have a lot of loops, but I still have no clear idea how it actually runs. While tools like pycallgraph2 can generate detailed and visually appealing call graphs of a model like GPT-2, I found that these visualizations often lack truly valuable insight unless you're already unfamiliar with the code. It feels like a waste of time. As a co-design optimizer, we should be capable of structuring the source code logic ourselves. Using LLMs to guide me through profiling tools ends up wasting more time than just learning and analyzing the algorithm and framework directly. These profiling tools are helpful for getting a quick structural overview, but they can't replace manual code tracing and logical reasoning. It's only by going through the code ourselves — understanding the algorithm design, reasoning behind each block, and the flow of data — that we gain insights that are actually useful for co-design and optimization.

So the takeaway from my profiling trial is: we should use profiling tools to quickly get a high-level view of the algorithm — but not rely on them. Often, profiling tools are less effective than going back to the code and understanding the logic directly. In co-design, we ultimately need to return to the algorithm itself. As engineers, we must deeply understand the system — not just depend on profiling outputs.

After using these profiling tools, I got some observations about code timing, memory usage, and runtime structure. But now, we should return to the algorithm and draw a high-level block diagram or flow chart to better understand what we want to optimize, and where the real computational demand is coming from.

# Actual Code Analysis:
In this part, I walk through the source code line by line as excuting with gpt to fully go across the code to make more sense of the code.


Come back to our source code, the logic block of the code would be as follow:
1. Parameter Setup (sampling hyperparameters. They control how many samples, how long, and how randomly to generate text.)
2. Seed + CUDA Precision Setup
3. Device & Precision Context ⚠️ Optimization opportunity: float16 / bf16 brings speedups.
4. Model Loading from pretrained model - ⚠️ It takes times!
5. Tokenizer Setup; Input Preparation Initial input gets tokenized and converted to a batch tensor shape [1, T].
6. Text Generation Loop 📌 This is where the main compute load happens.

1-5 will all be set up in our algurithm, though some part may take time and loads of memory as we observe in previous profiling, they are all one-time setup and cann be cleaned up or refactored for better modularity or quicker experimentation (e.g., config file, CLI args, preset profiles). I think we want to focus more on the real computation part, then we dig more into the 6.Text generation loop.
But first, for setting up the model, why it takes that much time to set up the model? We should also go to take a look at our model Class to make a sense of how really our GPT model construct.
   


We call     model = GPT.from_pretrained(init_from, dict(dropout=0.0)) to fit our model.
Inside the call:


```python
 def from_pretrained(cls, model_type, override_args=None):
        # Step 1: Model Selection and Config Setup
        assert model_type in {'gpt2', 'gpt2-medium', 'gpt2-large', 'gpt2-xl'}
        override_args = override_args or {} # default to empty dict
        # only dropout can be overridden see more notes below
        assert all(k == 'dropout' for k in override_args)
        from transformers import GPT2LMHeadModel
        print("loading weights from pretrained gpt: %s" % model_type)

        # n_layer, n_head and n_embd are determined from model_type
        config_args = {
            'gpt2':         dict(n_layer=12, n_head=12, n_embd=768),  # 124M params
            'gpt2-medium':  dict(n_layer=24, n_head=16, n_embd=1024), # 350M params
            'gpt2-large':   dict(n_layer=36, n_head=20, n_embd=1280), # 774M params
            'gpt2-xl':      dict(n_layer=48, n_head=25, n_embd=1600), # 1558M params
        }[model_type]
        print("forcing vocab_size=50257, block_size=1024, bias=True")
        config_args['vocab_size'] = 50257 # always 50257 for GPT model checkpoints
        config_args['block_size'] = 1024 # always 1024 for GPT model checkpoints
        config_args['bias'] = True # always True for GPT model checkpoints
        # we can override the dropout rate, if desired
        if 'dropout' in override_args:
            print(f"overriding dropout rate to {override_args['dropout']}")
            config_args['dropout'] = override_args['dropout']
        # create a from-scratch initialized minGPT model
        config = GPTConfig(**config_args)
        model = GPT(config) # this will go to set the critical model!




        sd = model.state_dict()
        sd_keys = sd.keys()
        sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param

        # init a huggingface/transformers model
        model_hf = GPT2LMHeadModel.from_pretrained(model_type)
        sd_hf = model_hf.state_dict()

        # copy while ensuring all of the parameters are aligned and match in names and shapes
        sd_keys_hf = sd_hf.keys()
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
        transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
        # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
        # this means that we have to transpose these weights when we import them
        assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
        for k in sd_keys_hf:
            if any(k.endswith(w) for w in transposed):
                # special treatment for the Conv1D weights we need to transpose
                assert sd_hf[k].shape[::-1] == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k].t())
            else:
                # vanilla copy over the other parameters
                assert sd_hf[k].shape == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k])

        return model
```


```python
# The config in our simple GPT2 task should be:
@dataclass
class GPTConfig:
    block_size: int = 1024
    vocab_size: int = 50304
    n_layer: int = 12
    n_head: int = 12
    n_embd: int = 768
    dropout: float = 0.0
    bias: bool = True
```


# Break down into transformer:
However, I really don't know how a transformer block will act, then I went with GPT to get more sense:
I ask: I know nothing about that, how this really work?
What is a Transformer Block?
A Transformer block is like a processing unit that takes a sequence of vectors and transforms them into a better, more informed representation — one that understands context.



```python
class GPT(nn.Module):

    def __init__(self, config):
        super().__init__()
        assert config.vocab_size is not None
        assert config.block_size is not None
        self.config = config
#inside GPT model

        #set the transformer
        self.transformer = nn.ModuleDict(dict(
            wte = nn.Embedding(config.vocab_size, config.n_embd), # the Token Embedding layer.
            # turns each token ID (like “cat” = 1234) into a vector of size 768.
            wpe = nn.Embedding(config.block_size, config.n_embd), # the Positional Embedding.
            #  adds a unique vector to each position (1st word, 2nd word, ...), because otherwise the model can't know word order.
            # here we have block size of 1024, indicating our we 1024 different vector(size 768) to characterize as different position
            drop = nn.Dropout(config.dropout),
            #  
            h = nn.ModuleList([Block(config) for _ in range(config.n_layer)]), # This builds a stack of Transformer blocks.
            # this part create a pytorch list of model, it will call another fuction Block to form each block according to config
            
            ln_f = LayerNorm(config.n_embd, bias=config.bias),
        ))

        # This serve as extracting weight and initialing random weight
        # not 100% sure what this is, so far seems to be harmless. TODO investigate
        self.transformer.wte.weight = self.lm_head.weight # https://paperswithcode.com/method/weight-tying

        # init all weights
        self.apply(self._init_weights)
        # apply special scaled init to the residual projections, per GPT-2 paper
        for pn, p in self.named_parameters():
            if pn.endswith('c_proj.weight'):
                torch.nn.init.normal_(p, mean=0.0, std=0.02/math.sqrt(2 * config.n_layer))

        # report number of parameters
        print("number of parameters: %.2fM" % (self.get_num_params()/1e6,))
# Break down into transformer:


```


```python
class Block(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.ln_1 = LayerNorm(config.n_embd, bias=config.bias) # LayerNorms of size n_embd = 768
        # This means each token vector (of length 768) is normalized before attention and MLP.
        self.attn = CausalSelfAttention(config)
        self.ln_2 = LayerNorm(config.n_embd, bias=config.bias)
        self.mlp = MLP(config)


    def forward(self, x):
        x = x + self.attn(self.ln_1(x))
        x = x + self.mlp(self.ln_2(x))
        return x

```

The Block Class will also call different function to form different layers, let's go deeper into each part. (Before figuring out how the block construct)


```python
class LayerNorm(nn.Module):
    """ LayerNorm but with an optional bias. PyTorch doesn't support simply bias=False """
    # 
    def __init__(self, ndim, bias):
        super().__init__()
        self.weight = nn.Parameter(torch.ones(ndim))
        # tensor of shape [ndim], filled with 1.0
        # torch.nn.Parameter is a special kind of tensor
        # Automatically registered as part of the model's parameters.
        # Will be updated by the optimizer during training
        self.bias = nn.Parameter(torch.zeros(ndim)) if bias else None
        # Creates a tensor of shape [ndim] filled with 0s.
        # bias here serve as a trick for Slightly improving training...
    def forward(self, input):
        return F.layer_norm(input, self.weight.shape, self.weight, self.bias, 1e-5)
        # F.layer_norm(...) is Torch’s functional version of nn.LayerNorm
        # input tensor would be [batch_size, seq_len, ndim] = [B, T, 768]
        # self.weight.shape would be size of our weight, in our case is 768
        # self.weight just weight
        # 
        # all in all norm does:

```

### 📐 Layer Normalization Equation

For each input token vector:
\[
x = [x_1, x_2, \ldots, x_{768}]
\]

---

#### 1. Compute the mean:
\[
\mu = \frac{1}{768} \sum_{i=1}^{768} x_i
\]

---

#### 2. Compute the variance:
\[
\sigma^2 = \frac{1}{768} \sum_{i=1}^{768} (x_i - \mu)^2
\]

---

#### 3. Normalize:
\[
\hat{x}_i = \frac{x_i - \mu}{\sqrt{\sigma^2 + \epsilon}}
\]

---

#### 4. Apply learnable scale and shift:
\[
y_i = \gamma_i \cdot \hat{x}_i + \beta_i
\]

---

Where:

- \( \gamma \in \mathbb{R}^{768} \): learnable scale parameter (`self.weight`)
- \( \beta \in \mathbb{R}^{768} \): learnable shift parameter (`self.bias`)
- \( \epsilon \): a small constant (e.g., \( 1e{-5} \)) to prevent division by zero

Each of these operations is applied **per token** across its feature dimensions (e.g., 768 in GPT-2).



```python
class CausalSelfAttention(nn.Module):

    def __init__(self, config):
        super().__init__()
        assert config.n_embd % config.n_head == 0
        # This ensures that the embedding dimension can be evenly divided into attention heads.
        # In my case n_embd = 768, n_head = 12 - so for each header, I will assign 64 for different header
        # key, query, value projections for all heads, but in a batch
        self.c_attn = nn.Linear(config.n_embd, 3 * config.n_embd, bias=config.bias)
        # QKV Projection Layer 
        # a single linear layer that computes: Q (Query); K (Key); V (Value)
        # Instead of doing 3 separate projections, this layer outputs:
        # [x_Q; x_K; x_V]  ← shape: (B, T, 3 × 768)

        # output projection
        self.c_proj = nn.Linear(config.n_embd, config.n_embd, bias=config.bias)
        # Output Projection： After attention is calculated, all head outputs are concatenated back to shape (B, T, 768)
        # 

        # regularization
        self.attn_dropout = nn.Dropout(config.dropout)
        self.resid_dropout = nn.Dropout(config.dropout)
        # config.dropout = 0.0； so my implementation don't have to worry about this 
        self.n_head = config.n_head
        self.n_embd = config.n_embd
        self.dropout = config.dropout
        # flash attention make GPU go brrrrr but support is only in PyTorch >= 2.0
        self.flash = hasattr(torch.nn.functional, 'scaled_dot_product_attention')
        if not self.flash:
            print("WARNING: using slow attention. Flash Attention requires PyTorch >= 2.0")
            # causal mask to ensure that attention is only applied to the left in the input sequence
            self.register_buffer("bias", torch.tril(torch.ones(config.block_size, config.block_size))
                                        .view(1, 1, config.block_size, config.block_size))
        # the self.flash could be an issue

    def forward(self, x):
        # Input Shape Extraction
        B, T, C = x.size() # batch size, sequence length, embedding dimensionality (n_embd)

        # calculate query, key, values for all heads in batch and move head forward to be the batch dim
        q, k, v  = self.c_attn(x).split(self.n_embd, dim=2)
        # as we previously discussion in Class, the cacluation of qkv form together, then split the value

        # Reshape and Transpose
        # Each head gets 64 dim if C=768
        #
        k = k.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        q = q.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        v = v.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        # reshape into (B, T, 12, 64) (B, T, n_head, head_size)
        # But attention needs: (B, n_head, T, head_size) then .transpose(1, 2) swap axes 1 and 2

        # causal self-attention; Self-attend: (B, nh, T, hs) x (B, nh, hs, T) -> (B, nh, T, T)
        if self.flash:
            # efficient attention using Flash Attention CUDA kernels
            y = torch.nn.functional.scaled_dot_product_attention(q, k, v, attn_mask=None, dropout_p=self.dropout if self.training else 0, is_causal=True)
        else:
            # manual implementation of attention
            # swap gives (B, nh, T, hs) x (B, nh, hs, T) -> (B, nh, T, T) 
            # q @ k.T: Dot product between queries and keys
            att = (q @ k.transpose(-2, -1)) * (1.0 / math.sqrt(k.size(-1)))
            # Apply Causal Mask
            # Each token can only see itself and previous tokens (no future)
            # [1 0 0 0
            #  1 1 0 0
            #  1 1 1 0
            #  1 1 1 1]
            att = att.masked_fill(self.bias[:,:,:T,:T] == 0, float('-inf'))
            att = F.softmax(att, dim=-1)
            att = self.attn_dropout(att)
            y = att @ v # (B, nh, T, T) x (B, nh, T, hs) -> (B, nh, T, hs)
        y = y.transpose(1, 2).contiguous().view(B, T, C) # re-assemble all head outputs side by side
            # .view(B, T, C)  # (B, T, nh × hs) → (B, T, 768)
        # output projection
        y = self.resid_dropout(self.c_proj(y))
        # (B, T, 768) same format as we input! 
        return y

```


```python
class MLP(nn.Module):
    # a standard Transformer position-wise feed-forward network.
    def __init__(self, config):
        super().__init__()
        self.c_fc    = nn.Linear(config.n_embd, 4 * config.n_embd, bias=config.bias)# token embedding from 768 → 3072,
        self.gelu    = nn.GELU() # applies a nonlinearity (GELU)
        self.c_proj  = nn.Linear(4 * config.n_embd, config.n_embd, bias=config.bias)# then projects it back down to 768.
        self.dropout = nn.Dropout(config.dropout)
        
    def forward(self, x):
        x = self.c_fc(x)
        x = self.gelu(x)
        x = self.c_proj(x)
        x = self.dropout(x)
        return x
    
```

After digging into each Class, we can come back to our construction of block:


```python
class Block(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.ln_1 = LayerNorm(config.n_embd, bias=config.bias) # LayerNorms of size n_embd = 768
        # This means each token vector (of length 768) is normalized before attention and MLP.
        self.attn = CausalSelfAttention(config)
        self.ln_2 = LayerNorm(config.n_embd, bias=config.bias)
        self.mlp = MLP(config)


    def forward(self, x):
        x = x + self.attn(self.ln_1(x))
        # normalize each token; Apply self-attention: output (B, T, 768), 	Add x + residual: output stays (B, T, 768)
        # x goes through attention and is added back in — allowing gradients and information to flow easier.
        x = x + self.mlp(self.ln_2(x))
        # Again, but go through the mlp
        return x
        # x ∈ ℝ^{B × T × C}  # (batch_size, sequence_length, embedding_dim)
        # x → Block → x'
        # After going through one Block, you get:
        # x′ ∈ ℝ^{B × T × C}  # same shape as input
        # But — the contents of x′ are different.
        # They now hold richer, more contextualized, transformed representations of the tokens.
        
```


```python
# come back to state our multi-block building
 nn.ModuleList([Block(config) for _ in range(config.n_layer)]), # This builds a stack of Transformer blocks.
    # this part create a pytorch list of model, it will call another fuction Block to form each block according to config
    # x0 → Block1 → x1 → Block2 → x2 → ... → Block12 → x_final
    # Tokens are refined; Relationships between them are deepened
    # But shape never changes — always (B, T, 768)

```


```python
        model = GPT(config) # this will go to set the critical model!

#         This creates a new instance of your custom GPT class, initialized from scratch.

# At this point:

# The model has random weights

# It has the correct architecture, but knows nothing

# 🧠 We need to load the pretrained GPT-2 weights next.
# after initial configing our model, we move on:

        # declear more：

        sd = model.state_dict()

        # load the weight from model

        sd_keys = sd.keys()
        sd_keys = [k for k in sd_keys if not k.endswith('.attn.bias')] # discard this mask / buffer, not a param
        # Each key in sd is the name of a parameter, like:
        # 'transformer.h.0.attn.c_attn.weight'
        # This filters out non-learnable stuff (e.g., the buffer mask).

        # We now have a list of trainable parameter names from your model that we want to load into.  

        # init a huggingface/transformers model
        model_hf = GPT2LMHeadModel.from_pretrained(model_type)

        sd_hf = model_hf.state_dict()


        # all below code for Matching layout
        # copy while ensuring all of the parameters are aligned and match in names and shapes
        sd_keys_hf = sd_hf.keys()
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.masked_bias')] # ignore these, just a buffer
        sd_keys_hf = [k for k in sd_keys_hf if not k.endswith('.attn.bias')] # same, just the mask (buffer)
        transposed = ['attn.c_attn.weight', 'attn.c_proj.weight', 'mlp.c_fc.weight', 'mlp.c_proj.weight']
        # basically the openai checkpoints use a "Conv1D" module, but we only want to use a vanilla Linear
        # this means that we have to transpose these weights when we import them
        assert len(sd_keys_hf) == len(sd_keys), f"mismatched keys: {len(sd_keys_hf)} != {len(sd_keys)}"
        for k in sd_keys_hf:
            if any(k.endswith(w) for w in transposed):
                # special treatment for the Conv1D weights we need to transpose
                assert sd_hf[k].shape[::-1] == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k].t())
            else:
                # vanilla copy over the other parameters
                assert sd_hf[k].shape == sd[k].shape
                with torch.no_grad():
                    sd[k].copy_(sd_hf[k])

        return model
```


```python
# above we finish the load_pretrain, then we move to 

# Puts the model in evaluation mode
# must do this before using the model to generate or evaluate.
 model.eval().to(device)
    if compile:
        model = torch.compile(model) # torch.compile() Traces your model; Can significantly speed up inference and training? But how?

    import tiktoken
# Loads the GPT-2 tokenizer from tiktoken — it maps text ↔ token IDs using GPT-2’s vocabulary and BPE rules.
    enc = tiktoken.get_encoding("gpt2")
    encode = lambda s: enc.encode(s, allowed_special={"<|endoftext|>"})
    decode = lambda l: enc.decode(l)
# Define encode/decode functions
    start = "What is the answer to life, the universe, and everything?"
    start_ids = encode(start)
# wrap input
    x = (torch.tensor(start_ids, dtype=torch.long, device=device)[None, ...])

    with torch.no_grad():
        with ctx:
            for _ in range(num_samples):
                y = generate_tokens(model, x, max_new_tokens, temperature, top_k)


# autoregressive text generation.
@profile
def generate_tokens(model, x, max_new_tokens, temperature, top_k):
    return model.generate(x, max_new_tokens, temperature=temperature, top_k=top_k)

 def generate(self, idx, max_new_tokens, temperature=1.0, top_k=None):
        """
        Take a conditioning sequence of indices idx (LongTensor of shape (b,t)) and complete
        the sequence max_new_tokens times, feeding the predictions back into the model each time.
        Most likely you'll want to make sure to be in model.eval() mode of operation for this.
        """
        for _ in range(max_new_tokens):
            # if the sequence context is growing too long we must crop it at block_size
            idx_cond = idx if idx.size(1) <= self.config.block_size else idx[:, -self.config.block_size:]



            # forward the model to get the logits for the index in the sequence
            logits, _ = self(idx_cond)


# inside forwards()
                def forward(self, idx, targets=None):
                    device = idx.device
                    b, t = idx.size()
                    # Read input shape

                    assert t <= self.config.block_size, f"Cannot forward sequence of length {t}, block size is only {self.config.block_size}"
                    pos = torch.arange(0, t, dtype=torch.long, device=device) # shape (t)
                    # Each token gets a unique position ID
                    # If t = 3, then pos = [0, 1, 2]

                    # forward the GPT model itself
                    tok_emb = self.transformer.wte(idx) # token embeddings of shape (b, t, n_embd)
                    # word/token embedding (same as lookup table)

                    pos_emb = self.transformer.wpe(pos) # position embeddings of shape (t, n_embd)
                    
                    x = self.transformer.drop(tok_emb + pos_emb)
                    # x.shape = (B, T, C)  # example: (1, 3, 768)
                    # (B, T, 768) + (T, 768) = (B, T, 768)
                    for block in self.transformer.h:
                        x = block(x)
                    x = self.transformer.ln_f(x)

                    # if targets is not None:
                    #     # if we are given some desired targets also calculate the loss
                    #     logits = self.lm_head(x)
                    #     loss = F.cross_entropy(logits.view(-1, logits.size(-1)), targets.view(-1), ignore_index=-1)
                    # else:

                    # inference-time mini-optimization: only forward the lm_head on the very last position
                    logits = self.lm_head(x[:, [-1], :]) # note: using list [-1] to preserve the time dim
                    loss = None
                    # above is only for log

                    return logits, loss


            # pluck the logits at the final step and scale by desired temperature
            logits = logits[:, -1, :] / temperature
            # optionally crop the logits to only the top k options
            #  Apply top-k filtering (optional)
            if top_k is not None:
                v, _ = torch.topk(logits, min(top_k, logits.size(-1)))
                logits[logits < v[:, [-1]]] = -float('Inf')
            # apply softmax to convert logits to (normalized) probabilities
            probs = F.softmax(logits, dim=-1)
            # sample from the distribution
            idx_next = torch.multinomial(probs, num_samples=1)
            # append sampled index to the running sequence and continue adding one and one 
            idx = torch.cat((idx, idx_next), dim=1)

        return idx
```


```python
after above digging into the code, I thik I am ready to pose the code diagram:
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
```

GPT2 used to be a hot research topic around, so there has been some great plot showcase the high level structure, I leave it here. 

(Given the time I have spent on this challenge, I may come back if I have time to create my own plots.)



```python
from IPython.display import Image

Image(filename="gpt2_structure.png")
```




    
![png](Transformer_files/Transformer_82_0.png)
    



Figure source: adapted from Yang, Steve; Ali, Zulfikhar; and Wong, Bryan. FLUID-GPT (2023): Fast Learning to Understand and Investigate Dynamics with a Generative Pre-Trained Transformer. ChemRxiv. DOI: 10.26434/chemrxiv-2023-ppk9s



# dead zones


```python

```



I generated a control flow graph for GPT-2 using StaticCFG. It provides a rough overview of the logical structure of each function. However, I noticed that the generated blocks are often fragmented and disconnected from the original code context.

Personally, I believe that truly profiling and understanding code still requires us to go line by line, dig into the core algorithm, and ask GPT (or others) for clarification when needed. The tools help us zoom out, but real understanding comes from working through the logic ourselves.

# Failure: Trial of StaticFG
takeaway: to install the correct package, better come beck to check offical file description, do not trust GPT. GPT will waste your time.



```python

```


```python
!git clone https://github.com/coetaur0/staticfg.git
!cd staticfg
```

    fatal: destination path 'staticfg' already exists and is not an empty directory.
    


```python
!cd staticfg && python setup.py install

```

    running install
    running bdist_egg
    running egg_info
    creating staticfg.egg-info
    writing staticfg.egg-info\PKG-INFO
    writing dependency_links to staticfg.egg-info\dependency_links.txt
    writing requirements to staticfg.egg-info\requires.txt
    writing top-level names to staticfg.egg-info\top_level.txt
    writing manifest file 'staticfg.egg-info\SOURCES.txt'
    reading manifest file 'staticfg.egg-info\SOURCES.txt'
    adding license file 'LICENSE'
    writing manifest file 'staticfg.egg-info\SOURCES.txt'
    installing library code to build\bdist.win-amd64\egg
    running install_lib
    running build_py
    creating build\lib\staticfg
    copying staticfg\builder.py -> build\lib\staticfg
    copying staticfg\model.py -> build\lib\staticfg
    copying staticfg\__init__.py -> build\lib\staticfg
    creating build\bdist.win-amd64\egg
    creating build\bdist.win-amd64\egg\staticfg
    copying build\lib\staticfg\builder.py -> build\bdist.win-amd64\egg\staticfg
    copying build\lib\staticfg\model.py -> build\bdist.win-amd64\egg\staticfg
    copying build\lib\staticfg\__init__.py -> build\bdist.win-amd64\egg\staticfg
    byte-compiling build\bdist.win-amd64\egg\staticfg\builder.py to builder.cpython-310.pyc
    byte-compiling build\bdist.win-amd64\egg\staticfg\model.py to model.cpython-310.pyc
    byte-compiling build\bdist.win-amd64\egg\staticfg\__init__.py to __init__.cpython-310.pyc
    creating build\bdist.win-amd64\egg\EGG-INFO
    copying staticfg.egg-info\PKG-INFO -> build\bdist.win-amd64\egg\EGG-INFO
    copying staticfg.egg-info\SOURCES.txt -> build\bdist.win-amd64\egg\EGG-INFO
    copying staticfg.egg-info\dependency_links.txt -> build\bdist.win-amd64\egg\EGG-INFO
    copying staticfg.egg-info\requires.txt -> build\bdist.win-amd64\egg\EGG-INFO
    copying staticfg.egg-info\top_level.txt -> build\bdist.win-amd64\egg\EGG-INFO
    creating dist
    creating 'dist\staticfg-0.9.6-py3.10.egg' and adding 'build\bdist.win-amd64\egg' to it
    removing 'build\bdist.win-amd64\egg' (and everything under it)
    Processing staticfg-0.9.6-py3.10.egg
    Copying staticfg-0.9.6-py3.10.egg to c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages
    Adding staticfg 0.9.6 to easy-install.pth file
    
    Installed c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\staticfg-0.9.6-py3.10.egg
    Processing dependencies for staticfg==0.9.6
    Searching for astor
    Reading https://pypi.org/simple/astor/
    Downloading https://files.pythonhosted.org/packages/c3/88/97eef84f48fa04fbd6750e62dcceafba6c63c81b7ac1420856c8dcc0a3f9/astor-0.8.1-py2.py3-none-any.whl#sha256=070a54e890cefb5b3739d19f30f5a5ec840ffc9c50ffa7d23cc9fc1a38ebbfc5
    Best match: astor 0.8.1
    Processing astor-0.8.1-py2.py3-none-any.whl
    Installing astor-0.8.1-py2.py3-none-any.whl to c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages
    Adding astor 0.8.1 to easy-install.pth file
    detected new path './staticfg-0.9.6-py3.10.egg'
    
    Installed c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\astor-0.8.1-py3.10.egg
    Searching for graphviz==0.20.3
    Best match: graphviz 0.20.3
    Adding graphviz 0.20.3 to easy-install.pth file
    detected new path './astor-0.8.1-py3.10.egg'
    
    Using c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages
    Finished processing dependencies for staticfg==0.9.6
    

    c:\Users\15360\anaconda3\envs\nanoGPT\lib\site-packages\setuptools\_distutils\dist.py:270: UserWarning: Unknown distribution option: 'test_suite'
      warnings.warn(msg)
    c:\Users\15360\anaconda3\envs\nanoGPT\lib\site-packages\setuptools\_distutils\cmd.py:79: SetuptoolsDeprecationWarning: setup.py install is deprecated.
    !!
    
            ********************************************************************************
            Please avoid running ``setup.py`` directly.
            Instead, use pypa/build, pypa/installer or other
            standards-based tools.
    
            See https://blog.ganssle.io/articles/2021/10/setup-py-deprecated.html for details.
            ********************************************************************************
    
    !!
      self.initialize_options()
    c:\Users\15360\anaconda3\envs\nanoGPT\lib\site-packages\setuptools\_distutils\cmd.py:79: EasyInstallDeprecationWarning: easy_install command is deprecated.
    !!
    
            ********************************************************************************
            Please avoid running ``setup.py`` and ``easy_install``.
            Instead, use pypa/build, pypa/installer or other
            standards-based tools.
    
            See https://github.com/pypa/setuptools/issues/917 for details.
            ********************************************************************************
    
    !!
      self.initialize_options()
    zip_safe flag not set; analyzing archive contents...
    


```python
!pip install -e staticfg

```

    Obtaining file:///D:/AI4Hardware_ECE_410_2025_Spring/Challenge_lists/Challenge%239/Code/Progress/staticfg
      Preparing metadata (setup.py): started
      Preparing metadata (setup.py): finished with status 'done'
    Requirement already satisfied: astor in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\astor-0.8.1-py3.10.egg (from staticfg==0.9.6) (0.8.1)
    Requirement already satisfied: graphviz in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from staticfg==0.9.6) (0.20.3)
    Installing collected packages: staticfg
      Attempting uninstall: staticfg
        Found existing installation: staticfg 0.9.6
        Uninstalling staticfg-0.9.6:
          Successfully uninstalled staticfg-0.9.6
      Running setup.py develop for staticfg
    Successfully installed staticfg
    

      DEPRECATION: Legacy editable install of staticfg==0.9.6 from file:///D:/AI4Hardware_ECE_410_2025_Spring/Challenge_lists/Challenge%239/Code/Progress/staticfg (setup.py develop) is deprecated. pip 25.1 will enforce this behaviour change. A possible replacement is to add a pyproject.toml or enable --use-pep517, and use setuptools >= 64. If the resulting installation is not behaving as expected, try using --config-settings editable_mode=compat. Please consult the setuptools documentation for more information. Discussion can be found at https://github.com/pypa/pip/issues/11457
    


```python
code = '''
def test(x):
    if x > 0:
        print("positive")
    else:
        print("non-positive")

for i in range(3):
    test(i)
'''

with open("demo_example.py", "w") as f:
    f.write(code)

```


```python
import sys
sys.path.append('./staticfg')  # 添加 staticfg 文件夹到 Python path

from builder import CFGBuilder  # 注意从 builder.py 导入

```


    ---------------------------------------------------------------------------

    ModuleNotFoundError                       Traceback (most recent call last)

    Cell In[12], line 4
          1 import sys
          2 sys.path.append('./staticfg')  # 添加 staticfg 文件夹到 Python path
    ----> 4 from builder import CFGBuilder
    

    ModuleNotFoundError: No module named 'builder'



```python
from staticfg import CFGBuilder

cfg = CFGBuilder().build_from_file('demo', 'demo_example.py')
cfg.build_visual('demo_cfg', 'png')  # 或者 pdf/svg


```


    ---------------------------------------------------------------------------

    ImportError                               Traceback (most recent call last)

    Cell In[11], line 1
    ----> 1 from staticfg import CFGBuilder
          3 cfg = CFGBuilder().build_from_file('demo', 'demo_example.py')
          4 cfg.build_visual('demo_cfg', 'png')
    

    ImportError: cannot import name 'CFGBuilder' from 'staticfg' (unknown location)



```python
from staticfg import CFGBuilder

cfg = CFGBuilder().build_from_file("demo", "demo_example.py")
cfg.build_visual("demo_cfg", "png") 


```


    ---------------------------------------------------------------------------

    ImportError                               Traceback (most recent call last)

    Cell In[31], line 1
    ----> 1 from staticfg import CFGBuilder  # 现在不会再报错了！
          3 cfg = CFGBuilder().build_from_file("demo", "demo_example.py")
          4 cfg.build_visual("demo_cfg", "png")
    

    ImportError: cannot import name 'CFGBuilder' from 'staticfg' (unknown location)



```python
!pip install staticfg

```

    Collecting staticfg
      Downloading staticfg-0.9.5-py3-none-any.whl.metadata (313 bytes)
    Requirement already satisfied: astor in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\astor-0.8.1-py3.10.egg (from staticfg) (0.8.1)
    Requirement already satisfied: graphviz in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from staticfg) (0.20.3)
    Downloading staticfg-0.9.5-py3-none-any.whl (11 kB)
    Installing collected packages: staticfg
    Successfully installed staticfg-0.9.5
    


```python
from staticfg.builder import CFGBuilder  


```


    ---------------------------------------------------------------------------

    ModuleNotFoundError                       Traceback (most recent call last)

    Cell In[29], line 1
    ----> 1 from staticfg.builder import CFGBuilder
    

    ModuleNotFoundError: No module named 'staticfg.builder'


# above are some garbage generagted by chatgpt, they are useless. Then I decide to move forward to digging into the source code itself to activate the code/



```python
!pip install git+https://github.com/coetaur0/staticfg.git


```

    Collecting git+https://github.com/coetaur0/staticfg.git
      Cloning https://github.com/coetaur0/staticfg.git to c:\users\15360\appdata\local\temp\pip-req-build-l9rlytnv
      Resolved https://github.com/coetaur0/staticfg.git to commit ef3172950f459394101fc2cb311d36a2f6eebf6b
      Preparing metadata (setup.py): started
      Preparing metadata (setup.py): finished with status 'done'
    Requirement already satisfied: astor in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\astor-0.8.1-py3.10.egg (from staticfg==0.9.6) (0.8.1)
    Requirement already satisfied: graphviz in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from staticfg==0.9.6) (0.20.3)
    

      Running command git clone --filter=blob:none --quiet https://github.com/coetaur0/staticfg.git 'C:\Users\15360\AppData\Local\Temp\pip-req-build-l9rlytnv'
    


```python
!pip uninstall staticfg -y


```

    Found existing installation: staticfg 0.9.6
    Uninstalling staticfg-0.9.6:
      Successfully uninstalled staticfg-0.9.6
    


```python
!pip install git+https://github.com/coetaur0/staticfg.git

```

    Collecting git+https://github.com/coetaur0/staticfg.git
      Cloning https://github.com/coetaur0/staticfg.git to c:\users\15360\appdata\local\temp\pip-req-build-ws64tvpu
      Resolved https://github.com/coetaur0/staticfg.git to commit ef3172950f459394101fc2cb311d36a2f6eebf6b
      Preparing metadata (setup.py): started
      Preparing metadata (setup.py): finished with status 'done'
    Requirement already satisfied: astor in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages\astor-0.8.1-py3.10.egg (from staticfg==0.9.6) (0.8.1)
    Requirement already satisfied: graphviz in c:\users\15360\anaconda3\envs\nanogpt\lib\site-packages (from staticfg==0.9.6) (0.20.3)
    Building wheels for collected packages: staticfg
      Building wheel for staticfg (setup.py): started
      Building wheel for staticfg (setup.py): finished with status 'done'
      Created wheel for staticfg: filename=staticfg-0.9.6-py3-none-any.whl size=12130 sha256=f6b106ba748873f2403f24763ad2e5ca88cac85d0802c601fa62f2cfc9f24825
      Stored in directory: C:\Users\15360\AppData\Local\Temp\pip-ephem-wheel-cache-tm6v5mbj\wheels\63\78\0c\e093aece2c15ff38c78f9e84e4e7844d966b08a182c0921bbd
    Successfully built staticfg
    Installing collected packages: staticfg
    Successfully installed staticfg-0.9.6
    

      Running command git clone --filter=blob:none --quiet https://github.com/coetaur0/staticfg.git 'C:\Users\15360\AppData\Local\Temp\pip-req-build-ws64tvpu'
    


```python
import staticfg
print(staticfg.__file__)

```

    None
    


```python
import sys
sys.path.append("./staticfg/staticfg")  # 注意是 staticfg 里的 staticfg

```


```python
from builder import CFGBuilder

cfg = CFGBuilder().build_from_file("demo", "demo_example.py")
cfg.build_visual("demo_cfg", "png")  # 生成 demo_cfg.png 文件

```


    ---------------------------------------------------------------------------

    ImportError                               Traceback (most recent call last)

    Cell In[40], line 1
    ----> 1 from builder import CFGBuilder
          3 cfg = CFGBuilder().build_from_file("demo", "demo_example.py")
          4 cfg.build_visual("demo_cfg", "png")
    

    File D:\AI4Hardware_ECE_410_2025_Spring\Challenge_lists\Challenge#9\Code\Progress\staticfg\staticfg\builder.py:8
          4 # Aurelien Coet, 2018.
          5 # Modified by Andrei Nacu, 2020
          7 import ast
    ----> 8 from .model import Block, Link, CFG
          9 import sys
         12 def is_py38_or_higher():
    

    ImportError: attempted relative import with no known parent package

