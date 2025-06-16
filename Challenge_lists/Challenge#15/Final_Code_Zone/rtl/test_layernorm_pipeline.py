import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.binary import BinaryValue
import random

# Q5.10 format helper functions
def float_to_q5_10(val):
    """Convert float to Q5.10 format (16-bit)"""
    # Clamp to valid range for Q5.10: -32.0 to +31.999
    val = max(-32.0, min(31.999, val))
    return int(val * 1024) & 0xFFFF

def q5_10_to_float(val):
    """Convert Q5.10 format to float"""
    # Handle 16-bit signed value
    if val >= 32768:  # If MSB is set (negative)
        val = val - 65536
    return val / 1024.0

def print_vector_q5_10(name, vector, length=16):
    """Print a vector in both hex and float format"""
    print(f"{name}:")
    hex_str = " ".join([f"{vector[i]:04x}" for i in range(length)])
    float_str = " ".join([f"{q5_10_to_float(vector[i]):6.3f}" for i in range(length)])
    print(f"  Hex:   {hex_str}")
    print(f"  Float: {float_str}")

@cocotb.test()
async def test_layernorm_pipeline_basic(dut):
    """Basic functionality test for LayerNorm pipeline"""
    
    print("="*80)
    print("LayerNorm Pipeline Basic Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz clock
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    
    # Initialize all input vectors to 0
    for i in range(16):
        getattr(dut, f"input_vector_{i}").value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("Reset complete, starting test...")
    
    # Test Case 1: Simple test vector with known pattern
    print("\n" + "="*50)
    print("TEST CASE 1: Simple pattern [1.0, 2.0, 3.0, ...]")
    print("="*50)
    
    # Create input vector: [1.0, 2.0, 3.0, ..., 16.0]
    input_vector = []
    for i in range(16):
        val = float(i + 1)  # 1.0 to 16.0
        q5_10_val = float_to_q5_10(val)
        input_vector.append(q5_10_val)
        getattr(dut, f"input_vector_{i}").value = q5_10_val
    
    print_vector_q5_10("Input Vector", input_vector)
    
    # Calculate expected mean and variance for verification
    float_inputs = [q5_10_to_float(x) for x in input_vector]
    expected_mean = sum(float_inputs) / len(float_inputs)
    expected_variance = sum((x - expected_mean)**2 for x in float_inputs) / len(float_inputs)
    print(f"Expected mean: {expected_mean:.6f}")
    print(f"Expected variance: {expected_variance:.6f}")
    
    # Apply input
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for pipeline to complete (20 stages + some margin)
    print("Waiting for pipeline to complete (20+ cycles)...")
    for cycle in range(25):
        await RisingEdge(dut.clk)
        if cycle >= 19:  # Check for valid output after expected delay
            if dut.valid_out.value == 1:
                print(f"Output valid at cycle {cycle + 1}")
                break
    
    # Check if we got valid output
    if dut.valid_out.value != 1:
        print("ERROR: No valid output after 25 cycles!")
        return
    
    # Read output vector
    output_vector = []
    for i in range(16):
        val = int(getattr(dut, f"output_vector_{i}").value)
        output_vector.append(val)
    
    print_vector_q5_10("Output Vector", output_vector)
    
    # Basic sanity checks
    output_floats = [q5_10_to_float(x) for x in output_vector]
    output_mean = sum(output_floats) / len(output_floats)
    output_variance = sum(x**2 for x in output_floats) / len(output_floats)
    
    print(f"Output mean: {output_mean:.6f} (should be ~0 for standard LayerNorm)")
    print(f"Output variance: {output_variance:.6f} (should be ~1 for standard LayerNorm)")
    
    # Test Case 2: All zeros (edge case)
    print("\n" + "="*50)
    print("TEST CASE 2: All zeros (edge case)")
    print("="*50)
    
    # Set all inputs to 0
    for i in range(16):
        getattr(dut, f"input_vector_{i}").value = 0
    
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for output
    for cycle in range(25):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            print(f"Output valid at cycle {cycle + 1}")
            break
    
    if dut.valid_out.value == 1:
        output_vector = []
        for i in range(16):
            val = int(getattr(dut, f"output_vector_{i}").value)
            output_vector.append(val)
        print_vector_q5_10("Output Vector (all zeros input)", output_vector)
    
    # Test Case 3: Random vector
    print("\n" + "="*50)
    print("TEST CASE 3: Random vector")
    print("="*50)
    
    # Generate random input vector
    random.seed(42)  # For reproducible results
    input_vector = []
    for i in range(16):
        val = random.uniform(-4.0, 4.0)  # Random values in reasonable range
        q5_10_val = float_to_q5_10(val)
        input_vector.append(q5_10_val)
        getattr(dut, f"input_vector_{i}").value = q5_10_val
    
    print_vector_q5_10("Random Input Vector", input_vector)
    
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for output
    for cycle in range(25):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            print(f"Output valid at cycle {cycle + 1}")
            break
    
    if dut.valid_out.value == 1:
        output_vector = []
        for i in range(16):
            val = int(getattr(dut, f"output_vector_{i}").value)
            output_vector.append(val)
        print_vector_q5_10("Random Output Vector", output_vector)
        
        # Sanity check
        output_floats = [q5_10_to_float(x) for x in output_vector]
        output_mean = sum(output_floats) / len(output_floats)
        output_variance = sum(x**2 for x in output_floats) / len(output_floats)
        print(f"Random output mean: {output_mean:.6f}")
        print(f"Random output variance: {output_variance:.6f}")
    
    print("\n" + "="*80)
    print("LayerNorm Pipeline Test Complete!")
    print("="*80)

@cocotb.test()
async def test_layernorm_pipeline_throughput(dut):
    """Test pipeline throughput - multiple inputs back-to-back"""
    
    print("="*80)
    print("LayerNorm Pipeline Throughput Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    for i in range(16):
        getattr(dut, f"input_vector_{i}").value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Send 3 different input vectors back-to-back
    test_vectors = [
        [1.0] * 16,  # All ones
        [i+1 for i in range(16)],  # 1,2,3...16
        [-1.0, 1.0] * 8  # Alternating -1, 1
    ]
    
    print("Sending 3 input vectors back-to-back...")
    
    # Send inputs
    for vec_idx, test_vec in enumerate(test_vectors):
        print(f"Sending vector {vec_idx + 1}: {test_vec[:4]}...")
        
        for i in range(16):
            q5_10_val = float_to_q5_10(test_vec[i])
            getattr(dut, f"input_vector_{i}").value = q5_10_val
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.valid_in.value = 0
        
        # No wait between inputs - test back-to-back capability
    
    # Now wait for all 3 outputs
    output_count = 0
    for cycle in range(30):  # Give enough time for all outputs
        await RisingEdge(dut.clk)
        
        if dut.valid_out.value == 1:
            output_count += 1
            print(f"Got output {output_count} at cycle {cycle + 1}")
            
            # Read and display this output
            output_vector = []
            for i in range(16):
                val = int(getattr(dut, f"output_vector_{i}").value)
                output_vector.append(val)
            
            output_floats = [q5_10_to_float(x) for x in output_vector]
            print(f"  Output {output_count} sample: {output_floats[:4]}")
            
            if output_count >= 3:
                break
    
    if output_count == 3:
        print("SUCCESS: Got all 3 outputs as expected!")
    else:
        print(f"WARNING: Only got {output_count} outputs, expected 3")
    
    print("Throughput test complete!")

def generate_test_vector(vector_type, index=0):
    """Generate different types of test vectors"""
    if vector_type == "linear":
        # Linear progression: [1, 2, 3, ..., 16]
        return [float(i + 1) for i in range(16)]
    
    elif vector_type == "sine":
        # Sine wave pattern
        import math
        return [2.0 * math.sin(2 * math.pi * (i + index) / 16.0) for i in range(16)]
    
    elif vector_type == "random":
        # Random values with fixed seed for reproducibility
        random.seed(42 + index)
        return [random.uniform(-4.0, 4.0) for i in range(16)]
    
    elif vector_type == "alternating":
        # Alternating pattern: [-2, 2, -2, 2, ...]
        return [-2.0 if i % 2 == 0 else 2.0 for i in range(16)]
    
    elif vector_type == "gaussian":
        # Gaussian-like pattern centered at middle
        import math
        center = 7.5
        return [2.0 * math.exp(-((i - center) / 3.0)**2) - 1.0 for i in range(16)]
    
    elif vector_type == "zeros":
        # All zeros (edge case)
        return [0.0] * 16
    
    elif vector_type == "ones":
        # All ones
        return [1.0] * 16
    
    else:  # "ramp"
        # Ramping pattern with index
        return [float(i + index * 0.1) for i in range(16)]

@cocotb.test()
async def test_pipeline_continuous_stream(dut):
    """Test pipeline with continuous input and output streams"""
    
    print("="*100)
    print("LayerNorm Pipeline Continuous Stream Test")
    print("="*100)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz clock
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    for i in range(16):
        getattr(dut, f"input_vector_{i}").value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("Reset complete. Starting continuous stream test...\n")
    
    # Test parameters
    NUM_VECTORS = 10  # Number of input vectors to send
    vector_types = ["linear", "sine", "random", "alternating", "gaussian", "ones", "zeros", "ramp"] * 2
    
    # Storage for tracking inputs and outputs
    input_vectors = []
    output_vectors = []
    
    # Phase 1: Send continuous input stream
    print("PHASE 1: Sending continuous input stream")
    print("-" * 50)
    
    for vec_idx in range(NUM_VECTORS):
        # Generate test vector
        vector_type = vector_types[vec_idx % len(vector_types)]
        test_vector = generate_test_vector(vector_type, vec_idx)
        
        # Convert to Q5.10 and apply to DUT
        q5_10_vector = [float_to_q5_10(val) for val in test_vector]
        input_vectors.append((vec_idx, vector_type, q5_10_vector, test_vector))
        
        for i in range(16):
            getattr(dut, f"input_vector_{i}").value = q5_10_vector[i]
        
        dut.valid_in.value = 1
        
        print(f"Cycle {vec_idx:2d}: Sending {vector_type:12s} vector")
        if vec_idx < 3:  # Print details for first few
            print_vector_q5_10(f"  Input {vec_idx}", q5_10_vector)
        
        await RisingEdge(dut.clk)
    
    # Stop sending inputs
    dut.valid_in.value = 0
    print(f"\nSent {NUM_VECTORS} input vectors continuously (no gaps)")
    
    # Phase 2: Collect continuous output stream
    print("\nPHASE 2: Collecting output stream")
    print("-" * 50)
    
    outputs_collected = 0
    cycle_count = 0
    first_output_cycle = None
    output_cycles = []
    
    # Wait for and collect all outputs
    while outputs_collected < NUM_VECTORS and cycle_count < 100:  # Safety timeout
        await RisingEdge(dut.clk)
        cycle_count += 1
        
        if dut.valid_out.value == 1:
            if first_output_cycle is None:
                first_output_cycle = cycle_count
                print(f"First output appeared at cycle {cycle_count}")
            
            output_cycles.append(cycle_count)
            
            # Read output vector
            output_vector = []
            for i in range(16):
                val = int(getattr(dut, f"output_vector_{i}").value)
                output_vector.append(val)
            
            output_float_vector = [q5_10_to_float(x) for x in output_vector]
            output_vectors.append((outputs_collected, output_vector, output_float_vector))
            
            print(f"Cycle {cycle_count:2d}: Got output {outputs_collected + 1}")
            if outputs_collected < 3:  # Print details for first few
                print_vector_q5_10(f"  Output {outputs_collected}", output_vector)
                
                # Quick sanity check
                mean = sum(output_float_vector) / len(output_float_vector)
                variance = sum(x**2 for x in output_float_vector) / len(output_float_vector)
                print(f"    Mean: {mean:8.6f}, Variance: {variance:8.6f}")
            
            outputs_collected += 1
    
    # Phase 3: Analysis
    print("\n" + "="*100)
    print("PIPELINE PERFORMANCE ANALYSIS")
    print("="*100)
    
    if outputs_collected == NUM_VECTORS:
        print(f"✅ SUCCESS: Collected all {NUM_VECTORS} outputs")
        
        # Calculate pipeline metrics
        pipeline_latency = first_output_cycle
        print(f"✅ Pipeline latency: {pipeline_latency} cycles")
        
        # Check if outputs are consecutive (perfect throughput)
        consecutive = all(output_cycles[i+1] - output_cycles[i] == 1 for i in range(len(output_cycles)-1))
        
        if consecutive:
            print(f"✅ PERFECT THROUGHPUT: All outputs consecutive (1 per cycle)")
        else:
            gaps = [output_cycles[i+1] - output_cycles[i] for i in range(len(output_cycles)-1)]
            print(f"❌ Throughput issues: Gaps between outputs: {gaps}")
        
        efficiency = NUM_VECTORS / (output_cycles[-1] - output_cycles[0] + 1) * 100
        print(f"✅ Pipeline efficiency: {efficiency:.1f}%")
        
    else:
        print(f"❌ FAILURE: Only collected {outputs_collected}/{NUM_VECTORS} outputs")
    
    # Phase 4: Functional correctness check
    print("\n" + "="*50)
    print("FUNCTIONAL CORRECTNESS CHECK")
    print("-" * 50)
    
    if len(output_vectors) >= 3:
        print("Checking LayerNorm properties for first 3 outputs:")
        
        for i in range(min(3, len(output_vectors))):
            _, output_q5_10, output_float = output_vectors[i]
            
            mean = sum(output_float) / len(output_float)
            variance = sum(x**2 for x in output_float) / len(output_float)
            
            mean_ok = abs(mean) < 0.01  # Mean should be very close to 0
            var_ok = 0.8 < variance < 1.2  # Variance should be close to 1
            
            status_mean = "✅" if mean_ok else "❌"
            status_var = "✅" if var_ok else "❌"
            
            print(f"  Output {i}: {status_mean} Mean={mean:8.6f}, {status_var} Var={variance:8.6f}")
    
    print("\n" + "="*100)
    print("CONTINUOUS STREAM TEST COMPLETE!")
    print("="*100)

@cocotb.test() 
async def test_pipeline_sustained_load(dut):
    """Test pipeline under sustained load - many vectors"""
    
    print("="*100)
    print("LayerNorm Pipeline Sustained Load Test (25 vectors)")
    print("="*100)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    for i in range(16):
        getattr(dut, f"input_vector_{i}").value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk) 
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    NUM_VECTORS = 25
    outputs_collected = 0
    cycle = 0
    
    print(f"Sending {NUM_VECTORS} vectors with continuous monitoring...")
    
    # Send vectors continuously while monitoring outputs
    vector_sent = 0
    
    for test_cycle in range(NUM_VECTORS + 50):  # Extra cycles for pipeline drain
        await RisingEdge(dut.clk)
        cycle += 1
        
        # Send new vector if we have more to send
        if vector_sent < NUM_VECTORS:
            # Generate simple test vector
            test_vector = [float(i + vector_sent * 0.1) for i in range(16)]
            q5_10_vector = [float_to_q5_10(val) for val in test_vector]
            
            for i in range(16):
                getattr(dut, f"input_vector_{i}").value = q5_10_vector[i]
            
            dut.valid_in.value = 1
            vector_sent += 1
            
            if vector_sent % 5 == 0:
                print(f"  Sent {vector_sent} vectors...")
        else:
            dut.valid_in.value = 0
        
        # Check for output
        if dut.valid_out.value == 1:
            outputs_collected += 1
            
            if outputs_collected == 1:
                print(f"  First output at cycle {cycle}")
            elif outputs_collected % 5 == 0:
                print(f"  Collected {outputs_collected} outputs...")
                
            if outputs_collected >= NUM_VECTORS:
                print(f"  All {NUM_VECTORS} outputs collected at cycle {cycle}")
                break
    
    # Final analysis
    success = (outputs_collected == NUM_VECTORS)
    throughput = NUM_VECTORS / cycle if cycle > 0 else 0
    
    print(f"\nSUSTAINED LOAD TEST RESULTS:")
    print(f"  Vectors sent: {vector_sent}")
    print(f"  Outputs collected: {outputs_collected}")
    print(f"  Total cycles: {cycle}")
    print(f"  Throughput: {throughput:.3f} vectors/cycle")
    print(f"  Result: {'✅ SUCCESS' if success else '❌ FAILURE'}")

if __name__ == "__main__":
    # This allows running the test standalone
    import sys
    import os
    # Add any additional setup here if needed
    pass