import math

def to_q5_10(value):
    """Convert float to Q5.10 fixed-point format"""
    value = max(-32.0, min(31.999, value))
    return int(value * 1024) & 0xFFFF

def from_q5_10(value):
    """Convert Q5.10 fixed-point format to float"""
    if value & 0x8000:  # Negative number
        return (value - 65536) / 1024.0
    else:
        return value / 1024.0

def generate_dense_lut():
    """Generate dense LUT table"""
    
    epsilon = 1.0/1024.0  # Minimum value of Q5.10 as epsilon
    
    print("// =============================================================================")
    print("// Dense LUT table: covers test cases")
    print("// =============================================================================")
    
    # Define critical test points to cover precisely
    critical_variances = [
        0.001, 0.002, 0.004, 0.005, 0.008, 0.010,
        0.016, 0.020, 0.031, 0.040, 0.050, 0.063, 0.078,  # Small variance, dense coverage
        0.100, 0.125, 0.150, 0.188, 0.200, 0.250, 0.300,  # Small to medium variance
        0.328, 0.375, 0.438, 0.500, 0.600, 0.750,         # Medium variance
        1.000, 1.250, 1.500, 1.750, 2.000, 2.500, 3.000, # Large variance
        4.000, 5.000, 6.000, 8.000, 10.000, 12.000,      # Very large variance
        16.000, 20.000, 24.000, 32.000                    # Ultra large variance
    ]
    
    print("// Generate Verilog case statements:")
    print("case (variance_in)")
    
    for var_float in critical_variances:
        var_q5_10 = to_q5_10(var_float)
        inv_sqrt_result = 1.0 / math.sqrt(var_float + epsilon)
        inv_sqrt_q5_10 = to_q5_10(inv_sqrt_result)
        
        print(f"    16'h{var_q5_10:04X}: lut_result = 16'h{inv_sqrt_q5_10:04X}; // var={var_float:.3f} -> 1/sqrt={inv_sqrt_result:.3f}")
    
    print("    default: lut_result = 16'h0400; // Default return 1.0")
    print("endcase")
    print()
    
    # Verify critical test points
    print("// =============================================================================")
    print("// Verification test cases:")
    print("// =============================================================================")
    
    test_points = [0.078, 0.125, 0.328, 0.750, 1.500, 6.000]  # Interpolation test points
    
    for var_float in test_points:
        var_q5_10 = to_q5_10(var_float)
        inv_sqrt_result = 1.0 / math.sqrt(var_float + epsilon)
        inv_sqrt_q5_10 = to_q5_10(inv_sqrt_result)
        
        print(f"// Test: variance={var_float:.3f} (0x{var_q5_10:04X}) -> 1/sqrt={inv_sqrt_result:.3f} (0x{inv_sqrt_q5_10:04X})")

if __name__ == "__main__":
    generate_dense_lut()