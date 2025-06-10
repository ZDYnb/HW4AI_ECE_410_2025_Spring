import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.regression import TestFactory
import numpy as np
import random

def to_q5_10(value):
    """将浮点数转换为Q5.10定点格式"""
    # 限制范围到 [-32, 31.999]
    value = max(-32.0, min(31.999, value))
    return int(value * 1024) & 0xFFFF

def from_q5_10(value):
    """将Q5.10定点格式转换为浮点数"""
    if value & 0x8000:  # 负数
        return (value - 65536) / 1024.0
    else:
        return value / 1024.0

def signed_diff(a, b):
    """计算两个16位有符号数的差值"""
    # 转换为正确的有符号表示
    def to_signed_16(val):
        val = val & 0xFFFF
        return val - 65536 if val & 0x8000 else val
    
    return abs(to_signed_16(a) - to_signed_16(b))

def reference_layernorm_preprocess(input_vector):
    """参考实现：计算均值、方差和差值向量 (Q5.10格式)"""
    # 转换为浮点数
    x = np.array([from_q5_10(val) for val in input_vector])
    
    # 计算均值
    mean = np.mean(x)
    
    # 计算差值
    diff = x - mean
    
    # 计算方差（加epsilon）
    variance = np.var(x) + 1.0/1024  # epsilon = 1 in Q5.10 ≈ 0.001
    
    # 转换回Q5.10格式
    mean_q5_10 = to_q5_10(mean)
    variance_q5_10 = to_q5_10(variance)
    diff_q5_10 = [to_q5_10(d) for d in diff]
    
    return mean_q5_10, variance_q5_10, diff_q5_10

def set_input_vector(dut, test_vector):
    """设置输入向量，使用新的CocoTB语法"""
    dut.input_vector_0.value = test_vector[0]
    dut.input_vector_1.value = test_vector[1]
    dut.input_vector_2.value = test_vector[2]
    dut.input_vector_3.value = test_vector[3]
    dut.input_vector_4.value = test_vector[4]
    dut.input_vector_5.value = test_vector[5]
    dut.input_vector_6.value = test_vector[6]
    dut.input_vector_7.value = test_vector[7]
    dut.input_vector_8.value = test_vector[8]
    dut.input_vector_9.value = test_vector[9]
    dut.input_vector_10.value = test_vector[10]
    dut.input_vector_11.value = test_vector[11]
    dut.input_vector_12.value = test_vector[12]
    dut.input_vector_13.value = test_vector[13]
    dut.input_vector_14.value = test_vector[14]
    dut.input_vector_15.value = test_vector[15]

def get_diff_vector(dut):
    """获取差值向量输出"""
    return [
        dut.diff_vector_0.value.signed_integer,
        dut.diff_vector_1.value.signed_integer,
        dut.diff_vector_2.value.signed_integer,
        dut.diff_vector_3.value.signed_integer,
        dut.diff_vector_4.value.signed_integer,
        dut.diff_vector_5.value.signed_integer,
        dut.diff_vector_6.value.signed_integer,
        dut.diff_vector_7.value.signed_integer,
        dut.diff_vector_8.value.signed_integer,
        dut.diff_vector_9.value.signed_integer,
        dut.diff_vector_10.value.signed_integer,
        dut.diff_vector_11.value.signed_integer,
        dut.diff_vector_12.value.signed_integer,
        dut.diff_vector_13.value.signed_integer,
        dut.diff_vector_14.value.signed_integer,
        dut.diff_vector_15.value.signed_integer
    ]

@cocotb.test()
async def test_simple_case(dut):
    """测试简单情况：全1向量"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # 测试用例：全1向量 (1.0 in Q5.10 = 0x0400 = 1024)
    test_vector = [0x0400] * 16  # 16个1.0
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Simple Case: All 1.0 ===")
    print(f"Input vector: {[hex(x) for x in test_vector]}")
    print(f"Expected mean: {expected_mean} (0x{expected_mean:04X}) = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} (0x{expected_var:04X}) = {from_q5_10(expected_var):.4f}")
    
    # 输入数据
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待流水线输出（9个时钟周期）
    for cycle in range(9):
        await RisingEdge(dut.clk)
        print(f"Cycle {cycle}: valid_out = {dut.valid_out.value}")
    
    # 检查输出
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} (0x{actual_mean&0xFFFF:04X}) = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} (0x{actual_var&0xFFFF:04X}) = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # 允许一定的误差（由于定点运算）
    mean_error = signed_diff(actual_mean, expected_mean)
    var_error = abs(actual_var - expected_var)
    
    print(f"Mean error: {mean_error}")
    print(f"Variance error: {var_error}")
    
    assert mean_error <= 2, f"Mean error too large: {mean_error}"
    assert var_error <= 10, f"Variance error too large: {var_error}"
    
    # 检查差值向量（应该全为0，因为所有元素都等于均值）
    print("Difference vector check:")
    actual_diff_vector = get_diff_vector(dut)
    for i in range(16):
        actual_diff = actual_diff_vector[i]
        expected_diff_val = expected_diff[i]
        diff_error = abs(actual_diff - expected_diff_val)
        print(f"  Diff[{i}]: expected {expected_diff_val}, actual {actual_diff}, error {diff_error}")
        assert diff_error <= 2, f"Diff vector error too large at index {i}: {diff_error}"
    
    print("✓ Simple case test passed!\n")

@cocotb.test()
async def test_zero_vector(dut):
    """测试零向量"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # 测试用例：全零向量
    test_vector = [0x0000] * 16
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Zero Vector ===")
    print(f"Expected mean: {expected_mean} = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} = {from_q5_10(expected_var):.4f}")
    
    # 输入数据
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待流水线输出
    await ClockCycles(dut.clk, 9)
    
    # 检查输出
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # 均值应该为0
    assert abs(actual_mean) <= 1, f"Mean should be ~0, got {actual_mean}"
    # 方差应该为epsilon (1 in Q5.10)
    assert actual_var == 1, f"Variance should be epsilon (1), got {actual_var}"
    
    print("✓ Zero vector test passed!\n")

@cocotb.test()
async def test_random_vector(dut):
    """测试随机向量"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # 生成随机测试向量（Q5.10格式，范围-4.0到4.0）
    test_vector = []
    for i in range(16):
        val = random.uniform(-4.0, 4.0)
        test_vector.append(to_q5_10(val))
    
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Random Vector ===")
    print("Random test vector:")
    for i, val in enumerate(test_vector):
        print(f"  [{i}] = 0x{val:04X} ({from_q5_10(val):.4f})")
    
    print(f"Expected mean: {expected_mean} (0x{expected_mean:04X}) = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} (0x{expected_var:04X}) = {from_q5_10(expected_var):.4f}")
    
    # 输入数据
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待流水线输出
    await ClockCycles(dut.clk, 10)
    
    # 检查输出
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} (0x{actual_mean&0xFFFF:04X}) = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} (0x{actual_var&0xFFFF:04X}) = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # 允许更大的误差，因为随机数据可能有更大的舍入误差
    mean_error = signed_diff(actual_mean, expected_mean)
    var_error = abs(actual_var - expected_var)
    
    print(f"Mean error: {mean_error}")
    print(f"Variance error: {var_error}")
    
    assert mean_error <= 10, f"Mean error too large: {mean_error}"
    assert var_error <= 50, f"Variance error too large: {var_error}"
    
    print("✓ Random vector test passed!\n")

@cocotb.test()
async def test_pipeline_throughput(dut):
    """测试流水线吞吐率：连续输入数据"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # 准备3组测试数据 (Q5.10格式)
    test_cases = [
        [0x0400] * 16,  # 全1.0 (1024 in decimal)
        [0x0200] * 16,  # 全0.5 (512 in decimal)
        [0x0800] * 16,  # 全2.0 (2048 in decimal)
    ]
    
    expected_results = []
    for test_case in test_cases:
        expected_results.append(reference_layernorm_preprocess(test_case))
    
    print("=== Test Pipeline Throughput ===")
    for i, test_case in enumerate(test_cases):
        print(f"Test case {i}: {[from_q5_10(x) for x in test_case[:4]]}... (all same)")
    
    # 连续输入3组数据
    for cycle, test_vector in enumerate(test_cases):
        dut.valid_in.value = 1
        set_input_vector(dut, test_vector)
        await RisingEdge(dut.clk)
        print(f"Input cycle {cycle}: data sent")
    
    dut.valid_in.value = 0
    
    # 等待并检查输出
    output_count = 0
    for cycle in range(16):  # 等待足够长的时间
        await RisingEdge(dut.clk)
        
        if dut.valid_out.value == 1:
            print(f"Output cycle {cycle}: valid output received")
            
            if output_count < len(expected_results):
                expected_mean, expected_var, expected_diff = expected_results[output_count]
                actual_mean = dut.mean_out.value.signed_integer
                actual_var = dut.variance_out.value.signed_integer
                
                print(f"  Result {output_count}:")
                print(f"    Expected mean={expected_mean} ({from_q5_10(expected_mean):.3f})")
                print(f"    Actual mean={actual_mean} ({from_q5_10(actual_mean&0xFFFF):.3f})")
                print(f"    Expected var={expected_var} ({from_q5_10(expected_var):.3f})")
                print(f"    Actual var={actual_var} ({from_q5_10(actual_var&0xFFFF):.3f})")
                
                # 基本检查
                mean_error = abs(actual_mean - expected_mean)
                var_error = abs(actual_var - expected_var)
                assert mean_error <= 10, f"Pipeline test {output_count}: mean error {mean_error}"
                assert var_error <= 50, f"Pipeline test {output_count}: var error {var_error}"
                
                output_count += 1
    
    assert output_count == 3, f"Expected 3 outputs, got {output_count}"
    print("✓ Pipeline throughput test passed!")

# 运行所有测试
if __name__ == "__main__":
    import os
    # 设置仿真器（默认使用icarus verilog）
    os.environ["SIM"] = "icarus"
    os.environ["TOPLEVEL"] = "layernorm_preprocess"
    os.environ["TOPLEVEL_LANG"] = "verilog"
    os.environ["VERILOG_SOURCES"] = "layernorm_preprocess.v"
    
    # 运行测试
    import pytest
    pytest.main([__file__])