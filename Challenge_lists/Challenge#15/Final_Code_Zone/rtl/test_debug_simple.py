import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import math

def to_q5_10(value):
    """Convert a float to Q5.10 fixed-point format"""
    value = max(-32.0, min(31.999, value))
    return int(value * 1024) & 0xFFFF

def from_q5_10(value):
    """Convert Q5.10 fixed-point format to float"""
    if value & 0x8000:  # Negative number
        return (value - 65536) / 1024.0
    else:
        return value / 1024.0

@cocotb.test()
async def test_simple_debug(dut):
    """Simple test for debug version"""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    print("=== Debug Test ===")
    
    # Test case: variance = 1.0
    test_variance = to_q5_10(1.0)
    expected_inv_sqrt = to_q5_10(1.0)  # 1/√1 = 1
    
    print(f"Input variance: 0x{test_variance:04X} = {from_q5_10(test_variance):.4f}")
    print(f"Expected 1/√variance: 0x{expected_inv_sqrt:04X} = {from_q5_10(expected_inv_sqrt):.4f}")
    
    # Input data
    dut.valid_in.value = 1
    dut.variance_in.value = test_variance
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for output, observe debug info
    for cycle in range(10):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            actual_inv_sqrt = dut.inv_sigma_out.value.signed_integer
            print(f"Output at cycle {cycle}: 0x{actual_inv_sqrt&0xFFFF:04X} = {from_q5_10(actual_inv_sqrt&0xFFFF):.4f}")
            break
    else:
        print("No valid output received!")
        assert False, "No output received"