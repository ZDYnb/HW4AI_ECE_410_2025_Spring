#!/usr/bin/env python3
"""
matrix_display_test.py - 显示16x16矩阵数据的测试
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import numpy as np

class SPIMaster:
    """SPI主机模拟器"""
    
    def __init__(self, dut):
        self.dut = dut
        self.spi_clk_period = 1000  # 1MHz SPI时钟
    
    async def reset(self):
        """复位SPI总线"""
        self.dut.spi_cs.value = 1
        self.dut.spi_clk.value = 0
        self.dut.spi_mosi.value = 0
        await Timer(100, units="us")
    
    async def send_word(self, data):
        """发送一个16位数据"""
        for bit in range(16):
            bit_value = (data >> (15 - bit)) & 1
            self.dut.spi_mosi.value = bit_value
            
            await Timer(self.spi_clk_period // 2, units="ns")
            self.dut.spi_clk.value = 1
            await Timer(self.spi_clk_period // 2, units="ns")
            self.dut.spi_clk.value = 0
    
    async def receive_word(self):
        """接收一个16位数据"""
        received_data = 0
        
        for bit in range(16):
            await Timer(self.spi_clk_period // 2, units="ns")
            self.dut.spi_clk.value = 1
            
            await Timer(self.spi_clk_period // 4, units="ns")
            
            # 修复：处理X状态
            try:
                bit_value = self.dut.spi_miso.value.integer
            except ValueError as e:
                if "Unresolvable bit" in str(e):
                    self.dut._log.warning(f"MISO信号为X状态，位{bit}，假设为0")
                    bit_value = 0
                else:
                    raise e
            
            received_data = (received_data << 1) | bit_value
            
            await Timer(self.spi_clk_period // 4, units="ns")
            self.dut.spi_clk.value = 0
        
        return received_data
    
    async def write_matrix(self, matrix_data):
        """写入16x16矩阵数据"""
        self.dut.spi_cs.value = 0
        await Timer(5000, units="ns")
        
        for data in matrix_data:
            await self.send_word(data)
        
        await Timer(5000, units="ns")
        self.dut.spi_cs.value = 1
        await Timer(10000, units="ns")
    
    async def read_matrix(self):
        """读取16x16矩阵数据"""
        self.dut.spi_cs.value = 0
        await Timer(5000, units="ns")
        
        matrix_data = []
        for i in range(256):
            data = await self.receive_word()
            matrix_data.append(data)
        
        await Timer(5000, units="ns")
        self.dut.spi_cs.value = 1
        await Timer(1000, units="ns")
        
        return matrix_data

def print_matrix_16x16(matrix_data, title="16x16 Matrix"):
    """漂亮地打印16x16矩阵"""
    print(f"\n{'='*80}")
    print(f"{title:^80}")
    print(f"{'='*80}")
    
    # 转换为numpy数组以便处理
    matrix = np.array(matrix_data).reshape(16, 16)
    
    # 打印列标题
    print("    ", end="")
    for col in range(16):
        print(f"{col:4d}", end="")
    print("\n" + "-" * 80)
    
    # 打印每一行
    for row in range(16):
        print(f"{row:2d}: ", end="")
        for col in range(16):
            print(f"{matrix[row, col]:4X}", end="")
        print()
    
    print("=" * 80)

def analyze_matrix_data(input_matrix, output_matrix):
    """分析输入输出矩阵的关系"""
    print(f"\n{'='*60}")
    print(f"{'数据分析':^60}")
    print(f"{'='*60}")
    
    # 基本统计
    input_array = np.array(input_matrix)
    output_array = np.array(output_matrix)
    
    print(f"输入数据范围: 0x{input_array.min():04X} ~ 0x{input_array.max():04X}")
    print(f"输出数据范围: 0x{output_array.min():04X} ~ 0x{output_array.max():04X}")
    
    # 检查是否相等
    differences = np.sum(input_array != output_array)
    if differences == 0:
        print("✅ 输出与输入完全相同 (直通模式)")
    else:
        print(f"❌ 有 {differences} 个位置的数据不同")
    
    # 显示前几个和后几个数据的对比
    print(f"\n前5个数据对比:")
    print(f"输入:  {[f'0x{x:04X}' for x in input_matrix[:5]]}")
    print(f"输出:  {[f'0x{x:04X}' for x in output_matrix[:5]]}")
    
    print(f"\n后5个数据对比:")
    print(f"输入:  {[f'0x{x:04X}' for x in input_matrix[-5:]]}")
    print(f"输出:  {[f'0x{x:04X}' for x in output_matrix[-5:]]}")
    
    print("=" * 60)

@cocotb.test()
async def test_matrix_display(dut):
    """完整的矩阵显示测试"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位系统
    dut.rst_n.value = 0
    await Timer(1000, units="ns")
    dut.rst_n.value = 1
    await Timer(1000, units="ns")
    
    # 创建SPI主机
    spi = SPIMaster(dut)
    await spi.reset()
    
    dut._log.info("🎯 开始16x16矩阵显示测试")
    
    # 生成有规律的测试数据
    print(f"\n{'='*80}")
    print(f"{'生成测试数据':^80}")
    print(f"{'='*80}")
    
    input_matrix = []
    for row in range(16):
        for col in range(16):
            # 创建有规律的数据：高字节=行号，低字节=列号
            value = (row << 8) | col
            input_matrix.append(value)
    
    print(f"数据规律: 每个元素 = (行号 << 8) | 列号")
    print(f"例如: 位置[0,0]=0x0000, 位置[1,5]=0x0105, 位置[15,15]=0x0F0F")
    
    # 显示输入矩阵
    print_matrix_16x16(input_matrix, "输入矩阵 (Input Matrix)")
    
    # 写入数据
    dut._log.info("📤 写入16x16矩阵数据...")
    await spi.write_matrix(input_matrix)
    
    # 等待计算完成
    dut._log.info("⏳ 等待计算完成...")
    while True:
        await RisingEdge(dut.clk)
        if dut.system_state.value.integer == 3:  # READY状态
            break
    
    # 读取结果
    dut._log.info("📥 读取16x16矩阵结果...")
    output_matrix = await spi.read_matrix()
    
    # 显示输出矩阵
    print_matrix_16x16(output_matrix, "输出矩阵 (Output Matrix)")
    
    # 分析数据
    analyze_matrix_data(input_matrix, output_matrix)
    
    # 验证结果
    if input_matrix == output_matrix:
        dut._log.info("✅ 测试通过! 输入输出矩阵完全一致")
        print(f"\n🎉 测试成功! 16x16矩阵数据传输正确")
    else:
        dut._log.error("❌ 测试失败! 输入输出矩阵不一致")
        assert False, "矩阵数据验证失败"

@cocotb.test()
async def test_random_matrix(dut):
    """随机矩阵测试"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位系统
    dut.rst_n.value = 0
    await Timer(1000, units="ns")
    dut.rst_n.value = 1
    await Timer(1000, units="ns")
    
    # 创建SPI主机
    spi = SPIMaster(dut)
    await spi.reset()
    
    dut._log.info("🎲 开始随机矩阵测试")
    
    # 生成随机测试数据
    np.random.seed(42)  # 固定种子以便重现
    input_matrix = [int(x) for x in np.random.randint(0, 0x10000, 256)]
    
    print_matrix_16x16(input_matrix, "随机输入矩阵")
    
    # 执行测试
    await spi.write_matrix(input_matrix)
    
    # 等待计算完成
    while True:
        await RisingEdge(dut.clk)
        if dut.system_state.value.integer == 3:
            break
    
    # 读取结果
    output_matrix = await spi.read_matrix()
    
    print_matrix_16x16(output_matrix, "随机输出矩阵")
    analyze_matrix_data(input_matrix, output_matrix)
    
    # 验证
    assert input_matrix == output_matrix, "随机矩阵测试失败"
    dut._log.info("✅ 随机矩阵测试通过!")

@cocotb.test()
async def test_edge_cases(dut):
    """边界情况测试"""
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位系统
    dut.rst_n.value = 0
    await Timer(1000, units="ns")
    dut.rst_n.value = 1
    await Timer(1000, units="ns")
    
    # 创建SPI主机
    spi = SPIMaster(dut)
    await spi.reset()
    
    dut._log.info("⚡ 开始边界情况测试")
    
    # 测试极值数据
    test_cases = [
        ("全零矩阵", [0x0000] * 256),
        ("全1矩阵", [0xFFFF] * 256),
        ("交替模式", [0xAAAA if i % 2 == 0 else 0x5555 for i in range(256)]),
        ("递增模式", [i for i in range(256)])
    ]
    
    for case_name, input_matrix in test_cases:
        print(f"\n{'='*60}")
        print(f"测试案例: {case_name}")
        print(f"{'='*60}")
        
        print_matrix_16x16(input_matrix, f"输入: {case_name}")
        
        # 执行测试
        await spi.write_matrix(input_matrix)
        
        # 等待计算完成
        while True:
            await RisingEdge(dut.clk)
            if dut.system_state.value.integer == 3:
                break
        
        # 读取结果
        output_matrix = await spi.read_matrix()
        
        print_matrix_16x16(output_matrix, f"输出: {case_name}")
        analyze_matrix_data(input_matrix, output_matrix)
        
        # 验证
        assert input_matrix == output_matrix, f"{case_name} 测试失败"
        dut._log.info(f"✅ {case_name} 测试通过!")

if __name__ == "__main__":
    print("这是矩阵显示测试文件")