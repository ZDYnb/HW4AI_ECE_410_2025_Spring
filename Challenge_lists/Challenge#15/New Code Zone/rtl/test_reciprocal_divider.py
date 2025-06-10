import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_reciprocal_basic(dut):
    """基本功能测试"""
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.exp_sum_in.value = 0
    
    # 初始化exp_values_in
    for i in range(16):
        dut.exp_values_in[i].value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("=== Reciprocal Divider Basic Test ===")
    
    # 测试用例 - 模拟softmax的典型输出
    test_cases = [
        ("16个exp(0)", 0x4000, [0x0400] * 16),      # 16*1024 = 16384
        ("8个exp(1)", 0x5798, [0x0ADF] * 8 + [0x0400] * 8),  # 约22424
        ("大值测试", 0x8000, [0x0800] * 16),         # 32768  
        ("小值测试", 0x2000, [0x0200] * 16),         # 8192
    ]
    
    for test_name, exp_sum, exp_values in test_cases:
        print(f"\n--- 测试: {test_name} ---")
        
        # 设置输入
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = exp_values[i]
        
        # 发送有效信号
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        print(f"输入: exp_sum=0x{exp_sum:04X} ({exp_sum})")
        print(f"期望倒数: 约 0x{int(65536/exp_sum*1024):04X}")
        
        # 等待流水线输出 (17周期)
        for cycle in range(20):
            await RisingEdge(dut.clk)
            
            if int(dut.valid_out.value) == 1:
                reciprocal = int(dut.reciprocal_out.value)
                print(f"✅ 周期{cycle+1}: 输出 reciprocal=0x{reciprocal:04X} ({reciprocal})")
                
                # 验证exp_values是否正确传递
                print("exp_values传递检查:")
                for i in [0, 7, 15]:  # 检查几个位置
                    expected = exp_values[i]
                    actual = int(dut.exp_values_out[i].value)
                    status = "✅" if actual == expected else "❌"
                    print(f"  {status} exp_values[{i}]: 期望=0x{expected:04X}, 实际=0x{actual:04X}")
                
                # 计算准确度
                expected_reciprocal = int(65536 * 1024 / exp_sum)  # 理论值
                error = abs(reciprocal - expected_reciprocal) / expected_reciprocal * 100
                print(f"准确度: 误差 {error:.2f}%")
                break
        else:
            print("❌ 超时未收到输出")
        
        # 等待几个周期再进行下一个测试
        for _ in range(3):
            await RisingEdge(dut.clk)

@cocotb.test()
async def test_reciprocal_pipeline(dut):
    """流水线连续测试"""
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== Reciprocal Pipeline Streaming Test ===")
    
    # 连续发送多个值
    test_inputs = [
        ("Input1", 0x4000, [0x0400] * 16),
        ("Input2", 0x6000, [0x0600] * 16), 
        ("Input3", 0x8000, [0x0800] * 16),
        ("Input4", 0x3000, [0x0300] * 16),
        ("Input5", 0x5000, [0x0500] * 16),
    ]
    
    print(f"连续发送 {len(test_inputs)} 个输入...")
    
    # 连续发送输入 (每周期一个)
    for i, (name, exp_sum, exp_values) in enumerate(test_inputs):
        print(f"周期{i+1}: 发送 {name}, exp_sum=0x{exp_sum:04X}")
        
        dut.exp_sum_in.value = exp_sum
        for j in range(16):
            dut.exp_values_in[j].value = exp_values[j]
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    # 停止发送
    dut.valid_in.value = 0
    
    # 收集输出
    print(f"\n--- 收集流水线输出 ---")
    outputs = []
    
    for cycle in range(25):  # 等待所有输出
        await RisingEdge(dut.clk)
        
        if int(dut.valid_out.value) == 1:
            output_num = len(outputs) + 1
            reciprocal = int(dut.reciprocal_out.value)
            outputs.append((cycle + len(test_inputs) + 1, reciprocal))
            
            print(f"输出{output_num} (周期{cycle + len(test_inputs) + 1}): reciprocal=0x{reciprocal:04X}")
        
        # 如果收到了所有期望的输出就停止
        if len(outputs) >= len(test_inputs):
            break
    
    # 分析流水线性能
    print(f"\n=== 流水线分析 ===")
    print(f"发送输入: {len(test_inputs)}")
    print(f"接收输出: {len(outputs)}")
    
    if len(outputs) >= len(test_inputs):
        print("✅ 所有输入都得到了输出!")
        
        # 计算延迟和吞吐量
        first_output_cycle = outputs[0][0]
        latency = first_output_cycle - 1  # 第一个输入在周期1
        print(f"流水线延迟: {latency} 周期")
        
        if len(outputs) > 1:
            # 检查输出间隔
            intervals = []
            for i in range(1, len(outputs)):
                interval = outputs[i][0] - outputs[i-1][0]
                intervals.append(interval)
            
            avg_interval = sum(intervals) / len(intervals)
            print(f"平均输出间隔: {avg_interval:.1f} 周期")
            
            if all(interval == 1 for interval in intervals):
                print("✅ 每周期输出一个结果 - 真流水线确认!")
            else:
                print("⚠️ 输出间隔不是1周期")
                print(f"输出间隔: {intervals}")
    else:
        print(f"❌ 只收到 {len(outputs)} 个输出，期望 {len(test_inputs)} 个")
    
    print("流水线测试完成!")

@cocotb.test() 
async def test_reciprocal_accuracy(dut):
    """精度测试"""
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== Reciprocal Accuracy Test ===")
    
    # 精度测试用例
    accuracy_tests = [
        0x1000,  # 4096
        0x2000,  # 8192  
        0x4000,  # 16384
        0x6000,  # 24576
        0x8000,  # 32768
        0xA000,  # 40960
        0xC000,  # 49152
    ]
    
    print("测试不同值的计算精度:")
    
    for exp_sum in accuracy_tests:
        # 设置输入
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = 0x0400
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # 等待输出
        for cycle in range(20):
            await RisingEdge(dut.clk)
            if int(dut.valid_out.value) == 1:
                reciprocal = int(dut.reciprocal_out.value)
                
                # 计算理论值 (1/exp_sum in Q5.10)
                theoretical = int(1024 * 1024 / exp_sum)  # Q5.10格式
                error = abs(reciprocal - theoretical) / theoretical * 100 if theoretical > 0 else 0
                
                print(f"exp_sum=0x{exp_sum:04X}: 输出=0x{reciprocal:04X}, 理论=0x{theoretical:04X}, 误差={error:.2f}%")
                break
        
        # 小延迟
        await RisingEdge(dut.clk)
    
    print("精度测试完成!")

# Makefile 内容
makefile_content = '''
# Cocotb Makefile for reciprocal divider test

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += reciprocal_divider.v

TOPLEVEL = reciprocal_divider  
MODULE = test_reciprocal_divider

include $(shell cocotb-config --makefiles)/Makefile.sim
'''