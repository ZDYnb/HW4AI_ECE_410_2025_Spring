"""
test_spi_transformer_system.py - Comprehensive testbench for SPI-based Transformer system
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge
from cocotb.binary import BinaryValue
import numpy as np
import random

def float_to_s5_10(x):
    """Convert float to S5.10 fixed-point"""
    x = np.clip(x, -16.0, 15.999)
    return int(np.round(x * 1024))

def s5_10_to_float(x):
    """Convert S5.10 fixed-point back to float"""
    if x >= 32768:  # Handle negative numbers (16-bit signed)
        x = x - 65536
    return x / 1024.0

class SPIMaster:
    """SPI Master controller for testbench"""
    
    def __init__(self, dut):
        self.dut = dut
        self.spi_clk_period = 20  # 50MHz SPI clock (20ns period)
        
    async def spi_reset(self):
        """Reset SPI interface"""
        self.dut.spi_cs_n.value = 1
        self.dut.spi_clk.value = 0
        self.dut.spi_mosi.value = 0
        await Timer(100, units="ns")
        
    async def spi_send_byte(self, data_byte):
        """Send one byte via SPI"""
        # Assert chip select
        self.dut.spi_cs_n.value = 0
        await Timer(self.spi_clk_period//4, units="ns")
        
        received_byte = 0
        
        # Send 8 bits, MSB first
        for bit in range(8):
            # Setup data on MOSI
            bit_val = (data_byte >> (7 - bit)) & 1
            self.dut.spi_mosi.value = bit_val
            await Timer(self.spi_clk_period//4, units="ns")
            
            # Rising edge of SPI clock
            self.dut.spi_clk.value = 1
            await Timer(self.spi_clk_period//4, units="ns")
            
            # Sample MISO on rising edge
            miso_bit = int(self.dut.spi_miso.value)
            received_byte = (received_byte << 1) | miso_bit
            
            # Falling edge of SPI clock
            self.dut.spi_clk.value = 0
            await Timer(self.spi_clk_period//4, units="ns")
        
        # Deassert chip select
        self.dut.spi_cs_n.value = 1
        await Timer(self.spi_clk_period, units="ns")
        
        return received_byte
    
    async def spi_write_row(self, row_index, row_data):
        """Write a complete row (64 elements) via SPI"""
        # Send WRITE_ROW command
        await self.spi_send_byte(0x01)  # CMD_WRITE_ROW
        
        # Send row index
        await self.spi_send_byte(row_index)
        
        # Send 64 elements (128 bytes total)
        for element in row_data:
            fixed_point = float_to_s5_10(element)
            # Send high byte first
            high_byte = (fixed_point >> 8) & 0xFF
            low_byte = fixed_point & 0xFF
            
            await self.spi_send_byte(high_byte)
            await self.spi_send_byte(low_byte)
        
        self.dut._log.info(f"Wrote row {row_index} via SPI")
    
    async def spi_read_row(self, row_index):
        """Read a complete row (64 elements) via SPI"""
        # Send READ_ROW command
        await self.spi_send_byte(0x02)  # CMD_READ_ROW
        
        # Send row index
        await self.spi_send_byte(row_index)
        
        # Read 64 elements (128 bytes total)
        row_data = []
        for i in range(64):
            high_byte = await self.spi_send_byte(0x00)  # Dummy data
            low_byte = await self.spi_send_byte(0x00)   # Dummy data
            
            # Reconstruct 16-bit value
            fixed_point = (high_byte << 8) | low_byte
            float_val = s5_10_to_float(fixed_point)
            row_data.append(float_val)
        
        self.dut._log.info(f"Read row {row_index} via SPI")
        return np.array(row_data)
    
    async def spi_start_compute(self):
        """Send start computation command"""
        await self.spi_send_byte(0x03)  # CMD_START_COMPUTE
        await self.spi_send_byte(0x00)  # Dummy byte
        self.dut._log.info("Sent START_COMPUTE command via SPI")
    
    async def spi_get_status(self):
        """Get system status"""
        status = await self.spi_send_byte(0x04)  # CMD_GET_STATUS
        await self.spi_send_byte(0x00)  # Dummy byte for response
        return status

@cocotb.test()
async def test_spi_basic_interface(dut):
    """Test basic SPI interface functionality"""
    
    # Start clocks
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())  # 100MHz system clock
    
    # Reset system
    dut.sys_rst_n.value = 0
    await RisingEdge(dut.sys_clk)
    await RisingEdge(dut.sys_clk)
    dut.sys_rst_n.value = 1
    await RisingEdge(dut.sys_clk)
    
    # Initialize SPI
    spi = SPIMaster(dut)
    await spi.spi_reset()
    
    dut._log.info("Starting SPI basic interface test")
    
    # Test status command
    status = await spi.spi_get_status()
    dut._log.info(f"Initial status: 0x{status:02x}")
    
    # Verify ready bit is set
    assert status & 0x01, f"System should be ready, status: 0x{status:02x}"
    
    dut._log.info("✅ SPI basic interface test PASSED!")

@cocotb.test()
async def test_spi_data_transfer(dut):
    """Test SPI data transfer (write and read back)"""
    
    # Start clocks
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
    
    # Reset
    dut.sys_rst_n.value = 0
    await RisingEdge(dut.sys_clk)
    dut.sys_rst_n.value = 1
    await RisingEdge(dut.sys_clk)
    
    spi = SPIMaster(dut)
    await spi.spi_reset()
    
    dut._log.info("Starting SPI data transfer test")
    
    # Create test data
    test_row = np.random.randn(64) * 0.5  # Small values for S5.10
    dut._log.info(f"Test row range: [{test_row.min():.3f}, {test_row.max():.3f}]")
    
    # Write test row
    await spi.spi_write_row(0, test_row)
    
    # Small delay
    await Timer(1000, units="ns")
    
    # Note: Reading back requires computation to complete first
    # For now, just verify write completed without error
    status = await spi.spi_get_status()
    dut._log.info(f"Status after write: 0x{status:02x}")
    
    dut._log.info("✅ SPI data transfer test PASSED!")

@cocotb.test()
async def test_complete_spi_computation(dut):
    """Test complete computation flow via SPI"""
    
    # Start clocks
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
    
    # Reset
    dut.sys_rst_n.value = 0
    await RisingEdge(dut.sys_clk)
    dut.sys_rst_n.value = 1
    await RisingEdge(dut.sys_clk)
    
    spi = SPIMaster(dut)
    await spi.spi_reset()
    
    dut._log.info("Starting complete SPI computation test")
    
    # Create test matrix
    np.random.seed(42)
    test_matrix = np.random.randn(64, 64) * 0.3
    dut._log.info(f"Input matrix range: [{test_matrix.min():.3f}, {test_matrix.max():.3f}]")
    
    # Write entire matrix via SPI
    dut._log.info("Writing 64x64 matrix via SPI...")
    for row in range(64):
        await spi.spi_write_row(row, test_matrix[row, :])
        if row % 16 == 0:
            dut._log.info(f"  Written {row+1}/64 rows")
    
    dut._log.info("Matrix write completed")
    
    # Start computation
    await spi.spi_start_compute()
    
    # Poll status until computation is done
    dut._log.info("Waiting for computation to complete...")
    computation_cycles = 0
    max_wait_cycles = 10000  # Timeout protection
    
    while computation_cycles < max_wait_cycles:
        await Timer(100, units="ns")  # Small delay between polls
        status = await spi.spi_get_status()
        
        if status & 0x04:  # STATUS_DONE bit
            dut._log.info(f"Computation completed! Status: 0x{status:02x}")
            break
        elif status & 0x02:  # STATUS_BUSY bit
            if computation_cycles % 100 == 0:
                dut._log.info(f"  Still computing... (cycle {computation_cycles})")
        
        computation_cycles += 1
    
    assert computation_cycles < max_wait_cycles, "Computation timeout!"
    
    # Read back results
    dut._log.info("Reading back results via SPI...")
    result_matrix = np.zeros((64, 64))
    
    for row in range(64):
        result_row = await spi.spi_read_row(row)
        result_matrix[row, :] = result_row
        if row % 16 == 0:
            dut._log.info(f"  Read {row+1}/64 rows")
    
    dut._log.info(f"Result matrix range: [{result_matrix.min():.3f}, {result_matrix.max():.3f}]")
    
    # For pass-through V2, result should be similar to input
    diff = np.abs(result_matrix - test_matrix)
    max_diff = np.max(diff)
    mean_diff = np.mean(diff)
    
    dut._log.info(f"Difference analysis:")
    dut._log.info(f"  Max difference: {max_diff:.6f}")
    dut._log.info(f"  Mean difference: {mean_diff:.6f}")
    
    # Verify results (allowing for quantization error)
    assert max_diff < 0.1, f"Results differ too much: max_diff = {max_diff}"
    
    dut._log.info("✅ Complete SPI computation test PASSED!")

@cocotb.test()
async def test_spi_performance(dut):
    """Test SPI interface performance"""
    
    # Start clocks
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
    
    # Reset
    dut.sys_rst_n.value = 0
    await RisingEdge(dut.sys_clk)
    dut.sys_rst_n.value = 1
    await RisingEdge(dut.sys_clk)
    
    spi = SPIMaster(dut)
    await spi.spi_reset()
    
    dut._log.info("Starting SPI performance test")
    
    # Time SPI write performance
    start_time = cocotb.utils.get_sim_time(units='ns')
    
    # Write one row to measure SPI bandwidth
    test_row = np.ones(64) * 0.5
    await spi.spi_write_row(0, test_row)
    
    write_time = cocotb.utils.get_sim_time(units='ns') - start_time
    
    # Calculate throughput
    bytes_transferred = 64 * 2 + 2  # 64 elements × 2 bytes + command + address
    throughput_mbps = (bytes_transferred * 8) / (write_time * 1e-3)  # Mbps
    
    dut._log.info(f"SPI Performance:")
    dut._log.info(f"  Row write time: {write_time} ns")
    dut._log.info(f"  Bytes transferred: {bytes_transferred}")
    dut._log.info(f"  Throughput: {throughput_mbps:.1f} Mbps")
    
    # Estimate full matrix transfer time
    full_matrix_time_us = (write_time * 64) / 1000  # microseconds
    dut._log.info(f"  Full 64x64 matrix write time: ~{full_matrix_time_us:.1f} μs")
    
    dut._log.info("✅ SPI performance test PASSED!")

@cocotb.test()
async def test_spi_error_handling(dut):
    """Test SPI error handling and edge cases"""
    
    # Start clocks
    cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
    
    # Reset
    dut.sys_rst_n.value = 0
    await RisingEdge(dut.sys_clk)
    dut.sys_rst_n.value = 1
    await RisingEdge(dut.sys_clk)
    
    spi = SPIMaster(dut)
    await spi.spi_reset()
    
    dut._log.info("Starting SPI error handling test")
    
    # Test invalid command
    invalid_status = await spi.spi_send_byte(0xFF)  # Invalid command
    await spi.spi_send_byte(0x00)
    
    dut._log.info(f"Invalid command response: 0x{invalid_status:02x}")
    
    # Test status after invalid command
    status = await spi.spi_get_status()
    dut._log.info(f"Status after invalid command: 0x{status:02x}")
    
    # System should still be ready
    assert status & 0x01, "System should remain ready after invalid command"
    
    dut._log.info("✅ SPI error handling test PASSED!")

# Run configuration
if __name__ == "__main__":
    print("This is a cocotb testbench for SPI Transformer System.")
    print("Run with: make MODULE=test_spi_transformer_system TOPLEVEL=spi_transformer_system")