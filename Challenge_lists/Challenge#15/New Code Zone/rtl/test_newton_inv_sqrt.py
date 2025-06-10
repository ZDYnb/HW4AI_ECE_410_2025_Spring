import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
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

def reference_inv_sqrt(variance):
    """参考实现：计算1/√variance"""
    var_float = from_q5_10(variance)
    if var_float <= 0:
        var_float = 1.0/1024  # 最小epsilon
    inv_sqrt_float = 1.0 / math.sqrt(var_float)
    return to_q5_10(inv_sqrt_float)

@cocotb.test()
async def test_basic_newton(dut):
    """基本功能测试"""
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Basic Newton Test ===")
    
    # 测试方差=1.0，期望1/√1=1.0
    test_variance = to_q5_10(1.0)  # 0x0400
    expected = reference_inv_sqrt(test_variance)
    
    print(f"Input variance: 1.0 (0x{test_variance:04X})")
    print(f"Expected output: {from_q5_10(expected):.3f} (0x{expected:04X})")
    
    # 设置输入
    dut.valid_in.value = 1
    dut.variance_in.value = test_variance
    dut.mean_in.value = 0
    
    # 设置差值向量为0
    for i in range(16):
        getattr(dut, f"diff_vector_in_{i}").value = 0
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出（8级流水线）
    output_found = False
    for cycle in range(15):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            print(f"Output valid at cycle {cycle}")
            output_found = True
            break
    
    assert output_found, "No valid output received"
    
    # 检查结果
    actual = dut.inv_sigma_out.value.signed_integer & 0xFFFF
    actual_float = from_q5_10(actual)
    expected_float = from_q5_10(expected)
    
    print(f"Actual output: {actual_float:.3f} (0x{actual:04X})")
    
    # 计算相对误差
    relative_error = abs(actual_float - expected_float) / max(abs(expected_float), 0.001)
    print(f"Relative error: {relative_error:.3f}")
    
    # 2次迭代牛顿法，允许20%误差
    assert relative_error <= 0.2, f"Error too large: {relative_error:.3f}"
    print("✓ Basic test passed!")

@cocotb.test()
async def test_multiple_values(dut):
    """测试多个方差值"""
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("\n=== Multiple Values Test ===")
    
    test_cases = [
        0.25,   # 1/√0.25 = 2.0
        1.0,    # 1/√1.0  = 1.0
        4.0,    # 1/√4.0  = 0.5
        0.5,    # 1/√0.5  ≈ 1.41
    ]
    
    for i, var_value in enumerate(test_cases):
        print(f"\n--- Test {i}: variance = {var_value} ---")
        
        test_variance = to_q5_10(var_value)
        expected = reference_inv_sqrt(test_variance)
        
        # 设置输入
        dut.valid_in.value = 1
        dut.variance_in.value = test_variance
        dut.mean_in.value = 0
        
        # 设置差值向量为0
        for j in range(16):
            getattr(dut, f"diff_vector_in_{j}").value = 0
        
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        output_found = False
        for cycle in range(15):
            await RisingEdge(dut.clk)
            if dut.valid_out.value == 1:
                output_found = True
                break
        
        assert output_found, f"No valid output for test {i}"
        
        # 检查结果
        actual = dut.inv_sigma_out.value.signed_integer & 0xFFFF
        actual_float = from_q5_10(actual)
        expected_float = from_q5_10(expected)
        
        print(f"Expected: {expected_float:.3f}, Actual: {actual_float:.3f}")
        
        relative_error = abs(actual_float - expected_float) / max(abs(expected_float), 0.001)
        print(f"Relative error: {relative_error:.3f}")
        
        # 根据值的大小调整容忍度
        max_error = 0.3 if var_value < 0.5 or var_value > 2.0 else 0.25
        assert relative_error <= max_error, f"Test {i}: error {relative_error:.3f} > {max_error}"
        
        # 等待几个周期
        await ClockCycles(dut.clk, 3)
    
    print("✓ Multiple values test passed!")

@cocotb.test()
async def test_passthrough(dut):
    """测试数据透传"""
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("\n=== Passthrough Test ===")
    
    test_variance = to_q5_10(1.0)
    test_mean = 0x0600  # 1.5 in Q5.10
    
    # 设置输入
    dut.valid_in.value = 1
    dut.variance_in.value = test_variance
    dut.mean_in.value = test_mean
    
    # 设置测试差值向量
    test_diffs = [0x0100, 0x0200, 0x0300, 0x0400]  # 前4个非零
    for i in range(16):
        diff_val = test_diffs[i] if i < 4 else 0
        getattr(dut, f"diff_vector_in_{i}").value = diff_val
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出
    output_found = False
    for cycle in range(15):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            output_found = True
            break
    
    assert output_found, "No valid output received"
    
    # 检查均值透传
    actual_mean = dut.mean_out.value.signed_integer & 0xFFFF
    mean_error = abs(actual_mean - test_mean)
    print(f"Mean: expected=0x{test_mean:04X}, actual=0x{actual_mean:04X}, error={mean_error}")
    assert mean_error <= 1, f"Mean passthrough error: {mean_error}"
    
    # 检查差值向量透传
    print("Diff vector check:")
    for i in range(4):
        expected_diff = test_diffs[i]
        actual_diff = getattr(dut, f"diff_vector_out_{i}").value.signed_integer & 0xFFFF
        diff_error = abs(actual_diff - expected_diff)
        print(f"  Diff[{i}]: expected=0x{expected_diff:04X}, actual=0x{actual_diff:04X}, error={diff_error}")
        assert diff_error <= 1, f"Diff vector error at index {i}: {diff_error}"
    
    print("✓ Passthrough test passed!")

@cocotb.test()
async def test_pipeline(dut):
    """测试流水线吞吐率"""
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("\n=== Pipeline Test ===")
    
    # 连续发送3个数据
    variances = [to_q5_10(1.0), to_q5_10(4.0), to_q5_10(0.25)]
    expected_results = [reference_inv_sqrt(v) for v in variances]
    
    print("Sending 3 consecutive inputs...")
    for i, var in enumerate(variances):
        dut.valid_in.value = 1
        dut.variance_in.value = var
        dut.mean_in.value = 0
        
        # 设置差值向量为0
        for j in range(16):
            getattr(dut, f"diff_vector_in_{j}").value = 0
        
        await RisingEdge(dut.clk)
        print(f"Sent input {i}: 0x{var:04X}")
    
    dut.valid_in.value = 0
    
    # 收集输出
    outputs = []
    for cycle in range(25):  # 最多等25个周期
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            output = dut.inv_sigma_out.value.signed_integer & 0xFFFF
            outputs.append(output)
            print(f"Cycle {cycle}: received output 0x{output:04X}")
            if len(outputs) >= 3:
                break
    
    assert len(outputs) == 3, f"Expected 3 outputs, got {len(outputs)}"
    
    # 检查每个输出
    for i, (actual, expected) in enumerate(zip(outputs, expected_results)):
        actual_float = from_q5_10(actual)
        expected_float = from_q5_10(expected)
        relative_error = abs(actual_float - expected_float) / max(abs(expected_float), 0.001)
        
        print(f"Output {i}: actual={actual_float:.3f}, expected={expected_float:.3f}, error={relative_error:.3f}")
        assert relative_error <= 0.3, f"Pipeline output {i}: error {relative_error:.3f} > 30%"
    
    print("✓ Pipeline test passed!")

@cocotb.test()
async def test_edge_cases(dut):
    """测试边界情况"""
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("\n=== Edge Cases Test ===")
    
    edge_cases = [
        {"var": 0.1, "desc": "Small variance", "max_err": 0.4},
        {"var": 10.0, "desc": "Large variance", "max_err": 0.3},
        {"var": 0.01, "desc": "Very small variance", "max_err": 0.5},
        {"var": 16.0, "desc": "Very large variance", "max_err": 0.3}
    ]
    
    for i, case in enumerate(edge_cases):
        print(f"\n--- Edge case {i}: {case['desc']} ---")
        
        test_variance = to_q5_10(case["var"])
        expected = reference_inv_sqrt(test_variance)
        
        # 设置输入
        dut.valid_in.value = 1
        dut.variance_in.value = test_variance
        dut.mean_in.value = 0
        
        # 设置差值向量为0
        for j in range(16):
            getattr(dut, f"diff_vector_in_{j}").value = 0
        
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        output_found = False
        for cycle in range(15):
            await RisingEdge(dut.clk)
            if dut.valid_out.value == 1:
                output_found = True
                break
        
        assert output_found, f"No valid output for edge case {i}"
        
        # 检查结果
        actual = dut.inv_sigma_out.value.signed_integer & 0xFFFF
        actual_float = from_q5_10(actual)
        expected_float = from_q5_10(expected)
        
        print(f"Input: {case['var']}, Expected: {expected_float:.3f}, Actual: {actual_float:.3f}")
        
        relative_error = abs(actual_float - expected_float) / max(abs(expected_float), 0.001)
        print(f"Relative error: {relative_error:.3f}")
        
        assert relative_error <= case["max_err"], f"Edge case {i}: error {relative_error:.3f} > {case['max_err']}"
        
        await ClockCycles(dut.clk, 3)
    
    print("✓ Edge cases test passed!")