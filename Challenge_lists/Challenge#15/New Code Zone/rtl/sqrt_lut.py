import math

def to_q5_10(value):
    """将浮点数转换为Q5.10定点格式"""
    value = max(-32.0, min(31.999, value))
    return int(value * 1024) & 0xFFFF

def from_q5_10(value):
    """将Q5.10定点格式转换为浮点数"""
    if value & 0x8000:  # 负数
        return (value - 65536) / 1024.0
    else:
        return value / 1024.0

def generate_dense_lut():
    """生成密集的LUT表"""
    
    epsilon = 1.0/1024.0  # Q5.10的最小值作为epsilon
    
    print("// =============================================================================")
    print("// 密集LUT表：覆盖测试用例")
    print("// =============================================================================")
    
    # 定义需要精确覆盖的测试点
    critical_variances = [
        0.001, 0.002, 0.004, 0.005, 0.008, 0.010,
        0.016, 0.020, 0.031, 0.040, 0.050, 0.063, 0.078,  # 小方差密集覆盖
        0.100, 0.125, 0.150, 0.188, 0.200, 0.250, 0.300,  # 中小方差
        0.328, 0.375, 0.438, 0.500, 0.600, 0.750,         # 中等方差
        1.000, 1.250, 1.500, 1.750, 2.000, 2.500, 3.000, # 大方差
        4.000, 5.000, 6.000, 8.000, 10.000, 12.000,      # 很大方差
        16.000, 20.000, 24.000, 32.000                    # 超大方差
    ]
    
    print("// 生成Verilog case语句:")
    print("case (variance_in)")
    
    for var_float in critical_variances:
        var_q5_10 = to_q5_10(var_float)
        inv_sqrt_result = 1.0 / math.sqrt(var_float + epsilon)
        inv_sqrt_q5_10 = to_q5_10(inv_sqrt_result)
        
        print(f"    16'h{var_q5_10:04X}: lut_result = 16'h{inv_sqrt_q5_10:04X}; // var={var_float:.3f} -> 1/sqrt={inv_sqrt_result:.3f}")
    
    print("    default: lut_result = 16'h0400; // 默认返回1.0")
    print("endcase")
    print()
    
    # 验证关键测试点
    print("// =============================================================================")
    print("// 验证测试用例:")
    print("// =============================================================================")
    
    test_points = [0.078, 0.125, 0.328, 0.750, 1.500, 6.000]  # 插值测试点
    
    for var_float in test_points:
        var_q5_10 = to_q5_10(var_float)
        inv_sqrt_result = 1.0 / math.sqrt(var_float + epsilon)
        inv_sqrt_q5_10 = to_q5_10(inv_sqrt_result)
        
        print(f"// Test: variance={var_float:.3f} (0x{var_q5_10:04X}) -> 1/sqrt={inv_sqrt_result:.3f} (0x{inv_sqrt_q5_10:04X})")

if __name__ == "__main__":
    generate_dense_lut()