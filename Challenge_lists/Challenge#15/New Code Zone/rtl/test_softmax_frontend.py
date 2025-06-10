import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_true_pipeline_basic(dut):
    """Test basic true pipeline functionality"""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    
    # Initialize input vector
    for i in range(16):
        dut.input_vector[i].value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Release reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("=== True Pipeline Basic Test ===")
    
    # Test 1: Single vector through pipeline
    print("\n--- Test 1: Single Vector ---")
    
    # Set input vector (all zeros -> should give exp(0) = 1.0 = 0x0400)
    for i in range(16):
        dut.input_vector[i].value = 0x0000
    
    # Send valid signal for 1 cycle
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Monitor pipeline - should take 6 cycles to get output
    for cycle in range(10):
        valid_out = int(dut.valid_out.value)
        print(f"Cycle {cycle + 1}: valid_out = {valid_out}")
        
        if valid_out == 1:
            print(f"✅ Output received at cycle {cycle + 1}")
            
            # Check results
            try:
                exp_sum_str = str(dut.exp_sum.value)
                if 'x' in exp_sum_str:
                    clean_bits = exp_sum_str.replace('x', '0')[-20:]
                    exp_sum = int(clean_bits, 2)
                else:
                    exp_sum = int(dut.exp_sum.value)
                    
                print(f"exp_sum = 0x{exp_sum:05X} ({exp_sum})")
                
                # Check a few exp_values
                for i in [0, 7, 15]:
                    exp_val = int(dut.exp_values[i].value)
                    print(f"exp_values[{i}] = 0x{exp_val:04X}")
                    
            except ValueError as e:
                print(f"Error reading values: {e}")
            
            break
            
        await RisingEdge(dut.clk)
    
    print("Single vector test completed!")

@cocotb.test()
async def test_true_pipeline_streaming(dut):
    """Test continuous streaming through true pipeline"""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== True Pipeline Streaming Test ===")
    
    # Define test vectors with identifiable patterns
    test_vectors = [
        # Vector 1: All zeros
        ("Vec1_Zeros", [0x0000] * 16),
        
        # Vector 2: All ones
        ("Vec2_Ones", [0x0400] * 16),
        
        # Vector 3: First element different
        ("Vec3_First", [0x0800] + [0x0000] * 15),
        
        # Vector 4: Last element different  
        ("Vec4_Last", [0x0000] * 15 + [0x0800]),
        
        # Vector 5: All different value
        ("Vec5_Half", [0x0200] * 16),
    ]
    
    print(f"Streaming {len(test_vectors)} vectors continuously...")
    
    # Stream vectors continuously (every cycle)
    for vec_idx, (name, test_vector) in enumerate(test_vectors):
        print(f"\nCycle {vec_idx + 1}: Sending {name}")
        
        # Load input vector
        for i in range(16):
            dut.input_vector[i].value = test_vector[i]
        
        # Assert valid_in
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    # Stop sending after all vectors
    dut.valid_in.value = 0
    
    # Now collect outputs
    print(f"\n--- Collecting Pipeline Outputs ---")
    outputs = []
    
    for cycle in range(15):  # Wait up to 15 cycles for all outputs
        valid_out = int(dut.valid_out.value)
        
        if valid_out == 1:
            output_num = len(outputs) + 1
            print(f"\n=== Output {output_num} (Cycle {cycle + len(test_vectors) + 1}) ===")
            
            try:
                # Extract exp_sum
                exp_sum_str = str(dut.exp_sum.value)
                if 'x' in exp_sum_str:
                    clean_bits = exp_sum_str.replace('x', '0')[-20:]
                    exp_sum = int(clean_bits, 2)
                else:
                    exp_sum = int(dut.exp_sum.value)
                
                # Extract some exp_values
                exp_vals = []
                for i in range(16):
                    exp_vals.append(int(dut.exp_values[i].value))
                
                outputs.append({
                    'cycle': cycle + len(test_vectors) + 1,
                    'exp_sum': exp_sum,
                    'exp_values': exp_vals
                })
                
                print(f"exp_sum = 0x{exp_sum:05X}")
                print(f"exp_values sample: [0x{exp_vals[0]:04X}, 0x{exp_vals[1]:04X}, ..., 0x{exp_vals[15]:04X}]")
                
            except Exception as e:
                print(f"Error reading output {output_num}: {e}")
        
        await RisingEdge(dut.clk)
        
        # Stop if we got all expected outputs
        if len(outputs) >= len(test_vectors):
            break
    
    # Analysis
    print(f"\n=== Pipeline Analysis ===")
    print(f"Input vectors sent: {len(test_vectors)}")
    print(f"Output vectors received: {len(outputs)}")
    
    if len(outputs) >= len(test_vectors):
        print("✅ All vectors processed successfully!")
        
        # Calculate latency and throughput
        first_output_cycle = outputs[0]['cycle']
        latency = first_output_cycle - 1  # First input was at cycle 1
        print(f"Pipeline latency: {latency} cycles")
        
        if len(outputs) > 1:
            last_output_cycle = outputs[-1]['cycle']
            span = last_output_cycle - first_output_cycle + 1
            throughput = len(outputs) / span
            print(f"Throughput: {throughput:.2f} vectors/cycle")
            
            # Check if outputs come every cycle (true pipeline behavior)
            consecutive = True
            for i in range(1, len(outputs)):
                if outputs[i]['cycle'] - outputs[i-1]['cycle'] != 1:
                    consecutive = False
                    break
            
            if consecutive:
                print("✅ Outputs come every cycle - true pipeline confirmed!")
            else:
                print("⚠️ Outputs not consecutive - check pipeline")
                
    else:
        print(f"❌ Only received {len(outputs)} outputs, expected {len(test_vectors)}")
    
    # Detailed results
    print(f"\n=== Detailed Results ===")
    for i, output in enumerate(outputs):
        print(f"Output {i+1}: Cycle {output['cycle']}, Sum=0x{output['exp_sum']:05X}")

@cocotb.test()
async def test_pipeline_backpressure(dut):
    """Test pipeline with gaps in input"""
    
    # Start clock  
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("\n=== Pipeline Backpressure Test ===")
    
    # Send vector 1
    for i in range(16):
        dut.input_vector[i].value = 0x0000
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait 2 cycles (gap)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Send vector 2
    for i in range(16):
        dut.input_vector[i].value = 0x0400
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Monitor outputs
    outputs = []
    for cycle in range(15):
        if int(dut.valid_out.value) == 1:
            outputs.append(cycle + 4)  # Cycle relative to first input
            print(f"Output at cycle {cycle + 4}")
        await RisingEdge(dut.clk)
    
    print(f"Outputs received at cycles: {outputs}")
    if len(outputs) == 2:
        gap = outputs[1] - outputs[0]
        print(f"Output gap: {gap} cycles (should be 3 due to 2-cycle input gap + 1 natural)")
        if gap == 3:
            print("✅ Pipeline handles input gaps correctly!")
        else:
            print("⚠️ Unexpected output gap")
    
    print("Backpressure test completed!")

# Makefile for new testbench
makefile_content = '''
# Cocotb Makefile for true pipeline softmax test

SIM ?= icarus  
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += softmax_frontend.v

TOPLEVEL = softmax_frontend
MODULE = test_softmax_true_pipeline

include $(shell cocotb-config --makefiles)/Makefile.sim
'''