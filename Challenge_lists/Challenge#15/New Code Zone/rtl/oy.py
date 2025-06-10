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

def newton_iteration(x0, variance, iterations=2):
    """模拟牛顿法迭代过程"""
    x = x0
    print(f"  Initial guess: {x:.4f}")
    
    for i in range(iterations):
        x_sq = x * x
        var_x_sq = variance * x_sq
        three_minus = 3.0 - var_x_sq
        
        print(f"  Iter {i+1}: x={x:.4f}, x²={x_sq:.4f}, var*x²={var_x_sq:.4f}, 3-var*x²={three_minus:.4f}")
        
        if three_minus <= 0:
            print(f"  ERROR: 3-var*x² = {three_minus:.4f} <= 0, will diverge!")
            return float('inf')
        
        x_new = x * three_minus / 2.0
        print(f"  -> x_new = {x_new:.4f}")
        x = x_new
    
    return x

def find_optimal_initial_guess(variance_float):
    """为给定方差找到最优初始猜测"""
    target = 1.0 / math.sqrt(variance_float)
    print(f"\nVariance: {variance_float:.4f}, Target: 1/√{variance_float:.4f} = {target:.4f}")
    
    best_guess = None
    best_error = float('inf')
    
    # 搜索范围：从0.1到3.0，步长0.1
    for guess_int in range(1, 31):  # 0.1 到 3.0
        guess = guess_int / 10.0
        
        # 检查牛顿法收敛条件：guess² * variance < 3
        if guess * guess * variance_float >= 3.0:
            continue
        
        result = newton_iteration(guess, variance_float, iterations=2)
        if result == float('inf'):
            continue
            
        error = abs(result - target) / target
        print(f"  Final result: {result:.4f}, Error: {error:.4f}")
        
        if error < best_error:
            best_error = error
            best_guess = guess
    
    print(f"  BEST: guess={best_guess:.4f}, error={best_error:.4f}")
    return best_guess

def generate_lut():
    """生成初始猜测LUT表"""
    print("=== Generating Initial Guess LUT ===")
    
    # 测试关键的方差值
    test_variances = [
        0.01, 0.02, 0.04, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5,
        0.6, 0.7, 0.8, 0.9, 1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0,
        6.0, 8.0, 10.0, 12.0, 16.0, 20.0, 24.0, 30.0
    ]
    
    lut_entries = []
    
    for var_float in test_variances:
        var_q5_10 = to_q5_10(var_float)
        best_guess = find_optimal_initial_guess(var_float)
        
        if best_guess is not None:
            guess_q5_10 = to_q5_10(best_guess)
            high_8_bits = (var_q5_10 >> 8) & 0xFF
            
            lut_entries.append({
                'variance_float': var_float,
                'variance_hex': f"0x{var_q5_10:04X}",
                'high_8_bits': f"8'h{high_8_bits:02X}",
                'best_guess_float': best_guess,
                'best_guess_hex': f"0x{guess_q5_10:04X}"
            })
    
    # 生成Verilog代码
    print("\n=== Generated Verilog LUT Function ===")
    print("function [15:0] get_initial_guess;")
    print("    input [15:0] variance;")
    print("    begin")
    print("        casez (variance[15:8])")
    
    for entry in lut_entries:
        print(f"            {entry['high_8_bits']}: get_initial_guess = {entry['best_guess_hex']};  // var≈{entry['variance_float']:.3f} -> guess≈{entry['best_guess_float']:.3f}")
    
    print("            default: get_initial_guess = 16'h0100;  // 0.25 default")
    print("        endcase")
    print("    end")
    print("endfunction")
    
    # 生成汇总表
    print("\n=== LUT Summary Table ===")
    print("Variance | Hex     | High8 | Best Guess | Hex     | Expected Result")
    print("---------|---------|-------|------------|---------|----------------")
    for entry in lut_entries:
        expected = 1.0 / math.sqrt(entry['variance_float'])
        print(f"{entry['variance_float']:8.3f} | {entry['variance_hex']} | {entry['high_8_bits']} | {entry['best_guess_float']:10.3f} | {entry['best_guess_hex']} | {expected:14.3f}")

if __name__ == "__main__":
    generate_lut()