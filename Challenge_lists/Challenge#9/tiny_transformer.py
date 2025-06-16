import numpy as np
import time

def float_to_q5_10(x):
    """Convert float to Q5.10 fixed-point (5 integer bits, 10 fractional bits)"""
    x = np.clip(x, -32.0, 31.999)
    return np.round(x * 1024) / 1024

def quantize_q5_10(arr):
    """Quantize array to Q5.10 format"""
    return np.vectorize(float_to_q5_10)(arr)

def tiny_transformer_inference(input_tokens, weights, quantized=False):
    """
    16x16 Tiny Transformer inference (fixed architecture)
    
    Args:
        input_tokens: [16] token IDs (0-15 for vocab size 16)
        weights: dictionary containing all weight matrices
        quantized: whether to use Q5.10 quantization
    
    Returns:
        output_probs: [16] probability distribution over vocabulary
    """
    EPS = 1e-6
    
    # EMBEDDING
    input_matrix = np.zeros((16, 16))
    for i in range(16):
        token_id = input_tokens[i]
        start_idx = token_id * 16
        end_idx = start_idx + 16
        input_matrix[i, :] = weights['embedding'][start_idx:end_idx]
    
    if quantized:
        input_matrix = quantize_q5_10(input_matrix)
    
    # LAYERNORM_INPUT
    x = input_matrix
    mean = np.mean(x, axis=-1, keepdims=True)
    var = np.var(x, axis=-1, keepdims=True)
    ln_input_output = (x - mean) / np.sqrt(var + EPS)
    
    if quantized:
        ln_input_output = quantize_q5_10(ln_input_output)
    
    # Q, K, V COMPUTATION
    Q = np.matmul(ln_input_output, weights['w_q'])
    K = np.matmul(ln_input_output, weights['w_k'])  
    V = np.matmul(ln_input_output, weights['w_v'])
    
    if quantized:
        Q = quantize_q5_10(Q)
        K = quantize_q5_10(K)
        V = quantize_q5_10(V)
    
    # ATTENTION SCORES
    attention_scores = np.matmul(Q, K.T)
    
    if quantized:
        attention_scores = quantize_q5_10(attention_scores)
    
    # SOFTMAX_SCORES
    scores_max = np.max(attention_scores, axis=-1, keepdims=True)
    exp_scores = np.exp(attention_scores - scores_max)
    attention_weights = exp_scores / np.sum(exp_scores, axis=-1, keepdims=True)
    
    if quantized:
        attention_weights = quantize_q5_10(attention_weights)
    
    # ATTENTION OUTPUT
    attention_output = np.matmul(attention_weights, V)
    
    if quantized:
        attention_output = quantize_q5_10(attention_output)
    
    # FIRST RESIDUAL
    residual_1 = input_matrix + attention_output
    
    if quantized:
        residual_1 = quantize_q5_10(residual_1)
    
    # LAYERNORM_1
    mean1 = np.mean(residual_1, axis=-1, keepdims=True)
    var1 = np.var(residual_1, axis=-1, keepdims=True)
    ln1_output = (residual_1 - mean1) / np.sqrt(var1 + EPS)
    
    if quantized:
        ln1_output = quantize_q5_10(ln1_output)
    
    # FEED-FORWARD LAYER 1
    ff1_output = np.matmul(ln1_output, weights['w_ff1'])
    
    if quantized:
        ff1_output = quantize_q5_10(ff1_output)
    
    # GELU ACTIVATION
    sqrt_2_pi = np.sqrt(2.0 / np.pi)
    gelu_input = sqrt_2_pi * (ff1_output + 0.044715 * ff1_output**3)
    gelu_output = 0.5 * ff1_output * (1.0 + np.tanh(gelu_input))
    
    if quantized:
        gelu_output = quantize_q5_10(gelu_output)
    
    # FEED-FORWARD LAYER 2
    ff2_output = np.matmul(gelu_output, weights['w_ff2'])
    
    if quantized:
        ff2_output = quantize_q5_10(ff2_output)
    
    # SECOND RESIDUAL
    residual_2 = ln1_output + ff2_output
    
    if quantized:
        residual_2 = quantize_q5_10(residual_2)
    
    # LAYERNORM_2
    mean2 = np.mean(residual_2, axis=-1, keepdims=True)
    var2 = np.var(residual_2, axis=-1, keepdims=True)
    ln2_output = (residual_2 - mean2) / np.sqrt(var2 + EPS)
    
    if quantized:
        ln2_output = quantize_q5_10(ln2_output)
    
    # OUTPUT PROJECTION
    output_logits = np.matmul(ln2_output, weights['w_out'])
    
    if quantized:
        output_logits = quantize_q5_10(output_logits)
    
    # FINAL SOFTMAX
    final_logits = output_logits[0, :]
    logits_max = np.max(final_logits)
    exp_logits = np.exp(final_logits - logits_max)
    output_probs = exp_logits / np.sum(exp_logits)
    
    if quantized:
        output_probs = quantize_q5_10(output_probs)
    
    return output_probs

def create_weights(quantized=False):
    """Create 16x16 weights (fixed size)"""
    np.random.seed(42)
    init_scale = 0.02
    
    weights = {
        'embedding': np.random.randn(256) * init_scale,  # 16*16 = 256
        'w_q': np.random.randn(16, 16) * init_scale,
        'w_k': np.random.randn(16, 16) * init_scale,
        'w_v': np.random.randn(16, 16) * init_scale,
        'w_ff1': np.random.randn(16, 16) * init_scale,
        'w_ff2': np.random.randn(16, 16) * init_scale,
        'w_out': np.random.randn(16, 16) * init_scale,
    }
    
    if quantized:
        for key in weights:
            weights[key] = quantize_q5_10(weights[key])
    
    return weights

def generate_random_tokens():
    """Generate random 16 tokens (0-15)"""
    return np.random.randint(0, 16, size=16)

if __name__ == "__main__":
    # Benchmarking the 16x16 Tiny Transformer
    num_samples = 1000  # number of samples to benchmark
    quantized = True

    
    # create weights
    weights = create_weights(quantized=quantized)
    
    # hot start with a random input to warm up the cache
    test_tokens = generate_random_tokens()
    _ = tiny_transformer_inference(test_tokens, weights, quantized=quantized)
    
    # start benchmarking
    start_time = time.time()
    
    for k in range(num_samples):
        gen_start = time.time()
        
        # Randomly generate input tokens
        input_tokens = generate_random_tokens()
        probs = tiny_transformer_inference(input_tokens, weights, quantized=quantized)
        
        gen_end = time.time()
        gen_time = gen_end - gen_start
        
    end_time = time.time()
    total_time = end_time - start_time
    avg_time_per_sample = total_time / num_samples
