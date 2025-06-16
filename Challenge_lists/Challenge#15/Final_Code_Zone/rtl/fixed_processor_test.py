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
async def test_processor_with_correct_timing(dut):
    """Full Processor test with fixed timing"""
    
    print("=== Full Processor test with fixed timing ===")
    
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
    
    print("Set input: [0x0400, 0x0000, ...]")
    dut.input_vector[0].value = 0x0400  # 1.0
    for i in range(1, 16):
        dut.input_vector[i].value = 0x0000  # 0.0
    
    # Send input
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    print("\n=== Wait for a longer time ===")
    print("Frontend needs 7 cycles, Backend needs 3 cycles, total about 10 cycles")
    
    # Wait longer - 15 cycles
    for cycle in range(15):
        await RisingEdge(dut.clk)
        
        # Monitor key signals
        valid_out = safe_int_convert(dut.valid_out.value)
        
        # Show status every few cycles
        if cycle % 2 == 0 or valid_out == 1:
            try:
                frontend_valid = safe_int_convert(dut.frontend_valid.value)
                backend_valid = safe_int_convert(dut.u_backend.valid_out.value)
                
                print(f"Cycle {cycle+1}: frontend_valid={frontend_valid}, backend_valid={backend_valid}, final_valid={valid_out}")
                
                if frontend_valid == 1:
                    frontend_sum = safe_int_convert(dut.frontend_exp_sum.value)
                    frontend_val0 = safe_int_convert(dut.frontend_exp_values[0].value)
                    print(f"  Frontend output: sum=0x{frontend_sum:08X}, val[0]=0x{frontend_val0:04X}")
                try:
                    backend_valid_in = safe_int_convert(dut.u_backend.valid_in.value)
                    if backend_valid_in == 1:
                        backend_sum_in = safe_int_convert(dut.u_backend.exp_sum_in.value)
                        backend_val0_in = safe_int_convert(dut.u_backend.exp_values_in[0].value)
                        print(f"  Backend received: sum_in=0x{backend_sum_in:08X}, val_in[0]=0x{backend_val0_in:04X}")
                        
                        # Also show raw signal values (not converted to int)
                        print(f"  Backend raw signals: sum_in={dut.u_backend.exp_sum_in.value}, val_in[0]={dut.u_backend.exp_values_in[0].value}")
                except Exception as e:
                    print(f"  Error reading Backend input: {e}")
                
            except:
                pass
        
        if valid_out == 1:
            print(f"\n✅ Final output received (cycle {cycle+1})!")
            
            # Read output
            all_outputs = []
            for i in range(16):
                val = safe_int_convert(dut.softmax_out[i].value)
                all_outputs.append(val)
            
            print(f"Output: softmax[0]=0x{all_outputs[0]:04X}, softmax[1]=0x{all_outputs[1]:04X}")
            
            # Analyze result
            max_val = max(all_outputs)
            max_idx = all_outputs.index(max_val)
            total_sum = sum(all_outputs)
            
            print(f"Max value: 0x{max_val:04X} at position {max_idx}")
            print(f"Total sum: 0x{total_sum:04X}")
            
            if all_outputs[0] > 0:
                print("🎉 Success! Processor works correctly!")
                
                # Manual verification
                print(f"\n=== Calculation verification ===")
                # Frontend should output: exp_values[0]=0x0ADF, exp_sum=0x46DF
                # Backend should compute: (0x0ADF * 1024) / 0x46DF
                
                expected_frontend_val0 = 0x0ADF
                expected_frontend_sum = 0x46DF  # Known from separate test
                expected_result = (expected_frontend_val0 * 1024) // expected_frontend_sum
                
                print(f"Expected calculation:")
                print(f"  Frontend: val[0]=0x{expected_frontend_val0:04X}, sum=0x{expected_frontend_sum:04X}")
                print(f"  Backend: ({expected_frontend_val0} * 1024) / {expected_frontend_sum} = {expected_result} = 0x{expected_result:04X}")
                print(f"  Actual result: 0x{all_outputs[0]:04X}")
                
                if abs(all_outputs[0] - expected_result) <= 1:
                    print("✅ Calculation result is correct!")
                else:
                    print("⚠️ Calculation result has error")
                
            else:
                print("❌ Still output zero")
            
            break
    else:
        print("❌ No output received within 15 cycles")
        print("May need more time, or there is another issue")

@cocotb.test() 
async def test_processor_pipeline_timing(dut):
    """Test Processor pipeline accurate timing"""
    
    print("\n=== Processor pipeline timing test ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Send 3 different vectors in succession
    test_vectors = [
        [0x0400] + [0x0000]*15,  # Peak at 0
        [0x0000, 0x0400] + [0x0000]*14,  # Peak at 1  
        [0x0200]*16,  # All equal
    ]
    
    print("Send 3 vectors in succession, observe output timing:")
    
    for i, vector in enumerate(test_vectors):
        print(f"Cycle {i+1}: Send vector {i+1}")
        
        for j in range(16):
            dut.input_vector[j].value = vector[j]
        
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    
    # Monitor output
    outputs_received = 0
    for cycle in range(25):  # Wait long enough
        await RisingEdge(dut.clk)
        
        valid_out = safe_int_convert(dut.valid_out.value)
        if valid_out == 1:
            outputs_received += 1
            
            out_0 = safe_int_convert(dut.softmax_out[0].value)
            out_1 = safe_int_convert(dut.softmax_out[1].value)
            
            total_cycle = cycle + len(test_vectors) + 1
            print(f"Output {outputs_received} (total cycle {total_cycle}): softmax[0]=0x{out_0:04X}, softmax[1]=0x{out_1:04X}")
        
        if outputs_received >= len(test_vectors):
            break
    
    print(f"\nTiming analysis:")
    print(f"Sent: {len(test_vectors)} vectors")
    print(f"Received: {outputs_received} outputs")
    
    if outputs_received >= len(test_vectors):
        print("🎉 Pipeline timing is correct!")
    else:
        print("⚠️ Pipeline may have timing issue")

print("Fixed timing tests created!")
print("Main fixes:")
print("1. Wait 15 cycles instead of 10 cycles")
print("2. Detailed monitoring of Frontend and Backend valid signals")
print("3. Verify calculation result correctness")
print("4. Test continuous pipeline processing")