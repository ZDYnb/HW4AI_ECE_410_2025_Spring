# exp_q88_gen.py
import math

def to_q88(x):
    return int(round(x * 256))  # Q8.8

with open("exp_q88.hex", "w") as f:
    for i in range(256):
        # Convert index to signed 8-bit
        x = (i / 255.0) * 16.0 - 8.0  # x ∈ [-8, +8]

        val = math.exp(x)
        q88 = to_q88(min(val, 255.996))  # clamp for Q8.8 max
        f.write(f"{q88:04x}\n")