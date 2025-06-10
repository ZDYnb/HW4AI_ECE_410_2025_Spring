# test_runner.py (FIXED VERSION)

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
import random

class SpiMaster:
    """一个简单的SPI Master驱动 (SPI Mode 0)"""
    def __init__(self, dut):
        self.dut = dut
        self.dut.spi_sclk.value = 0
        self.dut.spi_cs.value = 1
        self.dut.spi_mosi.value = 0

    async def _transceive_byte(self, tx_byte):
        """传输并接收一个字节"""
        rx_byte = 0
        for i in range(8):
            self.dut.spi_mosi.value = (tx_byte >> (7 - i)) & 1
            await Timer(50, units="ns")
            self.dut.spi_sclk.value = 1
            await Timer(50, units="ns")
            rx_bit = self.dut.spi_miso.value
            # The next line was causing the error because rx_bit was 'x'
            rx_byte = (rx_byte << 1) | int(rx_bit)
            self.dut.spi_sclk.value = 0
        return rx_byte

    async def write_burst(self, address, data):
        """突发写 (命令+地址+数据)"""
        self.dut._log.info(f"SPI Write Burst to Addr: {address:#06x}, Len: {len(data)} bytes")
        self.dut.spi_cs.value = 0
        await self._transceive_byte(0x02) # Command for Burst Write
        await self._transceive_byte((address >> 8) & 0xFF)
        await self._transceive_byte(address & 0xFF)
        for byte in data:
            await self._transceive_byte(byte)
        self.dut.spi_cs.value = 1

    async def read_reg(self, address):
        """读取一个16位的寄存器"""
        self.dut._log.info(f"SPI Read Register from Addr: {address:#06x}")
        self.dut.spi_cs.value = 0
        await self._transceive_byte(0x05) # Command for Register Read
        await self._transceive_byte((address >> 8) & 0xFF)
        await self._transceive_byte(address & 0xFF)
        high_byte = await self._transceive_byte(0)
        low_byte = await self._transceive_byte(0)
        self.dut.spi_cs.value = 1
        return (high_byte << 8) | low_byte

    async def write_reg(self, address, value):
        """写入一个16位的寄存器"""
        self.dut._log.info(f"SPI Write Register to Addr: {address:#06x} with Val: {value:#06x}")
        self.dut.spi_cs.value = 0
        await self._transceive_byte(0x06) # Command for Register Write
        await self._transceive_byte((address >> 8) & 0xFF)
        await self._transceive_byte(address & 0xFF)
        await self._transceive_byte((value >> 8) & 0xFF)
        await self._transceive_byte(value & 0xFF)
        self.dut.spi_cs.value = 1

    async def read_burst(self, address, length):
        """突发读"""
        self.dut._log.info(f"SPI Read Burst from Addr: {address:#06x}, Len: {length} bytes")
        self.dut.spi_cs.value = 0
        await self._transceive_byte(0x03) # Command for Burst Read
        await self._transceive_byte((address >> 8) & 0xFF)
        await self._transceive_byte(address & 0xFF)
        read_data = bytearray()
        for _ in range(length):
            byte = await self._transceive_byte(0)
            read_data.append(byte)
        self.dut.spi_cs.value = 1
        return read_data

@cocotb.test()
async def test_asic_full_flow(dut):
    """测试ASIC的完整加载、计算、读取流程"""
    
    # 启动ASIC的100MHz系统时钟
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
    
    # 实例化SPI Master驱动
    spi_master = SpiMaster(dut)

    # 定义常量
    ADDR_INPUT_RAM = 0x0000
    ADDR_OUTPUT_RAM = 0x0100
    ADDR_CONTROL_REG = 0xFF00
    ADDR_STATUS_REG = 0xFF01
    CMD_START_COMPUTATION = 0x0001
    STATUS_DONE = 0x0001
    DATA_LENGTH_BYTES = 512 # 16x16 matrix, 16-bit elements = 256 words = 512 bytes
    
    # 复位DUT
    dut._log.info("Resetting DUT...")
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    dut._log.info("DUT Reset Complete.")

    # ------------------ 测试流程开始 ------------------

    # 步骤 1: 加载随机的输入数据
    dut._log.info("--- PHASE 1: Loading Input Data ---")
    input_data = bytearray([random.randint(0, 255) for _ in range(DATA_LENGTH_BYTES)])
    await spi_master.write_burst(ADDR_INPUT_RAM, input_data)
    dut._log.info("Input data loading complete.")
    await Timer(100, units="ns")

    # 步骤 2: 发送 "开始计算" 命令
    dut._log.info("--- PHASE 2: Triggering Computation ---")
    await spi_master.write_reg(ADDR_CONTROL_REG, CMD_START_COMPUTATION)
    dut._log.info("'Start Computation' command sent.")
    await Timer(100, units="ns")

    # 步骤 3: 循环查询，直到计算完成
    dut._log.info("--- PHASE 3: Polling for Status ---")
    while True:
        status = await spi_master.read_reg(ADDR_STATUS_REG)
        dut._log.info(f"Polling Status Register... Got: {status:#06x}")
        if status == STATUS_DONE:
            dut._log.info("Computation Done!")
            break
        await Timer(1, units="us") # 等待1微秒再查询

    # 步骤 4: 读取输出结果
    dut._log.info("--- PHASE 4: Reading Output Result ---")
    result_data = await spi_master.read_burst(ADDR_OUTPUT_RAM, DATA_LENGTH_BYTES)
    dut._log.info(f"Successfully read {len(result_data)} bytes of result data.")

    # ------------------ 验证结果 ------------------
    dut._log.info("--- FINAL: Verifying Result ---")
    # 因为我们的Verilog只是把输入复制到输出，所以两者必须完全相等
    assert result_data == input_data, f"Verification FAILED! Result data does not match input data."
    dut._log.info("Verification PASSED! Result matches input perfectly. 🎉")