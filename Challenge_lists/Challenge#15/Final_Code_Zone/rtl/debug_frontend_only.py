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

def safe_hex_convert(signal_value):
    try:
        val = int(signal_value)
        return f"0x{val:04X}"
    except ValueError:
        return f"X({signal_value})"

@cocotb.test()
async def test_frontend_only_debug(dut):
    """Test Frontend module only"""
    
    print("=== Frontend Standalone Debug Test ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    for i in range(16):
        dut.input_vector[i].value = 0
    
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    dut.rst_n.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    
    print("Reset complete")
    
    # Test simple input
    print("\n=== Setting test input ===")
    dut.input_vector[0].value = 0x0400  # 1.0
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000  # 0.0
    
    print("Input: [0x0400, 0x0000, ...]")
    print("Expected: LUT[4] should give some EXP value")
    
    # Send input
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    print("\n=== Frontend pipeline trace ===")
    
    # Monitor for longer - Frontend may need more cycles
    for cycle in range(20):
        await RisingEdge(dut.clk)
        
        print(f"\n--- Cycle {cycle+1} ---")
        
        # Basic signals
        try:
            valid_in = safe_int_convert(dut.valid_in.value)
            valid_out = safe_int_convert(dut.valid_out.value)
            input_0 = safe_hex_convert(dut.input_vector[0].value)
            
            print(f"Basic signals:")
            print(f"  valid_in: {valid_in}")
            print(f"  valid_out: {valid_out}")
            print(f"  input[0]: {input_0}")
        except Exception as e:
            print(f"Error reading basic signals: {e}")
        
        # LUT address and output (if accessible)
        try:
            # Try to read LUT related signals
            if hasattr(dut, 'exp_lut_addr'):
                lut_addr_0 = safe_int_convert(dut.exp_lut_addr[0].value)
                print(f"  LUT address[0]: {lut_addr_0}")
            
            if hasattr(dut, 'exp_lut_out'):
                lut_out_0 = safe_hex_convert(dut.exp_lut_out[0].value)
                print(f"  LUT output[0]: {lut_out_0}")
        except Exception as e:
            print(f"Error reading LUT signals: {e}")
        
        # Pipeline stages
        try:
            if hasattr(dut, 'valid_stage'):
                print(f"Pipeline stages:")
                for stage in range(6):
                    try:
                        stage_valid = safe_int_convert(dut.valid_stage[stage].value)
                        print(f"  valid_stage[{stage}]: {stage_valid}")
                    except:
                        print(f"  valid_stage[{stage}]: Unable to read")
        except Exception as e:
            print(f"Error reading pipeline stages: {e}")
        
        # Stage 0 data
        try:
            if hasattr(dut, 'exp_s0'):
                exp_s0_0 = safe_hex_convert(dut.exp_s0[0].value)
                print(f"  exp_s0[0]: {exp_s0_0}")
        except:
            pass
        
        # Output data
        try:
            if valid_out == 1:
                exp_sum = safe_hex_convert(dut.exp_sum.value)
                exp_val_0 = safe_hex_convert(dut.exp_values[0].value)
                
                print(f"✅ Frontend output:")
                print(f"  exp_sum: {exp_sum}")
                print(f"  exp_values[0]: {exp_val_0}")
                
                # Check all outputs
                print(f"  Full exp_values:")
                for i in range(16):
                    val = safe_hex_convert(dut.exp_values[i].value)
                    print(f"    exp_values[{i:2d}]: {val}")
                
                break
        except Exception as e:
            print(f"Error reading output: {e}")
    
    else:
        print("\n❌ No Frontend output in 20 cycles")
        print("Possible issues:")
        print("1. Frontend pipeline needs more cycles")
        print("2. Frontend logic error")
        print("3. LUT initialization problem")

@cocotb.test()
async def test_frontend_lut_basic(dut):
    """Test basic functionality of Frontend LUT"""
    
    print("\n=== Frontend LUT Basic Test ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Test LUT address 0
    print("Test LUT[0] (input 0x0000):")
    dut.input_vector[0].value = 0x0000
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000
    
    await RisingEdge(dut.clk)
    
    # Test LUT address 1  
    print("Test LUT[1] (input 0x0100):")
    dut.input_vector[0].value = 0x0100
    
    await RisingEdge(dut.clk)
    
    # Test LUT address 4
    print("Test LUT[4] (input 0x0400):")
    dut.input_vector[0].value = 0x0400
    
    await RisingEdge(dut.clk)
    
    print("LUT basic test complete")

# Frontend dedicated Makefile
makefile_frontend = """
SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = softmax_frontend.v
TOPLEVEL = softmax_frontend
MODULE = debug_frontend_only
COMPILE_ARGS += -DDEBUG_SOFTMAX
export COCOTB_RESOLVE_X = ZEROS
include $(shell cocotb-config --makefiles)/Makefile.sim
"""

print("Frontend standalone debug test created!")
print("This will tell us:")
print("1. Whether Frontend can start correctly")
print("2. Whether LUT lookup works")
print("3. How many cycles the pipeline needs")
print("4. Which stage has a problem")
print("")
print("How to run:")
print("1. Save debug_frontend_only.py")
print("2. Create a dedicated Makefile for Frontend:")
print("   TOPLEVEL = softmax_frontend")
print("   MODULE = debug_frontend_only")
print("3. Run: make clean && make")