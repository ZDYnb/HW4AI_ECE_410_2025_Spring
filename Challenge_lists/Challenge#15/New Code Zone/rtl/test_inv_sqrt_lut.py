import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import numpy as np
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

def reference_inv_sqrt_lut(variance):
    """参考实现：计算1/√(variance + epsilon)"""
    epsilon = 1.0/1024.0  # Q5.10的epsilon
    var_float = from_q5_10(variance)
    inv_sqrt_float = 1.0 / math.sqrt(var_float + epsilon)
    return to_q5_10(inv_sqrt_float)

def set_input_data(dut, variance, mean, diff_vector):
    """设置输入数据"""
    dut.variance_in.value = variance
    dut.mean_in.value = mean
    
    # 设置差值向量
    dut.diff_vector_in_0.value = diff_vector[0]
    dut.diff_vector_in_1.value = diff_vector[1]
    dut.diff_vector_in_2.value = diff_vector[2]
    dut.diff_vector_in_3.value = diff_vector[3]
    dut.diff_vector_in_4.value = diff_vector[4]
    dut.diff_vector_in_5.value = diff_vector[5]
    dut.diff_vector_in_6.value = diff_vector[6]
    dut.diff_vector_in_7.value = diff_vector[7]
    dut.diff_vector_in_8.value = diff_vector[8]
    dut.diff_vector_in_9.value = diff_vector[9]
    dut.diff_vector_in_10.value = diff_vector[10]
    dut.diff_vector_in_11.value = diff_vector[11]
    dut.diff_vector_in_12.value = diff_vector[12]
    dut.diff_vector_in_13.value = diff_vector[13]
    dut.diff_vector_in_14.value = diff_vector[14]
    dut.diff_vector_in_15.value = diff_vector[15]

def get_output_diff_vector(dut):
    """获取输出差值向量"""
    return [
        dut.diff_vector_out_0.value.signed_integer,
        dut.diff_vector_out_1.value.signed_integer,
        dut.diff_vector_out_2.value.signed_integer,
        dut.diff_vector_out_3.value.signed_integer,
        dut.diff_vector_out_4.value.signed_integer,
        dut.diff_vector_out_5.value.signed_integer,
        dut.diff_vector_out_6.value.signed_integer,
        dut.diff_vector_out_7.value.signed_integer,
        dut.diff_vector_out_8.value.signed_integer,
        dut.diff_vector_out_9.value.signed_integer,
        dut.diff_vector_out_10.value.signed_integer,
        dut.diff_vector_out_11.value.signed_integer,
        dut.diff_vector_out_12.value.signed_integer,
        dut.diff_vector_out_13.value.signed_integer,
        dut.diff_vector_out_14.value.signed_integer,
        dut.diff_vector_out_15.value.signed_integer
    ]

@cocotb.test()
async def test_lut_exact_values(dut):
    """测试LUT表中的精确值"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Test LUT Exact Values ===")
    
    # 测试LUT表中的精确值 (基于Python脚本生成的数据)
    test_cases = [
        {"var": 0x0001, "expected": 0x59F8, "desc": "var=0.001"},
        {"var": 0x000A, "expected": 0x262D, "desc": "var=0.010"},
        {"var": 0x0066, "expected": 0x0C96, "desc": "var=0.100"},
        {"var": 0x0100, "expected": 0x07FC, "desc": "var=0.250"},
        {"var": 0x0200, "expected": 0x05A6, "desc": "var=0.500"},
        {"var": 0x0400, "expected": 0x03FF, "desc": "var=1.000"},
        {"var": 0x0800, "expected": 0x02D3, "desc": "var=2.000"},
        {"var": 0x1000, "expected": 0x01FF, "desc": "var=4.000"},
        {"var": 0x2000, "expected": 0x016A, "desc": "var=8.000"},
        {"var": 0x4000, "expected": 0x00FF, "desc": "var=16.000"},
    ]
    
    test_mean = to_q5_10(0.0)
    test_diff = [to_q5_10(0.0)] * 16  # 零差值向量
    
    for i, case in enumerate(test_cases):
        print(f"\n--- Test case {i}: {case['desc']} ---")
        
        # 输入数据
        dut.valid_in.value = 1
        set_input_data(dut, case['var'], test_mean, test_diff)
        
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # LUT是1级流水线，等待1个周期
        await RisingEdge(dut.clk)
        
        # 检查输出
        assert dut.valid_out.value == 1, f"Valid output should be high for test {i}"
        
        actual_inv_sqrt = dut.inv_sigma_out.value.signed_integer & 0xFFFF
        expected_inv_sqrt = case['expected']
        
        print(f"Input variance: 0x{case['var']:04X} = {from_q5_10(case['var']):.3f}")
        print(f"Expected: 0x{expected_inv_sqrt:04X} = {from_q5_10(expected_inv_sqrt):.3f}")
        print(f"Actual:   0x{actual_inv_sqrt:04X} = {from_q5_10(actual_inv_sqrt):.3f}")
        
        # LUT表中的值应该完全匹配
        error = abs(actual_inv_sqrt - expected_inv_sqrt)
        print(f"Error: {error}")
        
        assert error <= 1, f"LUT exact value test {i} failed: error {error}"
        
        # 等几个周期再进行下一个测试
        await ClockCycles(dut.clk, 2)
    
    print("✓ All LUT exact value tests passed!")

@cocotb.test()
async def test_lut_interpolation(dut):
    """测试LUT插值区域"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Test LUT Interpolation ===")
    
    # 测试不在LUT表中的值(会使用插值)
    test_cases = [
        {"var": 0x0050, "desc": "var≈0.078 (interpolation)"},
        {"var": 0x0080, "desc": "var≈0.125 (interpolation)"},
        {"var": 0x0150, "desc": "var≈0.328 (interpolation)"},
        {"var": 0x0300, "desc": "var≈0.750 (interpolation)"},
        {"var": 0x0600, "desc": "var≈1.500 (interpolation)"},
        {"var": 0x1800, "desc": "var≈6.000 (interpolation)"},
    ]
    
    test_mean = to_q5_10(0.5)
    test_diff = [to_q5_10(0.1 * (i-8)) for i in range(16)]  # -0.8 to 0.7
    
    for i, case in enumerate(test_cases):
        print(f"\n--- Interpolation test {i}: {case['desc']} ---")
        
        # 计算理论期望值
        expected_ref = reference_inv_sqrt_lut(case['var'])
        
        # 输入数据
        dut.valid_in.value = 1
        set_input_data(dut, case['var'], test_mean, test_diff)
        
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        await RisingEdge(dut.clk)
        
        # 检查输出
        assert dut.valid_out.value == 1, f"Valid output should be high for interpolation test {i}"
        
        actual_inv_sqrt = dut.inv_sigma_out.value.signed_integer & 0xFFFF
        
        print(f"Input variance: 0x{case['var']:04X} = {from_q5_10(case['var']):.3f}")
        print(f"Reference: 0x{expected_ref:04X} = {from_q5_10(expected_ref):.3f}")
        print(f"Actual:    0x{actual_inv_sqrt:04X} = {from_q5_10(actual_inv_sqrt):.3f}")
        
        # 插值精度允许较大误差
        error = abs(actual_inv_sqrt - expected_ref)
        relative_error = error / max(expected_ref, 1)
        
        print(f"Absolute error: {error}")
        print(f"Relative error: {relative_error:.3f}")
        
        # 插值误差应在20%以内
        assert relative_error <= 0.2, f"Interpolation test {i}: relative error {relative_error:.3f} > 20%"
        
        await ClockCycles(dut.clk, 2)
    
    print("✓ All interpolation tests passed!")

@cocotb.test()
async def test_lut_passthrough(dut):
    """测试数据透传功能"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Test Data Passthrough ===")
    
    # 测试数据透传
    test_variance = 0x0400  # 1.0
    test_mean = to_q5_10(1.5)
    test_diff = [to_q5_10(0.1 * i) for i in range(16)]  # 0.0 to 1.5
    
    print(f"Testing passthrough with mean=0x{test_mean:04X}")
    print(f"Diff vector: {[hex(x) for x in test_diff[:4]]}...")
    
    # 输入数据
    dut.valid_in.value = 1
    set_input_data(dut, test_variance, test_mean, test_diff)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出
    await RisingEdge(dut.clk)
    
    # 检查输出
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    # 检查均值透传
    actual_mean = dut.mean_out.value.signed_integer & 0xFFFF
    mean_error = abs(actual_mean - test_mean)
    print(f"Mean passthrough: expected 0x{test_mean:04X}, actual 0x{actual_mean:04X}, error {mean_error}")
    assert mean_error <= 1, f"Mean passthrough error: {mean_error}"
    
    # 检查差值向量透传
    actual_diff = get_output_diff_vector(dut)
    print("Difference vector passthrough check:")
    for i in range(16):
        diff_error = abs(actual_diff[i] - test_diff[i])
        if i < 4:  # 只打印前4个
            print(f"  Diff[{i}]: expected 0x{test_diff[i]:04X}, actual 0x{actual_diff[i]&0xFFFF:04X}, error {diff_error}")
        assert diff_error <= 1, f"Diff vector passthrough error at index {i}: {diff_error}"
    
    print("✓ Data passthrough test passed!")

@cocotb.test()
async def test_lut_pipeline_throughput(dut):
    """测试LUT流水线吞吐率"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Test LUT Pipeline Throughput ===")
    
    # 准备连续输入数据
    test_cases = [
        0x0100,  # 0.25
        0x0400,  # 1.0  
        0x1000,  # 4.0
        0x0200,  # 0.5
        0x0800,  # 2.0
    ]
    
    expected_results = []
    for var in test_cases:
        # 对于LUT表中的值，使用精确预期
        lut_exact = {
            0x0100: 0x07FC,  # var=0.250
            0x0400: 0x03FF,  # var=1.000  
            0x1000: 0x01FF,  # var=4.000
            0x0200: 0x05A6,  # var=0.500
            0x0800: 0x02D3,  # var=2.000
        }
        expected_results.append(lut_exact.get(var, reference_inv_sqrt_lut(var)))
    
    test_mean = to_q5_10(0.0)
    test_diff = [to_q5_10(0.0)] * 16
    
    print(f"Sending {len(test_cases)} consecutive inputs...")
    
    # 连续输入数据 - 每个周期输入一个
    for cycle, var in enumerate(test_cases):
        dut.valid_in.value = 1
        set_input_data(dut, var, test_mean, test_diff)
        await RisingEdge(dut.clk)
        print(f"Input cycle {cycle}: variance=0x{var:04X} sent")
        # 注意：不要设置valid_in=0，保持连续输入
    
    # 最后一个周期后停止输入
    dut.valid_in.value = 0
    
    # 收集输出 (1级流水线延迟，第一个结果在输入后1个周期出现)
    await RisingEdge(dut.clk)  # 等待第一个结果
    
    output_count = 0
    for cycle in range(len(test_cases) + 2):  # 额外等待确保所有结果出现
        if dut.valid_out.value == 1:
            actual_result = dut.inv_sigma_out.value.signed_integer & 0xFFFF
            expected_result = expected_results[output_count]
            
            print(f"Output cycle {cycle}: got 0x{actual_result:04X}, expected 0x{expected_result:04X}")
            
            error = abs(actual_result - expected_result)
            assert error <= 1, f"Pipeline output {output_count}: error {error}"
            
            output_count += 1
            if output_count >= len(test_cases):
                break
        
        await RisingEdge(dut.clk)
    
    assert output_count == len(test_cases), f"Expected {len(test_cases)} outputs, got {output_count}"
    print(f"✓ Pipeline throughput test passed! Processed {output_count} results in {output_count+1} cycles")

@cocotb.test()
async def test_lut_edge_cases(dut):
    """测试LUT边界情况"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Test LUT Edge Cases ===")
    
    # 边界情况测试
    edge_cases = [
        {"var": 0x0000, "desc": "Zero variance"},
        {"var": 0x7FFF, "desc": "Maximum variance"},
        {"var": 0x0005, "desc": "Very small variance"},
        {"var": 0x5000, "desc": "Large variance"},
    ]
    
    test_mean = to_q5_10(0.0)
    test_diff = [to_q5_10(0.0)] * 16
    
    for case in edge_cases:
        print(f"\n--- Edge case: {case['desc']} ---")
        
        # 输入数据
        dut.valid_in.value = 1
        set_input_data(dut, case['var'], test_mean, test_diff)
        
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        await RisingEdge(dut.clk)
        
        # 检查输出
        assert dut.valid_out.value == 1, f"Valid output should be high for {case['desc']}"
        
        actual_result = dut.inv_sigma_out.value.signed_integer & 0xFFFF
        
        print(f"Input: 0x{case['var']:04X} = {from_q5_10(case['var']):.3f}")
        print(f"Output: 0x{actual_result:04X} = {from_q5_10(actual_result):.3f}")
        
        # 基本合理性检查
        assert actual_result > 0, f"Output should be positive for {case['desc']}"
        assert actual_result < 0x8000, f"Output should be reasonable for {case['desc']}"
        
        await ClockCycles(dut.clk, 2)
    
    print("✓ Edge cases test passed!")

# 运行所有测试
if __name__ == "__main__":
    import os
    os.environ["SIM"] = "icarus"
    os.environ["TOPLEVEL"] = "inv_sqrt_lut_simple"
    os.environ["TOPLEVEL_LANG"] = "verilog"
    os.environ["VERILOG_SOURCES"] = "inv_sqrt_lut_simple.v"
    
    import pytest
    pytest.main([__file__])