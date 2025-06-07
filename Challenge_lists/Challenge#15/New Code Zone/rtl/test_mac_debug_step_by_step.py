#!/usr/bin/env python3
"""
MAC单元 cocotb测试
测试S5.10定点数乘法累加功能
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

def float_to_s5_10(x):
    """转换浮点数到S5.10格式"""
    x = max(-16.0, min(15.999, x))  # 限制范围
    return int(round(x * 1024)) & 0xFFFF

def s5_10_to_float(x):
    """转换S5.10格式到浮点数"""
    if x & 0x8000:  # 负数
        x = x - 65536
    return x / 1024.0

@cocotb.test()
async def test_mac_debug_step_by_step(dut):
    """逐步调试MAC运算"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.clear.value = 0
    dut.a.value = 0
    dut.b.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🔍 MAC逐步调试测试")
    
    # 步骤1: 检查复位后状态
    await RisingEdge(dut.clk)
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"复位后result: {result} (应该是0)")
    
    # 步骤2: 设置输入但不enable
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    dut.enable.value = 0
    dut.clear.value = 0
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"设置输入但enable=0: result={result} (应该是0)")
    
    # 步骤3: 第一次计算 - 只等1个周期试试
    dut._log.info("步骤3: 第一次计算 2.0 * 3.0 (clear=1开始新累加)")
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    dut.clear.value = 1  # 开始新的累加序列
    dut.enable.value = 1
    await RisingEdge(dut.clk)  # 只等1个周期
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"第一次计算结果(1周期后): {result} (期望6.0)")
    
    await RisingEdge(dut.clk)  # 再等1个周期看看
    result2 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"第一次计算结果(2周期后): {result2} (应该还是6.0)")
    
    # 步骤4: 第二次计算 - 累加模式，也需要等待
    dut._log.info("步骤4: 第二次计算 1.0 * 1.0，累加模式")
    dut.a.value = float_to_s5_10(1.0)  # 1.0
    dut.b.value = float_to_s5_10(1.0)  # 1.0
    dut.clear.value = 0  # 累加模式
    dut.enable.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # 也需要等待一个周期
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"累加后结果: {result} (期望6+1=7)")
    
    # 步骤5: 测试负数 - 也需要等待
    dut._log.info("步骤5: 测试负数 2.0 * (-3.0)，clear=1")
    dut.a.value = float_to_s5_10(2.0)   # 2.0
    dut.b.value = float_to_s5_10(-3.0)  # -3.0
    dut.clear.value = 1  # 清除累加器
    dut.enable.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # 等待计算完成
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"负数乘法结果: {result} (期望-6.0)")
    
    # 打印输入的十六进制值用于调试
    a_hex = hex(float_to_s5_10(2.0))
    b_hex = hex(float_to_s5_10(-3.0))
    dut._log.info(f"调试: 2.0 = {a_hex}, -3.0 = {b_hex}")

@cocotb.test()
async def test_mac_basic(dut):
    """基本MAC功能测试"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.clear.value = 0
    dut.a.value = 0
    dut.b.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 开始MAC基本功能测试")
    
    # 测试1: 简单乘法 2.0 * 3.0 = 6.0
    dut._log.info("测试1: 2.0 * 3.0 = 6.0")
    
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    dut.enable.value = 1
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    expected = 6.0
    error = abs(result - expected)
    
    dut._log.info(f"   输入: 2.0 * 3.0")
    dut._log.info(f"   期望: {expected}")
    dut._log.info(f"   实际: {result:.3f}")
    dut._log.info(f"   误差: {error:.6f}")
    
    assert error < 0.01, f"测试1失败: 误差{error}过大"
    dut._log.info("   ✅ 测试1通过")

@cocotb.test()
async def test_mac_accumulate(dut):
    """累加功能测试"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 累加功能测试")
    
    # 清空累加器
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    # 累加序列: 1*1 + 2*2 + 3*3 = 1 + 4 + 9 = 14
    test_pairs = [(1.0, 1.0), (2.0, 2.0), (3.0, 3.0)]
    expected_total = 14.0
    
    dut.enable.value = 1
    
    for i, (a_val, b_val) in enumerate(test_pairs):
        dut.a.value = float_to_s5_10(a_val)
        dut.b.value = float_to_s5_10(b_val)
        await RisingEdge(dut.clk)
        
        current_result = s5_10_to_float(dut.result.value.integer)
        dut._log.info(f"   步骤{i+1}: {a_val} * {b_val}, 累加结果: {current_result:.3f}")
    
    final_result = s5_10_to_float(dut.result.value.integer)
    error = abs(final_result - expected_total)
    
    dut._log.info(f"   最终结果: {final_result:.3f}")
    dut._log.info(f"   期望结果: {expected_total}")
    dut._log.info(f"   误差: {error:.6f}")
    
    assert error < 0.1, f"累加测试失败: 误差{error}过大"
    dut._log.info("   ✅ 累加测试通过")

@cocotb.test()
async def test_mac_negative(dut):
    """负数乘法测试"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 负数乘法测试")
    
    # 测试用例: 正数*负数, 负数*负数
    test_cases = [
        (2.0, -3.0, -6.0),    # 正数 * 负数 = 负数
        (-2.0, -3.0, 6.0),    # 负数 * 负数 = 正数  
        (-1.5, 4.0, -6.0),    # 负数 * 正数 = 负数
        (0.0, -5.0, 0.0)      # 零 * 负数 = 零
    ]
    
    for i, (a_val, b_val, expected) in enumerate(test_cases):
        # 清空累加器
        dut.clear.value = 1
        await RisingEdge(dut.clk)
        dut.clear.value = 0
        
        # 执行运算
        dut.enable.value = 1
        dut.a.value = float_to_s5_10(a_val)
        dut.b.value = float_to_s5_10(b_val)
        await RisingEdge(dut.clk)
        
        result = s5_10_to_float(dut.result.value.integer)
        error = abs(result - expected)
        
        dut._log.info(f"   测试{i+1}: {a_val} * {b_val} = {result:.3f} (期望{expected})")
        
        assert error < 0.01, f"负数测试{i+1}失败: {a_val}*{b_val}, 期望{expected}, 实际{result}"
    
    dut._log.info("   ✅ 负数测试全部通过")

@cocotb.test()
async def test_mac_enable_clear(dut):
    """enable和clear控制信号测试"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 控制信号测试")
    
    # 测试enable=0时不累加
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    dut.enable.value = 0  # 不使能
    dut.a.value = float_to_s5_10(5.0)
    dut.b.value = float_to_s5_10(5.0)
    await RisingEdge(dut.clk)
    
    result1 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   enable=0时结果: {result1} (应该是0)")
    assert abs(result1) < 0.01, "enable=0时应该不累加"
    
    # 测试clear功能
    dut.enable.value = 1
    await RisingEdge(dut.clk)  # 现在应该累加
    
    result2 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   enable=1后结果: {result2} (应该是25)")
    
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    result3 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   clear后结果: {result3} (应该是0)")
    assert abs(result3) < 0.01, "clear后应该归零"
    
    dut._log.info("   ✅ 控制信号测试通过")

@cocotb.test()
async def test_mac_overflow(dut):
    """溢出测试"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 溢出边界测试")
    
    # 清空累加器
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    # 测试大数值 (接近S5.10的边界)
    dut.enable.value = 1
    dut.a.value = float_to_s5_10(15.0)  # 接近最大值
    dut.b.value = float_to_s5_10(15.0)
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    expected = 15.0 * 15.0  # 225
    
    dut._log.info(f"   大数值测试: 15 * 15 = {result} (期望{expected})")
    dut._log.info(f"   注意: 由于16位限制，可能会溢出")
    
    # 这个测试主要是观察行为，不做严格断言
    dut._log.info("   ✅ 溢出测试完成 (观察行为)")

if __name__ == "__main__":
    print("MAC单元cocotb测试文件")