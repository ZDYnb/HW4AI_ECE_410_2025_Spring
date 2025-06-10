import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

def safe_int_convert(signal_value):
    try:
        return int(signal_value)
    except ValueError:
        return 0

@cocotb.test()
async def test_backend_only_fix(dut):
    """只测试Backend模块（不是完整processor）"""
    
    print("=== 测试Backend模块除法修复 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # 使用从调试中发现的真实数据
    exp_val = 0x0ADF      # 2783 decimal
    exp_sum = 0x000046DF  # 18143 decimal
    
    print(f"输入数据:")
    print(f"  exp_values[0] = 0x{exp_val:04X} ({exp_val})")
    print(f"  exp_sum = 0x{exp_sum:08X} ({exp_sum})")
    
    # 手工计算期望结果
    numerator = exp_val * 1024
    expected = numerator // exp_sum
    
    print(f"手工计算:")
    print(f"  numerator = {exp_val} * 1024 = {numerator}")
    print(f"  expected = {numerator} / {exp_sum} = {expected} = 0x{expected:04X}")
    
    # 设置backend输入（这次是直接测试backend）
    dut.exp_sum_in.value = exp_sum
    dut.exp_values_in[0].value = exp_val
    for i in range(1, 16):
        dut.exp_values_in[i].value = exp_val  # 所有相同便于验证
    
    # 发送输入
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出
    for cycle in range(5):
        await RisingEdge(dut.clk)
        
        valid_out = safe_int_convert(dut.valid_out.value)
        if valid_out == 1:
            actual = safe_int_convert(dut.softmax_out[0].value)
            
            print(f"\n✅ Backend输出 (周期{cycle+1}):")
            print(f"  实际结果: 0x{actual:04X} ({actual})")
            print(f"  期望结果: 0x{expected:04X} ({expected})")
            
            if actual == 0:
                print(f"❌ 仍然输出零！需要检查除法逻辑")
            elif actual == expected:
                print(f"🎉 除法计算完全正确!")
            else:
                error_pct = abs(actual - expected) / expected * 100
                if error_pct < 5:
                    print(f"✅ 除法基本正确，误差{error_pct:.1f}%")
                else:
                    print(f"⚠️ 除法有误差{error_pct:.1f}%")
            
            # 检查归一化
            all_outputs = [safe_int_convert(dut.softmax_out[i].value) for i in range(16)]
            total_sum = sum(all_outputs)
            
            print(f"\n归一化检查:")
            print(f"  16个输出都是: 0x{actual:04X}")
            print(f"  总和: 0x{total_sum:04X} ({total_sum})")
            print(f"  期望: 0x0400 (1024)")
            
            break
    else:
        print("❌ 未收到Backend输出")

# Backend专用Makefile
makefile_backend = """
SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = softmax_backend.v
TOPLEVEL = softmax_backend
MODULE = correct_backend_test
EXTRA_ARGS += +define+DEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
"""

print("正确的Backend测试已创建!")
print("使用方法:")
print("1. 保存 correct_backend_test.py")
print("2. 更新Makefile测试backend模块:")
print("   TOPLEVEL = softmax_backend")
print("   MODULE = correct_backend_test") 
print("3. 运行: make")
print("")
print("这会直接测试backend模块的除法计算")