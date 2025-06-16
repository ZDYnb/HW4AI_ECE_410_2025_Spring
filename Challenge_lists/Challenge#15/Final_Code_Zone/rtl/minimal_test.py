import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

@cocotb.test()
async def test_debug_calculation(dut):
    """Detailed debug calculation process"""
    
    print("=== Detailed Calculation Debug Test ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Use simpler values for debugging
    exp_sum = 0x1000      # 4096 decimal
    exp_value = 0x0100    # 256 decimal
    
    print(f"Test input:")
    print(f"  exp_sum = 0x{exp_sum:08X} ({exp_sum} decimal)")
    print(f"  exp_value = 0x{exp_value:04X} ({exp_value} decimal)")
    
    # Manually calculate expected result
    numerator = exp_value * 1024  # 256 * 1024 = 262144
    expected_result = numerator // exp_sum  # 262144 / 4096 = 64
    print(f"  numerator = {exp_value} * 1024 = {numerator}")
    print(f"  expected = {numerator} / {exp_sum} = {expected_result} = 0x{expected_result:04X}")
    
    # Set input
    dut.exp_sum_in.value = exp_sum
    for i in range(16):
        dut.exp_values_in[i].value = exp_value
    
    # Send valid signal
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for output and observe each stage
    print(f"\nPipeline trace:")
    for cycle in range(6):
        await RisingEdge(dut.clk)
        
        # Read pipeline status
        try:
            valid_out = int(dut.valid_out.value)
            softmax_0 = int(dut.softmax_out[0].value)
            
            print(f"  Cycle {cycle+1}: valid_out={valid_out}, softmax[0]=0x{softmax_0:04X}")
            
            if valid_out == 1:
                print(f"\n✅ Output received!")
                print(f"  Actual result: 0x{softmax_0:04X} ({softmax_0} decimal)")
                print(f"  Expected result: 0x{expected_result:04X} ({expected_result} decimal)")
                
                if softmax_0 == expected_result:
                    print(f"  🎉 Calculation correct!")
                elif softmax_0 == 0xFFFF:
                    print(f"  ❌ Result saturated to max value - possible overflow")
                else:
                    error_pct = abs(softmax_0 - expected_result) / expected_result * 100
                    print(f"  ⚠️ Result has error: {error_pct:.1f}%")
                
                # Check other elements
                other_values = []
                for i in range(1, 4):  # Check first few
                    other_values.append(int(dut.softmax_out[i].value))
                
                if all(val == softmax_0 for val in other_values):
                    print(f"  ✅ All elements consistent: {[hex(v) for v in other_values[:3]]}")
                else:
                    print(f"  ⚠️ Elements inconsistent: {[hex(v) for v in other_values[:3]]}")
                
                break
        except Exception as e:
            print(f"  Cycle {cycle+1}: Read failed - {e}")
    
    print(f"\nCalculation debug complete!")

@cocotb.test()
async def test_various_inputs(dut):
    """Test various input combinations"""
    
    print(f"\n=== Multiple Input Test ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    test_cases = [
        (0x0400, 0x0040, "Small values"),      # sum=1024, val=64
        (0x1000, 0x0100, "Medium values"),     # sum=4096, val=256  
        (0x4000, 0x0400, "Large values"),      # sum=16384, val=1024
        (0x0040, 0x0004, "Very small values"), # sum=64, val=4
    ]
    
    for exp_sum, exp_val, desc in test_cases:
        print(f"\n--- Test: {desc} ---")
        print(f"exp_sum=0x{exp_sum:04X}, exp_val=0x{exp_val:04X}")
        
        # Reset
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)
        
        # Set input
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = exp_val
        
        # Calculate expected
        numerator = exp_val * 1024
        if exp_sum > 0:
            expected = numerator // exp_sum
        else:
            expected = 0
        
        print(f"Expected result: 0x{expected:04X}")
        
        # Send input
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # Wait for output
        for cycle in range(5):
            await RisingEdge(dut.clk)
            if int(dut.valid_out.value) == 1:
                actual = int(dut.softmax_out[0].value)
                print(f"Actual result: 0x{actual:04X}")
                
                if actual == expected:
                    print(f"✅ Correct")
                else:
                    print(f"❌ Incorrect (expected 0x{expected:04X})")
                break
        else:
            print(f"❌ No output")
    
    print(f"\nMultiple input test complete!")

# Update Makefile, enable debug
makefile_with_debug = '''
SIM = icarus
TOPLEVEL_LANG = verilog  
VERILOG_SOURCES = softmax_backend.v
TOPLEVEL = softmax_backend
MODULE = debug_calculation_test
EXTRA_ARGS += +define+DEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
'''

print("Debug test created!")
print("This test will:")
print("1. Use simple values for detailed calculation debugging")
print("2. Show the status of each pipeline stage") 
print("3. Test multiple input combinations")
print("4. Enable DEBUG_SOFTMAX to show calculation process")
print("")
print("Replace your softmax_backend.v with the fixed version, then run the test!")