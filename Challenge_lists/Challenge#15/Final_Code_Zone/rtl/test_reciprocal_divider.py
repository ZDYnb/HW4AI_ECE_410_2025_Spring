import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_reciprocal_basic(dut):
    """Basic functionality test"""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.exp_sum_in.value = 0
    
    # Initialize exp_values_in
    for i in range(16):
        dut.exp_values_in[i].value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("=== Reciprocal Divider Basic Test ===")
    
    # Test cases - simulate typical softmax outputs
    test_cases = [
        ("16 exp(0)", 0x4000, [0x0400] * 16),      # 16*1024 = 16384
        ("8 exp(1)", 0x5798, [0x0ADF] * 8 + [0x0400] * 8),  # approx 22424
        ("Large value test", 0x8000, [0x0800] * 16),         # 32768  
        ("Small value test", 0x2000, [0x0200] * 16),         # 8192
    ]
    
    for test_name, exp_sum, exp_values in test_cases:
        print(f"\n--- Test: {test_name} ---")
        
        # Set inputs
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = exp_values[i]
        
        # Send valid signal
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        print(f"Input: exp_sum=0x{exp_sum:04X} ({exp_sum})")
        print(f"Expected reciprocal: approx 0x{int(65536/exp_sum*1024):04X}")
        
        # Wait for pipeline output (17 cycles)
        for cycle in range(20):
            await RisingEdge(dut.clk)
            
            if int(dut.valid_out.value) == 1:
                reciprocal = int(dut.reciprocal_out.value)
                print(f"✅ Cycle {cycle+1}: Output reciprocal=0x{reciprocal:04X} ({reciprocal})")
                
                # Verify exp_values are correctly passed through
                print("exp_values pass-through check:")
                for i in [0, 7, 15]:  # Check a few positions
                    expected = exp_values[i]
                    actual = int(dut.exp_values_out[i].value)
                    status = "✅" if actual == expected else "❌"
                    print(f"  {status} exp_values[{i}]: expected=0x{expected:04X}, actual=0x{actual:04X}")
                
                # Calculate accuracy
                expected_reciprocal = int(65536 * 1024 / exp_sum)  # Theoretical value
                error = abs(reciprocal - expected_reciprocal) / expected_reciprocal * 100
                print(f"Accuracy: error {error:.2f}%")
                break
        else:
            print("❌ Timeout: no output received")
        
        # Wait a few cycles before next test
        for _ in range(3):
            await RisingEdge(dut.clk)

@cocotb.test()
async def test_reciprocal_pipeline(dut):
    """Pipeline continuous test"""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== Reciprocal Pipeline Streaming Test ===")
    
    # Send multiple values continuously
    test_inputs = [
        ("Input1", 0x4000, [0x0400] * 16),
        ("Input2", 0x6000, [0x0600] * 16), 
        ("Input3", 0x8000, [0x0800] * 16),
        ("Input4", 0x3000, [0x0300] * 16),
        ("Input5", 0x5000, [0x0500] * 16),
    ]
    
    print(f"Sending {len(test_inputs)} inputs continuously...")
    
    # Send inputs continuously (one per cycle)
    for i, (name, exp_sum, exp_values) in enumerate(test_inputs):
        print(f"Cycle {i+1}: Sending {name}, exp_sum=0x{exp_sum:04X}")
        
        dut.exp_sum_in.value = exp_sum
        for j in range(16):
            dut.exp_values_in[j].value = exp_values[j]
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    # Stop sending
    dut.valid_in.value = 0
    
    # Collect outputs
    print(f"\n--- Collecting pipeline outputs ---")
    outputs = []
    
    for cycle in range(25):  # Wait for all outputs
        await RisingEdge(dut.clk)
        
        if int(dut.valid_out.value) == 1:
            output_num = len(outputs) + 1
            reciprocal = int(dut.reciprocal_out.value)
            outputs.append((cycle + len(test_inputs) + 1, reciprocal))
            
            print(f"Output {output_num} (cycle {cycle + len(test_inputs) + 1}): reciprocal=0x{reciprocal:04X}")
        
        # Stop if all expected outputs are received
        if len(outputs) >= len(test_inputs):
            break
    
    # Analyze pipeline performance
    print(f"\n=== Pipeline analysis ===")
    print(f"Inputs sent: {len(test_inputs)}")
    print(f"Outputs received: {len(outputs)}")
    
    if len(outputs) >= len(test_inputs):
        print("✅ All inputs produced outputs!")
        
        # Calculate latency and throughput
        first_output_cycle = outputs[0][0]
        latency = first_output_cycle - 1  # First input at cycle 1
        print(f"Pipeline latency: {latency} cycles")
        
        if len(outputs) > 1:
            # Check output intervals
            intervals = []
            for i in range(1, len(outputs)):
                interval = outputs[i][0] - outputs[i-1][0]
                intervals.append(interval)
            
            avg_interval = sum(intervals) / len(intervals)
            print(f"Average output interval: {avg_interval:.1f} cycles")
            
            if all(interval == 1 for interval in intervals):
                print("✅ One result per cycle - true pipeline confirmed!")
            else:
                print("⚠️ Output interval is not 1 cycle")
                print(f"Output intervals: {intervals}")
    else:
        print(f"❌ Only received {len(outputs)} outputs, expected {len(test_inputs)}")
    
    print("Pipeline test complete!")

@cocotb.test() 
async def test_reciprocal_accuracy(dut):
    """Accuracy test"""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== Reciprocal Accuracy Test ===")
    
    # Accuracy test cases
    accuracy_tests = [
        0x1000,  # 4096
        0x2000,  # 8192  
        0x4000,  # 16384
        0x6000,  # 24576
        0x8000,  # 32768
        0xA000,  # 40960
        0xC000,  # 49152
    ]
    
    print("Testing calculation accuracy for different values:")
    
    for exp_sum in accuracy_tests:
        # Set input
        dut.exp_sum_in.value = exp_sum
        for i in range(16):
            dut.exp_values_in[i].value = 0x0400
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # Wait for output
        for cycle in range(20):
            await RisingEdge(dut.clk)
            if int(dut.valid_out.value) == 1:
                reciprocal = int(dut.reciprocal_out.value)
                
                # Calculate theoretical value (1/exp_sum in Q5.10)
                theoretical = int(1024 * 1024 / exp_sum)  # Q5.10 format
                error = abs(reciprocal - theoretical) / theoretical * 100 if theoretical > 0 else 0
                
                print(f"exp_sum=0x{exp_sum:04X}: output=0x{reciprocal:04X}, theoretical=0x{theoretical:04X}, error={error:.2f}%")
                break
        
        # Small delay
        await RisingEdge(dut.clk)
    
    print("Accuracy test complete!")

# Makefile content
makefile_content = '''
# Cocotb Makefile for reciprocal divider test

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += reciprocal_divider.v

TOPLEVEL = reciprocal_divider  
MODULE = test_reciprocal_divider

include $(shell cocotb-config --makefiles)/Makefile.sim
'''