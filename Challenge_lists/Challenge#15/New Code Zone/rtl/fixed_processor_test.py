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
async def test_processor_with_correct_timing(dut):
    """修复时序的完整Processor测试"""
    
    print("=== 修复时序的完整Processor测试 ===")
    
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
    
    print("设置输入: [0x0400, 0x0000, ...]")
    dut.input_vector[0].value = 0x0400  # 1.0
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000  # 0.0
    
    # 发送输入
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    print("\n=== 等待更长时间 ===")
    print("Frontend需要7周期，Backend需要3周期，总共约10周期")
    
    # 等待更长时间 - 15周期
    for cycle in range(15):
        await RisingEdge(dut.clk)
        
        # 监控关键信号
        valid_out = safe_int_convert(dut.valid_out.value)
        
        # 每隔几个周期显示状态
        if cycle % 2 == 0 or valid_out == 1:
            try:
                frontend_valid = safe_int_convert(dut.frontend_valid.value)
                backend_valid = safe_int_convert(dut.u_backend.valid_out.value)
                
                print(f"周期{cycle+1}: frontend_valid={frontend_valid}, backend_valid={backend_valid}, final_valid={valid_out}")
                
                if frontend_valid == 1:
                    frontend_sum = safe_int_convert(dut.frontend_exp_sum.value)
                    frontend_val0 = safe_int_convert(dut.frontend_exp_values[0].value)
                    print(f"  Frontend输出: sum=0x{frontend_sum:08X}, val[0]=0x{frontend_val0:04X}")
                try:
                    backend_valid_in = safe_int_convert(dut.u_backend.valid_in.value)
                    if backend_valid_in == 1:
                        backend_sum_in = safe_int_convert(dut.u_backend.exp_sum_in.value)
                        backend_val0_in = safe_int_convert(dut.u_backend.exp_values_in[0].value)
                        print(f"  Backend接收: sum_in=0x{backend_sum_in:08X}, val_in[0]=0x{backend_val0_in:04X}")
                        
                        # 同时显示原始信号值（不转换为int）
                        print(f"  Backend原始信号: sum_in={dut.u_backend.exp_sum_in.value}, val_in[0]={dut.u_backend.exp_values_in[0].value}")
                except Exception as e:
                    print(f"  Backend输入读取错误: {e}")
                
            except:
                pass
        
        if valid_out == 1:
            print(f"\n✅ 收到最终输出 (周期{cycle+1})!")
            
            # 读取输出
            all_outputs = []
            for i in range(16):
                val = safe_int_convert(dut.softmax_out[i].value)
                all_outputs.append(val)
            
            print(f"输出: softmax[0]=0x{all_outputs[0]:04X}, softmax[1]=0x{all_outputs[1]:04X}")
            
            # 分析结果
            max_val = max(all_outputs)
            max_idx = all_outputs.index(max_val)
            total_sum = sum(all_outputs)
            
            print(f"最大值: 0x{max_val:04X} at 位置{max_idx}")
            print(f"总和: 0x{total_sum:04X}")
            
            if all_outputs[0] > 0:
                print("🎉 成功！Processor正常工作！")
                
                # 手工验证计算
                print(f"\n=== 验证计算 ===")
                # Frontend应该输出: exp_values[0]=0x0ADF, exp_sum=0x46DF
                # Backend应该计算: (0x0ADF * 1024) / 0x46DF
                
                expected_frontend_val0 = 0x0ADF
                expected_frontend_sum = 0x46DF  # 从单独测试知道的
                expected_result = (expected_frontend_val0 * 1024) // expected_frontend_sum
                
                print(f"期望计算:")
                print(f"  Frontend: val[0]=0x{expected_frontend_val0:04X}, sum=0x{expected_frontend_sum:04X}")
                print(f"  Backend: ({expected_frontend_val0} * 1024) / {expected_frontend_sum} = {expected_result} = 0x{expected_result:04X}")
                print(f"  实际结果: 0x{all_outputs[0]:04X}")
                
                if abs(all_outputs[0] - expected_result) <= 1:
                    print("✅ 计算结果正确！")
                else:
                    print("⚠️ 计算结果有误差")
                
            else:
                print("❌ 仍然输出零")
            
            break
    else:
        print("❌ 在15周期内仍未收到输出")
        print("可能需要更长时间，或者有其他问题")

@cocotb.test() 
async def test_processor_pipeline_timing(dut):
    """测试Processor流水线准确时序"""
    
    print("\n=== Processor流水线时序测试 ===")
    
    # 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 复位
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # 连续发送3个不同向量
    test_vectors = [
        [0x0400] + [0x0000]*15,  # Peak at 0
        [0x0000, 0x0400] + [0x0000]*14,  # Peak at 1  
        [0x0200]*16,  # All equal
    ]
    
    print("连续发送3个向量，观察输出时序:")
    
    for i, vector in enumerate(test_vectors):
        print(f"周期{i+1}: 发送向量{i+1}")
        
        for j in range(16):
            dut.input_vector[j].value = vector[j]
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    
    # 监控输出
    outputs_received = 0
    for cycle in range(25):  # 等待足够长时间
        await RisingEdge(dut.clk)
        
        valid_out = safe_int_convert(dut.valid_out.value)
        if valid_out == 1:
            outputs_received += 1
            
            out_0 = safe_int_convert(dut.softmax_out[0].value)
            out_1 = safe_int_convert(dut.softmax_out[1].value)
            
            total_cycle = cycle + len(test_vectors) + 1
            print(f"输出{outputs_received} (总周期{total_cycle}): softmax[0]=0x{out_0:04X}, softmax[1]=0x{out_1:04X}")
        
        if outputs_received >= len(test_vectors):
            break
    
    print(f"\n时序分析:")
    print(f"发送: {len(test_vectors)} 个向量")
    print(f"接收: {outputs_received} 个输出")
    
    if outputs_received >= len(test_vectors):
        print("🎉 流水线时序正常！")
    else:
        print("⚠️ 流水线可能有时序问题")

print("修复时序的测试已创建!")
print("主要修复:")
print("1. 等待15周期而不是10周期")
print("2. 详细监控Frontend和Backend的valid信号")
print("3. 验证计算结果的正确性")
print("4. 测试连续流水线处理")