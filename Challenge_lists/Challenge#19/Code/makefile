TOP_MODULE = lif_neuron
SIM_CPP = sim_main.cpp

all: sim

sim: $(SIM_CPP)
	verilator -Wall -Wno-fatal --trace \
		--cc $(TOP_MODULE).sv --exe $(SIM_CPP) -o V$(TOP_MODULE) \
		-CFLAGS "-DVM_TRACE=1" \
		-LDFLAGS "--trace"
	make -C obj_dir -f V$(TOP_MODULE).mk
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd V$(TOP_MODULE)
