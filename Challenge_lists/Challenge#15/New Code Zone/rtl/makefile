# Makefile for simulating the tiny GPT-2 model using cocotb
# with Icarus Verilog.
# This Makefile sets up the simulation environment and specifies the
# Verilog sources, top-level module, and Python test module.
# It also includes the cocotb makefile for simulation.
# The tiny GPT-2 model is a simplified version of the GPT-2 architecture
# designed for educational purposes, focusing on matrix operations
# and basic transformer functionalities.		
SIM = icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = tiny_gpt2_top.v \
                 matrix_mult_16x16.v \
                 layernorm_matrix_processor.v \
                 softmax_matrix_processor.v \
                 gelu_matrix_processor.v \
				 inv_sqrt_newton.v \
				 layernorm_pipeline.v \
				 layernorm_postprocess.v \
				 layernorm_preprocess.v \
				 mac_unit.v \
				 systolic_pe.v \
				 softmax_processor.v\
				 softmax_frontend.v \
				 softmax_backend.v \


TOPLEVEL = tiny_gpt2_top
MODULE = test_tiny_gpt2

include $(shell cocotb-config --makefiles)/Makefile.sim