#!/usr/bin/env python3
"""
PE单元 cocotb测试
测试Systolic Processing Element的数据流和MAC功能
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

def float_to_s5_10(x):
    """转换浮点数到S5.10格式"""
    x = max(-16.0, min(15.999, x))
    return int(round(x * 1024)) & 0xFFFF

def s5_10_to_float(val):
    """S5.10转换回浮点数"""
    if val & 0x8000:  # 负数
        val = val - 0x10000
    return val / 1024.0

@cocotb.test()
async def test_pe_basic_mac(dut):
    """测试PE的基本MAC功能"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    await Timer(20, units="ns")
    
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    dut._log.info("🔍 PE基本MAC测试")
    
    # 测试1: 单次MAC运算
    dut._log.info("测试1: 基本MAC运算 2.0 * 3.0 = 6.0")
    
    await FallingEdge(dut.clk)  # 下降沿设置输入
    dut.a_in.value = float_to_s5_10(2.0)
    dut.b_in.value = float_to_s5_10(3.0)
    dut.enable.value = 1
    
    await RisingEdge(dut.clk)   # 上升沿更新
    await FallingEdge(dut.clk)  # 下降沿读取
    
    result = s5_10_to_float(dut.c_out.value.integer)
    a_out = s5_10_to_float(dut.a_out.value.integer)
    b_out = s5_10_to_float(dut.b_out.value.integer)
    
    dut._log.info(f"MAC结果: {result} (期望6.0)")
    dut._log.info(f"A输出: {a_out} (期望2.0)")
    dut._log.info(f"B输出: {b_out} (期望3.0)")
    
    assert abs(result - 6.0) < 0.01, f"MAC计算错误: {result} != 6.0"
    assert abs(a_out - 2.0) < 0.01, f"A数据流错误: {a_out} != 2.0"
    assert abs(b_out - 3.0) < 0.01, f"B数据流错误: {b_out} != 3.0"

@cocotb.test()
async def test_pe_accumulation(dut):
    """测试PE的累加功能"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")

    result = s5_10_to_float(dut.c_out.value.integer)
    a_out = s5_10_to_float(dut.a_out.value.integer)
    b_out = s5_10_to_float(dut.b_out.value.integer)
    
    dut._log.info(f"MAC结果: {result} (期望6.0)")
    dut._log.info(f"A输出: {a_out} (期望2.0)")
    dut._log.info(f"B输出: {b_out} (期望3.0)")
    dut.enable.value = 1
    
    # 计算点积: A = [1, 2, 3], B = [4, 5, 6]
    # 期望结果: 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    test_pairs = [(1.0, 4.0), (2.0, 5.0), (1, 1)]
    expected_results = [4.0, 14.0, 15.0]  # 累加中间结果
    
    for i, ((a_val, b_val), expected) in enumerate(zip(test_pairs, expected_results)):
        dut._log.info(f"步骤{i+1}: {a_val} * {b_val}, 累加到 {expected}")
        
        dut.a_in.value = float_to_s5_10(a_val)
        dut.b_in.value = float_to_s5_10(b_val)
        result = s5_10_to_float(dut.c_out.value.integer)
        # dut._log.info(f"累加结果: {result} (期望{expected})")
        await FallingEdge(dut.clk)
        
        result = s5_10_to_float(dut.c_out.value.integer)
        dut._log.info(f"累加结果: {result} (期望{expected})")
        
        assert abs(result - expected) < 0.01, f"累加错误: {result} != {expected}"

@cocotb.test()
async def test_pe_data_flow(dut):
    """测试PE的数据流传递"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    
    dut._log.info("🔍 PE数据流测试")
    
    # 测试数据流传递延迟
    test_data = [1.5, 2.5, 3.5, -1.0, -2.5]
    
    for i, val in enumerate(test_data):
        dut._log.info(f"周期{i}: 输入A={val}, B={val*2}")
        dut.a_in.value = float_to_s5_10(val)
        dut.b_in.value = float_to_s5_10(val * 2)
        
        await FallingEdge(dut.clk)
        
        a_out = s5_10_to_float(dut.a_out.value.integer)
        b_out = s5_10_to_float(dut.b_out.value.integer)
        
        dut._log.info(f"输出A={a_out}, B={b_out}")
        
        # 数据应该在同一个周期传递
        assert abs(a_out - val) < 0.01, f"A数据流延迟错误: {a_out} != {val}"
        assert abs(b_out - val*2) < 0.01, f"B数据流延迟错误: {b_out} != {val*2}"

@cocotb.test()
async def test_pe_2x2_systolic_simulation(dut):
    """模拟2x2 systolic array中一个PE的行为"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    
    dut._log.info("🔍 2x2 Systolic Array PE[0,0]行为模拟")
    dut._log.info("计算矩阵: A=[[1,2],[3,4]] × B=[[5,6],[7,8]]")
    dut._log.info("PE[0,0]应该计算: C[0,0] = 1*5 + 2*7 = 19")
    
    dut.enable.value = 1
    
    # 模拟systolic array的数据流模式
    # PE[0,0]会按序接收到: (A[0,0], B[0,0]), (A[0,1], B[1,0])
    systolic_data = [
        (1.0, 5.0),  # A[0,0] * B[0,0] = 5
        (2.0, 7.0),  # A[0,1] * B[1,0] = 14
    ]
    expected_partial = [5.0, 19.0]  # 中间累加结果
    
    for i, ((a_val, b_val), expected) in enumerate(zip(systolic_data, expected_partial)):
        dut._log.info(f"Systolic步骤{i+1}: A={a_val}, B={b_val}")
        dut.a_in.value = float_to_s5_10(a_val)
        dut.b_in.value = float_to_s5_10(b_val)
        
        await FallingEdge(dut.clk)
        
        result = s5_10_to_float(dut.c_out.value.integer)
        a_out = s5_10_to_float(dut.a_out.value.integer)
        b_out = s5_10_to_float(dut.b_out.value.integer)
        
        dut._log.info(f"PE输出: C={result}, A_out={a_out}, B_out={b_out}")
        
        assert abs(result - expected) < 0.01, f"Systolic计算错误: {result} != {expected}"
    
    dut._log.info(f"最终结果: C[0,0] = {result} ✅")

@cocotb.test()
async def test_pe_enable_control(dut):
    """测试PE的enable控制"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    dut.enable.value = 1
    dut._log.info("🔍 PE enable控制测试")
    
    # 设置初始值
    dut.a_in.value = float_to_s5_10(5.0)
    dut.b_in.value = float_to_s5_10(6.0)
    
    await FallingEdge(dut.clk)
    
    result1 = s5_10_to_float(dut.c_out.value.integer)
    dut._log.info(f"enable=1时结果: {result1} (期望30.0)")
    
    # 禁用后应该不再累加
    dut.a_in.value = float_to_s5_10(10.0)
    dut.b_in.value = float_to_s5_10(10.0)
    dut.enable.value = 0  # 禁用
    await FallingEdge(dut.clk)
    
    result2 = s5_10_to_float(dut.c_out.value.integer)
    dut._log.info(f"enable=0时结果: {result2} (应该还是30.0)")
    
    assert abs(result1 - 30.0) < 0.01, f"Enable测试失败: {result1} != 30.0"
    assert abs(result2 - 30.0) < 0.01, f"Disable测试失败: {result2} != 30.0"