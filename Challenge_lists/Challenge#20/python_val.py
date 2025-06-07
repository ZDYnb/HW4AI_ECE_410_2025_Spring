import numpy as np

# ---------------------------------------------------------------
# Define the 4-element input voltage vector (V1 to V4)
# These simulate voltages applied to the rows of a 4x4 crossbar
# ---------------------------------------------------------------
V = np.array([1.0, 0.5, 0.2, 0.8])  # shape: (4,)

# ---------------------------------------------------------------
# Define the 4x4 resistance matrix (in ohms)
# Each R[i][j] represents a resistor between row i and column j
# ---------------------------------------------------------------
R = np.array([
    [1000, 1000, 1000, 1000],   # Weights from V1 to I1–I4
    [1000, 2000, 1000, 2000],   # Weights from V2 to I1–I4
    [1000, 1000, 3000, 1000],   # Weights from V3 to I1–I4
    [1000, 1000, 1000, 1000]    # Weights from V4 to I1–I4
], dtype=float)  # shape: (4, 4)

G = 1 / R  # element-wise reciprocal

# Perform the matrix-vector multiplication:
I = G.T @ V  # shape: (4,)

for j, current in enumerate(I, start=1):
    print(f"I{j} = {current:.6f} A")

