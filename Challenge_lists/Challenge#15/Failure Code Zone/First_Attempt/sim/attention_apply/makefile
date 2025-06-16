TOP_MODULE = attention_apply
RTL_DIR = ../../rtl
SIM_CPP = sim_main.cpp

# Grab all SystemVerilog files in RTL_DIR
RTL_SRCS := $(wildcard $(RTL_DIR)/*.sv)

# Default target
all: sim

# Simulation build and run
sim: $(SIM_CPP)
	verilator -Wall -Wno-fatal \
		--cc $(RTL_SRCS) --top-module $(TOP_MODULE) \
		--exe $(SIM_CPP) -o V$(TOP_MODULE)
	make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)
	./obj_dir/V$(TOP_MODULE)

# Clean build artifacts
clean:
	rm -rf obj_dir V$(TOP_MODULE)
