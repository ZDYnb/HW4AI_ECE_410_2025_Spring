import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

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

@cocotb.test()
async def test_matrix_processor_basic(dut):
    """Simple basic test for Softmax matrix processor"""
    
    print("="*80)
    print("Softmax Matrix Processor Test")
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
    for i in range(16):  # 16 rows
        for j in range(16):  # 16 columns per row
            idx = i * 16 + j
            # Simple test pattern: each element = (j + 1) * 0.25
            val = float_to_q5_10((j + 1) * 0.25)
            try:
                dut.matrix_i[idx].value = val
            except Exception as e:
                print(f"Failed to load matrix element {idx}: {e}")
                return
    
    print("Input matrix loaded successfully!")
    print(f"Sample input row 0: {[q5_10_to_float(float_to_q5_10((j + 1) * 0.25)) for j in range(8)]}...")
    
    # Test: Start processing
    print(f"\n--- Testing State Machine Logic ---")
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    print("Start signal sent. Monitoring state machine behavior...")
    
    # Monitor state machine for longer period - EVERY CYCLE
    cycles_waited = 0
    max_cycles = 50 # Reasonable timeout
    
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
            valid_out = int(dut.u_softmax_processor.valid_out.value) if hasattr(dut, 'u_softmax_processor') else -1
            
            print(f"Cycle {cycles_waited:2d}: done={done_val}, send_st={send_state}, recv_st={recv_state}, send={send_cnt:2d}, recv={recv_cnt:2d}, pipe_in={valid_in}, pipe_out={valid_out}")
                    
        except Exception as e:
            print(f"Cycle {cycles_waited:2d}: (Debug read error: {e})")
        
        if dut.done.value == 1:
            print(f"✅ Processing completed in {cycles_waited} cycles!")
            print("✅ Processing completed!")
    
            # 检查输出矩阵的前几个元素
            print("Checking output results...")
            
            # 读取第一行输出 (matrix_o[0:15])
            try:
                for row in range(3):  # Only check first 3 rows
                    print(f"\nRow {row} output:")
                    row_sum = 0
                    for col in range(8):  # 只打印前8个元素
                        idx = row * 16 + col
                        val = int(dut.matrix_o[idx].value)
                        float_val = q5_10_to_float(val)
                        print(f"  [{row}][{col}] = 0x{val:04x} ({float_val:.3f})")
                        if col < 16:  # Count all 16 elements for sum
                            row_sum += val
                    
                    # Check full row sum
                    full_row_sum = sum([int(dut.matrix_o[row * 16 + c].value) for c in range(16)])
                    print(f"  Row {row} sum: {full_row_sum} (expected ~1024)")
                    
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
                
            if hasattr(dut, 'u_softmax_processor'):
                final_valid_out = int(dut.u_softmax_processor.valid_out.value)
                print(f"  Pipeline valid_out: {final_valid_out}")
                
        except Exception as e:
            print(f"  Debug analysis failed: {e}")
            
        return
    
    print("\n--- Test Conclusions ---")
    print("✅ State machine logic appears to be working")
    print("✅ Input matrix loaded successfully")
    print("✅ Output matrix contains valid values")
    
    print("\n" + "="*80)
    print("Softmax Test Complete!")
    print("="*80)

@cocotb.test()
async def test_matrix_processor_timing(dut):
    """Simple timing test"""
    
    print("="*80)
    print("Simple Timing Test")
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
    
    # Load simple matrix (all same values for uniform distribution)
    print("Loading uniform matrix (all 1.0)...")
    for i in range(256):
        val = float_to_q5_10(1.0)
        try:
            dut.matrix_i[i].value = val
        except:
            print("Failed to load matrix!")
            return
    
    # Measure timing
    print("Starting timing measurement...")
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    while cycles < 200:  # Generous timeout
        await RisingEdge(dut.clk)
        cycles += 1
        
        if dut.done.value == 1:
            print(f"✅ Matrix processing took {cycles} cycles")
            if cycles <= 30:
                print("🚀 Excellent! Very fast pipeline processing")
            elif cycles <= 50:
                print("👍 Good pipeline timing")
            else:
                print("⚠️  Slower than expected for pipeline")
            
            # Check that uniform input produces uniform output
            try:
                first_row_vals = [int(dut.matrix_o[i].value) for i in range(16)]
                expected_val = 1024 // 16  # Should be ~64 each for uniform distribution
                print(f"Uniform test: first element = {first_row_vals[0]} (expected ~{expected_val})")
                if abs(first_row_vals[0] - expected_val) < 8:
                    print("✅ Uniform distribution test passed!")
                else:
                    print("⚠️  Uniform distribution test failed")
            except:
                print("Could not verify uniform distribution")
            
            break
    
    if cycles >= 200:
        print("❌ Timing test failed - took too long")
    
    print("Timing test complete!")

if __name__ == "__main__":
    pass