import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

@cocotb.test()
async def test_debug_calculation(dut):
    """详细调试计算过程"""
    
    print("=== 详细计算调试测试 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # 使用更简单的数值来调试
    exp_sum = 0x1000      # 4096 decimal
    exp_value = 0x0100    # 256 decimal
    
    print(f"测试输入:")
    print(f"  exp_sum = 0x{exp_sum:08X} ({exp_sum} decimal)")
    print(f"  exp_value = 0x{exp_value:04X} ({exp_value} decimal)")
    
    # 手工计算期望结果
    numerator = exp_value * 1024  # 256 * 1024 = 262144
    expected_result = numerator // exp_sum  # 262144 / 4096 = 64
    print(f"  numerator = {exp_value} * 1024 = {numerator}")
    print(f"  expected = {numerator} / {exp_sum} = {expected_result} = 0x{expected_result:04X}")
    
    # 设置输入
    dut.exp_sum_in.value = exp_sum
    for i in range(16):
        dut.exp_values_in[i].value = exp_value
    
    # 发送有效信号
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出并观察每个阶段
    print(f"\n流水线追踪:")
    for cycle in range(6):
        await RisingEdge(dut.clk)
        
        # 读取流水线状态
        try:
            valid_out = int(dut.valid_out.value)
            softmax_0 = int(dut.softmax_out[0].value)
            
            print(f"  周期{cycle+1}: valid_out={valid_out}, softmax[0]=0x{softmax_0:04X}")
            
            if valid_out == 1:
                print(f"\n✅ 收到输出!")
                print(f"  实际结果: 0x{softmax_0:04X} ({softmax_0} decimal)")
                print(f"  期望结果: 0x{expected_result:04X} ({expected_result} decimal)")
                
                if softmax_0 == expected_result:
                    print(f"  🎉 计算正确!")
                elif softmax_0 == 0xFFFF:
                    print(f"  ❌ 结果饱和到最大值 - 可能是溢出")
                else:
                    error_pct = abs(softmax_0 - expected_result) / expected_result * 100
                    print(f"  ⚠️ 结果有误差: {error_pct:.1f}%")
                
                # 检查其他元素
                other_values = []
                for i in range(1, 4):  # 检查前几个
                    other_values.append(int(dut.softmax_out[i].value))
                
                if all(val == softmax_0 for val in other_values):
                    print(f"  ✅ 所有元素一致: {[hex(v) for v in other_values[:3]]}")
                else:
                    print(f"  ⚠️ 元素不一致: {[hex(v) for v in other_values[:3]]}")
                
                break
        except Exception as e:
            print(f"  周期{cycle+1}: 读取失败 - {e}")
    
    print(f"\n计算调试完成!")

@cocotb.test()
async def test_various_inputs(dut):
    """测试各种输入组合"""
    
    print(f"\n=== 多种输入测试 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    test_cases = [
        (0x0400, 0x0040, "小数值"),      # sum=1024, val=64
        (0x1000, 0x0100, "中等数值"),    # sum=4096, val=256  
        (0x4000, 0x0400, "较大数值"),    # sum=16384, val=1024
        (0x0040, 0x0004, "很小数值"),    # sum=64, val=4
    ]
    
    for exp_sum, exp_val, desc in test_cases:
        print(f"\n--- 测试: {desc} ---")
        print(f"exp_sum=0x{exp_sum:04X}, exp_val=0x{exp_val:04X}")
        
        # 复位
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)
        
        # 设置输入
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = exp_val
        
        # 计算期望
        numerator = exp_val * 1024
        if exp_sum > 0:
            expected = numerator // exp_sum
        else:
            expected = 0
        
        print(f"期望结果: 0x{expected:04X}")
        
        # 发送输入
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        for cycle in range(5):
            await RisingEdge(dut.clk)
            if int(dut.valid_out.value) == 1:
                actual = int(dut.softmax_out[0].value)
                print(f"实际结果: 0x{actual:04X}")
                
                if actual == expected:
                    print(f"✅ 正确")
                else:
                    print(f"❌ 错误 (期望0x{expected:04X})")
                break
        else:
            print(f"❌ 无输出")
    
    print(f"\n多种输入测试完成!")

# 更新Makefile，启用调试
makefile_with_debug = '''
SIM = icarus
TOPLEVEL_LANG = verilog  
VERILOG_SOURCES = softmax_backend.v
TOPLEVEL = softmax_backend
MODULE = debug_calculation_test
EXTRA_ARGS += +define+DEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
'''

print("调试测试已创建!")
print("这个测试会:")
print("1. 使用简单数值进行详细计算调试")
print("2. 显示每个流水线阶段的状态") 
print("3. 测试多种输入组合")
print("4. 启用DEBUG_SOFTMAX显示计算过程")
print("")
print("替换你的softmax_backend.v用修复版本，然后运行测试!")