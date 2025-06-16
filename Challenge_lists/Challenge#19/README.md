# Challenge #19
**Eric Zhou**  
**May 10, 2025**

Challenge #19: Implement a binary LIF neuron
Learning goals:
• Learn how a binary Leaky Integrate-and-Fire (LIF) neuron works.
• Implement such a neuron in Verilog or any other HDL.
Binary LIF neuron:
The binary LIF neuron can be formulated as:
• State representation: The neuron's state S(t) is either 0 (not spiking) or 1 (spiking)
• Simplfied update rule:
o Accumulate input: P(t) = λP(t-1) + I(t)
o Where P(t) is a potential variable, λ is a leak factor (between 0 and 1)
o I(t) is the binary input at time t
• Threshold function:
o S(t) = 1 if P(t) ≥ θ (threshold)
o S(t) = 0 otherwise
• Reset mechanism:
o If S(t) = 1, then P(t) is reset to a lower value
Tasks:
1. Write a Verilog implementation of a simple binary LIF neuron (using the formulation above) with a
single input.
2. Write a testbench that demonstrates the following scenarios:
• Constant input below threshold
• Input that accumulates until reaching threshold
• Leakage with no input
• Strong input causing immediate spiking

use gpt to write system verilog code is pain

I want to say actually should be easy coding, but my way of vibe coding seems always generate me the wrong result

You can check my lif code under Code folder

GPT always generate strange bit shifting result as I scale my bits result.

Suffering greatly from verilator simulation. simulation makes no sense.

I think I should allow more bits input then we can so called a input

Below is my simulation test result to show the behavior of the LIF neuron in Verilog: Constant input below threshold; then accumulates until reaching threshold; next Leakage with no input and lastly strong input causing immediate spiking. I observe that if the constant input is too weak, the potential may never reach the threshold and will accumulate to a constant value below the threshold.

![Simulation binary output](binary%20output.png)




command to check:
vlib work

vlog +acc lif_neuron.sv lif_neuron_tb.sv

vsim -voptargs="+acc" lif_neuron_tb

add wave -r /*
run -all
