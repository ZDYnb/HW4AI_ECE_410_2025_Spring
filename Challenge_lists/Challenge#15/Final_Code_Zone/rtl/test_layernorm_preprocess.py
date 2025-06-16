import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.regression import TestFactory
import numpy as np
import random

def to_q5_10(value):
    """Convert float to Q5.10 fixed-point format"""
    # Clamp range to [-32, 31.999]
    value = max(-32.0, min(31.999, value))
    return int(value * 1024) & 0xFFFF

def from_q5_10(value):
    """Convert Q5.10 fixed-point format to float"""
    if value & 0x8000:  # negative number
        return (value - 65536) / 1024.0
    else:
        return value / 1024.0

def signed_diff(a, b):
    """Calculate the difference between two 16-bit signed numbers"""
    # Convert to correct signed representation
    def to_signed_16(val):
        val = val & 0xFFFF
        return val - 65536 if val & 0x8000 else val
    
    return abs(to_signed_16(a) - to_signed_16(b))

def reference_layernorm_preprocess(input_vector):
    """Reference implementation: calculate mean, variance, and diff vector (Q5.10 format)"""
    # Convert to float
    x = np.array([from_q5_10(val) for val in input_vector])
    
    # Calculate mean
    mean = np.mean(x)
    
    # Calculate difference
    diff = x - mean
    
    # Calculate variance (add epsilon)
    variance = np.var(x) + 1.0/1024  # epsilon = 1 in Q5.10 ≈ 0.001
    
    # Convert back to Q5.10 format
    mean_q5_10 = to_q5_10(mean)
    variance_q5_10 = to_q5_10(variance)
    diff_q5_10 = [to_q5_10(d) for d in diff]
    
    return mean_q5_10, variance_q5_10, diff_q5_10

def set_input_vector(dut, test_vector):
    """Set input vector using new CocoTB syntax"""
    dut.input_vector_0.value = test_vector[0]
    dut.input_vector_1.value = test_vector[1]
    dut.input_vector_2.value = test_vector[2]
    dut.input_vector_3.value = test_vector[3]
    dut.input_vector_4.value = test_vector[4]
    dut.input_vector_5.value = test_vector[5]
    dut.input_vector_6.value = test_vector[6]
    dut.input_vector_7.value = test_vector[7]
    dut.input_vector_8.value = test_vector[8]
    dut.input_vector_9.value = test_vector[9]
    dut.input_vector_10.value = test_vector[10]
    dut.input_vector_11.value = test_vector[11]
    dut.input_vector_12.value = test_vector[12]
    dut.input_vector_13.value = test_vector[13]
    dut.input_vector_14.value = test_vector[14]
    dut.input_vector_15.value = test_vector[15]

def get_diff_vector(dut):
    """Get diff vector output"""
    return [
        dut.diff_vector_0.value.signed_integer,
        dut.diff_vector_1.value.signed_integer,
        dut.diff_vector_2.value.signed_integer,
        dut.diff_vector_3.value.signed_integer,
        dut.diff_vector_4.value.signed_integer,
        dut.diff_vector_5.value.signed_integer,
        dut.diff_vector_6.value.signed_integer,
        dut.diff_vector_7.value.signed_integer,
        dut.diff_vector_8.value.signed_integer,
        dut.diff_vector_9.value.signed_integer,
        dut.diff_vector_10.value.signed_integer,
        dut.diff_vector_11.value.signed_integer,
        dut.diff_vector_12.value.signed_integer,
        dut.diff_vector_13.value.signed_integer,
        dut.diff_vector_14.value.signed_integer,
        dut.diff_vector_15.value.signed_integer
    ]

@cocotb.test()
async def test_simple_case(dut):
    """Test simple case: all-ones vector"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test case: all-ones vector (1.0 in Q5.10 = 0x0400 = 1024)
    test_vector = [0x0400] * 16  # 16 elements of 1.0
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Simple Case: All 1.0 ===")
    print(f"Input vector: {[hex(x) for x in test_vector]}")
    print(f"Expected mean: {expected_mean} (0x{expected_mean:04X}) = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} (0x{expected_var:04X}) = {from_q5_10(expected_var):.4f}")
    
    # Input data
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for pipeline output (9 clock cycles)
    for cycle in range(9):
        await RisingEdge(dut.clk)
        print(f"Cycle {cycle}: valid_out = {dut.valid_out.value}")
    
    # Check output
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} (0x{actual_mean&0xFFFF:04X}) = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} (0x{actual_var&0xFFFF:04X}) = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # Allow some error (due to fixed-point calculation)
    mean_error = signed_diff(actual_mean, expected_mean)
    var_error = abs(actual_var - expected_var)
    
    print(f"Mean error: {mean_error}")
    print(f"Variance error: {var_error}")
    
    assert mean_error <= 2, f"Mean error too large: {mean_error}"
    assert var_error <= 10, f"Variance error too large: {var_error}"
    
    # Check diff vector (should all be 0, since all elements equal mean)
    print("Difference vector check:")
    actual_diff_vector = get_diff_vector(dut)
    for i in range(16):
        actual_diff = actual_diff_vector[i]
        expected_diff_val = expected_diff[i]
        diff_error = abs(actual_diff - expected_diff_val)
        print(f"  Diff[{i}]: expected {expected_diff_val}, actual {actual_diff}, error {diff_error}")
        assert diff_error <= 2, f"Diff vector error too large at index {i}: {diff_error}"
    
    print("✓ Simple case test passed!\n")

@cocotb.test()
async def test_zero_vector(dut):
    """Test zero vector"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test case: all-zero vector
    test_vector = [0x0000] * 16
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Zero Vector ===")
    print(f"Expected mean: {expected_mean} = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} = {from_q5_10(expected_var):.4f}")
    
    # Input data
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for pipeline output
    await ClockCycles(dut.clk, 9)
    
    # Check output
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # Mean should be 0
    assert abs(actual_mean) <= 1, f"Mean should be ~0, got {actual_mean}"
    # Variance should be epsilon (1 in Q5.10)
    assert actual_var == 1, f"Variance should be epsilon (1), got {actual_var}"
    
    print("✓ Zero vector test passed!\n")

@cocotb.test()
async def test_random_vector(dut):
    """Test random vector"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Generate random test vector (Q5.10 format, range -4.0 to 4.0)
    test_vector = []
    for i in range(16):
        val = random.uniform(-4.0, 4.0)
        test_vector.append(to_q5_10(val))
    
    expected_mean, expected_var, expected_diff = reference_layernorm_preprocess(test_vector)
    
    print("=== Test Random Vector ===")
    print("Random test vector:")
    for i, val in enumerate(test_vector):
        print(f"  [{i}] = 0x{val:04X} ({from_q5_10(val):.4f})")
    
    print(f"Expected mean: {expected_mean} (0x{expected_mean:04X}) = {from_q5_10(expected_mean):.4f}")
    print(f"Expected variance: {expected_var} (0x{expected_var:04X}) = {from_q5_10(expected_var):.4f}")
    
    # Input data
    dut.valid_in.value = 1
    set_input_vector(dut, test_vector)
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for pipeline output
    await ClockCycles(dut.clk, 10)
    
    # Check output
    assert dut.valid_out.value == 1, "Valid output should be high"
    
    actual_mean = dut.mean_out.value.signed_integer
    actual_var = dut.variance_out.value.signed_integer
    
    print(f"Actual mean: {actual_mean} (0x{actual_mean&0xFFFF:04X}) = {from_q5_10(actual_mean&0xFFFF):.4f}")
    print(f"Actual variance: {actual_var} (0x{actual_var&0xFFFF:04X}) = {from_q5_10(actual_var&0xFFFF):.4f}")
    
    # Allow larger error, since random data may have larger rounding error
    mean_error = signed_diff(actual_mean, expected_mean)
    var_error = abs(actual_var - expected_var)
    
    print(f"Mean error: {mean_error}")
    print(f"Variance error: {var_error}")
    
    assert mean_error <= 10, f"Mean error too large: {mean_error}"
    assert var_error <= 50, f"Variance error too large: {var_error}"
    
    print("✓ Random vector test passed!\n")

@cocotb.test()
async def test_pipeline_throughput(dut):
    """Test pipeline throughput: continuous input data"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Prepare 3 sets of test data (Q5.10 format)
    test_cases = [
        [0x0400] * 16,  # all 1.0 (1024 in decimal)
        [0x0200] * 16,  # all 0.5 (512 in decimal)
        [0x0800] * 16,  # all 2.0 (2048 in decimal)
    ]
    
    expected_results = []
    for test_case in test_cases:
        expected_results.append(reference_layernorm_preprocess(test_case))
    
    print("=== Test Pipeline Throughput ===")
    for i, test_case in enumerate(test_cases):
        print(f"Test case {i}: {[from_q5_10(x) for x in test_case[:4]]}... (all same)")
    
    # Continuously input 3 sets of data
    for cycle, test_vector in enumerate(test_cases):
        dut.valid_in.value = 1
        set_input_vector(dut, test_vector)
        await RisingEdge(dut.clk)
        print(f"Input cycle {cycle}: data sent")
    
    dut.valid_in.value = 0
    
    # Wait and check output
    output_count = 0
    for cycle in range(16):  # wait long enough
        await RisingEdge(dut.clk)
        
        if dut.valid_out.value == 1:
            print(f"Output cycle {cycle}: valid output received")
            
            if output_count < len(expected_results):
                expected_mean, expected_var, expected_diff = expected_results[output_count]
                actual_mean = dut.mean_out.value.signed_integer
                actual_var = dut.variance_out.value.signed_integer
                
                print(f"  Result {output_count}:")
                print(f"    Expected mean={expected_mean} ({from_q5_10(expected_mean):.3f})")
                print(f"    Actual mean={actual_mean} ({from_q5_10(actual_mean&0xFFFF):.3f})")
                print(f"    Expected var={expected_var} ({from_q5_10(expected_var):.3f})")
                print(f"    Actual var={actual_var} ({from_q5_10(actual_var&0xFFFF):.3f})")
                
                # Basic check
                mean_error = abs(actual_mean - expected_mean)
                var_error = abs(actual_var - expected_var)
                assert mean_error <= 10, f"Pipeline test {output_count}: mean error {mean_error}"
                assert var_error <= 50, f"Pipeline test {output_count}: var error {var_error}"
                
                output_count += 1
    
    assert output_count == 3, f"Expected 3 outputs, got {output_count}"
    print("✓ Pipeline throughput test passed!")

# Run all tests
if __name__ == "__main__":
    import os
    # Set simulator (default: icarus verilog)
    os.environ["SIM"] = "icarus"
    os.environ["TOPLEVEL"] = "layernorm_preprocess"
    os.environ["TOPLEVEL_LANG"] = "verilog"
    os.environ["VERILOG_SOURCES"] = "layernorm_preprocess.v"
    
    # Run tests
    import pytest
    pytest.main([__file__])