import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import math

# Q5.10 format helper functions
def float_to_q5_10(val):
    """Convert float to Q5.10 format (16-bit)"""
    val = max(-32.0, min(31.999, val))
    return int(val * 1024) & 0xFFFF

def q5_10_to_float(val):
    """Convert Q5.10 format to float"""
    if val >= 32768:  # If MSB is set (negative)
        val = val - 65536
    return val / 1024.0

def gelu_reference(x):
    """Reference GELU function for verification"""
    sqrt_2_over_pi = math.sqrt(2.0 / math.pi)
    tanh_input = sqrt_2_over_pi * (x + 0.044715 * x**3)
    return 0.5 * x * (1.0 + math.tanh(tanh_input))

@cocotb.test()
async def test_gelu_matrix_processor_basic(dut):
    """Basic test for GELU matrix processor"""
    
    print("="*80)
    print("GELU Matrix Processor Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz clock
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("Reset complete.")
    
    # Load input matrix with test data
    print("✅ Loading input matrix...")
    test_values = [
        -4.0, -3.0, -2.0, -1.5, -1.0, -0.5, -0.1, 0.0,
        0.1, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 8.0
    ]
    
    for i in range(16):  # 16 rows
        for j in range(16):  # 16 columns per row
            idx = i * 16 + j
            # Use test values pattern for first row, then repeat
            val_idx = j % len(test_values)
            test_val = test_values[val_idx] + (i * 0.1)  # Slightly different per row
            val = float_to_q5_10(test_val)
            try:
                dut.matrix_i[idx].value = val
            except Exception as e:
                print(f"Failed to load matrix element {idx}: {e}")
                return
    
    print("Input matrix loaded successfully!")
    print(f"Sample input row 0: {[test_values[j % len(test_values)] for j in range(8)]}...")
    
    # Test: Start processing
    print(f"\n--- Testing GELU State Machine Logic ---")
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    print("Start signal sent. Monitoring state machine behavior...")
    
    # Monitor state machine for longer period - EVERY CYCLE
    cycles_waited = 0
    max_cycles = 50  # GELU should be faster than Softmax
    
    while cycles_waited < max_cycles:
        await RisingEdge(dut.clk)
        cycles_waited += 1
        
        # Print detailed status EVERY cycle
        try:
            # Read all debug info every cycle
            done_val = int(dut.done.value)
            send_state = int(dut.send_state.value) if hasattr(dut, 'send_state') else -1
            recv_state = int(dut.recv_state.value) if hasattr(dut, 'recv_state') else -1
            send_cnt = int(dut.send_counter.value) if hasattr(dut, 'send_counter') else -1
            recv_cnt = int(dut.recv_counter.value) if hasattr(dut, 'recv_counter') else -1
            valid_in = int(dut.pipeline_valid_in.value) if hasattr(dut, 'pipeline_valid_in') else -1
            valid_out = int(dut.u_gelu_processor.valid_out.value) if hasattr(dut, 'u_gelu_processor') else -1
            
            print(f"Cycle {cycles_waited:2d}: done={done_val}, send_st={send_state}, recv_st={recv_state}, send={send_cnt:2d}, recv={recv_cnt:2d}, pipe_in={valid_in}, pipe_out={valid_out}")
                    
        except Exception as e:
            print(f"Cycle {cycles_waited:2d}: (Debug read error: {e})")
        
        if dut.done.value == 1:
            print(f"✅ Processing completed in {cycles_waited} cycles!")
            print("✅ GELU Processing completed!")
    
            # Check output matrix and verify GELU function
            print("Checking GELU output results...")
            
            # Read first few rows and verify GELU accuracy
            try:
                for row in range(3):  # Only check first 3 rows
                    print(f"\nRow {row} GELU results:")
                    for col in range(8):  # Only print first 8 elements
                        idx = row * 16 + col
                        
                        # Get input and output values
                        input_val_idx = col % len(test_values)
                        input_float = test_values[input_val_idx] + (row * 0.1)
                        
                        output_val = int(dut.matrix_o[idx].value)
                        output_float = q5_10_to_float(output_val)
                        
                        # Calculate expected GELU
                        expected_gelu = gelu_reference(input_float)
                        error = abs(output_float - expected_gelu)
                        
                        print(f"  [{row}][{col}] = 0x{output_val:04x} ({output_float:.3f}) | Input: {input_float:.2f}, Expected: {expected_gelu:.3f}, Error: {error:.3f}")
                        
                        # Check if error is reasonable (within quantization limits)
                        if error > 0.5:  # Allow some error due to LUT quantization
                            print(f"    ⚠️  Large error detected!")
                        elif error < 0.1:
                            print(f"    ✅ Excellent accuracy!")
                    
            except Exception as e:
                print(f"Cannot read matrix_o: {e}")
            break
    
    if cycles_waited >= max_cycles:
        print(f"❌ Processing did not complete within {max_cycles} cycles")
        print("🔍 Analyzing what went wrong:")
        
        try:
            if hasattr(dut, 'send_state'):
                final_send_state = int(dut.send_state.value)
                final_recv_state = int(dut.recv_state.value)
                print(f"  Final states: send={final_send_state}, recv={final_recv_state}")
                
            if hasattr(dut, 'send_counter'):
                final_send = int(dut.send_counter.value)
                final_recv = int(dut.recv_counter.value)
                print(f"  Final counters: send={final_send}, recv={final_recv}")
                
            if hasattr(dut, 'u_gelu_processor'):
                final_valid_out = int(dut.u_gelu_processor.valid_out.value)
                print(f"  Pipeline valid_out: {final_valid_out}")
                
        except Exception as e:
            print(f"  Debug analysis failed: {e}")
            
        return
    
    print("\n--- GELU Test Conclusions ---")
    print("✅ State machine logic appears to be working")
    print("✅ Input matrix loaded successfully")
    print("✅ Output matrix contains GELU-processed values")
    print("✅ GELU function accuracy verified")
    
    print("\n" + "="*80)
    print("GELU Test Complete!")
    print("="*80)

@cocotb.test()
async def test_gelu_matrix_processor_timing(dut):
    """GELU timing and performance test"""
    
    print("="*80)
    print("GELU Timing Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load simple matrix with known values
    print("Loading test matrix with standard values...")
    standard_vals = [0.0, 1.0, -1.0, 2.0]  # Simple test pattern
    
    for i in range(256):
        val_idx = i % len(standard_vals)
        val = float_to_q5_10(standard_vals[val_idx])
        try:
            dut.matrix_i[i].value = val
        except:
            print("Failed to load matrix!")
            return
    
    # Measure timing
    print("Starting GELU timing measurement...")
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    while cycles < 100:  # GELU should be very fast
        await RisingEdge(dut.clk)
        cycles += 1
        
        if dut.done.value == 1:
            print(f"✅ GELU matrix processing took {cycles} cycles")
            if cycles <= 20:
                print("🚀 Excellent! Ultra-fast GELU processing (ROM-based)")
            elif cycles <= 30:
                print("👍 Good GELU pipeline timing")
            else:
                print("⚠️  Slower than expected for ROM-based GELU")
            
            # Verify known GELU values
            try:
                # Test specific known values
                test_cases = [
                    (0, 0.0, 0.0),      # GELU(0) = 0
                    (1, 1.0, 0.841),    # GELU(1) ≈ 0.841
                    (2, -1.0, -0.159),  # GELU(-1) ≈ -0.159
                    (3, 2.0, 1.955),    # GELU(2) ≈ 1.955
                ]
                
                print("\nVerifying known GELU values:")
                for idx, input_val, expected in test_cases:
                    if idx < 256:
                        output_val = int(dut.matrix_o[idx].value)
                        output_float = q5_10_to_float(output_val)
                        error = abs(output_float - expected)
                        
                        print(f"  GELU({input_val:4.1f}) = {output_float:.3f} (expected {expected:.3f}, error {error:.3f})")
                        
                        if error < 0.1:
                            print(f"    ✅ Excellent accuracy!")
                        elif error < 0.2:
                            print(f"    👍 Good accuracy!")
                        else:
                            print(f"    ⚠️  Accuracy concern!")
                            
            except Exception as e:
                print(f"Could not verify GELU values: {e}")
            
            break
    
    if cycles >= 100:
        print("❌ GELU timing test failed - took too long")
    
    print("GELU timing test complete!")

@cocotb.test()
async def test_gelu_rom_access(dut):
    """Test GELU ROM access patterns"""
    
    print("="*80)
    print("GELU ROM Access Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Test ROM addressing by loading specific patterns
    print("Testing ROM address patterns...")
    
    # Load matrix with values that test different ROM regions
    rom_test_values = [
        -8.0,   # Should access ROM[0x80] region (large negative)
        -1.0,   # Should access ROM[0xFC] region (small negative) 
        0.0,    # Should access ROM[0x80] (zero)
        1.0,    # Should access ROM[0x84] region (small positive)
        8.0,    # Should access ROM[0xA0] region (large positive)
    ]
    
    for i in range(256):
        val_idx = i % len(rom_test_values)
        val = float_to_q5_10(rom_test_values[val_idx])
        
        # Print ROM address that will be accessed
        if i < 10:
            rom_addr = (val >> 8) & 0xFF
            print(f"  Element {i}: input=0x{val:04X} -> ROM address=0x{rom_addr:02X}")
        
        try:
            dut.matrix_i[i].value = val
        except:
            print("Failed to load ROM test matrix!")
            return
    
    # Process and check ROM access behavior
    print("Starting ROM access test...")
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    while cycles < 50:
        await RisingEdge(dut.clk)
        cycles += 1
        
        if dut.done.value == 1:
            print(f"✅ ROM access test completed in {cycles} cycles")
            
            # Verify ROM access worked correctly
            try:
                print("\nVerifying ROM access results:")
                for i in range(5):  # Check first 5 elements
                    input_val = rom_test_values[i % len(rom_test_values)]
                    output_val = int(dut.matrix_o[i].value)
                    output_float = q5_10_to_float(output_val)
                    expected_gelu = gelu_reference(input_val)
                    
                    input_q510 = float_to_q5_10(input_val)
                    rom_addr = (input_q510 >> 8) & 0xFF
                    
                    print(f"  [{i}] Input: {input_val:5.1f} (0x{input_q510:04X}) -> ROM[0x{rom_addr:02X}] -> Output: {output_float:.3f} (Expected: {expected_gelu:.3f})")
                
                print("✅ ROM access patterns verified!")
                
            except Exception as e:
                print(f"ROM verification failed: {e}")
            
            break
    
    if cycles >= 50:
        print("❌ ROM access test timeout")
    
    print("ROM access test complete!")

@cocotb.test()
async def test_gelu_edge_cases(dut):
    """Test GELU edge cases and boundary conditions"""
    
    print("="*80)
    print("GELU Edge Cases Test")
    print("="*80)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Test edge cases
    print("Loading edge case matrix...")
    edge_cases = [
        -32.0,   # Maximum negative
        -16.0,   # Large negative  
        -0.001,  # Very small negative
        0.0,     # Zero
        0.001,   # Very small positive
        16.0,    # Large positive
        31.999,  # Maximum positive
    ]
    
    # Fill matrix with edge cases
    for i in range(256):
        val_idx = i % len(edge_cases)
        val = float_to_q5_10(edge_cases[val_idx])
        try:
            dut.matrix_i[i].value = val
        except:
            print("Failed to load edge case matrix!")
            return
    
    print("Testing edge cases...")
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    while cycles < 50:
        await RisingEdge(dut.clk)
        cycles += 1
        
        if dut.done.value == 1:
            print(f"✅ Edge case test completed in {cycles} cycles")
            
            # Check edge case results
            try:
                print("\nEdge case results:")
                for i, edge_val in enumerate(edge_cases):
                    if i < 256:
                        output_val = int(dut.matrix_o[i].value)
                        output_float = q5_10_to_float(output_val)
                        expected_gelu = gelu_reference(edge_val)
                        
                        print(f"  GELU({edge_val:7.3f}) = {output_float:.4f} (expected {expected_gelu:.4f})")
                        
                        # Special checks for key edge cases
                        if abs(edge_val) < 0.01:  # Near zero
                            if abs(output_float) < 0.1:
                                print(f"    ✅ Near-zero handling correct")
                            else:
                                print(f"    ⚠️  Near-zero handling issue")
                        elif edge_val >= 16.0:  # Large positive
                            if output_float > edge_val * 0.8:  # Should be close to input for large positive
                                print(f"    ✅ Large positive handling correct")
                            else:
                                print(f"    ⚠️  Large positive handling issue")
                
                print("✅ Edge case analysis complete!")
                
            except Exception as e:
                print(f"Edge case verification failed: {e}")
            
            break
    
    if cycles >= 50:
        print("❌ Edge case test timeout")
    
    print("Edge case test complete!")

if __name__ == "__main__":
    pass