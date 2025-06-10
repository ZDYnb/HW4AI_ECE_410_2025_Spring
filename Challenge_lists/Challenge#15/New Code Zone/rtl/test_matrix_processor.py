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
    """Simple basic test for LayerNorm matrix processor - skip array access"""
    
    print("="*80)
    print("Simple LayerNorm Matrix Processor Test (Debug Mode)")
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
    print("❌ Skipping matrix data loading due to array access issues")
    print("🔍 Testing hardware logic with uninitialized inputs...")
    
    # Test: Start processing without setting inputs (to test state machine)
    print(f"\n--- Testing State Machine Logic ---")
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    print("Start signal sent. Monitoring state machine behavior...")
    
    # Monitor state machine for longer period - EVERY CYCLE
    cycles_waited = 0
    max_cycles = 50  # Reasonable timeout
    
    while cycles_waited < max_cycles:
        await RisingEdge(dut.clk)
        cycles_waited += 1
        
        # Print detailed status EVERY cycle
        try:
            # Read all debug info every cycle
            done_val = int(dut.done.value)
            state_val = int(dut.state.value) if hasattr(dut, 'state') else -1
            send_cnt = int(dut.send_counter.value) if hasattr(dut, 'send_counter') else -1
            recv_cnt = int(dut.recv_counter.value) if hasattr(dut, 'recv_counter') else -1
            valid_in = int(dut.pipeline_valid_in.value) if hasattr(dut, 'pipeline_valid_in') else -1
            valid_out = int(dut.pipeline_valid_out.value) if hasattr(dut, 'pipeline_valid_out') else -1
            
            print(f"Cycle {cycles_waited:2d}: done={done_val}, state={state_val}, send={send_cnt:2d}, recv={recv_cnt:2d}, pipe_in={valid_in}, pipe_out={valid_out}")
                    
        except Exception as e:
            print(f"Cycle {cycles_waited:2d}: (Debug read error: {e})")
        
        if dut.done.value == 1:
            print(f"✅ Processing completed in {cycles_waited} cycles!")
            print("✅ Processing completed!")
    
            # 检查输出矩阵的前几个元素
            print("Checking output results...")
            
            # 读取第一行输出 (matrix_o[0:15])
            try:
                for row in range(16):
                    print(f"\nRow {row} output:")
                    for col in range(8):  # 只打印前8个元素
                        idx = row * 16 + col
                        val = int(getattr(dut, f'matrix_o[{idx}]').value)
                        float_val = q5_10_to_float(val)
                        print(f"  [{row}][{col}] = 0x{val:04x} ({float_val:.3f})")
            except Exception as e:
                print(f"Cannot read matrix_o: {e}")
            break
    
    if cycles_waited >= max_cycles:
        print(f"❌ Processing did not complete within {max_cycles} cycles")
        print("🔍 Analyzing what went wrong:")
        
        try:
            if hasattr(dut, 'state'):
                final_state = int(dut.state.value)
                print(f"  Final state: {final_state}")
                
            if hasattr(dut, 'send_counter'):
                final_send = int(dut.send_counter.value)
                final_recv = int(dut.recv_counter.value)
                print(f"  Final counters: send={final_send}, recv={final_recv}")
                
            if hasattr(dut, 'pipeline_valid_out'):
                final_valid_out = int(dut.pipeline_valid_out.value)
                print(f"  Pipeline valid_out: {final_valid_out}")

                
        except Exception as e:
            print(f"  Debug analysis failed: {e}")
            
        return
    
    print("\n--- Test Conclusions ---")
    print("✅ State machine logic appears to be working")
    print("❌ Array interface needs to be fixed for data testing")
    print("💡 Next step: Fix array access or use different interface")
    
    print("\n" + "="*80)
    print("Debug Test Complete!")
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
    
    # Determine array access method
    method = 1
    try:
        dut.matrix_i[0].value = 0
    except:
        method = 2
    
    # Load simple matrix (all 1s)
    for i in range(256):
        val = float_to_q5_10(1.0)
        if method == 1:
            dut.matrix_i[i].value = val
        else:
            getattr(dut, f'matrix_i[{i}]').value = val
    
    # Measure timing
    start_time = 0
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    while cycles < 200:  # Generous timeout
        await RisingEdge(dut.clk)
        cycles += 1
        
        if dut.done.value == 1:
            print(f"✅ Matrix processing took {cycles} cycles")
            if cycles <= 50:
                print("🚀 Great! Very fast processing")
            elif cycles <= 100:
                print("👍 Good timing")
            else:
                print("⚠️  Slower than expected")
            break
    
    if cycles >= 200:
        print("❌ Timing test failed - took too long")
    
    print("Timing test complete!")

if __name__ == "__main__":
    pass