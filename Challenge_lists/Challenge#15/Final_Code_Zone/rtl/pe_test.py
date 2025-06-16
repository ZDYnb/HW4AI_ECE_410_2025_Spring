#!/usr/bin/env python3
"""
PE unit cocotb test
Test Systolic Processing Element data flow and MAC functionality
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

def float_to_s5_10(x):
    """Convert float to S5.10 format"""
    x = max(-16.0, min(15.999, x))
    return int(round(x * 1024)) & 0xFFFF

def s5_10_to_float(val):
    """Convert S5.10 format back to float"""
    if val & 0x8000:  # negative number
        val = val - 0x10000
    return val / 1024.0

@cocotb.test()
async def test_pe_basic_mac(dut):
    """Test basic MAC functionality of PE"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    await Timer(20, units="ns")
    
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    dut._log.info("🔍 PE Basic MAC Test")
    
    # Test 1: Single MAC operation
    dut._log.info("Test 1: Basic MAC operation 2.0 * 3.0 = 6.0")
    
    await FallingEdge(dut.clk)  # Set input on falling edge
    dut.a_in.value = float_to_s5_10(2.0)
    dut.b_in.value = float_to_s5_10(3.0)
    dut.enable.value = 1
    
    await RisingEdge(dut.clk)   # Update on rising edge
    await FallingEdge(dut.clk)  # Read on falling edge
    
    result = s5_10_to_float(dut.c_out.value.integer)
    a_out = s5_10_to_float(dut.a_out.value.integer)
    b_out = s5_10_to_float(dut.b_out.value.integer)
    
    dut._log.info(f"MAC result: {result} (expected 6.0)")
    dut._log.info(f"A output: {a_out} (expected 2.0)")
    dut._log.info(f"B output: {b_out} (expected 3.0)")
    
    assert abs(result - 6.0) < 0.01, f"MAC calculation error: {result} != 6.0"
    assert abs(a_out - 2.0) < 0.01, f"A data flow error: {a_out} != 2.0"
    assert abs(b_out - 3.0) < 0.01, f"B data flow error: {b_out} != 3.0"

@cocotb.test()
async def test_pe_accumulation(dut):
    """Test PE accumulation functionality"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")

    result = s5_10_to_float(dut.c_out.value.integer)
    a_out = s5_10_to_float(dut.a_out.value.integer)
    b_out = s5_10_to_float(dut.b_out.value.integer)
    
    dut._log.info(f"MAC result: {result} (expected 6.0)")
    dut._log.info(f"A output: {a_out} (expected 2.0)")
    dut._log.info(f"B output: {b_out} (expected 3.0)")
    dut.enable.value = 1
    
    # Compute dot product: A = [1, 2, 3], B = [4, 5, 6]
    # Expected result: 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    test_pairs = [(1.0, 4.0), (2.0, 5.0), (1, 1)]
    expected_results = [4.0, 14.0, 15.0]  # Intermediate accumulation results
    
    for i, ((a_val, b_val), expected) in enumerate(zip(test_pairs, expected_results)):
        dut._log.info(f"Step {i+1}: {a_val} * {b_val}, accumulate to {expected}")
        
        dut.a_in.value = float_to_s5_10(a_val)
        dut.b_in.value = float_to_s5_10(b_val)
        result = s5_10_to_float(dut.c_out.value.integer)
        # dut._log.info(f"Accumulation result: {result} (expected {expected})")
        await FallingEdge(dut.clk)
        
        result = s5_10_to_float(dut.c_out.value.integer)
        dut._log.info(f"Accumulation result: {result} (expected {expected})")
        
        assert abs(result - expected) < 0.01, f"Accumulation error: {result} != {expected}"

@cocotb.test()
async def test_pe_data_flow(dut):
    """Test PE data flow transmission"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    
    dut._log.info("🔍 PE Data Flow Test")
    
    # Test data flow transmission delay
    test_data = [1.5, 2.5, 3.5, -1.0, -2.5]
    
    for i, val in enumerate(test_data):
        dut._log.info(f"Cycle {i}: Input A={val}, B={val*2}")
        dut.a_in.value = float_to_s5_10(val)
        dut.b_in.value = float_to_s5_10(val * 2)
        
        await FallingEdge(dut.clk)
        
        a_out = s5_10_to_float(dut.a_out.value.integer)
        b_out = s5_10_to_float(dut.b_out.value.integer)
        
        dut._log.info(f"Output A={a_out}, B={b_out}")
        
        # Data should be transmitted in the same cycle
        assert abs(a_out - val) < 0.01, f"A data flow delay error: {a_out} != {val}"
        assert abs(b_out - val*2) < 0.01, f"B data flow delay error: {b_out} != {val*2}"

@cocotb.test()
async def test_pe_2x2_systolic_simulation(dut):
    """Simulate the behavior of a PE in a 2x2 systolic array"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    
    dut._log.info("🔍 2x2 Systolic Array PE[0,0] Behavior Simulation")
    dut._log.info("Compute matrix: A=[[1,2],[3,4]] × B=[[5,6],[7,8]]")
    dut._log.info("PE[0,0] should compute: C[0,0] = 1*5 + 2*7 = 19")
    
    dut.enable.value = 1
    
    # Simulate systolic array data flow mode
    # PE[0,0] will sequentially receive: (A[0,0], B[0,0]), (A[0,1], B[1,0])
    systolic_data = [
        (1.0, 5.0),  # A[0,0] * B[0,0] = 5
        (2.0, 7.0),  # A[0,1] * B[1,0] = 14
    ]
    expected_partial = [5.0, 19.0]  # Intermediate accumulation results
    
    for i, ((a_val, b_val), expected) in enumerate(zip(systolic_data, expected_partial)):
        dut._log.info(f"Systolic step {i+1}: A={a_val}, B={b_val}")
        dut.a_in.value = float_to_s5_10(a_val)
        dut.b_in.value = float_to_s5_10(b_val)
        
        await FallingEdge(dut.clk)
        
        result = s5_10_to_float(dut.c_out.value.integer)
        a_out = s5_10_to_float(dut.a_out.value.integer)
        b_out = s5_10_to_float(dut.b_out.value.integer)
        
        dut._log.info(f"PE output: C={result}, A_out={a_out}, B_out={b_out}")
        
        assert abs(result - expected) < 0.01, f"Systolic calculation error: {result} != {expected}"
    
    dut._log.info(f"Final result: C[0,0] = {result} ✅")

@cocotb.test()
async def test_pe_enable_control(dut):
    """Test PE enable control"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.a_in.value = float_to_s5_10(0)
    dut.b_in.value = float_to_s5_10(0)
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(20, units="ns")
    dut.enable.value = 1
    dut._log.info("🔍 PE Enable Control Test")
    
    # Set initial value
    dut.a_in.value = float_to_s5_10(5.0)
    dut.b_in.value = float_to_s5_10(6.0)
    
    await FallingEdge(dut.clk)
    
    result1 = s5_10_to_float(dut.c_out.value.integer)
    dut._log.info(f"Result when enable=1: {result1} (expected 30.0)")
    
    # Should not accumulate when disabled
    dut.a_in.value = float_to_s5_10(10.0)
    dut.b_in.value = float_to_s5_10(10.0)
    dut.enable.value = 0  # Disable
    await FallingEdge(dut.clk)
    
    result2 = s5_10_to_float(dut.c_out.value.integer)
    dut._log.info(f"Result when enable=0: {result2} (should still be 30.0)")
    
    assert abs(result1 - 30.0) < 0.01, f"Enable test failed: {result1} != 30.0"
    assert abs(result2 - 30.0) < 0.01, f"Disable test failed: {result2} != 30.0"