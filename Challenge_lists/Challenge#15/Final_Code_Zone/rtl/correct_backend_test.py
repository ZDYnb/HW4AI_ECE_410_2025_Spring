import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

def safe_int_convert(signal_value):
    try:
        return int(signal_value)
    except ValueError:
        return 0

@cocotb.test()
async def test_backend_only_fix(dut):
    """Test only the Backend module (not the full processor)"""
    
    print("=== Testing Backend module division fix ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Use real data found from debugging
    exp_val = 0x0ADF      # 2783 decimal
    exp_sum = 0x000046DF  # 18143 decimal
    
    print(f"Input data:")
    print(f"  exp_values[0] = 0x{exp_val:04X} ({exp_val})")
    print(f"  exp_sum = 0x{exp_sum:08X} ({exp_sum})")
    
    # Manually calculate expected result
    numerator = exp_val * 1024
    expected = numerator // exp_sum
    
    print(f"Manual calculation:")
    print(f"  numerator = {exp_val} * 1024 = {numerator}")
    print(f"  expected = {numerator} / {exp_sum} = {expected} = 0x{expected:04X}")
    
    # Set backend inputs (directly testing backend this time)
    dut.exp_sum_in.value = exp_sum
    dut.exp_values_in[0].value = exp_val
    for i in range(1, 16):
        dut.exp_values_in[i].value = exp_val  # All the same for easy verification
    
    # Send input
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for output
    for cycle in range(5):
        await RisingEdge(dut.clk)
        
        valid_out = safe_int_convert(dut.valid_out.value)
        if valid_out == 1:
            actual = safe_int_convert(dut.softmax_out[0].value)
            
            print(f"\n✅ Backend output (cycle {cycle+1}):")
            print(f"  Actual result: 0x{actual:04X} ({actual})")
            print(f"  Expected result: 0x{expected:04X} ({expected})")
            
            if actual == 0:
                print(f"❌ Still outputting zero! Need to check division logic")
            elif actual == expected:
                print(f"🎉 Division calculation is completely correct!")
            else:
                error_pct = abs(actual - expected) / expected * 100
                if error_pct < 5:
                    print(f"✅ Division basically correct, error {error_pct:.1f}%")
                else:
                    print(f"⚠️ Division error {error_pct:.1f}%")
            
            # Check normalization
            all_outputs = [safe_int_convert(dut.softmax_out[i].value) for i in range(16)]
            total_sum = sum(all_outputs)
            
            print(f"\nNormalization check:")
            print(f"  All 16 outputs are: 0x{actual:04X}")
            print(f"  Total sum: 0x{total_sum:04X} ({total_sum})")
            print(f"  Expected: 0x0400 (1024)")
            
            break
    else:
        print("❌ Did not receive Backend output")

# Backend-specific Makefile
makefile_backend = """
SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = softmax_backend.v
TOPLEVEL = softmax_backend
MODULE = correct_backend_test
EXTRA_ARGS += +define+DEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
"""

print("Correct Backend test created!")
print("Usage:")
print("1. Save correct_backend_test.py")
print("2. Update Makefile to test backend module:")
print("   TOPLEVEL = softmax_backend")
print("   MODULE = correct_backend_test") 
print("3. Run: make")
print("")
print("This will directly test the division calculation of the backend module")