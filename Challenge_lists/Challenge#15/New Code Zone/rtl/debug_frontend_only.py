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

def safe_hex_convert(signal_value):
    try:
        val = int(signal_value)
        return f"0x{val:04X}"
    except ValueError:
        return f"X({signal_value})"

@cocotb.test()
async def test_frontend_only_debug(dut):
    """单独测试Frontend模块"""
    
    print("=== Frontend单独调试测试 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    for i in range(16):
        dut.input_vector[i].value = 0
    
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    dut.rst_n.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    
    print("复位完成")
    
    # 测试简单输入
    print("\n=== 设置测试输入 ===")
    dut.input_vector[0].value = 0x0400  # 1.0
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000  # 0.0
    
    print("输入: [0x0400, 0x0000, ...]")
    print("期望: LUT[4] 应该给出某个EXP值")
    
    # 发送输入
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    print("\n=== Frontend流水线追踪 ===")
    
    # 监控更长时间 - Frontend可能需要更多周期
    for cycle in range(20):
        await RisingEdge(dut.clk)
        
        print(f"\n--- 周期 {cycle+1} ---")
        
        # 基本信号
        try:
            valid_in = safe_int_convert(dut.valid_in.value)
            valid_out = safe_int_convert(dut.valid_out.value)
            input_0 = safe_hex_convert(dut.input_vector[0].value)
            
            print(f"基本信号:")
            print(f"  valid_in: {valid_in}")
            print(f"  valid_out: {valid_out}")
            print(f"  input[0]: {input_0}")
        except Exception as e:
            print(f"基本信号读取错误: {e}")
        
        # LUT地址和输出 (如果能访问)
        try:
            # 尝试读取LUT相关信号
            if hasattr(dut, 'exp_lut_addr'):
                lut_addr_0 = safe_int_convert(dut.exp_lut_addr[0].value)
                print(f"  LUT地址[0]: {lut_addr_0}")
            
            if hasattr(dut, 'exp_lut_out'):
                lut_out_0 = safe_hex_convert(dut.exp_lut_out[0].value)
                print(f"  LUT输出[0]: {lut_out_0}")
        except Exception as e:
            print(f"LUT信号读取错误: {e}")
        
        # 流水线阶段
        try:
            if hasattr(dut, 'valid_stage'):
                print(f"流水线阶段:")
                for stage in range(6):
                    try:
                        stage_valid = safe_int_convert(dut.valid_stage[stage].value)
                        print(f"  valid_stage[{stage}]: {stage_valid}")
                    except:
                        print(f"  valid_stage[{stage}]: 无法读取")
        except Exception as e:
            print(f"流水线阶段读取错误: {e}")
        
        # Stage 0 数据
        try:
            if hasattr(dut, 'exp_s0'):
                exp_s0_0 = safe_hex_convert(dut.exp_s0[0].value)
                print(f"  exp_s0[0]: {exp_s0_0}")
        except:
            pass
        
        # 输出数据
        try:
            if valid_out == 1:
                exp_sum = safe_hex_convert(dut.exp_sum.value)
                exp_val_0 = safe_hex_convert(dut.exp_values[0].value)
                
                print(f"✅ Frontend输出:")
                print(f"  exp_sum: {exp_sum}")
                print(f"  exp_values[0]: {exp_val_0}")
                
                # 检查所有输出
                print(f"  完整exp_values:")
                for i in range(16):
                    val = safe_hex_convert(dut.exp_values[i].value)
                    print(f"    exp_values[{i:2d}]: {val}")
                
                break
        except Exception as e:
            print(f"输出读取错误: {e}")
    
    else:
        print("\n❌ Frontend在20个周期内没有输出")
        print("可能的问题:")
        print("1. Frontend流水线需要更多周期")
        print("2. Frontend逻辑有错误")
        print("3. LUT初始化有问题")

@cocotb.test()
async def test_frontend_lut_basic(dut):
    """测试Frontend LUT基础功能"""
    
    print("\n=== Frontend LUT基础测试 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # 测试LUT地址0
    print("测试 LUT[0] (输入 0x0000):")
    dut.input_vector[0].value = 0x0000
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000
    
    await RisingEdge(dut.clk)
    
    # 测试LUT地址1  
    print("测试 LUT[1] (输入 0x0100):")
    dut.input_vector[0].value = 0x0100
    
    await RisingEdge(dut.clk)
    
    # 测试LUT地址4
    print("测试 LUT[4] (输入 0x0400):")
    dut.input_vector[0].value = 0x0400
    
    await RisingEdge(dut.clk)
    
    print("LUT基础测试完成")

# Frontend专用Makefile
makefile_frontend = """
SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = softmax_frontend.v
TOPLEVEL = softmax_frontend
MODULE = debug_frontend_only
COMPILE_ARGS += -DDEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
"""

print("Frontend单独调试测试已创建!")
print("这会告诉我们:")
print("1. Frontend是否能正确启动")
print("2. LUT查找是否工作")
print("3. 流水线需要多少周期")
print("4. 哪个阶段出现问题")
print("")
print("运行方法:")
print("1. 保存 debug_frontend_only.py")
print("2. 创建Frontend专用Makefile:")
print("   TOPLEVEL = softmax_frontend")
print("   MODULE = debug_frontend_only")
print("3. 运行: make clean && make")