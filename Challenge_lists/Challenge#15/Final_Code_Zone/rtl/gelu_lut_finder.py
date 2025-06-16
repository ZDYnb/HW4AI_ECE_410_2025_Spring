import numpy as np
import math

def generate_correct_gelu_lut():
    """
    Generate GELU LUT with CORRECT address mapping for hardware
    Strategy: For each 8-bit address, calculate what Q5.10 input it represents,
    then calculate GELU of that input value
    """
    
    print("Generating CORRECT GELU LUT (8-bit addressing)")
    print("=" * 55)
    
    def gelu_function(x):
        """GELU activation function"""
        sqrt_2_over_pi = math.sqrt(2.0 / math.pi)  # ≈ 0.7978845608
        tanh_input = sqrt_2_over_pi * (x + 0.044715 * x**3)
        return 0.5 * x * (1.0 + math.tanh(tanh_input))
    
    def float_to_q510(f):
        """Convert float to Q5.10 integer representation with saturation"""
        if f >= 31.999:
            return 0x7FFF
        elif f <= -32.0:
            return 0x8000
        else:
            fixed_point = int(round(f * 1024.0))
            if fixed_point < 0:
                fixed_point = fixed_point + 65536
            return fixed_point & 0xFFFF
    
    def q510_to_float(q510_int):
        """Convert Q5.10 integer to float"""
        if q510_int >= 32768:  # Negative number (2's complement)
            return (q510_int - 65536) / 1024.0
        else:  # Positive number
            return q510_int / 1024.0
    
    lut_indices = []
    input_values = []
    gelu_values = []
    lut_hex = []
    
    print("Correct Address Mapping:")
    print("Hardware uses input_vector[15:8] as address")
    print("So address 0x04 means input has MSB 8 bits = 0x04xx")
    print("And address 0xFC means input has MSB 8 bits = 0xFCxx")
    print()
    
    # Generate LUT for all 256 possible addresses (0x00 to 0xFF)
    for addr in range(256):
        # Convert address back to Q5.10 input value
        # Address is the MSB 8 bits, so multiply by 256 to get Q5.10 value
        q510_input = addr << 8  # Shift left 8 bits (multiply by 256)
        
        # Convert Q5.10 to float
        input_val = q510_to_float(q510_input)
        
        # Calculate GELU
        gelu_val = gelu_function(input_val)
        
        # Convert GELU result back to Q5.10
        gelu_q510 = float_to_q510(gelu_val)
        
        # Store results
        lut_indices.append(addr)
        input_values.append(input_val)
        gelu_values.append(gelu_val)
        lut_hex.append(gelu_q510)
    
    return lut_indices, input_values, gelu_values, lut_hex

def save_correct_verilog_lut(lut_hex, filename="gelu_lut_correct.v"):
    """Save corrected LUT as Verilog"""
    print(f"Saving CORRECTED Verilog LUT to {filename}...")
    
    with open(filename, 'w') as f:
        f.write("// CORRECTED GELU LUT - 256 entries (8-bit addressing)\n")
        f.write("// Usage: gelu_output = gelu_lut[q510_input[15:8]];\n")
        f.write("// Address mapping: MSB 8 bits directly index into LUT\n\n")
        
        f.write("reg [15:0] gelu_lut [0:255];\n\n")
        f.write("initial begin\n")
        
        # Write in groups of 4 for readability
        for i in range(0, len(lut_hex), 4):
            f.write("    ")
            for j in range(4):
                if i + j < len(lut_hex):
                    f.write(f"gelu_lut[{i+j:3d}] = 16'h{lut_hex[i+j]:04X}; ")
            f.write("\n")
        
        f.write("end\n\n")
        
        f.write("// Address mapping examples:\n")
        f.write("// Input 0.0 (0x0000) -> Address 0x00 -> LUT[0]\n")
        f.write("// Input 1.0 (0x0400) -> Address 0x04 -> LUT[4]\n")
        f.write("// Input -1.0 (0xFC00) -> Address 0xFC -> LUT[252]\n")
    
    print(f"CORRECTED Verilog LUT saved!")

def show_corrected_sample_values(indices, inputs, gelu_vals, hex_vals):
    """Show sample LUT values with correct mapping"""
    print("\nCORRECTED Sample LUT values:")
    print("Address  Q5.10_Input  Float_Input  GELU_Output  GELU_Hex")
    print("-" * 60)
    
    # Show key sample points that match hardware addressing
    test_addresses = [
        0x00,  # 0.0
        0x04,  # 1.0  
        0x08,  # 2.0
        0x10,  # 4.0
        0x80,  # -32.0
        0xF0,  # -4.0
        0xFC,  # -1.0
        0xFF,  # -0.25
    ]
    
    for addr in test_addresses:
        if addr < len(inputs):
            q510_repr = addr << 8
            print(f"0x{addr:02X}     0x{q510_repr:04X}      {inputs[addr]:8.3f}     {gelu_vals[addr]:8.4f}    0x{hex_vals[addr]:04X}")

def verify_hardware_mapping():
    """Verify that our mapping matches hardware expectations"""
    print("\n" + "=" * 60)
    print("HARDWARE MAPPING VERIFICATION")
    print("=" * 60)
    
    def q510_to_float(q510_int):
        if q510_int >= 32768:
            return (q510_int - 65536) / 1024.0
        else:
            return q510_int / 1024.0
    
    test_cases = [
        (0x0000, "0.0"),
        (0x0400, "1.0"), 
        (0x0800, "2.0"),
        (0xFC00, "-1.0"),
        (0xF000, "-4.0"),
        (0x8000, "-32.0"),
    ]
    
    print("Hardware Test Cases:")
    print("Q5.10_Input -> Address -> Expected_Input")
    print("-" * 40)
    
    for q510_input, description in test_cases:
        address = (q510_input >> 8) & 0xFF
        reconstructed_q510 = address << 8
        reconstructed_float = q510_to_float(reconstructed_q510)
        original_float = q510_to_float(q510_input)
        
        print(f"0x{q510_input:04X} ({description:>6}) -> 0x{address:02X} -> {reconstructed_float:6.1f} (vs {original_float:6.1f})")

def main():
    """Generate corrected GELU LUT"""
    print("FIXING GELU LUT ADDRESS MAPPING")
    print("=" * 60)
    
    indices, inputs, gelu_vals, hex_vals = generate_correct_gelu_lut()
    
    show_corrected_sample_values(indices, inputs, gelu_vals, hex_vals)
    verify_hardware_mapping()
    
    save_correct_verilog_lut(hex_vals)
    
    print("\n" + "=" * 60)
    print("CORRECTED GELU LUT COMPLETE!")
    print("=" * 60)
    print("✅ Address mapping now matches hardware [15:8]")
    print("✅ LUT[4] now contains GELU(1.0) ≈ 0.841")
    print("✅ LUT[252] now contains GELU(-1.0) ≈ -0.159")
    print("✅ Ready for ASIC implementation")
    
    # Show a few key corrections
    print("\nKey Corrections Made:")
    print(f"✅ LUT[4] = 0x{hex_vals[4]:04X} (GELU({inputs[4]:.1f}) = {gelu_vals[4]:.3f})")
    print(f"✅ LUT[252] = 0x{hex_vals[252]:04X} (GELU({inputs[252]:.1f}) = {gelu_vals[252]:.3f})")
    print(f"✅ LUT[0] = 0x{hex_vals[0]:04X} (GELU({inputs[0]:.1f}) = {gelu_vals[0]:.3f})")

if __name__ == "__main__":
    main()