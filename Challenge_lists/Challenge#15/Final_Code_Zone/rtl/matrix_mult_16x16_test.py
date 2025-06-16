#!/usr/bin/env python3
"""
16x16 Systolic Array Matrix Multiplier Test
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import numpy as np

def float_to_s5_10(x):
    """Convert float to S5.10 format"""
    x = max(-16.0, min(15.999, x))
    return int(round(x * 1024)) & 0xFFFF

def s5_10_to_float(val):
    """S5.10 to float conversion"""
    if val & 0x8000:  # negative
        val = val - 0x10000
    return val / 1024.0

async def setup_clock_and_reset(dut):
    """Setup clock and reset"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await Timer(10, units="ns")

async def load_matrices(dut, matrix_a, matrix_b):
    """Load input matrices into DUT"""
    await FallingEdge(dut.clk)  # Ensure clock is stable before loading
    # Convert to S5.10 format
    a_fixed = [[float_to_s5_10(val) for val in row] for row in matrix_a]
    b_fixed = [[float_to_s5_10(val) for val in row] for row in matrix_b]
    
    # Load matrix A (row-major)
    for i in range(16):
        for j in range(16):
            dut.matrix_a[i*16 + j].value = a_fixed[i][j]
    
    # Load matrix B (column-major for systolic array)
    for j in range(16):
        for i in range(16):
            dut.matrix_b[j*16 + i].value = b_fixed[i][j]

async def start_computation(dut):
    """Start matrix multiplication"""
    dut.start.value = 1
    await FallingEdge(dut.clk)

async def wait_for_completion(dut, timeout_cycles=1000):
    """Wait for computation to complete"""
    cycle_count = 0
    while dut.done.value != 1:
        await FallingEdge(dut.clk)
        cycle_count += 1
        if cycle_count > timeout_cycles:
            raise TimeoutError(f"Computation didn't complete within {timeout_cycles} cycles")
    
    dut._log.info(f"Computation completed in {cycle_count} cycles")
    return cycle_count

async def read_result_matrix(dut):
    """Read result matrix from DUT"""
    result_flat = []
    for i in range(256):
        val = dut.matrix_c[i].value.integer
        result_flat.append(s5_10_to_float(val))
    
    return np.array(result_flat).reshape(16, 16)

def print_matrix(matrix, name, precision=2, size=4):
    """Pretty print matrix (show only top-left corner)"""
    print(f"\n{name} (top-left {size}x{size}):")
    for i in range(min(size, matrix.shape[0])):
        row_str = "  ["
        for j in range(min(size, matrix.shape[1])):
            row_str += f"{matrix[i,j]:6.{precision}f}"
            if j < min(size, matrix.shape[1]) - 1:
                row_str += ", "
        row_str += "]"
        print(row_str)

def compare_matrices(result, expected, tolerance=0.1):
    """Compare two matrices with tolerance"""
    diff = np.abs(result - expected)
    max_error = np.max(diff)
    mean_error = np.mean(diff)
    
    print(f"\nMatrix Comparison:")
    print(f"  Max error: {max_error:.4f}")
    print(f"  Mean error: {mean_error:.4f}")
    print(f"  Tolerance: {tolerance}")
    
    return max_error < tolerance

@cocotb.test()
async def test_identity_matrix(dut):
    """Test with identity matrices"""
    
    await setup_clock_and_reset(dut)
    dut._log.info("🔍 Identity Matrix Test")
    
    # Create identity matrices
    I = np.eye(16)
    A = np.ones((16, 16)) * 0.5  # Small values to avoid overflow
    
    dut._log.info("Loading matrices...")
    await load_matrices(dut, A, I)
    
    dut._log.info("Starting computation...")
    await start_computation(dut)
    
    cycles = await wait_for_completion(dut)
    
    result = await read_result_matrix(dut)
    
    # A × I should equal A
    print_matrix(A, "Input A", size=4)
    print_matrix(result, "Result", size=4)
    
    assert compare_matrices(result, A, tolerance=0.05), "Identity test failed"
    dut._log.info("✅ Identity matrix test passed")

@cocotb.test()
async def test_small_matrices(dut):
    """Test with small known matrices"""
    
    await setup_clock_and_reset(dut)
    dut._log.info("🔍 Small Matrices Test")
    
    # Create simple test matrices
    A = np.zeros((16, 16))
    B = np.zeros((16, 16))
    
    # Fill top-left 2x2 with known values
    A[0:2, 0:2] = [[1.0, 2.0], [3.0, 4.0]]
    B[0:2, 0:2] = [[2.0, 0.0], [1.0, 3.0]]
    
    expected = np.zeros((16, 16))
    expected[0:2, 0:2] = [[4.0, 6.0], [10.0, 12.0]]  # Manual calculation
    
    await load_matrices(dut, A, B)
    await start_computation(dut)
    cycles = await wait_for_completion(dut)
    
    result = await read_result_matrix(dut)
    
    print_matrix(A, "Matrix A", size=2)
    print_matrix(B, "Matrix B", size=2)
    print_matrix(expected, "Expected", size=2)
    print_matrix(result, "Actual", size=2)
    
    assert compare_matrices(result[0:2, 0:2], expected[0:2, 0:2], tolerance=0.05), \
        "Small matrix test failed"
    
    dut._log.info("✅ Small matrices test passed")

@cocotb.test()
async def test_simple_values(dut):
    """Test with very simple values"""
    
    await setup_clock_and_reset(dut)
    dut._log.info("🔍 Simple Values Test")
    
    # Very simple matrices
    A = np.zeros((16, 16))
    B = np.zeros((16, 16))
    
    # Just test one element
    A[0, 0] = 2.0
    B[0, 0] = 3.0
    
    expected = np.zeros((16, 16))
    expected[0, 0] = 6.0  # 2.0 * 3.0 = 6.0
    
    await load_matrices(dut, A, B)
    await start_computation(dut)
    cycles = await wait_for_completion(dut)
    
    result = await read_result_matrix(dut)
    
    dut._log.info(f"A[0,0] = {A[0,0]}, B[0,0] = {B[0,0]}")
    dut._log.info(f"Expected C[0,0] = {expected[0,0]}")
    dut._log.info(f"Actual C[0,0] = {result[0,0]}")
    
    assert abs(result[0,0] - expected[0,0]) < 0.05, \
        f"Simple test failed: {result[0,0]} != {expected[0,0]}"
    
    dut._log.info("✅ Simple values test passed")

@cocotb.test()
async def test_timing_only(dut):
    """Test just the timing and control signals"""
    
    await setup_clock_and_reset(dut)
    dut._log.info("🔍 Timing Test")
    
    # Load zeros
    A = np.zeros((16, 16))
    B = np.zeros((16, 16))
    
    await load_matrices(dut, A, B)
    
    dut._log.info("Starting computation...")
    await start_computation(dut)
    
    # Monitor state if available
    cycle_count = 0
    while dut.done.value != 1 and cycle_count < 100:
        await RisingEdge(dut.clk)
        cycle_count += 1
        
        if cycle_count % 10 == 0:
            dut._log.info(f"Cycle {cycle_count}, done = {dut.done.value}")
    
    if dut.done.value == 1:
        dut._log.info(f"✅ Timing test passed - completed in {cycle_count} cycles")
    else:
        dut._log.error(f"❌ Timing test failed - timeout after {cycle_count} cycles")
        assert False, "Timing test timeout"