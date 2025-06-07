import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

@cocotb.test()
async def test_step1_basic_signals(dut):
    """Step 1: 测试基本信号和复位"""
    
    dut._log.info("🚀 Step 1: Testing basic signals")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位序列
    dut._log.info("  Applying reset...")
    dut.rst_n.value = 0      # 复位
    dut.spi_cs_n.value = 1   # CS不活跃
    dut.spi_sclk.value = 0   # SPI时钟低
    dut.spi_mosi.value = 0   # MOSI低
    
    await Timer(100, units='ns')  # 等待100ns
    
    dut.rst_n.value = 1      # 释放复位
    await Timer(50, units='ns')
    
    # 检查复位后的状态
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After reset: bit_count={bit_count}, data_ready={data_ready}, received_data=0x{received_data:02X}")
    
    # 验证复位状态
    assert bit_count == 0, f"bit_count should be 0, got {bit_count}"
    assert data_ready == 0, f"data_ready should be 0, got {data_ready}"
    assert received_data == 0, f"received_data should be 0, got 0x{received_data:02X}"
    
    dut._log.info("✅ Step 1: Basic signals test PASSED!")

@cocotb.test()
async def test_step2_single_bit(dut):
    """Step 2: 发送一个bit并检查移位寄存器"""
    
    dut._log.info("🚀 Step 2: Testing single bit transmission")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("  Starting SPI transaction...")
    
    # 激活CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # 发送第一个bit: 1
    dut._log.info("  Sending bit 1...")
    dut.spi_mosi.value = 1
    await Timer(10, units='ns')  # 建立时间
    
    # SPI时钟上升沿 - 接收数据
    dut.spi_sclk.value = 1
    await Timer(20, units='ns')
    
    # 检查状态
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    
    dut._log.info(f"  After 1st bit: bit_count={bit_count}, data_ready={data_ready}")
    
    # 验证第一个bit后的状态
    assert bit_count == 1, f"After 1 bit, bit_count should be 1, got {bit_count}"
    assert data_ready == 0, f"After 1 bit, data_ready should be 0, got {data_ready}"
    
    # SPI时钟下降沿
    dut.spi_sclk.value = 0
    await Timer(20, units='ns')
    
    # 发送第二个bit: 0
    dut._log.info("  Sending bit 0...")
    dut.spi_mosi.value = 0
    await Timer(10, units='ns')
    
    # SPI时钟上升沿
    dut.spi_sclk.value = 1
    await Timer(20, units='ns')
    
    # 检查状态
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    
    dut._log.info(f"  After 2nd bit: bit_count={bit_count}, data_ready={data_ready}")
    
    # 验证第二个bit后的状态
    assert bit_count == 2, f"After 2 bits, bit_count should be 2, got {bit_count}"
    assert data_ready == 0, f"After 2 bits, data_ready should be 0, got {data_ready}"
    
    # 结束事务
    dut.spi_sclk.value = 0
    dut.spi_cs_n.value = 1
    await Timer(20, units='ns')
    
    dut._log.info("✅ Step 2: Single bit transmission test PASSED!")

@cocotb.test()
async def test_step3_full_byte(dut):
    """Step 3: 发送完整的8位字节"""
    
    dut._log.info("🚀 Step 3: Testing full 8-bit byte transmission")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # 测试字节: 0xA5 = 10100101
    test_byte = 0xA5
    dut._log.info(f"  Sending byte: 0x{test_byte:02X} = {test_byte:08b}")
    
    # 激活CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # 发送8个bits
    for bit_pos in range(8):
        bit_value = (test_byte >> (7 - bit_pos)) & 1
        dut._log.info(f"    Bit {bit_pos}: sending {bit_value}")
        
        # 设置MOSI
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # SPI时钟上升沿
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        # 检查中间状态
        bit_count = int(dut.bit_count.value)
        data_ready = int(dut.data_ready.value)
        
        if bit_pos < 7:
            # 前7个bit: data_ready应该为0
            assert data_ready == 0, f"Bit {bit_pos}: data_ready should be 0, got {data_ready}"
            assert bit_count == bit_pos + 1, f"Bit {bit_pos}: bit_count should be {bit_pos + 1}, got {bit_count}"
        else:
            # 第8个bit: data_ready应该为1
            assert data_ready == 1, f"Bit {bit_pos}: data_ready should be 1, got {data_ready}"
            assert bit_count == 0, f"Bit {bit_pos}: bit_count should reset to 0, got {bit_count}"
        
        dut._log.info(f"      → bit_count={bit_count}, data_ready={data_ready}")
        
        # SPI时钟下降沿
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # 结束事务
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    # 检查最终存储的数据
    received_data = int(dut.received_data.value)
    dut._log.info(f"  Final result: received_data = 0x{received_data:02X}")
    
    # 验证存储的数据
    assert received_data == test_byte, f"Expected 0x{test_byte:02X}, got 0x{received_data:02X}"
    
    dut._log.info("✅ Step 3: Full byte transmission test PASSED!")
    dut._log.info("🎯 Ready for Step 4: Add loopback testing!")

@cocotb.test()
async def test_step4_loopback_output(dut):
    """Step 4: 测试SPI输出（loopback）功能 - 简化版本"""
    
    dut._log.info("🚀 Step 4: Testing SPI output (loopback)")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # 第一次传输：发送数据
    test_byte1 = 0xAA  # 10101010 - 容易验证的pattern
    dut._log.info(f"  First transaction: sending 0x{test_byte1:02X} = {test_byte1:08b}")
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # 发送第一个字节
    for bit_pos in range(8):
        bit_value = (test_byte1 >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    # 验证第一次传输被正确存储
    stored_data = int(dut.received_data.value)
    dut._log.info(f"  First transaction stored: 0x{stored_data:02X}")
    assert stored_data == test_byte1, f"Storage failed: expected 0x{test_byte1:02X}, got 0x{stored_data:02X}"
    
    # 第二次传输：应该在MISO收到第一次的数据
    test_byte2 = 0x55  # 01010101
    dut._log.info(f"  Second transaction: sending 0x{test_byte2:02X}")
    dut._log.info(f"  Expecting MISO to return: 0x{test_byte1:02X} (from first transaction)")
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    received_bits = []
    
    # 发送第二个字节，同时收集MISO
    for bit_pos in range(8):
        bit_value = (test_byte2 >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        dut.spi_sclk.value = 0
        miso_bit = int(dut.spi_miso.value)
        received_bits.append(miso_bit)
        await Timer(20, units='ns')
        
        dut._log.info(f"    Bit {bit_pos}: MOSI={bit_value}, MISO={miso_bit}")
    
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    # 重构接收到的字节 - 使用LSB first（我们确认硬件是LSB first）
    received_byte = 0
    for i, bit in enumerate(received_bits):
        received_byte |= (bit << i)  # LSB first重组
    
    dut._log.info(f"\n📊 Loopback Results:")
    dut._log.info(f"  Transaction 1: Sent=0x{test_byte1:02X}, Stored=0x{stored_data:02X}")
    dut._log.info(f"  Transaction 2: Sent=0x{test_byte2:02X}, MISO=0x{received_byte:02X}")
    dut._log.info(f"  Expected: MISO should be 0x{test_byte1:02X}")
    
    # 验证loopback
    assert received_byte == test_byte1, f"Loopback failed: expected 0x{test_byte1:02X}, got 0x{received_byte:02X}"
    
    # 验证第二次传输的存储
    final_stored = int(dut.received_data.value)
    assert final_stored == test_byte2, f"Second storage failed: expected 0x{test_byte2:02X}, got 0x{final_stored:02X}"
    
    dut._log.info("✅ Step 4: SPI loopback output test PASSED!")
    dut._log.info("🎯 Ready for Step 5: Add 16-bit data support!")

@cocotb.test()
async def test_step4_debug_output(dut):
    """Step 4 Debug: 详细调试SPI输出"""
    
    dut._log.info("🔧 Step 4 Debug: Detailed SPI output debugging")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # 先手动设置一个已知的tx_data值来测试
    # 我们先发送一个简单的字节来验证输出
    test_byte = 0xAA  # 10101010 - 容易识别的模式
    dut._log.info(f"  Testing with pattern: 0x{test_byte:02X} = {test_byte:08b}")
    
    # 第一次传输：发送数据并观察内部状态
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # 发送8个bits，详细观察内部状态
    for bit_pos in range(8):
        bit_value = (test_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # 在时钟沿之前检查状态
        tx_bit_count_before = int(dut.tx_bit_count.value)
        
        # SPI时钟上升沿（接收）
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        # 在时钟沿之后检查状态
        tx_bit_count_after = int(dut.tx_bit_count.value)
        bit_count = int(dut.bit_count.value)
        data_ready = int(dut.data_ready.value)
        
        # SPI时钟下降沿（发送）
        dut.spi_sclk.value = 0
        miso_bit = int(dut.spi_miso.value)
        await Timer(20, units='ns')
        
        dut._log.info(f"    Bit {bit_pos}: MOSI={bit_value}, MISO={miso_bit}")
        dut._log.info(f"      tx_bit_count: {tx_bit_count_before}→{tx_bit_count_after}, rx_bit_count={bit_count}, data_ready={data_ready}")
        
        # 如果是最后一个bit，检查数据是否准备好
        if bit_pos == 7:
            await Timer(30, units='ns')  # 等待系统时钟处理
            received_data = int(dut.received_data.value)
            dut._log.info(f"      After bit 7: received_data=0x{received_data:02X}")
    
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("🔧 First transaction debug completed")
    
    # 第二次传输：现在应该发送第一次接收的数据
    dut._log.info("  Starting second transaction...")
    test_byte2 = 0x55  # 01010101
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    received_bits = []
    
    for bit_pos in range(8):
        bit_value = (test_byte2 >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # 检查发送状态
        tx_bit_count_before = int(dut.tx_bit_count.value)
        tx_data_val = int(dut.tx_data.value) if hasattr(dut, 'tx_data') else 0
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        dut.spi_sclk.value = 0
        miso_bit = int(dut.spi_miso.value)
        received_bits.append(miso_bit)
        await Timer(20, units='ns')
        
        dut._log.info(f"    Bit {bit_pos}: MOSI={bit_value}, MISO={miso_bit}")
        dut._log.info(f"      tx_data=0x{tx_data_val:02X}, tx_bit_count={tx_bit_count_before}")
    
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    # 重构接收的数据 - 使用LSB first (硬件实际发送顺序)
    received_byte = 0
    for i, bit in enumerate(received_bits):
        received_byte |= (bit << i)  # LSB first: bit[0]→位置0, bit[1]→位置1
    
    dut._log.info(f"📊 Debug Results:")
    dut._log.info(f"  First sent:     0x{test_byte:02X} = {test_byte:08b}")
    dut._log.info(f"  Received bits:  {received_bits}")
    dut._log.info(f"  Received byte:  0x{received_byte:02X} = {received_byte:08b}")
    dut._log.info(f"  Match result:   {test_byte == received_byte}")
    
    # 验证loopback
    assert received_byte == test_byte, f"Loopback failed: expected 0x{test_byte:02X}, got 0x{received_byte:02X}"
    
@cocotb.test()
async def test_step5_16bit_data(dut):
    """Step 5: 测试16位数据传输"""
    
    dut._log.info("🚀 Step 5: Testing 16-bit data transmission")
    
    # 启动系统时钟
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # 复位
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # 测试16位数据: 0x1234
    test_data_16 = 0x1234
    high_byte = (test_data_16 >> 8) & 0xFF  # 0x12
    low_byte = test_data_16 & 0xFF         # 0x34
    
    dut._log.info(f"  Testing 16-bit data: 0x{test_data_16:04X}")
    dut._log.info(f"  High byte: 0x{high_byte:02X}, Low byte: 0x{low_byte:02X}")
    
    # 激活CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # 发送第一个字节（高字节）
    dut._log.info("  Sending high byte...")
    for bit_pos in range(8):
        bit_value = (high_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # 检查第一个字节的状态
    byte_count_16 = int(dut.byte_count_16.value)
    data_ready_16 = int(dut.data_ready_16.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After high byte: byte_count_16={byte_count_16}, data_ready_16={data_ready_16}")
    dut._log.info(f"  Received 8-bit: 0x{received_data:02X}")
    
    # 验证第一个字节后的状态
    assert byte_count_16 == 1, f"After first byte, byte_count_16 should be 1, got {byte_count_16}"
    assert data_ready_16 == 0, f"After first byte, data_ready_16 should be 0, got {data_ready_16}"
    assert received_data == high_byte, f"First byte should be 0x{high_byte:02X}, got 0x{received_data:02X}"
    
    # 发送第二个字节（低字节）
    dut._log.info("  Sending low byte...")
    for bit_pos in range(8):
        bit_value = (low_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # 等待系统时钟处理
    await Timer(50, units='ns')
    
    # 检查16位数据接收状态
    byte_count_16 = int(dut.byte_count_16.value)
    data_ready_16 = int(dut.data_ready_16.value)
    received_data_16 = int(dut.received_data_16.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After low byte: byte_count_16={byte_count_16}, data_ready_16={data_ready_16}")
    dut._log.info(f"  Received 16-bit: 0x{received_data_16:04X}")
    dut._log.info(f"  Received 8-bit: 0x{received_data:02X}")
    
    # 验证16位数据接收
    assert data_ready_16 == 1, f"After second byte, data_ready_16 should be 1, got {data_ready_16}"
    assert received_data_16 == test_data_16, f"16-bit data should be 0x{test_data_16:04X}, got 0x{received_data_16:04X}"
    assert received_data == low_byte, f"Last 8-bit should be 0x{low_byte:02X}, got 0x{received_data:02X}"
    
    # 结束事务
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("✅ Step 5: 16-bit data transmission test PASSED!")
    dut._log.info("🎯 Ready for Step 6: Matrix element transmission!")

    dut._log.info("✅ Debug test PASSED - LSB first confirmed!")