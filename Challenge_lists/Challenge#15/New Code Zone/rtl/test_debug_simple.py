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

@cocotb.test()
async def test_simple_debug(dut):
    """简单测试调试版本"""
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Debug Test ===")
    
    # 测试用例：方差 = 1.0
    test_variance = to_q5_10(1.0)
    expected_inv_sqrt = to_q5_10(1.0)  # 1/√1 = 1
    
    print(f"Input variance: 0x{test_variance:04X} = {from_q5_10(test_variance):.4f}")
    print(f"Expected 1/√variance: 0x{expected_inv_sqrt:04X} = {from_q5_10(expected_inv_sqrt):.4f}")
    
    # 输入数据
    dut.valid_in.value = 1
    dut.variance_in.value = test_variance
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # 等待输出，观察debug信息
    for cycle in range(10):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            actual_inv_sqrt = dut.inv_sigma_out.value.signed_integer
            print(f"Output at cycle {cycle}: 0x{actual_inv_sqrt&0xFFFF:04X} = {from_q5_10(actual_inv_sqrt&0xFFFF):.4f}")
            break
    else:
        print("No valid output received!")
        assert False, "No output received"