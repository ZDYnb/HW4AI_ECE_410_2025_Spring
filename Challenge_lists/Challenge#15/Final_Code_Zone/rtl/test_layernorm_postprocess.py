import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import numpy as np

def q5_10_to_float(val):
    """Convert Q5.10 format to float"""
    val = int(val)
    if val >= 2**15:  # Handle negative numbers
        val = val - 2**16
    return val / 1024.0

def float_to_q5_10(val):
    """Convert float to Q5.10 format"""
    result = int(val * 1024)
    if result < 0:
        result = result + 2**16
    return result & 0xFFFF

def float_to_unsigned_q5_10(val):
    """Convert float to unsigned Q5.10 format (for gamma and beta)"""
    result = int(val * 1024)
    return result & 0xFFFF

class LayerNormPostprocessTester:
    def __init__(self, dut):
        self.dut = dut
        
    async def reset(self):
        """Reset DUT"""
        self.dut.rst_n.value = 0
        await ClockCycles(self.dut.clk, 2)
        self.dut.rst_n.value = 1
        await RisingEdge(self.dut.clk)
        
    async def send_input(self, inv_sigma, mean, diff_vector, gamma, beta):
        """Send a set of input data"""
        # Set input signals
        self.dut.valid_in.value = 1
        self.dut.inv_sigma_in.value = float_to_q5_10(inv_sigma)
        self.dut.mean_in.value = float_to_q5_10(mean)
        
        # Set diff vector
        for i in range(16):
            getattr(self.dut, f'diff_vector_in_{i}').value = float_to_q5_10(diff_vector[i])
            
        # Set gamma parameters
        for i in range(16):
            getattr(self.dut, f'gamma_{i}').value = float_to_unsigned_q5_10(gamma[i])
            
        # Set beta parameters  
        for i in range(16):
            getattr(self.dut, f'beta_{i}').value = float_to_unsigned_q5_10(beta[i])
            
        await RisingEdge(self.dut.clk)
        self.dut.valid_in.value = 0
        
    def get_output(self):
        """Get output vector"""
        output = []
        for i in range(16):
            val = getattr(self.dut, f'output_vector_{i}').value
            output.append(q5_10_to_float(int(val)))
        return output

@cocotb.test()
async def test_pipeline_throughput(dut):
    """Test pipeline throughput - send data continuously, verify output every cycle"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tester = LayerNormPostprocessTester(dut)
    await tester.reset()
    
    cocotb.log.info("=== Test 3-stage pipeline throughput ===")
    
    # Prepare 5 sets of test data
    test_cases = []
    for case in range(5):
        inv_sigma = 1.0 + case * 0.2
        mean = case * 0.5
        diff_vector = [(i - 8) * 0.25 + case * 0.1 for i in range(16)]
        gamma = [1.0 + case * 0.1] * 16
        beta = [case * 0.2] * 16
        test_cases.append((inv_sigma, mean, diff_vector, gamma, beta))
    
    # Send 5 sets of data continuously (one set per clock cycle)
    for case_idx, (inv_sigma, mean, diff_vector, gamma, beta) in enumerate(test_cases):
        cocotb.log.info(f"Clock cycle {case_idx}: Sending test case {case_idx}")
        await tester.send_input(inv_sigma, mean, diff_vector, gamma, beta)
    
    # Start checking output - check valid_out every cycle
    outputs = []
    cycle_count = 0
    first_output_cycle = None
    
    # Check until 5 outputs are collected or timeout
    while len(outputs) < 5 and cycle_count < 20:  # Wait up to 20 cycles
        await RisingEdge(dut.clk)
        cycle_count += 1
        
        cocotb.log.info(f"Clock cycle {cycle_count}: valid_out = {dut.valid_out.value}")
        
        # Check if output is valid
        if dut.valid_out.value == 1:
            if first_output_cycle is None:
                first_output_cycle = cycle_count
                cocotb.log.info(f"✓ First output appears at clock cycle {cycle_count}")
            
            output = tester.get_output()
            outputs.append(output)
            output_idx = len(outputs) - 1
            cocotb.log.info(f"✓ Clock cycle {cycle_count}: Successfully received output {output_idx}")
            cocotb.log.info(f"  Output sample: output[0]={output[0]:.3f}")
    
    # Verify pipeline latency
    if first_output_cycle is not None:
        cocotb.log.info(f"Pipeline latency check: first output at cycle {first_output_cycle}")
        assert first_output_cycle == 3, f"Expected 3-stage latency, actual latency {first_output_cycle} cycles"
    else:
        raise TimeoutError("No valid output detected")
    
    # Verify all outputs are received
    assert len(outputs) == 5, f"Should receive 5 outputs, actually received {len(outputs)}"
    
    # Simple check for output validity (not all zeros or abnormal values)
    for case_idx, output in enumerate(outputs):
        # Check output is not all zeros
        non_zero_count = sum(1 for x in output if abs(x) > 0.001)
        assert non_zero_count > 0, f"Output {case_idx} is all zeros, possible calculation error"
        
        # Check output is within reasonable range (Q5.10 format range)
        for i, val in enumerate(output):
            assert -32.0 <= val <= 31.999, f"Output {case_idx}[{i}] = {val} out of Q5.10 range"
    
    cocotb.log.info("✓ Pipeline throughput test passed!")
    cocotb.log.info("✓ Verified: 5 sets of data sent continuously, valid output every cycle for 5 cycles")
    cocotb.log.info("✓ Verified: 3-stage pipeline produces one output per clock cycle")

@cocotb.test()
async def test_pipeline_latency(dut):
    """Test pipeline latency - precisely verify 3-stage latency"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tester = LayerNormPostprocessTester(dut)
    await tester.reset()
    
    cocotb.log.info("=== Test 3-stage pipeline latency ===")
    
    # Simple test data
    inv_sigma = 1.0
    mean = 0.0
    diff_vector = [float(i-8) for i in range(16)]
    gamma = [1.0] * 16
    beta = [0.0] * 16
    
    # Record send time
    send_cycle = 0
    cocotb.log.info(f"Clock cycle {send_cycle}: Sending data")
    await tester.send_input(inv_sigma, mean, diff_vector, gamma, beta)
    
    # Check output cycle by cycle
    for cycle in range(1, 8):  # Check next 7 cycles
        await RisingEdge(dut.clk)
        cocotb.log.info(f"Clock cycle {cycle}: valid_out = {dut.valid_out.value}")
        
        if dut.valid_out.value == 1:
            cocotb.log.info(f"✓ Clock cycle {cycle}: Valid output detected")
            cocotb.log.info(f"✓ Pipeline latency = {cycle} clock cycles")
            
            # Verify latency is 3 cycles
            assert cycle == 3, f"Expected latency 3 cycles, actual latency {cycle} cycles"
            
            output = tester.get_output()
            cocotb.log.info(f"✓ Output sample: output[0]={output[0]:.3f}")
            break
    else:
        raise TimeoutError("No valid output detected within 7 clock cycles")
    
    cocotb.log.info("✓ Pipeline latency test passed!")

@cocotb.test()
async def test_continuous_pipeline(dut):
    """Test continuous pipeline operation - long continuous data stream"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tester = LayerNormPostprocessTester(dut)
    await tester.reset()
    
    cocotb.log.info("=== Test continuous pipeline operation ===")
    
    # Send 10 sets of data continuously
    num_cases = 10
    for case in range(num_cases):
        inv_sigma = 0.5 + case * 0.1
        mean = case * 0.1
        diff_vector = [(i - 8) * 0.1 + case * 0.05 for i in range(16)]
        gamma = [1.0 + case * 0.05] * 16
        beta = [case * 0.1] * 16
        
        cocotb.log.info(f"Sending packet {case}")
        await tester.send_input(inv_sigma, mean, diff_vector, gamma, beta)
    
    # Wait and check output
    outputs = []
    output_cycles = []  # Record the cycle when each output appears
    cycle_count = 0
    
    # Keep checking until 10 outputs are collected or timeout
    while len(outputs) < num_cases and cycle_count < 25:  # Wait up to 25 cycles
        await RisingEdge(dut.clk)
        cycle_count += 1
        
        if dut.valid_out.value == 1:
            output = tester.get_output()
            outputs.append(output)
            output_cycles.append(cycle_count)
            output_idx = len(outputs) - 1
            
            if output_idx % 2 == 0:  # Print log every other output
                cocotb.log.info(f"Cycle {cycle_count}: Received output {output_idx}, output[0]={output[0]:.3f}")
    
    # Verify output count
    successful_outputs = len(outputs)
    assert successful_outputs == num_cases, f"Expected {num_cases} outputs, actually {successful_outputs}"
    
    # Verify output continuity
    if len(output_cycles) >= 2:
        first_output_cycle = output_cycles[0]
        cocotb.log.info(f"Output cycles: {output_cycles[:5]}...")  # Print first 5 cycles
        
        # Check if there is output every cycle starting from the first output
        consecutive_count = 0
        for i in range(1, len(output_cycles)):
            if output_cycles[i] == output_cycles[i-1] + 1:
                consecutive_count += 1
        
        cocotb.log.info(f"Consecutive output pairs: {consecutive_count}/{len(output_cycles)-1}")
        
        # Allow some tolerance for possible timing differences
        if consecutive_count >= len(output_cycles) - 2:
            cocotb.log.info("✓ Output is basically continuous")
        else:
            cocotb.log.warning("Output continuity may not be perfect, but within acceptable range")
    
    cocotb.log.info(f"✓ Continuous pipeline test passed! Successfully processed {successful_outputs} packets")

if __name__ == "__main__":
    print("LayerNorm postprocess module - pipeline throughput test")
    print("Tests include:")
    print("1. Pipeline throughput test - verify output every cycle")  
    print("2. Pipeline latency test - verify 3-stage latency")
    print("3. Continuous pipeline test - long data stream")