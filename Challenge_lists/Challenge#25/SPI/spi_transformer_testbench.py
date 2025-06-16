import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

@cocotb.test()
async def test_step1_basic_signals(dut):
    """Step 1: Test basic signals and reset"""
    
    dut._log.info("🚀 Step 1: Testing basic signals")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset sequence
    dut._log.info("  Applying reset...")
    dut.rst_n.value = 0      # Reset
    dut.spi_cs_n.value = 1   # CS inactive
    dut.spi_sclk.value = 0   # SPI clock low
    dut.spi_mosi.value = 0   # MOSI low
    
    await Timer(100, units='ns')  # Wait 100ns
    
    dut.rst_n.value = 1      # Release reset
    await Timer(50, units='ns')
    
    # Check status after reset
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After reset: bit_count={bit_count}, data_ready={data_ready}, received_data=0x{received_data:02X}")
    
    # Verify reset state
    assert bit_count == 0, f"bit_count should be 0, got {bit_count}"
    assert data_ready == 0, f"data_ready should be 0, got {data_ready}"
    assert received_data == 0, f"received_data should be 0, got 0x{received_data:02X}"
    
    dut._log.info("✅ Step 1: Basic signals test PASSED!")

@cocotb.test()
async def test_step2_single_bit(dut):
    """Step 2: Send one bit and check shift register"""
    
    dut._log.info("🚀 Step 2: Testing single bit transmission")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("  Starting SPI transaction...")
    
    # Activate CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # Send first bit: 1
    dut._log.info("  Sending bit 1...")
    dut.spi_mosi.value = 1
    await Timer(10, units='ns')  # Setup time
    
    # SPI clock rising edge - receive data
    dut.spi_sclk.value = 1
    await Timer(20, units='ns')
    
    # Check status
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    
    dut._log.info(f"  After 1st bit: bit_count={bit_count}, data_ready={data_ready}")
    
    # Verify state after first bit
    assert bit_count == 1, f"After 1 bit, bit_count should be 1, got {bit_count}"
    assert data_ready == 0, f"After 1 bit, data_ready should be 0, got {data_ready}"
    
    # SPI clock falling edge
    dut.spi_sclk.value = 0
    await Timer(20, units='ns')
    
    # Send second bit: 0
    dut._log.info("  Sending bit 0...")
    dut.spi_mosi.value = 0
    await Timer(10, units='ns')
    
    # SPI clock rising edge
    dut.spi_sclk.value = 1
    await Timer(20, units='ns')
    
    # Check status
    bit_count = int(dut.bit_count.value)
    data_ready = int(dut.data_ready.value)
    
    dut._log.info(f"  After 2nd bit: bit_count={bit_count}, data_ready={data_ready}")
    
    # Verify state after second bit
    assert bit_count == 2, f"After 2 bits, bit_count should be 2, got {bit_count}"
    assert data_ready == 0, f"After 2 bits, data_ready should be 0, got {data_ready}"
    
    # End transaction
    dut.spi_sclk.value = 0
    dut.spi_cs_n.value = 1
    await Timer(20, units='ns')
    
    dut._log.info("✅ Step 2: Single bit transmission test PASSED!")

@cocotb.test()
async def test_step3_full_byte(dut):
    """Step 3: Send a full 8-bit byte"""
    
    dut._log.info("🚀 Step 3: Testing full 8-bit byte transmission")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # Test byte: 0xA5 = 10100101
    test_byte = 0xA5
    dut._log.info(f"  Sending byte: 0x{test_byte:02X} = {test_byte:08b}")
    
    # Activate CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # Send 8 bits
    for bit_pos in range(8):
        bit_value = (test_byte >> (7 - bit_pos)) & 1
        dut._log.info(f"    Bit {bit_pos}: sending {bit_value}")
        
        # Set MOSI
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # SPI clock rising edge
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        # Check intermediate status
        bit_count = int(dut.bit_count.value)
        data_ready = int(dut.data_ready.value)
        
        if bit_pos < 7:
            # First 7 bits: data_ready should be 0
            assert data_ready == 0, f"Bit {bit_pos}: data_ready should be 0, got {data_ready}"
            assert bit_count == bit_pos + 1, f"Bit {bit_pos}: bit_count should be {bit_pos + 1}, got {bit_count}"
        else:
            # 8th bit: data_ready should be 1
            assert data_ready == 1, f"Bit {bit_pos}: data_ready should be 1, got {data_ready}"
            assert bit_count == 0, f"Bit {bit_pos}: bit_count should reset to 0, got {bit_count}"
        
        dut._log.info(f"      → bit_count={bit_count}, data_ready={data_ready}")
        
        # SPI clock falling edge
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # End transaction
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    # Check final stored data
    received_data = int(dut.received_data.value)
    dut._log.info(f"  Final result: received_data = 0x{received_data:02X}")
    
    # Verify stored data
    assert received_data == test_byte, f"Expected 0x{test_byte:02X}, got 0x{received_data:02X}"
    
    dut._log.info("✅ Step 3: Full byte transmission test PASSED!")
    dut._log.info("🎯 Ready for Step 4: Add loopback testing!")

@cocotb.test()
async def test_step4_loopback_output(dut):
    """Step 4: Test SPI output (loopback) function - simplified version"""
    
    dut._log.info("🚀 Step 4: Testing SPI output (loopback)")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # First transfer: send data
    test_byte1 = 0xAA  # 10101010 - easy to verify pattern
    dut._log.info(f"  First transaction: sending 0x{test_byte1:02X} = {test_byte1:08b}")
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # Send first byte
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
    
    # Verify first transfer is stored correctly
    stored_data = int(dut.received_data.value)
    dut._log.info(f"  First transaction stored: 0x{stored_data:02X}")
    assert stored_data == test_byte1, f"Storage failed: expected 0x{test_byte1:02X}, got 0x{stored_data:02X}"
    
    # Second transfer: should receive first data on MISO
    test_byte2 = 0x55  # 01010101
    dut._log.info(f"  Second transaction: sending 0x{test_byte2:02X}")
    dut._log.info(f"  Expecting MISO to return: 0x{test_byte1:02X} (from first transaction)")
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    received_bits = []
    
    # Send second byte, collect MISO
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
    
    # Reconstruct received byte - using LSB first (hardware confirmed LSB first)
    received_byte = 0
    for i, bit in enumerate(received_bits):
        received_byte |= (bit << i)  # LSB first reassembly
    
    dut._log.info(f"\n📊 Loopback Results:")
    dut._log.info(f"  Transaction 1: Sent=0x{test_byte1:02X}, Stored=0x{stored_data:02X}")
    dut._log.info(f"  Transaction 2: Sent=0x{test_byte2:02X}, MISO=0x{received_byte:02X}")
    dut._log.info(f"  Expected: MISO should be 0x{test_byte1:02X}")
    
    # Verify loopback
    assert received_byte == test_byte1, f"Loopback failed: expected 0x{test_byte1:02X}, got 0x{received_byte:02X}"
    
    # Verify second transfer storage
    final_stored = int(dut.received_data.value)
    assert final_stored == test_byte2, f"Second storage failed: expected 0x{test_byte2:02X}, got 0x{final_stored:02X}"
    
    dut._log.info("✅ Step 4: SPI loopback output test PASSED!")
    dut._log.info("🎯 Ready for Step 5: Add 16-bit data support!")

@cocotb.test()
async def test_step4_debug_output(dut):
    """Step 4 Debug: Detailed SPI output debugging"""
    
    dut._log.info("🔧 Step 4 Debug: Detailed SPI output debugging")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # Manually set a known tx_data value for testing
    # First send a simple byte to verify output
    test_byte = 0xAA  # 10101010 - easy to recognize pattern
    dut._log.info(f"  Testing with pattern: 0x{test_byte:02X} = {test_byte:08b}")
    
    # First transfer: send data and observe internal state
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # Send 8 bits, observe internal state in detail
    for bit_pos in range(8):
        bit_value = (test_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # Check state before clock edge
        tx_bit_count_before = int(dut.tx_bit_count.value)
        
        # SPI clock rising edge (receive)
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        
        # Check state after clock edge
        tx_bit_count_after = int(dut.tx_bit_count.value)
        bit_count = int(dut.bit_count.value)
        data_ready = int(dut.data_ready.value)
        
        # SPI clock falling edge (send)
        dut.spi_sclk.value = 0
        miso_bit = int(dut.spi_miso.value)
        await Timer(20, units='ns')
        
        dut._log.info(f"    Bit {bit_pos}: MOSI={bit_value}, MISO={miso_bit}")
        dut._log.info(f"      tx_bit_count: {tx_bit_count_before}→{tx_bit_count_after}, rx_bit_count={bit_count}, data_ready={data_ready}")
        
        # If last bit, check if data is ready
        if bit_pos == 7:
            await Timer(30, units='ns')  # Wait for system clock to process
            received_data = int(dut.received_data.value)
            dut._log.info(f"      After bit 7: received_data=0x{received_data:02X}")
    
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("🔧 First transaction debug completed")
    
    # Second transfer: now should send first received data
    dut._log.info("  Starting second transaction...")
    test_byte2 = 0x55  # 01010101
    
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    received_bits = []
    
    for bit_pos in range(8):
        bit_value = (test_byte2 >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        # Check send state
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
    
    # Reconstruct received data - using LSB first (actual hardware send order)
    received_byte = 0
    for i, bit in enumerate(received_bits):
        received_byte |= (bit << i)  # LSB first: bit[0]→position 0, bit[1]→position 1
    
    dut._log.info(f"📊 Debug Results:")
    dut._log.info(f"  First sent:     0x{test_byte:02X} = {test_byte:08b}")
    dut._log.info(f"  Received bits:  {received_bits}")
    dut._log.info(f"  Received byte:  0x{received_byte:02X} = {received_byte:08b}")
    dut._log.info(f"  Match result:   {test_byte == received_byte}")
    
    # Verify loopback
    assert received_byte == test_byte, f"Loopback failed: expected 0x{test_byte:02X}, got 0x{received_byte:02X}"
    
@cocotb.test()
async def test_step5_16bit_data(dut):
    """Step 5: Test 16-bit data transmission"""
    
    dut._log.info("🚀 Step 5: Testing 16-bit data transmission")
    
    # Start system clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.spi_cs_n.value = 1
    dut.spi_sclk.value = 0
    dut.spi_mosi.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await Timer(50, units='ns')
    
    # Test 16-bit data: 0x1234
    test_data_16 = 0x1234
    high_byte = (test_data_16 >> 8) & 0xFF  # 0x12
    low_byte = test_data_16 & 0xFF         # 0x34
    
    dut._log.info(f"  Testing 16-bit data: 0x{test_data_16:04X}")
    dut._log.info(f"  High byte: 0x{high_byte:02X}, Low byte: 0x{low_byte:02X}")
    
    # Activate CS
    dut.spi_cs_n.value = 0
    await Timer(20, units='ns')
    
    # Send first byte (high byte)
    dut._log.info("  Sending high byte...")
    for bit_pos in range(8):
        bit_value = (high_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # Check first byte status
    byte_count_16 = int(dut.byte_count_16.value)
    data_ready_16 = int(dut.data_ready_16.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After high byte: byte_count_16={byte_count_16}, data_ready_16={data_ready_16}")
    dut._log.info(f"  Received 8-bit: 0x{received_data:02X}")
    
    # Verify state after first byte
    assert byte_count_16 == 1, f"After first byte, byte_count_16 should be 1, got {byte_count_16}"
    assert data_ready_16 == 0, f"After first byte, data_ready_16 should be 0, got {data_ready_16}"
    assert received_data == high_byte, f"First byte should be 0x{high_byte:02X}, got 0x{received_data:02X}"
    
    # Send second byte (low byte)
    dut._log.info("  Sending low byte...")
    for bit_pos in range(8):
        bit_value = (low_byte >> (7 - bit_pos)) & 1
        dut.spi_mosi.value = bit_value
        await Timer(10, units='ns')
        
        dut.spi_sclk.value = 1
        await Timer(20, units='ns')
        dut.spi_sclk.value = 0
        await Timer(20, units='ns')
    
    # Wait for system clock to process
    await Timer(50, units='ns')
    
    # Check 16-bit data receive status
    byte_count_16 = int(dut.byte_count_16.value)
    data_ready_16 = int(dut.data_ready_16.value)
    received_data_16 = int(dut.received_data_16.value)
    received_data = int(dut.received_data.value)
    
    dut._log.info(f"  After low byte: byte_count_16={byte_count_16}, data_ready_16={data_ready_16}")
    dut._log.info(f"  Received 16-bit: 0x{received_data_16:04X}")
    dut._log.info(f"  Received 8-bit: 0x{received_data:02X}")
    
    # Verify 16-bit data receive
    assert data_ready_16 == 1, f"After second byte, data_ready_16 should be 1, got {data_ready_16}"
    assert received_data_16 == test_data_16, f"16-bit data should be 0x{test_data_16:04X}, got 0x{received_data_16:04X}"
    assert received_data == low_byte, f"Last 8-bit should be 0x{low_byte:02X}, got 0x{received_data:02X}"
    
    # End transaction
    dut.spi_cs_n.value = 1
    await Timer(50, units='ns')
    
    dut._log.info("✅ Step 5: 16-bit data transmission test PASSED!")
    dut._log.info("🎯 Ready for Step 6: Matrix element transmission!")

    dut._log.info("✅ Debug test PASSED - LSB first confirmed!")