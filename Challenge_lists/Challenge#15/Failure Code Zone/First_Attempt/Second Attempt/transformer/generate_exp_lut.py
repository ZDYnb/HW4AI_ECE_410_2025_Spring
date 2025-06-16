
# -*- coding: utf-8 -*-
# generate_exp_lut.py
import math

LUT_BITS = 8
FRAC_BITS = 8  # Q4.8 input
OUTPUT_FRAC_BITS = 15  # Q1.15 output

N = 2 ** LUT_BITS
MAX_INPUT = N / (2 ** FRAC_BITS)  # 256/256 = 1.0 ¿ covers range [-1.0, 0]

with open("exp_lut.mem", "w") as f:
    for i in range(N):
        x = i / (2 ** FRAC_BITS)  # x in [0, 1)
        y = math.exp(-x)
        fixed_val = int(round(y * (2 ** OUTPUT_FRAC_BITS)))
        fixed_val = min(fixed_val, (1 << 16) - 1)  # Clamp to 16-bit
        f.write(f"{fixed_val:04x}\n")

