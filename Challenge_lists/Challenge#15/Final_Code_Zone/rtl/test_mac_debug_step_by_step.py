#!/usr/bin/env python3
"""
MAC unit cocotb test
Test S5.10 fixed-point multiplication and accumulation
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

def float_to_s5_10(x):
    """Convert float to S5.10 format"""
    x = max(-16.0, min(15.999, x))  # Limit range
    return int(round(x * 1024)) & 0xFFFF

def s5_10_to_float(x):
    """Convert S5.10 format to float"""
    if x & 0x8000:  # Negative number
        x = x - 65536
    return x / 1024.0

@cocotb.test()
async def test_mac_debug_step_by_step(dut):
    """Step-by-step debug of MAC operation"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.clear.value = 0
    dut.a.value = 0
    dut.b.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🔍 Step-by-step MAC debug test")
    
    # Step 1: Check state after reset
    await RisingEdge(dut.clk)
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"Result after reset: {result} (should be 0)")
    
    # Step 2: Set input but not enable
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    dut.enable.value = 0
    dut.clear.value = 0
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"Set input but enable=0: result={result} (should be 0)")
    
    # Step 3: First calculation - try just 1 cycle
    dut._log.info("Step 3: First calculation 2.0 * 3.0 (clear=1 to start new accumulation)")
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    dut.clear.value = 1  # Start new accumulation sequence
    dut.enable.value = 1
    await RisingEdge(dut.clk)  # Wait 1 cycle
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"First calculation result (after 1 cycle): {result} (expected 6.0)")
    
    await RisingEdge(dut.clk)  # Wait another cycle
    result2 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"First calculation result (after 2 cycles): {result2} (should still be 6.0)")
    
    # Step 4: Second calculation - accumulate mode, also need to wait
    dut._log.info("Step 4: Second calculation 1.0 * 1.0, accumulate mode")
    dut.a.value = float_to_s5_10(1.0)  # 1.0
    dut.b.value = float_to_s5_10(1.0)  # 1.0
    dut.clear.value = 0  # Accumulate mode
    dut.enable.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # Also need to wait one cycle
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"Result after accumulation: {result} (expected 6+1=7)")
    
    # Step 5: Test negative numbers - also need to wait
    dut._log.info("Step 5: Test negative 2.0 * (-3.0), clear=1")
    dut.a.value = float_to_s5_10(2.0)   # 2.0
    dut.b.value = float_to_s5_10(-3.0)  # -3.0
    dut.clear.value = 1  # Clear accumulator
    dut.enable.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # Wait for calculation to complete
    
    result = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"Negative multiplication result: {result} (expected -6.0)")
    
    # Print input hex values for debug
    a_hex = hex(float_to_s5_10(2.0))
    b_hex = hex(float_to_s5_10(-3.0))
    dut._log.info(f"Debug: 2.0 = {a_hex}, -3.0 = {b_hex}")

@cocotb.test()
async def test_mac_basic(dut):
    """Basic MAC functionality test"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.clear.value = 0
    dut.a.value = 0
    dut.b.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 Start basic MAC functionality test")
    
    # Test 1: Simple multiplication 2.0 * 3.0 = 6.0
    dut._log.info("Test 1: 2.0 * 3.0 = 6.0")
    
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    dut.enable.value = 1
    dut.a.value = float_to_s5_10(2.0)  # 2.0
    dut.b.value = float_to_s5_10(3.0)  # 3.0
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    expected = 6.0
    error = abs(result - expected)
    
    dut._log.info(f"   Input: 2.0 * 3.0")
    dut._log.info(f"   Expected: {expected}")
    dut._log.info(f"   Actual: {result:.3f}")
    dut._log.info(f"   Error: {error:.6f}")
    
    assert error < 0.01, f"Test 1 failed: error {error} too large"
    dut._log.info("   ✅ Test 1 passed")

@cocotb.test()
async def test_mac_accumulate(dut):
    """Accumulate functionality test"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 Accumulate functionality test")
    
    # Clear accumulator
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    # Accumulate sequence: 1*1 + 2*2 + 3*3 = 1 + 4 + 9 = 14
    test_pairs = [(1.0, 1.0), (2.0, 2.0), (3.0, 3.0)]
    expected_total = 14.0
    
    dut.enable.value = 1
    
    for i, (a_val, b_val) in enumerate(test_pairs):
        dut.a.value = float_to_s5_10(a_val)
        dut.b.value = float_to_s5_10(b_val)
        await RisingEdge(dut.clk)
        
        current_result = s5_10_to_float(dut.result.value.integer)
        dut._log.info(f"   Step {i+1}: {a_val} * {b_val}, accumulated result: {current_result:.3f}")
    
    final_result = s5_10_to_float(dut.result.value.integer)
    error = abs(final_result - expected_total)
    
    dut._log.info(f"   Final result: {final_result:.3f}")
    dut._log.info(f"   Expected result: {expected_total}")
    dut._log.info(f"   Error: {error:.6f}")
    
    assert error < 0.1, f"Accumulate test failed: error {error} too large"
    dut._log.info("   ✅ Accumulate test passed")

@cocotb.test()
async def test_mac_negative(dut):
    """Negative multiplication test"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 Negative multiplication test")
    
    # Test cases: positive*negative, negative*negative
    test_cases = [
        (2.0, -3.0, -6.0),    # positive * negative = negative
        (-2.0, -3.0, 6.0),    # negative * negative = positive  
        (-1.5, 4.0, -6.0),    # negative * positive = negative
        (0.0, -5.0, 0.0)      # zero * negative = zero
    ]
    
    for i, (a_val, b_val, expected) in enumerate(test_cases):
        # Clear accumulator
        dut.clear.value = 1
        await RisingEdge(dut.clk)
        dut.clear.value = 0
        
        # Perform operation
        dut.enable.value = 1
        dut.a.value = float_to_s5_10(a_val)
        dut.b.value = float_to_s5_10(b_val)
        await RisingEdge(dut.clk)
        
        result = s5_10_to_float(dut.result.value.integer)
        error = abs(result - expected)
        
        dut._log.info(f"   Test {i+1}: {a_val} * {b_val} = {result:.3f} (expected {expected})")
        
        assert error < 0.01, f"Negative test {i+1} failed: {a_val}*{b_val}, expected {expected}, got {result}"
    
    dut._log.info("   ✅ All negative tests passed")

@cocotb.test()
async def test_mac_enable_clear(dut):
    """enable and clear control signal test"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 Control signal test")
    
    # Test no accumulation when enable=0
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    dut.enable.value = 0  # Not enabled
    dut.a.value = float_to_s5_10(5.0)
    dut.b.value = float_to_s5_10(5.0)
    await RisingEdge(dut.clk)
    
    result1 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   Result when enable=0: {result1} (should be 0)")
    assert abs(result1) < 0.01, "Should not accumulate when enable=0"
    
    # Test clear function
    dut.enable.value = 1
    await RisingEdge(dut.clk)  # Now should accumulate
    
    result2 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   Result after enable=1: {result2} (should be 25)")
    
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    result3 = s5_10_to_float(dut.result.value.integer)
    dut._log.info(f"   Result after clear: {result3} (should be 0)")
    assert abs(result3) < 0.01, "Should be zero after clear"
    
    dut._log.info("   ✅ Control signal test passed")

@cocotb.test()
async def test_mac_overflow(dut):
    """Overflow test"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("🧪 Overflow boundary test")
    
    # Clear accumulator
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    
    # Test large values (near S5.10 boundary)
    dut.enable.value = 1
    dut.a.value = float_to_s5_10(15.0)  # Near max value
    dut.b.value = float_to_s5_10(15.0)
    await RisingEdge(dut.clk)
    
    result = s5_10_to_float(dut.result.value.integer)
    expected = 15.0 * 15.0  # 225
    
    dut._log.info(f"   Large value test: 15 * 15 = {result} (expected {expected})")
    dut._log.info(f"   Note: May overflow due to 16-bit limit")
    
    # This test is mainly for observation, no strict assertion
    dut._log.info("   ✅ Overflow test completed (observe behavior)")

if __name__ == "__main__":
    print("MAC unit cocotb test file")