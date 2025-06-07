import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

class SPIMaster:
    """简单的SPI主设备模拟"""
    
    def __init__(self, dut):
        self.dut = dut
        self.sclk = dut.spi_sclk
        self.mosi = dut.spi_mosi
        self.miso = dut.spi_miso
        self.cs_n = dut.spi_cs_n
        
    async def reset(self):
        """复位SPI信号"""
        self.cs_n.value = 1
        self.sclk.value = 0
        self.mosi.value = 0
        await Timer(100, units='ns')
        
    async def send_16bit(self, data):
        """发送16位数据"""
        received_data = 0
        
        # CS拉低开始传输
        self.cs_n.value = 0
        await Timer(50, units='ns')
        
        # 发送16位数据，MSB first
        for i in range(16):
            bit_to_send = (data >> (15 - i)) & 1
            
            # 时钟低电平，设置MOSI数据
            self.sclk.value = 0
            self.mosi.value = bit_to_send
            await Timer(50, units='ns')
            
            # 时钟高电平，采样MISO数据
            self.sclk.value = 1
            await Timer(10, units='ns')  # 等待建立时间
            miso_bit = int(self.miso.value)
            received_data = (received_data << 1) | miso_bit
            await Timer(40, units='ns')
            
        # 时钟回到低电平
        self.sclk.value = 0
        await Timer(50, units='ns')
        
        # CS拉高结束传输
        self.cs_n.value = 1
        await Timer(100, units='ns')
        
        return received_data

    async def send_matrix(self, matrix_data):
        """发送完整的64x64矩阵"""
        # CS拉低开始矩阵传输
        self.cs_n.value = 0
        await Timer(100, units='ns')
        
        for data in matrix_data:
            # 发送每个16位数据
            for i in range(16):
                bit_to_send = (data >> (15 - i)) & 1
                
                # 时钟低电平，设置数据
                self.sclk.value = 0
                self.mosi.value = bit_to_send
                await Timer(50, units='ns')
                
                # 时钟高电平
                self.sclk.value = 1
                await Timer(50, units='ns')
                
        # 时钟回到低电平
        self.sclk.value = 0
        await Timer(50, units='ns')
        
        # CS拉高结束传输
        self.cs_n.value = 1
        await Timer(100, units='ns')

    async def read_matrix(self, size=4096):
        """读取矩阵数据"""
        received_data = []
        
        # CS拉低开始读取
        self.cs_n.value = 0
        await Timer(100, units='ns')
        
        for word_idx in range(size):
            word_data = 0
            
            # 读取16位数据
            for i in range(16):
                # 时钟低电平
                self.sclk.value = 0
                self.mosi.value = 0  # 读取时MOSI可以是任意值
                await Timer(50, units='ns')
                
                # 时钟高电平，采样数据
                self.sclk.value = 1
                await Timer(10, units='ns')
                miso_bit = int(self.miso.value)
                word_data = (word_data << 1) | miso_bit
                await Timer(40, units='ns')
                
            received_data.append(word_data)
            
        # 时钟回到低电平
        self.sclk.value = 0
        await Timer(50, units='ns')
        
        # CS拉高结束传输
        self.cs_n.value = 1
        await Timer(100, units='ns')
        
        return received_data


@cocotb.test()
async def test_spi_basic(dut):
    """基础SPI功能测试"""
    
    # 启动系统时钟
    clock = Clock(dut.sys_clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 创建SPI主设备
    spi = SPIMaster(dut)
    
    # 复位
    dut.sys_rst_n.value = 0
    dut.read_enable.value = 0
    await spi.reset()
    await Timer(100, units='ns')
    dut.sys_rst_n.value = 1
    await Timer(100, units='ns')
    
    dut._log.info("=== 开始基础SPI测试 ===")
    
    # 测试单个16位数据传输
    test_data = 0xABCD
    dut._log.info(f"发送测试数据: 0x{test_data:04X}")
    
    received = await spi.send_16bit(test_data)
    dut._log.info(f"接收到数据: 0x{received:04X}")
    
    # 等待处理
    await Timer(500, units='ns')
    
    # 检查状态
    state = int(dut.fsm_state.value)
    dut._log.info(f"当前FSM状态: {state}")
    
    assert dut.matrix_valid.value == 0, "单个数据不应该使matrix_valid有效"


@cocotb.test()
async def test_spi_small_matrix(dut):
    """小矩阵测试（减少测试时间）"""
    
    # 启动时钟
    clock = Clock(dut.sys_clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    spi = SPIMaster(dut)
    
    # 复位
    dut.sys_rst_n.value = 0
    dut.read_enable.value = 0
    await spi.reset()
    await Timer(100, units='ns')
    dut.sys_rst_n.value = 1
    await Timer(100, units='ns')
    
    dut._log.info("=== 开始小矩阵测试 ===")
    
    # 创建测试数据（只测试前10个数据）
    test_matrix = []
    for i in range(10):
        test_matrix.append(0x1000 + i)
    
    dut._log.info(f"发送{len(test_matrix)}个测试数据")
    
    # 发送数据
    await spi.send_matrix(test_matrix)
    
    # 等待处理
    await Timer(1000, units='ns')
    
    # 检查状态
    data_count = int(dut.data_count.value)
    dut._log.info(f"接收到的数据个数: {data_count}")
    
    assert data_count == len(test_matrix), f"期望{len(test_matrix)}个数据，实际{data_count}个"


@cocotb.test()  
async def test_spi_write_read_cycle(dut):
    """完整的写-读循环测试"""
    
    # 启动时钟
    clock = Clock(dut.sys_clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    spi = SPIMaster(dut)
    
    # 复位
    dut.sys_rst_n.value = 0
    dut.read_enable.value = 0
    await spi.reset()
    await Timer(100, units='ns')
    dut.sys_rst_n.value = 1
    await Timer(100, units='ns')
    
    dut._log.info("=== 开始写-读循环测试 ===")
    
    # 创建测试矩阵（小一点，节省时间）
    test_size = 100  # 只测试100个数据点
    test_matrix = []
    for i in range(test_size):
        test_matrix.append(0x2000 + i)
    
    dut._log.info(f"第1步：发送{test_size}个数据")
    
    # 发送矩阵数据
    await spi.send_matrix(test_matrix)
    
    # 等待数据稳定
    await Timer(1000, units='ns')
    
    # 检查接收状态
    data_count = int(dut.data_count.value)
    dut._log.info(f"接收完成，数据个数: {data_count}")
    
    # 启用读取
    dut._log.info("第2步：启用读取并读回数据")
    dut.read_enable.value = 1
    await Timer(100, units='ns')
    
    # 读取数据
    received_matrix = await spi.read_matrix(test_size)
    
    dut._log.info(f"读取完成，收到{len(received_matrix)}个数据")
    
    # 验证数据
    errors = 0
    for i, (sent, received) in enumerate(zip(test_matrix, received_matrix)):
        if sent != received:
            dut._log.error(f"数据{i}: 发送0x{sent:04X}, 接收0x{received:04X}")
            errors += 1
        elif i < 5:  # 只打印前5个正确的数据
            dut._log.info(f"数据{i}: 0x{sent:04X} ✓")
    
    dut._log.info(f"验证完成，错误数: {errors}/{len(test_matrix)}")
    assert errors == 0, f"有{errors}个数据错误"


@cocotb.test()
async def test_spi_full_matrix(dut):
    """完整64x64矩阵测试（可选，时间较长）"""
    
    # 可以通过环境变量控制是否运行完整测试
    import os
    if not os.getenv('FULL_TEST'):
        dut._log.info("跳过完整矩阵测试（设置FULL_TEST=1启用）")
        return
    
    # 启动时钟
    clock = Clock(dut.sys_clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    spi = SPIMaster(dut)
    
    # 复位
    dut.sys_rst_n.value = 0
    dut.read_enable.value = 0
    await spi.reset()
    await Timer(100, units='ns')
    dut.sys_rst_n.value = 1
    await Timer(100, units='ns')
    
    dut._log.info("=== 开始完整64x64矩阵测试 ===")
    
    # 创建4096个测试数据
    test_matrix = []
    for i in range(4096):
        # 使用一些有意义的测试模式
        row = i // 64
        col = i % 64
        test_matrix.append((row << 8) | col)
    
    dut._log.info("发送4096个数据...")
    
    # 发送完整矩阵
    await spi.send_matrix(test_matrix)
    
    # 等待处理
    await Timer(5000, units='ns')
    
    # 检查状态
    assert int(dut.matrix_valid.value) == 1, "矩阵应该有效"
    assert int(dut.data_count.value) == 4096, "应该接收4096个数据"
    
    dut._log.info("64x64矩阵测试通过！")


# 辅助函数
def generate_test_pattern(size):
    """生成测试图案"""
    pattern = []
    for i in range(size):
        # 简单的计数器模式
        pattern.append(i & 0xFFFF)
    return pattern


# Makefile配置提示
"""
在Makefile中添加：

VERILOG_SOURCES = spi_transformer_interface.v
TOPLEVEL = spi_transformer_interface  
MODULE = test_spi

# 可选：启用完整测试
export FULL_TEST=1

# 运行：make SIM=verilator
"""