import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def q5_10_to_float(val):
    """Convert Q5.10 format to float (signed)"""
    if val >= 32768:  # MSB set = negative
        val = val - 65536
    return val / 1024.0

def safe_read_signal(signal, name, default=0):
    """Safely read a signal, handling X values"""
    try:
        val = signal.value
        if 'x' in str(val).lower() or 'z' in str(val).lower():
            return "X/Z"
        
        # 正确获取整数值
        if hasattr(val, 'integer'):
            return val.integer
        else:
            return int(val)
            
    except Exception as e:
        return "ERR"

def check_separated_buses_for_x(dut, cycle_num):
    """Check all separated bus signals for X values with proper Q5.10 conversion"""
    print(f"\n=== Cycle {cycle_num} Separated Bus Analysis ===")
    
    # Check shared input buses (still shared)
    bus_a_x_count = 0
    bus_b_x_count = 0
    
    # Check separated output buses (NEW!)
    mult_c_x_count = 0
    ln_c_x_count = 0
    sm_c_x_count = 0
    gelu_c_x_count = 0
    
    # Sample first 4 elements of each bus
    for i in range(4):
        try:
            val_a = safe_read_signal(dut.bus_matrix_a[i], f"bus_a[{i}]")
            val_b = safe_read_signal(dut.bus_matrix_b[i], f"bus_b[{i}]") 
            
            # Check separated output wires
            val_mult_c = safe_read_signal(dut.mult_matrix_c[i], f"mult_c[{i}]")
            val_ln_c = safe_read_signal(dut.ln_matrix_c[i], f"ln_c[{i}]")
            val_sm_c = safe_read_signal(dut.sm_matrix_c[i], f"sm_c[{i}]")
            val_gelu_c = safe_read_signal(dut.gelu_matrix_c[i], f"gelu_c[{i}]")
            
            if val_a == "X/Z": 
                bus_a_x_count += 1
                print(f"  bus[{i}]: A=X/Z, ", end="")
            else:
                float_a = q5_10_to_float(val_a)
                print(f"  bus[{i}]: A=0x{val_a:04x}({float_a:.3f}), ", end="")
                
            if val_b == "X/Z": 
                bus_b_x_count += 1
                print(f"B=X/Z")
            else:
                float_b = q5_10_to_float(val_b)
                print(f"B=0x{val_b:04x}({float_b:.3f})")
                
            # Check separated outputs
            outputs = [
                (val_mult_c, "mult_c", mult_c_x_count),
                (val_ln_c, "ln_c", ln_c_x_count), 
                (val_sm_c, "sm_c", sm_c_x_count),
                (val_gelu_c, "gelu_c", gelu_c_x_count)
            ]
            
            for val, name, x_count in outputs:
                if val == "X/Z":
                    print(f"    {name}[{i}]=X/Z", end=" ")
                elif val == "ERR":
                    print(f"    {name}[{i}]=ERR", end=" ")
                else:
                    float_val = q5_10_to_float(val)
                    print(f"    {name}[{i}]=0x{val:04x}({float_val:.3f})", end=" ")
            print()  # newline
                
        except Exception as e:
            print(f"  bus[{i}]: Cannot read - {e}")
    
    # Count X values in separated output buses (check 16 elements)
    for i in range(4, 16):
        try:
            if safe_read_signal(dut.bus_matrix_a[i], f"bus_a[{i}]") == "X/Z": 
                bus_a_x_count += 1
            if safe_read_signal(dut.bus_matrix_b[i], f"bus_b[{i}]") == "X/Z": 
                bus_b_x_count += 1
            if safe_read_signal(dut.mult_matrix_c[i], f"mult_c[{i}]") == "X/Z": 
                mult_c_x_count += 1
            if safe_read_signal(dut.ln_matrix_c[i], f"ln_c[{i}]") == "X/Z": 
                ln_c_x_count += 1
            if safe_read_signal(dut.sm_matrix_c[i], f"sm_c[{i}]") == "X/Z": 
                sm_c_x_count += 1
            if safe_read_signal(dut.gelu_matrix_c[i], f"gelu_c[{i}]") == "X/Z": 
                gelu_c_x_count += 1
        except:
            pass
    
    print(f"  Input Bus X count: A={bus_a_x_count}/16, B={bus_b_x_count}/16")
    print(f"  Output Bus X count: mult={mult_c_x_count}/16, ln={ln_c_x_count}/16, sm={sm_c_x_count}/16, gelu={gelu_c_x_count}/16")
    
    # Check intermediate storage
    try:
        input_x = sum([1 for i in range(16) if safe_read_signal(dut.input_matrix[i], f"input[{i}]") == "X/Z"])
        ln_input_x = sum([1 for i in range(16) if safe_read_signal(dut.ln_input_output[i], f"ln_input[{i}]") == "X/Z"])
        working_x = sum([1 for i in range(16) if safe_read_signal(dut.working_matrix[i], f"working[{i}]") == "X/Z"])
        v_x = sum([1 for i in range(16) if safe_read_signal(dut.v_matrix[i], f"v[{i}]") == "X/Z"])
        k_x = sum([1 for i in range(16) if safe_read_signal(dut.k_matrix[i], f"k[{i}]") == "X/Z"])
        ln1_x = sum([1 for i in range(16) if safe_read_signal(dut.ln1_output[i], f"ln1[{i}]") == "X/Z"])
        
        print(f"  Storage X count: input={input_x}/16, ln_input={ln_input_x}/16, working={working_x}/16")
        print(f"                   v={v_x}/16, k={k_x}/16, ln1={ln1_x}/16")
    except Exception as e:
        print(f"  Storage check failed: {e}")

def check_active_output_bus(dut, cycle_num):
    """Check which output bus is currently active based on state"""
    try:
        current_state = int(dut.current_state.value)
        state_names = {
            0: "IDLE", 1: "EMBEDDING", 2: "LAYERNORM_INPUT", 3: "SAVE_LN_INPUT",
            4: "COMPUTE_Q", 5: "SAVE_Q", 6: "COMPUTE_K", 7: "SAVE_K", 
            8: "COMPUTE_V", 9: "SAVE_V", 10: "COMPUTE_SCORES", 11: "SOFTMAX_SCORES", 
            12: "COMPUTE_ATTN", 13: "ADD_RESIDUAL_1", 14: "LAYERNORM_1", 15: "SAVE_LN1",
            16: "COMPUTE_FF1", 17: "GELU_FF1", 18: "COMPUTE_FF2",
            19: "ADD_RESIDUAL_2", 20: "LAYERNORM_2", 21: "COMPUTE_OUTPUT",
            22: "SOFTMAX_OUTPUT", 23: "DONE_STATE"
        }
        
        # Determine which output bus should be active
        active_bus = "none"
        if current_state in [4, 6, 8, 10, 12, 16, 18, 21]:  # COMPUTE states
            active_bus = "mult_matrix_c"
        elif current_state in [2, 14, 20]:  # LAYERNORM states
            active_bus = "ln_matrix_c"  
        elif current_state in [11, 22]:  # SOFTMAX states
            active_bus = "sm_matrix_c"
        elif current_state == 17:  # GELU state
            active_bus = "gelu_matrix_c"
            
        state_name = state_names.get(current_state, f"UNK({current_state})")
        print(f"  Active state: {state_name} → Expected active bus: {active_bus}")
        
        return active_bus
        
    except Exception as e:
        print(f"  Cannot determine active bus: {e}")
        return "unknown"

@cocotb.test() 
async def test_separated_bus_monitoring(dut):
    """Monitor separated bus activity cycle by cycle with proper Q5.10 handling"""
    
    # Set environment variable for X handling
    import os
    os.environ['COCOTB_RESOLVE_X'] = 'VALUE_ERROR'
    
    print("="*80)
    print("Separated Bus Architecture Monitoring Test (Q5.10 Format)")
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
    
    print("Reset complete. Checking initial state...")
    check_separated_buses_for_x(dut, 0)
    
    # Set input tokens
    test_tokens = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    for i in range(16):
        getattr(dut, f'input_tokens_{i}').value = test_tokens[i]
    
    print(f"\nSet input tokens: {test_tokens}")
    
    # Check embedding values
    print("\nChecking embedding lookup...")
    try:
        for i in range(4):
            token_id = test_tokens[i]
            emb_addr = token_id * 16
            emb_val = safe_read_signal(dut.embedding[emb_addr], f"emb[{emb_addr}]")
            if emb_val != "X/Z" and emb_val != "ERR":
                emb_float = q5_10_to_float(emb_val)
                print(f"  Token[{i}]={token_id} → embedding[{emb_addr}] = 0x{emb_val:04x} ({emb_float:.3f})")
    except Exception as e:
        print(f"  Cannot read embeddings: {e}")
    
    print("\nStarting GPT-2 pipeline with separated bus monitoring...")
    
    # Start and monitor every 2 cycles + key transition cycles
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    cycles = 0
    key_states = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 22, 23]  # All major states
    
    while cycles < 500 and not dut.done.value:  # Increased timeout for safety
        await RisingEdge(dut.clk)
        cycles += 1
        
        try:
            current_state = int(dut.current_state.value)
            state_names = {
                0: "IDLE", 1: "EMBEDDING", 2: "LAYERNORM_INPUT", 3: "SAVE_LN_INPUT",
                4: "COMPUTE_Q", 5: "SAVE_Q", 6: "COMPUTE_K", 7: "SAVE_K", 
                8: "COMPUTE_V", 9: "SAVE_V", 10: "COMPUTE_SCORES", 11: "SOFTMAX_SCORES", 
                12: "COMPUTE_ATTN", 13: "ADD_RESIDUAL_1", 14: "LAYERNORM_1", 15: "SAVE_LN1",
                16: "COMPUTE_FF1", 17: "GELU_FF1", 18: "COMPUTE_FF2",
                19: "ADD_RESIDUAL_2", 20: "LAYERNORM_2", 21: "COMPUTE_OUTPUT",
                22: "SOFTMAX_OUTPUT", 23: "DONE_STATE"
            }
            state_name = state_names.get(current_state, f"UNK({current_state})")
            
            # Check separated buses every 2 cycles or during key states
            if cycles % 2 == 0 or current_state in key_states:
                print(f"\nCycle {cycles}: State = {state_name}")
                check_separated_buses_for_x(dut, cycles)
                active_bus = check_active_output_bus(dut, cycles)
                
                # Check module control signals
                try:
                    mult_start = safe_read_signal(dut.mult_start, "mult_start")
                    mult_done = safe_read_signal(dut.mult_done, "mult_done")
                    layernorm_start = safe_read_signal(dut.layernorm_start, "layernorm_start")
                    layernorm_done = safe_read_signal(dut.layernorm_done, "layernorm_done")
                    softmax_start = safe_read_signal(dut.softmax_start, "softmax_start")
                    softmax_done = safe_read_signal(dut.softmax_done, "softmax_done")
                    gelu_start = safe_read_signal(dut.gelu_start, "gelu_start")
                    gelu_done = safe_read_signal(dut.gelu_done, "gelu_done")
                    
                    print(f"  Control: mult_start={mult_start}, mult_done={mult_done}")
                    print(f"           ln_start={layernorm_start}, ln_done={layernorm_done}")
                    print(f"           sm_start={softmax_start}, sm_done={softmax_done}")
                    print(f"           gelu_start={gelu_start}, gelu_done={gelu_done}")
                    
                    # Highlight race condition elimination
                    if mult_start == 1 and layernorm_start == 1:
                        print("  ⚠️  WARNING: Multiple starts detected!")
                    if mult_done == 1 and layernorm_done == 1:
                        print("  ⚠️  WARNING: Multiple done signals!")
                    if active_bus != "none":
                        print(f"  ✅ Active output bus: {active_bus}")
                        
                except:
                    print("  Control signals not accessible")
            
        except Exception as e:
            print(f"Cycle {cycles}: State read error: {e}")
    
    # Final output check with separated wires
    print(f"\n=== Final Output Analysis (Cycle {cycles}) ===")
    
    if dut.done.value:
        print("✅ Pipeline completed with separated wire architecture!")
        
        # Check all output probabilities with proper Q5.10 conversion
        x_count = 0
        valid_count = 0
        prob_sum = 0.0
        
        print("Output probabilities (from sm_matrix_c):")
        for i in range(16):
            try:
                prob_signal = getattr(dut, f'output_prob_{i}')
                val = safe_read_signal(prob_signal, f"prob_{i}")
                
                if val == "X/Z":
                    print(f"  prob[{i:2d}] = X/Z ❌")
                    x_count += 1
                elif val == "ERR":
                    print(f"  prob[{i:2d}] = ERROR ❌") 
                    x_count += 1
                else:
                    float_val = q5_10_to_float(val)
                    prob_sum += float_val
                    print(f"  prob[{i:2d}] = 0x{val:04x} ({float_val:.6f}) ✅")
                    valid_count += 1
                    
            except Exception as e:
                print(f"  prob[{i:2d}] = EXCEPTION: {e} ❌")
                x_count += 1
        
        print(f"\nOutput Summary: {valid_count} valid, {x_count} invalid")
        print(f"Probability sum: {prob_sum:.6f} (should be ~1.0 for softmax)")
        
        # Check final state of all separated buses
        print("\nFinal separated bus state:")
        check_separated_buses_for_x(dut, cycles)
        
        if valid_count > 0 and abs(prob_sum - 1.0) < 0.1:
            print("✅ Output probabilities look reasonable!")
            print("✅ Separated wire architecture working correctly!")
        elif x_count > 0:
            print("🔍 X values detected in output! Race condition might still exist...")
        else:
            print("⚠️  Probability sum doesn't look like softmax output")
            
    else:
        print("❌ Pipeline did not complete within timeout")
        print("🔍 Final state analysis:")
        try:
            final_state = int(dut.current_state.value)
            state_names = {
                0: "IDLE", 1: "EMBEDDING", 2: "LAYERNORM_INPUT", 3: "SAVE_LN_INPUT",
                4: "COMPUTE_Q", 5: "SAVE_Q", 6: "COMPUTE_K", 7: "SAVE_K", 
                8: "COMPUTE_V", 9: "SAVE_V", 10: "COMPUTE_SCORES", 11: "SOFTMAX_SCORES", 
                12: "COMPUTE_ATTN", 13: "ADD_RESIDUAL_1", 14: "LAYERNORM_1", 15: "SAVE_LN1",
                16: "COMPUTE_FF1", 17: "GELU_FF1", 18: "COMPUTE_FF2",
                19: "ADD_RESIDUAL_2", 20: "LAYERNORM_2", 21: "COMPUTE_OUTPUT",
                22: "SOFTMAX_OUTPUT", 23: "DONE_STATE"
            }
            final_state_name = state_names.get(final_state, f"UNK({final_state})")
            print(f"  Final state: {final_state_name}")
            check_separated_buses_for_x(dut, cycles)
        except Exception as e:
            print(f"  Cannot read final state: {e}")
    
    print("\n" + "="*80)
    print("Separated Bus Monitoring Complete!")
    print("Race condition analysis: Look for any simultaneous 'done' signals")
    print("="*80)

if __name__ == "__main__":
    pass